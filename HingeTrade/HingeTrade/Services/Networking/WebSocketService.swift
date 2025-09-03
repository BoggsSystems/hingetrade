import Foundation
import Combine

// MARK: - WebSocket Service Protocol
protocol WebSocketServiceProtocol {
    var connectionState: AnyPublisher<WebSocketConnectionState, Never> { get }
    var messagePublisher: AnyPublisher<WebSocketMessage, Never> { get }
    
    func connect()
    func disconnect()
    func subscribe(to channels: [WebSocketSubscription])
    func unsubscribe(from channels: [WebSocketSubscription])
    func send<T: Codable>(message: T)
}

// MARK: - WebSocket Connection State
enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case error(Error)
    
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    var displayName: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting"
        case .error:
            return "Error"
        }
    }
}

// MARK: - WebSocket Service Implementation
class WebSocketService: NSObject, WebSocketServiceProtocol {
    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    @Published private var _connectionState: WebSocketConnectionState = .disconnected
    @Published private var _messages = PassthroughSubject<WebSocketMessage, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectInterval: TimeInterval = 5.0
    
    // Subscription management
    private var activeSubscriptions: Set<WebSocketSubscription> = []
    private var pendingSubscriptions: Set<WebSocketSubscription> = []
    
    // Heartbeat management
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30.0
    private var lastHeartbeatResponse: Date?
    
    // MARK: - Public Properties
    
    var connectionState: AnyPublisher<WebSocketConnectionState, Never> {
        return $_connectionState.eraseToAnyPublisher()
    }
    
    var messagePublisher: AnyPublisher<WebSocketMessage, Never> {
        return _messages.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(url: URL) {
        self.url = url
        super.init()
        setupURLSession()
    }
    
    deinit {
        disconnect()
        heartbeatTimer?.invalidate()
        reconnectTimer?.invalidate()
    }
    
    // MARK: - Connection Management
    
    func connect() {
        switch _connectionState {
        case .connected, .connecting:
            return
        default:
            break
        }
        
        _connectionState = .connecting
        reconnectAttempts = 0
        
        createWebSocketTask()
        webSocketTask?.resume()
        
        startReceivingMessages()
        startHeartbeat()
        
        print("WebSocket: Attempting to connect to \(url)")
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        heartbeatTimer?.invalidate()
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        _connectionState = .disconnected
        activeSubscriptions.removeAll()
        pendingSubscriptions.removeAll()
        
        print("WebSocket: Disconnected")
    }
    
    // MARK: - Subscription Management
    
    func subscribe(to channels: [WebSocketSubscription]) {
        for subscription in channels {
            if _connectionState.isConnected {
                sendSubscription(subscription)
                activeSubscriptions.insert(subscription)
            } else {
                pendingSubscriptions.insert(subscription)
            }
        }
    }
    
    func unsubscribe(from channels: [WebSocketSubscription]) {
        for subscription in channels {
            if _connectionState.isConnected {
                sendUnsubscription(subscription)
            }
            activeSubscriptions.remove(subscription)
            pendingSubscriptions.remove(subscription)
        }
    }
    
    func send<T: Codable>(message: T) {
        guard _connectionState.isConnected else {
            print("WebSocket: Cannot send message - not connected")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("WebSocket: Failed to send message - \(error)")
                }
            }
        } catch {
            print("WebSocket: Failed to encode message - \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupURLSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    private func createWebSocketTask() {
        guard let urlSession = urlSession else { return }
        webSocketTask = urlSession.webSocketTask(with: url)
    }
    
    private func startReceivingMessages() {
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                self?.receiveMessage() // Continue receiving
                
            case .failure(let error):
                print("WebSocket: Receive error - \(error)")
                self?.handleConnectionError(error)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
            
        case .data(let data):
            handleDataMessage(data)
            
        @unknown default:
            print("WebSocket: Unknown message type received")
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            print("WebSocket: Failed to convert text message to data")
            return
        }
        
        handleDataMessage(data)
    }
    
    private func handleDataMessage(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let wsMessage = try decoder.decode(WebSocketMessage.self, from: data)
            
            // Handle special message types
            switch wsMessage.type {
            case .heartbeat:
                handleHeartbeat()
                
            case .error:
                if let errorData = wsMessage.data {
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    print("WebSocket: Server error - \(errorMessage)")
                }
                
            case .quote, .trade, .bar, .orderUpdate, .positionUpdate, .accountUpdate, .alert:
                // Forward to subscribers
                _messages.send(wsMessage)
                
            case .subscribe, .unsubscribe:
                // Acknowledgment messages
                print("WebSocket: Subscription acknowledgment - \(wsMessage.type)")
            }
            
        } catch {
            print("WebSocket: Failed to decode message - \(error)")
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        _connectionState = .error(error)
        
        // Attempt reconnection if not intentionally disconnected
        if reconnectAttempts < maxReconnectAttempts {
            scheduleReconnect()
        }
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        
        let delay = reconnectInterval * pow(2.0, Double(reconnectAttempts)) // Exponential backoff
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
        
        _connectionState = .reconnecting
        print("WebSocket: Scheduling reconnect attempt \(reconnectAttempts + 1) in \(delay) seconds")
    }
    
    private func attemptReconnect() {
        reconnectAttempts += 1
        
        createWebSocketTask()
        webSocketTask?.resume()
        startReceivingMessages()
        
        print("WebSocket: Reconnect attempt \(reconnectAttempts)")
    }
    
    private func onConnectionEstablished() {
        _connectionState = .connected
        reconnectAttempts = 0
        
        // Send pending subscriptions
        for subscription in pendingSubscriptions {
            sendSubscription(subscription)
            activeSubscriptions.insert(subscription)
        }
        pendingSubscriptions.removeAll()
        
        print("WebSocket: Connection established")
    }
    
    private func sendSubscription(_ subscription: WebSocketSubscription) {
        let subscribeMessage = WebSocketMessage(
            type: .subscribe,
            data: try? JSONEncoder().encode(subscription),
            timestamp: Date(),
            id: UUID().uuidString
        )
        
        send(message: subscribeMessage)
    }
    
    private func sendUnsubscription(_ subscription: WebSocketSubscription) {
        let unsubscribeMessage = WebSocketMessage(
            type: .unsubscribe,
            data: try? JSONEncoder().encode(subscription),
            timestamp: Date(),
            id: UUID().uuidString
        )
        
        send(message: unsubscribeMessage)
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        let heartbeatMessage = WebSocketMessage(
            type: .heartbeat,
            data: nil,
            timestamp: Date(),
            id: UUID().uuidString
        )
        
        send(message: heartbeatMessage)
        
        // Check if we've received a recent heartbeat response
        if let lastResponse = lastHeartbeatResponse,
           Date().timeIntervalSince(lastResponse) > heartbeatInterval * 2 {
            print("WebSocket: Heartbeat timeout - connection may be stale")
            handleConnectionError(WebSocketError.heartbeatTimeout)
        }
    }
    
    private func handleHeartbeat() {
        lastHeartbeatResponse = Date()
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket: Connection opened")
        onConnectionEstablished()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket: Connection closed with code \(closeCode)")
        
        if closeCode == .normalClosure {
            _connectionState = .disconnected
        } else {
            let error = WebSocketError.connectionClosed(closeCode)
            handleConnectionError(error)
        }
    }
}

// MARK: - WebSocket Subscription Extensions
extension WebSocketSubscription: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(symbols)
        hasher.combine(channels)
    }
    
    static func == (lhs: WebSocketSubscription, rhs: WebSocketSubscription) -> Bool {
        return lhs.type == rhs.type &&
               lhs.symbols == rhs.symbols &&
               lhs.channels == rhs.channels
    }
}

// MARK: - Subscription Helpers
extension WebSocketSubscription {
    // Convenience initializers for common subscription types
    static func quotes(symbols: [String]) -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .quote,
            symbols: symbols,
            channels: nil
        )
    }
    
    static func trades(symbols: [String]) -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .trade,
            symbols: symbols,
            channels: nil
        )
    }
    
    static func bars(symbols: [String]) -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .bar,
            symbols: symbols,
            channels: nil
        )
    }
    
    static func orderUpdates() -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .orderUpdate,
            symbols: nil,
            channels: ["orders"]
        )
    }
    
    static func positionUpdates() -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .positionUpdate,
            symbols: nil,
            channels: ["positions"]
        )
    }
    
    static func accountUpdates() -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .accountUpdate,
            symbols: nil,
            channels: ["account"]
        )
    }
    
    static func alerts() -> WebSocketSubscription {
        return WebSocketSubscription(
            type: .alert,
            symbols: nil,
            channels: ["alerts"]
        )
    }
}

// MARK: - WebSocket Errors
enum WebSocketError: Error, LocalizedError {
    case connectionClosed(URLSessionWebSocketTask.CloseCode)
    case heartbeatTimeout
    case invalidMessage
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .connectionClosed(let code):
            return "WebSocket connection closed with code \(code)"
        case .heartbeatTimeout:
            return "WebSocket heartbeat timeout"
        case .invalidMessage:
            return "Invalid WebSocket message received"
        case .encodingError:
            return "Failed to encode WebSocket message"
        }
    }
}

// MARK: - Mock WebSocket Service
class MockWebSocketService: WebSocketServiceProtocol {
    @Published private var _connectionState: WebSocketConnectionState = .disconnected
    private let _messageSubject = PassthroughSubject<WebSocketMessage, Never>()
    
    private var timer: Timer?
    private var subscribedSymbols: Set<String> = []
    
    var connectionState: AnyPublisher<WebSocketConnectionState, Never> {
        return $_connectionState.eraseToAnyPublisher()
    }
    
    var messagePublisher: AnyPublisher<WebSocketMessage, Never> {
        return _messageSubject.eraseToAnyPublisher()
    }
    
    func connect() {
        _connectionState = .connecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?._connectionState = .connected
            self?.startMockDataGeneration()
        }
    }
    
    func disconnect() {
        timer?.invalidate()
        timer = nil
        _connectionState = .disconnected
        subscribedSymbols.removeAll()
    }
    
    func subscribe(to channels: [WebSocketSubscription]) {
        for subscription in channels {
            if let symbols = subscription.symbols {
                subscribedSymbols.formUnion(symbols)
            }
        }
    }
    
    func unsubscribe(from channels: [WebSocketSubscription]) {
        for subscription in channels {
            if let symbols = subscription.symbols {
                subscribedSymbols.subtract(symbols)
            }
        }
    }
    
    func send<T: Codable>(message: T) {
        // Mock implementation - just print
        print("Mock WebSocket: Sending message \(T.self)")
    }
    
    // MARK: - Mock Data Generation
    
    private func startMockDataGeneration() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.generateMockQuoteUpdate()
        }
    }
    
    private func generateMockQuoteUpdate() {
        guard !subscribedSymbols.isEmpty else { return }
        
        let symbol = subscribedSymbols.randomElement()!
        let basePrice = Double.random(in: 100...200)
        let change = Double.random(in: -2...2)
        
        let quote = Quote(
            symbol: symbol,
            timestamp: Date(),
            askPrice: basePrice + 0.01,
            askSize: Int.random(in: 100...1000),
            bidPrice: basePrice - 0.01,
            bidSize: Int.random(in: 100...1000),
            lastPrice: basePrice,
            lastSize: Int.random(in: 100...500),
            dailyChange: change,
            dailyChangePercent: change / basePrice,
            dailyHigh: basePrice + 5,
            dailyLow: basePrice - 5,
            dailyOpen: basePrice - change,
            previousClose: basePrice - change,
            volume: Int.random(in: 1000000...10000000),
            averageVolume: Int.random(in: 500000...5000000)
        )
        
        do {
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            let data = try encoder.encode(quote)
            
            let message = WebSocketMessage(
                type: .quote,
                data: data,
                timestamp: Date(),
                id: UUID().uuidString
            )
            
            _messageSubject.send(message)
            
        } catch {
            print("Mock WebSocket: Failed to encode quote - \(error)")
        }
    }
}
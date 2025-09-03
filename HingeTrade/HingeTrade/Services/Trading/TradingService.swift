import Foundation
import Combine

// MARK: - Trading Service Protocol
protocol TradingServiceProtocol {
    // Account Operations
    func getAccount() -> AnyPublisher<Account, APIError>
    func getAccountHistory(period: String) -> AnyPublisher<PortfolioHistoryResponse, APIError>
    
    // Position Operations
    func getPositions() -> AnyPublisher<[Position], APIError>
    func getPosition(symbol: String) -> AnyPublisher<Position?, APIError>
    func closePosition(symbol: String, qty: String?) -> AnyPublisher<Order, APIError>
    
    // Order Operations
    func placeOrder(_ request: PlaceOrderRequest) -> AnyPublisher<Order, APIError>
    func getOrders(status: OrderStatus?) -> AnyPublisher<[Order], APIError>
    func getOrder(id: String) -> AnyPublisher<Order, APIError>
    func cancelOrder(id: String) -> AnyPublisher<Void, APIError>
    func replaceOrder(id: String, request: ReplaceOrderRequest) -> AnyPublisher<Order, APIError>
    
    // Order Validation
    func validateOrder(_ request: PlaceOrderRequest) -> AnyPublisher<OrderValidation, APIError>
    func calculateOrderValue(_ request: PlaceOrderRequest, currentPrice: Double?) -> Double?
    func checkBuyingPower(_ request: PlaceOrderRequest, account: Account?) -> Bool
}

// MARK: - Order Validation Model
struct OrderValidation: Codable {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
    let estimatedValue: Double?
    let estimatedFees: Double?
    let requiredBuyingPower: Double?
    let marginRequirement: Double?
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
}

struct ValidationError: Codable {
    let field: String
    let code: String
    let message: String
}

struct ValidationWarning: Codable {
    let code: String
    let message: String
}

// MARK: - Trading Service Implementation
class TradingService: TradingServiceProtocol {
    private let apiClient: APIClientProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Account Operations
    
    func getAccount() -> AnyPublisher<Account, APIError> {
        let endpoint = APIEndpoint.get("/account")
        
        return apiClient.request<Account>(endpoint)
            .tryMap { (response: APIResponse<Account>) in
                guard let account = response.data else {
                    throw APIError(
                        code: "ACCOUNT_FETCH_FAILED",
                        message: "Failed to get account information",
                        details: "No account data received from server",
                        field: nil
                    )
                }
                return account
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil, field: nil)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getAccountHistory(period: String) -> AnyPublisher<PortfolioHistoryResponse, APIError> {
        let request = PortfolioHistoryRequest(
            period: period,
            timeframe: nil,
            extendedHours: nil
        )
        
        let queryItems = [
            URLQueryItem(name: "period", value: period)
        ]
        
        let endpoint = APIEndpoint.get("/account/portfolio/history", queryItems: queryItems)
        
        return apiClient.request<PortfolioHistoryResponse>(endpoint)
            .tryMap { (response: APIResponse<PortfolioHistoryResponse>) in
                guard let history = response.data else {
                    throw APIError(
                        code: "HISTORY_FETCH_FAILED",
                        message: "Failed to get portfolio history",
                        details: "No history data received from server",
                        field: nil
                    )
                }
                return history
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil, field: nil)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Position Operations
    
    func getPositions() -> AnyPublisher<[Position], APIError> {
        let endpoint = APIEndpoint.get("/positions")
        
        return apiClient.request<[Position]>(endpoint)
            .map { response in
                return response.data ?? []
            }
            .eraseToAnyPublisher()
    }
    
    func getPosition(symbol: String) -> AnyPublisher<Position?, APIError> {
        let endpoint = APIEndpoint.get("/positions/\(symbol)")
        
        return apiClient.request<Position>(endpoint)
            .map { response in
                return response.data
            }
            .catch { error -> AnyPublisher<Position?, APIError> in
                // If position not found, return nil instead of error
                if case let apiError as APIError = error, apiError.code == "NOT_FOUND" {
                    return Just(nil).setFailureType(to: APIError.self).eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func closePosition(symbol: String, qty: String?) -> AnyPublisher<Order, APIError> {
        // First get the position to determine current quantity and side
        return getPosition(symbol: symbol)
            .flatMap { [weak self] position -> AnyPublisher<Order, APIError> in
                guard let self = self, let position = position else {
                    return Fail(error: APIError(
                        code: "POSITION_NOT_FOUND",
                        message: "Position not found",
                        details: "Cannot close position that doesn't exist",
                        field: "symbol"
                    )).eraseToAnyPublisher()
                }
                
                // Create order request to close position
                let closeRequest = PlaceOrderRequest(
                    symbol: symbol,
                    side: position.side == .long ? .sell : .buy,
                    type: .market,
                    timeInForce: .day,
                    qty: qty ?? position.qty,
                    notional: nil,
                    limitPrice: nil,
                    stopPrice: nil,
                    extendedHours: false,
                    clientOrderId: "close-\(symbol)-\(UUID().uuidString)"
                )
                
                return self.placeOrder(closeRequest)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Order Operations
    
    func placeOrder(_ request: PlaceOrderRequest) -> AnyPublisher<Order, APIError> {
        do {
            let endpoint = try APIEndpoint.post("/orders", body: request)
            
            return apiClient.request(endpoint)
                .tryMap { (response: APIResponse<OrderResponse>) -> Order in
                    guard let orderResponse = response.data else {
                        throw APIError(
                            code: "ORDER_PLACEMENT_FAILED",
                            message: "Failed to place order",
                            details: "No order data received from server",
                            field: nil
                        )
                    }
                    return orderResponse.order
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create order request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Order, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func getOrders(status: OrderStatus?) -> AnyPublisher<[Order], APIError> {
        var queryItems: [URLQueryItem] = []
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        
        let endpoint = APIEndpoint.get("/orders", queryItems: queryItems.isEmpty ? nil : queryItems)
        
        return apiClient.request(endpoint)
            .map { (response: APIResponse<[Order]>) -> [Order] in
                return response.data ?? []
            }
            .mapError { error -> APIError in
                return error as? APIError ?? APIError(
                    code: "REQUEST_ERROR",
                    message: "Request failed",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getOrder(id: String) -> AnyPublisher<Order, APIError> {
        let endpoint = APIEndpoint.get("/orders/\(id)")
        
        return apiClient.request(endpoint)
            .tryMap { (response: APIResponse<Order>) -> Order in
                guard let order = response.data else {
                    throw APIError(
                        code: "ORDER_FETCH_FAILED",
                        message: "Failed to get order",
                        details: "No order data received from server",
                        field: nil
                    )
                }
                return order
            }
            .mapError { error -> APIError in
                return error as? APIError ?? APIError(
                    code: "REQUEST_ERROR",
                    message: "Request failed",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func cancelOrder(id: String) -> AnyPublisher<Void, APIError> {
        let endpoint = APIEndpoint.delete("/orders/\(id)")
        
        return apiClient.request(endpoint)
            .map { (_: APIResponse<String>) -> Void in () }
            .mapError { error -> APIError in
                return error as? APIError ?? APIError(
                    code: "REQUEST_ERROR",
                    message: "Request failed",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func replaceOrder(id: String, request: ReplaceOrderRequest) -> AnyPublisher<Order, APIError> {
        do {
            let endpoint = try APIEndpoint.put("/orders/\(id)", body: request)
            
            return apiClient.request(endpoint)
                .tryMap { (response: APIResponse<Order>) -> Order in
                    guard let order = response.data else {
                        throw APIError(
                            code: "ORDER_REPLACE_FAILED",
                            message: "Failed to replace order",
                            details: "No order data received from server",
                            field: nil
                        )
                    }
                    return order
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create replace order request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Order, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Order Validation
    
    func validateOrder(_ request: PlaceOrderRequest) -> AnyPublisher<OrderValidation, APIError> {
        do {
            let endpoint = try APIEndpoint.post("/orders/validate", body: request)
            
            return apiClient.request(endpoint)
                .tryMap { (response: APIResponse<OrderValidation>) -> OrderValidation in
                    guard let validation = response.data else {
                        throw APIError(
                            code: "VALIDATION_FAILED",
                            message: "Failed to validate order",
                            details: "No validation data received from server",
                            field: nil
                        )
                    }
                    return validation
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create validation request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<OrderValidation, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func calculateOrderValue(_ request: PlaceOrderRequest, currentPrice: Double?) -> Double? {
        // Calculate order value based on order type and parameters
        guard let qtyString = request.qty, let qty = Double(qtyString) else {
            return nil
        }
        
        switch request.type {
        case .market:
            // Use current market price
            guard let price = currentPrice else { return nil }
            return qty * price
            
        case .limit:
            // Use limit price
            guard let limitPriceString = request.limitPrice,
                  let limitPrice = Double(limitPriceString) else { return nil }
            return qty * limitPrice
            
        case .stop:
            // Use stop price as estimate
            guard let stopPriceString = request.stopPrice,
                  let stopPrice = Double(stopPriceString) else { return nil }
            return qty * stopPrice
            
        case .stopLimit:
            // Use limit price if available, otherwise stop price
            if let limitPriceString = request.limitPrice,
               let limitPrice = Double(limitPriceString) {
                return qty * limitPrice
            } else if let stopPriceString = request.stopPrice,
                      let stopPrice = Double(stopPriceString) {
                return qty * stopPrice
            }
            return nil
        }
    }
    
    func checkBuyingPower(_ request: PlaceOrderRequest, account: Account?) -> Bool {
        guard let account = account,
              request.side == .buy,
              let orderValue = calculateOrderValue(request, currentPrice: nil),
              let buyingPower = Double(account.buyingPower) else {
            return false
        }
        
        return orderValue <= buyingPower
    }
}

// MARK: - Mock Trading Service
class MockTradingService: TradingServiceProtocol {
    private var mockAccount = Account.sampleData
    private var mockPositions = Position.sampleData
    private var mockOrders = Order.sampleData
    
    func getAccount() -> AnyPublisher<Account, APIError> {
        return Future<Account, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let account = self?.mockAccount {
                    promise(.success(account))
                } else {
                    promise(.failure(APIError(
                        code: "ACCOUNT_NOT_FOUND",
                        message: "Account not found",
                        details: nil,
                        field: nil
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAccountHistory(period: String) -> AnyPublisher<PortfolioHistoryResponse, APIError> {
        return Future<PortfolioHistoryResponse, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Generate mock portfolio history
                let history = MockTradingService.generateMockPortfolioHistory(period: period)
                promise(.success(history))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getPositions() -> AnyPublisher<[Position], APIError> {
        return Future<[Position], APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                promise(.success(self?.mockPositions ?? []))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getPosition(symbol: String) -> AnyPublisher<Position?, APIError> {
        return Future<Position?, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let position = self?.mockPositions.first { $0.symbol == symbol }
                promise(.success(position))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func closePosition(symbol: String, qty: String?) -> AnyPublisher<Order, APIError> {
        return Future<Order, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Create mock close order
                let mockOrder = Order(
                    id: UUID().uuidString,
                    clientOrderId: "close-\(symbol)",
                    createdAt: Date(),
                    updatedAt: Date(),
                    submittedAt: Date(),
                    filledAt: nil,
                    expiredAt: nil,
                    canceledAt: nil,
                    failedAt: nil,
                    replacedAt: nil,
                    replacedBy: nil,
                    replaces: nil,
                    assetId: UUID().uuidString,
                    symbol: symbol,
                    assetClass: .usEquity,
                    qty: qty ?? "100",
                    filledQty: nil,
                    notional: nil,
                    filledAvgPrice: nil,
                    side: .sell,
                    type: .market,
                    timeInForce: .day,
                    limitPrice: nil,
                    stopPrice: nil,
                    status: .new,
                    extendedHours: false,
                    legs: nil
                )
                promise(.success(mockOrder))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func placeOrder(_ request: PlaceOrderRequest) -> AnyPublisher<Order, APIError> {
        return Future<Order, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Simulate order validation
                if request.symbol.isEmpty {
                    promise(.failure(APIError(
                        code: "VALIDATION_INVALID_SYMBOL",
                        message: "Symbol is required",
                        details: nil,
                        field: "symbol"
                    )))
                    return
                }
                
                // Create mock order
                let mockOrder = Order(
                    id: UUID().uuidString,
                    clientOrderId: request.clientOrderId,
                    createdAt: Date(),
                    updatedAt: Date(),
                    submittedAt: Date(),
                    filledAt: nil,
                    expiredAt: nil,
                    canceledAt: nil,
                    failedAt: nil,
                    replacedAt: nil,
                    replacedBy: nil,
                    replaces: nil,
                    assetId: UUID().uuidString,
                    symbol: request.symbol,
                    assetClass: .usEquity,
                    qty: request.qty,
                    filledQty: nil,
                    notional: request.notional,
                    filledAvgPrice: nil,
                    side: request.side,
                    type: request.type,
                    timeInForce: request.timeInForce,
                    limitPrice: request.limitPrice,
                    stopPrice: request.stopPrice,
                    status: .new,
                    extendedHours: request.extendedHours,
                    legs: nil
                )
                
                self?.mockOrders.append(mockOrder)
                promise(.success(mockOrder))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getOrders(status: OrderStatus?) -> AnyPublisher<[Order], APIError> {
        return Future<[Order], APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                var orders = self?.mockOrders ?? []
                if let status = status {
                    orders = orders.filter { $0.status == status }
                }
                promise(.success(orders))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getOrder(id: String) -> AnyPublisher<Order, APIError> {
        return Future<Order, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let order = self?.mockOrders.first(where: { $0.id == id }) {
                    promise(.success(order))
                } else {
                    promise(.failure(APIError(
                        code: "ORDER_NOT_FOUND",
                        message: "Order not found",
                        details: nil,
                        field: nil
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func cancelOrder(id: String) -> AnyPublisher<Void, APIError> {
        return Future<Void, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Update mock order status
                if let index = self?.mockOrders.firstIndex(where: { $0.id == id }) {
                    // Create updated order with canceled status
                    // Note: In real implementation, you'd update the existing order
                    promise(.success(()))
                } else {
                    promise(.failure(APIError(
                        code: "ORDER_NOT_FOUND",
                        message: "Order not found",
                        details: nil,
                        field: nil
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func replaceOrder(id: String, request: ReplaceOrderRequest) -> AnyPublisher<Order, APIError> {
        return Future<Order, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let order = self?.mockOrders.first(where: { $0.id == id }) {
                    // Create updated order (simplified for mock)
                    promise(.success(order))
                } else {
                    promise(.failure(APIError(
                        code: "ORDER_NOT_FOUND",
                        message: "Order not found",
                        details: nil,
                        field: nil
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func validateOrder(_ request: PlaceOrderRequest) -> AnyPublisher<OrderValidation, APIError> {
        return Future<OrderValidation, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let validation = OrderValidation(
                    isValid: !request.symbol.isEmpty,
                    errors: request.symbol.isEmpty ? [
                        ValidationError(
                            field: "symbol",
                            code: "REQUIRED",
                            message: "Symbol is required"
                        )
                    ] : [],
                    warnings: [],
                    estimatedValue: 1000.0,
                    estimatedFees: 0.0,
                    requiredBuyingPower: 1000.0,
                    marginRequirement: nil
                )
                promise(.success(validation))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func calculateOrderValue(_ request: PlaceOrderRequest, currentPrice: Double?) -> Double? {
        guard let qtyString = request.qty, let qty = Double(qtyString) else {
            return nil
        }
        
        let estimatedPrice = currentPrice ?? 100.0 // Mock price
        return qty * estimatedPrice
    }
    
    func checkBuyingPower(_ request: PlaceOrderRequest, account: Account?) -> Bool {
        // Mock implementation - always return true for demo
        return true
    }
    
    // MARK: - Helper Methods
    
    private static func generateMockPortfolioHistory(period: String) -> PortfolioHistoryResponse {
        let calendar = Calendar.current
        let now = Date()
        var snapshots: [PortfolioSnapshot] = []
        
        let (days, interval): (Int, TimeInterval) = {
            switch period {
            case "1D": return (1, 300) // 5 minute intervals
            case "7D": return (7, 3600) // 1 hour intervals
            case "1M": return (30, 86400) // 1 day intervals
            case "3M": return (90, 86400) // 1 day intervals
            case "1Y": return (365, 86400) // 1 day intervals
            default: return (30, 86400)
            }
        }()
        
        let totalSnapshots = period == "1D" ? 78 : days // 78 snapshots for intraday
        var currentValue = 45000.0
        let baseValue = 40000.0
        
        for i in 0..<totalSnapshots {
            let timestamp = now.addingTimeInterval(-Double(totalSnapshots - i) * interval)
            
            // Add some random walk to the portfolio value
            let change = Double.random(in: -200...200)
            currentValue = max(baseValue * 0.8, currentValue + change)
            
            let profitLoss = currentValue - baseValue
            let profitLossPercent = profitLoss / baseValue
            
            let snapshot = PortfolioSnapshot(
                timestamp: timestamp,
                equity: currentValue,
                profitLoss: profitLoss,
                profitLossPercent: profitLossPercent,
                baseValue: baseValue,
                timeframe: period
            )
            snapshots.append(snapshot)
        }
        
        return PortfolioHistoryResponse(
            history: snapshots,
            baseValue: baseValue,
            timeframe: period
        )
    }
}
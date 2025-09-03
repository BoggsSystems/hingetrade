//
//  VideoPlayerViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var video: VideoContent
    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentTime: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var bufferProgress: Double = 0
    @Published var isMuted: Bool = false
    @Published var error: VideoPlayerError?
    @Published var showingError: Bool = false
    
    // UI State
    @Published var isControlsHidden: Bool = false
    @Published var isFullscreen: Bool = true
    
    // Market data for ticker strip
    @Published var symbolQuotes: [String: Quote] = [:]
    
    // User interactions
    @Published var hasLiked: Bool = false
    @Published var tipAmount: Double = 0.0
    
    // AVPlayer
    var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // Services
    private let marketDataService: MarketDataService
    private let videoService: VideoService
    private let webSocketService: WebSocketService
    private let tipService: TipService
    
    // Timers
    private var controlsHideTimer: Timer?
    private var analyticsTimer: Timer?
    
    // Analytics tracking
    private var sessionStartTime: Date?
    private var totalWatchTime: TimeInterval = 0
    private var lastProgressReported: Double = 0
    
    init(
        video: VideoContent,
        marketDataService: MarketDataService = MarketDataService(apiClient: APIClient(baseURL: URL(string: "https://api.alpaca.markets")!, tokenManager: TokenManager())),
        videoService: VideoService = DefaultVideoService(),
        webSocketService: WebSocketService = WebSocketService(url: URL(string: "wss://api.alpaca.markets/stream")!),
        tipService: TipService = DefaultTipService()
    ) {
        self.video = video
        self.marketDataService = marketDataService
        self.videoService = videoService
        self.webSocketService = webSocketService
        self.tipService = tipService
        
        setupRealTimeUpdates()
        setupErrorHandling()
    }
    
    // MARK: - Player Setup
    
    func prepare() async {
        isLoading = true
        sessionStartTime = Date()
        
        do {
            // Create player item
            guard let videoURL = URL(string: video.videoURL) else {
                throw VideoPlayerError.invalidURL(video.videoURL)
            }
            
            let asset = AVAsset(url: videoURL)
            playerItem = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: playerItem)
            
            // Setup player observers
            setupPlayerObservers()
            
            // Load market data for symbols
            await loadMarketData()
            
            // Start analytics tracking
            startAnalyticsTracking()
            
            isLoading = false
            
        } catch {
            self.error = VideoPlayerError.loadingFailed(error.localizedDescription)
            self.showingError = true
            self.isLoading = false
        }
    }
    
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        // Time observer
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.updatePlaybackTime(time)
        }
        
        // Player item status
        playerItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                case .failed:
                    self?.error = VideoPlayerError.playbackFailed("Player item failed to load")
                    self?.showingError = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Buffer progress
        playerItem?.publisher(for: \.loadedTimeRanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ranges in
                self?.updateBufferProgress(ranges)
            }
            .store(in: &cancellables)
        
        // Playback finished
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePlaybackFinished()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Playback Controls
    
    func play() {
        player?.play()
        isPlaying = true
        hideControlsAfterDelay()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        showControls()
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to progress: Double) {
        guard let player = player else { return }
        
        let duration = video.duration
        let targetTime = duration * progress
        let cmTime = CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: cmTime) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    func seekForward(seconds: TimeInterval = 10) {
        guard let player = player else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = min(currentTime + seconds, video.duration)
        let cmTime = CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: cmTime)
    }
    
    func seekBackward(seconds: TimeInterval = 10) {
        guard let player = player else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - seconds, 0)
        let cmTime = CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: cmTime)
    }
    
    func toggleMute() {
        player?.isMuted.toggle()
        isMuted = player?.isMuted ?? false
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
    
    // MARK: - UI Controls
    
    func showControls() {
        isControlsHidden = false
        controlsHideTimer?.invalidate()
    }
    
    func hideControls() {
        isControlsHidden = true
    }
    
    func toggleControlsVisibility() {
        if isControlsHidden {
            showControls()
            hideControlsAfterDelay()
        } else {
            hideControls()
        }
    }
    
    private func hideControlsAfterDelay() {
        controlsHideTimer?.invalidate()
        controlsHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            if self?.isPlaying == true {
                self?.hideControls()
            }
        }
    }
    
    // MARK: - Market Data Integration
    
    private func loadMarketData() async {
        for symbol in video.symbols {
            do {
                let quote = try await withCheckedThrowingContinuation { continuation in
                    marketDataService.getQuote(symbol: symbol)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    continuation.resume(throwing: error)
                                }
                            },
                            receiveValue: { quote in
                                continuation.resume(returning: quote)
                            }
                        )
                        .store(in: &cancellables)
                }
                symbolQuotes[symbol] = quote
            } catch {
                print("Failed to load market data for \(symbol): \(error)")
            }
        }
    }
    
    func getQuote(for symbol: String) -> Quote? {
        return symbolQuotes[symbol]
    }
    
    var primarySymbol: String {
        return video.symbols.first ?? ""
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Subscribe to quote updates for video symbols
        webSocketService.quoteUpdates
            .filter { [weak self] quote in
                self?.video.symbols.contains(quote.symbol) ?? false
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quote in
                self?.symbolQuotes[quote.symbol] = quote
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Interactions
    
    func likeVideo() async {
        guard !hasLiked else { return }
        
        do {
            try await videoService.likeVideo(video.id)
            hasLiked = true
            
            // Track interaction
            await trackPlayerUserInteraction(.like)
            
        } catch {
            print("Failed to like video: \(error)")
        }
    }
    
    func sendTip(amount: Double) async {
        do {
            try await tipService.sendTip(
                toCreator: video.creator.id,
                amount: amount,
                videoId: video.id
            )
            
            tipAmount += amount
            
            // Track interaction
            await trackPlayerUserInteraction(.tip(amount: amount))
            
        } catch {
            print("Failed to send tip: \(error)")
        }
    }
    
    func addToWatchlist() async {
        guard !primarySymbol.isEmpty else { return }
        
        do {
            // This would integrate with the existing watchlist service
            print("Adding \(primarySymbol) to watchlist")
            
            // Track interaction
            await trackPlayerUserInteraction(.addToWatchlist)
            
        } catch {
            print("Failed to add to watchlist")
        }
    }
    
    // MARK: - Analytics & Tracking
    
    private func startAnalyticsTracking() {
        analyticsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.reportWatchProgress()
            }
        }
    }
    
    private func reportWatchProgress() async {
        let currentProgress = progress
        
        // Only report significant progress changes
        if abs(currentProgress - lastProgressReported) >= 0.05 { // 5% progress
            do {
                try await videoService.reportWatchProgress(
                    videoId: video.id,
                    progress: currentProgress,
                    watchTime: currentTime
                )
                lastProgressReported = currentProgress
            } catch {
                print("Failed to report watch progress: \(error)")
            }
        }
    }
    
    private func trackPlayerUserInteraction(_ interaction: PlayerUserInteraction) async {
        do {
            try await videoService.trackInteraction(
                videoId: video.id,
                interaction: interaction,
                timestamp: currentTime
            )
        } catch {
            print("Failed to track interaction: \(error)")
        }
    }
    
    private func handlePlaybackFinished() {
        isPlaying = false
        showControls()
        
        Task {
            await trackPlayerUserInteraction(.completed)
            await finalizeAnalytics()
        }
    }
    
    private func finalizeAnalytics() async {
        guard let sessionStart = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(sessionStart)
        let completionRate = progress
        
        do {
            try await videoService.finalizeVideoSession(
                videoId: video.id,
                sessionDuration: sessionDuration,
                completionRate: completionRate,
                averageEngagement: calculateEngagementScore()
            )
        } catch {
            print("Failed to finalize analytics: \(error)")
        }
    }
    
    private func calculateEngagementScore() -> Double {
        // Calculate engagement based on interactions, watch time, etc.
        var score = progress * 0.6 // Base score from completion
        
        if hasLiked { score += 0.2 }
        if tipAmount > 0 { score += 0.3 }
        
        return min(score, 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func updatePlaybackTime(_ time: CMTime) {
        let seconds = CMTimeGetSeconds(time)
        guard seconds.isFinite else { return }
        
        currentTime = seconds
        updateProgress()
        totalWatchTime = seconds
    }
    
    private func updateProgress() {
        guard video.duration > 0 else { return }
        progress = min(currentTime / video.duration, 1.0)
    }
    
    private func updateBufferProgress(_ ranges: [NSValue]) {
        guard let player = player,
              let range = ranges.first?.timeRangeValue,
              video.duration > 0 else {
            return
        }
        
        let bufferedSeconds = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
        bufferProgress = min(bufferedSeconds / video.duration, 1.0)
    }
    
    func retry() async {
        error = nil
        showingError = false
        await prepare()
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
                self?.pause()
            }
            .store(in: &cancellables)
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        
        controlsHideTimer?.invalidate()
        analyticsTimer?.invalidate()
        cancellables.removeAll()
        
        // Finalize analytics on cleanup
        Task {
            await finalizeAnalytics()
        }
    }
}

// MARK: - Supporting Types

enum PlayerUserInteraction {
    case like
    case tip(amount: Double)
    case addToWatchlist
    case completed
    case skipped
    case shared
    
    var name: String {
        switch self {
        case .like: return "like"
        case .tip: return "tip"
        case .addToWatchlist: return "add_to_watchlist"
        case .completed: return "completed"
        case .skipped: return "skipped"
        case .shared: return "shared"
        }
    }
}

// MARK: - Service Protocols

protocol TipService {
    func sendTip(toCreator creatorId: String, amount: Double, videoId: String) async throws
}

class DefaultTipService: TipService {
    func sendTip(toCreator creatorId: String, amount: Double, videoId: String) async throws {
        // Simulate tip processing
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Sent $\(amount) tip to creator \(creatorId)")
    }
}

// MARK: - VideoPlayerError

enum VideoPlayerError: LocalizedError, Identifiable {
    case invalidURL(String)
    case loadingFailed(String)
    case playbackFailed(String)
    case networkError(String)
    case permissionDenied
    case unknown(String)
    
    var id: String {
        switch self {
        case .invalidURL(let url):
            return url
        case .loadingFailed(let message),
             .playbackFailed(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        case .permissionDenied:
            return "permission_denied"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid video URL: \(url)"
        case .loadingFailed(let message):
            return "Failed to load video: \(message)"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .permissionDenied:
            return "Permission denied to play video"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please try a different video."
        case .loadingFailed, .playbackFailed:
            return "Please check your internet connection and try again."
        case .networkError:
            return "Please check your internet connection and retry."
        case .permissionDenied:
            return "Please check your device settings and try again."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Extensions

extension VideoService {
    func reportWatchProgress(videoId: String, progress: Double, watchTime: TimeInterval) async throws {
        // Default implementation - would integrate with analytics service
        print("Progress: \(progress * 100)% for video \(videoId)")
    }
    
    func trackInteraction(videoId: String, interaction: PlayerUserInteraction, timestamp: TimeInterval) async throws {
        // Default implementation - would integrate with analytics service
        print("Interaction: \(interaction.name) at \(timestamp)s for video \(videoId)")
    }
    
    func finalizeVideoSession(videoId: String, sessionDuration: TimeInterval, completionRate: Double, averageEngagement: Double) async throws {
        // Default implementation - would integrate with analytics service
        print("Session complete for video \(videoId): \(completionRate * 100)% completion, \(averageEngagement * 100)% engagement")
    }
}
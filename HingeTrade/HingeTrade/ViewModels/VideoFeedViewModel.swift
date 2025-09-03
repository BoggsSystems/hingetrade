//
//  VideoFeedViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class VideoFeedViewModel: ObservableObject {
    @Published var videoCategories: [VideoCategory] = []
    @Published var heroVideos: [VideoContent]?
    @Published var isLoading: Bool = false
    @Published var error: VideoFeedError?
    @Published var showingError: Bool = false
    @Published var lastUpdated: Date = Date()
    
    // Market data for header
    @Published var marketStatus: MarketStatus = .closed
    @Published var topMovers: [TopMover] = []
    
    // Feed personalization
    @Published var userPreferences: FeedPreferences = FeedPreferences()
    @Published var recommendedVideos: [VideoContent] = []
    @Published var trendingVideos: [VideoContent] = []
    
    // Video content by category
    private var videosByCategory: [String: [VideoContent]] = [:]
    
    private let videoService: VideoService
    private let marketDataService: MarketDataService
    private let creatorStudioService: CreatorStudioService
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    init(
        videoService: VideoService = DefaultVideoService(),
        marketDataService: MarketDataService = MarketDataService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager())),
        creatorStudioService: CreatorStudioService = DefaultCreatorStudioService()
    ) {
        self.videoService = videoService
        self.marketDataService = marketDataService
        self.creatorStudioService = creatorStudioService
        setupRealTimeUpdates()
        setupErrorHandling()
    }
    
    // MARK: - Data Loading
    
    func loadFeed() async {
        isLoading = true
        error = nil
        
        do {
            await loadHeroContent()
            await loadCategoryContent() 
            await loadMarketData()
            await loadPersonalizedContent()
            
            lastUpdated = Date()
        } catch {
            self.error = VideoFeedError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
        startAutoRefresh()
    }
    
    func refreshFeed() async {
        await loadFeed()
    }
    
    private func loadHeroContent() async {
        do {
            let videos = try await videoService.getFeaturedVideos(limit: 5)
            self.heroVideos = videos
        } catch {
            print("Failed to load hero content: \(error)")
        }
    }
    
    private func loadCategoryContent() async {
        do {
            let categories = VideoCategory.allCategories.sorted { $0.sortOrder < $1.sortOrder }
            var categoriesWithContent: [VideoCategory] = []
            
            for category in categories {
                let videos = try await videoService.getVideosForCategory(category.name, limit: 10)
                if !videos.isEmpty {
                    videosByCategory[category.id] = videos
                    categoriesWithContent.append(category)
                }
            }
            
            self.videoCategories = categoriesWithContent
        } catch {
            print("Failed to load category content: \(error)")
        }
    }
    
    private func loadMarketData() async {
        do {
            // Load market status
            let status = try await withCheckedThrowingContinuation { continuation in
                marketDataService.getMarketStatus()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { status in
                            continuation.resume(returning: status)
                        }
                    )
                    .store(in: &cancellables)
            }
            self.marketStatus = status
            
            // Load top movers
            let movers = try await withCheckedThrowingContinuation { continuation in
                marketDataService.getTopMovers(direction: nil, limit: 5)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { movers in
                            continuation.resume(returning: movers)
                        }
                    )
                    .store(in: &cancellables)
            }
            self.topMovers = movers
        } catch {
            print("Failed to load market data: \(error)")
        }
    }
    
    private func loadPersonalizedContent() async {
        do {
            // Load recommended videos based on user preferences and history
            let recommended = try await videoService.getRecommendedVideos(
                preferences: userPreferences,
                limit: 20
            )
            self.recommendedVideos = recommended
            
            // Load trending videos
            let trending = try await videoService.getTrendingVideos(limit: 15)
            self.trendingVideos = trending
        } catch {
            print("Failed to load personalized content: \(error)")
        }
    }
    
    // MARK: - Content Access
    
    func getVideosForCategory(_ categoryId: String) -> [VideoContent] {
        return videosByCategory[categoryId] ?? []
    }
    
    func getVideoById(_ videoId: String) -> VideoContent? {
        for videos in videosByCategory.values {
            if let video = videos.first(where: { $0.id == videoId }) {
                return video
            }
        }
        
        if let video = heroVideos?.first(where: { $0.id == videoId }) {
            return video
        }
        
        return recommendedVideos.first { $0.id == videoId }
    }
    
    // MARK: - User Interactions
    
    func markVideoAsWatched(_ video: VideoContent, watchTime: TimeInterval) async {
        do {
            try await videoService.recordVideoView(
                videoId: video.id,
                watchTime: watchTime,
                completed: watchTime >= video.duration * 0.8
            )
            
            // Update user preferences based on viewing behavior
            updateUserPreferences(from: video, watchTime: watchTime)
        } catch {
            print("Failed to record video view: \(error)")
        }
    }
    
    func likeVideo(_ video: VideoContent) async {
        do {
            try await videoService.likeVideo(video.id)
            updateUserPreferences(from: video, interaction: .like)
        } catch {
            print("Failed to like video: \(error)")
        }
    }
    
    func followCreator(_ creator: Creator) async {
        do {
            try await videoService.followCreator(creator.id)
            userPreferences.followedCreators.insert(creator.id)
        } catch {
            print("Failed to follow creator: \(error)")
        }
    }
    
    private func updateUserPreferences(from video: VideoContent, watchTime: TimeInterval? = nil, interaction: UserInteraction? = nil) {
        // Update symbol interests
        for symbol in video.symbols {
            let currentWeight = userPreferences.symbolInterests[symbol] ?? 0.0
            userPreferences.symbolInterests[symbol] = min(1.0, currentWeight + 0.1)
        }
        
        // Update category preferences
        let currentCategoryWeight = userPreferences.categoryPreferences[video.category.name] ?? 0.0
        userPreferences.categoryPreferences[video.category.name] = min(1.0, currentCategoryWeight + 0.05)
        
        // Update creator preferences if interaction was positive
        if interaction == .like || (watchTime ?? 0) > video.duration * 0.7 {
            let currentCreatorWeight = userPreferences.creatorPreferences[video.creator.id] ?? 0.0
            userPreferences.creatorPreferences[video.creator.id] = min(1.0, currentCreatorWeight + 0.15)
        }
    }
    
    // MARK: - Search and Filtering
    
    func searchVideos(query: String) async -> [VideoContent] {
        do {
            return try await videoService.searchVideos(query: query, limit: 50)
        } catch {
            print("Search failed: \(error)")
            return []
        }
    }
    
    func getVideosForSymbol(_ symbol: String) -> [VideoContent] {
        var results: [VideoContent] = []
        
        for videos in videosByCategory.values {
            results.append(contentsOf: videos.filter { $0.symbols.contains(symbol) })
        }
        
        if let heroVideos = heroVideos {
            results.append(contentsOf: heroVideos.filter { $0.symbols.contains(symbol) })
        }
        
        return results.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Set up periodic refresh for market data
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadMarketData()
            }
        }
        
        // Listen for new video notifications
        NotificationCenter.default.publisher(for: .newVideoAvailable)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                Task {
                    await self?.handleNewVideoNotification(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleNewVideoNotification(_ notification: Notification) async {
        guard let videoInfo = notification.userInfo as? [String: Any],
              let categoryName = videoInfo["category"] as? String else {
            return
        }
        
        // Refresh specific category or add to appropriate section
        if let category = VideoCategory.allCategories.first(where: { $0.name == categoryName }) {
            do {
                let newVideos = try await videoService.getVideosForCategory(categoryName, limit: 1)
                if let newVideo = newVideos.first {
                    // Insert new video at beginning of category
                    var existing = videosByCategory[category.id] ?? []
                    existing.insert(newVideo, at: 0)
                    
                    // Keep only latest 10 videos per category
                    if existing.count > 10 {
                        existing = Array(existing.prefix(10))
                    }
                    
                    videosByCategory[category.id] = existing
                }
            } catch {
                print("Failed to load new video: \(error)")
            }
        }
    }
    
    private func startAutoRefresh() {
        // Refresh hero content every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadHeroContent()
            }
        }
    }
    
    // MARK: - Analytics
    
    func trackVideoImpression(_ video: VideoContent) async {
        do {
            try await videoService.recordVideoImpression(
                videoId: video.id,
                position: 0, // Would be calculated based on scroll position
                context: "feed"
            )
        } catch {
            print("Failed to track impression: \(error)")
        }
    }
    
    func trackCategoryEngagement(_ category: VideoCategory) async {
        userPreferences.categoryEngagement[category.name] = Date()
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    // MARK: - Cleanup
    
    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct FeedPreferences: Codable {
    var symbolInterests: [String: Double] = [:]
    var categoryPreferences: [String: Double] = [:]
    var creatorPreferences: [String: Double] = [:]
    var followedCreators: Set<String> = []
    var categoryEngagement: [String: Date] = [:]
    var preferredVideoLength: TimeInterval = 180 // 3 minutes
    var riskTolerance: VideoContent.RiskLevel = .moderate
    var timeHorizonPreference: VideoContent.TimeHorizon = .mediumTerm
}

enum UserInteraction {
    case like
    case share
    case comment
    case follow
    case trade
}

// MARK: - Service Protocols (Placeholder implementations)

protocol VideoService {
    func getFeaturedVideos(limit: Int) async throws -> [VideoContent]
    func getVideosForCategory(_ category: String, limit: Int) async throws -> [VideoContent]
    func getRecommendedVideos(preferences: FeedPreferences, limit: Int) async throws -> [VideoContent]
    func getTrendingVideos(limit: Int) async throws -> [VideoContent]
    func searchVideos(query: String, limit: Int) async throws -> [VideoContent]
    func recordVideoView(videoId: String, watchTime: TimeInterval, completed: Bool) async throws
    func recordVideoImpression(videoId: String, position: Int, context: String) async throws
    func likeVideo(_ videoId: String) async throws
    func followCreator(_ creatorId: String) async throws
}

protocol CreatorStudioService {
    func getCreatorVideos(_ creatorId: String, limit: Int) async throws -> [VideoContent]
    func getCreatorAnalytics(_ creatorId: String) async throws -> CreatorAnalytics
}

struct CreatorAnalytics {
    let totalViews: Int
    let totalLikes: Int
    let averageWatchTime: TimeInterval
    let subscriberCount: Int
    let recentGrowth: Double
}

// MARK: - Default Service Implementations

class DefaultVideoService: VideoService {
    func getFeaturedVideos(limit: Int) async throws -> [VideoContent] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return Array(repeating: VideoContent.sampleVideo, count: min(limit, 5))
    }
    
    func getVideosForCategory(_ category: String, limit: Int) async throws -> [VideoContent] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return Array(repeating: VideoContent.sampleVideo, count: min(limit, 8))
    }
    
    func getRecommendedVideos(preferences: FeedPreferences, limit: Int) async throws -> [VideoContent] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return Array(repeating: VideoContent.sampleVideo, count: min(limit, 15))
    }
    
    func getTrendingVideos(limit: Int) async throws -> [VideoContent] {
        try await Task.sleep(nanoseconds: 600_000_000)
        return Array(repeating: VideoContent.sampleVideo, count: min(limit, 10))
    }
    
    func searchVideos(query: String, limit: Int) async throws -> [VideoContent] {
        try await Task.sleep(nanoseconds: 1_200_000_000)
        return Array(repeating: VideoContent.sampleVideo, count: min(limit, 20))
    }
    
    func recordVideoView(videoId: String, watchTime: TimeInterval, completed: Bool) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    func recordVideoImpression(videoId: String, position: Int, context: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    func likeVideo(_ videoId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func followCreator(_ creatorId: String) async throws {
        try await Task.sleep(nanoseconds: 400_000_000)
    }
}

class DefaultCreatorStudioService: CreatorStudioService {
    func getCreatorVideos(_ creatorId: String, limit: Int) async throws -> [VideoContent] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return Array(repeating: VideoContent.sampleVideo, count: min(limit, 12))
    }
    
    func getCreatorAnalytics(_ creatorId: String) async throws -> CreatorAnalytics {
        try await Task.sleep(nanoseconds: 600_000_000)
        return CreatorAnalytics(
            totalViews: 125000,
            totalLikes: 8500,
            averageWatchTime: 142.5,
            subscriberCount: 15600,
            recentGrowth: 0.08
        )
    }
}

// MARK: - Extensions

extension VideoService where Self == DefaultVideoService {
    static func `default`() -> DefaultVideoService {
        return DefaultVideoService()
    }
}

extension CreatorStudioService where Self == DefaultCreatorStudioService {
    static func `default`() -> DefaultCreatorStudioService {
        return DefaultCreatorStudioService()
    }
}

extension Notification.Name {
    static let newVideoAvailable = Notification.Name("newVideoAvailable")
}

// MARK: - VideoFeedError

enum VideoFeedError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case networkError(String)
    case noContent
    case invalidContent(String)
    case rateLimited
    case unauthorized
    case unknown(String)
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .networkError(let message),
             .invalidContent(let message),
             .unknown(let message):
            return message
        case .noContent:
            return "no_content"
        case .rateLimited:
            return "rate_limited"
        case .unauthorized:
            return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load video feed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .noContent:
            return "No video content available"
        case .invalidContent(let message):
            return "Invalid content: \(message)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .unauthorized:
            return "Unauthorized to access video content"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .networkError:
            return "Please check your internet connection and try again."
        case .noContent:
            return "New content will be available soon."
        case .invalidContent:
            return "Please refresh the feed and try again."
        case .rateLimited:
            return "Please wait a moment before refreshing."
        case .unauthorized:
            return "Please sign in to access video content."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}
//
//  CreatorProfileViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class CreatorProfileViewModel: ObservableObject {
    let creator: VideoCreator
    
    // Follow status
    @Published var isFollowing: Bool = false
    @Published var isLoadingFollowStatus: Bool = false
    
    // Creator stats
    @Published var followerCount: Int = 0
    @Published var videoCount: Int = 0
    @Published var winRate: Double = 0.0
    @Published var averageReturn: Double = 0.0
    
    // Creator content
    @Published var creatorVideos: [VideoContent] = []
    @Published var isLoadingVideos: Bool = false
    
    // Performance data
    @Published var performanceData: [PerformanceDataPoint] = []
    @Published var isLoadingPerformance: Bool = false
    @Published var recentTradeCalls: [TradeCall] = []
    
    // Insights data
    @Published var topSectors: [CreatorSector] = []
    @Published var tradingStyle: TradingStyle = TradingStyle.defaultStyle
    
    // Following data
    @Published var followingCreators: [VideoCreator] = []
    @Published var isFollowingDataPublic: Bool = true
    @Published var isLoadingFollowing: Bool = false
    
    // Modal states
    @Published var showingTipModal: Bool = false
    @Published var showingShareModal: Bool = false
    
    // Error handling
    @Published var error: CreatorProfileError?
    @Published var showingError: Bool = false
    
    // Services
    private let socialService: SocialService
    private let contentService: ContentService
    private let analyticsService: AnalyticsService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        creator: VideoCreator,
        socialService: SocialService = SocialService(),
        contentService: ContentService = ContentService(),
        analyticsService: AnalyticsService = AnalyticsService()
    ) {
        self.creator = creator
        self.socialService = socialService
        self.contentService = contentService
        self.analyticsService = analyticsService
        
        setupBindings()
    }
    
    // MARK: - Data Loading
    
    func loadCreatorData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFollowStatus() }
            group.addTask { await self.loadCreatorStats() }
            group.addTask { await self.loadCreatorVideos() }
            group.addTask { await self.loadPerformanceData() }
            group.addTask { await self.loadInsightsData() }
        }
    }
    
    private func loadFollowStatus() async {
        isLoadingFollowStatus = true
        
        do {
            let followStatus = try await socialService.getFollowStatus(creatorId: creator.id)
            self.isFollowing = followStatus.isFollowing
        } catch {
            handleError(.followStatusFailed(error.localizedDescription))
        }
        
        isLoadingFollowStatus = false
    }
    
    private func loadCreatorStats() async {
        do {
            let stats = try await socialService.getCreatorStats(creatorId: creator.id)
            self.followerCount = stats.followerCount
            self.videoCount = stats.videoCount
            self.winRate = stats.winRate
            self.averageReturn = stats.averageReturn
        } catch {
            handleError(.statsLoadingFailed(error.localizedDescription))
        }
    }
    
    private func loadCreatorVideos() async {
        isLoadingVideos = true
        
        do {
            let videos = try await contentService.getCreatorVideos(
                creatorId: creator.id,
                limit: 20,
                sortBy: .newest
            )
            self.creatorVideos = videos
        } catch {
            handleError(.videosLoadingFailed(error.localizedDescription))
        }
        
        isLoadingVideos = false
    }
    
    private func loadPerformanceData() async {
        isLoadingPerformance = true
        
        do {
            let performance = try await analyticsService.getCreatorPerformance(
                creatorId: creator.id,
                timeframe: .threeMonths
            )
            self.performanceData = performance.dataPoints
            self.recentTradeCalls = performance.recentTradeCalls
        } catch {
            handleError(.performanceLoadingFailed(error.localizedDescription))
        }
        
        isLoadingPerformance = false
    }
    
    private func loadInsightsData() async {
        do {
            let insights = try await analyticsService.getCreatorInsights(creatorId: creator.id)
            self.topSectors = insights.topSectors
            self.tradingStyle = insights.tradingStyle
        } catch {
            handleError(.insightsLoadingFailed(error.localizedDescription))
        }
    }
    
    private func loadFollowingData() async {
        isLoadingFollowing = true
        
        do {
            let followingData = try await socialService.getCreatorFollowing(creatorId: creator.id)
            self.followingCreators = followingData.creators
            self.isFollowingDataPublic = followingData.isPublic
        } catch {
            if let socialError = error as? SocialServiceError,
               case .followingDataPrivate = socialError {
                self.isFollowingDataPublic = false
            } else {
                handleError(.followingLoadingFailed(error.localizedDescription))
            }
        }
        
        isLoadingFollowing = false
    }
    
    // MARK: - Social Actions
    
    func toggleFollowStatus() async {
        guard !isLoadingFollowStatus else { return }
        
        isLoadingFollowStatus = true
        let previousStatus = isFollowing
        isFollowing.toggle() // Optimistic update
        
        do {
            if isFollowing {
                try await socialService.followCreator(creatorId: creator.id)
                followerCount += 1
                
                // Track follow event
                await trackAnalyticsEvent(.creatorFollowed)
            } else {
                try await socialService.unfollowCreator(creatorId: creator.id)
                followerCount = max(0, followerCount - 1)
                
                // Track unfollow event
                await trackAnalyticsEvent(.creatorUnfollowed)
            }
        } catch {
            // Revert optimistic update on error
            isFollowing = previousStatus
            handleError(.followActionFailed(error.localizedDescription))
        }
        
        isLoadingFollowStatus = false
    }
    
    func showTipModal() async {
        showingTipModal = true
        await trackAnalyticsEvent(.tipModalOpened)
    }
    
    func sendTip(amount: Decimal) async {
        do {
            try await socialService.sendTip(
                creatorId: creator.id,
                amount: amount,
                message: nil
            )
            
            showingTipModal = false
            await trackAnalyticsEvent(.tipSent)
            
            // Show success feedback
            // This could trigger a toast or animation
        } catch {
            handleError(.tipFailed(error.localizedDescription))
        }
    }
    
    func shareCreator() async {
        showingShareModal = true
        await trackAnalyticsEvent(.creatorShared)
    }
    
    // MARK: - Content Actions
    
    func refreshVideos() async {
        await loadCreatorVideos()
    }
    
    func loadMoreVideos() async {
        guard !isLoadingVideos else { return }
        
        do {
            let moreVideos = try await contentService.getCreatorVideos(
                creatorId: creator.id,
                limit: 20,
                offset: creatorVideos.count,
                sortBy: .newest
            )
            
            self.creatorVideos.append(contentsOf: moreVideos)
        } catch {
            handleError(.videosLoadingFailed(error.localizedDescription))
        }
    }
    
    func filterVideosByPerformance(_ performance: VideoPerformanceFilter) {
        // Filter videos based on performance criteria
        // This could be implemented with local filtering or server-side filtering
    }
    
    // MARK: - Analytics
    
    private func trackAnalyticsEvent(_ event: CreatorProfileAnalyticsEvent) async {
        let context: [String: Any] = [
            "creator_id": creator.id,
            "creator_name": creator.displayName,
            "creator_verified": creator.isVerified,
            "follower_count": followerCount,
            "is_following": isFollowing
        ]
        
        await analyticsService.trackEvent(event.rawValue, properties: context)
    }
    
    // MARK: - Error Handling
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: CreatorProfileError) {
        self.error = error
        print("CreatorProfileViewModel Error: \(error.localizedDescription)")
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct PerformanceDataPoint {
    let date: Date
    let cumulativeReturn: Double
    let dailyReturn: Double
    let winRate: Double
}

struct TradeCall {
    let id: String
    let symbol: String
    let direction: VideoContent.MarketDirection
    let entryPrice: Decimal
    let targetPrice: Decimal?
    let stopPrice: Decimal?
    let performance: Double
    let date: Date
    let isActive: Bool
}

struct CreatorStats {
    let followerCount: Int
    let videoCount: Int
    let winRate: Double
    let averageReturn: Double
    let totalTips: Decimal
    let monthlyViews: Int
}

struct CreatorInsights {
    let topSectors: [CreatorSector]
    let tradingStyle: TradingStyle
    let riskMetrics: RiskMetrics
    let consistencyScore: Double
}

struct CreatorSector {
    let name: String
    let percentage: Double
    let averageReturn: Double
    let tradeCount: Int
    let winRate: Double
}

struct TradingStyle {
    let type: String
    let riskLevel: String
    let averageHoldTime: String
    let description: String
    
    var riskColor: Color {
        switch riskLevel.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .gray
        }
    }
    
    static let defaultStyle = TradingStyle(
        type: "Swing Trader",
        riskLevel: "Medium",
        averageHoldTime: "3-7 days",
        description: "Focuses on medium-term price movements with balanced risk management"
    )
}

struct RiskMetrics {
    let sharpeRatio: Double
    let maxDrawdown: Double
    let volatility: Double
    let betaToMarket: Double
}

struct FollowStatus {
    let isFollowing: Bool
    let followedAt: Date?
    let notificationsEnabled: Bool
}

struct CreatorFollowingData {
    let creators: [VideoCreator]
    let isPublic: Bool
    let totalCount: Int
}

struct CreatorPerformanceData {
    let dataPoints: [PerformanceDataPoint]
    let recentTradeCalls: [TradeCall]
    let metrics: RiskMetrics
}

// MARK: - Error Types

enum CreatorProfileError: LocalizedError, Identifiable {
    case followStatusFailed(String)
    case statsLoadingFailed(String)
    case videosLoadingFailed(String)
    case performanceLoadingFailed(String)
    case insightsLoadingFailed(String)
    case followingLoadingFailed(String)
    case followActionFailed(String)
    case tipFailed(String)
    case networkError(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .followStatusFailed(let message),
             .statsLoadingFailed(let message),
             .videosLoadingFailed(let message),
             .performanceLoadingFailed(let message),
             .insightsLoadingFailed(let message),
             .followingLoadingFailed(let message),
             .followActionFailed(let message),
             .tipFailed(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .followStatusFailed(let message):
            return "Failed to load follow status: \(message)"
        case .statsLoadingFailed(let message):
            return "Failed to load creator stats: \(message)"
        case .videosLoadingFailed(let message):
            return "Failed to load creator videos: \(message)"
        case .performanceLoadingFailed(let message):
            return "Failed to load performance data: \(message)"
        case .insightsLoadingFailed(let message):
            return "Failed to load insights: \(message)"
        case .followingLoadingFailed(let message):
            return "Failed to load following data: \(message)"
        case .followActionFailed(let message):
            return "Failed to follow/unfollow creator: \(message)"
        case .tipFailed(let message):
            return "Failed to send tip: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

enum VideoPerformanceFilter {
    case all
    case winners
    case losers
    case active
    case recent
}

enum CreatorProfileAnalyticsEvent: String {
    case profileViewed = "creator_profile_viewed"
    case creatorFollowed = "creator_followed"
    case creatorUnfollowed = "creator_unfollowed"
    case tipModalOpened = "tip_modal_opened"
    case tipSent = "tip_sent"
    case creatorShared = "creator_shared"
    case videoWatched = "creator_video_watched"
    case performanceTabViewed = "performance_tab_viewed"
    case insightsTabViewed = "insights_tab_viewed"
}

// MARK: - Service Protocols

protocol SocialService {
    func getFollowStatus(creatorId: String) async throws -> FollowStatus
    func getCreatorStats(creatorId: String) async throws -> CreatorStats
    func followCreator(creatorId: String) async throws
    func unfollowCreator(creatorId: String) async throws
    func sendTip(creatorId: String, amount: Decimal, message: String?) async throws
    func getCreatorFollowing(creatorId: String) async throws -> CreatorFollowingData
}

protocol ContentService {
    func getCreatorVideos(creatorId: String, limit: Int, offset: Int, sortBy: VideoSortOrder) async throws -> [VideoContent]
    func getCreatorVideos(creatorId: String, limit: Int, sortBy: VideoSortOrder) async throws -> [VideoContent]
}

protocol AnalyticsService {
    func getCreatorPerformance(creatorId: String, timeframe: PerformanceTimeframe) async throws -> CreatorPerformanceData
    func getCreatorInsights(creatorId: String) async throws -> CreatorInsights
    func trackEvent(_ eventName: String, properties: [String: Any]) async
}

enum VideoSortOrder {
    case newest
    case oldest
    case mostViewed
    case bestPerforming
    case worstPerforming
}

enum PerformanceTimeframe {
    case oneWeek
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case allTime
}

enum SocialServiceError: Error {
    case followingDataPrivate
    case unauthorized
    case rateLimit
    case serverError
}

// MARK: - Default Implementations

class SocialService: SocialService {
    func getFollowStatus(creatorId: String) async throws -> FollowStatus {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return FollowStatus(
            isFollowing: Bool.random(),
            followedAt: Bool.random() ? Date() : nil,
            notificationsEnabled: true
        )
    }
    
    func getCreatorStats(creatorId: String) async throws -> CreatorStats {
        try await Task.sleep(nanoseconds: 800_000_000)
        return CreatorStats(
            followerCount: Int.random(in: 1000...100000),
            videoCount: Int.random(in: 50...500),
            winRate: Double.random(in: 0.45...0.75),
            averageReturn: Double.random(in: -0.1...0.3),
            totalTips: Decimal.random(in: 100...5000),
            monthlyViews: Int.random(in: 10000...1000000)
        )
    }
    
    func followCreator(creatorId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func unfollowCreator(creatorId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func sendTip(creatorId: String, amount: Decimal, message: String?) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func getCreatorFollowing(creatorId: String) async throws -> CreatorFollowingData {
        try await Task.sleep(nanoseconds: 600_000_000)
        
        if Bool.random() {
            throw SocialServiceError.followingDataPrivate
        }
        
        return CreatorFollowingData(
            creators: [],
            isPublic: true,
            totalCount: Int.random(in: 10...100)
        )
    }
}

class ContentService: ContentService {
    func getCreatorVideos(creatorId: String, limit: Int, offset: Int = 0, sortBy: VideoSortOrder) async throws -> [VideoContent] {
        try await Task.sleep(nanoseconds: 700_000_000)
        // Return sample videos
        return []
    }
    
    func getCreatorVideos(creatorId: String, limit: Int, sortBy: VideoSortOrder) async throws -> [VideoContent] {
        return try await getCreatorVideos(creatorId: creatorId, limit: limit, offset: 0, sortBy: sortBy)
    }
}

class AnalyticsService: AnalyticsService {
    func getCreatorPerformance(creatorId: String, timeframe: PerformanceTimeframe) async throws -> CreatorPerformanceData {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return CreatorPerformanceData(
            dataPoints: [],
            recentTradeCalls: [],
            metrics: RiskMetrics(
                sharpeRatio: Double.random(in: 0.5...2.0),
                maxDrawdown: Double.random(in: -0.3...(-0.05)),
                volatility: Double.random(in: 0.15...0.4),
                betaToMarket: Double.random(in: 0.8...1.5)
            )
        )
    }
    
    func getCreatorInsights(creatorId: String) async throws -> CreatorInsights {
        try await Task.sleep(nanoseconds: 800_000_000)
        return CreatorInsights(
            topSectors: [
                CreatorSector(name: "Technology", percentage: 0.35, averageReturn: 0.12, tradeCount: 25, winRate: 0.68),
                CreatorSector(name: "Healthcare", percentage: 0.25, averageReturn: 0.08, tradeCount: 18, winRate: 0.61),
                CreatorSector(name: "Energy", percentage: 0.20, averageReturn: 0.15, tradeCount: 14, winRate: 0.71),
                CreatorSector(name: "Finance", percentage: 0.20, averageReturn: 0.06, tradeCount: 12, winRate: 0.58)
            ],
            tradingStyle: TradingStyle.defaultStyle,
            riskMetrics: RiskMetrics(
                sharpeRatio: 1.2,
                maxDrawdown: -0.15,
                volatility: 0.22,
                betaToMarket: 1.1
            ),
            consistencyScore: Double.random(in: 0.6...0.9)
        )
    }
    
    func trackEvent(_ eventName: String, properties: [String: Any]) async {
        // Track analytics event
        print("Analytics Event: \(eventName), Properties: \(properties)")
    }
}

extension Decimal {
    static func random(in range: ClosedRange<Double>) -> Decimal {
        return Decimal(Double.random(in: range))
    }
}
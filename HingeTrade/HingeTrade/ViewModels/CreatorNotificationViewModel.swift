//
//  CreatorNotificationViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class CreatorNotificationViewModel: ObservableObject {
    @Published var followingCreators: [Creator] = []
    @Published var recentNotifications: [CreatorNotification] = []
    @Published var trendingCreators: [Creator] = []
    @Published var isLoading = false
    @Published var error: CreatorError?
    @Published var showingError = false
    
    // Statistics
    @Published var followingCount = 0
    @Published var newContentTodayCount = 0
    @Published var unreadNotificationsCount = 0
    @Published var contentThisWeekCount = 0
    
    // Current tab
    private var activeTab: CreatorNotificationsView.CreatorNotificationTab = .following
    
    // Services
    private let notificationService: NotificationService
    private let creatorService: CreatorService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        notificationService: NotificationService = NotificationService.shared,
        creatorService: CreatorService = CreatorService()
    ) {
        self.notificationService = notificationService
        self.creatorService = creatorService
        
        setupBindings()
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        isLoading = true
        error = nil
        
        do {
            async let followingTask = creatorService.getFollowingCreators()
            async let notificationsTask = creatorService.getRecentNotifications()
            async let trendingTask = creatorService.getTrendingCreators()
            
            let (following, notifications, trending) = try await (followingTask, notificationsTask, trendingTask)
            
            self.followingCreators = following
            self.recentNotifications = notifications
            self.trendingCreators = trending
            
            updateStatistics()
            
            // Check for new content that needs notifications
            await checkForNewContent()
            
        } catch {
            self.error = CreatorError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Tab Management
    
    func setActiveTab(_ tab: CreatorNotificationsView.CreatorNotificationTab) {
        activeTab = tab
    }
    
    // MARK: - Creator Management
    
    func followCreator(_ creatorId: String) async {
        do {
            try await creatorService.followCreator(creatorId)
            
            // Refresh following list
            followingCreators = try await creatorService.getFollowingCreators()
            updateStatistics()
            
        } catch {
            self.error = CreatorError.followFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func unfollowCreator(_ creatorId: String) async {
        do {
            try await creatorService.unfollowCreator(creatorId)
            
            // Remove from following list
            followingCreators.removeAll { $0.id == creatorId }
            updateStatistics()
            
        } catch {
            self.error = CreatorError.unfollowFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    func toggleCreatorNotifications(_ creatorId: String) async {
        do {
            try await creatorService.toggleNotifications(for: creatorId)
            
            // Update local state
            if let index = followingCreators.firstIndex(where: { $0.id == creatorId }) {
                followingCreators[index].notificationsEnabled.toggle()
            }
            
        } catch {
            self.error = CreatorError.notificationToggleFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    // MARK: - Notification Management
    
    func markNotificationAsRead(_ notificationId: String) {
        if let index = recentNotifications.firstIndex(where: { $0.id == notificationId }) {
            recentNotifications[index].isRead = true
            updateStatistics()
        }
        
        // Also mark in the notification service
        notificationService.markNotificationAsRead("video-\(notificationId)")
    }
    
    func markAllNotificationsAsRead() {
        for index in recentNotifications.indices {
            recentNotifications[index].isRead = true
        }
        updateStatistics()
    }
    
    private func checkForNewContent() async {
        let unreadNotifications = recentNotifications.filter { !$0.isRead }
        
        for notification in unreadNotifications.prefix(3) { // Limit to prevent spam
            await sendCreatorContentNotification(for: notification)
        }
    }
    
    private func sendCreatorContentNotification(for notification: CreatorNotification) async {
        // Create a VideoContent object from the notification
        let videoContent = VideoContent(
            id: notification.contentId ?? UUID().uuidString,
            title: notification.title,
            description: notification.description,
            thumbnailURL: notification.thumbnailURL ?? "",
            videoURL: "https://example.com/video.mp4", // Placeholder
            creator: notification.creator,
            duration: 300, // 5 minutes placeholder
            viewCount: 0,
            likeCount: 0,
            publishedAt: notification.timestamp,
            tickers: [],
            tags: [],
            isLive: false,
            category: .general
        )
        
        do {
            try await notificationService.scheduleCreatorContentNotification(videoContent)
        } catch {
            print("Failed to send creator content notification: \(error)")
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Check for new creator content every 5 minutes
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkForNewCreatorContent()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkForNewCreatorContent() async {
        // In a real app, this would check for new content from followed creators
        // For demo purposes, simulate new content occasionally
        guard !followingCreators.isEmpty else { return }
        
        if Bool.random() { // 50% chance
            let randomCreator = followingCreators.randomElement()!
            await simulateNewContent(from: randomCreator)
        }
    }
    
    private func simulateNewContent(from creator: Creator) async {
        let newNotification = CreatorNotification(
            id: UUID().uuidString,
            creator: creator,
            title: "New Trading Strategy Video",
            description: "Just posted my latest analysis on market trends",
            thumbnailURL: creator.profileImageURL,
            timestamp: Date(),
            isRead: false,
            contentId: UUID().uuidString,
            contentType: .video
        )
        
        recentNotifications.insert(newNotification, at: 0)
        
        // Mark creator as having new content
        if let index = followingCreators.firstIndex(where: { $0.id == creator.id }) {
            followingCreators[index].hasNewContent = true
        }
        
        updateStatistics()
        
        // Send notification if enabled for this creator
        if creator.notificationsEnabled {
            await sendCreatorContentNotification(for: newNotification)
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        followingCount = followingCreators.count
        unreadNotificationsCount = recentNotifications.filter { !$0.isRead }.count
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        // Count content from today
        newContentTodayCount = recentNotifications.filter { notification in
            calendar.startOfDay(for: notification.timestamp) == today
        }.count
        
        // Count content from this week
        contentThisWeekCount = recentNotifications.filter { notification in
            notification.timestamp >= weekAgo
        }.count
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
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
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Creator Service

protocol CreatorService {
    func getFollowingCreators() async throws -> [Creator]
    func getRecentNotifications() async throws -> [CreatorNotification]
    func getTrendingCreators() async throws -> [Creator]
    func followCreator(_ id: String) async throws
    func unfollowCreator(_ id: String) async throws
    func toggleNotifications(for creatorId: String) async throws
}

class CreatorService: CreatorService {
    func getFollowingCreators() async throws -> [Creator] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return [
            Creator(
                id: "creator-1",
                username: "tradingpro",
                displayName: "Trading Pro",
                bio: "Professional trader sharing daily market insights and strategies",
                profileImageURL: "https://example.com/avatar1.jpg",
                isVerified: true,
                followersCount: 125000,
                totalVideos: 450,
                notificationsEnabled: true,
                hasNewContent: true
            ),
            Creator(
                id: "creator-2",
                username: "stockwhiz",
                displayName: "Stock Whiz",
                bio: "Teaching options trading and technical analysis to retail investors",
                profileImageURL: "https://example.com/avatar2.jpg",
                isVerified: true,
                followersCount: 89000,
                totalVideos: 320,
                notificationsEnabled: false,
                hasNewContent: false
            ),
            Creator(
                id: "creator-3",
                username: "cryptoking",
                displayName: "Crypto King",
                bio: "Cryptocurrency expert covering DeFi, NFTs, and blockchain technology",
                profileImageURL: "https://example.com/avatar3.jpg",
                isVerified: false,
                followersCount: 67000,
                totalVideos: 280,
                notificationsEnabled: true,
                hasNewContent: true
            )
        ]
    }
    
    func getRecentNotifications() async throws -> [CreatorNotification] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let creators = try await getFollowingCreators()
        
        return [
            CreatorNotification(
                id: "notif-1",
                creator: creators[0],
                title: "Market Analysis: Tech Stocks Rally",
                description: "Breaking down today's tech stock surge and what it means for your portfolio",
                thumbnailURL: "https://example.com/thumb1.jpg",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false,
                contentId: "video-1",
                contentType: .video
            ),
            CreatorNotification(
                id: "notif-2",
                creator: creators[2],
                title: "Bitcoin Weekly Update",
                description: "Latest developments in the crypto space and price predictions",
                thumbnailURL: "https://example.com/thumb2.jpg",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true,
                contentId: "video-2",
                contentType: .video
            ),
            CreatorNotification(
                id: "notif-3",
                creator: creators[0],
                title: "Live Trading Session",
                description: "Join me for a live trading session starting in 10 minutes",
                thumbnailURL: "https://example.com/thumb3.jpg",
                timestamp: Date().addingTimeInterval(-10800),
                isRead: false,
                contentId: "live-1",
                contentType: .liveStream
            )
        ]
    }
    
    func getTrendingCreators() async throws -> [Creator] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 700_000_000)
        
        return [
            Creator(
                id: "trending-1",
                username: "daytradermax",
                displayName: "Day Trader Max",
                bio: "Day trading strategies and real-time market analysis",
                profileImageURL: "https://example.com/trending1.jpg",
                isVerified: false,
                followersCount: 45000,
                totalVideos: 180,
                notificationsEnabled: false,
                hasNewContent: false
            ),
            Creator(
                id: "trending-2",
                username: "optionsqueen",
                displayName: "Options Queen",
                bio: "Options trading education and weekly market outlooks",
                profileImageURL: "https://example.com/trending2.jpg",
                isVerified: true,
                followersCount: 78000,
                totalVideos: 220,
                notificationsEnabled: false,
                hasNewContent: false
            )
        ]
    }
    
    func followCreator(_ id: String) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func unfollowCreator(_ id: String) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 400_000_000)
    }
    
    func toggleNotifications(for creatorId: String) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}

// MARK: - Models

struct CreatorNotification: Identifiable {
    let id: String
    let creator: Creator
    let title: String
    let description: String?
    let thumbnailURL: String?
    let timestamp: Date
    var isRead: Bool
    let contentId: String?
    let contentType: CreatorContentType
}

enum CreatorContentType {
    case video
    case liveStream
    case post
    case announcement
}

extension Creator {
    var hasNewContent: Bool {
        get {
            // This would typically be stored in the creator data
            // For demo purposes, we'll simulate this
            return Bool.random()
        }
        set {
            // In a real implementation, this would update the creator record
        }
    }
    
    var notificationsEnabled: Bool {
        get {
            // This would typically be stored in user preferences
            // For demo purposes, we'll simulate this
            return true
        }
        set {
            // In a real implementation, this would update user preferences
        }
    }
}

// MARK: - Error Types

enum CreatorError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case followFailed(String)
    case unfollowFailed(String)
    case notificationToggleFailed(String)
    case unauthorized
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .followFailed(let message),
             .unfollowFailed(let message),
             .notificationToggleFailed(let message):
            return message
        case .unauthorized:
            return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load creator data: \(message)"
        case .followFailed(let message):
            return "Failed to follow creator: \(message)"
        case .unfollowFailed(let message):
            return "Failed to unfollow creator: \(message)"
        case .notificationToggleFailed(let message):
            return "Failed to update notification settings: \(message)"
        case .unauthorized:
            return "You are not authorized to access creator features"
        }
    }
}
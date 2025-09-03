//
//  MarketNewsAlertsViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class MarketNewsAlertsViewModel: ObservableObject {
    @Published var newsItems: [MarketNewsItem] = []
    @Published var filteredNewsItems: [MarketNewsItem] = []
    @Published var isLoading = false
    @Published var error: NewsError?
    @Published var showingError = false
    
    // Statistics
    @Published var todayNewsCount = 0
    @Published var breakingNewsCount = 0
    @Published var unreadNewsCount = 0
    @Published var watchlistNewsCount = 0
    
    // Current filter
    private var currentCategory: MarketNewsAlertsView.NewsCategory = .all
    
    // Services
    private let notificationService: NotificationService
    private let newsService: DefaultNewsService
    
    // User preferences
    @Published var enabledCategories: Set<MarketNewsItem.NewsCategory> = Set(MarketNewsItem.NewsCategory.allCases)
    @Published var minimumImportance: MarketNewsItem.NewsImportance = .medium
    @Published var watchlistSymbols: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        notificationService: NotificationService = NotificationService.shared,
        newsService: DefaultNewsService = DefaultNewsService()
    ) {
        self.notificationService = notificationService
        self.newsService = newsService
        
        setupBindings()
        setupRealTimeUpdates()
    }
    
    // MARK: - Data Loading
    
    func loadNewsItems() async {
        isLoading = true
        error = nil
        
        do {
            let loadedNews = try await newsService.getMarketNews()
            self.newsItems = loadedNews
            
            updateStatistics()
            applyFilter()
            
            // Check for news items that need notifications
            await checkForNewNews()
            
        } catch {
            self.error = NewsError.loadingFailed(error.localizedDescription)
            self.showingError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    
    func setCategory(_ category: MarketNewsAlertsView.NewsCategory) {
        currentCategory = category
        applyFilter()
    }
    
    private func applyFilter() {
        switch currentCategory {
        case .all:
            filteredNewsItems = newsItems
        case .breaking:
            filteredNewsItems = newsItems.filter { $0.importance == .high }
        case .earnings:
            filteredNewsItems = newsItems.filter { $0.category == .earnings }
        case .economicData:
            filteredNewsItems = newsItems.filter { $0.category == .economicData }
        case .companyNews:
            filteredNewsItems = newsItems.filter { $0.category == .companyNews }
        case .marketMovers:
            filteredNewsItems = newsItems.filter { $0.category == .marketMovers }
        case .sectorNews:
            filteredNewsItems = newsItems.filter { $0.category == .sectorNews }
        case .regulatory:
            filteredNewsItems = newsItems.filter { $0.category == .regulatory }
        }
        
        // Sort by importance first, then by publish date
        filteredNewsItems.sort { item1, item2 in
            if item1.importance != item2.importance {
                return item1.importance.sortOrder < item2.importance.sortOrder
            }
            return item1.publishedAt > item2.publishedAt
        }
    }
    
    func getCount(for category: MarketNewsAlertsView.NewsCategory) -> Int {
        switch category {
        case .all:
            return newsItems.count
        case .breaking:
            return newsItems.filter { $0.importance == .high }.count
        case .earnings:
            return newsItems.filter { $0.category == .earnings }.count
        case .economicData:
            return newsItems.filter { $0.category == .economicData }.count
        case .companyNews:
            return newsItems.filter { $0.category == .companyNews }.count
        case .marketMovers:
            return newsItems.filter { $0.category == .marketMovers }.count
        case .sectorNews:
            return newsItems.filter { $0.category == .sectorNews }.count
        case .regulatory:
            return newsItems.filter { $0.category == .regulatory }.count
        }
    }
    
    // MARK: - News Management
    
    func markNewsAsRead(_ newsId: String) {
        if let index = newsItems.firstIndex(where: { $0.id == newsId }) {
            newsItems[index].isRead = true
            updateStatistics()
        }
        
        // Also mark in notification service
        notificationService.markNotificationAsRead("news-\(newsId)")
    }
    
    func markAllNewsAsRead() {
        for index in newsItems.indices {
            newsItems[index].isRead = true
        }
        updateStatistics()
    }
    
    private func checkForNewNews() async {
        let newNewsItems = newsItems.filter { newsItem in
            !newsItem.isRead &&
            shouldSendNotificationFor(newsItem) &&
            !newsItem.notificationSent
        }
        
        for newsItem in newNewsItems.prefix(5) { // Limit to prevent spam
            await sendNewsNotification(for: newsItem)
        }
    }
    
    private func shouldSendNotificationFor(_ newsItem: MarketNewsItem) -> Bool {
        // Check if category is enabled
        guard enabledCategories.contains(newsItem.category) else { return false }
        
        // Check if importance meets minimum threshold
        guard newsItem.importance.sortOrder <= minimumImportance.sortOrder else { return false }
        
        // Check if related to watchlist symbols
        if !watchlistSymbols.isEmpty {
            let hasWatchlistSymbol = !Set(newsItem.relatedSymbols).isDisjoint(with: Set(watchlistSymbols))
            if !hasWatchlistSymbol && newsItem.importance != .high {
                return false
            }
        }
        
        return true
    }
    
    private func sendNewsNotification(for newsItem: MarketNewsItem) async {
        do {
            try await notificationService.scheduleMarketNewsAlert(newsItem)
            
            // Mark notification as sent
            if let index = newsItems.firstIndex(where: { $0.id == newsItem.id }) {
                newsItems[index].notificationSent = true
            }
            
        } catch {
            print("Failed to send news notification: \(error)")
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Check for new news every 2 minutes
        Timer.publish(every: 120, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkForNewNewsUpdates()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkForNewNewsUpdates() async {
        // In a real app, this would fetch only new news since last update
        // For demo purposes, simulate new breaking news occasionally
        if Bool.random() && Bool.random() { // 25% chance
            await simulateBreakingNews()
        }
    }
    
    private func simulateBreakingNews() async {
        let breakingNews = MarketNewsItem(
            id: UUID().uuidString,
            headline: "Breaking: Major Market Development",
            summary: "Significant market event affecting multiple sectors and investor sentiment.",
            content: nil,
            source: "Market Wire",
            publishedAt: Date(),
            relatedSymbols: ["AAPL", "MSFT", "GOOGL"],
            category: .marketMovers,
            imageURL: nil,
            importance: .high
        )
        
        newsItems.insert(breakingNews, at: 0)
        updateStatistics()
        applyFilter()
        
        // Send immediate notification for breaking news
        if shouldSendNotificationFor(breakingNews) {
            await sendNewsNotification(for: breakingNews)
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Count news from today
        todayNewsCount = newsItems.filter { newsItem in
            calendar.startOfDay(for: newsItem.publishedAt) == today
        }.count
        
        // Count breaking news (high importance)
        breakingNewsCount = newsItems.filter { $0.importance == .high }.count
        
        // Count unread news
        unreadNewsCount = newsItems.filter { !$0.isRead }.count
        
        // Count news related to watchlist symbols
        watchlistNewsCount = newsItems.filter { newsItem in
            !Set(newsItem.relatedSymbols).isDisjoint(with: Set(watchlistSymbols))
        }.count
    }
    
    // MARK: - Preferences
    
    func updateCategoryPreferences(_ categories: Set<MarketNewsItem.NewsCategory>) {
        enabledCategories = categories
        // In a real app, this would persist to user defaults or server
    }
    
    func updateImportanceThreshold(_ importance: MarketNewsItem.NewsImportance) {
        minimumImportance = importance
        // In a real app, this would persist to user defaults or server
    }
    
    func updateWatchlistSymbols(_ symbols: [String]) {
        watchlistSymbols = symbols
        updateStatistics()
        // In a real app, this would persist to user defaults or server
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

// MARK: - News Service

protocol NewsService {
    func getMarketNews() async throws -> [MarketNewsItem]
    func getNewsItem(id: String) async throws -> MarketNewsItem?
}

class DefaultNewsService: NewsService {
    func getMarketNews() async throws -> [MarketNewsItem] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_200_000_000)
        
        return [
            MarketNewsItem(
                id: "news-1",
                headline: "Fed Announces Interest Rate Decision",
                summary: "Federal Reserve keeps rates unchanged, signals potential cuts in coming months based on inflation data and economic indicators.",
                content: "The Federal Reserve announced today that it will maintain current interest rates...",
                source: "Federal Reserve",
                publishedAt: Date().addingTimeInterval(-3600),
                relatedSymbols: ["SPY", "QQQ", "IWM"],
                category: .economicData,
                imageURL: "https://example.com/fed-news.jpg",
                importance: .high
            ),
            MarketNewsItem(
                id: "news-2",
                headline: "Apple Reports Strong Quarterly Earnings",
                summary: "Apple Inc. beats earnings expectations with strong iPhone sales and services revenue growth exceeding analyst forecasts.",
                content: "Apple Inc. reported quarterly earnings that exceeded Wall Street expectations...",
                source: "MarketWatch",
                publishedAt: Date().addingTimeInterval(-7200),
                relatedSymbols: ["AAPL"],
                category: .earnings,
                imageURL: "https://example.com/apple-earnings.jpg",
                importance: .medium
            ),
            MarketNewsItem(
                id: "news-3",
                headline: "Tech Sector Leads Market Rally",
                summary: "Technology stocks surge as investors show renewed confidence in growth stocks amid positive earnings reports.",
                content: "The technology sector led a broad market rally today...",
                source: "Bloomberg",
                publishedAt: Date().addingTimeInterval(-10800),
                relatedSymbols: ["MSFT", "GOOGL", "META", "NVDA"],
                category: .marketMovers,
                imageURL: "https://example.com/tech-rally.jpg",
                importance: .medium
            ),
            MarketNewsItem(
                id: "news-4",
                headline: "New SEC Regulations for Crypto Trading",
                summary: "Securities and Exchange Commission introduces new framework for cryptocurrency trading platforms and investor protection measures.",
                content: "The SEC announced comprehensive new regulations...",
                source: "SEC",
                publishedAt: Date().addingTimeInterval(-14400),
                relatedSymbols: ["COIN", "MSTR"],
                category: .regulatory,
                imageURL: nil,
                importance: .high
            ),
            MarketNewsItem(
                id: "news-5",
                headline: "Energy Sector Sees Mixed Performance",
                summary: "Oil and gas companies show varied results as crude prices fluctuate amid global supply concerns and demand projections.",
                content: "The energy sector experienced mixed performance today...",
                source: "Energy News",
                publishedAt: Date().addingTimeInterval(-18000),
                relatedSymbols: ["XOM", "CVX", "COP"],
                category: .sectorNews,
                imageURL: "https://example.com/energy-sector.jpg",
                importance: .low
            )
        ]
    }
    
    func getNewsItem(id: String) async throws -> MarketNewsItem? {
        let allNews = try await getMarketNews()
        return allNews.first { $0.id == id }
    }
}

// MARK: - Extensions

extension MarketNewsItem {
    var isRead: Bool {
        get {
            // This would typically be stored in the news data or user preferences
            // For demo purposes, simulate some read status
            return Bool.random()
        }
        set {
            // In a real implementation, this would update the news record
        }
    }
    
    var notificationSent: Bool {
        get {
            // This would typically be stored in the news data
            // For demo purposes, simulate notification status
            return false
        }
        set {
            // In a real implementation, this would update the news record
        }
    }
}

extension MarketNewsItem.NewsImportance {
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Error Types

enum NewsError: LocalizedError, Identifiable {
    case loadingFailed(String)
    case newsNotFound(String)
    case notificationFailed(String)
    case unauthorized
    
    var id: String {
        switch self {
        case .loadingFailed(let message),
             .newsNotFound(let message),
             .notificationFailed(let message):
            return message
        case .unauthorized:
            return "unauthorized"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load news: \(message)"
        case .newsNotFound(let message):
            return "News item not found: \(message)"
        case .notificationFailed(let message):
            return "Failed to send notification: \(message)"
        case .unauthorized:
            return "You are not authorized to access news alerts"
        }
    }
}
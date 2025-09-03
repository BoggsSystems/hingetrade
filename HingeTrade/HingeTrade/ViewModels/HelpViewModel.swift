//
//  HelpViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class HelpViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var helpCategories: [HelpCategory] = []
    @Published var allArticles: [HelpArticle] = []
    @Published var searchResults: [HelpArticle] = []
    @Published var isLoading = false
    @Published var error: HelpError?
    @Published var showingError = false
    
    // Services
    private let helpService: HelpService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(helpService: HelpService = DefaultHelpService()) {
        self.helpService = helpService
        setupBindings()
    }
    
    // MARK: - Data Loading
    
    func loadHelpContent() async {
        isLoading = true
        
        do {
            async let categoriesLoad = helpService.loadHelpCategories()
            async let articlesLoad = helpService.loadHelpArticles()
            
            helpCategories = try await categoriesLoad
            allArticles = try await articlesLoad
            
            isLoading = false
            
        } catch {
            await MainActor.run {
                self.error = HelpError.loadFailed(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Category Management
    
    func getArticles(for category: HelpCategory) -> [HelpArticle] {
        return allArticles.filter { $0.category == category }
    }
    
    func getArticleCount(for category: HelpCategory) -> Int {
        return getArticles(for: category).count
    }
    
    func getPopularArticles() -> [HelpArticle] {
        return allArticles.filter { $0.isPopular }.sorted { $0.readingTimeMinutes < $1.readingTimeMinutes }
    }
    
    func getRecentArticles() -> [HelpArticle] {
        return allArticles.filter { $0.isNew }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Search Functionality
    
    func searchArticles(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        let lowercaseQuery = query.lowercased()
        
        searchResults = allArticles.filter { article in
            article.title.lowercased().contains(lowercaseQuery) ||
            article.summary.lowercased().contains(lowercaseQuery) ||
            article.content.lowercased().contains(lowercaseQuery) ||
            article.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
        .sorted { first, second in
            // Prioritize title matches
            let firstTitleMatch = first.title.lowercased().contains(lowercaseQuery)
            let secondTitleMatch = second.title.lowercased().contains(lowercaseQuery)
            
            if firstTitleMatch && !secondTitleMatch {
                return true
            } else if !firstTitleMatch && secondTitleMatch {
                return false
            } else {
                // Sort by popularity, then by reading time
                if first.isPopular && !second.isPopular {
                    return true
                } else if !first.isPopular && second.isPopular {
                    return false
                } else {
                    return first.readingTimeMinutes < second.readingTimeMinutes
                }
            }
        }
    }
    
    func clearSearch() {
        searchResults = []
    }
    
    // MARK: - Article Actions
    
    func markArticleAsViewed(_ article: HelpArticle) {
        // In a real implementation, this would track analytics
        Task {
            await helpService.trackArticleView(article.id)
        }
    }
    
    func rateArticle(_ article: HelpArticle, rating: Int) {
        Task {
            try? await helpService.submitArticleRating(article.id, rating: rating)
        }
    }
    
    func reportArticleIssue(_ article: HelpArticle, issue: String) {
        Task {
            try? await helpService.reportArticleIssue(article.id, issue: issue)
        }
    }
    
    // MARK: - Quick Actions
    
    func getQuickActions() -> [QuickAction] {
        return [
            QuickAction(
                title: "Contact Support",
                icon: "person.2.fill"
            ) {
                // Handle contact support
            },
            
            QuickAction(
                title: "Trading Guide",
                icon: "book.fill"
            ) {
                // Navigate to trading guide
            },
            
            QuickAction(
                title: "Account Setup",
                icon: "gearshape.fill"
            ) {
                // Navigate to account setup
            },
            
            QuickAction(
                title: "Risk Management",
                icon: "shield.fill"
            ) {
                // Navigate to risk management help
            }
        ]
    }
    
    // MARK: - Error Handling
    
    func dismissError() {
        error = nil
        showingError = false
    }
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Models

enum HelpCategory: String, CaseIterable, Codable {
    case gettingStarted = "getting_started"
    case trading = "trading"
    case portfolio = "portfolio"
    case analytics = "analytics"
    case riskManagement = "risk_management"
    case account = "account"
    case technical = "technical"
    case troubleshooting = "troubleshooting"
    
    var displayName: String {
        switch self {
        case .gettingStarted: return "Getting Started"
        case .trading: return "Trading"
        case .portfolio: return "Portfolio"
        case .analytics: return "Analytics"
        case .riskManagement: return "Risk Management"
        case .account: return "Account"
        case .technical: return "Technical"
        case .troubleshooting: return "Troubleshooting"
        }
    }
    
    var description: String {
        switch self {
        case .gettingStarted:
            return "Learn the basics and get started with HingeTrade"
        case .trading:
            return "Trading strategies, order types, and execution"
        case .portfolio:
            return "Managing your portfolio and tracking performance"
        case .analytics:
            return "Understanding charts, indicators, and analysis tools"
        case .riskManagement:
            return "Protecting your investments and managing risk"
        case .account:
            return "Account settings, security, and preferences"
        case .technical:
            return "Technical analysis tools and advanced features"
        case .troubleshooting:
            return "Common issues and their solutions"
        }
    }
    
    var icon: String {
        switch self {
        case .gettingStarted: return "star.fill"
        case .trading: return "chart.line.uptrend.xyaxis"
        case .portfolio: return "briefcase.fill"
        case .analytics: return "chart.bar.fill"
        case .riskManagement: return "shield.fill"
        case .account: return "person.fill"
        case .technical: return "wrench.and.screwdriver.fill"
        case .troubleshooting: return "exclamationmark.triangle.fill"
        }
    }
}

struct HelpArticle: Identifiable, Codable {
    let id: String
    let title: String
    let summary: String
    let content: String
    let category: HelpCategory
    let tags: [String]
    let readingTimeMinutes: Int
    let isPopular: Bool
    let isNew: Bool
    let createdAt: Date
    let updatedAt: Date
    let authorName: String
    let difficulty: DifficultyLevel
    let relatedArticleIds: [String]
    
    enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        
        var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            }
        }
        
        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }
}

// MARK: - Help Service

protocol HelpService {
    func loadHelpCategories() async throws -> [HelpCategory]
    func loadHelpArticles() async throws -> [HelpArticle]
    func getArticle(by id: String) async throws -> HelpArticle?
    func trackArticleView(_ articleId: String) async
    func submitArticleRating(_ articleId: String, rating: Int) async throws
    func reportArticleIssue(_ articleId: String, issue: String) async throws
}

class DefaultHelpService: HelpService {
    
    func loadHelpCategories() async throws -> [HelpCategory] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        return HelpCategory.allCases
    }
    
    func loadHelpArticles() async throws -> [HelpArticle] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return createMockArticles()
    }
    
    func getArticle(by id: String) async throws -> HelpArticle? {
        let articles = try await loadHelpArticles()
        return articles.first { $0.id == id }
    }
    
    func trackArticleView(_ articleId: String) async {
        // Track article view analytics
        print("Article viewed: \(articleId)")
    }
    
    func submitArticleRating(_ articleId: String, rating: Int) async throws {
        // Submit rating to backend
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Article \(articleId) rated: \(rating)")
    }
    
    func reportArticleIssue(_ articleId: String, issue: String) async throws {
        // Report issue to support system
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Issue reported for article \(articleId): \(issue)")
    }
    
    // MARK: - Mock Data
    
    private func createMockArticles() -> [HelpArticle] {
        return [
            // Getting Started Articles
            HelpArticle(
                id: "getting-started-1",
                title: "Welcome to HingeTrade",
                summary: "Learn the basics of using HingeTrade for Apple TV",
                content: "HingeTrade brings professional trading to your Apple TV...",
                category: .gettingStarted,
                tags: ["welcome", "basics", "introduction"],
                readingTimeMinutes: 3,
                isPopular: true,
                isNew: true,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                updatedAt: Date(),
                authorName: "HingeTrade Team",
                difficulty: .beginner,
                relatedArticleIds: ["getting-started-2", "account-1"]
            ),
            
            HelpArticle(
                id: "getting-started-2",
                title: "Setting Up Your First Watchlist",
                summary: "Create and customize your first stock watchlist",
                content: "Watchlists help you track your favorite stocks...",
                category: .gettingStarted,
                tags: ["watchlist", "stocks", "setup"],
                readingTimeMinutes: 5,
                isPopular: true,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!,
                updatedAt: Date(),
                authorName: "Sarah Johnson",
                difficulty: .beginner,
                relatedArticleIds: ["portfolio-1", "trading-1"]
            ),
            
            // Trading Articles
            HelpArticle(
                id: "trading-1",
                title: "Understanding Order Types",
                summary: "Learn about market orders, limit orders, and stop orders",
                content: "Different order types serve different purposes in trading...",
                category: .trading,
                tags: ["orders", "market", "limit", "stop"],
                readingTimeMinutes: 8,
                isPopular: true,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date())!,
                updatedAt: Date(),
                authorName: "Michael Chen",
                difficulty: .intermediate,
                relatedArticleIds: ["trading-2", "risk-1"]
            ),
            
            HelpArticle(
                id: "trading-2",
                title: "Advanced Order Strategies",
                summary: "Bracket orders, trailing stops, and conditional orders",
                content: "Advanced order types provide more sophisticated trading strategies...",
                category: .trading,
                tags: ["advanced", "bracket", "trailing", "conditional"],
                readingTimeMinutes: 12,
                isPopular: false,
                isNew: true,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                updatedAt: Date(),
                authorName: "David Rodriguez",
                difficulty: .advanced,
                relatedArticleIds: ["trading-1", "risk-2"]
            ),
            
            // Portfolio Articles
            HelpArticle(
                id: "portfolio-1",
                title: "Portfolio Performance Metrics",
                summary: "Understanding returns, volatility, and risk metrics",
                content: "Track your portfolio's performance with key metrics...",
                category: .portfolio,
                tags: ["performance", "metrics", "returns", "volatility"],
                readingTimeMinutes: 6,
                isPopular: true,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date())!,
                updatedAt: Date(),
                authorName: "Emily Davis",
                difficulty: .intermediate,
                relatedArticleIds: ["analytics-1", "risk-1"]
            ),
            
            // Risk Management Articles
            HelpArticle(
                id: "risk-1",
                title: "Position Sizing Basics",
                summary: "How to determine appropriate position sizes for your trades",
                content: "Proper position sizing is crucial for risk management...",
                category: .riskManagement,
                tags: ["position", "sizing", "risk", "management"],
                readingTimeMinutes: 7,
                isPopular: true,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date())!,
                updatedAt: Date(),
                authorName: "James Wilson",
                difficulty: .intermediate,
                relatedArticleIds: ["trading-1", "risk-2"]
            ),
            
            HelpArticle(
                id: "risk-2",
                title: "Stop Loss Strategies",
                summary: "Different approaches to setting and managing stop losses",
                content: "Stop losses are essential tools for protecting your capital...",
                category: .riskManagement,
                tags: ["stop", "loss", "protection", "strategies"],
                readingTimeMinutes: 9,
                isPopular: false,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                updatedAt: Date(),
                authorName: "Lisa Garcia",
                difficulty: .advanced,
                relatedArticleIds: ["risk-1", "trading-2"]
            ),
            
            // Analytics Articles
            HelpArticle(
                id: "analytics-1",
                title: "Reading Stock Charts",
                summary: "Understanding candlesticks, trends, and technical indicators",
                content: "Charts provide valuable insights into stock price movements...",
                category: .analytics,
                tags: ["charts", "candlesticks", "technical", "analysis"],
                readingTimeMinutes: 10,
                isPopular: true,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .weekOfYear, value: -5, to: Date())!,
                updatedAt: Date(),
                authorName: "Robert Kim",
                difficulty: .intermediate,
                relatedArticleIds: ["analytics-2", "technical-1"]
            ),
            
            // Account Articles
            HelpArticle(
                id: "account-1",
                title: "Account Security Best Practices",
                summary: "Keeping your trading account secure",
                content: "Security is paramount when trading online...",
                category: .account,
                tags: ["security", "account", "protection", "safety"],
                readingTimeMinutes: 4,
                isPopular: true,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
                updatedAt: Date(),
                authorName: "Amanda Taylor",
                difficulty: .beginner,
                relatedArticleIds: ["account-2"]
            ),
            
            // Troubleshooting Articles
            HelpArticle(
                id: "troubleshooting-1",
                title: "Connection Issues",
                summary: "Resolving network and connection problems",
                content: "If you're experiencing connection issues...",
                category: .troubleshooting,
                tags: ["connection", "network", "issues", "troubleshooting"],
                readingTimeMinutes: 5,
                isPopular: false,
                isNew: false,
                createdAt: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                updatedAt: Date(),
                authorName: "Tech Support",
                difficulty: .beginner,
                relatedArticleIds: ["troubleshooting-2"]
            )
        ]
    }
}

// MARK: - Error Types

enum HelpError: LocalizedError, Identifiable {
    case loadFailed(String)
    case networkError(String)
    case articleNotFound(String)
    case searchFailed(String)
    
    var id: String {
        switch self {
        case .loadFailed(let message),
             .networkError(let message),
             .articleNotFound(let message),
             .searchFailed(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load help content: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .articleNotFound(let message):
            return "Article not found: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        }
    }
}
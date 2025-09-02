//
//  VideoContent.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation

struct VideoContent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let thumbnailURL: String
    let videoURL: String
    let duration: TimeInterval
    let publishedAt: Date
    let creator: Creator
    let symbols: [String]
    let category: VideoCategory
    let tags: [String]
    let viewCount: Int
    let likeCount: Int
    let isSponsored: Bool
    let sponsorInfo: SponsorInfo?
    
    // Market-related metadata
    let marketDirection: MarketDirection?
    let priceTargets: [PriceTarget]
    let riskLevel: RiskLevel
    let timeHorizon: TimeHorizon
    
    // Video analytics
    let averageWatchTime: TimeInterval
    let clickThroughRate: Double
    let tradingConversionRate: Double
    
    // AI-generated insights
    let keyTakeaways: [String]
    let transcript: String?
    let aiSummary: String?
    
    enum MarketDirection: String, Codable, CaseIterable {
        case bullish
        case bearish
        case neutral
        
        var displayName: String {
            switch self {
            case .bullish: return "Bullish"
            case .bearish: return "Bearish"
            case .neutral: return "Neutral"
            }
        }
        
        var color: Color {
            switch self {
            case .bullish: return .green
            case .bearish: return .red
            case .neutral: return .gray
            }
        }
        
        var systemImage: String {
            switch self {
            case .bullish: return "arrow.up.right"
            case .bearish: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
    }
    
    enum RiskLevel: String, Codable, CaseIterable {
        case conservative
        case moderate
        case aggressive
        case speculative
        
        var displayName: String {
            switch self {
            case .conservative: return "Conservative"
            case .moderate: return "Moderate"
            case .aggressive: return "Aggressive"  
            case .speculative: return "Speculative"
            }
        }
        
        var color: Color {
            switch self {
            case .conservative: return .green
            case .moderate: return .blue
            case .aggressive: return .orange
            case .speculative: return .red
            }
        }
    }
    
    enum TimeHorizon: String, Codable, CaseIterable {
        case intraday
        case shortTerm // 1-4 weeks
        case mediumTerm // 1-6 months
        case longTerm // 6+ months
        
        var displayName: String {
            switch self {
            case .intraday: return "Intraday"
            case .shortTerm: return "Short Term"
            case .mediumTerm: return "Medium Term"
            case .longTerm: return "Long Term"
            }
        }
    }
}

// MARK: - Creator

struct Creator: Identifiable, Codable {
    let id: String
    let displayName: String
    let username: String
    let avatarURL: String
    let isVerified: Bool
    let followerCount: Int
    let totalViews: Int
    let joinedDate: Date
    let expertise: [String]
    let trackRecord: TrackRecord?
    
    struct TrackRecord: Codable {
        let accuracyRate: Double
        let totalPredictions: Int
        let avgReturn: Double
        let bestCall: String?
        let worstCall: String?
    }
}

// MARK: - VideoCategory

struct VideoCategory: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let description: String
    let systemImage: String
    let color: Color
    let sortOrder: Int
    
    static let topMovers = VideoCategory(
        id: "top-movers",
        name: "topMovers",
        displayName: "Top Movers Today",
        description: "AI-generated recaps of biggest gainers and losers",
        systemImage: "chart.line.uptrend.xyaxis",
        color: .green,
        sortOrder: 1
    )
    
    static let earningsInFocus = VideoCategory(
        id: "earnings",
        name: "earnings",
        displayName: "Earnings in Focus",
        displayName: "Latest quarterly results analysis",
        systemImage: "chart.bar.doc.horizontal",
        color: .blue,
        sortOrder: 2
    )
    
    static let cryptoPulse = VideoCategory(
        id: "crypto",
        name: "crypto",
        displayName: "Crypto Pulse",
        description: "Bitcoin, Ethereum, and altcoin updates",
        systemImage: "bitcoinsign.circle",
        color: .orange,
        sortOrder: 3
    )
    
    static let educationalShorts = VideoCategory(
        id: "education",
        name: "education",
        displayName: "Educational Shorts",
        description: "Learn RSI, MACD, options, and more",
        systemImage: "graduationcap",
        color: .purple,
        sortOrder: 4
    )
    
    static let creatorSpotlights = VideoCategory(
        id: "creators",
        name: "creators",
        displayName: "Creator Spotlights",
        description: "Hand-picked finance influencers and analysts",
        systemImage: "person.2.crop.square.stack",
        color: .pink,
        sortOrder: 5
    )
    
    static let breakingNews = VideoCategory(
        id: "news",
        name: "news",
        displayName: "Breaking News",
        description: "Market-moving news and analysis",
        systemImage: "newspaper",
        color: .red,
        sortOrder: 6
    )
    
    static let allCategories: [VideoCategory] = [
        .topMovers,
        .earningsInFocus,
        .cryptoPulse,
        .educationalShorts,
        .creatorSpotlights,
        .breakingNews
    ]
}

// MARK: - Supporting Types

struct SponsorInfo: Codable {
    let brandName: String
    let brandLogoURL: String
    let sponsorshipType: SponsorshipType
    let disclosureText: String
    
    enum SponsorshipType: String, Codable {
        case sponsored = "sponsored"
        case partnership = "partnership"
        case affiliate = "affiliate"
        case paid = "paid"
    }
}

struct PriceTarget: Codable {
    let symbol: String
    let targetPrice: Decimal
    let timeframe: String
    let confidence: Double
    let reasoning: String
}

// MARK: - Market Data Types

struct TopMover: Identifiable {
    let id = UUID()
    let symbol: String
    let price: Decimal
    let change: Decimal
    let changePercent: Double
    let volume: Int
}

enum MarketStatus {
    case preMarket
    case open
    case afterHours
    case closed
    case holiday
    
    var displayName: String {
        switch self {
        case .preMarket: return "Pre-Market"
        case .open: return "Market Open"
        case .afterHours: return "After Hours"
        case .closed: return "Market Closed"
        case .holiday: return "Market Holiday"
        }
    }
    
    var color: Color {
        switch self {
        case .preMarket, .afterHours: return .orange
        case .open: return .green
        case .closed, .holiday: return .gray
        }
    }
}

// MARK: - Extensions

extension Color {
    static let green = Color.green
    static let red = Color.red
    static let blue = Color.blue
    static let orange = Color.orange
    static let purple = Color.purple
    static let pink = Color.pink
    static let gray = Color.gray
}

extension VideoContent {
    // Sample data for development
    static let sampleVideo = VideoContent(
        id: "sample-1",
        title: "Tesla Earnings Beat: What This Means for EV Sector",
        description: "Breaking down Tesla's Q4 earnings and the implications for electric vehicle stocks",
        thumbnailURL: "https://example.com/thumb1.jpg",
        videoURL: "https://example.com/video1.mp4",
        duration: 180, // 3 minutes
        publishedAt: Date().addingTimeInterval(-3600), // 1 hour ago
        creator: Creator.sampleCreator,
        symbols: ["TSLA", "NIO", "LCID"],
        category: .earningsInFocus,
        tags: ["earnings", "tesla", "ev", "analysis"],
        viewCount: 12500,
        likeCount: 890,
        isSponsored: false,
        sponsorInfo: nil,
        marketDirection: .bullish,
        priceTargets: [
            PriceTarget(symbol: "TSLA", targetPrice: 250.0, timeframe: "6 months", confidence: 0.75, reasoning: "Strong delivery growth")
        ],
        riskLevel: .moderate,
        timeHorizon: .mediumTerm,
        averageWatchTime: 142.5,
        clickThroughRate: 0.08,
        tradingConversionRate: 0.03,
        keyTakeaways: [
            "Revenue up 15% YoY",
            "Margin expansion in all segments",
            "FSD progress ahead of schedule"
        ],
        transcript: "In today's video, we're diving deep into Tesla's latest earnings...",
        aiSummary: "Tesla reported strong Q4 results with revenue growth and margin expansion, signaling continued strength in the EV market."
    )
}

extension Creator {
    static let sampleCreator = Creator(
        id: "creator-1",
        displayName: "MarketMike",
        username: "@marketmike",
        avatarURL: "https://example.com/avatar1.jpg",
        isVerified: true,
        followerCount: 125000,
        totalViews: 2500000,
        joinedDate: Date().addingTimeInterval(-365 * 24 * 3600), // 1 year ago
        expertise: ["Technical Analysis", "Options Trading", "EV Sector"],
        trackRecord: Creator.TrackRecord(
            accuracyRate: 0.72,
            totalPredictions: 156,
            avgReturn: 0.08,
            bestCall: "TSLA $180 → $250",
            worstCall: "META $320 → $280"
        )
    )
}
//
//  MarketNewsAlertsView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct MarketNewsAlertsView: View {
    @StateObject private var newsAlertsViewModel = MarketNewsAlertsViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: NewsAlertsSection?
    
    @State private var selectedCategory: NewsCategory = .all
    @State private var selectedNewsItem: MarketNewsItem?
    @State private var showingNewsPreferences = false
    
    enum NewsAlertsSection: Hashable {
        case back
        case category(NewsCategory)
        case newsItem(String)
        case preferences
    }
    
    enum NewsCategory: String, CaseIterable {
        case all = "All"
        case breaking = "Breaking"
        case earnings = "Earnings"
        case economicData = "Economic"
        case companyNews = "Companies"
        case marketMovers = "Movers"
        case sectorNews = "Sectors"
        case regulatory = "Regulatory"
        
        var systemImage: String {
            switch self {
            case .all: return "newspaper.fill"
            case .breaking: return "exclamationmark.triangle.fill"
            case .earnings: return "chart.bar.fill"
            case .economicData: return "globe.americas.fill"
            case .companyNews: return "building.2.fill"
            case .marketMovers: return "arrow.up.arrow.down"
            case .sectorNews: return "square.grid.3x3.fill"
            case .regulatory: return "scale.3d"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .breaking: return .red
            case .earnings: return .green
            case .economicData: return .purple
            case .companyNews: return .orange
            case .marketMovers: return .yellow
            case .sectorNews: return .pink
            case .regulatory: return .gray
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                newsAlertsHeader
                
                // Categories
                categoriesView
                
                // Content
                if newsAlertsViewModel.isLoading {
                    LoadingStateView(message: "Loading market news...")
                        .frame(maxHeight: .infinity)
                } else if newsAlertsViewModel.filteredNewsItems.isEmpty {
                    emptyStateView
                } else {
                    newsListView
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await newsAlertsViewModel.loadNewsItems()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(item: $selectedNewsItem) { newsItem in
            MarketNewsDetailView(newsItem: newsItem)
                .environmentObject(newsAlertsViewModel)
        }
        .sheet(isPresented: $showingNewsPreferences) {
            NewsPreferencesView()
                .environmentObject(newsAlertsViewModel)
        }
    }
    
    // MARK: - Header
    
    private var newsAlertsHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Market News Alerts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("Preferences", systemImage: "gear") {
                    showingNewsPreferences = true
                }
                .focused($focusedSection, equals: .preferences)
            }
            
            // Stats Row
            newsStatsView
        }
        .padding(.horizontal, 60)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var newsStatsView: some View {
        HStack(spacing: 40) {
            NewsStatCard(
                title: "Today",
                value: newsAlertsViewModel.todayNewsCount.formatted(.number),
                color: .green
            )
            
            NewsStatCard(
                title: "Breaking",
                value: newsAlertsViewModel.breakingNewsCount.formatted(.number),
                color: .red
            )
            
            NewsStatCard(
                title: "Unread",
                value: newsAlertsViewModel.unreadNewsCount.formatted(.number),
                color: .orange
            )
            
            NewsStatCard(
                title: "Watchlist",
                value: newsAlertsViewModel.watchlistNewsCount.formatted(.number),
                color: .blue
            )
            
            Spacer()
        }
    }
    
    // MARK: - Categories
    
    private var categoriesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    NewsCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        isFocused: focusedSection == .category(category),
                        count: newsAlertsViewModel.getCount(for: category)
                    ) {
                        selectedCategory = category
                        newsAlertsViewModel.setCategory(category)
                    }
                    .focused($focusedSection, equals: .category(category))
                }
            }
            .padding(.horizontal, 60)
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content
    
    private var newsListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(newsAlertsViewModel.filteredNewsItems, id: \.id) { newsItem in
                    MarketNewsRow(
                        newsItem: newsItem,
                        isFocused: focusedSection == .newsItem(newsItem.id)
                    ) {
                        selectedNewsItem = newsItem
                        newsAlertsViewModel.markNewsAsRead(newsItem.id)
                    }
                    .focused($focusedSection, equals: .newsItem(newsItem.id))
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            title: emptyStateTitle,
            message: emptyStateMessage,
            systemImage: "newspaper",
            actionTitle: nil,
            action: nil
        )
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch selectedCategory {
        case .all:
            return "No Market News"
        case .breaking:
            return "No Breaking News"
        default:
            return "No \(selectedCategory.rawValue) News"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedCategory {
        case .all:
            return "Market news alerts will appear here as they're published"
        case .breaking:
            return "Breaking news alerts will appear here when major market events occur"
        default:
            return "\(selectedCategory.rawValue) news will appear here when available"
        }
    }
}

// MARK: - Supporting Views

struct NewsStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct NewsCategoryButton: View {
    let category: MarketNewsAlertsView.NewsCategory
    let isSelected: Bool
    let isFocused: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.body)
                    .foregroundColor(category.color)
                
                Text(category.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .foregroundColor(buttonForegroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var buttonForegroundColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return category.color
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return category.color.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return category.color
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct MarketNewsRow: View {
    let newsItem: MarketNewsItem
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // News image or placeholder
                Group {
                    if let imageURL = newsItem.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(newsItem.category.color.opacity(0.3))
                            .overlay(
                                Image(systemName: newsItem.category.systemImage)
                                    .font(.title2)
                                    .foregroundColor(newsItem.category.color)
                            )
                    }
                }
                .frame(width: 120, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // News content
                VStack(alignment: .leading, spacing: 8) {
                    // Category and importance
                    HStack {
                        Text(newsItem.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(newsItem.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(newsItem.category.color.opacity(0.2))
                            )
                        
                        // Importance indicator
                        HStack(spacing: 2) {
                            ForEach(0..<importanceLevel, id: \.self) { _ in
                                Circle()
                                    .fill(newsItem.importance.color)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        
                        Spacer()
                        
                        // Read status
                        if !newsItem.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Headline
                    Text(newsItem.headline)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Summary
                    Text(newsItem.summary)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                    
                    // Footer info
                    HStack {
                        Text(newsItem.source)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(newsItem.publishedAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Related symbols
                        if !newsItem.relatedSymbols.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(newsItem.relatedSymbols.prefix(3), id: \.self) { symbol in
                                    Text(symbol)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.blue.opacity(0.3))
                                        )
                                }
                                
                                if newsItem.relatedSymbols.count > 3 {
                                    Text("+\(newsItem.relatedSymbols.count - 3)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isFocused ? 0.1 : (newsItem.isRead ? 0.05 : 0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var importanceLevel: Int {
        switch newsItem.importance {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    private var borderColor: Color {
        switch newsItem.importance {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Detail Views

struct MarketNewsDetailView: View {
    let newsItem: MarketNewsItem
    
    @EnvironmentObject private var newsAlertsViewModel: MarketNewsAlertsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("News Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(newsItem.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct NewsPreferencesView: View {
    @EnvironmentObject private var newsAlertsViewModel: MarketNewsAlertsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("News Preferences")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Configure your news alert preferences")
                    .foregroundColor(.gray)
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Extensions

extension MarketNewsItem.NewsCategory {
    var systemImage: String {
        switch self {
        case .earnings: return "chart.bar.fill"
        case .economicData: return "globe.americas.fill"
        case .companyNews: return "building.2.fill"
        case .marketMovers: return "arrow.up.arrow.down"
        case .sectorNews: return "square.grid.3x3.fill"
        case .regulatory: return "scale.3d"
        }
    }
    
    var color: Color {
        switch self {
        case .earnings: return .green
        case .economicData: return .purple
        case .companyNews: return .orange
        case .marketMovers: return .yellow
        case .sectorNews: return .pink
        case .regulatory: return .gray
        }
    }
}

extension MarketNewsItem {
    var isRead: Bool {
        get {
            // This would typically be stored in the news data
            // For demo purposes, simulate some read status
            return Bool.random()
        }
        set {
            // In a real implementation, this would update the news record
        }
    }
}

#Preview {
    MarketNewsAlertsView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
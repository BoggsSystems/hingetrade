//
//  CreatorProfileView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct CreatorProfileView: View {
    let creator: VideoCreator
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var creatorViewModel: CreatorProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: ProfileSection?
    @State private var selectedTab: ProfileTab = .videos
    
    enum ProfileSection: Hashable {
        case back
        case follow
        case tip
        case tab(ProfileTab)
        case video(String)
    }
    
    enum ProfileTab: String, CaseIterable {
        case videos = "Videos"
        case performance = "Performance"
        case insights = "Insights"
        case following = "Following"
        
        var systemImage: String {
            switch self {
            case .videos: return "tv.fill"
            case .performance: return "chart.line.uptrend.xyaxis"
            case .insights: return "lightbulb.fill"
            case .following: return "person.2.fill"
            }
        }
    }
    
    init(creator: VideoCreator) {
        self.creator = creator
        self._creatorViewModel = StateObject(wrappedValue: CreatorProfileViewModel(creator: creator))
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Creator Header
                creatorHeaderView
                
                // Tab Navigation
                tabNavigationView
                
                // Content Area
                contentAreaView
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await creatorViewModel.loadCreatorData()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
    }
    
    // MARK: - Creator Header
    
    private var creatorHeaderView: some View {
        VStack(spacing: 24) {
            // Top Bar
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Tip Button
                    FocusableButton("Tip Creator", systemImage: "heart.fill") {
                        Task {
                            await creatorViewModel.showTipModal()
                        }
                    }
                    .focused($focusedSection, equals: .tip)
                    
                    // Follow/Unfollow Button
                    FocusableButton(
                        creatorViewModel.isFollowing ? "Unfollow" : "Follow",
                        systemImage: creatorViewModel.isFollowing ? "person.fill.checkmark" : "person.badge.plus",
                        style: creatorViewModel.isFollowing ? .secondary : .primary
                    ) {
                        Task {
                            await creatorViewModel.toggleFollowStatus()
                        }
                    }
                    .focused($focusedSection, equals: .follow)
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 40)
            
            // Creator Info Card
            creatorInfoCard
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var creatorInfoCard: some View {
        HStack(spacing: 24) {
            // Profile Picture
            AsyncImage(url: URL(string: creator.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 40))
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.green, lineWidth: creator.isVerified ? 3 : 0)
            )
            
            // Creator Details
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(creator.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if creator.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                if let tagline = creator.tagline {
                    Text(tagline)
                        .font(.title3)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                // Stats Row
                HStack(spacing: 32) {
                    StatItem(
                        title: "Followers",
                        value: creatorViewModel.followerCount.formatted(.number.notation(.compactName)),
                        color: .green
                    )
                    
                    StatItem(
                        title: "Videos",
                        value: creatorViewModel.videoCount.formatted(.number.notation(.compactName)),
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Win Rate",
                        value: creatorViewModel.winRate.formatted(.percent.precision(.fractionLength(1))),
                        color: creatorViewModel.winRate > 0.5 ? .green : .red
                    )
                    
                    StatItem(
                        title: "Avg Return",
                        value: creatorViewModel.averageReturn.formatted(.percent.precision(.fractionLength(1))),
                        color: creatorViewModel.averageReturn > 0 ? .green : .red
                    )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 30)
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigationView: some View {
        HStack(spacing: 20) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isFocused: focusedSection == .tab(tab)
                ) {
                    selectedTab = tab
                }
                .focused($focusedSection, equals: .tab(tab))
            }
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Content Area
    
    private var contentAreaView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                switch selectedTab {
                case .videos:
                    creatorVideosView
                case .performance:
                    creatorPerformanceView
                case .insights:
                    creatorInsightsView
                case .following:
                    creatorFollowingView
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Tab Content Views
    
    private var creatorVideosView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
            ForEach(creatorViewModel.creatorVideos, id: \.id) { video in
                CreatorVideoCard(
                    video: video,
                    isFocused: focusedSection == .video(video.id)
                ) {
                    // Navigate to video player
                    // This would typically present the VideoPlayerView
                }
                .focused($focusedSection, equals: .video(video.id))
            }
        }
    }
    
    private var creatorPerformanceView: some View {
        VStack(spacing: 24) {
            // Performance Chart
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance Over Time")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if creatorViewModel.isLoadingPerformance {
                    LoadingStateView(message: "Loading performance data...")
                        .frame(height: 200)
                } else {
                    CreatorPerformanceChart(data: creatorViewModel.performanceData)
                        .frame(height: 200)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            
            // Recent Trades Performance
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Trade Calls")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVStack(spacing: 12) {
                    ForEach(creatorViewModel.recentTradeCalls, id: \.id) { tradeCall in
                        TradeCallCard(tradeCall: tradeCall)
                    }
                }
            }
        }
    }
    
    private var creatorInsightsView: some View {
        VStack(spacing: 24) {
            // Top Sectors
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Sectors")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(creatorViewModel.topSectors, id: \.name) { sector in
                        SectorCard(sector: sector)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // Trading Style Analysis
            VStack(alignment: .leading, spacing: 16) {
                Text("Trading Style")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TradingStyleAnalysis(style: creatorViewModel.tradingStyle)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var creatorFollowingView: some View {
        VStack(spacing: 24) {
            if creatorViewModel.isFollowingDataPublic {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(creatorViewModel.followingCreators, id: \.id) { followedCreator in
                        FollowingCreatorCard(creator: followedCreator)
                    }
                }
            } else {
                EmptyStateView(
                    title: "Private Following List",
                    message: "\(creator.displayName) keeps their following list private",
                    systemImage: "lock.fill"
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
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

struct TabButton: View {
    let tab: CreatorProfileView.ProfileTab
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .font(.body)
                
                Text(tab.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
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
            return .green
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return Color.green.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .green
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct CreatorVideoCard: View {
    let video: VideoContent
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
                )
                
                // Video Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(video.createdAt?.formatted(.relative(presentation: .named)) ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("\(video.viewCount.formatted(.number.notation(.compactName))) views")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let performance = video.performanceScore {
                            Text("\(performance.formatted(.percent.precision(.fractionLength(1))))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(performance > 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Placeholder Views

struct CreatorPerformanceChart: View {
    let data: [PerformanceDataPoint]
    
    var body: some View {
        // Placeholder for performance chart
        Rectangle()
            .fill(Color.green.opacity(0.1))
            .overlay(
                Text("Performance Chart")
                    .foregroundColor(.green)
            )
    }
}

struct TradeCallCard: View {
    let tradeCall: TradeCall
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tradeCall.symbol)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(tradeCall.direction.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(tradeCall.direction == .bullish ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                    )
                    .foregroundColor(tradeCall.direction == .bullish ? .green : .red)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(tradeCall.performance.formatted(.percent.precision(.fractionLength(1))))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(tradeCall.performance > 0 ? .green : .red)
                
                Text(tradeCall.date.formatted(.dateTime.month().day()))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct SectorCard: View {
    let sector: CreatorSector
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sector.name)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("\(sector.percentage.formatted(.percent.precision(.fractionLength(1)))) of trades")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Avg: \(sector.averageReturn.formatted(.percent.precision(.fractionLength(1))))")
                .font(.caption)
                .foregroundColor(sector.averageReturn > 0 ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct TradingStyleAnalysis: View {
    let style: TradingStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Style: \(style.type)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Risk: \(style.riskLevel)")
                    .font(.body)
                    .foregroundColor(style.riskColor)
            }
            
            Text("Avg Hold Time: \(style.averageHoldTime)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(style.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
        }
    }
}

struct FollowingCreatorCard: View {
    let creator: VideoCreator
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: creator.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            Text(creator.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    CreatorProfileView(creator: VideoCreator.sampleCreator)
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
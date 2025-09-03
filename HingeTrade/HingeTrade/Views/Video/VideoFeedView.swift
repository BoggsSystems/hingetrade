//
//  VideoFeedView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct VideoFeedView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var videoFeedViewModel = VideoFeedViewModel()
    @State private var selectedVideo: VideoContent?
    @State private var showingVideoPlayer = false
    @FocusState private var focusedSection: FeedSection?
    
    enum FeedSection: Hashable {
        case hero
        case category(VideoCategory)
    }
    
    var body: some View {
        TVNavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if videoFeedViewModel.isLoading && videoFeedViewModel.videoCategories.isEmpty {
                    LoadingStateView(message: "Loading your personalized feed...")
                } else if videoFeedViewModel.videoCategories.isEmpty {
                    emptyFeedView
                } else {
                    feedContentView
                }
            }
        }
        .fullScreenCover(item: $selectedVideo) { video in
            VideoPlayerView(video: video)
                .environmentObject(appState)
        }
        .onAppear {
            Task {
                await videoFeedViewModel.loadFeed()
            }
            
            // Auto-focus hero section
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .hero
            }
        }
        .refreshable {
            await videoFeedViewModel.refreshFeed()
        }
    }
    
    // MARK: - Feed Content
    
    private var feedContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 40) {
                // Hero Section
                heroSectionView
                    .focused($focusedSection, equals: .hero)
                
                // Category Sections
                ForEach(videoFeedViewModel.videoCategories, id: \.id) { category in
                    CategorySectionView(
                        category: category,
                        isFocused: focusedSection == .category(category)
                    ) { video in
                        selectedVideo = video
                        showingVideoPlayer = true
                    }
                    .focused($focusedSection, equals: .category(category))
                }
            }
            .padding(.vertical, 40)
        }
    }
    
    private var heroSectionView: some View {
        VStack(spacing: 20) {
            // Market Status Header
            marketStatusHeaderView
            
            // Hero Carousel
            if let heroVideos = videoFeedViewModel.heroVideos, !heroVideos.isEmpty {
                HeroCarouselView(videos: heroVideos) { video in
                    selectedVideo = video
                    showingVideoPlayer = true
                }
            }
        }
    }
    
    private var marketStatusHeaderView: some View {
        HStack(spacing: 40) {
            // Current Time
            VStack(alignment: .leading, spacing: 4) {
                Text("Market Status")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(videoFeedViewModel.marketStatus.color.swiftUIColor)
                        .frame(width: 8, height: 8)
                    
                    Text(videoFeedViewModel.marketStatus.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            // Top Market Movers
            HStack(spacing: 30) {
                ForEach(videoFeedViewModel.topMovers.prefix(3), id: \.symbol) { mover in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mover.symbol)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(mover.price.formatted(.currency(code: "USD")))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("\(mover.changePercent.formatted(.percent.precision(.fractionLength(2))))")
                            .font(.caption)
                            .foregroundColor(mover.changePercent >= 0 ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            // Account Summary (if authenticated)
            if appState.isAuthenticated {
                accountSummaryView
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 60)
    }
    
    private var accountSummaryView: some View {
        HStack(spacing: 20) {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Portfolio")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(appState.totalEquity.formatted(.currency(code: "USD")))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Today's P&L")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(appState.todaysPL.formatted(.currency(code: "USD")))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(appState.todaysPL >= 0 ? .green : .red)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyFeedView: some View {
        EmptyStateView(
            title: "No Videos Available",
            message: "We're working to bring you the latest market insights and trading content.",
            systemImage: "tv.fill",
            actionTitle: "Refresh Feed",
            action: {
                Task {
                    await videoFeedViewModel.refreshFeed()
                }
            }
        )
    }
}

// MARK: - HeroCarouselView

struct HeroCarouselView: View {
    let videos: [VideoContent]
    let onVideoSelected: (VideoContent) -> Void
    
    @State private var currentIndex: Int = 0
    @State private var timer: Timer?
    @FocusState private var focusedVideo: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Hero Video
            if !videos.isEmpty {
                HeroVideoCard(
                    video: videos[currentIndex],
                    isFocused: focusedVideo == videos[currentIndex].id
                ) {
                    onVideoSelected(videos[currentIndex])
                }
                .focused($focusedVideo, equals: videos[currentIndex].id)
            }
            
            // Thumbnail Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        HeroThumbnail(
                            video: video,
                            isSelected: index == currentIndex,
                            isFocused: focusedVideo == "thumb_\(video.id)"
                        ) {
                            withAnimation(.easeInOut) {
                                currentIndex = index
                            }
                            restartAutoAdvance()
                        }
                        .focused($focusedVideo, equals: "thumb_\(video.id)")
                    }
                }
                .padding(.horizontal, 60)
            }
        }
        .onAppear {
            startAutoAdvance()
            
            // Auto-focus first video
            if !videos.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedVideo = videos[0].id
                }
            }
        }
        .onDisappear {
            stopAutoAdvance()
        }
    }
    
    private func startAutoAdvance() {
        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            withAnimation(.easeInOut) {
                currentIndex = (currentIndex + 1) % videos.count
            }
        }
    }
    
    private func restartAutoAdvance() {
        stopAutoAdvance()
        startAutoAdvance()
    }
    
    private func stopAutoAdvance() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - HeroVideoCard

struct HeroVideoCard: View {
    let video: VideoContent
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Video Thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "tv.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Content Overlay
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    
                    // Video Metadata
                    HStack(spacing: 12) {
                        if !video.symbols.isEmpty {
                            SymbolTagsView(symbols: video.symbols)
                        }
                        
                        Spacer()
                        
                        Text(Duration.seconds(video.duration).formatted(.time(pattern: .minuteSecond)))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                    
                    // Title and Description
                    Text(video.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    if let description = video.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    // Creator and Views
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            AsyncImage(url: URL(string: video.creator.avatarURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            
                            Text(video.creator.displayName)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text("\(video.viewCount.formatted(.number.notation(.compactName))) views")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(video.publishedAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(24)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green, lineWidth: isFocused ? 3 : 0)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
    }
}

// MARK: - Supporting Views

struct HeroThumbnail: View {
    let video: VideoContent
    let isSelected: Bool
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 120, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: isFocused ? 2 : 0)
            )
            .opacity(isSelected ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct SymbolTagsView: View {
    let symbols: [String]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(symbols.prefix(3), id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.8))
                    )
            }
            
            if symbols.count > 3 {
                Text("+\(symbols.count - 3)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    VideoFeedView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
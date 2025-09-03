//
//  CategorySectionView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct CategorySectionView: View {
    let category: VideoCategory
    let isFocused: Bool
    let onVideoSelected: (VideoContent) -> Void
    
    @EnvironmentObject private var videoFeedViewModel: VideoFeedViewModel
    @FocusState private var focusedVideo: String?
    @State private var showAllVideos = false
    
    var videos: [VideoContent] {
        videoFeedViewModel.getVideosForCategory(category.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            sectionHeaderView
            
            // Video Thumbnails Carousel
            if videos.isEmpty {
                emptyCategoryView
            } else {
                videoCarouselView
            }
        }
        .onAppear {
            Task {
                await videoFeedViewModel.trackCategoryEngagement(category)
            }
        }
    }
    
    // MARK: - Section Header
    
    private var sectionHeaderView: some View {
        HStack(spacing: 16) {
            // Category Icon
            Image(systemName: category.systemImage)
                .font(.title2)
                .foregroundColor(category.color)
            
            // Category Title and Description
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(category.description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Video Count and See All Button
            if videos.count > 6 {
                Button(action: {
                    showAllVideos = true
                }) {
                    HStack(spacing: 6) {
                        Text("\(videos.count) videos")
                            .font(.caption)
                        
                        Text("See All")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(isFocused ? .white : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 60)
    }
    
    // MARK: - Video Carousel
    
    private var videoCarouselView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(videos.prefix(8).enumerated()), id: \.element.id) { index, video in
                    VideoThumbnailCard(
                        video: video,
                        isFocused: focusedVideo == video.id,
                        showMarketData: true
                    ) {
                        onVideoSelected(video)
                        
                        // Track video interaction
                        Task {
                            await videoFeedViewModel.trackVideoImpression(video)
                        }
                    }
                    .focused($focusedVideo, equals: video.id)
                    .onAppear {
                        // Auto-focus first video when section becomes focused
                        if isFocused && index == 0 && focusedVideo == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedVideo = video.id
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyCategoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.system(size: 40))
                .foregroundColor(category.color.opacity(0.6))
            
            Text("No \(category.displayName.lowercased()) available")
                .font(.body)
                .foregroundColor(.gray)
            
            Text("New content will be added soon")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Sheet Presentations
    
    @ViewBuilder
    private var fullCategoryView: some View {
        if showAllVideos {
            FullCategoryView(category: category, videos: videos) {
                showAllVideos = false
            }
        }
    }
}

// MARK: - VideoThumbnailCard

struct VideoThumbnailCard: View {
    let video: VideoContent
    let isFocused: Bool
    let showMarketData: Bool
    let onTap: () -> Void
    
    private let cardWidth: CGFloat = 320
    private let cardHeight: CGFloat = 240
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Video Thumbnail with Overlays
                thumbnailView
                
                // Video Metadata
                metadataView
            }
            .frame(width: cardWidth)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var thumbnailView: some View {
        ZStack(alignment: .topTrailing) {
            // Main Thumbnail
            AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "tv.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                            
                            Text(video.title)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding()
                    )
            }
            .frame(width: cardWidth, height: cardHeight * 0.7)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: 2)
            )
            
            // Overlays
            VStack {
                HStack {
                    // Sponsored Badge
                    if video.isSponsored {
                        sponsoredBadge
                    }
                    
                    Spacer()
                    
                    // Duration
                    durationBadge
                }
                .padding(8)
                
                Spacer()
                
                // Market Data Overlay (Bottom)
                if showMarketData && !video.symbols.isEmpty {
                    marketDataOverlay
                }
            }
            .frame(width: cardWidth, height: cardHeight * 0.7)
        }
    }
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
            Text(video.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Creator and Stats
            HStack(spacing: 8) {
                // Creator Avatar
                AsyncImage(url: URL(string: video.creator.avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                
                // Creator Name
                Text(video.creator.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // Verified Badge
                if video.creator.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // View Count
                Text("\(video.viewCount.formatted(.number.notation(.compactName)))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Symbol Tags
            if !video.symbols.isEmpty {
                symbolTagsView
            }
            
            // Market Direction Indicator
            if let direction = video.marketDirection {
                marketDirectionView(direction)
            }
        }
    }
    
    // MARK: - Overlay Components
    
    private var sponsoredBadge: some View {
        Text("SPONSORED")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
            )
    }
    
    private var durationBadge: some View {
        Text(Duration.seconds(video.duration).formatted(.time(pattern: .minuteSecond)))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.7))
            )
    }
    
    private var marketDataOverlay: some View {
        HStack(spacing: 8) {
            ForEach(video.symbols.prefix(2), id: \.self) { symbol in
                // This would show real-time price data
                HStack(spacing: 4) {
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("+2.3%") // Placeholder - would be real data
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.8))
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    private var symbolTagsView: some View {
        HStack(spacing: 4) {
            ForEach(video.symbols.prefix(3), id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.6))
                    )
            }
            
            if video.symbols.count > 3 {
                Text("+\(video.symbols.count - 3)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func marketDirectionView(_ direction: VideoContent.MarketDirection) -> some View {
        HStack(spacing: 4) {
            Image(systemName: direction.systemImage)
                .font(.caption)
            
            Text(direction.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(direction.color)
    }
}

// MARK: - FullCategoryView (Placeholder)

struct FullCategoryView: View {
    let category: VideoCategory
    let videos: [VideoContent]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(category.displayName)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Close") {
                    onDismiss()
                }
                .foregroundColor(.gray)
            }
            .padding()
            
            Text("Full category view coming soon...")
                .foregroundColor(.gray)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    CategorySectionView(
        category: .topMovers,
        isFocused: false
    ) { video in
        print("Selected video: \(video.title)")
    }
    .environmentObject(VideoFeedViewModel())
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
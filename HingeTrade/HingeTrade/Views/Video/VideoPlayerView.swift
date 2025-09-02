//
//  VideoPlayerView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let video: VideoContent
    
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var videoPlayerViewModel: VideoPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedControl: PlayerControl?
    @State private var showingTradeModal = false
    @State private var showingChartView = false
    @State private var showingCreatorProfile = false
    
    enum PlayerControl: Hashable {
        case playPause
        case trade
        case watchlist
        case tip
        case chart
        case back
    }
    
    init(video: VideoContent) {
        self.video = video
        self._videoPlayerViewModel = StateObject(wrappedValue: VideoPlayerViewModel(video: video))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Video Player
            videoPlayerContent
            
            // Video Overlays
            if !videoPlayerViewModel.isControlsHidden {
                videoOverlaysView
            }
            
            // Chart Picture-in-Picture
            if showingChartView {
                chartPiPView
            }
        }
        .onAppear {
            setupPlayerEnvironment()
        }
        .onDisappear {
            videoPlayerViewModel.pause()
        }
        .sheet(isPresented: $showingTradeModal) {
            TradeTicketModalView(
                symbol: videoPlayerViewModel.primarySymbol,
                videoContext: VideoContext(
                    videoId: video.id,
                    videoTitle: video.title,
                    creatorName: video.creator.displayName,
                    marketDirection: video.marketDirection,
                    keyInsight: video.aiSummary,
                    mentionedSymbols: video.symbols,
                    priceTargets: video.priceTargets
                )
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showingCreatorProfile) {
            CreatorProfileView(creator: video.creator)
                .environmentObject(appState)
        }
    }
    
    // MARK: - Video Player Content
    
    private var videoPlayerContent: some View {
        GeometryReader { geometry in
            ZStack {
                if videoPlayerViewModel.isLoading {
                    LoadingStateView(message: "Loading video...")
                } else if let error = videoPlayerViewModel.error {
                    ErrorStateView(
                        title: "Playback Error",
                        message: error.localizedDescription,
                        systemImage: "exclamationmark.triangle.fill",
                        retryAction: {
                            Task {
                                await videoPlayerViewModel.retry()
                            }
                        }
                    )
                } else {
                    // AVPlayer View (Placeholder - would use AVPlayerViewController in production)
                    VideoPlayerRepresentable(player: videoPlayerViewModel.player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                videoPlayerViewModel.toggleControlsVisibility()
            }
        }
    }
    
    // MARK: - Video Overlays
    
    private var videoOverlaysView: some View {
        ZStack {
            // Top Overlay
            topOverlayView
            
            // Bottom Overlay  
            bottomOverlayView
            
            // Right Side Actions
            rightSideActionsView
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: videoPlayerViewModel.isControlsHidden)
    }
    
    private var topOverlayView: some View {
        VStack {
            HStack {
                // Back Button
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedControl, equals: .back)
                
                Spacer()
                
                // Video Title
                VStack(alignment: .trailing, spacing: 4) {
                    Text(video.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    
                    Button(action: {
                        showingCreatorProfile = true
                    }) {
                        HStack(spacing: 8) {
                            Text(video.creator.displayName)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if video.creator.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 40)
            
            Spacer()
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        )
    }
    
    private var bottomOverlayView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                // Ticker Strip (if symbols present)
                if !video.symbols.isEmpty {
                    TickerStripView(symbols: video.symbols)
                        .environmentObject(videoPlayerViewModel)
                }
                
                // Playback Controls
                playbackControlsView
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        )
    }
    
    private var playbackControlsView: some View {
        VStack(spacing: 12) {
            // Progress Bar
            progressBarView
            
            // Control Buttons
            HStack(spacing: 40) {
                // Play/Pause
                Button(action: {
                    videoPlayerViewModel.togglePlayback()
                }) {
                    Image(systemName: videoPlayerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(focusedControl == .playPause ? .black : .white)
                        .frame(width: 60, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(focusedControl == .playPause ? .white : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: focusedControl == .playPause ? 2 : 0)
                        )
                }
                .focused($focusedControl, equals: .playPause)
                .buttonStyle(PlainButtonStyle())
                
                // Time Display
                HStack(spacing: 8) {
                    Text(videoPlayerViewModel.currentTime.formatted(.time(pattern: .minuteSecond)))
                        .font(.body)
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Text("/")
                        .foregroundColor(.gray)
                    
                    Text(video.duration.formatted(.time(pattern: .minuteSecond)))
                        .font(.body)
                        .foregroundColor(.gray)
                        .monospacedDigit()
                }
                
                Spacer()
                
                // Volume Control (if needed)
                Button(action: {
                    videoPlayerViewModel.toggleMute()
                }) {
                    Image(systemName: videoPlayerViewModel.isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var progressBarView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: geometry.size.width * videoPlayerViewModel.progress, height: 4)
                
                // Buffer Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: geometry.size.width * videoPlayerViewModel.bufferProgress, height: 4)
            }
        }
        .frame(height: 4)
        .onTapGesture { location in
            let progress = location.x / UIScreen.main.bounds.width // Approximate
            videoPlayerViewModel.seek(to: progress)
        }
    }
    
    // MARK: - Right Side Actions
    
    private var rightSideActionsView: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Quick Actions
                QuickActionsView(
                    video: video,
                    focusedAction: $focusedControl
                ) { action in
                    handleQuickAction(action)
                }
                
                Spacer()
            }
            .padding(.trailing, 60)
        }
    }
    
    // MARK: - Chart Picture-in-Picture
    
    private var chartPiPView: some View {
        VStack {
            HStack {
                Spacer()
                
                ChartPiPView(
                    symbol: videoPlayerViewModel.primarySymbol,
                    isExpanded: $showingChartView
                )
                .frame(width: 400, height: 225)
                .padding(.trailing, 60)
                .padding(.top, 100)
            }
            
            Spacer()
        }
        .transition(.move(edge: .trailing))
        .animation(.easeInOut(duration: 0.3), value: showingChartView)
    }
    
    // MARK: - Setup and Actions
    
    private func setupPlayerEnvironment() {
        Task {
            await videoPlayerViewModel.prepare()
            
            // Auto-focus play button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                focusedControl = .playPause
            }
            
            // Hide controls after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                videoPlayerViewModel.hideControls()
            }
        }
    }
    
    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .trade:
            showingTradeModal = true
        case .watchlist:
            Task {
                await appState.addToWatchlist(symbol: videoPlayerViewModel.primarySymbol)
            }
        case .tip:
            Task {
                await videoPlayerViewModel.sendTip(amount: 1.0)
            }
        case .chart:
            showingChartView.toggle()
        case .share:
            // Handle sharing
            break
        case .like:
            Task {
                await videoPlayerViewModel.likeVideo()
            }
        }
    }
}

// MARK: - VideoPlayerRepresentable

struct VideoPlayerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// MARK: - TickerStripView

struct TickerStripView: View {
    let symbols: [String]
    @EnvironmentObject private var videoPlayerViewModel: VideoPlayerViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(symbols.prefix(4), id: \.self) { symbol in
                if let quote = videoPlayerViewModel.getQuote(for: symbol) {
                    TickerItem(quote: quote)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
        )
    }
}

struct TickerItem: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(quote.symbol)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Text(quote.bidPrice.formatted(.currency(code: "USD")))
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("\(quote.changePercent.formatted(.percent.precision(.fractionLength(2))))")
                    .font(.caption2)
                    .foregroundColor(quote.changePercent >= 0 ? .green : .red)
            }
        }
    }
}

// MARK: - QuickActionsView

struct QuickActionsView: View {
    let video: VideoContent
    @Binding var focusedAction: VideoPlayerView.PlayerControl?
    let onAction: (QuickAction) -> Void
    
    enum QuickAction {
        case trade, watchlist, tip, chart, share, like
        
        var systemImage: String {
            switch self {
            case .trade: return "dollarsign.circle.fill"
            case .watchlist: return "plus.circle.fill"
            case .tip: return "heart.fill"
            case .chart: return "chart.line.uptrend.xyaxis"
            case .share: return "square.and.arrow.up"
            case .like: return "hand.thumbsup.fill"
            }
        }
        
        var title: String {
            switch self {
            case .trade: return "Trade"
            case .watchlist: return "Watchlist"
            case .tip: return "Tip"
            case .chart: return "Chart"
            case .share: return "Share"
            case .like: return "Like"
            }
        }
        
        var color: Color {
            switch self {
            case .trade: return .green
            case .watchlist: return .blue
            case .tip: return .pink
            case .chart: return .purple
            case .share: return .gray
            case .like: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach([QuickAction.trade, .watchlist, .chart, .tip], id: \.self) { action in
                QuickActionButton(
                    action: action,
                    isFocused: focusedAction == playerControlFor(action)
                ) {
                    onAction(action)
                }
                .focused($focusedAction, equals: playerControlFor(action))
            }
        }
    }
    
    private func playerControlFor(_ action: QuickAction) -> VideoPlayerView.PlayerControl {
        switch action {
        case .trade: return .trade
        case .watchlist: return .watchlist
        case .tip: return .tip
        case .chart: return .chart
        case .share, .like: return .trade // Default fallback
        }
    }
}

struct QuickActionButton: View {
    let action: QuickActionsView.QuickAction
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: action.systemImage)
                    .font(.title2)
                    .foregroundColor(isFocused ? .white : action.color)
                
                Text(action.title)
                    .font(.caption)
                    .foregroundColor(isFocused ? .white : action.color)
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? action.color : Color.black.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(action.color, lineWidth: isFocused ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - ChartPiPView (Placeholder)

struct ChartPiPView: View {
    let symbol: String
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(symbol)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("×") {
                    isExpanded = false
                }
                .foregroundColor(.gray)
            }
            
            // Placeholder chart
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .overlay(
                    Text("Chart Preview")
                        .foregroundColor(.green)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .stroke(Color.green, lineWidth: 1)
        )
    }
}

// The TradeTicketModalView is now implemented in its own file

#Preview {
    VideoPlayerView(video: VideoContent.sampleVideo)
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
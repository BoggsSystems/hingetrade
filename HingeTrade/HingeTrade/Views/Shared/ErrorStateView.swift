//
//  ErrorStateView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let retryAction: (() -> Void)?
    
    @FocusState private var retryButtonFocused: Bool
    
    init(
        title: String = "Something went wrong",
        message: String,
        systemImage: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
            
            if let retryAction = retryAction {
                FocusableButton("Try Again", systemImage: "arrow.clockwise") {
                    retryAction()
                }
                .focused($retryButtonFocused)
            }
        }
        .padding(40)
        .onAppear {
            if retryAction != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    retryButtonFocused = true
                }
            }
        }
    }
}

// MARK: - LoadingStateView

struct LoadingStateView: View {
    let message: String
    let showProgress: Bool
    
    @State private var rotationAngle: Double = 0
    
    init(message: String = "Loading...", showProgress: Bool = true) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if showProgress {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(Angle(degrees: rotationAngle))
                        .onAppear {
                            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }
                }
            }
            
            Text(message)
                .font(.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @FocusState private var actionButtonFocused: Bool
    
    init(
        title: String,
        message: String,
        systemImage: String = "tray.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
            
            if let actionTitle = actionTitle, let action = action {
                FocusableButton(actionTitle, systemImage: "plus.circle.fill") {
                    action()
                }
                .focused($actionButtonFocused)
            }
        }
        .padding(40)
        .onAppear {
            if action != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    actionButtonFocused = true
                }
            }
        }
    }
}

// MARK: - NetworkErrorView

struct NetworkErrorView: View {
    let retryAction: () -> Void
    
    var body: some View {
        ErrorStateView(
            title: "Connection Issue",
            message: "Unable to connect to HingeTrade servers. Please check your internet connection and try again.",
            systemImage: "wifi.exclamationmark",
            retryAction: retryAction
        )
    }
}

// MARK: - MaintenanceView

struct MaintenanceView: View {
    var body: some View {
        ErrorStateView(
            title: "Under Maintenance",
            message: "HingeTrade is currently undergoing scheduled maintenance. We'll be back shortly.",
            systemImage: "wrench.and.screwdriver.fill"
        )
    }
}

// MARK: - Preview Support

#Preview("Error State") {
    ErrorStateView(
        title: "Failed to Load",
        message: "Unable to load your portfolio data. Please try again.",
        retryAction: {
            print("Retry tapped")
        }
    )
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

#Preview("Loading State") {
    LoadingStateView(message: "Loading your portfolio...")
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    EmptyStateView(
        title: "No Positions",
        message: "You don't have any open positions yet. Start trading to see them here.",
        systemImage: "chart.bar.fill",
        actionTitle: "Start Trading",
        action: {
            print("Start Trading tapped")
        }
    )
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

#Preview("Network Error") {
    NetworkErrorView {
        print("Retry network connection")
    }
    .background(Color.black.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
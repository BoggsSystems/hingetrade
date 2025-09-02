//
//  MainTabView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppStateViewModel()
    @State private var selectedTab: TabSection = .feed
    
    enum TabSection: String, CaseIterable {
        case feed = "Feed"
        case accounts = "Accounts" 
        case orders = "Orders"
        case alerts = "Alerts"
        
        var systemImage: String {
            switch self {
            case .feed: return "tv"
            case .accounts: return "chart.pie.fill"
            case .orders: return "list.bullet"
            case .alerts: return "bell.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabSection.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .environmentObject(appState)
        .onAppear {
            setupTVAppearance()
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: TabSection) -> some View {
        switch tab {
        case .feed:
            if appState.isAuthenticated {
                VideoFeedView()
            } else {
                WelcomeView()
            }
        case .accounts:
            if appState.isAuthenticated {
                AccountsDashboardView()
            } else {
                AuthenticationRequiredView(tabName: tab.rawValue)
            }
        case .orders:
            if appState.isAuthenticated {
                OrdersPlaceholderView()
            } else {
                AuthenticationRequiredView(tabName: tab.rawValue)
            }
        case .alerts:
            if appState.isAuthenticated {
                AlertsPlaceholderView()
            } else {
                AuthenticationRequiredView(tabName: tab.rawValue)
            }
        }
    }
    
    private func setupTVAppearance() {
        // Configure tvOS-specific appearance
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        UITabBar.appearance().tintColor = UIColor.systemGreen
    }
}

// MARK: - Placeholder Views

struct OrdersPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "list.bullet")
                .font(.system(size: 100))
                .foregroundColor(.secondary)
            Text("Orders")
                .font(.largeTitle)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct AlertsPlaceholderView: View {
    var body: some View {
        VStack {
            Image(systemName: "bell.fill")
                .font(.system(size: 100))
                .foregroundColor(.secondary)
            Text("Alerts")
                .font(.largeTitle)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct AuthenticationRequiredView: View {
    let tabName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 100))
                .foregroundColor(.orange)
            
            Text("Authentication Required")
                .font(.largeTitle)
            
            Text("Please sign in to access \(tabName)")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: WelcomeView()) {
                Text("Sign In")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    MainTabView()
}
//
//  CreatorNotificationsView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct CreatorNotificationsView: View {
    @StateObject private var creatorNotificationViewModel = CreatorNotificationViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: CreatorNotificationSection?
    
    @State private var selectedTab: CreatorNotificationTab = .following
    @State private var selectedCreator: Creator?
    @State private var selectedNotification: CreatorNotification?
    
    enum CreatorNotificationSection: Hashable {
        case back
        case tab(CreatorNotificationTab)
        case creator(String)
        case notification(String)
        case preferences
    }
    
    enum CreatorNotificationTab: String, CaseIterable {
        case following = "Following"
        case recent = "Recent"
        case trending = "Trending"
        
        var systemImage: String {
            switch self {
            case .following: return "person.badge.plus.fill"
            case .recent: return "clock.fill"
            case .trending: return "flame.fill"
            }
        }
    }
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                creatorNotificationsHeader
                
                // Tabs
                tabsView
                
                // Content
                if creatorNotificationViewModel.isLoading {
                    LoadingStateView(message: "Loading creator notifications...")
                        .frame(maxHeight: .infinity)
                } else {
                    switch selectedTab {
                    case .following:
                        followingCreatorsView
                    case .recent:
                        recentNotificationsView
                    case .trending:
                        trendingCreatorsView
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await creatorNotificationViewModel.loadData()
            }
            
            // Auto-focus back button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(item: $selectedCreator) { creator in
            CreatorNotificationSettingsView(creator: creator)
                .environmentObject(creatorNotificationViewModel)
        }
        .sheet(item: $selectedNotification) { notification in
            CreatorNotificationDetailView(notification: notification)
                .environmentObject(creatorNotificationViewModel)
        }
    }
    
    // MARK: - Header
    
    private var creatorNotificationsHeader: some View {
        VStack(spacing: 20) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
                
                Text("Creator Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                FocusableButton("Settings", systemImage: "gear") {
                    // Show notification preferences
                }
                .focused($focusedSection, equals: .preferences)
            }
            
            // Stats Row
            creatorStatsView
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
    
    private var creatorStatsView: some View {
        HStack(spacing: 40) {
            CreatorStatCard(
                title: "Following",
                value: creatorNotificationViewModel.followingCount.formatted(.number),
                color: .blue
            )
            
            CreatorStatCard(
                title: "New Today",
                value: creatorNotificationViewModel.newContentTodayCount.formatted(.number),
                color: .green
            )
            
            CreatorStatCard(
                title: "Unread",
                value: creatorNotificationViewModel.unreadNotificationsCount.formatted(.number),
                color: .orange
            )
            
            CreatorStatCard(
                title: "This Week",
                value: creatorNotificationViewModel.contentThisWeekCount.formatted(.number),
                color: .purple
            )
            
            Spacer()
        }
    }
    
    // MARK: - Tabs
    
    private var tabsView: some View {
        HStack(spacing: 16) {
            ForEach(CreatorNotificationTab.allCases, id: \.self) { tab in
                CreatorTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isFocused: focusedSection == .tab(tab)
                ) {
                    selectedTab = tab
                    creatorNotificationViewModel.setActiveTab(tab)
                }
                .focused($focusedSection, equals: .tab(tab))
            }
            
            Spacer()
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Content Views
    
    private var followingCreatorsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(creatorNotificationViewModel.followingCreators, id: \.id) { creator in
                    FollowingCreatorRow(
                        creator: creator,
                        isFocused: focusedSection == .creator(creator.id)
                    ) {
                        selectedCreator = creator
                    }
                    .focused($focusedSection, equals: .creator(creator.id))
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    private var recentNotificationsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(creatorNotificationViewModel.recentNotifications, id: \.id) { notification in
                    CreatorNotificationRow(
                        notification: notification,
                        isFocused: focusedSection == .notification(notification.id)
                    ) {
                        selectedNotification = notification
                        creatorNotificationViewModel.markNotificationAsRead(notification.id)
                    }
                    .focused($focusedSection, equals: .notification(notification.id))
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
    
    private var trendingCreatorsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(creatorNotificationViewModel.trendingCreators, id: \.id) { creator in
                    TrendingCreatorRow(
                        creator: creator,
                        isFocused: focusedSection == .creator(creator.id)
                    ) {
                        // Follow creator action
                        Task {
                            await creatorNotificationViewModel.followCreator(creator.id)
                        }
                    }
                    .focused($focusedSection, equals: .creator(creator.id))
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 30)
        }
    }
}

// MARK: - Supporting Views

struct CreatorStatCard: View {
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

struct CreatorTabButton: View {
    let tab: CreatorNotificationsView.CreatorNotificationTab
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
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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
            return .blue
        } else {
            return .white
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else if isSelected {
            return .blue.opacity(0.2)
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

struct FollowingCreatorRow: View {
    let creator: Creator
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Creator Avatar
                AsyncImage(url: URL(string: creator.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Creator Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(creator.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if creator.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    
                    Text(creator.bio)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(creator.followersCount.formatted(.number.notation(.compactName))) followers")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text("\(creator.totalVideos) videos")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Notification status
                        if creator.hasNewContent {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                
                                Text("New content")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // Notification settings indicator
                Image(systemName: creator.notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                    .font(.body)
                    .foregroundColor(creator.notificationsEnabled ? .green : .gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct CreatorNotificationRow: View {
    let notification: CreatorNotification
    let isFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Creator Avatar
                AsyncImage(url: URL(string: notification.creator.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // Notification Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(notification.creator.displayName)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("posted new content")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(notification.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(notification.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let description = notification.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                // Thumbnail and status
                VStack(spacing: 8) {
                    if let thumbnailURL = notification.thumbnailURL {
                        AsyncImage(url: URL(string: thumbnailURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : (notification.isRead ? 0.05 : 0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct TrendingCreatorRow: View {
    let creator: Creator
    let isFocused: Bool
    let onFollow: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Creator Avatar with trending indicator
            ZStack {
                AsyncImage(url: URL(string: creator.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                // Trending badge
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(4)
                    .background(Circle().fill(Color.black))
                    .offset(x: 20, y: -20)
            }
            
            // Creator Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(creator.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if creator.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                
                Text(creator.bio)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text("\(creator.followersCount.formatted(.number.notation(.compactName))) followers")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text("Trending")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            
            // Follow Button
            Button(action: onFollow) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.caption)
                    Text("Follow")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 2 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Detail Views (Placeholders)

struct CreatorNotificationSettingsView: View {
    let creator: Creator
    
    @EnvironmentObject private var creatorNotificationViewModel: CreatorNotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Creator Notification Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Settings for \(creator.displayName)")
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

struct CreatorNotificationDetailView: View {
    let notification: CreatorNotification
    
    @EnvironmentObject private var creatorNotificationViewModel: CreatorNotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        TVNavigationView {
            VStack {
                Text("Notification Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(notification.title)
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

#Preview {
    CreatorNotificationsView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
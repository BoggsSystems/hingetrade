//
//  HelpView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct HelpView: View {
    @StateObject private var helpViewModel = HelpViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: HelpSection?
    
    @State private var selectedCategory: HelpCategory = .gettingStarted
    @State private var searchText: String = ""
    @State private var showingSearch = false
    
    enum HelpSection: Hashable {
        case back
        case search
        case category(HelpCategory)
        case article(String)
        case contact
    }
    
    var body: some View {
        TVNavigationView {
            HStack(spacing: 0) {
                // Sidebar
                helpSidebar
                
                // Content Area
                helpContent
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            Task {
                await helpViewModel.loadHelpContent()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = .back
            }
        }
        .sheet(isPresented: $showingSearch) {
            HelpSearchView(searchText: $searchText)
                .environmentObject(helpViewModel)
        }
    }
    
    // MARK: - Sidebar
    
    private var helpSidebar: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            // Search
            searchSection
            
            // Categories
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(HelpCategory.allCases, id: \.self) { category in
                        HelpCategoryItem(
                            category: category,
                            isSelected: selectedCategory == category,
                            isFocused: focusedSection == .category(category),
                            articleCount: helpViewModel.getArticleCount(for: category)
                        ) {
                            selectedCategory = category
                        }
                        .focused($focusedSection, equals: .category(category))
                    }
                }
                .padding(.vertical, 20)
            }
            
            Spacer()
            
            // Contact Support
            contactSection
        }
        .frame(width: 320)
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
    }
    
    private var sidebarHeader: some View {
        VStack(spacing: 16) {
            HStack {
                FocusableButton("Back", systemImage: "chevron.left") {
                    dismiss()
                }
                .focused($focusedSection, equals: .back)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Help & Support")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            FocusableButton("Search Help Articles", systemImage: "magnifyingglass") {
                showingSearch = true
            }
            .focused($focusedSection, equals: .search)
            
            Divider()
                .background(Color.white.opacity(0.2))
        }
        .padding(.horizontal, 24)
    }
    
    private var contactSection: some View {
        VStack(spacing: 12) {
            FocusableButton("Contact Support", systemImage: "person.2.fill") {
                // Open contact support
            }
            .focused($focusedSection, equals: .contact)
            
            Text("Available 24/7")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Content Area
    
    private var helpContent: some View {
        VStack(spacing: 0) {
            // Content Header
            contentHeader
            
            // Help Articles
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(helpViewModel.getArticles(for: selectedCategory), id: \.id) { article in
                        HelpArticleRow(
                            article: article,
                            isFocused: focusedSection == .article(article.id)
                        ) {
                            // Navigate to article detail
                        }
                        .focused($focusedSection, equals: .article(article.id))
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 30)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var contentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: selectedCategory.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(selectedCategory.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(selectedCategory.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if helpViewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 30)
        .background(Color.white.opacity(0.02))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Supporting Views

struct HelpCategoryItem: View {
    let category: HelpCategory
    let isSelected: Bool
    let isFocused: Bool
    let articleCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(textColor)
                    
                    Text("\(articleCount) articles")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }
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
        .padding(.horizontal, 16)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var iconColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .blue
        } else {
            return .gray
        }
    }
    
    private var textColor: Color {
        if isFocused {
            return .black
        } else if isSelected {
            return .white
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
            return Color.clear
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

struct HelpArticleRow: View {
    let article: HelpArticle
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(article.summary)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(article.readingTimeMinutes) min read")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if article.isPopular {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                
                                Text("Popular")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        if article.isNew {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Text("New")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
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

struct HelpSearchView: View {
    @EnvironmentObject private var helpViewModel: HelpViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Search Help")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.blue)
                    .opacity(searchText.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                
                // Search Field
                TextField("Search help articles...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .stroke(isSearchFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .focused($isSearchFocused)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                
                // Search Results
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(helpViewModel.searchResults, id: \.id) { article in
                            HelpSearchResultRow(article: article) {
                                // Navigate to article
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: searchText) { query in
            helpViewModel.searchArticles(query: query)
        }
    }
}

struct HelpSearchResultRow: View {
    let article: HelpArticle
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(article.summary)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(article.category.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    let actions: [QuickAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(actions, id: \.id) { action in
                    QuickActionCard(action: action)
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let action: QuickAction
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(action.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.green : Color.blue.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

#Preview {
    HelpView()
        .preferredColorScheme(.dark)
}
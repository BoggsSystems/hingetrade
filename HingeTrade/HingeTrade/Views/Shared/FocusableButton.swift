//
//  FocusableButton.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct FocusableButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title2)
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .foregroundColor(isFocused ? .black : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isFocused ? 3 : 0)
            )
        }
        .focused($isFocused)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        #if !os(tvOS)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        #endif
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        return .green
    }
}

// MARK: - FocusableCard

struct FocusableCard<Content: View>: View {
    let content: Content
    let action: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    @State private var isPressed: Bool = false
    
    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private var cardContent: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
                    .scaleEffect(isPressed ? 0.98 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            #if !os(tvOS)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if action != nil {
                    isPressed = pressing
                }
            }, perform: {})
        #endif
    }
}

// MARK: - TVNavigationView

struct TVNavigationView<Content: View>: View {
    let content: Content
    
    @FocusState private var isNavigationFocused: Bool
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
                .focused($isNavigationFocused)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Auto-focus the navigation area on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNavigationFocused = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FocusableButton("Sign In", systemImage: "person.fill") {
            print("Sign In tapped")
        }
        
        FocusableCard(action: {
            print("Card tapped")
        }) {
            VStack {
                Text("Sample Card")
                    .font(.title2)
                Text("This is focusable content")
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
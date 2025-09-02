//
//  WelcomeView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @State private var showingSignIn = false
    @State private var showingOnboarding = false
    @FocusState private var focusedButton: WelcomeButton?
    
    enum WelcomeButton: Hashable {
        case signIn
        case getStarted
        case watchDemo
    }
    
    var body: some View {
        TVNavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.black, Color.black.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo and Branding
                    VStack(spacing: 16) {
                        Image(systemName: "tv.and.hifispeaker.fill")
                            .font(.system(size: 120))
                            .foregroundStyle(.green)
                        
                        Text("HingeTrade")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Tradeable Video Experience")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    // Value Proposition
                    VStack(spacing: 12) {
                        Text("Discover finance in a new way")
                            .font(.title)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Watch, learn, and trade directly from your TV")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 100)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 40) {
                        FocusableButton("Sign In", systemImage: "person.fill") {
                            showingSignIn = true
                        }
                        .focused($focusedButton, equals: .signIn)
                        
                        FocusableButton("Get Started", systemImage: "play.fill") {
                            showingOnboarding = true
                        }
                        .focused($focusedButton, equals: .getStarted)
                        
                        FocusableButton("Watch Demo", systemImage: "tv.fill") {
                            // TODO: Show demo video
                        }
                        .focused($focusedButton, equals: .watchDemo)
                    }
                    
                    // Legal Text
                    VStack(spacing: 8) {
                        Text("Not investment advice. Trading involves risk.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Securities offered by Alpaca Securities LLC")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(60)
            }
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingWelcomeView()
        }
        .onAppear {
            // Auto-focus the primary button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedButton = appState.isAuthenticated ? .getStarted : .signIn
            }
        }
    }
}

// MARK: - OnboardingWelcomeView (Placeholder)

struct OnboardingWelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to HingeTrade!")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("Let's set up your account")
                .font(.title2)
                .foregroundColor(.gray)
            
            QRCodeOnboardingView()
            
            FocusableButton("Close") {
                dismiss()
            }
        }
        .padding(60)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
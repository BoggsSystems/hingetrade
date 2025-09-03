//
//  QRCodeOnboardingView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct QRCodeOnboardingView: View {
    @StateObject private var onboardingViewModel = QRCodeOnboardingViewModel()
    @State private var sessionToken: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "smartphone")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Continue on Mobile")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Complete account setup on your mobile device for faster typing")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
            
            // QR Code Container
            VStack(spacing: 20) {
                if onboardingViewModel.isGeneratingQR {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2.0)
                            .tint(.green)
                        
                        Text("Generating secure link...")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 300, height: 300)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                } else {
                    // QR Code
                    QRCodeDisplay(
                        url: onboardingViewModel.mobileOnboardingURL,
                        size: 300
                    )
                }
                
                // Instructions
                VStack(spacing: 8) {
                    Text("Scan with your camera app")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Or visit: \(onboardingViewModel.shortURL)")
                        .font(.body)
                        .foregroundColor(.gray)
                        #if os(iOS)
                        .textSelection(.enabled)
                        #endif
                }
            }
            
            // Status Updates
            if onboardingViewModel.mobileSessionActive {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Mobile device connected")
                            .foregroundColor(.green)
                    }
                    .font(.title3)
                    
                    Text("Complete the setup process on your mobile device")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Alternative option
            if !onboardingViewModel.mobileSessionActive {
                VStack(spacing: 16) {
                    Text("Having trouble?")
                        .foregroundColor(.gray)
                    
                    FocusableButton("Continue on TV", systemImage: "tv.fill") {
                        onboardingViewModel.startTVOnboarding()
                    }
                    .focused($isFocused)
                }
            }
        }
        .padding(40)
        .onAppear {
            Task {
                await onboardingViewModel.generateMobileLink()
            }
            
            // Auto-focus for navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
        .onReceive(onboardingViewModel.sessionStatusTimer) { _ in
            Task {
                await onboardingViewModel.checkSessionStatus()
            }
        }
    }
}

// MARK: - QRCodeDisplay

struct QRCodeDisplay: View {
    let url: String
    let size: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .frame(width: size, height: size)
            .overlay(
                VStack(spacing: 12) {
                    // Placeholder QR Code - In production, use CoreImage to generate actual QR code
                    Grid {
                        ForEach(0..<25) { row in
                            GridRow {
                                ForEach(0..<25) { col in
                                    Rectangle()
                                        .fill(qrPixelColor(row: row, col: col))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                    
                    Text("Scan to continue")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                .padding(20)
            )
            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func qrPixelColor(row: Int, col: Int) -> Color {
        // Simple pattern generation for demo purposes
        let isBlack = (row + col) % 3 == 0 || (row % 5 == 0 && col % 5 == 0)
        return isBlack ? .black : .white
    }
}

// MARK: - OnboardingViewModel

@MainActor
class QRCodeOnboardingViewModel: ObservableObject {
    @Published var isGeneratingQR: Bool = false
    @Published var mobileOnboardingURL: String = ""
    @Published var shortURL: String = ""
    @Published var mobileSessionActive: Bool = false
    @Published var sessionToken: String = ""
    
    let sessionStatusTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    func generateMobileLink() async {
        isGeneratingQR = true
        
        // Generate unique session token
        sessionToken = UUID().uuidString
        
        // Simulate API call to generate mobile onboarding link
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        mobileOnboardingURL = "https://hingetrade.com/onboard/mobile?session=\(sessionToken)"
        shortURL = "hinge.trade/\(sessionToken.prefix(8))"
        
        isGeneratingQR = false
    }
    
    func checkSessionStatus() async {
        guard !sessionToken.isEmpty else { return }
        
        // Simulate checking if mobile device has connected
        // In production, this would check the session status via API
        
        // For demo, randomly activate after some time
        if !mobileSessionActive && Bool.random() && sessionToken.count > 0 {
            mobileSessionActive = true
        }
    }
    
    func startTVOnboarding() {
        // Fallback to TV-based onboarding flow
        // TODO: Navigate to TV onboarding flow
        print("Starting TV-based onboarding")
    }
}

#Preview {
    QRCodeOnboardingView()
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
}
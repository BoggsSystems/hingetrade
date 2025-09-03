//
//  OnboardingView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSection: OnboardingSection?
    
    @State private var currentStep = 0
    @State private var showingSkipConfirmation = false
    
    enum OnboardingSection: Hashable {
        case next
        case skip
        case getStarted
        case option(String)
        case input(String)
    }
    
    var body: some View {
        TVNavigationView {
            ZStack {
                // Background
                backgroundGradient
                
                // Content
                VStack(spacing: 0) {
                    // Progress Indicator
                    if currentStep < onboardingSteps.count - 1 {
                        progressIndicator
                    }
                    
                    // Step Content
                    stepContent
                        .frame(maxHeight: .infinity)
                    
                    // Navigation Controls
                    navigationControls
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedSection = currentStep == onboardingSteps.count - 1 ? .getStarted : .next
            }
        }
        .alert("Skip Onboarding", isPresented: $showingSkipConfirmation) {
            Button("Continue Onboarding", role: .cancel) { }
            Button("Skip") {
                completeOnboarding()
            }
        } message: {
            Text("Are you sure you want to skip the setup? You can always configure these settings later.")
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.3),
                Color.purple.opacity(0.2),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<onboardingSteps.count - 1, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.blue : Color.white.opacity(0.3))
                    .frame(width: index == currentStep ? 40 : 20, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 60)
    }
    
    private var stepContent: some View {
        VStack {
            switch currentStep {
            case 0:
                WelcomeStep()
            case 1:
                TradingExperienceStep()
                    .environmentObject(onboardingViewModel)
            case 2:
                RiskProfileStep()
                    .environmentObject(onboardingViewModel)
            case 3:
                NotificationPreferencesStep()
                    .environmentObject(onboardingViewModel)
            case 4:
                AccountSetupStep()
                    .environmentObject(onboardingViewModel)
            case 5:
                ReadyToStartStep()
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 40)
    }
    
    private var navigationControls: some View {
        HStack {
            // Skip Button
            if currentStep < onboardingSteps.count - 1 {
                FocusableButton("Skip Setup", systemImage: "arrow.right") {
                    showingSkipConfirmation = true
                }
                .focused($focusedSection, equals: .skip)
            }
            
            Spacer()
            
            // Next/Get Started Button
            if currentStep == onboardingSteps.count - 1 {
                FocusableButton("Get Started", systemImage: "checkmark.circle.fill") {
                    completeOnboarding()
                }
                .focused($focusedSection, equals: .getStarted)
                .buttonStyle(PrimaryButtonStyle())
            } else {
                FocusableButton("Next", systemImage: "chevron.right") {
                    nextStep()
                }
                .focused($focusedSection, equals: .next)
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 60)
    }
    
    private var onboardingSteps: [OnboardingStepType] {
        [.welcome, .experience, .riskProfile, .notifications, .account, .ready]
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
        
        // Auto-focus appropriate control
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            focusedSection = currentStep == onboardingSteps.count - 1 ? .getStarted : .next
        }
    }
    
    private func completeOnboarding() {
        // Save onboarding completion
        onboardingViewModel.completeOnboarding()
        
        // Update app state
        appState.needsOnboarding = false
        appState.isFirstLaunch = false
        
        // Dismiss onboarding
        dismiss()
    }
}

// MARK: - Onboarding Steps

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 30) {
            // App Icon
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Text("Welcome to HingeTrade")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your complete trading platform for Apple TV")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                FeatureHighlight(
                    icon: "chart.bar.fill",
                    title: "Real-time Market Data",
                    description: "Live quotes and advanced charting"
                )
                
                FeatureHighlight(
                    icon: "shield.fill",
                    title: "Advanced Risk Management",
                    description: "Sophisticated tools to protect your portfolio"
                )
                
                FeatureHighlight(
                    icon: "brain.head.profile",
                    title: "AI-Powered Analytics",
                    description: "Intelligent insights and recommendations"
                )
            }
            .padding(.top, 20)
        }
    }
}

struct TradingExperienceStep: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @FocusState private var focusedOption: TradingExperience?
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("What's your trading experience?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This helps us customize your experience and set appropriate defaults")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(TradingExperience.allCases, id: \.self) { experience in
                    ExperienceOptionCard(
                        experience: experience,
                        isSelected: onboardingViewModel.selectedExperience == experience,
                        isFocused: focusedOption == experience
                    ) {
                        onboardingViewModel.selectedExperience = experience
                    }
                    .focused($focusedOption, equals: experience)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedOption = onboardingViewModel.selectedExperience
            }
        }
    }
}

struct RiskProfileStep: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @FocusState private var focusedProfile: RiskProfile?
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("Choose your risk profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll set up risk management rules based on your comfort level")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(RiskProfile.allCases, id: \.self) { profile in
                    RiskProfileCard(
                        profile: profile,
                        isSelected: onboardingViewModel.selectedRiskProfile == profile,
                        isFocused: focusedProfile == profile
                    ) {
                        onboardingViewModel.selectedRiskProfile = profile
                    }
                    .focused($focusedProfile, equals: profile)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedProfile = onboardingViewModel.selectedRiskProfile
            }
        }
    }
}

struct NotificationPreferencesStep: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @FocusState private var focusedToggle: OnboardingNotificationType?
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("Notification preferences")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Choose which notifications you'd like to receive")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                ForEach(OnboardingNotificationType.allCases, id: \.self) { type in
                    NotificationToggleRow(
                        type: type,
                        isEnabled: onboardingViewModel.notificationPreferences[type] ?? true,
                        isFocused: focusedToggle == type
                    ) { enabled in
                        onboardingViewModel.notificationPreferences[type] = enabled
                    }
                    .focused($focusedToggle, equals: type)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedToggle = OnboardingNotificationType.allCases.first
            }
        }
    }
}

struct AccountSetupStep: View {
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @FocusState private var focusedField: AccountField?
    
    enum AccountField {
        case displayName
        case email
    }
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Text("Set up your profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Enter your basic information to personalize your experience")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                OnboardingTextField(
                    title: "Display Name",
                    text: $onboardingViewModel.displayName,
                    placeholder: "Enter your name",
                    isFocused: focusedField == .displayName
                )
                .focused($focusedField, equals: .displayName)
                
                OnboardingTextField(
                    title: "Email Address",
                    text: $onboardingViewModel.email,
                    placeholder: "Enter your email",
                    isFocused: focusedField == .email
                )
                .focused($focusedField, equals: .email)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .displayName
            }
        }
    }
}

struct ReadyToStartStep: View {
    var body: some View {
        VStack(spacing: 40) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            VStack(spacing: 20) {
                Text("You're all set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your HingeTrade experience has been customized based on your preferences.")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ReadyFeature(
                    icon: "star.fill",
                    title: "Personalized Dashboard",
                    description: "Tailored to your trading style"
                )
                
                ReadyFeature(
                    icon: "shield.checkered",
                    title: "Risk Management",
                    description: "Configured for your risk profile"
                )
                
                ReadyFeature(
                    icon: "bell.fill",
                    title: "Smart Notifications",
                    description: "Only the alerts you want"
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct ExperienceOptionCard: View {
    let experience: TradingExperience
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(experience.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(experience.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white.opacity(0.1)
        } else if isSelected {
            return .blue.opacity(0.2)
        } else {
            return .white.opacity(0.05)
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
        (isFocused || isSelected) ? 2 : 0
    }
}

struct RiskProfileCard: View {
    let profile: RiskProfile
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Text(profile.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                Text(profile.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < profile.riskLevel ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("Risk Level")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white.opacity(0.1)
        } else if isSelected {
            return .blue.opacity(0.2)
        } else {
            return .white.opacity(0.05)
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
        (isFocused || isSelected) ? 2 : 0
    }
}

struct NotificationToggleRow: View {
    let type: OnboardingNotificationType
    let isEnabled: Bool
    let isFocused: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button {
            onToggle(!isEnabled)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(isEnabled))
                    #if os(iOS)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    #endif
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct OnboardingTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: isFocused ? 2 : 0)
                )
        }
    }
}

struct ReadyFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
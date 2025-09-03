//
//  AuthenticationViewModel.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: AuthenticationError?
    @Published var showingError: Bool = false
    
    // Onboarding state
    @Published var onboardingStep: OnboardingStep = .welcome
    @Published var kycStatus: KYCStatus = .notStarted
    @Published var accountLinkingStatus: AccountLinkingStatus = .notLinked
    
    private let authenticationService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    enum OnboardingStep: CaseIterable {
        case welcome
        case personalInfo
        case addressInfo
        case financialProfile
        case identityVerification
        case documentUpload
        case accountLinking
        case fundingSetup
        case reviewSubmit
        case complete
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .personalInfo: return "Personal Information"
            case .addressInfo: return "Address Information"
            case .financialProfile: return "Financial Profile"
            case .identityVerification: return "Identity Verification"
            case .documentUpload: return "Document Upload"
            case .accountLinking: return "Account Linking"
            case .fundingSetup: return "Funding Setup"
            case .reviewSubmit: return "Review & Submit"
            case .complete: return "Complete"
            }
        }
        
        var description: String {
            switch self {
            case .welcome: return "Let's get started with your HingeTrade account"
            case .personalInfo: return "Tell us about yourself"
            case .addressInfo: return "Provide your address information"
            case .financialProfile: return "Help us understand your investment experience"
            case .identityVerification: return "Verify your identity"
            case .documentUpload: return "Upload required documents"
            case .accountLinking: return "Link your brokerage account"
            case .fundingSetup: return "Set up account funding"
            case .reviewSubmit: return "Review your information and submit"
            case .complete: return "Your account is ready!"
            }
        }
    }
    
    enum KYCStatus {
        case notStarted
        case inProgress
        case submitted
        case approved
        case rejected
        case needsReview
    }
    
    enum AccountLinkingStatus {
        case notLinked
        case linking
        case linked
        case failed
    }
    
    init(authenticationService: AuthenticationService = AuthenticationService(apiClient: APIClient(baseURL: URL(string: "https://paper-api.alpaca.markets")!, tokenManager: TokenManager()), tokenManager: TokenManager())) {
        self.authenticationService = authenticationService
        setupBindings()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        authenticationService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = AuthenticationError.signInFailed(error.localizedDescription)
                        self?.showingError = true
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isAuthenticated = true
                }
            )
            .store(in: &cancellables)
    }
    
    func signOut() {
        authenticationService.logout()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    // Handle completion if needed
                },
                receiveValue: { [weak self] _ in
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            )
            .store(in: &cancellables)
        currentUser = nil
        isAuthenticated = false
        resetOnboardingState()
    }
    
    func createAccount(email: String, password: String) async {
        isLoading = true
        error = nil
        
        // TODO: Implement account creation when AuthenticationService supports it
        self.error = AuthenticationError.accountCreationFailed("Account creation not yet implemented")
        self.showingError = true
        
        isLoading = false
    }
    
    private func checkAuthenticationStatus() {
        isAuthenticated = authenticationService.isAuthenticated
        if isAuthenticated {
            currentUser = authenticationService.currentUser
            // TODO: Check onboarding completion status
        }
    }
    
    // MARK: - Onboarding Flow
    
    func nextOnboardingStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: onboardingStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            return
        }
        onboardingStep = OnboardingStep.allCases[currentIndex + 1]
    }
    
    func previousOnboardingStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: onboardingStep),
              currentIndex > 0 else {
            return
        }
        onboardingStep = OnboardingStep.allCases[currentIndex - 1]
    }
    
    func completeOnboarding() async {
        isLoading = true
        
        // TODO: Submit all onboarding data
        // For now, simulate completion
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        onboardingStep = .complete
        isLoading = false
    }
    
    private func resetOnboardingState() {
        onboardingStep = .welcome
        kycStatus = .notStarted
        accountLinkingStatus = .notLinked
    }
    
    // MARK: - KYC Process
    
    func submitKYCInformation() async {
        kycStatus = .inProgress
        
        // TODO: Submit KYC data to backend
        // For now, simulate submission
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        kycStatus = .submitted
    }
    
    func checkKYCStatus() async {
        // TODO: Check KYC status from backend
        // For now, simulate approval
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        kycStatus = .approved
    }
    
    // MARK: - Account Linking
    
    func linkAccount(apiKey: String, apiSecret: String, environment: String) async {
        accountLinkingStatus = .linking
        
        do {
            // TODO: Implement actual account linking
            try await Task.sleep(nanoseconds: 2_000_000_000)
            accountLinkingStatus = .linked
        } catch {
            accountLinkingStatus = .failed
            self.error = AuthenticationError.accountLinkingFailed(error.localizedDescription)
            self.showingError = true
        }
    }
    
    // MARK: - Error Handling
    
    private func setupBindings() {
        $error
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.showingError = true
            }
            .store(in: &cancellables)
    }
    
    func dismissError() {
        error = nil
        showingError = false
    }
}

// MARK: - AuthenticationError

enum AuthenticationError: LocalizedError, Identifiable {
    case signInFailed(String)
    case accountCreationFailed(String)
    case accountLinkingFailed(String)
    case kycFailed(String)
    case networkError(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .signInFailed(let message),
             .accountCreationFailed(let message),
             .accountLinkingFailed(let message),
             .kycFailed(let message),
             .networkError(let message),
             .unknown(let message):
            return message
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .accountCreationFailed(let message):
            return "Account creation failed: \(message)"
        case .accountLinkingFailed(let message):
            return "Account linking failed: \(message)"
        case .kycFailed(let message):
            return "KYC verification failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .signInFailed:
            return "Please check your credentials and try again."
        case .accountCreationFailed:
            return "Please verify your information and try again."
        case .accountLinkingFailed:
            return "Please check your API credentials and try again."
        case .kycFailed:
            return "Please review your information and resubmit."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}
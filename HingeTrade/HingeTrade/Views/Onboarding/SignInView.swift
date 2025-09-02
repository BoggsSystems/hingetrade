//
//  SignInView.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingQRCode = false
    @FocusState private var focusedField: SignInField?
    
    enum SignInField: Hashable {
        case email
        case password
        case signIn
        case qrCode
        case cancel
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Sign In")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Enter your credentials or use mobile device")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Sign In Form
                VStack(spacing: 30) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(TVTextFieldStyle())
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(TVTextFieldStyle())
                            .focused($focusedField, equals: .password)
                            .textContentType(.password)
                    }
                    
                    // Sign In Button
                    FocusableButton("Sign In", systemImage: "arrow.right.circle.fill") {
                        Task {
                            await signIn()
                        }
                    }
                    .focused($focusedField, equals: .signIn)
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                }
                .padding(.horizontal, 100)
                
                // Alternative Options
                VStack(spacing: 20) {
                    Text("Or")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    FocusableButton("Use Mobile Device", systemImage: "qrcode") {
                        showingQRCode = true
                    }
                    .focused($focusedField, equals: .qrCode)
                }
                
                Spacer()
                
                // Cancel Button
                FocusableButton("Cancel") {
                    dismiss()
                }
                .focused($focusedField, equals: .cancel)
            }
            .padding(60)
            
            // Loading Overlay
            if authViewModel.isLoading {
                LoadingOverlay()
            }
        }
        .alert("Sign In Error", isPresented: $authViewModel.showingError) {
            Button("OK") {
                authViewModel.dismissError()
            }
        } message: {
            Text(authViewModel.error?.localizedDescription ?? "Unknown error occurred")
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeSignInView()
        }
        .onAppear {
            // Auto-focus email field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .email
            }
        }
        .onChange(of: appState.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private func signIn() async {
        await authViewModel.signIn(email: email, password: password)
        if authViewModel.isAuthenticated {
            await appState.signIn(email: email, password: password)
        }
    }
}

// MARK: - TVTextFieldStyle

struct TVTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.title2)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green, lineWidth: isFocused ? 2 : 0)
                    )
            )
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - LoadingOverlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(.green)
                
                Text("Signing In...")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - QRCodeSignInView (Placeholder)

struct QRCodeSignInView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Sign In with Mobile")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("Scan this QR code with your mobile device")
                .font(.title2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            QRCodeView(url: "https://hingetrade.com/auth/mobile?token=demo")
            
            FocusableButton("Cancel") {
                dismiss()
            }
        }
        .padding(60)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - QRCodeView (Placeholder)

struct QRCodeView: View {
    let url: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .frame(width: 300, height: 300)
            .overlay(
                VStack {
                    Image(systemName: "qrcode")
                        .font(.system(size: 200))
                        .foregroundColor(.black)
                    
                    Text("QR Code")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            )
    }
}

#Preview {
    SignInView()
        .environmentObject(AppStateViewModel())
        .preferredColorScheme(.dark)
}
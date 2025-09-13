//
//  SigninView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//

import SwiftUI

struct SigninView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingFaceID = false
    @State private var showSignUp = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var forgotPassword = false
    @State private var isBiometricLoading = false
    
    var body: some View {
        NavigationStack {
            Group {
                if showSignUp {
                    SignUpView()
                } else {
                    signinContent
                }
            }
            .animation(.none, value: showSignUp)
            .navigationDestination(isPresented: $forgotPassword) {
                ForgotPasswordView()
                    .navigationBarBackButtonHidden(true)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
      
        }
        .navigationBarHidden(true)
    }
    
    private var signinContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: "000000")
                    .ignoresSafeArea()
                
                // Content overlay
                VStack {
                    ZStack {
                        Image("cafe")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 390)
                            .cornerRadius(20)
                            .clipped()
                            .onTapGesture {
                            }
                    }
                    .frame(height: geometry.size.height * 0.4)
                    
                    
                    VStack(spacing: 10) {
                        // Logo
                        HStack(spacing: 8) {
                            
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("QUIET DELIGHT")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 5)
                        
                        // Signin form
            VStack(spacing: 5) {
            // Email
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Email")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    Spacer()
                        }
                                
                    TextField("Enter your email", text: $email)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .foregroundColor(.white)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "FFFFFF"), lineWidth: 0.5)
                    )
            )
            .disabled(authManager.isLoading || isBiometricLoading)
            }
                            
            // Password field
        VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Password")
            .foregroundColor(.white)
            .font(.system(size: 14))
            Spacer()
                }
                                
        SecureField("Enter your password", text: $password)
        .textFieldStyle(PlainTextFieldStyle())
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .foregroundColor(.white)
        .textContentType(.password)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "CCCCCC"), lineWidth: 0.5)
                )
        )
        .disabled(authManager.isLoading || isBiometricLoading)
                            }
                            
        // Forgot password
        HStack {
        Spacer()
        Button("Forgot Password?") {
            forgotPassword = true
        }
        .foregroundColor(Color(hex: "FFFFFF"))
        .font(.system(size: 14))
        .disabled(authManager.isLoading || isBiometricLoading)
                            }
        .padding(.top, 8)
                            
    // Sign in button
        Button(action: {handleSignIn()
                            }) {
        ZStack {
            Text("Sign in")
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
            .opacity(authManager.isLoading ? 0 : 1)
                                    
        if authManager.isLoading {
            ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.8)
                                }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "5A3529"))
                    .cornerRadius(8)
                            }
                            .padding(.top, 10)
                            .disabled(authManager.isLoading || isBiometricLoading)
                            
            // Divider
            HStack {
            Rectangle()
            .fill(Color(hex: "CCCCCC"))
            .frame(height: 1)
                                
            Text("or")
            .foregroundColor(Color(hex: "FFFFFF"))
            .padding(.horizontal, 16)
                                
            Rectangle()
            .fill(Color(hex: "CCCCCC"))
            .frame(height: 1)
                    }
                    .padding(.vertical, 10)
                            
            VStack(spacing: 8) {
                Text("Face ID")
                .foregroundColor(.white)
                .font(.system(size: 16))
                                
        // Face ID button
            Button(action: {
                print("Face ID button tapped")
                handleBiometricAuth()
            }) {
                ZStack {
                    Image(systemName: "faceid")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "CCCCCC"))
                        .opacity(isBiometricLoading ? 0 : 1)
                    
                    if isBiometricLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "CCCCCC")))
                            .scaleEffect(0.8)
                    }
                }
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
            }
            .disabled(authManager.isLoading || isBiometricLoading)
            .opacity((authManager.isLoading || isBiometricLoading) ? 0.5 : 1.0)
            .scaleEffect(isBiometricLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isBiometricLoading)
                            }
                            
        // Sign up
            HStack {
            Text("Don't have an account?")
            .foregroundColor(Color(hex: "cccccc"))
            .font(.system(size: 14))
                                
        Button("Sign up") {showSignUp = true
                                }
            .foregroundColor(.white)
            .font(.system(size: 14))
            .underline()
            .disabled(authManager.isLoading || isBiometricLoading)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .background(Color(hex: "382E2C"))
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    // Action Methods
    
    private func handleSignIn() {
  
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address.")
            return
        }
        
        guard !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter your password.")
            return
        }
        
        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        // Signin
        authManager.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    print("Sign in successful")
                
                case .failure(let errorMessage):
                    print("Sign in failed: \(errorMessage)")
                    self.showAlert(title: "Sign In Failed", message: errorMessage)
                }
            }
        }
    }
    
    private func handleBiometricAuth() {
        
        guard authManager.isBiometricAuthenticationAvailable() else {
            showAlert(title: "Face ID Not Available", message: "Biometric authentication is not available on this device.")
            return
        }
        
     
        isBiometricLoading = true
        
  
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        authManager.authenticateWithBiometrics { result in
            DispatchQueue.main.async {
                // Reset loading state
                self.isBiometricLoading = false
                
                switch result {
                case .success(_):
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    print("Biometric authentication successful")
               
                case .failure(let error):
                 
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                    
                    
                    let errorMessage = handleBiometricError(error)
                    showAlert(title: "Face ID Authentication Failed", message: errorMessage)
                }
            }
        }
    }
    
    private func handleBiometricError(_ error: Error) -> String {
        let errorCode = (error as NSError).code
        
        switch errorCode {
        case -8: // LAError.notAvailable
            return "Biometric authentication is not available on this device."
        case -6: // LAError.notEnrolled
            return "No Face ID or Touch ID is enrolled. Please set up biometric authentication in Settings."
        case -2: // LAError.userCancel
            return "Authentication was cancelled by user."
        case -4: // LAError.systemCancel
            return "Authentication was cancelled by system."
        case -1: // LAError.authenticationFailed
            return "Biometric authentication failed. Please try again."
        default:
            return error.localizedDescription
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    SigninView()
}

//
//  SignUpView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//

import SwiftUI

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var enableFaceID = false
    @State private var agreeToTerms = false
    @State private var sendUpdates = false
    @State private var showSignIn = false
    
    // Auth
    @StateObject private var authManager = FirebaseAuthManager.shared
    
  
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var signUpSuccess = false
    
    var body: some View {
        Group {
            if showSignIn {
               // SigninView()
            } else {
                signUpContent
            }
        }
        .animation(.none, value: showSignIn)
        .alert("Sign Up", isPresented: $showAlert) {
            Button("OK") {
                if signUpSuccess {
                    showSignIn = true
                }
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var signUpContent: some View {
        GeometryReader { geometry in
            ZStack {
    ZStack {Image("cofeecafe")
            .resizable()
            .aspectRatio(contentMode: .fill)
            
        Rectangle()
        .fill(
        LinearGradient(
        gradient: Gradient(colors: [
        Color.black.opacity(0.5),
        Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            ))
                }
        .ignoresSafeArea()
                
    ScrollView {
        VStack(spacing: 0) {
        
    Rectangle()
    .fill(Color.clear)
    .frame(height: 50)
        
    // Logo and title section
    VStack(spacing: 16) {
    // Coffee cup logo
    Image(systemName: "cup.and.saucer.fill")
    .font(.system(size: 40))
    .foregroundColor(.white)
    
        Text("QUIET DELIGHT")
        .font(.title2)
        .fontWeight(.medium)
        .foregroundColor(.white)
        Text("Create your account to Find the perfect\nwork-friendly cafés")
        .font(.system(size: 16))
        .foregroundColor(.white.opacity(0.9))
        .multilineTextAlignment(.center)
        .lineSpacing(4)
            }
                        .padding(.bottom, 40)
                        
        // Signup form
        VStack(spacing: 15) {
           // Username
        VStack(alignment: .leading, spacing: 8) {
        Text("Username")
        .foregroundColor(.white.opacity(0.9))
        .font(.system(size: 14))
                            
        TextField("", text: $username)
        .textFieldStyle(PlainTextFieldStyle())
        .foregroundColor(.white)
        .autocapitalization(.none)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Rectangle()
            .stroke(.white.opacity(0.3), lineWidth: 1)
            .background(Color.clear)
                )}
                            
        // Email field
        VStack(alignment: .leading, spacing: 8) {
    Text("Email")
    .foregroundColor(.white.opacity(0.9))
    .font(.system(size: 14))
                
    TextField("", text: $email)
    .textFieldStyle(PlainTextFieldStyle())
    .foregroundColor(.white)
    .keyboardType(.emailAddress)
    .autocapitalization(.none)
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
        Rectangle()
        .stroke(.white.opacity(0.3), lineWidth: 1)
        .background(Color.clear))
    }
                            
    // New Password field
    VStack(alignment: .leading, spacing: 8) {
    Text("New Password")
    .foregroundColor(.white.opacity(0.9))
    .font(.system(size: 14))
                                
    SecureField("", text: $newPassword)
    .textFieldStyle(PlainTextFieldStyle())
    .foregroundColor(.white)
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Rectangle()
        .stroke(.white.opacity(0.3), lineWidth: 1)
        .background(Color.clear))
            }
                            
    // Confirm password
    VStack(alignment: .leading, spacing: 8) {
        Text("Confirm Password")
        .foregroundColor(.white.opacity(0.9))
        .font(.system(size: 14))
                                
    SecureField("", text: $confirmPassword)
    .textFieldStyle(PlainTextFieldStyle())
    .foregroundColor(.white)
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Rectangle()
    .stroke(.white.opacity(0.3), lineWidth: 1)
    .background(Color.clear)
)}
                            
    // Checkboxes
    VStack(spacing: 16) {
    // Face ID checkbox
    HStack(alignment: .top, spacing: 12) {
    Button(action: {enableFaceID.toggle()}) {
        Rectangle()
        .stroke(.white.opacity(0.6), lineWidth: 1)
        .background(enableFaceID ? Color.white.opacity(0.2) : Color.clear)                                            .frame(width: 20, height: 20)
    .overlay(
            enableFaceID ?
            Image(systemName: "checkmark")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.white): nil
            )}
                    
        Text("Enable Face ID for quick sign-in")
        .foregroundColor(.white.opacity(0.9))
        .font(.system(size: 14))
        .multilineTextAlignment(.leading)
                    
        Spacer()
            }
                                
        // Terms
            HStack(alignment: .top, spacing: 12) {
            Button(action: {
            agreeToTerms.toggle()
            }) {
                Rectangle()
            .stroke(.white.opacity(0.6), lineWidth: 1)
                                        .background(agreeToTerms ? Color.white.opacity(0.2) : Color.clear)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                agreeToTerms ?
        Image(systemName: "checkmark")
        .font(.system(size: 12, weight: .bold))
    .foregroundColor(.white): nil
)
        }
                                    
        Text("I agree to the Terms of Service and Privacy Policy")
        .foregroundColor(.white.opacity(0.9))
        .font(.system(size: 14))
        .multilineTextAlignment(.leading)
                
        Spacer()
                                }
                                
        // Updates checkbox
        HStack(alignment: .top, spacing: 12) {
        Button(action: {sendUpdates.toggle()
        }) {
        Rectangle()
        .stroke(.white.opacity(0.6), lineWidth: 1)
    .background(sendUpdates ? Color.white.opacity(0.2) : Color.clear)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                sendUpdates ?
    Image(systemName: "checkmark")
    .font(.system(size: 12, weight: .bold))
    .foregroundColor(.white): nil
                                            )
                                    }
                                    
    Text("Send me updates about new cafes and special offers")
    .foregroundColor(.white.opacity(0.9))
    .font(.system(size: 14))
    .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
    .padding(.top, 8)
                            
    // CreateAcc
    Button(action: {
        signUpWithFirebase()}) {
HStack {
        if authManager.isLoading {
            ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(0.8)}
                                    
        Text(authManager.isLoading ? "Creating Account..." : "Create Account")
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .medium))}
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "8B4513"))
        .cornerRadius(8)
    .opacity(authManager.isLoading ? 0.7 : 1.0)}
    .disabled(authManager.isLoading)
            .padding(.top, 20)
                            
                            // Sign in link
        HStack {
            Text("Already have an account?")
            .foregroundColor(.white.opacity(0.9))
            .font(.system(size: 14))
                        
            Button("Sign In") {
            showSignIn = true }
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                                .underline()
                                .disabled(authManager.isLoading)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    //functions
    private func signUpWithFirebase() {
        authManager.signUp(
            username: username,
            email: email,
            password: newPassword,
            confirmPassword: confirmPassword,
            enableFaceID: enableFaceID,
            sendUpdates: sendUpdates,
            agreeToTerms: agreeToTerms
        ) { result in
            switch result {
            case .success(let message):
                signUpSuccess = true
                errorMessage = message
                showAlert = true
            case .failure(let error):
                signUpSuccess = false
                errorMessage = error
                showAlert = true
            }
        }
    }
}


#Preview {
    SignUpView()
}

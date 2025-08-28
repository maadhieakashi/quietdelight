//
//  ForgotPasswordView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//


import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showSignUp = false
    @State private var navigateToSignIn = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        navigateToSignIn = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    
                    Button("create an account") {
                        showSignUp = true
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 16))
                    .underline()
                }
                .navigationBarHidden(true)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Content
                VStack(spacing: 30) {
                    // Lock icon
                    VStack(spacing: 20) {
                        Image(systemName: "lock.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .frame(width: 70, height: 70)
                            )
                        
                        VStack(spacing: 8) {
                            Text("FORGOT PASSWORD ?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("No worries,we'll send you reset instruction")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.vertical, 12)
                            .padding(.horizontal, 0)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3)),
                                alignment: .bottom
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.horizontal, 30)
                    
                    // Reset button
                    VStack(spacing: 15) {
                        Button(action: {
                            resetPassword()
                        }) {
                            Text("Reset Password")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: "5A3529"))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 30)
                    }
                }
                
                Spacer()
                Spacer()
            }
            .navigationBarHidden(true)
            .background(Color.white)
            // Modern Navigation using navigationDestination
            .navigationDestination(isPresented: $navigateToSignIn) {
                SigninView()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
        .navigationBarHidden(true)
        .alert("Reset Email Sent", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("Password reset instructions have been sent") {
                    navigateToSignIn = true
                } else {
                   
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address"
            showingAlert = true
            return
        }
        
        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
    
        sendResetEmail(to: email)
    }
    
    private func sendResetEmail(to email: String) {
        guard let url = URL(string: "https://your-api-endpoint.com/forgot-password") else {
            alertMessage = "Error: Invalid server configuration"
            showingAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["email": email]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            alertMessage = "Error: Failed to prepare request"
            showingAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                    self.showingAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.alertMessage = "Error: Invalid server response"
                    self.showingAlert = true
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.alertMessage = "Password reset instructions have been sent to \(email)"
                    self.showingAlert = true
                } else {
                    // Handle different error codes
                    switch httpResponse.statusCode {
                    case 404:
                        self.alertMessage = "Email address not found"
                    case 429:
                        self.alertMessage = "Too many requests. Please try again later"
                    default:
                        self.alertMessage = "Failed to send reset email. Please try again"
                    }
                    self.showingAlert = true
                }
            }
        }.resume()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    ForgotPasswordView()
}

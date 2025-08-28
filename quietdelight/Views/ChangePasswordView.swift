//
//  ChangePasswordView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-27.
//

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Current Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    SecureField("Enter current password", text: $currentPassword)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // New Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    SecureField("Enter new password", text: $newPassword)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Password requires
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password Requirements:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RequirementRow(text: "At least 8 characters", isValid: newPassword.count >= 8)
                        RequirementRow(text: "One uppercase letter", isValid: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                        RequirementRow(text: "One lowercase letter", isValid: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                        RequirementRow(text: "One number", isValid: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Update pwd
                Button(action: updatePassword) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isLoading ? "Updating..." : "Update Password")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "5A3529"))
                    .cornerRadius(8)
                    .opacity(isValidForm ? 1.0 : 0.6)
                }
                .disabled(!isValidForm || isLoading)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            },
            trailing: Button("Save") {
                updatePassword()
            }
            .foregroundColor(Color(hex: "5A3529"))
            .fontWeight(.semibold)
            .disabled(!isValidForm || isLoading)
        )
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "Success" {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isValidForm: Bool {
        return !currentPassword.isEmpty &&
               !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword == confirmPassword &&
               newPassword.count >= 8 &&
               newPassword.range(of: "[A-Z]", options: .regularExpression) != nil &&
               newPassword.range(of: "[a-z]", options: .regularExpression) != nil &&
               newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }
    
    private func updatePassword() {
        guard isValidForm else { return }
        
        guard let user = authManager.currentUser,
              let email = user.email else {
            showAlert(title: "Error", message: "User not found")
            return
        }
        
        isLoading = true
        
        // Re-authenticate user first
        authManager.reauthenticateUser(email: email, password: currentPassword) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Update password
                    self.authManager.updateUserPassword(newPassword: self.newPassword) { updateResult in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            
                            switch updateResult {
                            case .success:
                                self.showAlert(title: "Success", message: "Password updated successfully!")
                            case .failure(let error):
                                self.showAlert(title: "Error", message: "Failed to update password: \(error.localizedDescription)")
                            }
                        }
                    }
                case .failure(let error):
                    self.isLoading = false
                    self.showAlert(title: "Error", message: "Current password is incorrect: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct RequirementRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(isValid ? .green : .gray)
            
            Text("• \(text)")
                .font(.system(size: 12))
                .foregroundColor(isValid ? .green : .gray)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        ChangePasswordView()
    }
}

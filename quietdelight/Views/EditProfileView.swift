//
//  EditProfileView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-27.
//

import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    VStack(spacing: 16) {
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(hex: "5A3529"), lineWidth: 3))
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(Color(hex: "5A3529").opacity(0.5))
                            }
                            
                            // Edit button overlay
                            Button(action: { showImagePicker = true }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color(hex: "5A3529"))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                            .offset(x: 40, y: 40)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            
                            TextField("Enter username", text: $username)
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
                        
                        // Email Field (Read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .disabled(true)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Security & Privacy Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Security & Privacy")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Face ID Row
                            SettingsRow(
                                icon: "faceid",
                                title: "Face ID",
                                subtitle: "Use Face ID to unlock the app",
                                showToggle: true
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            // Location Services Row
                            SettingsRow(
                                icon: "location",
                                title: "Location Services",
                                subtitle: "Find cafes near your location",
                                showToggle: true
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            // Change Password Row
                            NavigationLink(destination: ChangePasswordView()) {
                                SettingsRow(
                                    icon: "lock",
                                    title: "Change Password",
                                    subtitle: "Update your account password",
                                    showArrow: true
                                )
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.black),
            
            trailing: Button("Save") {
                saveProfile()
            }
            .foregroundColor(Color(hex: "5A3529"))
            .fontWeight(.semibold)
            .disabled(isLoading)
        )
        .onAppear {
            loadUserProfile()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $profileImage)
        }
        .alert("Profile Update", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadUserProfile() {
        if let user = authManager.currentUser {
            username = user.displayName ?? ""
            email = user.email ?? ""
            
            if let url = user.photoURL {
                fetchProfileImage(from: url)
            }
        }
    }
    
    private func fetchProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
    
    private func saveProfile() {
        isLoading = true
        
        if let image = profileImage {
            // Update with image
            authManager.updateProfileWithImage(image, displayName: username) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        self.alertMessage = "Profile updated successfully!"
                        self.showAlert = true
                        
                        // Dismiss after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        
                    case .failure(let error):
                        self.alertMessage = "Failed to update profile: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        } else {
            // Update display name only
            authManager.updateUserProfile(displayName: username, photoURL: nil) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        self.alertMessage = "Profile updated successfully!"
                        self.showAlert = true
                        
                        // Dismiss after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        
                    case .failure(let error):
                        self.alertMessage = "Failed to update profile: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
    }
}

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var showToggle: Bool = false
    var showArrow: Bool = false
    @State private var isToggleOn = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "5A3529"))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if showToggle {
                Toggle("", isOn: $isToggleOn)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5A3529")))
            } else if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    EditProfileView()
}

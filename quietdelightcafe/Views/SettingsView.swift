//
//  SettingsView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var profileImage: UIImage? = nil
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var isLoading: Bool = true
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color(hex: "FFFFFF").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Color(hex: "5A3529"))
                            }
                        }
                        .padding(.top, 20)

                        VStack(spacing: 4) {
                            Text(username)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            Text(email)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)

                    // Generals Section
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Generals")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                                                        
                            NavigationLink(destination: EditProfileView()) {
                                SettingsMenuRow(
                                    icon: "person.circle",
                                    title: "Edit Profile",
                                    subtitle: "Edit your profile and password"
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // Favourites Row
                            NavigationLink(destination: FavoriteView()) {
                                SettingsMenuRow(
                                    icon: "heart",
                                    title: "Favourites",
                                    subtitle: "Save your favorite cafes"
                                )
                            }
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // Reviews Row
                            SettingsMenuRow(
                                icon: "star.square",
                                title: "Reviews",
                                subtitle: "Share your cafe experiences"
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 30)
                    
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Preferences")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            // Notifications Row
                            SettingsToggleRow(
                                icon: "bell",
                                title: "Notifications",
                                subtitle: "Get notified about nearby cafes"
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // Privacy & Policy Row
                            SettingsMenuRow(
                                icon: "shield",
                                title: "Privacy & Policy",
                                subtitle: ""
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // License Row
                            SettingsMenuRow(
                                icon: "doc.text",
                                title: "License",
                                subtitle: ""
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // Term of service Row
                            SettingsMenuRow(
                                icon: "doc.plaintext",
                                title: "Term of service",
                                subtitle: ""
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // Log Out Row
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                SettingsMenuRow(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    title: "Log Out",
                                    subtitle: "",
                                    isDestructive: true
                                )
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .onAppear {
            // Configure navigation bar appearance
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor(Color(hex: "F5F5F5"))
            navBarAppearance.titleTextAttributes = [
                .foregroundColor: UIColor.black,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
            navBarAppearance.shadowColor = UIColor.clear
            
            // Configure back button appearance
            navBarAppearance.backButtonAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "5A3529"))
            ]
            navBarAppearance.setBackIndicatorImage(
                UIImage(systemName: "chevron.left")?.withTintColor(UIColor(Color(hex: "5A3529")), renderingMode: .alwaysOriginal),
                transitionMaskImage: UIImage(systemName: "chevron.left")?.withTintColor(UIColor(Color(hex: "5A3529")), renderingMode: .alwaysOriginal)
            )
            
            UINavigationBar.appearance().standardAppearance = navBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
            UINavigationBar.appearance().compactAppearance = navBarAppearance
            
            // Ensure tint color for navigation items
            UINavigationBar.appearance().tintColor = UIColor(Color(hex: "5A3529"))
            
            loadUserProfile()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            loadUserProfile()
        }
    }

    private func loadUserProfile() {
        isLoading = true
        if let user = authManager.currentUser {
            username = user.displayName ?? "User"
            email = user.email ?? ""
            
            // Try to load from Firestore first (for updated data)
            authManager.getUserData { userData in
                DispatchQueue.main.async {
                    if let firestoreUsername = userData?["username"] as? String {
                        self.username = firestoreUsername
                    }
                    if let profilePictureURL = userData?["profilePicture"] as? String,
                       let url = URL(string: profilePictureURL) {
                        self.fetchProfileImage(from: url)
                    } else if let url = user.photoURL {
                        // Fallback to Firebase Auth photoURL
                        self.fetchProfileImage(from: url)
                    } else {
                        self.profileImage = nil
                        self.isLoading = false
                    }
                }
            }
        } else {
            username = "Guest"
            email = ""
            profileImage = nil
            isLoading = false
        }
    }

    private func fetchProfileImage(from url: URL) {
        // Download image from URL
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func performLogout() {
        authManager.signOut { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Reset user defaults
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    UserDefaults.standard.synchronize()
                    
            
                    break
                case .failure(let error):
                    // logout
                    print("Logout error: \(error)")
                }
            }
        }
    }
}

// Settings Menu Row Component
struct SettingsMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isDestructive ? .red : Color(hex: "5A3529"))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .black)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// Settings Toggle Row Component
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @State private var isToggleOn = true
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "5A3529"))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isToggleOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5A3529")))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}


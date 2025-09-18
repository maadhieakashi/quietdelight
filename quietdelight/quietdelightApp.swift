//
//  quietdelightcafeApp.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-18.
//

import SwiftUI
import Firebase

@main
struct quietdelightApp: App {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
                Group {
                    if authManager.isLoading {
                        SplashView()
                    } else if authManager.isAuthenticated {
                        
                        let isNewUser = UserDefaults.standard.bool(forKey: "isNewUser")
                        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                        
                        if isNewUser && !hasCompletedOnboarding {
                            
                            OnboardingView()
                        } else if hasCompletedOnboarding {
                          
                            TabBarView()
                        } else {
                          
                            TabBarView()
                        }
                    } else {
                        SigninView()
                    }
                }
                .preferredColorScheme(.light)
                .onAppear {
                    print("App appeared - Auth loading: \(authManager.isLoading), Authenticated: \(authManager.isAuthenticated)")
                    
                    // Set up notifications when app launches
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        // Request notification permission at app launch
        notificationManager.requestNotificationPermission()
        
        // Check current permission status
        notificationManager.checkNotificationPermission()
        
        // Clear any existing badge
        notificationManager.clearBadge()
    }
}

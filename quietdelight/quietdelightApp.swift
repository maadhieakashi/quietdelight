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
                }
        }
    }
}

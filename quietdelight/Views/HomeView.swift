//
//  HomeView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//

import SwiftUI

struct HomeView: View {
    @State private var forgotPassword = false
    
    var body: some View {
        VStack {
            Text("Hello, World!")
            Button("Forgot Password?") {
                forgotPassword = true
            }
        }
        .navigationDestination(isPresented: $forgotPassword) {
            ForgotPasswordView()
        }
    }
}

struct TabBarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                HomeContentView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)
                
                MapView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                        Text("Map")
                    }
                    .tag(1)
                
                FavoriteView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "heart.fill" : "heart")
                        Text("Favorite")
                    }
                    .tag(2)
                
               SettingsView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                        Text("Setting")
                    }
                    .tag(3)
            }
            .accentColor(Color(hex: "5A3529"))
            .onAppear {
                // Configure TabBar appearance
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                tabBarAppearance.backgroundColor = UIColor.white
                
                // Configure selected item appearance (highlighted in theme color)
                tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "5A3529"))
                tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor(Color(hex: "5A3529"))
                ]
                
                // Configure unselected item appearance (gray)
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.gray
                ]
                
                // Apply the appearance
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}

// Separate content view for the Home tab to avoid circular reference
struct HomeContentView: View {
    @State private var forgotPassword = false
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Welcome to Cafe Delight")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "5A3529"))
                
                Text("Find your perfect workspace cafe")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Button("Forgot Password?") {
                    forgotPassword = true
                }
                .foregroundColor(Color(hex: "5A3529"))
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $forgotPassword) {
            ForgotPasswordView()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}

#Preview("TabBar") {
    TabBarView()
}

#Preview("Home Content") {
    HomeContentView()
}

#Preview("Home View") {
    HomeView()
}


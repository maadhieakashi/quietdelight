//
//  HomeView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//


import SwiftUI
import FirebaseAuth

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
    
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "5A3529"))
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "5A3529"))
            ]
            
         
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.gray
            ]
            
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

struct HomeContentView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var searchText = ""
    @State private var selectedPlace: PlaceData?
    @State private var showPlaceDetail = false
    @State private var favoriteCount = 0
    @State private var reviewCount = 0
    @State private var workFriendlyPlaces: [PlaceData] = []
    @State private var selectedFilter: String? = nil
    
    // Sample user data - replace with actual user data from Firebase
    @State private var userName = "Suzume Iwato"
    @State private var userImageURL = "" // Add actual user image URL
    
    let quickFilters = ["Quiet", "Fast WIFI", "Power Outlet"]
    
    var filteredPlaces: [PlaceData] {
        var places = workFriendlyPlaces
        
        // Apply search filter
        if !searchText.isEmpty {
            places = places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply quick filter
        if let filter = selectedFilter {
            switch filter {
            case "Quiet":
                places = places.filter { $0.isQuietZone }
            case "Fast WIFI":
                places = places.filter { $0.hasWiFi }
            case "Power Outlet":
                places = places.filter { $0.hasPowerOutlets }
            default:
                break
            }
        }
        
        return Array(places.prefix(4)) // Show only 4 places
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with user greeting and stats
                    VStack(alignment: .leading, spacing: 15) {
                        // User Greeting
                        HStack {
                            Text("Hi, \(userName)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // User Profile Image
                            AsyncImage(url: URL(string: userImageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        }
                        
                        // Stats Cards
                        HStack(spacing: 15) {
                            StatCard(number: favoriteCount, label: "Favorites", color: Color(hex: "5A3529"))
                            StatCard(number: reviewCount, label: "Reviews", color: Color(hex: "5A3529"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Search Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search cafe..", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(25)
                        
                        Button(action: {
                            // Filter action
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color(hex: "5A3529"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Quick Filter Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(quickFilters, id: \.self) { filter in
                                FilterTag(
                                    text: filter,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        if selectedFilter == filter {
                                            selectedFilter = nil
                                        } else {
                                            selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Work Friendly Cafes Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Work Friendly Cafes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("See All") {
                                // Navigate to places list
                            }
                            .foregroundColor(Color(hex: "5A3529"))
                            .font(.subheadline)
                        }
                        .padding(.horizontal, 20)
                        
                        // Places Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 15) {
                            ForEach(filteredPlaces, id: \.id) { place in
                                HomePlaceCard(place: place) {
                                    selectedPlace = place
                                    showPlaceDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            loadUserData()
            loadWorkFriendlyPlaces()
        }
        .sheet(isPresented: $showPlaceDetail) {
            if let place = selectedPlace {
                PlaceDetailView(place: place)
            }
        }
    }
    
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Load user name
        if let displayName = Auth.auth().currentUser?.displayName {
            userName = displayName
        }
        
        // Load user profile image
        if let photoURL = Auth.auth().currentUser?.photoURL {
            userImageURL = photoURL.absoluteString
        }
        
        // Load favorites count
        let favorites = coreDataManager.fetchFavorites(for: userId)
        favoriteCount = favorites.count
        
        // Load reviews count from Firebase
        firebaseManager.fetchUserReviewCount(for: userId) { count in
            DispatchQueue.main.async {
                self.reviewCount = count
            }
        }
    }
    
    private func loadWorkFriendlyPlaces() {
        firebaseManager.fetchColombo7Places { places in
            DispatchQueue.main.async {
                self.workFriendlyPlaces = places
            }
        }
    }
}

struct StatCard: View {
    let number: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(number)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .cornerRadius(15)
    }
}

struct FilterTag: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "5A3529") : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

struct HomePlaceCard: View {
    let place: PlaceData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Place Image
                AsyncImage(url: URL(string: place.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Toggle favorite
                            }) {
                                Image(systemName: "heart")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                        Spacer()
                    }
                )
                
                // Place Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(place.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", place.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(hex: "5A3529"))
                            .font(.system(size: 16))
                    }
                }
                .padding(12)
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extension to add fetchUserReviewCount to FirebaseManager
extension FirebaseManager {
    func fetchUserReviewCount(for userId: String, completion: @escaping (Int) -> Void) {
    // Expose db as public in FirebaseManager or add a public accessor if needed
    // For now, assuming db is public
    FirebaseManager.shared.db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user review count: \(error)")
                    completion(0)
                    return
                }
                let count = snapshot?.documents.count ?? 0
                completion(count)
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

//
//  HomeView.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-20.
//
//

import SwiftUI
import FirebaseAuth



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
            // TabBar
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
    private let authManager = FirebaseAuthManager.shared
    @State private var searchText = ""
    @State private var selectedPlace: PlaceData?
    @State private var showPlaceDetail = false
    @State private var favoriteCount = 0
    @State private var reviewCount = 0
    @State private var workFriendlyPlaces: [PlaceData] = []
    @State private var selectedFilter: String? = nil
    @State private var refreshTrigger = false
    @State private var showFilters = false
    
    //user data in firebse
    @State private var userName = ""
    @State private var userImageURL = ""
    @State private var userEmail = ""
    
    let quickFilters = ["Quiet", "Fast WIFI", "Power Outlet"]
    
    var filteredPlaces: [PlaceData] {
        var places = workFriendlyPlaces
        
        // search filter
        if !searchText.isEmpty {
            places = places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // quick filter
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
        
        return Array(places.prefix(10))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                  
                    VStack(alignment: .leading, spacing: 20) {
                        // User Greeting
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hi, \(userName)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                if !userEmail.isEmpty {
                                    Text(userEmail)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Find your perfect workspace")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // User Propic
                            if let url = URL(string: userImageURL), !userImageURL.isEmpty {
                                AsyncImage(url: url) { image in
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
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.brown.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.black)
                                    )
                                    .frame(width: 55, height: 55)
                            }
                        }
                        
                        // Stats Cards
                        HStack(spacing: 12) {
                            StatCard(number: favoriteCount, label: "Favorites", color: Color(hex: "5A3529"))
                            StatCard(number: reviewCount, label: "Reviews", color: Color(hex: "5A3529"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Search Bar
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            
                            TextField("Search cafe..", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(25)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showFilters.toggle()
                            }
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(14)
                                .background(
                                    Color(hex: showFilters || selectedFilter != nil ? "7A4A3A" : "5A3529")
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Quick Filter Tags
                    if showFilters {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Filters")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Clear All Filters
                                    FilterTag(
                                        text: "Clear All",
                                        isSelected: selectedFilter == nil
                                    ) {
                                        selectedFilter = nil
                                    }
                                    
                                    // Quick Filter Options
                                    ForEach(quickFilters, id: \.self) { filter in
                                        FilterTag(
                                            text: filter,
                                            isSelected: selectedFilter == filter
                                        ) {
                                            if selectedFilter == filter {
                                                selectedFilter = nil
                                            } else {
                                                selectedFilter = filter
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 10)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }
                    
                    // Work Friendly Cafes Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .center) {
                            Text("Work Friendly Cafes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("See All") {
                                // See all action
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "5A3529"))
                        }
                        .padding(.horizontal, 20)
                        
                        // Places Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 20) {
                            ForEach(filteredPlaces, id: \.id) { place in
                                HomePlaceCard(place: place, onFavoriteChange: {
                                    updateFavoriteCount()
                                }) {
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateFavoriteCount()
        }
        .sheet(isPresented: $showPlaceDetail) {
            if let place = selectedPlace {
                PlaceDetailView(place: place)
            }
        }
    }
    
    private func updateFavoriteCount() {
        guard let user = Auth.auth().currentUser else { return }
        let favorites = coreDataManager.fetchFavorites(for: user.uid)
        favoriteCount = favorites.count
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            userName = "Guest"
            userImageURL = ""
            userEmail = ""
            return
        }

        //userdata firestore
        authManager.getUserData { userData in
            DispatchQueue.main.async {
                if let firestoreUsername = userData?["username"] as? String, !firestoreUsername.isEmpty {
                    self.userName = firestoreUsername
                } else if let displayName = user.displayName, !displayName.isEmpty {
                    self.userName = displayName
                } else {
                    self.userName = "Guest"
                }

                if let profilePictureURL = userData?["profilePicture"] as? String, !profilePictureURL.isEmpty {
                    self.userImageURL = profilePictureURL
                } else if let photoURL = user.photoURL {
                    self.userImageURL = photoURL.absoluteString
                } else {
                    self.userImageURL = ""
                }

                // email
                if let firestoreEmail = userData?["email"] as? String, !firestoreEmail.isEmpty {
                    self.userEmail = firestoreEmail
                } else if let email = user.email {
                    self.userEmail = email
                } else {
                    self.userEmail = ""
                }
            }
        }

        // favorites count
        let favorites = coreDataManager.fetchFavorites(for: user.uid)
        favoriteCount = favorites.count

        // reviews count
        firebaseManager.fetchUserReviewCount(for: user.uid) { count in
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
        VStack(spacing: 10) {
            Text("\(number)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
        )
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
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
    let onFavoriteChange: () -> Void
    let onTap: () -> Void
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var isFavorite = false
    
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
                                .font(.system(size: 24))
                        )
                }
                .frame(height: 100)
                .clipped()
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                toggleFavorite()
                            }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .font(.system(size: 18, weight: .semibold))
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.7))
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .scaleEffect(isFavorite ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                        Spacer()
                    }
                )
                
                // Place Info
                VStack(alignment: .leading, spacing: 8) {
                    // Place name with better spacing
                    Text(place.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    // Address with consistent styling
                    Text(place.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Rating and work-friendly indicator
                    HStack(alignment: .center, spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 11))
                            Text(String(format: "%.1f", place.rating))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Work features
                        HStack(spacing: 4) {
                            if place.hasWiFi {
                                Image(systemName: "wifi")
                                    .foregroundColor(Color(hex: "5A3529"))
                                    .font(.system(size: 10))
                            }
                            
                            if place.hasPowerOutlets {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(Color(hex: "5A3529"))
                                    .font(.system(size: 10))
                            }
                            
                            if place.isQuietZone {
                                Image(systemName: "speaker.slash.fill")
                                    .foregroundColor(Color(hex: "5A3529"))
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            checkFavoriteStatus()
        }
    }
    
    private func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if isFavorite {
            coreDataManager.removeFavorite(placeId: place.id, userId: userId)
        } else {
            coreDataManager.addFavorite(placeId: place.id, userId: userId)
        }
        isFavorite.toggle()
        onFavoriteChange() // favorite count
    }
    
    private func checkFavoriteStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isFavorite = coreDataManager.isFavorite(placeId: place.id, userId: userId)
    }
}

// UserReviewCount
extension FirebaseManager {
    func fetchUserReviewCount(for userId: String, completion: @escaping (Int) -> Void) {
  
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



//
//  FavoriteView.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI
import FirebaseAuth

struct FavoriteView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var favoriteePlaces: [(place: PlaceData, favoritedAt: Date)] = []
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedPlace: PlaceData?
    @State private var showPlaceDetail = false
    
    let filterOptions = ["All", "Nearby", "recent"]
    
    var filteredPlaces: [(place: PlaceData, favoritedAt: Date)] {
        var places = favoriteePlaces
        
        if !searchText.isEmpty {
            places = places.filter { item in
                item.place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case "Nearby":
            // Sort by distance (implement location-based sorting)
            return places
        case "recent":
            // Sort by recently added to favorites
            return places.sorted { $0.favoritedAt > $1.favoritedAt }
        default:
            return places
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search cafes...", text: $searchText)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    
                    Button(action: {
                        // TODO: Implement filter functionality
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.brown)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Filter Options
                HStack {
                    ForEach(filterOptions, id: \.self) { option in
                        Button(action: {
                            selectedFilter = option
                        }) {
                            Text(option)
                                .font(.subheadline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(selectedFilter == option ? Color.black : Color.clear)
                                .foregroundColor(selectedFilter == option ? .white : .black)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.black, lineWidth: selectedFilter == option ? 0 : 1)
                                )
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                // Favorites List
                if filteredPlaces.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Favorite Places Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Start exploring cafes and add them to your favorites!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredPlaces, id: \.place.id) { item in
                                FavoritePlaceCard(place: item.place, favoritedAt: item.favoritedAt) {
                                    selectedPlace = item.place
                                    showPlaceDetail = true
                                } onRemoveFavorite: {
                                    removeFavorite(place: item.place)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFavorites()
            }
            .sheet(isPresented: $showPlaceDetail) {
                if let place = selectedPlace {
                    PlaceDetailView(place: place)
                }
            }
        }
    }
    
    private func loadFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Sync with Firebase first
        firebaseManager.syncFavorites(for: userId)
        
        // Get favorites from Core Data
        let favoritePlaces = coreDataManager.fetchFavorites(for: userId)
        
        // Fetch place details for each favorite
        var places: [(place: PlaceData, favoritedAt: Date)] = []
        for favorite in favoritePlaces {
            guard let placeId = favorite.placeId else { continue }
            let favoritedAt = favorite.createdAt ?? Date()
            
          
            let coreDataPlaces = coreDataManager.fetchPlaces()
            if let existingPlace = coreDataPlaces.first(where: { $0.id == placeId }) {
                // Fetch real-time rating from reviews
                fetchRealTimeRating(for: placeId) { realRating in
                    let place = PlaceData(
                        id: existingPlace.id ?? "",
                        name: existingPlace.name ?? "",
                        address: existingPlace.address ?? "",
                        latitude: existingPlace.latitude,
                        longitude: existingPlace.longitude,
                        rating: realRating,
                        imageURL: existingPlace.imageURL ?? "",
                        description: existingPlace.placeDescription ?? "",
                        isWorkFriendly: existingPlace.isWorkFriendly,
                        hasWiFi: existingPlace.hasWiFi,
                        hasPowerOutlets: existingPlace.hasPowerOutlets,
                        isQuietZone: existingPlace.isQuietZone
                    )
                    
                    DispatchQueue.main.async {
                        if let index = self.favoriteePlaces.firstIndex(where: { $0.place.id == placeId }) {
                            self.favoriteePlaces[index] = (place: place, favoritedAt: favoritedAt)
                        } else {
                            self.favoriteePlaces.append((place: place, favoritedAt: favoritedAt))
                        }
                    }
                }
            } else {
               
                firebaseManager.db.collection("places").document(placeId).getDocument { document, error in
                    if let document = document, document.exists, let data = document.data() {
                        let venueTypeString = data["venueType"] as? String
                        let venueType = VenueType(rawValue: venueTypeString ?? "") ?? .cafe
                        
                        // Fetch real-time rating from reviews
                        self.fetchRealTimeRating(for: placeId) { realRating in
                            let place = PlaceData(
                                id: document.documentID,
                                name: data["name"] as? String ?? "",
                                address: data["address"] as? String ?? "",
                                latitude: data["latitude"] as? Double ?? 0.0,
                                longitude: data["longitude"] as? Double ?? 0.0,
                                rating: realRating,
                                imageURL: data["imageURL"] as? String ?? "",
                                description: data["description"] as? String ?? "",
                                isWorkFriendly: data["isWorkFriendly"] as? Bool ?? false,
                                hasWiFi: data["hasWiFi"] as? Bool ?? false,
                                hasPowerOutlets: data["hasPowerOutlets"] as? Bool ?? false,
                                isQuietZone: data["isQuietZone"] as? Bool ?? false,
                                venueType: venueType
                            )
                            
                            DispatchQueue.main.async {
                                if !self.favoriteePlaces.contains(where: { $0.place.id == place.id }) {
                                    self.favoriteePlaces.append((place: place, favoritedAt: favoritedAt))
                                }
                            }
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.favoriteePlaces = places
        }
    }
    
    private func fetchRealTimeRating(for placeId: String, completion: @escaping (Double) -> Void) {
        firebaseManager.fetchReviews(for: placeId) { reviews in
            guard !reviews.isEmpty else {
                completion(0.0)
                return
            }
            
            // Calculate average rating from reviews using the same logic as updatePlaceRating
            let averageQuietness = reviews.reduce(0.0) { $0 + $1.quietnessRating } / Double(reviews.count)
            let averageWiFi = reviews.reduce(0.0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
            let averageFood = reviews.reduce(0.0) { $0 + $1.foodTasteRating } / Double(reviews.count)
            
            // Calculate overall rating as average of the three categories
            let overallRating = (averageQuietness + averageWiFi + averageFood) / 3.0
            completion(overallRating)
        }
    }
    
    private func removeFavorite(place: PlaceData) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        coreDataManager.removeFavorite(placeId: place.id, userId: userId)
        
        favoriteePlaces.removeAll { $0.place.id == place.id }
    }
}

struct FavoritePlaceCard: View {
    let place: PlaceData
    let favoritedAt: Date
    let onTap: () -> Void
    let onRemoveFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack {
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
                    .frame(width: 80, height: 80)
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(place.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: onRemoveFavorite) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        Text(place.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        // Feature tags
                        HStack(spacing: 5) {
                            if place.hasWiFi {
                                FeatureTag(text: "Fast WiFi")
                            }
                            if place.isQuietZone {
                                FeatureTag(text: "Quiet Zone")
                            }
                            if place.hasPowerOutlets {
                                FeatureTag(text: "Power Outlet")
                            }
                        }
                        
                        HStack {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: Double(index) < place.rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            
                            Text(String(format: "%.1f", place.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("saved \(timeAgoString(from: favoritedAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(15)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FavoriteView()
}

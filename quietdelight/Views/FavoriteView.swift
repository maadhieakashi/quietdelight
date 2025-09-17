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
            // Sort by distance
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
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        firebaseManager.syncFavorites(for: userId)
        
        // Get favorites from Core Data
        let favoritePlaces = coreDataManager.fetchFavorites(for: userId)
        
     
        DispatchQueue.main.async {
            self.favoriteePlaces.removeAll()
        }
        
        var places: [(place: PlaceData, favoritedAt: Date)] = []
        for favorite in favoritePlaces {
            guard let placeId = favorite.placeId else {
                continue
            }
            let favoritedAt = favorite.createdAt ?? Date()
            
            // First check Core Data
            let coreDataPlaces = coreDataManager.fetchPlaces()
            if let existingPlace = coreDataPlaces.first(where: { $0.id == placeId }) {
                let imageURL = existingPlace.imageURL ?? ""
                
                if imageURL.isEmpty {
                    firebaseManager.db.collection("places").document(placeId).getDocument { document, error in
                        if let document = document, document.exists, let data = document.data() {
                            let firebaseImageURL = data["imageURL"] as? String ?? ""
                            
                            self.fetchRealTimeRating(for: placeId) { realRating in
                                let place = PlaceData(
                                    id: existingPlace.id ?? "",
                                    name: existingPlace.name ?? "",
                                    address: existingPlace.address ?? "",
                                    latitude: existingPlace.latitude,
                                    longitude: existingPlace.longitude,
                                    rating: realRating,
                                    imageURL: firebaseImageURL.isEmpty ? imageURL : firebaseImageURL,
                                    description: existingPlace.placeDescription ?? "",
                                    isWorkFriendly: existingPlace.isWorkFriendly,
                                    hasWiFi: existingPlace.hasWiFi,
                                    hasPowerOutlets: existingPlace.hasPowerOutlets,
                                    isQuietZone: existingPlace.isQuietZone,
                                    venueType: PlaceData.determineVenueType(from: existingPlace.name ?? "")
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
                           
                            self.fetchRealTimeRating(for: placeId) { realRating in
                                let place = PlaceData(
                                    id: existingPlace.id ?? "",
                                    name: existingPlace.name ?? "",
                                    address: existingPlace.address ?? "",
                                    latitude: existingPlace.latitude,
                                    longitude: existingPlace.longitude,
                                    rating: realRating,
                                    imageURL: imageURL,
                                    description: existingPlace.placeDescription ?? "",
                                    isWorkFriendly: existingPlace.isWorkFriendly,
                                    hasWiFi: existingPlace.hasWiFi,
                                    hasPowerOutlets: existingPlace.hasPowerOutlets,
                                    isQuietZone: existingPlace.isQuietZone,
                                    venueType: PlaceData.determineVenueType(from: existingPlace.name ?? "")
                                )
                                
                                DispatchQueue.main.async {
                                    if let index = self.favoriteePlaces.firstIndex(where: { $0.place.id == placeId }) {
                                        self.favoriteePlaces[index] = (place: place, favoritedAt: favoritedAt)
                                    } else {
                                        self.favoriteePlaces.append((place: place, favoritedAt: favoritedAt))
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Core Data has image URL, use it directly
                    fetchRealTimeRating(for: placeId) { realRating in
                        let place = PlaceData(
                            id: existingPlace.id ?? "",
                            name: existingPlace.name ?? "",
                            address: existingPlace.address ?? "",
                            latitude: existingPlace.latitude,
                            longitude: existingPlace.longitude,
                            rating: realRating,
                            imageURL: imageURL,
                            description: existingPlace.placeDescription ?? "",
                            isWorkFriendly: existingPlace.isWorkFriendly,
                            hasWiFi: existingPlace.hasWiFi,
                            hasPowerOutlets: existingPlace.hasPowerOutlets,
                            isQuietZone: existingPlace.isQuietZone,
                            venueType: PlaceData.determineVenueType(from: existingPlace.name ?? "")
                        )
                        
                        DispatchQueue.main.async {
                            if let index = self.favoriteePlaces.firstIndex(where: { $0.place.id == placeId }) {
                                self.favoriteePlaces[index] = (place: place, favoritedAt: favoritedAt)
                            } else {
                                self.favoriteePlaces.append((place: place, favoritedAt: favoritedAt))
                            }
                        }
                    }
                }
            } else {
                firebaseManager.db.collection("places").document(placeId).getDocument { document, error in
                    if let error = error {
                        return
                    }
                    
                    if let document = document, document.exists, let data = document.data() {
                        let venueTypeString = data["venueType"] as? String
                        let venueType = VenueType(rawValue: venueTypeString ?? "") ?? .cafe
                        let imageURL = data["imageURL"] as? String ?? ""
                        let placeName = data["name"] as? String ?? "Unknown"
                        
                        // rating from reviews
                        self.fetchRealTimeRating(for: placeId) { realRating in
                            let place = PlaceData(
                                id: document.documentID,
                                name: placeName,
                                address: data["address"] as? String ?? "",
                                latitude: data["latitude"] as? Double ?? 0.0,
                                longitude: data["longitude"] as? Double ?? 0.0,
                                rating: realRating,
                                imageURL: imageURL,
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
            
            // Calculate average rating
            let averageQuietness = reviews.reduce(0.0) { $0 + $1.quietnessRating } / Double(reviews.count)
            let averageWiFi = reviews.reduce(0.0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
            let averageFood = reviews.reduce(0.0) { $0 + $1.foodTasteRating } / Double(reviews.count)
            
            // Calculate overall rating
            let overallRating = (averageQuietness + averageWiFi + averageFood) / 3.0
            completion(overallRating)
        }
    }
    
    private func removeFavorite(place: PlaceData) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        coreDataManager.removeFavorite(placeId: place.id, userId: userId)
        
        favoriteePlaces.removeAll { $0.place.id == place.id }
    }
    
    private func isValidImageURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty else { return false }
        guard let url = URL(string: urlString) else { return false }
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return false }
        guard let host = url.host, !host.isEmpty else { return false }
        
        let validHosts = [
            "firebasestorage.googleapis.com",
            "storage.googleapis.com",
            "firebase.google.com",
            "images.unsplash.com",
            "via.placeholder.com",
            "picsum.photos"
        ]
        
        let hasValidHost = validHosts.contains { host.contains($0) }
        let hasImageExtension = urlString.lowercased().range(of: "\\.(jpg|jpeg|png|gif|webp|bmp)", options: .regularExpression) != nil ||
                               urlString.contains("alt=media")
        return hasValidHost || hasImageExtension
    }
}

struct FavoritePlaceCard: View {
    let place: PlaceData
    let favoritedAt: Date
    let onTap: () -> Void
    let onRemoveFavorite: () -> Void
    
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var reviewRatings: (quietness: Double, wifi: Double, food: Double) = (0.0, 0.0, 0.0)
    @State private var reviewCount = 0
    @State private var powerOutletStatus = "Available"
    @State private var workFeatures: [String] = []
    
    private func isValidImageURL(_ urlString: String) -> Bool {
        guard !urlString.isEmpty else { return false }
        guard let url = URL(string: urlString) else { return false }
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return false }
        guard let host = url.host, !host.isEmpty else { return false }
        
        let validHosts = [
            "firebasestorage.googleapis.com",
            "storage.googleapis.com",
            "firebase.google.com",
            "images.unsplash.com",
            "via.placeholder.com",
            "picsum.photos"
        ]
        
        let hasValidHost = validHosts.contains { host.contains($0) }
        let hasImageExtension = urlString.lowercased().range(of: "\\.(jpg|jpeg|png|gif|webp|bmp)", options: .regularExpression) != nil ||
                               urlString.contains("alt=media")
        
        return hasValidHost || hasImageExtension
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 15) {
                    AsyncImage(url: URL(string: place.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                        case .failure(_):
                            Image("cafe")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .opacity(0.9)
                        case .empty:
                            if place.imageURL.isEmpty || !isValidImageURL(place.imageURL) {
                                Image("cafe")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .opacity(0.9)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        VStack(spacing: 4) {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                            Text("Loading...")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    )
                                    .frame(width: 80, height: 80)
                            }
                        @unknown default:
                            Image("cafe")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .opacity(0.9)
                        }
                    }
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(place.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: onRemoveFavorite) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18))
                            }
                        }
                        
                        Text(place.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Feature tags
                        HStack(spacing: 5) {
                            ForEach(workFeatures.prefix(3), id: \.self) { feature in
                                FeatureTag(text: feature)
                            }
                        }
                        
                        // Rating
                        HStack(spacing: 12) {
                            // Real review ratings
                            if reviewCount > 0 {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.1f", reviewRatings.wifi))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("WiFi")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.1f", reviewRatings.quietness))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("Quiet")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.1f", reviewRatings.food))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("Food")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                // Show basic features when no reviews
                                if place.hasWiFi {
                                    FeatureTag(text: "WiFi")
                                }
                                if place.isQuietZone {
                                    FeatureTag(text: "Quiet Zone")
                                }
                                if place.hasPowerOutlets {
                                    FeatureTag(text: "Power Outlet")
                                }
                            }
                            
                            Spacer()
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
                            
                            if reviewCount > 0 {
                                Text("(\(reviewCount) review\(reviewCount == 1 ? "" : "s"))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("saved \(timeAgoString(from: favoritedAt))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
         
                }
                .padding(15)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadRealReviewData()
        }
    }
    
    private func loadRealReviewData() {
        firebaseManager.fetchReviews(for: place.id) { reviews in
            DispatchQueue.main.async {
                self.reviewCount = reviews.count
                
                guard !reviews.isEmpty else {
                    // No reviews
                    self.reviewRatings = (0.0, 0.0, 0.0)
                    self.workFeatures = []
                    self.powerOutletStatus = "Available"
                    return
                }
                
                //  average ratings for each category
                let avgQuietness = reviews.reduce(0.0) { $0 + $1.quietnessRating } / Double(reviews.count)
                let avgWiFi = reviews.reduce(0.0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
                let avgFood = reviews.reduce(0.0) { $0 + $1.foodTasteRating } / Double(reviews.count)
                
                self.reviewRatings = (avgQuietness, avgWiFi, avgFood)
                
                // Determine work features based on review ratings
                var features: [String] = []
                
                if avgWiFi >= 4.0 {
                    features.append("Fast WiFi")
                } else if avgWiFi >= 3.0 {
                    features.append("WiFi Available")
                }
                
                if avgQuietness >= 4.0 {
                    features.append("Quiet Zone")
                } else if avgQuietness >= 3.0 {
                    features.append("Moderate Noise")
                }
                
                if avgFood >= 4.0 {
                    features.append("Great Food")
                } else if avgFood >= 3.0 {
                    features.append("Good Food")
                }
                
                // Calculate power outlet status based on reviews
                let abundantCount = reviews.filter { $0.powerOutletStatus == "Abundant" }.count
                let limitedCount = reviews.filter { $0.powerOutletStatus == "Limited" }.count
                let notAvailableCount = reviews.filter { $0.powerOutletStatus == "Not Available" }.count
                
                if abundantCount > limitedCount && abundantCount > notAvailableCount {
                    self.powerOutletStatus = "Abundant"
                    features.append("Power Outlets")
                } else if limitedCount > abundantCount && limitedCount > notAvailableCount {
                    self.powerOutletStatus = "Limited"
                    features.append("Limited Power")
                } else if notAvailableCount > abundantCount && notAvailableCount > limitedCount {
                    self.powerOutletStatus = "Not Available"
                } else {
                    self.powerOutletStatus = "Available"
                    if place.hasPowerOutlets {
                        features.append("Power Outlets")
                    }
                }
                
                self.workFeatures = features
            }
        }
    }
}

#Preview {
    FavoriteView()
}

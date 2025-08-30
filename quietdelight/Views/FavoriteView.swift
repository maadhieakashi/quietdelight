//
//  FavoriteView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI
import FirebaseAuth

struct FavoriteView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var favoriteePlaces: [PlaceData] = []
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedPlace: PlaceData?
    @State private var showPlaceDetail = false
    
    let filterOptions = ["All", "Nearby", "recent"]
    
    var filteredPlaces: [PlaceData] {
        var places = favoriteePlaces
        
        if !searchText.isEmpty {
            places = places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case "Nearby":
           
            return places
        case "recent":
         
            return places
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
                        // Filter action
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
                            ForEach(filteredPlaces, id: \.id) { place in
                                FavoritePlaceCard(place: place) {
                                    selectedPlace = place
                                    showPlaceDetail = true
                                } onRemoveFavorite: {
                                    removeFavorite(place: place)
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
        var places: [PlaceData] = []
        for favorite in favoritePlaces {
            // In a real app, you'd fetch full place data from Core Data or Firebase
            // For now, creating placeholder data
            let place = PlaceData(
                id: favorite.placeId ?? "",
                name: "Sample Cafe",
                address: "Colombo 7",
                latitude: 6.914244,
                longitude: 79.861244,
                rating: 4.1,
                imageURL: "",
                isWorkFriendly: true,
                hasWiFi: true,
                hasPowerOutlets: true,
                isQuietZone: true
            )
            places.append(place)
        }
        
        DispatchQueue.main.async {
            self.favoriteePlaces = places
        }
    }
    
    private func removeFavorite(place: PlaceData) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        coreDataManager.removeFavorite(placeId: place.id, userId: userId)
        
        // Remove from local array
        favoriteePlaces.removeAll { $0.id == place.id }
    }
}

struct FavoritePlaceCard: View {
    let place: PlaceData
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
                            
                            Text("save 2 days ago")
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

//
//  PlacesListView.swift
//  quietdelight
//
//  Created by SAHimeshi 002 on 2025-08-30.
//

import SwiftUI

struct PlacesListView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var places: [PlaceData] = []
    @State private var searchText = ""
    @State private var selectedPlace: PlaceData?
    @State private var showPlaceDetail = false
    @State private var isLoading = true
    
    var filteredPlaces: [PlaceData] {
        if searchText.isEmpty {
            return places
        } else {
            return places.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText) ||
                place.address.localizedCaseInsensitiveContains(searchText)
            }
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
                
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Work Friendly Cafes")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Colombo 7 Area • \(places.count) places found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading places...")
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredPlaces.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Places Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Try adjusting your search or filters")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Places List
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredPlaces, id: \.id) { place in
                                PlaceListCard(place: place) {
                                    selectedPlace = place
                                    showPlaceDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Places")
            .navigationBarHidden(true)
            .onAppear {
                loadPlaces()
            }
            .sheet(isPresented: $showPlaceDetail) {
                if let place = selectedPlace {
                    PlaceDetailView(place: place)
                }
            }
        }
    }
    
    private func loadPlaces() {
        isLoading = true
        firebaseManager.fetchColombo7Places { fetchedPlaces in
            DispatchQueue.main.async {
                self.places = fetchedPlaces
                self.isLoading = false
                
                // Save to Core Data for offline access
                fetchedPlaces.forEach { place in
                    CoreDataManager.shared.addPlace(place)
                }
            }
        }
    }
}

struct PlaceListCard: View {
    let place: PlaceData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image
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
                                .font(.system(size: 30))
                        )
                }
                .frame(height: 120)
                .clipped()
                
                // Content
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(place.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", place.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(place.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Feature tags
                    HStack(spacing: 5) {
                        if place.hasWiFi {
                            WorkFeatureTag(text: "Fast WiFi", color: .blue)
                        }
                        if place.isQuietZone {
                            WorkFeatureTag(text: "Quiet Zone", color: .purple)
                        }
                        if place.hasPowerOutlets {
                            WorkFeatureTag(text: "Power Outlet", color: .green)
                        }
                    }
                    
                    // Rating breakdown
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("4.7")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("WiFi")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("3.0")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Quiet")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("4.5")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Food")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if place.hasPowerOutlets {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Abundant")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                Text("Power")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(15)
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkFeatureTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
    }
}

#Preview {
    PlacesListView()
}

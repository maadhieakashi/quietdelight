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
    @State private var showQuickFilters = false
    
    // Filter states
    @State private var filterWiFi = false
    @State private var filterQuietZone = false
    @State private var filterPowerOutlets = false
    @State private var selectedRatingFilter: RatingFilter = .all
    
    enum RatingFilter: String, CaseIterable {
        case all = "All Ratings"
        case fourPlus = "4.0+ Stars"
        case threePlus = "3.0+ Stars"
    }
    
    enum SortOption: String, CaseIterable {
        case rating = "Rating"
        case name = "Name"
        case distance = "Distance"
    }
    
    var filteredPlaces: [PlaceData] {
        var filtered = places
        
        // Apply text search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText) ||
                place.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply feature filters
        if filterWiFi {
            filtered = filtered.filter { $0.hasWiFi }
        }
        
        if filterQuietZone {
            filtered = filtered.filter { $0.isQuietZone }
        }
        
        if filterPowerOutlets {
            filtered = filtered.filter { $0.hasPowerOutlets }
        }
        
        // Apply rating filter
        switch selectedRatingFilter {
        case .fourPlus:
            filtered = filtered.filter { $0.rating >= 4.0 }
        case .threePlus:
            filtered = filtered.filter { $0.rating >= 3.0 }
        case .all:
            break
        }
        
        // Sort by rating (default)
        filtered = filtered.sorted { $0.rating > $1.rating }
        
        return filtered
    }
    
    var hasActiveFilters: Bool {
        return filterWiFi || filterQuietZone || filterPowerOutlets ||
               selectedRatingFilter != .all
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if filterWiFi { count += 1 }
        if filterQuietZone { count += 1 }
        if filterPowerOutlets { count += 1 }
        if selectedRatingFilter != .all { count += 1 }
        return count
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showQuickFilters.toggle()
                        }
                    }) {
                        ZStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.brown)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            // Show indicator if any filters are active
                            if hasActiveFilters {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Quick Filter Tags (only show when toggled)
                if showQuickFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            QuickFilterTag(
                                title: "WiFi",
                                icon: "wifi",
                                isSelected: filterWiFi
                            ) {
                                filterWiFi.toggle()
                            }
                            
                            QuickFilterTag(
                                title: "Quiet",
                                icon: "speaker.slash",
                                isSelected: filterQuietZone
                            ) {
                                filterQuietZone.toggle()
                            }
                            
                            QuickFilterTag(
                                title: "Power",
                                icon: "bolt",
                                isSelected: filterPowerOutlets
                            ) {
                                filterPowerOutlets.toggle()
                            }
                            
                            QuickFilterTag(
                                title: "4+ Stars",
                                icon: "star.fill",
                                isSelected: selectedRatingFilter == .fourPlus
                            ) {
                                selectedRatingFilter = selectedRatingFilter == .fourPlus ? .all : .fourPlus
                            }
                            
                            QuickFilterTag(
                                title: "3+ Stars",
                                icon: "star",
                                isSelected: selectedRatingFilter == .threePlus
                            ) {
                                selectedRatingFilter = selectedRatingFilter == .threePlus ? .all : .threePlus
                            }
                            
                            // Clear filters button
                            if hasActiveFilters {
                                Button(action: {
                                    clearAllFilters()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Clear")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Work Friendly Cafes")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if hasActiveFilters {
                            Text("\(activeFiltersCount) filter\(activeFiltersCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.brown)
                                .cornerRadius(10)
                        }
                    }
                    
                    Text("Colombo 7 Area • \(filteredPlaces.count) places found")
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
    
    private func clearAllFilters() {
        filterWiFi = false
        filterQuietZone = false
        filterPowerOutlets = false
        selectedRatingFilter = .all
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
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var reviewRatings: (quietness: Double, wifi: Double, food: Double) = (0.0, 0.0, 0.0)
    @State private var reviewCount = 0
    @State private var powerOutletStatus = "Available"
    
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
                        
                        // Overall rating with stars
                        let overallRating = (reviewRatings.quietness + reviewRatings.wifi + reviewRatings.food) / 3.0
                        let displayRating = overallRating > 0 ? overallRating : place.rating
                        
                        HStack(spacing: 4) {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: Double(index + 1) <= displayRating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                            Text(String(format: "%.1f", displayRating))
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
                    
                    // Power outlet status
                    HStack {
                        Spacer()
                        
                        if place.hasPowerOutlets {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(powerOutletStatus)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        powerOutletStatus == "Abundant" ? .green :
                                        powerOutletStatus == "Limited" ? .orange :
                                        powerOutletStatus == "Not Available" ? .red : .green
                                    )
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
        .onAppear {
            loadRealRatings()
        }
    }
    
    private func loadRealRatings() {
        firebaseManager.fetchReviews(for: place.id) { reviews in
            DispatchQueue.main.async {
                self.reviewCount = reviews.count
                
                guard !reviews.isEmpty else {
                    self.reviewRatings = (0.0, 0.0, 0.0)
                    self.powerOutletStatus = "Available" // Default when no reviews
                    return
                }
                
                // Calculate average ratings for each category
                let avgQuietness = reviews.reduce(0.0) { $0 + $1.quietnessRating } / Double(reviews.count)
                let avgWiFi = reviews.reduce(0.0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
                let avgFood = reviews.reduce(0.0) { $0 + $1.foodTasteRating } / Double(reviews.count)
                
                self.reviewRatings = (avgQuietness, avgWiFi, avgFood)
                
                // Calculate power outlet status based on reviews
                let abundantCount = reviews.filter { $0.powerOutletStatus == "Abundant" }.count
                let limitedCount = reviews.filter { $0.powerOutletStatus == "Limited" }.count
                let notAvailableCount = reviews.filter { $0.powerOutletStatus == "Not Available" }.count
                
                if abundantCount > limitedCount && abundantCount > notAvailableCount {
                    self.powerOutletStatus = "Abundant"
                } else if limitedCount > abundantCount && limitedCount > notAvailableCount {
                    self.powerOutletStatus = "Limited"
                } else if notAvailableCount > abundantCount && notAvailableCount > limitedCount {
                    self.powerOutletStatus = "Not Available"
                } else {
                    self.powerOutletStatus = "Available" // Default when tied
                }
            }
        }
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

struct QuickFilterTag: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .brown)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brown : Color.brown.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PlacesListView()
}

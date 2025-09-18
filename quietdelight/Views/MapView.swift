//
//  MapView.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI
import MapKit
import CoreLocation

// Annotation Model
class PlaceAnnotation: NSObject, MKAnnotation, ObservableObject, Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let place: PlaceData
    let venueType: VenueType
    
    init(place: PlaceData) {
        self.place = place
        self.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        self.title = place.name
        self.subtitle = place.address
        self.venueType = place.venueType
        super.init()
    }
}

//  MapView
struct MapView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var cafeSearchService = CafeSearchService()
    
    @State private var places: [PlaceData] = []
    @State private var cafes: [Cafe] = []
    @State private var searchText = ""
    @State private var selectedPlace: PlaceData?
    @State private var showPlaceDetail = false
    @State private var showFilters = false
    @State private var isLoading = false
    
    // Filter states
    @State private var selectedVenueTypes: Set<VenueType> = [.cafe]
    @State private var selectedAmenities: Set<Amenity> = []
    @State private var minRating: Double = 0.0
    @State private var maxDistance: Double = 3000

    // Map location
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.906111, longitude: 79.870556), // NIBM center
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    // Combined data
    var allPlaces: [PlaceAnnotation] {
        var annotations: [PlaceAnnotation] = []
        
        // Add Firebase places
        for place in filteredPlaces {
            annotations.append(PlaceAnnotation(place: place))
        }
        
        // MapKit search results as PlaceData
        for cafe in filteredCafes {
            let placeData = PlaceData(
                id: cafe.id.uuidString,
                name: cafe.name,
                address: cafe.address,
                latitude: cafe.coordinate.latitude,
                longitude: cafe.coordinate.longitude,
                rating: cafe.rating,
                imageURL: cafe.imageURL ?? "",
                description: PlaceData.generateDescription(for: cafe.name, venueType: cafe.venueType),
                isWorkFriendly: cafe.venueType == .cafe,
                hasWiFi: cafe.amenities.contains(.wifi),
                hasPowerOutlets: cafe.amenities.contains(.powerOutlets),
                isQuietZone: cafe.amenities.contains(.quietZone),
                venueType: cafe.venueType
            )
            annotations.append(PlaceAnnotation(place: placeData))
        }
        
        print("Total annotations: \(annotations.count) (Firebase: \(filteredPlaces.count), MapKit: \(filteredCafes.count))")
        return annotations
    }
    
    var filteredPlaces: [PlaceData] {
        var filtered = places
        // Only include places
        let nibmLocation = CLLocation(latitude: 6.906111, longitude: 79.870556)
        filtered = filtered.filter { place in
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = nibmLocation.distance(from: placeLocation)
            return distance <= 2000
        }
        if !searchText.isEmpty {
            filtered = filtered.filter { place in
                place.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        filtered = filtered.filter { place in
            place.rating >= minRating
        }
       
        return filtered
    }

    var filteredCafes: [Cafe] {
        let nibmLocation = CLLocation(latitude: 6.906111, longitude: 79.870556)
        let filtered = cafes.filter { cafe in
            if !selectedVenueTypes.contains(cafe.venueType) { return false }
            if cafe.rating < minRating { return false }
            if cafe.distance > maxDistance { return false }
            // Only include
            let cafeLocation = CLLocation(latitude: cafe.coordinate.latitude, longitude: cafe.coordinate.longitude)
            let distance = nibmLocation.distance(from: cafeLocation)
            if distance > 2000 { return false }
            if !selectedAmenities.isEmpty {
                let hasRequiredAmenities = selectedAmenities.allSatisfy { amenity in
                    cafe.amenities.contains(amenity)
                }
                if !hasRequiredAmenities { return false }
            }
            if !searchText.isEmpty {
                return cafe.name.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        
        
        let totalFirebasePlaces = filteredPlaces.count
        let remainingSlots = max(0, 10 - totalFirebasePlaces)
        let limitedResults = Array(filtered.prefix(remainingSlots))
        
        let cafeCount = limitedResults.filter { $0.venueType == .cafe }.count
        let restaurantCount = limitedResults.filter { $0.venueType == .restaurant }.count
        print("Filtered results: \(cafeCount) cafes, \(restaurantCount) restaurants (Total: \(limitedResults.count))")
        
        return limitedResults
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Map with custom annotations
                Map(coordinateRegion: $region, annotationItems: allPlaces) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        CustomAnnotationView(
                            annotation: annotation,
                            venueType: annotation.venueType
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedPlace = annotation.place
                                showPlaceDetail = true
                            }
                        }
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
                .onAppear {
                    // center
                    region.center = CLLocationCoordinate2D(latitude: 6.906111, longitude: 79.870556)
                    region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                }
                
                // Search and Filter Bar
                VStack(spacing: 12) {
                 
                    HStack {
                        Spacer()
                        Text("Found \(allPlaces.count) places nearby")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        Spacer()
                    }
                    .padding(.top, 5)
                    
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search cafes & restaurants...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Button(action: {
                            showFilters.toggle()
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.brown)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Quick filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([VenueType.cafe], id: \.self) { venueType in
                                FilterChip(
                                    title: venueType.rawValue,
                                    icon: venueType.icon,
                                    isSelected: selectedVenueTypes.contains(venueType),
                                    color: venueType.color
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                
                                        selectedVenueTypes.removeAll()
                                        selectedVenueTypes.insert(venueType)
                                        print("Selected venue types: \(selectedVenueTypes)")
                                        applyFilters()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                
                // Loading indicator
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        Spacer()
                    }
                }
                
                // Zoom and Location buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 14) {
                            Button(action: {
                                // Zoom in
                                withAnimation {
                                    region.span.latitudeDelta /= 1.5
                                    region.span.longitudeDelta /= 1.5
                                }
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            Button(action: {
                                // Zoom out
                                withAnimation {
                                    region.span.latitudeDelta *= 1.5
                                    region.span.longitudeDelta *= 1.5
                                }
                            }) {
                                Image(systemName: "minus")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            Button(action: centerOnUserLocation) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Map ")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadData()
            }
            .onChange(of: locationManager.location) { location in
                if let location = location {
                    searchNearbyPlaces(location: location)
                }
            }
            .onChange(of: searchText) { _ in
                applyFilters()
            }
            .sheet(isPresented: $showPlaceDetail) {
                if let place = selectedPlace {
                    PlaceDetailView(place: place)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(
                    selectedVenueTypes: $selectedVenueTypes,
                    selectedAmenities: $selectedAmenities,
                    minRating: $minRating,
                    maxDistance: $maxDistance
                ) {
                    applyFilters()
                }
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        // Load Firebase places
        firebaseManager.fetchColombo7Places { fetchedPlaces in
            DispatchQueue.main.async {
                self.places = fetchedPlaces
                // Save to Core Data for offline access
                fetchedPlaces.forEach { place in
                    CoreDataManager.shared.addPlace(place)
                }
            }
        }
        
        // Always search for cafes
        let nibmLocation = CLLocation(latitude: 6.906111, longitude: 79.870556)
        searchNearbyPlaces(location: nibmLocation)
        
        // Also search if user location is available
        if let location = locationManager.location {
            searchNearbyPlaces(location: location)
        }
    }
    
    private func searchNearbyPlaces(location: CLLocation) {
        isLoading = true
        
        Task {
            await cafeSearchService.searchNearbyPlaces(location: location, query: searchText.isEmpty ? "cafe restaurant" : searchText)
            
            DispatchQueue.main.async {
                self.cafes = cafeSearchService.cafes
                print("Found \(self.cafes.count) cafes from search")
                
                // Save cafe in firebase
                self.saveCafesToFirebase()
                
             
                if self.cafes.isEmpty {
                    self.performDirectMapKitSearch(location: location)
                } else {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func performDirectMapKitSearch(location: CLLocation) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "cafe restaurant"
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                let mapKitCafes = response.mapItems.prefix(10).compactMap { item -> Cafe? in
                    guard let name = item.name else { return nil }
                    
                    let venueType: VenueType = PlaceData.determineVenueType(from: name)
                    print("Place: \(name) -> VenueType: \(venueType.rawValue)")
                    
                    return Cafe(
                        name: name,
                        address: item.placemark.title ?? "",
                        coordinate: item.placemark.coordinate,
                        rating: Double.random(in: 3.5...5.0),
                        distance: location.distance(from: CLLocation(
                            latitude: item.placemark.coordinate.latitude,
                            longitude: item.placemark.coordinate.longitude
                        )),
                        isOpen: true,
                        priceRange: "$$",
                        specialty: venueType == .cafe ? "Coffee" : "Local Cuisine",
                        imageURL: nil,
                        venueType: venueType,
                        amenities: [.wifi],
                        cuisine: venueType == .restaurant ? "Sri Lankan" : nil,
                        phoneNumber: nil,
                        website: nil
                    )
                }
                
                self.cafes = Array(mapKitCafes.prefix(10)) // Limit place
                print("Found \(self.cafes.count) places nearby")
                
                
                self.saveCafesToFirebase()
                
                self.isLoading = false
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation(.easeInOut(duration: 1.0)) {
                region.center = location.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
    }
    
    private func saveCafesToFirebase() {
        guard !cafes.isEmpty else { return }
        
        var savedCount = 0
        var skippedCount = 0
        let totalCafes = cafes.count
        
        print("Attempting to save \(totalCafes) places to Firebase...")
        
        for cafe in cafes {
            let placeData = PlaceData(
                id: cafe.id.uuidString,
                name: cafe.name,
                address: cafe.address,
                latitude: cafe.coordinate.latitude,
                longitude: cafe.coordinate.longitude,
                rating: cafe.rating,
                imageURL: cafe.imageURL ?? "",
                description: PlaceData.generateDescription(for: cafe.name, venueType: cafe.venueType),
                isWorkFriendly: cafe.venueType == .cafe,
                hasWiFi: cafe.amenities.contains(.wifi),
                hasPowerOutlets: cafe.amenities.contains(.powerOutlets),
                isQuietZone: cafe.amenities.contains(.quietZone),
                venueType: cafe.venueType
            )
            
            firebaseManager.savePlaceToFirebase(placeData) { success in
                if success {
                    // Check if it was actually saved (not a duplicate)
                    if cafe.name.contains("already exists") {
                        skippedCount += 1
                        print("Skipped duplicate: \(cafe.name)")
                    } else {
                        savedCount += 1
                        print("Successfully saved: \(cafe.name)")
                    }
                } else {
                    print("Failed to save: \(cafe.name)")
                }
                
                // Report summary when all attempts are complete
                DispatchQueue.main.async {
                    if savedCount + skippedCount >= totalCafes {
                        print("Firebase save summary: \(savedCount) new places saved, \(skippedCount) duplicates skipped")
                    }
                }
            }
        }
    }
    
    private func applyFilters() {
        cafeSearchService.selectedVenueTypes = selectedVenueTypes
        cafeSearchService.selectedAmenities = selectedAmenities
        cafeSearchService.minRating = minRating
        cafeSearchService.maxDistance = maxDistance
    }
}

// custom Annotation View
struct CustomAnnotationView: View {
    let annotation: PlaceAnnotation
    let venueType: VenueType
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                onTap()
            }
        }) {
            VStack(spacing: 0) {
                // Main annotation
                VStack(spacing: 2) {
                    Image(systemName: venueType.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(String(format: "%.1f", annotation.place.rating))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(16)
                .background(
                    Circle()
                        .fill(venueType.color)
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 4)
                )
                
                // larger
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(venueType.color)
                    .font(.system(size: 12))
                    .offset(y: -4)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            isPressed = isPressing
        } perform: {
          
        }
    }
}

//  Filter View
struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "5A3529") : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//  Filter View Sheet
struct FilterView: View {
    @Binding var selectedVenueTypes: Set<VenueType>
    @Binding var selectedAmenities: Set<Amenity>
    @Binding var minRating: Double
    @Binding var maxDistance: Double
    
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Amenities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amenities")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(Array(Amenity.allCases.prefix(8)), id: \.self) { amenity in
                                FilterOptionCard(
                                    title: amenity.rawValue,
                                    icon: amenity.icon,
                                    color: amenity.color,
                                    isSelected: selectedAmenities.contains(amenity)
                                ) {
                                    if selectedAmenities.contains(amenity) {
                                        selectedAmenities.remove(amenity)
                                    } else {
                                        selectedAmenities.insert(amenity)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Rating Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Minimum Rating")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("\(String(format: "%.1f", minRating))⭐")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Slider(value: $minRating, in: 0...5, step: 0.5)
                                .accentColor(.brown)
                        }
                    }
                    
                    // Distance Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Maximum Distance")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("\(String(format: "%.1f", maxDistance / 1000))km")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Slider(value: $maxDistance, in: 500...10000, step: 500)
                                .accentColor(.brown)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedVenueTypes = [.cafe, .restaurant]
                        selectedAmenities = []
                        minRating = 0.0
                        maxDistance = 5000
                    }
                    .foregroundColor(.brown)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.brown)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

//  Filter Option Card
struct FilterOptionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension PlaceData: Identifiable {}

#Preview {
    MapView()
}

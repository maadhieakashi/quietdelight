//
//  cafenearby.swift
//  cafedelight
//
// Created by SAHimeshi 002 on 2025-08-20.
//
import SwiftUI
import MapKit
import CoreLocation

//Models
struct Cafe: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let rating: Double
    let distance: Double
    let isOpen: Bool
    let priceRange: String
    let specialty: String
    let imageURL: String?
    let venueType: VenueType
    let amenities: [Amenity]
    let cuisine: String?
    let phoneNumber: String?
    let website: String?
    
    var distanceString: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    // Simplified hash function
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Cafe, rhs: Cafe) -> Bool {
        return lhs.id == rhs.id
    }
}

// Venue Types
enum VenueType: String, CaseIterable {
    case cafe = "Cafe"
    case restaurant = "Restaurant"
    
    var icon: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife"
        }
    }
    
    var color: Color {
        switch self {
        case .cafe: return Color(hex: "5A3529")
        case .restaurant: return Color.black
        }
    }
}

// Amenities
enum Amenity: String, CaseIterable {
    case wifi = "Fast WiFi"
    case quietZone = "Quiet Zone"
    case powerOutlets = "Power Outlets"
    case outdoorSeating = "Outdoor Seating"
    case parking = "Parking Available"
    case delivery = "Delivery"
    case takeout = "Takeout"
    case reservations = "Reservations"
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .quietZone: return "speaker.slash.fill"
        case .powerOutlets: return "bolt.fill"
        case .outdoorSeating: return "tree.fill"
        case .parking: return "car.fill"
        case .delivery: return "bicycle"
        case .takeout: return "bag.fill"
        case .reservations: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .wifi: return .blue
        case .quietZone: return .purple
        case .powerOutlets: return .green
        case .outdoorSeating: return .green
        case .parking: return .gray
        case .delivery: return .blue
        case .takeout: return .orange
        case .reservations: return .purple
        }
    }
}


// Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startLocationUpdates()
        }
    }
}

//Venue Search Service
class CafeSearchService: ObservableObject {
    @Published var cafes: [Cafe] = []
    @Published var isLoading = false
    @Published var selectedVenueTypes: Set<VenueType> = [.cafe, .restaurant]
    @Published var selectedAmenities: Set<Amenity> = []
    @Published var maxDistance: Double = 5000 // 5km
    @Published var minRating: Double = 0.0
    
    func searchNearbyPlaces(location: CLLocation, query: String = "") async {
        await MainActor.run {
            isLoading = true
        }
        
        // Search for cafes and restaurants separately to ensure we get 5 of each
        var allVenues: [Cafe] = []
        
        // Search for cafes
        let cafeQuery = query.isEmpty ? getSearchQuery(for: .cafe) : "\(query) cafe"
        let cafeVenues = await searchVenueType(location: location, query: cafeQuery, venueType: .cafe)
        let filteredCafes = applyFilters(to: cafeVenues, location: location)
        allVenues.append(contentsOf: Array(filteredCafes.prefix(5))) // Take only 5 cafes
        
        // Search for restaurants
        let restaurantQuery = query.isEmpty ? getSearchQuery(for: .restaurant) : "\(query) restaurant"
        let restaurantVenues = await searchVenueType(location: location, query: restaurantQuery, venueType: .restaurant)
        let filteredRestaurants = applyFilters(to: restaurantVenues, location: location)
        allVenues.append(contentsOf: Array(filteredRestaurants.prefix(5))) // Take only 5 restaurants
        
        await MainActor.run {
            self.cafes = allVenues.sorted { $0.distance < $1.distance }
            print("Found \(allVenues.filter { $0.venueType == .cafe }.count) cafes and \(allVenues.filter { $0.venueType == .restaurant }.count) restaurants")
            self.isLoading = false
        }
    }
    
    private func searchVenueType(location: CLLocation, query: String, venueType: VenueType) async -> [Cafe] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: maxDistance,
            longitudinalMeters: maxDistance
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            return response.mapItems.compactMap { mapItem -> Cafe? in
                guard let name = mapItem.name,
                      let itemLocation = mapItem.placemark.location else {
                    return nil
                }
                
                let distance = itemLocation.distance(from: location)
                let rating = Double.random(in: 3.0...5.0)
                let amenities = generateRandomAmenities(for: venueType)
                let cuisine = generateCuisineType(for: venueType)
                
                return Cafe(
                    name: name,
                    address: mapItem.placemark.thoroughfare ?? "Address unavailable",
                    coordinate: mapItem.placemark.coordinate,
                    rating: rating,
                    distance: distance,
                    isOpen: Bool.random(),
                    priceRange: "$$",
                    specialty: generateSpecialty(for: venueType),
                    imageURL: nil,
                    venueType: venueType,
                    amenities: amenities,
                    cuisine: cuisine,
                    phoneNumber: nil,
                    website: nil
                )
            }
        } catch {
            print("Search error: \(error.localizedDescription)")
            return []
        }
    }
    
    private func applyFilters(to venues: [Cafe], location: CLLocation) -> [Cafe] {
        return venues.filter { venue in
            // Distance filter
            guard venue.distance <= maxDistance else { return false }
            
            // Rating filter
            guard venue.rating >= minRating else { return false }
            
            // Amenities filter
            if !selectedAmenities.isEmpty {
                let venueAmenities = Set(venue.amenities)
                guard !selectedAmenities.isDisjoint(with: venueAmenities) else { return false }
            }
            
            return true
        }
    }
    
    private func getSearchQuery(for venueType: VenueType) -> String {
        switch venueType {
        case .cafe:
            return "cafe coffee work friendly wifi"
        case .restaurant:
            return "restaurant dining food"
        }
    }
    
    private func generateRandomAmenities(for venueType: VenueType) -> [Amenity] {
        var amenities: [Amenity] = []
        
        switch venueType {
        case .cafe:
            amenities = [.wifi, .powerOutlets, .quietZone].compactMap { Bool.random() ? $0 : nil }
        case .restaurant:
            amenities = [.reservations, .outdoorSeating, .parking].compactMap { Bool.random() ? $0 : nil }
        }
        
        return amenities
    }
    
    private func generateCuisineType(for venueType: VenueType) -> String? {
        switch venueType {
        case .restaurant:
            let cuisines = ["Italian", "Chinese", "Thai"]
            return cuisines.randomElement()
        case .cafe:
            return nil
        }
    }
    
    private func generateSpecialty(for venueType: VenueType) -> String {
        switch venueType {
        case .cafe:
            let specialties = ["Specialty Coffee", "Quiet Study Space", "Fast WiFi", "Great Atmosphere"]
            return specialties.randomElement() ?? "Coffee Shop"
        case .restaurant:
            let specialties = ["Fine Dining", "Casual Dining", "Family Restaurant", "Authentic Cuisine"]
            return specialties.randomElement() ?? "Fine Dining Experience"
        }
    }
}

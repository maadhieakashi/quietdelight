//
//  Cafe.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//

import SwiftUI
import MapKit
import CoreLocation

extension PlaceData: Identifiable {}

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
    var isFavorite: Bool = false
    
    var distanceString: String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    // hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(address)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(rating)
        hasher.combine(distance)
        hasher.combine(isOpen)
        hasher.combine(priceRange)
        hasher.combine(specialty)
        hasher.combine(imageURL)
        hasher.combine(venueType)
        hasher.combine(cuisine)
        // Note: Not including isFavorite since it's mutable and could change
    }
    
    static func == (lhs: Cafe, rhs: Cafe) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.address == rhs.address &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.rating == rhs.rating &&
        lhs.distance == rhs.distance &&
        lhs.isOpen == rhs.isOpen &&
        lhs.priceRange == rhs.priceRange &&
        lhs.specialty == rhs.specialty &&
        lhs.imageURL == rhs.imageURL &&
        lhs.venueType == rhs.venueType &&
        lhs.cuisine == rhs.cuisine
        // Note: Not comparing isFavorite since it's mutable
    }
}

// Venue Types
enum VenueType: String, CaseIterable {
    case cafe = "Cafe"
    case restaurant = "Restaurant"
    case fastFood = "Fast Food"
    case bakery = "Bakery"
    case bar = "Bar"
    case foodTruck = "Food Truck"
    
    var icon: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife"
        case .fastFood: return "takeoutbag.and.cup.and.straw.fill"
        case .bakery: return "birthday.cake.fill"
        case .bar: return "wineglass.fill"
        case .foodTruck: return "truck.box.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cafe: return .brown
        case .restaurant: return .blue
        case .fastFood: return .orange
        case .bakery: return .pink
        case .bar: return .purple
        case .foodTruck: return .green
        }
    }
}

// Amenities
enum Amenity: String, CaseIterable {
    case wifi = "Fast WiFi"
    case quietZone = "Quiet Zone"
    case powerOutlets = "Power Outlets"
    case outdoorSeating = "Outdoor Seating"
    case petFriendly = "Pet Friendly"
    case parking = "Parking Available"
    case liveMusic = "Live Music"
    case delivery = "Delivery"
    case takeout = "Takeout"
    case reservations = "Reservations"
    case wheelchairAccessible = "Wheelchair Accessible"
    case familyFriendly = "Family Friendly"
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .quietZone: return "speaker.slash.fill"
        case .powerOutlets: return "bolt.fill"
        case .outdoorSeating: return "tree.fill"
        case .petFriendly: return "pawprint.fill"
        case .parking: return "car.fill"
        case .liveMusic: return "music.note"
        case .delivery: return "bicycle"
        case .takeout: return "bag.fill"
        case .reservations: return "calendar"
        case .wheelchairAccessible: return "figure.roll"
        case .familyFriendly: return "figure.and.child.holdinghands"
        }
    }
    
    var color: Color {
        switch self {
        case .wifi: return .blue
        case .quietZone: return .purple
        case .powerOutlets: return .green
        case .outdoorSeating: return .green
        case .petFriendly: return .orange
        case .parking: return .gray
        case .liveMusic: return .red
        case .delivery: return .blue
        case .takeout: return .orange
        case .reservations: return .purple
        case .wheelchairAccessible: return .blue
        case .familyFriendly: return .pink
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
    @Published var priceRange: Set<String> = ["$", "$$", "$$$"]
    
    func searchNearbyPlaces(location: CLLocation, query: String = "") async {
        await MainActor.run {
            isLoading = true
        }
        
        // Search for different venue types
        var allVenues: [Cafe] = []
        
        for venueType in selectedVenueTypes {
            let searchQuery = query.isEmpty ? getSearchQuery(for: venueType) : "\(query) \(venueType.rawValue.lowercased())"
            let venues = await searchVenueType(location: location, query: searchQuery, venueType: venueType)
            allVenues.append(contentsOf: venues)
        }
        
        // Apply filters
        let filteredVenues = applyFilters(to: allVenues, location: location)
        
        await MainActor.run {
            self.cafes = filteredVenues.sorted { $0.distance < $1.distance }
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
                let priceRanges = ["$", "$$", "$$$"]
                let amenities = generateRandomAmenities(for: venueType)
                let cuisine = generateCuisineType(for: venueType)
                
                return Cafe(
                    name: name,
                    address: mapItem.placemark.thoroughfare ?? "Address unavailable",
                    coordinate: mapItem.placemark.coordinate,
                    rating: rating,
                    distance: distance,
                    isOpen: Bool.random(),
                    priceRange: priceRanges.randomElement() ?? "$",
                    specialty: generateSpecialty(for: venueType),
                    imageURL: nil,
                    venueType: venueType,
                    amenities: amenities,
                    cuisine: cuisine,
                    phoneNumber: generatePhoneNumber(),
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
            
            // Price range filter
            guard priceRange.contains(venue.priceRange) else { return false }
            
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
        case .fastFood:
            return "fast food quick service"
        case .bakery:
            return "bakery pastry bread"
        case .bar:
            return "bar pub drinks"
        case .foodTruck:
            return "food truck mobile food"
        }
    }
    
    private func generateRandomAmenities(for venueType: VenueType) -> [Amenity] {
        var amenities: [Amenity] = []
        
        switch venueType {
        case .cafe:
            amenities = [.wifi, .powerOutlets, .quietZone].compactMap { Bool.random() ? $0 : nil }
        case .restaurant:
            amenities = [.reservations, .outdoorSeating, .parking, .wheelchairAccessible].compactMap { Bool.random() ? $0 : nil }
        case .fastFood:
            amenities = [.takeout, .delivery, .parking, .familyFriendly].compactMap { Bool.random() ? $0 : nil }
        case .bakery:
            amenities = [.takeout, .wifi, .familyFriendly].compactMap { Bool.random() ? $0 : nil }
        case .bar:
            amenities = [.liveMusic, .outdoorSeating, .parking].compactMap { Bool.random() ? $0 : nil }
        case .foodTruck:
            amenities = [.takeout, .outdoorSeating].compactMap { Bool.random() ? $0 : nil }
        }
        
        // Add some random common amenities
        let commonAmenities: [Amenity] = [.petFriendly, .wheelchairAccessible, .familyFriendly]
        amenities.append(contentsOf: commonAmenities.compactMap { Bool.random(probability: 0.3) ? $0 : nil })
        
        return amenities
    }
    
    private func generateCuisineType(for venueType: VenueType) -> String? {
        switch venueType {
        case .restaurant:
            let cuisines = ["Italian", "Chinese", "Thai", "Mexican", "Japanese", "Indian", "American", "Mediterranean", "French", "Korean"]
            return cuisines.randomElement()
        case .fastFood:
            let fastFoodTypes = ["Burgers", "Pizza", "Sandwiches", "Fried Chicken", "Asian Fusion"]
            return fastFoodTypes.randomElement()
        case .bakery:
            return "Baked Goods"
        case .bar:
            return "Bar Food"
        default:
            return nil
        }
    }
    
    private func generateSpecialty(for venueType: VenueType) -> String {
        switch venueType {
        case .cafe:
            let specialties = ["Specialty Coffee", "Quiet Study Space", "Fast WiFi", "Great Atmosphere", "Artisan Pastries"]
            return specialties.randomElement() ?? "Coffee Shop"
        case .restaurant:
            return "Fine Dining Experience"
        case .fastFood:
            return "Quick & Convenient"
        case .bakery:
            return "Fresh Baked Daily"
        case .bar:
            return "Craft Drinks & Atmosphere"
        case .foodTruck:
            return "Street Food Experience"
        }
    }
    
    private func generatePhoneNumber() -> String {
        return "+1 (\(Int.random(in: 200...999))) \(Int.random(in: 200...999))-\(Int.random(in: 1000...9999))"
    }
}

extension Bool {
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}


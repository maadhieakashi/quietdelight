//
//  Cafe.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
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
        lhs.imageURL == rhs.imageURL
    
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

//Cafe Search Service
class CafeSearchService: ObservableObject {
    @Published var cafes: [Cafe] = []
    @Published var isLoading = false
    
    func searchNearbyPlaces(location: CLLocation, query: String = "cafe") async {
        await MainActor.run {
            isLoading = true
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000, // 5km radius
            longitudinalMeters: 5000
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            let foundCafes = response.mapItems.compactMap { mapItem -> Cafe? in
                guard let name = mapItem.name,
                      let itemLocation = mapItem.placemark.location else {
                    return nil
                }
                
                let distance = itemLocation.distance(from: location)
                let rating = Double.random(in: 3.5...5.0)
                let priceRanges = ["$", "$$", "$$$"]
                let specialties = ["Specialty Coffee", "Quiet Study Space", "Fast WiFi", "Great Atmosphere", "Artisan Pastries"]
                
                return Cafe(
                    name: name,
                    address: mapItem.placemark.thoroughfare ?? "Address unavailable",
                    coordinate: mapItem.placemark.coordinate,
                    rating: rating,
                    distance: distance,
                    isOpen: Bool.random(), // Mock data
                    priceRange: priceRanges.randomElement() ?? "$",
                    specialty: specialties.randomElement() ?? "Coffee Shop",
                    imageURL: nil
                )
            }
            
            await MainActor.run {
                self.cafes = foundCafes.sorted { $0.distance < $1.distance }
                self.isLoading = false
            }
        } catch {
            print("Search error: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

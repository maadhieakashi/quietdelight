//
//  CoreDataManager.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-30.
//

import CoreData
import Foundation

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CafeModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // MARK: - Place Methods
    func addPlace(_ place: PlaceData) {
        // Check if place already exists to prevent duplicates
        if isPlaceExists(place) {
            print("Place '\(place.name)' already exists in Core Data, skipping...")
            return
        }
        
        let newPlace = Place(context: context)
        newPlace.id = place.id
        newPlace.name = place.name
        newPlace.address = place.address
        newPlace.latitude = place.latitude
        newPlace.longitude = place.longitude
        newPlace.rating = place.rating
        newPlace.imageURL = place.imageURL
        newPlace.placeDescription = place.description
        newPlace.isWorkFriendly = place.isWorkFriendly
        newPlace.hasWiFi = place.hasWiFi
        newPlace.hasPowerOutlets = place.hasPowerOutlets
        newPlace.isQuietZone = place.isQuietZone
        newPlace.createdAt = Date()
        
        save()
    }
    
    private func isPlaceExists(_ place: PlaceData) -> Bool {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        
        // First check by exact ID
        request.predicate = NSPredicate(format: "id == %@", place.id)
        
        do {
            let count = try context.count(for: request)
            if count > 0 {
                return true
            }
        } catch {
            print("Error checking place by ID: \(error)")
        }
        
        // Then check by name and location proximity
        request.predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ AND latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f",
            place.name,
            place.latitude - 0.0005, // ~50m radius
            place.latitude + 0.0005,
            place.longitude - 0.0005,
            place.longitude + 0.0005
        )
        
        do {
            let similarPlaces = try context.fetch(request)
            return !similarPlaces.isEmpty
        } catch {
            print("Error checking similar places: \(error)")
            return false
        }
    }
    
    func fetchPlaces() -> [Place] {
        let request: NSFetchRequest<Place> = Place.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
    
    // MARK: - Favorite Methods
    func addFavorite(placeId: String, userId: String) {
        let favorite = FavoritePlace(context: context)
        favorite.id = UUID().uuidString
        favorite.placeId = placeId
        favorite.userId = userId
        favorite.createdAt = Date()
        save()
        
        // Also sync with Firebase
        FirebaseManager.shared.addFavorite(placeId: placeId, userId: userId)
    }
    
    func removeFavorite(placeId: String, userId: String) {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        request.predicate = NSPredicate(format: "placeId == %@ AND userId == %@", placeId, userId)
        
        do {
            let favorites = try context.fetch(request)
            for favorite in favorites {
                context.delete(favorite)
            }
            save()
            
            // Also sync with Firebase
            FirebaseManager.shared.removeFavorite(placeId: placeId, userId: userId)
        } catch {
            print("Remove favorite error: \(error)")
        }
    }
    
    func isFavorite(placeId: String, userId: String) -> Bool {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        request.predicate = NSPredicate(format: "placeId == %@ AND userId == %@", placeId, userId)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
    
    func fetchFavorites(for userId: String) -> [FavoritePlace] {
        let request: NSFetchRequest<FavoritePlace> = FavoritePlace.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch favorites error: \(error)")
            return []
        }
    }
}

// MARK: - Data Models
struct PlaceData {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let imageURL: String
    let description: String
    let isWorkFriendly: Bool
    let hasWiFi: Bool
    let hasPowerOutlets: Bool
    let isQuietZone: Bool
    let venueType: VenueType
    
    init(id: String, name: String, address: String, latitude: Double, longitude: Double, rating: Double, imageURL: String, description: String = "", isWorkFriendly: Bool, hasWiFi: Bool, hasPowerOutlets: Bool, isQuietZone: Bool, venueType: VenueType? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.imageURL = imageURL
        self.description = description.isEmpty ? PlaceData.generateDescription(for: name, venueType: venueType ?? PlaceData.determineVenueType(from: name)) : description
        self.isWorkFriendly = isWorkFriendly
        self.hasWiFi = hasWiFi
        self.hasPowerOutlets = hasPowerOutlets
        self.isQuietZone = isQuietZone
        // Determine venue type from name/keywords if not provided
        self.venueType = venueType ?? PlaceData.determineVenueType(from: name)
    }
    
    static func determineVenueType(from name: String) -> VenueType {
        let lowercaseName = name.lowercased()
        
        // Keywords for cafes
        let cafeKeywords = ["cafe", "coffee", "espresso", "barista", "latte", "cappuccino", "brew", "roast", "grind", "bean", "starbucks", "costa", "dunkin"]
        
        // Keywords for restaurants
        let restaurantKeywords = ["restaurant", "dining", "bistro", "grill", "kitchen", "eatery", "tavern", "pub", "pizzeria", "sushi", "curry", "noodle", "food court", "hotel", "inn"]
        
        // Check for cafe keywords first
        for keyword in cafeKeywords {
            if lowercaseName.contains(keyword) {
                return .cafe
            }
        }
        
        // Check for restaurant keywords
        for keyword in restaurantKeywords {
            if lowercaseName.contains(keyword) {
                return .restaurant
            }
        }
        
        // Default to cafe if uncertain (since we're focusing on work-friendly places)
        return .cafe
    }
    
    static func generateDescription(for name: String, venueType: VenueType) -> String {
        let lowercaseName = name.lowercased()
        
        switch venueType {
        case .cafe:
            if lowercaseName.contains("starbucks") {
                return "Global coffee chain offering premium coffee, comfortable seating, and reliable WiFi for work and study. Perfect for remote work with consistent atmosphere and quality beverages."
            } else if lowercaseName.contains("costa") {
                return "British coffee chain known for handcrafted coffee and cozy atmosphere. Features comfortable seating areas ideal for work sessions and casual meetings."
            } else if lowercaseName.contains("coffee") || lowercaseName.contains("cafe") {
                return "Local coffee shop featuring specialty coffee, comfortable seating, and work-friendly environment. Great spot for productivity with quality beverages and welcoming atmosphere."
            } else {
                return "Cozy cafe offering quality coffee and light meals in a comfortable setting. Perfect for work, study, or casual meetings with friends."
            }
        case .restaurant:
            if lowercaseName.contains("hotel") || lowercaseName.contains("inn") {
                return "Hotel restaurant offering fine dining experience with professional service. Features comfortable dining areas suitable for business meetings and special occasions."
            } else if lowercaseName.contains("sushi") {
                return "Japanese restaurant specializing in fresh sushi and authentic cuisine. Offers quiet dining atmosphere perfect for business lunches and intimate conversations."
            } else if lowercaseName.contains("pizzeria") || lowercaseName.contains("pizza") {
                return "Casual dining pizzeria serving fresh made-to-order pizzas. Family-friendly atmosphere with comfortable seating for groups and casual meetings."
            } else if lowercaseName.contains("curry") || lowercaseName.contains("indian") {
                return "Authentic restaurant serving flavorful local and international cuisine. Offers comfortable dining experience perfect for lunch meetings and dinner gatherings."
            } else {
                return "Popular restaurant serving delicious local and international cuisine. Comfortable dining environment perfect for business meals and social gatherings."
            }
        }
    }
}

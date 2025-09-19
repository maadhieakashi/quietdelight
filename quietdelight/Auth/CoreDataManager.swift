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
    
    //  Place Methods
    func addPlace(_ place: PlaceData) {
        // Check if place already exists to prevent dupicate
        if isPlaceExists(place) {
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
        request.predicate = NSPredicate(format: "id == %@", place.id)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking place existence: \(error)")
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
    
    //Favorite Methods
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
    
    //Review Methods
    func addReview(_ reviewData: ReviewData) {
        // Check if review already exists to prevent duplicates
        if isReviewExists(reviewData) {
            return
        }
        
        let newReview = Review(context: context)
        newReview.id = reviewData.id
        newReview.placeId = reviewData.placeId
        newReview.userId = reviewData.userId
        newReview.userName = reviewData.userName
        newReview.userImageURL = reviewData.userImageURL
        newReview.rating = reviewData.rating
        newReview.comment = reviewData.comment
        newReview.quietnessRating = reviewData.quietnessRating
        newReview.wifiStabilityRating = reviewData.wifiStabilityRating
        newReview.foodTasteRating = reviewData.foodTasteRating
        newReview.powerOutletStatus = reviewData.powerOutletStatus
        newReview.createdAt = reviewData.createdAt
        
        save()
    }
    
    private func isReviewExists(_ reviewData: ReviewData) -> Bool {
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reviewData.id)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking review existence: \(error)")
            return false
        }
    }
    
    func fetchReviews(for placeId: String) -> [Review] {
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        request.predicate = NSPredicate(format: "placeId == %@", placeId)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch reviews error: \(error)")
            return []
        }
    }
    
    func deleteReview(reviewId: String) {
        let request: NSFetchRequest<Review> = Review.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reviewId)
        
        do {
            let reviews = try context.fetch(request)
            for review in reviews {
                context.delete(review)
            }
            save()
        } catch {
            print("Delete review error: \(error)")
        }
    }
    
    func syncReviewsFromFirebase(_ firebaseReviews: [ReviewData]) {
        for firebaseReview in firebaseReviews {
            addReview(firebaseReview)
        }
    }
    
    // Helper function to convert Core Data Review to ReviewData
    func convertToReviewData(_ review: Review) -> ReviewData? {
        guard let id = review.id,
              let placeId = review.placeId,
              let userId = review.userId,
              let userName = review.userName,
              let userImageURL = review.userImageURL,
              let comment = review.comment,
              let powerOutletStatus = review.powerOutletStatus,
              let createdAt = review.createdAt else {
            return nil
        }
        
        return ReviewData(
            id: id,
            placeId: placeId,
            userId: userId,
            userName: userName,
            userImageURL: userImageURL,
            rating: review.rating,
            comment: comment,
            quietnessRating: review.quietnessRating,
            wifiStabilityRating: review.wifiStabilityRating,
            foodTasteRating: review.foodTasteRating,
            powerOutletStatus: powerOutletStatus,
            createdAt: createdAt
        )
    }
}

//  Data Models
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
        // Determine venue type from name
        self.venueType = venueType ?? PlaceData.determineVenueType(from: name)
    }
    
    static func determineVenueType(from name: String) -> VenueType {
        let lowercaseName = name.lowercased()
        
        // Keywords for cafes
        let cafeKeywords = ["cafe", "coffee", "espresso", "brew", "starbucks", "costa"]
        
        // Check for cafe keywords
        for keyword in cafeKeywords {
            if lowercaseName.contains(keyword) {
                return .cafe
            }
        }
        
        // Default to cafe
        return .cafe
    }
    
    static func generateDescription(for name: String, venueType: VenueType) -> String {
        return "Coffee shop offering quality beverages and comfortable seating. Great spot for work, study, or casual meetings with friends."
    }
}

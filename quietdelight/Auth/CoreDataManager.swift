//
//  CoreDataManager.swift
//  quietdelight
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
    
    // Place Methods
    func addPlace(_ place: PlaceData) {
        let newPlace = Place(context: context)
        newPlace.id = place.id
        newPlace.name = place.name
        newPlace.address = place.address
        newPlace.latitude = place.latitude
        newPlace.longitude = place.longitude
        newPlace.rating = place.rating
        newPlace.imageURL = place.imageURL
        newPlace.isWorkFriendly = place.isWorkFriendly
        newPlace.hasWiFi = place.hasWiFi
        newPlace.hasPowerOutlets = place.hasPowerOutlets
        newPlace.isQuietZone = place.isQuietZone
        newPlace.createdAt = Date()
        
        save()
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
    
    // Favorite Methods
    func addFavorite(placeId: String, userId: String) {
        let favorite = FavoritePlace(context: context)
        favorite.id = UUID().uuidString
        favorite.placeId = placeId
        favorite.userId = userId
        favorite.createdAt = Date()
        save()
        
        // sync Firebase
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
            
            //sync Firebase
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

//Data Models
struct PlaceData {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let imageURL: String
    let isWorkFriendly: Bool
    let hasWiFi: Bool
    let hasPowerOutlets: Bool
    let isQuietZone: Bool
}

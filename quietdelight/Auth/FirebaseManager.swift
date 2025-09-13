//
//  FirebaseManager.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-30.
//

import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
   let db = Firestore.firestore()
    
    init() {
    
    }
    
    //Places
    func fetchColombo7Places(completion: @escaping ([PlaceData]) -> Void) {
        db.collection("places")
            .whereField("area", isEqualTo: "Colombo 7")
            .whereField("isWorkFriendly", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching places: \(error)")
                    completion([])
                    return
                }
                
                let places = snapshot?.documents.compactMap { doc -> PlaceData? in
                    let data = doc.data()
                    let venueTypeString = data["venueType"] as? String
                    let venueType = VenueType(rawValue: venueTypeString ?? "") ?? .cafe
                    
                    return PlaceData(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        address: data["address"] as? String ?? "",
                        latitude: data["latitude"] as? Double ?? 0.0,
                        longitude: data["longitude"] as? Double ?? 0.0,
                        rating: data["rating"] as? Double ?? 0.0,
                        imageURL: data["imageURL"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        isWorkFriendly: data["isWorkFriendly"] as? Bool ?? false,
                        hasWiFi: data["hasWiFi"] as? Bool ?? false,
                        hasPowerOutlets: data["hasPowerOutlets"] as? Bool ?? false,
                        isQuietZone: data["isQuietZone"] as? Bool ?? false,
                        venueType: venueType
                    )
                } ?? []
                
                completion(places)
            }
    }
    
    func savePlaceToFirebase(_ place: PlaceData, completion: @escaping (Bool) -> Void) {
       
        checkIfPlaceExists(place) { exists, existingPlaceId in
            if exists {
                print("Place '\(place.name)' already exists in Firebase with ID: \(existingPlaceId ?? "unknown")")
                completion(true)
                return
            }
            
           
            let placeRef = self.db.collection("places").document(place.id)
            
            let placeData: [String: Any] = [
                "name": place.name,
                "address": place.address,
                "latitude": place.latitude,
                "longitude": place.longitude,
                "rating": place.rating,
                "imageURL": place.imageURL,
                "description": place.description,
                "isWorkFriendly": place.isWorkFriendly,
                "hasWiFi": place.hasWiFi,
                "hasPowerOutlets": place.hasPowerOutlets,
                "isQuietZone": place.isQuietZone,
                "venueType": place.venueType.rawValue,
                "area": "Colombo 7",
                "createdAt": Timestamp(date: Date()),
                "source": "mapkit"
            ]
            
            placeRef.setData(placeData, merge: true) { error in
                if let error = error {
                    print("Error saving place to Firebase: \(error)")
                    completion(false)
                } else {
                    print("Successfully saved new place: \(place.name)")
                    completion(true)
                }
            }
        }
    }
    
    private func checkIfPlaceExists(_ place: PlaceData, completion: @escaping (Bool, String?) -> Void) {

        db.collection("places")
            .whereField("latitude", isGreaterThan: place.latitude - 0.001) // ~100m radius
            .whereField("latitude", isLessThan: place.latitude + 0.001)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking for duplicate places: \(error)")
                    completion(false, nil)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(false, nil)
                    return
                }
                
               
                for doc in documents {
                    let data = doc.data()
                    let existingName = data["name"] as? String ?? ""
                    let existingLat = data["latitude"] as? Double ?? 0.0
                    let existingLng = data["longitude"] as? Double ?? 0.0
                    
                    
                    if self.isSamePlace(place.name, existingName) &&
                       self.isLocationSimilar(place.latitude, place.longitude, existingLat, existingLng) {
                        completion(true, doc.documentID)
                        return
                    }
                }
                
                completion(false, nil)
            }
    }
    
    private func isSamePlace(_ name1: String, _ name2: String) -> Bool {
        let cleanName1 = name1.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        let cleanName2 = name2.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        
        // Check for exact match
        if cleanName1 == cleanName2 {
            return true
        }
        
        // Check for similarity (one name contains the other)
        if cleanName1.contains(cleanName2) || cleanName2.contains(cleanName1) {
            return true
        }
        
        // Check for similar words (at least 70% similarity)
        let similarity = calculateStringSimilarity(cleanName1, cleanName2)
        return similarity > 0.7
    }
    
    private func isLocationSimilar(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Bool {
        // Check if locations are within ~50 meters of each other
        let latDiff = abs(lat1 - lat2)
        let lngDiff = abs(lng1 - lng2)
        return latDiff < 0.0005 && lngDiff < 0.0005
    }
    
    private func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
        let set1 = Set(str1.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)))
        let set2 = Set(str2.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)))
        
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
    
    // Reviews
    func addReview(_ review: ReviewData, completion: @escaping (Bool) -> Void) {
        let reviewRef = db.collection("reviews").document()
        
        let reviewData: [String: Any] = [
            "placeId": review.placeId,
            "userId": review.userId,
            "userName": review.userName,
            "userImageURL": review.userImageURL,
            "rating": review.rating,
            "comment": review.comment,
            "quietnessRating": review.quietnessRating,
            "wifiStabilityRating": review.wifiStabilityRating,
            "foodTasteRating": review.foodTasteRating,
            "powerOutletStatus": review.powerOutletStatus,
            "createdAt": Timestamp(date: Date())
        ]
        
        reviewRef.setData(reviewData) { error in
            if let error = error {
                print("Error adding review: \(error)")
                completion(false)
            } else {
                completion(true)
                
                self.updatePlaceRating(placeId: review.placeId)
            }
        }
    }
    
    func fetchReviews(for placeId: String, completion: @escaping ([ReviewData]) -> Void) {
        db.collection("reviews")
            .whereField("placeId", isEqualTo: placeId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error)")
                    completion([])
                    return
                }
                
                let reviews = snapshot?.documents.compactMap { doc -> ReviewData? in
                    let data = doc.data()
                    let timestamp = data["createdAt"] as? Timestamp
                    
                    return ReviewData(
                        id: doc.documentID,
                        placeId: data["placeId"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "",
                        userImageURL: data["userImageURL"] as? String ?? "",
                        rating: data["rating"] as? Double ?? 0.0,
                        comment: data["comment"] as? String ?? "",
                        quietnessRating: data["quietnessRating"] as? Double ?? 0.0,
                        wifiStabilityRating: data["wifiStabilityRating"] as? Double ?? 0.0,
                        foodTasteRating: data["foodTasteRating"] as? Double ?? 0.0,
                        powerOutletStatus: data["powerOutletStatus"] as? String ?? "",
                        createdAt: timestamp?.dateValue() ?? Date()
                    )
                } ?? []
                
                completion(reviews)
            }
    }
    
    func deleteReview(reviewId: String, placeId: String, completion: @escaping (Bool) -> Void) {
        db.collection("reviews").document(reviewId).delete { error in
            if let error = error {
                print("Error deleting review: \(error)")
                completion(false)
            } else {
                completion(true)
              
                self.updatePlaceRating(placeId: placeId)
            }
        }
    }
    
    //Favorites
    func addFavorite(placeId: String, userId: String) {
        let favoriteData: [String: Any] = [
            "placeId": placeId,
            "userId": userId,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("favorites").addDocument(data: favoriteData)
    }
    
    func removeFavorite(placeId: String, userId: String) {
        db.collection("favorites")
            .whereField("placeId", isEqualTo: placeId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                snapshot?.documents.forEach { doc in
                    doc.reference.delete()
                }
            }
    }
    
    func syncFavorites(for userId: String) {
        db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    let data = doc.data()
                    if let placeId = data["placeId"] as? String {
                        // Add to Core Data if not exists
                        if !CoreDataManager.shared.isFavorite(placeId: placeId, userId: userId) {
                            CoreDataManager.shared.addFavorite(placeId: placeId, userId: userId)
                        }
                    }
                }
            }
    }
    
    private func updatePlaceRating(placeId: String) {
        fetchReviews(for: placeId) { reviews in
            guard !reviews.isEmpty else { return }
            
            // Calculate average ratings for each category
            let averageQuietness = reviews.reduce(0.0) { $0 + $1.quietnessRating } / Double(reviews.count)
            let averageWiFi = reviews.reduce(0.0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
            let averageFood = reviews.reduce(0.0) { $0 + $1.foodTasteRating } / Double(reviews.count)
            
            // Calculate overall rating as average of the three categories
            let overallRating = (averageQuietness + averageWiFi + averageFood) / 3.0
            
            self.db.collection("places").document(placeId).updateData([
                "rating": overallRating,
                "reviewCount": reviews.count,
                "averageQuietness": averageQuietness,
                "averageWiFi": averageWiFi,
                "averageFood": averageFood
            ])
        }
    }
}

// Review Data Model
struct ReviewData {
    let id: String
    let placeId: String
    let userId: String
    let userName: String
    let userImageURL: String
    let rating: Double
    let comment: String
    let quietnessRating: Double
    let wifiStabilityRating: Double
    let foodTasteRating: Double
    let powerOutletStatus: String
    let createdAt: Date
}

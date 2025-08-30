//
//  FirebaseManager.swift
//  quietdelight
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
    
    // Places
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
                    return PlaceData(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        address: data["address"] as? String ?? "",
                        latitude: data["latitude"] as? Double ?? 0.0,
                        longitude: data["longitude"] as? Double ?? 0.0,
                        rating: data["rating"] as? Double ?? 0.0,
                        imageURL: data["imageURL"] as? String ?? "",
                        isWorkFriendly: data["isWorkFriendly"] as? Bool ?? false,
                        hasWiFi: data["hasWiFi"] as? Bool ?? false,
                        hasPowerOutlets: data["hasPowerOutlets"] as? Bool ?? false,
                        isQuietZone: data["isQuietZone"] as? Bool ?? false
                    )
                } ?? []
                
                completion(places)
            }
    }
    
    //Reviews
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
                // Update place rating
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
    
    // Favorites
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
            let averageRating = reviews.reduce(0.0) { $0 + $1.rating } / Double(reviews.count)
            
            self.db.collection("places").document(placeId).updateData([
                "rating": averageRating,
                "reviewCount": reviews.count
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

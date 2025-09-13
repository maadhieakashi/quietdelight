//
//  PlaceDetailView.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-30.
//


import SwiftUI
import FirebaseAuth

struct PlaceDetailView: View {
    let place: PlaceData
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var reviews: [ReviewData] = []
    @State private var isFavorite = false
    @State private var showWriteReview = false
    @State private var showAllReviews = false
    
    // Computed properties for average ratings
    var averageQuietnessRating: Double {
        guard !reviews.isEmpty else { return 0.0 }
        return reviews.reduce(0) { $0 + $1.quietnessRating } / Double(reviews.count)
    }
    
    var averageWiFiRating: Double {
        guard !reviews.isEmpty else { return 0.0 }
        return reviews.reduce(0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
    }
    
    var averageFoodRating: Double {
        guard !reviews.isEmpty else { return 0.0 }
        return reviews.reduce(0) { $0 + $1.foodTasteRating } / Double(reviews.count)
    }
    
    // Computed property for overall rating based on all user reviews
    var overallRating: Double {
        guard !reviews.isEmpty else { return 0.0 }
        return (averageQuietnessRating + averageWiFiRating + averageFoodRating) / 3.0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
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
                                .font(.system(size: 40))
                        )
                }
                .frame(height: 250)
                .clipped()
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: toggleFavorite) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .font(.system(size: 24))
                                    .padding(10)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 15)
                        Spacer()
                    }
                )
                
                // Status Bar
                HStack {
                    Circle()
                        .fill(place.isWorkFriendly ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(place.isWorkFriendly ? "Work Friendly" : "Not Work Friendly")
                        .font(.caption)
                        .foregroundColor(place.isWorkFriendly ? .green : .red)
                    
                    Spacer()
                    
                    Text(place.venueType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(place.venueType.color)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black)
                .foregroundColor(.white)
                
                // About Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("About")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(place.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 8) {
                        if place.hasWiFi {
                                FeatureRow(icon: "wifi", title: "High-speed WIFI", description: "Available")
                        }
                        
                        if place.hasPowerOutlets {
                                FeatureRow(icon: "bolt.fill", title: "Power outlets", description: "Available")
                        }
                        
                        if place.isQuietZone {
                                FeatureRow(icon: "speaker.slash.fill", title: "Quiet work zone", description: "Available")
                        }
                        
                        if place.isWorkFriendly {
                                FeatureRow(icon: "laptopcomputer", title: "Work-friendly environment", description: "Suitable for remote work")
                        }
                    }
                    
                    // Ratings Section
                    if reviews.isEmpty {
                        VStack(spacing: 15) {
                            Text("No ratings yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text("Be the first to review this place!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 15) {
                            Text("Average Ratings")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 0) {
                                VStack(spacing: 8) {
                                    Text(String(format: "%.1f", averageQuietnessRating))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("Quietness")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: 8) {
                                    Text(String(format: "%.1f", averageWiFiRating))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("WIFI Stability")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: 8) {
                                    Text(String(format: "%.1f", averageFoodRating))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("Food Taste")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 15)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Total Rating Card
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Rating")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                Text(String(format: "%.1f", reviews.isEmpty ? 0.0 : overallRating))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Based on \(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if !reviews.isEmpty {
                                    Text("Calculated from user ratings")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.brown)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Reviews Section
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center) {
                        Text("Reviews")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("Write Review") {
                            showWriteReview = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.brown)
                        .foregroundColor(.white)
                        .cornerRadius(22)
                    }
                    
                    // Recent Reviews
                    if reviews.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("No reviews yet")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                
                                Text("Be the first to share your experience at \(place.name)!")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(Array(reviews.prefix(3)), id: \.id) { review in
                                ReviewRowView(review: review) { reviewToDelete in
                                    deleteReview(reviewToDelete)
                                }
                            }
                            
                            if reviews.count > 3 {
                                Button("View All \(reviews.count) Reviews") {
                                    showAllReviews = true
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.brown)
                                .padding(.top, 8)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton())
        .onAppear {
            loadReviews()
            checkFavoriteStatus()
        }
        .sheet(isPresented: $showWriteReview) {
            WriteReviewView(place: place) { newReview in
                reviews.insert(newReview, at: 0)
            }
        }
        .sheet(isPresented: $showAllReviews) {
            PlaceReviewsView(place: place, reviews: reviews)
        }
    }
    
    private func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if isFavorite {
            coreDataManager.removeFavorite(placeId: place.id, userId: userId)
        } else {
            coreDataManager.addFavorite(placeId: place.id, userId: userId)
        }
        isFavorite.toggle()
    }
    
    private func checkFavoriteStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isFavorite = coreDataManager.isFavorite(placeId: place.id, userId: userId)
    }
    
    private func loadReviews() {
        firebaseManager.fetchReviews(for: place.id) { fetchedReviews in
            DispatchQueue.main.async {
                self.reviews = fetchedReviews
            }
        }
    }
    
    private func deleteReview(_ review: ReviewData) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              review.userId == currentUserId else {
            return // Only allow users to delete their own reviews
        }
        
        firebaseManager.deleteReview(reviewId: review.id, placeId: place.id) { success in
            DispatchQueue.main.async {
                if success {
                    self.reviews.removeAll { $0.id == review.id }
                }
            }
        }
    }
}

struct ReviewRowView: View {
    let review: ReviewData
    let onDelete: (ReviewData) -> Void
    @State private var showDeleteAlert = false
    
    private var isCurrentUserReview: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return review.userId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AsyncImage(url: URL(string: review.userImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.headline)
                    
                    HStack {
                        StarsView(rating: review.rating)
                        Text(String(format: "%.1f", review.rating))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text(timeAgoString(from: review.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUserReview {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            
            Text(review.comment)
                .font(.body)
            
            // Feature tags
            HStack {
                if !review.powerOutletStatus.isEmpty {
                    FeatureTag(text: review.powerOutletStatus)
                }
            }
            
            Divider()
        }
        .padding(.vertical, 5)
        .alert("Delete Review", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(review)
            }
        } message: {
            Text("Are you sure you want to delete this review? This action cannot be undone.")
        }
    }
}

struct FeatureTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
    }
}

struct StarsView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: Double(index) < rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
                .font(.title2)
        }
    }
}

#Preview {
    PlaceDetailView(place: PlaceData(
        id: "1",
        name: "A Table",
        address: "42 B, High level Road, Bambalapitiya",
        latitude: 6.914244,
        longitude: 79.861244,
        rating: 4.1,
        imageURL: "",
        description: "Cozy cafe offering quality coffee and light meals in a comfortable setting. Perfect for work, study, or casual meetings with friends.",
        isWorkFriendly: true,
        hasWiFi: true,
        hasPowerOutlets: true,
        isQuietZone: true
    ))
}

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
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                // Header Image with Modern Design
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: place.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 40, weight: .light))
                            )
                    }
                    .frame(height: 280)
                    .clipped()
                    
                    // Favorite Button with Modern Styling
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                
                // Modern Status Indicator
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Work Friendly Status
                        HStack(spacing: 8) {
                            Circle()
                                .fill(place.isWorkFriendly ? .green : .red)
                                .frame(width: 10, height: 10)
                            
                            Text(place.isWorkFriendly ? "Work Friendly" : "Not Work Friendly")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(place.isWorkFriendly ? .green : .red)
                        }
                        
                        Spacer()
                        
                        // Venue Type Badge
                        Text(place.venueType.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(place.venueType.color)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    )
                }
                
                // Main Content Container
                VStack(alignment: .leading, spacing: 32) {
                    // Place Title and Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text(place.name)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                        
                        Text(place.address)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 24)
                    
                    // About Section with Modern Typography
                    VStack(alignment: .leading, spacing: 20) {
                        Text("About")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                        
                        Text(place.description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                        
                        // Modern Features Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            if place.hasWiFi {
                                ModernFeatureCard(
                                    icon: "wifi",
                                    title: "High-speed WiFi",
                                    description: "Available",
                                    color: .blue
                                )
                            }
                            
                            if place.hasPowerOutlets {
                                ModernFeatureCard(
                                    icon: "bolt.fill",
                                    title: "Power Outlets",
                                    description: "Available",
                                    color: .orange
                                )
                            }
                            
                            if place.isQuietZone {
                                ModernFeatureCard(
                                    icon: "speaker.slash.fill",
                                    title: "Quiet Zone",
                                    description: "Available",
                                    color: .purple
                                )
                            }
                            
                            if place.isWorkFriendly {
                                ModernFeatureCard(
                                    icon: "laptopcomputer",
                                    title: "Work Friendly",
                                    description: "Remote work suitable",
                                    color: .green
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Modern Ratings Section
                    VStack(alignment: .leading, spacing: 24) {
                        if reviews.isEmpty {
                            VStack(spacing: 20) {
                                Text("No ratings yet")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                Text("Be the first to review this place!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Average Ratings")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 0) {
                                    RatingCard(
                                        value: averageQuietnessRating,
                                        title: "Quietness",
                                        color: .purple
                                    )
                                    
                                    RatingCard(
                                        value: averageWiFiRating,
                                        title: "WiFi Stability",
                                        color: .blue
                                    )
                                    
                                    RatingCard(
                                        value: averageFoodRating,
                                        title: "Food Taste",
                                        color: .orange
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Modern Total Rating Card
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Overall Rating")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 24, weight: .medium))
                                    
                                    Text(String(format: "%.1f", reviews.isEmpty ? 0.0 : overallRating))
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Based on \(reviews.count) review\(reviews.count == 1 ? "" : "s")")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    if !reviews.isEmpty {
                                        Text("Calculated from user ratings")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "5A3529"), Color(hex: "5A3529").opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                        )
                    }
                    .padding(.horizontal, 24)
                
                    //  Reviews
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(alignment: .center) {
                            Text("Reviews")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("Write Review") {
                                showWriteReview = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "5A3529"))
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                            .foregroundColor(.white)
                        }
                  
                        // Reviews
                        if reviews.isEmpty {
                            VStack(spacing: 24) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                VStack(spacing: 12) {
                                    Text("No reviews yet")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Be the first to share your experience at \(place.name)!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .padding(.horizontal, 16)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(Array(reviews.prefix(3)), id: \.id) { review in
                                    ModernReviewCard(review: review) { reviewToDelete in
                                        deleteReview(reviewToDelete)
                                    }
                                }
                                
                                if reviews.count > 3 {
                                    Button("View All \(reviews.count) Reviews") {
                                        showAllReviews = true
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.brown)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ModernBackButton()
            }
        }
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

// MARK: - Modern Components

struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 24, height: 24)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct RatingCard: View {
    let value: Double
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernReviewCard: View {
    let review: ReviewData
    let onDelete: (ReviewData) -> Void
    @State private var showDeleteAlert = false
    
    private var isCurrentUserReview: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return review.userId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: review.userImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16, weight: .medium))
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        ModernStarsView(rating: review.rating)
                        Text(String(format: "%.1f", review.rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(timeAgoString(from: review.createdAt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    if isCurrentUserReview {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                }
            }
            
            Text(review.comment)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(2)
            
            // Feature tags
            if !review.powerOutletStatus.isEmpty {
                HStack {
                    ModernFeatureTag(text: review.powerOutletStatus)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
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

struct ModernFeatureTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.blue)
    }
}

struct ModernStarsView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: Double(index) < rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.system(size: 12, weight: .medium))
            }
        }
    }
}

struct ModernBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Legacy Components (for compatibility)

struct ReviewRowView: View {
    let review: ReviewData
    let onDelete: (ReviewData) -> Void
    @State private var showDeleteAlert = false
    
    private var isCurrentUserReview: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return review.userId == currentUserId
    }
    
    var body: some View {
        // Use the modern card instead
        ModernReviewCard(review: review, onDelete: onDelete)
    }
}

struct FeatureTag: View {
    let text: String
    
    var body: some View {
        // Use the modern version
        ModernFeatureTag(text: text)
    }
}

struct StarsView: View {
    let rating: Double
    
    var body: some View {
        // Use the modern version
        ModernStarsView(rating: rating)
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        // Use the modern version
        ModernBackButton()
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

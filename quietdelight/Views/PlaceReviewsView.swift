//
//  PlaceReviewsView.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-30.
//

import SwiftUI
import FirebaseAuth

struct PlaceReviewsView: View {
    let place: PlaceData
    @State var reviews: [ReviewData]
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFilter = "All"
    @State private var showWriteReview = false
    @State private var helpfulCounts: [String: Int] = [:]
    @State private var userHelpfulMarks: Set<String> = []
    
    let filterOptions = ["All", "Positive", "Neutral", "negative"]
    
    var filteredReviews: [ReviewData] {
        switch selectedFilter {
        case "Positive":
            return reviews.filter { $0.rating >= 4.0 }
        case "Neutral":
            return reviews.filter { $0.rating >= 2.5 && $0.rating < 4.0 }
        case "negative":
            return reviews.filter { $0.rating < 2.5 }
        default:
            return reviews
        }
    }
    
    var averageRatings: (quietness: Double, wifi: Double, food: Double) {
        guard !reviews.isEmpty else { return (0, 0, 0) }
        
        let quietness = reviews.reduce(0) { $0 + $1.quietnessRating } / Double(reviews.count)
        let wifi = reviews.reduce(0) { $0 + $1.wifiStabilityRating } / Double(reviews.count)
        let food = reviews.reduce(0) { $0 + $1.foodTasteRating } / Double(reviews.count)
        
        return (quietness, wifi, food)
    }
    
    var powerOutletSummary: String {
        let abundantCount = reviews.filter { $0.powerOutletStatus == "Abundant" }.count
        let limitedCount = reviews.filter { $0.powerOutletStatus == "Limited" }.count
        let notAvailableCount = reviews.filter { $0.powerOutletStatus == "Not Available" }.count
        
        if abundantCount > limitedCount && abundantCount > notAvailableCount {
            return "Abundant"
        } else if limitedCount > notAvailableCount {
            return "Limited"
        } else {
            return "Not Available"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Place Header
                    HStack {
                        AsyncImage(url: URL(string: place.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                        
                        VStack(alignment: .leading) {
                            Text(place.name)
                                .font(.headline)
                            
                            HStack {
                                StarsView(rating: place.rating)
                                Text(String(format: "%.1f", place.rating))
                                    .font(.caption)
                                Text("Reviews \(reviews.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Filter Options
                    HStack {
                        ForEach(filterOptions, id: \.self) { option in
                            Button(action: {
                                selectedFilter = option
                            }) {
                                Text(option)
                                    .font(.subheadline)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == option ? Color.black : Color.clear)
                                    .foregroundColor(selectedFilter == option ? .white : .black)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: selectedFilter == option ? 0 : 1)
                                    )
                            }
                        }
                        Spacer()
                    }
                    
                    // Summary Card
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "speaker.slash")
                                .foregroundColor(.gray)
                            Text("Quietness")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.1f", averageRatings.quietness))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Image(systemName: "wifi")
                                .foregroundColor(.gray)
                            Text("WIFI Stability")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.1f", averageRatings.wifi))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Image(systemName: "fork.knife")
                                .foregroundColor(.gray)
                            Text("Food Taste")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.1f", averageRatings.food))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Image(systemName: "bolt")
                                .foregroundColor(.gray)
                            Text("Power Outlet")
                                .font(.headline)
                            Spacer()
                            Text(powerOutletSummary)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(powerOutletSummary == "Abundant" ? .green : powerOutletSummary == "Limited" ? .orange : .red)
                        }
                        
                        Text("based on \(reviews.count) reviews")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Reviews Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Reviews")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("write Review") {
                                showWriteReview = true
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        
                        // Reviews List
                        if filteredReviews.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No reviews match your filter")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Try selecting a different filter option")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 20) {
                                ForEach(filteredReviews, id: \ .id) { (review: ReviewData) in
                                    DetailedReviewView(
                                        review: review,
                                        helpfulCount: helpfulCounts[review.id] ?? 0,
                                        isMarkedHelpful: userHelpfulMarks.contains(review.id),
                                        onHelpfulTap: { reviewId in
                                            if userHelpfulMarks.contains(reviewId) {
                                                // Undo - remove mark and decrease count
                                                userHelpfulMarks.remove(reviewId)
                                                helpfulCounts[reviewId, default: 0] = max(0, helpfulCounts[reviewId, default: 0] - 1)
                                            } else {
                                                // Mark as helpful and increase count
                                                userHelpfulMarks.insert(reviewId)
                                                helpfulCounts[reviewId, default: 0] += 1
                                            }
                                        },
                                        onDelete: { reviewToDelete in
                                            deleteReview(reviewToDelete)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Reviews")
            .navigationBarItems(
                leading: Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.brown)
            )
        }
        .sheet(isPresented: $showWriteReview) {
            WriteReviewView(place: place) { newReview in
                reviews.insert(newReview, at: 0)
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

struct DetailedReviewView: View {
    let review: ReviewData
    let helpfulCount: Int
    let isMarkedHelpful: Bool
    let onHelpfulTap: (String) -> Void
    let onDelete: (ReviewData) -> Void
    @State private var isExpanded = false
    @State private var showDeleteAlert = false
    
    private var isCurrentUserReview: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return review.userId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // User Info and Rating
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
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.userName)
                        .font(.headline)
                    
                    HStack {
                        StarsView(rating: review.rating)
                        Text(String(format: "%.1f", review.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
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
    // Helper function for time ago string
    // Move this function outside the ViewBuilder
            
            // Review Text
            Text(review.comment)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
            
            if review.comment.count > 150 {
                Button(isExpanded ? "Show Less" : "Read More") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.brown)
            }
            
            // Feature Tags
            HStack {
                if !review.powerOutletStatus.isEmpty {
                    ReviewFeatureTag(text: review.powerOutletStatus)
                }
                
                // Add work-related tags based on ratings
                if review.wifiStabilityRating >= 4.0 {
                    ReviewFeatureTag(text: "Fast WiFi")
                }
                
                if review.quietnessRating >= 4.0 {
                    ReviewFeatureTag(text: "Quiet Zone")
                }
            }
            
            // Work Feature Ratings
            VStack(alignment: .leading, spacing: 8) {
                Text("Work Feature Rating")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "speaker.slash")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Quietness")
                            .font(.caption)
                        Spacer()
                        StarsView(rating: review.quietnessRating)
                        Text(String(format: "%.1f", review.quietnessRating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("WIFI Stability")
                            .font(.caption)
                        Spacer()
                        StarsView(rating: review.wifiStabilityRating)
                        Text(String(format: "%.1f", review.wifiStabilityRating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Food Taste")
                            .font(.caption)
                        Spacer()
                        StarsView(rating: review.foodTasteRating)
                        Text(String(format: "%.1f", review.foodTasteRating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "bolt")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Power Outlet")
                            .font(.caption)
                        Spacer()
                        Text(review.powerOutletStatus)
                            .font(.caption)
                            .foregroundColor(review.powerOutletStatus == "Abundant" ? .green : review.powerOutletStatus == "Limited" ? .orange : .red)
                    }
                }
            }
            
            // Helpful Button
            HStack {
                Button(action: {
                    onHelpfulTap(review.id)
                }) {
                    HStack {
                        Image(systemName: isMarkedHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text("Helpful (\(helpfulCount))")
                    }
                    .font(.caption)
                    .foregroundColor(isMarkedHelpful ? .brown : .secondary)
                }
                
                Spacer()
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
    // No explicit return statement needed in SwiftUI ViewBuilder
    }
}

struct ReviewFeatureTag: View {
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



//
//  PlaceDetailView.swift
//  quietdelight
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
                    if place.hasWiFi {
                        Text("Closed 7:00 AM")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Open Now")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button("Recipes") {
                        // Show recipes
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.brown)
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
                    
                    Text("Cafe chain featuring globally inspired wrap & salad, low calories options and smoothies.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 8) {
                        if place.hasWiFi {
                                FeatureRow(icon: "wifi", title: "High-speed WIFI", description: "50+ Mbps")
                        }
                        
                        if place.hasPowerOutlets {
                                FeatureRow(icon: "bolt.fill", title: "Power outlets", description: "at every table")
                        }
                        
                        if place.isQuietZone {
                                FeatureRow(icon: "speaker.slash.fill", title: "Designated quiet work areas", description: "")
                        }
                    }
                    
                    // Ratings Section
                    HStack(spacing: 30) {
                        VStack {
                            Text("3.0")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Quietness")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("4.7")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("WIFI Stability")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("4.5")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Food Taste")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Total Rating Card
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Rating")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", place.rating))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.brown)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
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
                    
                    // Recent Reviews
                    ForEach(Array(reviews.prefix(3)), id: \.id) { review in
                        ReviewRowView(review: review)
                    }
                    
                    if reviews.count > 3 {
                        Button("View All Reviews") {
                            showAllReviews = true
                        }
                        .foregroundColor(.brown)
                        .padding(.top, 10)
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
}

// Correct FeatureRow implementation
// ...existing code...

struct ReviewRowView: View {
    let review: ReviewData
    
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
                
                Text(timeAgoString(from: review.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// ...existing code...

#Preview {
    PlaceDetailView(place: PlaceData(
        id: "1",
        name: "A Table",
        address: "42 B, High level Road, Bambalapitiya",
        latitude: 6.914244,
        longitude: 79.861244,
        rating: 4.1,
        imageURL: "",
        isWorkFriendly: true,
        hasWiFi: true,
        hasPowerOutlets: true,
        isQuietZone: true
    ))
}

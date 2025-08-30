//
//  WriteReviewView.swift
//  quietdelight
//
//  Created by SAHimeshi 002 on 2025-08-30.
//

import SwiftUI
import FirebaseAuth

struct WriteReviewView: View {
    let place: PlaceData
    let onReviewAdded: (ReviewData) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    @State private var reviewText = ""
    @State private var quietnessRating: Double = 3
    @State private var wifiStabilityRating: Double = 3
    @State private var foodTasteRating: Double = 3
    @State private var powerOutletStatus = "Abundant"
    @State private var selectedFeatures: Set<String> = []
    @State private var isSubmitting = false
    
    let powerOutletOptions = ["Abundant", "Limited", "Not Available"]
    let featureOptions = ["Fast WiFi", "Power Outlet", "Quiet Zone"]
    
    var overallRating: Double {
        (quietnessRating + wifiStabilityRating + foodTasteRating) / 3.0
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
                                Text("Reviews 8")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    // Share Your Experience
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Share Your Experience")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $reviewText)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .overlay(
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("\(reviewText.count)/200 characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                            )
                    }
                    
                    // Rate Key Features
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Rate key Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("What made this place good for working?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Feature Tags
                        HStack {
                            ForEach(featureOptions, id: \.self) { feature in
                                Button(action: {
                                    if selectedFeatures.contains(feature) {
                                        selectedFeatures.remove(feature)
                                    } else {
                                        selectedFeatures.insert(feature)
                                    }
                                }) {
                                    Text(feature)
                                        .font(.caption)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(selectedFeatures.contains(feature) ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedFeatures.contains(feature) ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        
                        // Quietness Level
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "speaker.slash")
                                    .foregroundColor(.gray)
                                Text("Quietness Level")
                                    .font(.headline)
                            }
                            
                            HStack {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: {
                                        quietnessRating = Double(index)
                                    }) {
                                        Image(systemName: Double(index) <= quietnessRating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.title2)
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        // WiFi Stability
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "wifi")
                                    .foregroundColor(.gray)
                                Text("WIFI Stability")
                                    .font(.headline)
                            }
                            
                            HStack {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: {
                                        wifiStabilityRating = Double(index)
                                    }) {
                                        Image(systemName: Double(index) <= wifiStabilityRating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.title2)
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        // Food Taste
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.gray)
                                Text("Food Taste")
                                    .font(.headline)
                            }
                            
                            HStack {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: {
                                        foodTasteRating = Double(index)
                                    }) {
                                        Image(systemName: Double(index) <= foodTasteRating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.title2)
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        // Power Outlet
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bolt")
                                    .foregroundColor(.gray)
                                Text("Power Outlet")
                                    .font(.headline)
                            }
                            
                            HStack {
                                ForEach(powerOutletOptions, id: \.self) { option in
                                    Button(action: {
                                        powerOutletStatus = option
                                    }) {
                                        HStack {
                                            if option == "Abundant" {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.green)
                                            } else if option == "Limited" {
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundColor(.orange)
                                            } else {
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 10)
                                        .background(powerOutletStatus == option ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(powerOutletStatus == option ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            HStack {
                                Text("Abundant")
                                    .font(.caption)
                                Spacer()
                                Text("Limited")
                                    .font(.caption)
                                Spacer()
                                Text("Not Available")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Write Reviews")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Post") {
                    submitReview()
                }
                .disabled(reviewText.isEmpty || isSubmitting)
            )
        }
    }
    
    private func submitReview() {
        guard let user = Auth.auth().currentUser else { return }
        
        isSubmitting = true
        
        let review = ReviewData(
            id: UUID().uuidString,
            placeId: place.id,
            userId: user.uid,
            userName: user.displayName ?? "Anonymous",
            userImageURL: user.photoURL?.absoluteString ?? "",
            rating: overallRating,
            comment: reviewText,
            quietnessRating: quietnessRating,
            wifiStabilityRating: wifiStabilityRating,
            foodTasteRating: foodTasteRating,
            powerOutletStatus: powerOutletStatus,
            createdAt: Date()
        )
        
        firebaseManager.addReview(review) { success in
            DispatchQueue.main.async {
                self.isSubmitting = false
                if success {
                    self.onReviewAdded(review)
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    WriteReviewView(
        place: PlaceData(
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
        ),
        onReviewAdded: { _ in }
    )
}

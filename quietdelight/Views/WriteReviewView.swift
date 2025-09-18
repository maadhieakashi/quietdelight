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
    
    var buttonBackgroundColor: AnyShapeStyle {
        if reviewText.isEmpty || isSubmitting {
            return AnyShapeStyle(Color.gray)
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Place Header with enhanced styling
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                AsyncImage(url: URL(string: place.imageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                        
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                            .font(.title2)
                                    }
                                }
                                .frame(width: 70, height: 70)
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(place.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        StarsView(rating: place.rating)
                                        Text(String(format: "%.1f", place.rating))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("• 8 Reviews")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(place.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        
                        // Share Your Experience Section with enhanced styling
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "quote.bubble.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                Text("Share Your Experience")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            Text("Help others discover this place by sharing your honest review")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemGray6))
                                    .frame(minHeight: 120)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(
                                                reviewText.isEmpty ? Color.clear : Color.blue.opacity(0.3),
                                                lineWidth: 2
                                            )
                                    )
                                
                                if reviewText.isEmpty {
                                    VStack {
                                        HStack {
                                            Text("What made this place special? Share details about the atmosphere, service, food, and work environment...")
                                                .foregroundColor(.secondary)
                                                .font(.body)
                                                .padding(.top, 12)
                                                .padding(.leading, 15)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                                
                                TextEditor(text: $reviewText)
                                    .background(Color.clear)
                                    .padding(12)
                                
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        HStack(spacing: 5) {
                                            Image(systemName: "character.cursor.ibeam")
                                                .font(.caption2)
                                            Text("\(reviewText.count)/200")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(reviewText.count > 180 ? .orange : .secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemBackground).opacity(0.8))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(12)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        
                        // Rate Key Features Section with enhanced styling
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                Text("Rate Key Features")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            Text("What made this place good for working?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Feature Tags with enhanced styling
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Highlights")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                                    spacing: 10
                                ) {
                                    ForEach(featureOptions, id: \.self) { feature in
                                        Button(action: {
                                            if selectedFeatures.contains(feature) {
                                                selectedFeatures.remove(feature)
                                            } else {
                                                selectedFeatures.insert(feature)
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: getFeatureIcon(feature))
                                                    .foregroundColor(selectedFeatures.contains(feature) ? .white : .blue)
                                                Text(feature)
                                                    .fontWeight(.medium)
                                                Spacer()
                                                if selectedFeatures.contains(feature) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(
                                                        selectedFeatures.contains(feature) ?
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        ) :
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                            )
                                            .foregroundColor(selectedFeatures.contains(feature) ? .white : .primary)
                                            .scaleEffect(selectedFeatures.contains(feature) ? 1.02 : 1.0)
                                            .animation(
                                                .spring(response: 0.3, dampingFraction: 0.6),
                                                value: selectedFeatures.contains(feature)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Rating sections with enhanced styling
                            VStack(spacing: 20) {
                                // Quietness Level
                                RatingSection(
                                    icon: "speaker.slash.fill",
                                    title: "Quietness Level",
                                    subtitle: "How peaceful was the environment?",
                                    rating: $quietnessRating,
                                    color: .purple
                                )
                                
                                // WiFi Stability
                                RatingSection(
                                    icon: "wifi",
                                    title: "WiFi Stability",
                                    subtitle: "How reliable was the internet connection?",
                                    rating: $wifiStabilityRating,
                                    color: .blue
                                )
                                
                                // Food Taste
                                RatingSection(
                                    icon: "fork.knife",
                                    title: "Food & Beverages",
                                    subtitle: "How was the quality and taste?",
                                    rating: $foodTasteRating,
                                    color: .orange
                                )
                            }
                            
                            // Power Outlet with enhanced styling
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "bolt.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                    Text("Power Outlets")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                Text("How available were the power outlets?")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(spacing: 12) {
                                    ForEach(powerOutletOptions, id: \.self) { option in
                                        Button(action: {
                                            powerOutletStatus = option
                                        }) {
                                            HStack(spacing: 15) {
                                                ZStack {
                                                    Circle()
                                                        .fill(getOutletColor(option).opacity(0.2))
                                                        .frame(width: 40, height: 40)
                                                    
                                                    Image(systemName: getOutletIcon(option))
                                                        .foregroundColor(getOutletColor(option))
                                                        .font(.system(size: 18, weight: .semibold))
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(option)
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                    Text(getOutletDescription(option))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                if powerOutletStatus == option {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.title2)
                                                }
                                            }
                                            .padding(15)
                                            .background(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .fill(
                                                        powerOutletStatus == option ?
                                                        getOutletColor(option).opacity(0.1) :
                                                        Color(.systemGray6)
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .stroke(
                                                                powerOutletStatus == option ?
                                                                getOutletColor(option) :
                                                                Color.clear,
                                                                lineWidth: 2
                                                            )
                                                    )
                                            )
                                            .scaleEffect(powerOutletStatus == option ? 1.02 : 1.0)
                                            .animation(
                                                .spring(response: 0.3, dampingFraction: 0.6),
                                                value: powerOutletStatus == option
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        
                        // Overall Rating Display
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                Text("Overall Rating")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(String(format: "%.1f", overallRating))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                            }
                            
                            HStack {
                                StarsView(rating: overallRating)
                                Spacer()
                                Text("Based on your ratings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.yellow.opacity(0.1),
                                            Color.orange.opacity(0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel")
                    }
                    .foregroundColor(.secondary)
                },
                trailing: Button(action: {
                    submitReview()
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(isSubmitting ? "Posting..." : "Post")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(buttonBackgroundColor)
                    )
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
    
    // Helper functions for UI
    private func getFeatureIcon(_ feature: String) -> String {
        switch feature {
        case "Fast WiFi": return "wifi"
        case "Power Outlet": return "bolt.fill"
        case "Quiet Zone": return "speaker.slash.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private func getOutletIcon(_ option: String) -> String {
        switch option {
        case "Abundant": return "checkmark.circle.fill"
        case "Limited": return "exclamationmark.triangle.fill"
        case "Not Available": return "xmark.circle.fill"
        default: return "circle"
        }
    }
    
    private func getOutletColor(_ option: String) -> Color {
        switch option {
        case "Abundant": return .green
        case "Limited": return .orange
        case "Not Available": return .red
        default: return .gray
        }
    }
    
    private func getOutletDescription(_ option: String) -> String {
        switch option {
        case "Abundant": return "Plenty of outlets available"
        case "Limited": return "Few outlets, may need to wait"
        case "Not Available": return "No outlets found"
        default: return ""
        }
    }
}

// Custom Rating Section Component
struct RatingSection: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var rating: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                rating = Double(index)
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        Double(index) <= rating ?
                                        color.opacity(0.12) :
                                        Color(.systemGray6)
                                    )
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: Double(index) <= rating ? "star.fill" : "star")
                                    .foregroundColor(Double(index) <= rating ? color : .gray)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .scaleEffect(Double(index) <= rating ? 1.03 : 1.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6),
                            value: rating
                        )
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Text(String(format: "%.1f", rating))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(color)
                            .font(.system(size: 10, weight: .medium))
                    }
                    Text("out of 5")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
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

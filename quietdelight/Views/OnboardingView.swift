//  OnboardingView.swift
//  cafedelight
//
//  Created by SAHimeshi 002 on 2025-08-20.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @State private var currentPage = 0
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // BG
                Color.white
                    .ignoresSafeArea()
                
                decorativeBackground
                
                TabView(selection: $currentPage) {
                    // pro pic
                    ProfilePictureScreen(
                        showImagePicker: $showImagePicker,
                        profileImage: $profileImage,
                        onNext: { currentPage = 1 }
                    )
                    .tag(0)
                    
                    //Location Acess
                    LocationAccessScreen(
                        onNext: { currentPage = 2 }
                    )
                    .tag(1)
                    
                    //feature discover
                    FeatureDiscoveryScreen(
                        onGetStarted: {
                            completeOnboarding()
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
               
                VStack {
                    Spacer()
                    pageIndicator
                        .padding(.bottom, 100)
                }
                
                // Skip button
                VStack {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            print("Onboarding skipped")
                            completeOnboarding()
                        }
                        .foregroundColor(.black)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            
            .navigationDestination(isPresented: $navigateToHome) {
                TabBarView()
                    .navigationBarBackButtonHidden(true)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $profileImage)
        }
    }
    
    private var decorativeBackground: some View {
        ZStack {
            // Top decorative
            Circle()
                .fill(Color(hex: "5A3529").opacity(0.5))
                .frame(width: 120, height: 120)
                .offset(x: 150, y: -350)
            
            Circle()
                .fill(Color(hex: "5A3529").opacity(0.3))
                .frame(width: 80, height: 80)
                .offset(x: 180, y: -250)
            
            // Bottom dec
            Circle()
                .fill(Color(hex: "5A3529").opacity(0.4))
                .frame(width: 100, height: 100)
                .offset(x: -150, y: 350)
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }
    
    private func completeOnboarding() {
     
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(false, forKey: "isNewUser")
        UserDefaults.standard.synchronize()
        
        // Save profile image
        if let image = profileImage {
            authManager.updateProfileWithImage(image) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("Profile image saved successfully")
                    case .failure(let error):
                        print("Failed to save profile image: \(error.localizedDescription)")
                    }
                    
                    self.navigateToHome = true
                }
            }
        } else {
          
            navigateToHome = true
        }
        }
    }


//Profile Pic Screen
struct ProfilePictureScreen: View {
    @Binding var showImagePicker: Bool
    @Binding var profileImage: UIImage?
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                // Dec circle
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                        .frame(width: 200 + CGFloat(i * 20))
                        .rotationEffect(.degrees(Double(i * 10)))
                }
                
                // ProfilePic circle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 140, height: 140)
                    
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    }
                    
                }
            }
            
            VStack(spacing: 15) {
                Text("Set your profile picture")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Find the perfect workspace cafe near you")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: { showImagePicker = true }) {
                    Text("Upload your Profile Picture")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(8)
                }
                
                Button(action: onNext) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(Color(hex: "5A3529"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "5A3529"), lineWidth: 2)
                        )
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}

//  Location Access Screen
struct LocationAccessScreen: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // location access
            ZStack {
                // Dec Circles
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                        .frame(width: 200 + CGFloat(i * 20))
                        .rotationEffect(.degrees(Double(i * 10)))
                }
                
                // Location
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .overlay(
                        ZStack {
                            Image(systemName: "map.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "382E2C"))
                                .opacity(0.3)
                            
                            Image(systemName: "location.fill")
                                .font(.system(size: 35))
                                .foregroundColor(Color(hex: "382E2C"))
                                .offset(x: 10, y: -5)
                        }
                    )
            }
            
            VStack(spacing: 15) {
                Text("Enable Location Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Find the perfect workspace cafe near you")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Enable Location Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}

// allset view
struct FeatureDiscoveryScreen: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                // dec circle
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.brown.opacity(0.3), lineWidth: 2)
                        .frame(width: 200 + CGFloat(i * 20))
                        .rotationEffect(.degrees(Double(i * 10)))
                }
                
                // Checkmarkicon
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .overlay(
                        ZStack {
                           
                            Circle()
                                .fill(Color.brown)
                                .frame(width: 90, height: 80)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 0, y: 0)
                        }
                    )
            }
            
            VStack(spacing: 15) {
                Text("Discover the perfect cafe for your remote work needs")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Features
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "wifi",
                    title: "Fast WiFi",
                    description: "Find cafes with reliable high-speed internet"
                )
                
                FeatureRow(
                    icon: "speaker.slash.fill",
                    title: "Quiet Atmosphere",
                    description: "Perfect environments for focused work"
                )
                
                FeatureRow(
                    icon: "bolt.fill",
                    title: "Power Outlets",
                    description: "Never worry about your battery dying again"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}

//Feature component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.black)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

//Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


//Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

# QuietDelight

QuietDelight is an iOS application designed to help users discover, review, and save their favorite cafes. The app features user authentication, a map view for exploring cafes, the ability to write and read reviews, and manage user profiles.

## Features
- User authentication (Sign up, Sign in, Password reset)
- Browse and search for cafes
- View cafe details and reviews
- Add cafes to favorites
- Write and read reviews
- Edit user profile and change password
- Push notifications

## Project Structure
```
cafedelight/
  Auth/                # Authentication and firebase coredata management
  views/               # SwiftUI views for the app
  Assets.xcassets/     # App assets (images, colors, icons)
  cafedelightApp.swift # App entry point
  ...
cafedelightTests/      # Unit tests
cafedelightUITests/    # UI tests
CafeModel.xcdatamodeld # Core Data model
```

## Getting Started
1. **Clone the repository:**
   ```sh
   git clone <https://github.com/maadhieakashi/quietdelight.git>
   ```
2. **Open the project in Xcode:**
   - Open `quietdelight.xcodeproj`.
3. **Install dependencies:**
   - Make sure you have Swift Package Manager set up if needed.
4. **Configure Firebase:**
   - Add your `GoogleService-Info.plist` to the `quietdelight` folder.
5. **Run the app:**
   - Select a simulator or device and press Run (⌘R).

## Requirements
- Xcode 16+
- iOS 18.4+
- Swift 5.0+
- Firebase (for authenication and review place details store)

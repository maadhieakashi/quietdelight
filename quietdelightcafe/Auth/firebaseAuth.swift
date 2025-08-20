//
//  firebaseAuth.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication
import Security


enum AuthResult {
    case success(String)
    case failure(String)
}

//UserData Model
struct UserData {
    let username: String
    let email: String
    let enableFaceID: Bool
    let sendUpdates: Bool
}


enum AuthError: LocalizedError {
    case emptyFields
    case emptyEmail
    case invalidEmail
    case weakPassword
    case userNotFound
    case biometricsNotAvailable
    case biometricAuthFailed
    case noSavedCredentials
    
    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please fill in all required fields."
        case .emptyEmail:
            return "Please enter your email address."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .userNotFound:
            return "User not found. Please sign in first."
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricAuthFailed:
            return "Biometric authentication failed."
        case .noSavedCredentials:
            return "No saved credentials found. Please sign in with email and password first."
        }
    }
}

//Firebase Authentiction
class FirebaseAuthManager: ObservableObject {
    
 
    static let shared = FirebaseAuthManager()
    
  
    private let db = Firestore.firestore()
    private let keychainService = "QuietDelightCredentials"
    
    @Published var isLoading = false
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    
    private init() {
        self.currentUser = Auth.auth().currentUser
        self.isAuthenticated = currentUser != nil
        
        // Listen for auth state changes
//        Auth.auth().addStateDidChangeListener { [weak self] _, user in
//            DispatchQueue.main.async {
//                self?.currentUser = user
//                self?.isAuthenticated = user != nil
//            }
//        }
    }
    
    func checkAuthenticationState() {
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // signup
    
    func signUp(
        username: String,
        email: String,
        password: String,
        confirmPassword: String,
        enableFaceID: Bool,
        sendUpdates: Bool,
        agreeToTerms: Bool,
        completion: @escaping (AuthResult) -> Void
    ) {
        // Validate input
        guard let validationResult = validateSignUpInput(
            username: username,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            agreeToTerms: agreeToTerms
        ) else {
            // Validation passed
            performSignUp(
                userData: UserData(
                    username: username,
                    email: email,
                    enableFaceID: enableFaceID,
                    sendUpdates: sendUpdates
                ),
                password: password,
                completion: completion
            )
            return
        }
        
        // Validation failed
        completion(.failure(validationResult))
    }
    
    func signUpWithEmailPassword(email: String, password: String, displayName: String? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        guard !email.isEmpty, !password.isEmpty else {
            completion(.failure(AuthError.emptyFields))
            return
        }
        
        guard isValidEmail(email) else {
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        guard password.count >= 6 else {
            completion(.failure(AuthError.weakPassword))
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(.failure(error))
                } else if let user = result?.user {
                   
                    if let displayName = displayName {
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = displayName
                        changeRequest.commitChanges { _ in }
                    }
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.saveCredentialsToKeychain(email: email, password: password)
                    completion(.success(user))
                }
            }
        }
    }
    
    
    func signIn(email: String, password: String, completion: @escaping (AuthResult) -> Void) {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(.failure(self?.handleAuthError(error) ?? "Sign in failed"))
                    return
                }
                
                guard authResult?.user != nil else {
                    completion(.failure("Failed to sign in. Please try again."))
                    return
                }
                
              
                self?.saveCredentialsToKeychain(email: email, password: password)
                self?.updateLastLoginTime()
                completion(.success("Signed in successfully!"))
            }
        }
    }
    
    func signInWithEmailPassword(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard !email.isEmpty, !password.isEmpty else {
            completion(.failure(AuthError.emptyFields))
            return
        }
        
        guard isValidEmail(email) else {
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(.failure(error))
                } else if let user = result?.user {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.saveCredentialsToKeychain(email: email, password: password)
                    self?.updateLastLoginTime()
                    completion(.success(user))
                }
            }
        }
    }
    
    //signout
    
    func signOut(completion: @escaping (AuthResult) -> Void) {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            // Optionally remove saved credentials
            removeCredentialsFromKeychain()
            completion(.success("Signed out successfully"))
        } catch {
            completion(.failure("Failed to sign out: \(error.localizedDescription)"))
        }
    }
    
    // passwordReset
    
    func resetPassword(email: String, completion: @escaping (AuthResult) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure("Failed to send reset email: \(error.localizedDescription)"))
                } else {
                    completion(.success("Password reset email sent successfully"))
                }
            }
        }
    }
    
    func resetPasswordWithResult(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !email.isEmpty else {
            completion(.failure(AuthError.emptyEmail))
            return
        }
        
        guard isValidEmail(email) else {
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // account
    
    func deleteAccount(completion: @escaping (AuthResult) -> Void) {
        guard let user = currentUser else {
            completion(.failure("No user logged in"))
            return
        }
        
        // Delete user document from Firestore first
        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                completion(.failure("Failed to delete user data: \(error.localizedDescription)"))
                return
            }
            
            
            user.delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure("Failed to delete account: \(error.localizedDescription)"))
                    } else {
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        self?.removeCredentialsFromKeychain()
                        completion(.success("Account deleted successfully"))
                    }
                }
            }
        }
    }
    
    func deleteUserAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        
        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
        
            user.delete { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        self?.removeCredentialsFromKeychain()
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // Biometric
    
    func authenticateWithBiometrics(completion: @escaping (Result<User, Error>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(.failure(AuthError.biometricsNotAvailable))
            return
        }
        
        let reason = "Use Face ID or Touch ID to sign in to Quiet Delight"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    
                    if let credentials = self?.getCredentialsFromKeychain() {
                        self?.signInWithEmailPassword(email: credentials.email, password: credentials.password, completion: completion)
                    } else {
                        completion(.failure(AuthError.noSavedCredentials))
                    }
                } else {
                    if let error = authenticationError {
                        completion(.failure(error))
                    } else {
                        completion(.failure(AuthError.biometricAuthFailed))
                    }
                }
            }
        }
    }
    
    func isBiometricAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func getBiometricType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
    
    // MARK: - Profile Management
    
    func updateUserProfile(displayName: String? = nil, photoURL: URL? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        changeRequest.commitChanges { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateUserEmail(newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        guard isValidEmail(newEmail) else {
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func updateUserPassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        guard newPassword.count >= 6 else {
            completion(.failure(AuthError.weakPassword))
            return
        }
        
        user.updatePassword(to: newPassword) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                   
                    if let credentials = self?.getCredentialsFromKeychain() {
                        self?.saveCredentialsToKeychain(email: credentials.email, password: newPassword)
                    }
                    completion(.success(()))
                }
            }
        }
    }
    
    // Re-authentication
    
    func reauthenticateUser(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user.reauthenticate(with: credential) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // Email Verification
    
    func sendEmailVerification(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        user.sendEmailVerification { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func reloadUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.userNotFound))
            return
        }
        
        user.reload { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    self?.currentUser = user
                    completion(.success(()))
                }
            }
        }
    }
    
    //Firestore
    
    private func performSignUp(userData: UserData, password: String, completion: @escaping (AuthResult) -> Void) {
        isLoading = true
        
        Auth.auth().createUser(withEmail: userData.email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(.failure(self?.handleAuthError(error) ?? "Sign up failed"))
                    return
                }
                
                guard let user = authResult?.user else {
                    completion(.failure("Failed to create account. Please try again."))
                    return
                }
                
            
                self?.saveUserDataToFirestore(user: user, userData: userData, completion: completion)
            }
        }
    }
    
    private func saveUserDataToFirestore(user: User, userData: UserData, completion: @escaping (AuthResult) -> Void) {
        print("Starting to save user data for UID: \(user.uid)")
        
        let firestoreData: [String: Any] = [
            "uid": user.uid,
            "username": userData.username,
            "email": userData.email,
            "enableFaceID": userData.enableFaceID,
            "sendUpdates": userData.sendUpdates,
            "createdAt": Timestamp(),
            "lastLoginAt": Timestamp()
        ]
        
        db.collection("users").document(user.uid).setData(firestoreData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Firestore Error: \(error.localizedDescription)")
                    completion(.failure("Account created but failed to save profile data: \(error.localizedDescription)"))
                } else {
                    print("User data saved successfully to Firestore")
                    completion(.success("Account created successfully! Please sign in."))
                }
            }
        }
    }
    
    private func updateLastLoginTime() {
        guard let user = currentUser else { return }
        
        db.collection("users").document(user.uid).updateData([
            "lastLoginAt": Timestamp()
        ]) { error in
            if let error = error {
                print("Failed to update last login time: \(error.localizedDescription)")
            }
        }
    }
    
    func saveUserPreferences(enableFaceID: Bool, sendUpdates: Bool) {
        guard let user = currentUser else { return }
        
        db.collection("users").document(user.uid).updateData([
            "enableFaceID": enableFaceID,
            "sendUpdates": sendUpdates
        ]) { error in
            if let error = error {
                print("Failed to update user preferences: \(error.localizedDescription)")
            } else {
                print("User preferences updated successfully")
            }
        }
    }
    
    func getUserData(completion: @escaping ([String: Any]?) -> Void) {
        guard let user = currentUser else {
            completion(nil)
            return
        }
        
        db.collection("users").document(user.uid).getDocument { document, error in
            if let error = error {
                print("Error getting user data: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                completion(document.data())
            } else {
                completion(nil)
            }
        }
    }
    
    // keychain
    
    private func saveCredentialsToKeychain(email: String, password: String) {
        let credentials = ["email": email, "password": password]
        
        guard let data = try? JSONSerialization.data(withJSONObject: credentials) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "user_credentials",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to save credentials to keychain: \(status)")
        }
    }
    
    private func getCredentialsFromKeychain() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "user_credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let credentials = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let email = credentials["email"],
              let password = credentials["password"] else {
            return nil
        }
        
        return (email: email, password: password)
    }
    
    private func removeCredentialsFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "user_credentials"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    //Validation
    
    private func validateSignUpInput(
        username: String,
        email: String,
        password: String,
        confirmPassword: String,
        agreeToTerms: Bool
    ) -> String? {
        
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter a username."
        }
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Please enter an email address."
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email address."
        }
        
        if password.isEmpty {
            return "Please enter a password."
        }
        
        if password.count < 6 {
            return "Password must be at least 6 characters long."
        }
        
        if password != confirmPassword {
            return "Passwords don't match."
        }
        
        if !agreeToTerms {
            return "You must agree to the Terms of Service and Privacy Policy."
        }
        
        return nil // Novalidation errors
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let authError = error as NSError
        
        switch authError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email address is already registered. Please use a different email or sign in."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."
        case AuthErrorCode.weakPassword.rawValue:
            return "Password is too weak. Please choose a stronger password."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection and try again."
        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email address."
        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."
        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled. Please contact support."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many failed attempts. Please try again later."
        default:
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
}

//Authentication State Protocol
protocol AuthenticationStateDelegate: AnyObject {
    func authenticationStateDidChange(isAuthenticated: Bool)
    func authenticationDidFail(with error: Error)
}



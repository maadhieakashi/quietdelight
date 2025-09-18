//
//  NotificationManager.swift
//  quietdelight
//
//  Created by SAHimeshi 002 on 2025-09-18.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var isNotificationEnabled = true
    
    private override init() {
        super.init()
        loadNotificationSettings()
        setupNotificationCenter()
    }
    
    private func loadNotificationSettings() {
        // Load notification enabled state from UserDefaults, default to true
        isNotificationEnabled = UserDefaults.standard.object(forKey: "notificationEnabled") as? Bool ?? true
        print("Loaded notification settings: \(isNotificationEnabled)")
    }
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Settings Management
    
    func setNotificationEnabled(_ enabled: Bool) {
        isNotificationEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "notificationEnabled")
        print("Notification enabled set to: \(enabled)")
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                } else {
                    print("Notification permission granted: \(granted)")
                }
            }
        }
    }
    
    func checkNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self?.isAuthorized = true
                case .denied, .notDetermined:
                    self?.isAuthorized = false
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    //Notification Scheduling
    
    func scheduleSignInNotification() {
        print("Attempting to schedule sign-in notification...")
        print("Notification enabled: \(isNotificationEnabled)")
        print("Is authorized: \(isAuthorized)")
        
        // Check if notifications are enabled in settings
        guard isNotificationEnabled else {
            print("Notifications are disabled in settings")
            return
        }
        
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Signed In"
        content.body = "You have successfully signed in"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        // Create an immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // Create unique identifier
        let identifier = "sign_in_notification_\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling sign-in notification: \(error.localizedDescription)")
            } else {
                print("Sign-in notification scheduled successfully")
            }
        }
    }
    
    func scheduleCustomNotification(title: String, body: String, delay: TimeInterval = 0.1) {
        guard isNotificationEnabled else {
            print("Notifications are disabled in settings")
            return
        }
        
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let identifier = "custom_notification_\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling custom notification: \(error.localizedDescription)")
            } else {
                print("Custom notification scheduled successfully")
            }
        }
    }
    
    //  Notification Management
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        // Reset badge count
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

//  UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // This method is called when a notification is received while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Notification received in foreground: \(notification.request.content.title)")
        
       
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            // For older iOS versions
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // This method is called when the user interacts with a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("User interacted with notification: \(response.notification.request.content.title)")
        
        // Handle different action types if needed
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            print("User tapped the notification")
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("User dismissed the notification")
        default:
            break
        }
        
        
        clearBadge()
        
        completionHandler()
    }
}

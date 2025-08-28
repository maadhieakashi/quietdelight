//
//  quietdelightcafeApp.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-18.
//

import SwiftUI
import Firebase

@main
struct quietdelightApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
           // ContentView()
            SplashView()
        }
    }
}

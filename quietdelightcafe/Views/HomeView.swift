//
//  HomeView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-20.
//

import SwiftUI

struct HomeView: View {
    @State private var forgotPassword = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, World!")
                Button("Forgot Password?") {
                    forgotPassword = true
                }
            }
            .navigationDestination(isPresented: $forgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

#Preview {
    HomeView()
}

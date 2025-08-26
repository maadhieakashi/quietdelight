//
//  SettingsView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI
struct SettingsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F5F5").ignoresSafeArea()
                
                VStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your preferences")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#Preview {
    SettingsView()
}

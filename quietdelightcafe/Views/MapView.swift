//
//  MapView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI
struct MapView: View {
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack {
                Text("Map")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Find cafes near you")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    MapView()
}

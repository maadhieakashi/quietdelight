//
//  FavoriteView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-26.
//

import SwiftUI

struct FavoriteView: View {
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            VStack {
                Text("Favorites")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                
                Text("Your saved cafes")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    FavoriteView()
}

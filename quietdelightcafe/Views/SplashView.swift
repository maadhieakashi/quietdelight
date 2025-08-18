//
//  SplashView.swift
//  quietdelightcafe
//
//  Created by SAHimeshi 002 on 2025-08-18.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 50
    @State private var titleOpacity: Double = 0.0
    @State private var showSignIn = false
    
    var body: some View {
        Group {
            if showSignIn {
                //SigninView()
            } else {
            GeometryReader { geometry in
            ZStack {
            // BG color
            Color(hex: "382E2C")
            .ignoresSafeArea()
                        
            VStack(spacing: 20) {
            Spacer()
                            
            // Logo
            Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 80))
            .foregroundColor(.white)
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .animation(.easeOut(duration: 1.2), value: logoScale)
            .animation(.easeOut(duration: 1.2), value: logoOpacity)
                            
            // title
            Text("QUIET DELIGHT")
            .font(.title)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .offset(y: titleOffset)
            .opacity(titleOpacity)
            .animation(.easeOut(duration: 1.0).delay(0.5), value: titleOffset)
            .animation(.easeOut(duration: 1.0).delay(0.5), value: titleOpacity)
                            
            Spacer()
                            
            // Loading
            ProgressView()
            .scaleEffect(1.2)
            .tint(.white.opacity(0.7))
            .padding(.bottom, 50)
                        }
                    }
                }
                .onAppear {
                    // Start animations
                    logoScale = 1.0
                    logoOpacity = 1.0
                    titleOffset = 0
                    titleOpacity = 1.0
                   
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSignIn = true
                    }
                }
            }
        }
        .animation(.none, value: showSignIn)
    }
}

#Preview {
    SplashView()
}

//
//  LoginView.swift
//  Ping
//
//  Created by James Nebeker on 2/11/25.
//

import Foundation
import SwiftUI

public struct LoginView: View {
    @State private var noiseImage: NSImage?
    @State private var username: String = ""
    @State private var password: String = ""
    public var body: some View {
        ZStack {
            if let image = noiseImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)  // Fill instead of fit
                    .frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()  // Infinite frame
                VStack {
                    TextField("Username", text: $username).textFieldStyle(.plain)
                        .frame(width: 160, height: 32)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.messageBackground)
                        .foregroundColor(AppColors.focusedBorder)
                        .fontWeight(.heavy)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke( AppColors.focusedBorder )
                        )
                       
                    TextField("Password", text: $password).textFieldStyle(.plain)
                        .frame(width: 160, height: 32)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.messageBackground)
                        .foregroundColor(AppColors.focusedBorder)
                        .fontWeight(.heavy)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke( AppColors.focusedBorder )
                        )
                    Button("Log in") {
                        
                    }
                }.frame(width: 200, height: 200)
                
            }
        }.onAppear {
            noiseImage = loadNoiseImage(from: "background")
        }
    }
}

#Preview {
    LoginView()
}


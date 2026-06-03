//
//  RealsPage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI

struct ReelsPage: View {
    
    let reels: [Reel] = [
        Reel(video: "https://www.bigbuckbunny.org/", username: "john_doe", caption: "Late night vibes"),
        Reel(video: "https://www.bigbuckbunny.org/", username: "emma", caption: "Beach day"),
        Reel(video: "https://www.bigbuckbunny.org/", username: "alex", caption: "Workout time")
    ]
    
    var body: some View {
        
        GeometryReader { geometry in
            
            TabView {
                
                ForEach(reels) { reel in
                    
                    ReelCard(reel: reel)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .rotationEffect(.degrees(90))
                }
            }
            .frame(
                width: geometry.size.height,
                height: geometry.size.width
            )
            .rotationEffect(.degrees(-90), anchor: .topLeading)
            .offset(x: 0, y: geometry.size.height)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .ignoresSafeArea()
        .background(Color.black)
    }
}


struct ReelCard: View {
    
    let reel: Reel
    
    @State private var isLiked = false
    
    var body: some View {
        
        ZStack {
            
            // VIDEO / IMAGE
            Image(reel.video)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 380, maxHeight: .infinity)
                .clipped()
            
            // DARK OVERLAY
            LinearGradient(
                colors: [
                    .black.opacity(0.1),
                    .black.opacity(0.2),
                    .black.opacity(0.7)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    
                    // LEFT SIDE
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            
                            Image("profile")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .background(Color.white)
                            
                            Text(reel.username)
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                            
                            Button(action: {}) {
                                Text("Follow")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            }
                        }
                        
                        Text(reel.caption)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        
                        HStack(spacing: 8) {
                            
                            Image(systemName: "music.note")
                                .foregroundColor(.white)
                            
                            Text("Original Audio")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Spacer()
                    
                    // RIGHT SIDE ACTIONS
                    VStack(spacing: 24) {
                        
                        Button(action: {
                            isLiked.toggle()
                        }) {
                            
                            VStack(spacing: 6) {
                                
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .resizable()
                                    .frame(width: 30, height: 28)
                                    .foregroundColor(isLiked ? .red : .white)
                                
                                Text("12.5K")
                                    .foregroundColor(.white)
                                    .font(.system(size: 13))
                            }
                        }
                        
                        actionButton(
                            image: "message",
                            text: "845"
                        )
                        
                        actionButton(
                            image: "paperplane",
                            text: "Share"
                        )
                        
                        actionButton(
                            image: "ellipsis",
                            text: ""
                        )
                        
                        Image("profile")
                            .resizable()
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 20)
                }
                .padding()
            }
        }
    }
    
    func actionButton(image: String, text: String) -> some View {
        
        VStack(spacing: 6) {
            
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: 13))
            }
        }
    }
}


struct Reel: Identifiable {
    
    let id = UUID()
    
    let video: String
    let username: String
    let caption: String
}

#Preview {
    ReelsPage()
}

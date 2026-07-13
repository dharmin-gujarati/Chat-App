//
//  PageManage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI
import FirebaseDatabase

struct PageManage: View {
    
    @State var selectedTab: Int
    @State private var profileImageBase64 = ""
    
    var body: some View {
        
        NavigationStack {
            Rectangle()
                .fill(.white)
                .ignoresSafeArea()
                .overlay {
                    
                    VStack(spacing: 0.3) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 50)
                        
                        if selectedTab == 0 {
                            HomePage()
                        }
                        if selectedTab == 1 {
                            ReelsPage()
                        }
                        if selectedTab == 2 {
                            MessagePage()
                        }
                        if selectedTab == 3 {
                            SearchPage()
                        }
                        if selectedTab == 4 {
                            ProfilePage()
                        }
                        
                        ZStack {
                            HStack {
                                tabButton(icon: "house", index: 0)
                                Spacer()
                                tabButton(icon: "play.square", index: 1)
                                
                                Spacer()
                                tabButton(icon: "paperplane", index: 2)
                                
                                Spacer()
                                tabButton(icon: "magnifyingglass", index: 3)
                                
                                Spacer()
                                profileTabButton(index: 4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .padding(.top, 10)
                            .background(Color(.black))
                            .shadow(radius: 10)
                        }
                        .padding(.bottom, 1)
                    }
                    .ignoresSafeArea()
                }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            fetchProfileImage()
        }
    }
    
    func tabButton(icon: String, index: Int) -> some View {
        
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .bold()
                    .font(.system(size: 30))
                    .foregroundColor(selectedTab == index ? Color.white : .gray)
            }
        }
    }
    
    func profileTabButton(index: Int) -> some View {
        
        Button(action: {
            selectedTab = index
        }) {
            profileTabImage
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            selectedTab == index
                            ? Color.white
                            : Color.gray,
                            lineWidth: 2
                        )
                )
        }
    }
    
    @ViewBuilder
    private var profileTabImage: some View {
        
        if let imageData = Data(base64Encoded: profileImageBase64),
           let uiImage = UIImage(data: imageData) {
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
            
        } else {
            
            Image("profile")
                .resizable()
                .scaledToFill()
        }
    }
    
    func fetchProfileImage() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        Database.database()
            .reference()
            .child("users")
            .child(currentUserId)
            .observe(.value) { snapshot in
                
                guard let data =
                        snapshot.value as? [String: Any]
                else { return }
                
                profileImageBase64 =
                data["profileImage"] as? String ?? ""
            }
    }
}

#Preview {
    PageManage(selectedTab: 0)
}

//
//  homePage.swift
//  ChatApp
//
//  Created by CDMI on 28/05/26.
//

import SwiftUI
import FirebaseDatabase

struct HomePage: View {
    
    let stories = Array(1...10)
    
    @State private var posts: [PostModel] = []
    @State private var gotoRequests = false
    
    var body: some View {
        
        NavigationStack{
            ZStack(alignment: .top) {
                
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    
                    // Header
                    HStack {
                        
                        Button {
                            
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Image("mff")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 40)
                        
                        Spacer()
                        
                        Button {
                            gotoRequests = true
                        } label: {
                            Image(systemName: "heart")
                                .font(.system(size: 25))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    ScrollView {
                        
                        VStack(spacing: 0) {
                            
                            // Stories
                            ScrollView(.horizontal, showsIndicators: false) {
                                
                                HStack(spacing: 15) {
                                    
                                    ForEach(stories, id: \.self) { _ in
                                        
                                        VStack {
                                            
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.orange, .red, .purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                                .frame(width: 72, height: 72)
                                                .overlay {
                                                    
                                                    Image("profile")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 64, height: 64)
                                                        .clipShape(Circle())
                                                }
                                            
                                            Text("user")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                            
                            Divider()
                                .background(Color.gray.opacity(0.5))
                            
                            // Posts
                            LazyVStack(spacing: 25) {
                                
                                ForEach(posts) { post in
                                    
                                    VStack(alignment: .leading) {
                                        
                                        HStack {
                                            
                                            Image("profile")
                                                .resizable()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            
                                            Text(post.username)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        
                                        AsyncImage(
                                            url: URL(string: post.imageURL)
                                        ) { image in
                                            
                                            image
                                                .resizable()
                                                .scaledToFill()
                                            
                                        } placeholder: {
                                            
                                            ProgressView()
                                        }
                                        .frame(height: 350)
                                        .clipped()
                                        
                                        Text(post.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .onAppear {
                fetchPosts()
            }
            .navigationDestination(
                isPresented: $gotoRequests
            ) {
                
                FollowRequestsPage()
            }
        }
    }
    
    func fetchPosts() {
        
        let ref = Database.database()
            .reference()
            .child("posts")
        
        ref.observe(.value) { snapshot in
            
            var tempPosts: [PostModel] = []
            
            for child in snapshot.children {
                
                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any]
                else { continue }
                
                let post = PostModel(
                    id: snap.key,
                    userId: data["userId"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    imageURL: data["imageURL"] as? String ?? "",
                    caption: data["caption"] as? String ?? ""
                )
                
                tempPosts.append(post)
            }
            
            posts = Array(tempPosts.reversed())
        }
    }
}

#Preview {
    HomePage()
}



//
//  UserProfilePage.swift
//  ChatApp
//
//  Created by CDMI on 04/06/26.
//

import SwiftUI
import FirebaseDatabase

struct UserProfilePage: View {
    
    let userId: String
    
    @State private var username = ""
    @State private var fullname = ""
    @State private var userPosts: [PostModel] = []
    @State private var gotoSearchPage = false
    
    @State private var isFollowing = false
    @State private var requestSent = false
    @State private var showMessageButton = false
    @State private var gotoChat = false
    
    var body: some View {
        
        NavigationStack{
            ZStack {
                
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    
                    VStack(spacing: 16) {
                        HStack{
                            Button {
                                gotoSearchPage = true
                                
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.leading, 10)
                        
                        // Profile Image
                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                        
                        // Username
                        Text(username)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        // Fullname
                        Text(fullname)
                            .foregroundColor(.gray)
                        
                        // Stats
                        HStack {
                            
                            Spacer()
                            
                            statView(
                                count: "\(userPosts.count)",
                                title: "Posts"
                            )
                            
                            Spacer()
                            
                            statView(
                                count: "0",
                                title: "Followers"
                            )
                            
                            Spacer()
                            
                            statView(
                                count: "0",
                                title: "Following"
                            )
                            
                            Spacer()
                        }
                        
                        Divider()
                            .background(Color.gray)
                        HStack {
                            
                            if showMessageButton {
                                
                                NavigationLink {
                                    
                                    OpenMassegPage(
                                        profileName: username,
                                        otherUserId: userId
                                    )
                                    
                                } label: {
                                    
                                    Text("Message")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                                
                            } else {
                                
                                Button {
                                    
                                    sendFollowRequest()
                                    
                                } label: {
                                    
                                    Text(
                                        requestSent
                                        ? "Requested"
                                        : "Follow"
                                    )
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        requestSent
                                        ? Color.gray
                                        : Color.blue
                                    )
                                    .cornerRadius(10)
                                }
                                .disabled(requestSent)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Posts Grid
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible()),
                                count: 3
                            ),
                            spacing: 2
                        ) {
                            
                            ForEach(userPosts) { post in
                                
                                AsyncImage(
                                    url: URL(string: post.imageURL)
                                ) { image in
                                    
                                    image
                                        .resizable()
                                        .scaledToFill()
                                    
                                } placeholder: {
                                    
                                    ProgressView()
                                }
                                .frame(height: 120)
                                .clipped()
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                fetchUser()
                fetchPosts()
                checkFollowStatus()
            }
            .navigationDestination(isPresented: $gotoSearchPage) {
                PageManage(selectedTab: 3)
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    func sendFollowRequest() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        let ref = Database.database()
            .reference()
            .child("followRequests")
            .childByAutoId()
        
        let data: [String: Any] = [
            
            "fromUserId": currentUserId,
            "toUserId": userId,
            "status": "pending"
        ]
        
        ref.setValue(data)
        
        requestSent = true
    }
    
    // MARK: User Info
    
    func fetchUser() {
        
        Database.database()
            .reference()
            .child("users")
            .child(userId)
            .observeSingleEvent(of: .value) { snapshot in
                
                guard let data =
                        snapshot.value as? [String: Any]
                else { return }
                
                username =
                data["username"] as? String ?? ""
                
                fullname =
                data["fullname"] as? String ?? ""
            }
    }
    
    // MARK: User Posts
    
    func fetchPosts() {
        
        Database.database()
            .reference()
            .child("posts")
            .observe(.value) { snapshot in
                
                var tempPosts: [PostModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap =
                            child as? DataSnapshot,
                          let data =
                            snap.value as? [String: Any]
                    else { continue }
                    
                    let postUserId =
                    data["userId"] as? String ?? ""
                    
                    if postUserId == userId {
                        
                        tempPosts.append(
                            
                            PostModel(
                                id: snap.key,
                                userId: postUserId,
                                username:
                                    data["username"] as? String ?? "",
                                imageURL:
                                    data["imageURL"] as? String ?? "",
                                caption:
                                    data["caption"] as? String ?? ""
                            )
                        )
                    }
                }
                
                userPosts = tempPosts
            }
    }
    
    // MARK: Stats View
    
    func statView(
        count: String,
        title: String
    ) -> some View {
        
        VStack {
            
            Text(count)
                .foregroundColor(.white)
                .font(.headline)
            
            Text(title)
                .foregroundColor(.gray)
        }
    }
    func checkFollowStatus() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        // Check accepted follow
        Database.database()
            .reference()
            .child("followers")
            .child(userId)
            .child(currentUserId)
            .observe(.value) { snapshot in
                
                if snapshot.exists() {
                    
                    isFollowing = true
                    showMessageButton = true
                    requestSent = false
                }
            }
        
        // Check pending request
        Database.database()
            .reference()
            .child("followRequests")
            .observe(.value) { snapshot in
                
                var pending = false
                
                for child in snapshot.children {
                    
                    guard let snap =
                            child as? DataSnapshot,
                          let data =
                            snap.value as? [String: Any]
                    else { continue }
                    
                    let fromUserId =
                    data["fromUserId"] as? String ?? ""
                    
                    let toUserId =
                    data["toUserId"] as? String ?? ""
                    
                    if fromUserId == currentUserId &&
                        toUserId == userId {
                        
                        pending = true
                        break
                    }
                }
                
                if !isFollowing {
                    
                    requestSent = pending
                }
            }
    }
}

#Preview {
    NavigationStack {
        UserProfilePage(
            userId: "testUserId"
        )
    }
}

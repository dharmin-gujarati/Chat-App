//
//  ProfilePage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

//
//  ProfilePage.swift
//  ChatApp
//

import SwiftUI
import FirebaseDatabase

struct ProfilePage: View {
    
    @State private var username = ""
    @State private var bio = ""
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var logout = false
    
    @State private var myPosts: [PostModel] = []
    
    @State private var showEditBio = false
    @State private var newBio = ""
    
    
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 16) {
                    
                    // MARK: Profile Header
                    
                    HStack {
                        
                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                        
                        Spacer()
                        
                        statView(
                            count: "\(myPosts.count)",
                            title: "Posts"
                        )
                        
                        Spacer()
                        
                        statView(
                            count: "\(followersCount)",
                            title: "Followers"
                        )
                        
                        Spacer()
                        
                        statView(
                            count: "\(followingCount)",
                            title: "Following"
                        )
                    }
                    .padding(.horizontal)
                    
                    // MARK: Username + Bio
                    
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        
                        Text(username)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(bio)
                            .foregroundColor(.gray)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.horizontal)
                    
                    // MARK: Buttons
                    
                    HStack(spacing: 10) {
                        
                        Button {
                            
                            newBio = bio
                            showEditBio = true
                            
                        } label: {
                            
                            Text("Edit Bio")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    Color.gray.opacity(0.25)
                                )
                                .cornerRadius(8)
                        }
                        
                        NavigationLink {
                            
                            CreatePostPage()
                            
                        } label: {
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .frame(width: 50)
                                .padding(.vertical, 8)
                                .background(
                                    Color.gray.opacity(0.25)
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.gray)
                    
                    // MARK: Grid Icon
                    
                    HStack {
                        
                        Spacer()
                        
                        Image(systemName: "square.grid.3x3")
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    // MARK: Posts Grid
                    
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible()),
                            count: 3
                        ),
                        spacing: 2
                    ) {
                        
                        ForEach(myPosts) { post in
                            
                            AsyncImage(
                                url: URL(
                                    string: post.imageURL
                                )
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
                    
                    // MARK: Logout
                    
                    Button {
                        
                        UserDefaults.standard.removeObject(
                            forKey: "currentUsername"
                        )
                        
                        UserDefaults.standard.removeObject(
                            forKey: "currentUserId"
                        )
                        
                        logout = true
                        
                    } label: {
                        
                        Text("Log Out")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    .padding(.top)
                }
                .padding(.top)
            }
            .background(Color.black)
            
            .navigationDestination(
                isPresented: $logout
            ) {
                
                SigninPage()
            }
            
            .alert(
                "Edit Bio",
                isPresented: $showEditBio
            ) {
                
                TextField(
                    "Enter Bio",
                    text: $newBio
                )
                
                Button("Save") {
                    
                    saveBio()
                }
                
                Button(
                    "Cancel",
                    role: .cancel
                ) { }
            }
            
            .onAppear {
                
                fetchCurrentUser()
                fetchMyPosts()
                fetchFollowersCount()
                fetchFollowingCount()
            }
        }
    }
    // MARK: Followers Count
    
    func fetchFollowersCount() {
        
        guard let currentUserId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("followers")
            .child(currentUserId)
            .observe(.value) { snapshot in
                
                followersCount =
                Int(snapshot.childrenCount)
            }
    }
    
    // MARK: Following Count
    
    func fetchFollowingCount() {
        
        guard let currentUserId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("following")
            .child(currentUserId)
            .observe(.value) { snapshot in
                
                followingCount =
                Int(snapshot.childrenCount)
            }
    }
    
    
    // MARK: Stats View
    
    func statView(
        count: String,
        title: String
    ) -> some View {
        
        VStack {
            
            Text(count)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(title)
                .foregroundColor(.white)
        }
    }
    
    // MARK: Save Bio
    
    func saveBio() {
        
        guard let userId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("users")
            .child(userId)
            .updateChildValues([
                
                "bio": newBio
            ])
        
        bio = newBio
    }
    
    // MARK: Fetch User
    
    func fetchCurrentUser() {
        
        guard let userId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("users")
            .child(userId)
            .observeSingleEvent(
                of: .value
            ) { snapshot in
                
                guard let data =
                        snapshot.value as? [String: Any]
                else { return }
                
                username =
                data["username"] as? String ?? ""
                
                bio =
                data["bio"] as? String ?? ""
            }
    }
    
    // MARK: Fetch My Posts
    
    func fetchMyPosts() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
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
                    
                    let userId =
                    data["userId"] as? String ?? ""
                    
                    if userId == currentUserId {
                        
                        tempPosts.append(
                            
                            PostModel(
                                id: snap.key,
                                userId: userId,
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
                
                myPosts = tempPosts.reversed()
            }
    }
}

#Preview {
    
    ProfilePage()
}

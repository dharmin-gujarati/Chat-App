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
    @State private var selectedPost: PostModel?
    @State private var gotoSearchPage = false
    
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var isFollowing = false
    @State private var requestSent = false
    @State private var showMessageButton = false
    @State private var gotoChat = false
    
    @State private var profileImageBase64: String = ""
    
    @State private var highlights: [HighlightModel] = []
    @State private var selectedHighlight: HighlightModel?
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.06, green: 0.05, blue: 0.10)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 24) {
                        
                        // MARK: Header
                        
                        HStack {
                            
                            Button {
                                gotoSearchPage = true
                            } label: {
                                
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 42, height: 42)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Text("Profile")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 42, height: 42)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        
                        // MARK: Profile
                        
                        VStack(spacing: 14) {
                            
                            profileImageView
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    .purple,
                                                    .pink,
                                                    .orange
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                            
                            VStack(spacing: 4) {
                                
                                Text(username)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text(fullname)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        
                        // MARK: Stats
                        
                        HStack(spacing: 14) {
                            
                            statCard(
                                value: "\(userPosts.count)",
                                title: "Posts"
                            )
                            
                            statCard(
                                value: "\(followersCount)",
                                title: "Followers"
                            )
                            
                            statCard(
                                value: "\(followingCount)",
                                title: "Following"
                            )
                        }
                        .padding(.horizontal)
                        
                        // MARK: Follow Button
                        
                        if showMessageButton {
                            
                            NavigationLink {
                                
                                OpenMassegPage(
                                    profileName: username,
                                    otherUserId: userId
                                )
                                
                            } label: {
                                
                                Text("Message")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            
                        } else {
                            
                            Button {
                                sendFollowRequest()
                            } label: {
                                
                                Text(requestSent ? "Requested" : "Follow")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: requestSent
                                            ? [Color.gray.opacity(0.7), Color.gray]
                                            : [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                            }
                            .disabled(requestSent)
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal)
                        
                        highlightsRow
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal)
                        
                        postsGrid
                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                fetchUser()
                fetchPosts()
                checkFollowStatus()
                fetchFollowersCount()
                fetchFollowingCount()
                fetchHighlights()
            }
            .navigationDestination(isPresented: $gotoSearchPage) {
                PageManage(selectedTab: 3)
            }
            .fullScreenCover(item: $selectedHighlight) { highlight in
                
                UserHighlightStoryViewer(
                    highlight: highlight,
                    selectedHighlight: $selectedHighlight
                )
            }
            .fullScreenCover(item: $selectedPost) { post in
                
                UserPostPopupView(
                    post: post,
                    profileImageBase64: profileImageBase64,
                    selectedPost: $selectedPost
                )
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func statCard(
        value: String,
        title: String
    ) -> some View {
        
        VStack(spacing: 6) {
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    // MARK: Highlights Row
    
    private var highlightsRow: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 16) {
                
                ForEach(highlights) { highlight in
                    
                    VStack(spacing: 6) {
                        
                        highlightCoverView(for: highlight)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                            .onTapGesture {
                                selectedHighlight = highlight
                            }
                        
                        Text(highlight.title)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(width: 64)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func highlightCoverView(for highlight: HighlightModel) -> some View {
        
        if let firstImage = highlight.images.first,
           let imageData = Data(base64Encoded: firstImage),
           let uiImage = UIImage(data: imageData) {
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
            
        } else {
            
            Color.gray.opacity(0.2)
                .overlay(
                    Image(systemName: "star.fill")
                        .foregroundColor(.gray.opacity(0.6))
                )
        }
    }
    
    // MARK: Profile Image View
    
    @ViewBuilder
    private var profileImageView: some View {
        
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
    
    // MARK: Posts Grid
    
    private var postsGrid: some View {
        
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible()),
                count: 3
            ),
            spacing: 2
        ) {
            
            ForEach(userPosts) { post in
                postCell(post: post)
            }
        }
    }
    
    @ViewBuilder
    private func postCell(post: PostModel) -> some View {
        
        if let imageData = Data(base64Encoded: post.imageURL),
           let uiImage = UIImage(data: imageData) {
            
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .onTapGesture {
                    selectedPost = post
                }
            
        } else {
            
            Color.gray.opacity(0.2)
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray.opacity(0.5))
                )
                .onTapGesture {
                    selectedPost = post
                }
        }
    }
    
    // MARK: Send Follow Request
    
    func sendFollowRequest() {
        
        let currentUserId =
        UserDefaults.standard.string(forKey: "currentUserId") ?? ""
        
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
    
    // MARK: Fetch Highlights
    
    private func fetchHighlights() {
        
        Database.database()
            .reference()
            .child("highlights")
            .child(userId)
            .observe(.value) { snapshot in
                
                var temp: [HighlightModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    var images: [String] = []
                    
                    if let stringImages = data["images"] as? [String] {
                        images = stringImages
                        
                    } else if let anyImages = data["images"] as? [Any] {
                        images = anyImages.compactMap { $0 as? String }
                        
                    } else if let dictImages = data["images"] as? [String: Any] {
                        images = dictImages
                            .sorted { $0.key < $1.key }
                            .compactMap { $0.value as? String }
                    }
                    
                    temp.append(
                        HighlightModel(
                            id: snap.key,
                            title: data["title"] as? String ?? "",
                            images: images
                        )
                    )
                }
                
                highlights = temp
            }
    }
    
    // MARK: User Info
    
    func fetchUser() {
        
        Database.database()
            .reference()
            .child("users")
            .child(userId)
            .observeSingleEvent(of: .value) { snapshot in
                
                guard let data = snapshot.value as? [String: Any]
                else { return }
                
                username = data["username"] as? String ?? ""
                fullname = data["fullname"] as? String ?? ""
                profileImageBase64 = data["profileImage"] as? String ?? ""
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
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    let postUserId = data["userId"] as? String ?? ""
                    
                    if postUserId == userId {
                        
                        tempPosts.append(
                            PostModel(
                                id: snap.key,
                                userId: postUserId,
                                username: data["username"] as? String ?? "",
                                imageURL: data["imageURL"] as? String ?? "",
                                caption: data["caption"] as? String ?? ""
                            )
                        )
                    }
                }
                
                userPosts = tempPosts.reversed()
            }
    }
    
    // MARK: Followers Count
    
    func fetchFollowersCount() {
        
        Database.database()
            .reference()
            .child("followers")
            .child(userId)
            .observe(.value) { snapshot in
                
                followersCount = Int(snapshot.childrenCount)
            }
    }
    
    // MARK: Following Count
    
    func fetchFollowingCount() {
        
        Database.database()
            .reference()
            .child("following")
            .child(userId)
            .observe(.value) { snapshot in
                
                followingCount = Int(snapshot.childrenCount)
            }
    }
    
    // MARK: Stats View
    
    func statView(count: String, title: String) -> some View {
        
        VStack {
            
            Text(count)
                .foregroundColor(.white)
                .font(.headline)
            
            Text(title)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: Check Follow Status
    
    func checkFollowStatus() {
        
        let currentUserId =
        UserDefaults.standard.string(forKey: "currentUserId") ?? ""
        
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
        
        Database.database()
            .reference()
            .child("followRequests")
            .observe(.value) { snapshot in
                
                var pending = false
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    let fromUserId = data["fromUserId"] as? String ?? ""
                    let toUserId = data["toUserId"] as? String ?? ""
                    
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

// MARK: - User Post Popup View

struct UserPostPopupView: View {
    
    let post: PostModel
    let profileImageBase64: String
    @Binding var selectedPost: PostModel?
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    
                    profileImageView
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    Text(post.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        selectedPost = nil
                        
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Spacer()
                
                if let imageData = Data(base64Encoded: post.imageURL),
                   let uiImage = UIImage(data: imageData) {
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    
                } else {
                    
                    Text("No image")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if !post.caption.isEmpty {
                    
                    Text(post.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        
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
}

// MARK: - User Highlight Story Viewer

struct UserHighlightStoryViewer: View {
    
    let highlight: HighlightModel
    @Binding var selectedHighlight: HighlightModel?
    
    @State private var currentIndex = 0
    
    private let timer = Timer.publish(
        every: 3,
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            if highlight.images.indices.contains(currentIndex),
               let imageData = Data(base64Encoded: highlight.images[currentIndex]),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                
                VStack(spacing: 12) {
                    
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Image not found")
                        .foregroundColor(.white)
                }
            }
            
            VStack {
                
                HStack(spacing: 4) {
                    
                    ForEach(0..<max(highlight.images.count, 1), id: \.self) { index in
                        
                        Capsule()
                            .fill(
                                index <= currentIndex
                                ? Color.white
                                : Color.white.opacity(0.3)
                            )
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                HStack {
                    
                    Text(highlight.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        selectedHighlight = nil
                        
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToPrevious()
                    }
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToNext()
                    }
            }
        }
        .onReceive(timer) { _ in
            goToNext()
        }
    }
    
    private func goToNext() {
        
        if currentIndex < highlight.images.count - 1 {
            currentIndex += 1
        } else {
            selectedHighlight = nil
        }
    }
    
    private func goToPrevious() {
        
        if currentIndex > 0 {
            currentIndex -= 1
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

//
//  ProfilePage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI
import FirebaseDatabase
import PhotosUI
import Combine

struct HighlightModel: Identifiable {
    let id: String
    let title: String
    let images: [String]
}

struct ProfileCommentModel: Identifiable {
    let id: String
    let userId: String
    let username: String
    let text: String
    let timestamp: Double
}

struct ProfileListUserModel: Identifiable {
    let id: String
    let username: String
    let fullname: String
    let profileImage: String
}

struct ProfilePage: View {
    
    @State private var username = ""
    @State private var bio = ""
    @State private var followersCount = 0
    @State private var followingCount = 0
    
    @State private var logout = false
    @State private var myPosts: [PostModel] = []
    
    @State private var showEditBio = false
    @State private var newBio = ""
    
    @State private var profileImageBase64: String = ""
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var isUploadingDP = false
    
    @State private var highlights: [HighlightModel] = []
    @State private var selectedHighlightItem: PhotosPickerItem?
    @State private var pendingHighlightImage: UIImage?
    @State private var showAddHighlightAlert = false
    @State private var newHighlightTitle = ""
    @State private var isUploadingHighlight = false
    @State private var selectedHighlight: HighlightModel?
    @State private var showHighlightActionSheet = false
    @State private var addImageItem: PhotosPickerItem?
    @State private var showAddImagePicker = false
    @State private var showStoryViewer = false
    @State private var storyIndex = 0
    
    @State private var selectedPost: PostModel?
    @State private var selectedActionPost: PostModel?
    @State private var selectedCommentPost: PostModel?
    @State private var showPostActionSheet = false
    @State private var likedPostIds: Set<String> = []
    
    @State private var showFollowersSheet = false
    @State private var showFollowingSheet = false
    @State private var showLikesSheet = false
    
    @State private var followersUsers: [ProfileListUserModel] = []
    @State private var followingUsers: [ProfileListUserModel] = []
    @State private var likedUsers: [ProfileListUserModel] = []
    
    @State private var selectedUserId = ""
    @State private var gotoUserProfile = false
    
    private let gridSpacing: CGFloat = 2
    private let columnsCount = 3
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView(showsIndicators: false) {

                VStack(spacing: 25) {

                    // MARK: Profile Header

                    VStack(spacing: 18) {

                        ZStack(alignment: .bottomTrailing) {

                            PhotosPicker(
                                selection: $selectedProfileItem,
                                matching: .images
                            ) {

                                profileImageView
                                    .frame(width: 120, height: 120)
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
                                                lineWidth: 4
                                            )
                                    )
                                    .shadow(color: .purple.opacity(0.4),
                                            radius: 12)
                            }

                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .offset(x: -4, y: -4)
                        }

                        VStack(spacing: 4) {

                            Text(username)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text(
                                bio.isEmpty ?
                                "No bio yet"
                                : bio
                            )
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        }
                    }

                    // MARK: Stats

                    HStack(spacing: 15) {

                        statCard(
                            value: "\(myPosts.count)",
                            title: "Posts"
                        )

                        Button {

                            fetchFollowersUsers()
                            showFollowersSheet = true

                        } label: {

                            statCard(
                                value: "\(followersCount)",
                                title: "Followers"
                            )
                        }

                        Button {

                            fetchFollowingUsers()
                            showFollowingSheet = true

                        } label: {

                            statCard(
                                value: "\(followingCount)",
                                title: "Following"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // MARK: Buttons

                    HStack(spacing: 12) {

                        Button {

                            newBio = bio
                            showEditBio = true

                        } label: {

                            Text("Edit Profile")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [
                                            .blue,
                                            .purple
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                        }

                        NavigationLink {

                            CreatePostPage()

                        } label: {

                            Image(systemName: "plus")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    highlightsRow

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal)

                    HStack {

                        Spacer()

                        Image(systemName: "square.grid.3x3.fill")
                            .font(.title3)
                            .foregroundColor(.white)

                        Spacer()
                    }

                    postsGrid

                    Button {

                        UserDefaults.standard.removeObject(
                            forKey: "currentUsername"
                        )

                        UserDefaults.standard.removeObject(
                            forKey: "currentUserId"
                        )

                        logout = true

                    } label: {

                        Text("Logout")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color.red.opacity(0.15)
                            )
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    .padding(.bottom,30)

                }
                .padding(.top)
            }
            .background(

                LinearGradient(
                    colors: [
                        Color.black,
                        Color(
                            red: 0.08,
                            green: 0.08,
                            blue: 0.12
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .background(Color.black)
            .navigationDestination(isPresented: $logout) {
                SigninPage()
            }
            .navigationDestination(isPresented: $gotoUserProfile) {
                UserProfilePage(userId: selectedUserId)
            }
            .alert("Edit Bio", isPresented: $showEditBio) {
                
                TextField("Enter Bio", text: $newBio)
                
                Button("Save") {
                    saveBio()
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .alert("New Highlight", isPresented: $showAddHighlightAlert) {
                
                TextField("Highlight title", text: $newHighlightTitle)
                
                Button("Add") {
                    createHighlight()
                }
                
                Button("Cancel", role: .cancel) {
                    newHighlightTitle = ""
                    pendingHighlightImage = nil
                }
                
            } message: {
                Text("Enter a title for this highlight.")
            }
            .confirmationDialog(
                selectedHighlight?.title ?? "Highlight",
                isPresented: $showHighlightActionSheet,
                titleVisibility: .visible
            ) {
                Button("Add Highlight") {
                    showAddImagePicker = true
                }
                
                Button("Delete Highlight", role: .destructive) {
                    deleteHighlight()
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .confirmationDialog(
                "Post",
                isPresented: $showPostActionSheet,
                titleVisibility: .visible
            ) {
                Button("Open Comment") {
                    selectedCommentPost = selectedActionPost
                }
                
                
                Button("Show Likes") {
                    if let post = selectedActionPost {
                        fetchLikedUsers(post: post)
                        showLikesSheet = true
                    }
                }
                
                Button("Remove Post", role: .destructive) {
                    if let post = selectedActionPost {
                        removePost(post)
                    }
                }
                
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showStoryViewer) {
                if let highlight = selectedHighlight {
                    StoryViewerView(
                        highlight: highlight,
                        isPresented: $showStoryViewer
                    )
                }
            }
            .fullScreenCover(item: $selectedPost) { post in
                PostPopupView(
                    post: post,
                    selectedPost: $selectedPost
                )
            }
            .sheet(item: $selectedCommentPost) { post in
                ProfileCommentSheet(
                    post: post,
                    currentUsername: username
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFollowersSheet) {
                ProfileUserListSheet(
                    title: "Followers",
                    users: followersUsers,
                    onTapUser: { userId in
                        showFollowersSheet = false
                        selectedUserId = userId
                        gotoUserProfile = true
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showFollowingSheet) {
                ProfileUserListSheet(
                    title: "Following",
                    users: followingUsers,
                    onTapUser: { userId in
                        showFollowingSheet = false
                        selectedUserId = userId
                        gotoUserProfile = true
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showLikesSheet) {
                ProfileUserListSheet(
                    title: "Liked By",
                    users: likedUsers,
                    onTapUser: { userId in
                        showLikesSheet = false
                        selectedUserId = userId
                        gotoUserProfile = true
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .photosPicker(
                isPresented: $showAddImagePicker,
                selection: $addImageItem,
                matching: .images
            )
            .onAppear {
                fetchCurrentUser()
                fetchMyPosts()
                fetchFollowersCount()
                fetchFollowingCount()
                fetchHighlights()
                fetchLikedPosts()
            }
            .onChange(of: selectedProfileItem) { item in
                
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        uploadProfileImage(uiImage)
                    }
                }
            }
            .onChange(of: selectedHighlightItem) { item in
                
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        pendingHighlightImage = uiImage
                        newHighlightTitle = ""
                        showAddHighlightAlert = true
                    }
                }
            }
            .onChange(of: addImageItem) { item in
                
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        addImageToHighlight(uiImage)
                    }
                }
            }
        }
    }
    func statCard(
        value: String,
        title: String
    ) -> some View {

        VStack(spacing: 6) {

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical,18)
        .background(
            Color.white.opacity(0.06)
        )
        .cornerRadius(18)
    }
    
    private var highlightsRow: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 16) {
                
                PhotosPicker(
                    selection: $selectedHighlightItem,
                    matching: .images
                ) {
                    VStack(spacing: 6) {
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                )
                            
                            if isUploadingHighlight {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 64, height: 64)
                                
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        
                        Text("New")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .disabled(isUploadingHighlight)
                
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
                                storyIndex = 0
                                showStoryViewer = true
                            }
                            .onLongPressGesture {
                                selectedHighlight = highlight
                                showHighlightActionSheet = true
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
    
    private func createHighlight() {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        let trimmedTitle = newHighlightTitle.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedTitle.isEmpty else { return }
        
        guard let image = pendingHighlightImage,
              let imageData = image.jpegData(compressionQuality: 0.3)
        else { return }
        
        isUploadingHighlight = true
        
        let ref = Database.database()
            .reference()
            .child("highlights")
            .child(userId)
            .childByAutoId()
        
        let data: [String: Any] = [
            "title": trimmedTitle,
            "images": [imageData.base64EncodedString()],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        ref.setValue(data) { _, _ in
            isUploadingHighlight = false
        }
        
        newHighlightTitle = ""
        pendingHighlightImage = nil
    }
    
    private func addImageToHighlight(_ image: UIImage) {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId"),
              let highlight = selectedHighlight,
              let imageData = image.jpegData(compressionQuality: 0.3)
        else { return }
        
        var updatedImages = highlight.images
        updatedImages.append(imageData.base64EncodedString())
        
        Database.database()
            .reference()
            .child("highlights")
            .child(userId)
            .child(highlight.id)
            .updateChildValues([
                "images": updatedImages
            ])
    }
    
    private func deleteHighlight() {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId"),
              let highlight = selectedHighlight
        else { return }
        
        Database.database()
            .reference()
            .child("highlights")
            .child(userId)
            .child(highlight.id)
            .removeValue()
    }
    
    private func fetchHighlights() {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
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
                    
                    let images = data["images"] as? [String] ?? []
                    
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
    
    private func uploadProfileImage(_ image: UIImage) {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId"),
              let imageData = image.jpegData(compressionQuality: 0.3)
        else { return }
        
        isUploadingDP = true
        
        let base64String = imageData.base64EncodedString()
        
        Database.database()
            .reference()
            .child("users")
            .child(userId)
            .updateChildValues([
                "profileImage": base64String
            ]) { _, _ in
                isUploadingDP = false
                profileImageBase64 = base64String
            }
    }
    
    private var postsGrid: some View {
        
        GeometryReader { geo in
            
            let totalSpacing = gridSpacing * CGFloat(columnsCount - 1)
            let cellSize = (geo.size.width - totalSpacing) / CGFloat(columnsCount)
            
            if myPosts.isEmpty {
                
                VStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No posts yet")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                
            } else {
                
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: gridSpacing),
                        count: columnsCount
                    ),
                    spacing: gridSpacing
                ) {
                    ForEach(myPosts) { post in
                        postCell(post: post, size: cellSize)
                    }
                }
            }
        }
        .frame(height: gridHeight)
    }
    
    private var gridHeight: CGFloat {
        
        if myPosts.isEmpty { return 140 }
        
        let rows = ceil(Double(myPosts.count) / Double(columnsCount))
        let screenWidth = UIScreen.main.bounds.width - 32
        let totalSpacing = gridSpacing * CGFloat(columnsCount - 1)
        let cellSize = (screenWidth - totalSpacing) / CGFloat(columnsCount)
        
        return CGFloat(rows) * cellSize + CGFloat(rows - 1) * gridSpacing
    }
    
    private func postCell(post: PostModel, size: CGFloat) -> some View {
        
        Group {
            if let imageData = Data(base64Encoded: post.imageURL),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                
            } else {
                Color.gray.opacity(0.2)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .onTapGesture {
            selectedPost = post
        }
        .onLongPressGesture {
            selectedActionPost = post
            showPostActionSheet = true
        }
    }
    
    func toggleLike(post: PostModel) {
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        let ref = Database.database()
            .reference()
            .child("likes")
            .child(post.id)
            .child(currentUserId)
        
        if likedPostIds.contains(post.id) {
            ref.removeValue()
            likedPostIds.remove(post.id)
        } else {
            ref.setValue(true)
            likedPostIds.insert(post.id)
        }
    }
    
    func fetchLikedPosts() {
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        Database.database()
            .reference()
            .child("likes")
            .observe(.value) { snapshot in
                
                var temp: Set<String> = []
                
                for child in snapshot.children {
                    
                    guard let postSnap = child as? DataSnapshot
                    else { continue }
                    
                    if postSnap.hasChild(currentUserId) {
                        temp.insert(postSnap.key)
                    }
                }
                
                likedPostIds = temp
            }
    }
    
    func fetchLikedUsers(post: PostModel) {
        
        Database.database()
            .reference()
            .child("likes")
            .child(post.id)
            .observeSingleEvent(of: .value) { snapshot in
                
                fetchUsersFromSnapshot(snapshot) { users in
                    likedUsers = users
                }
            }
    }
    
    func removePost(_ post: PostModel) {
        
        Database.database()
            .reference()
            .child("posts")
            .child(post.id)
            .removeValue()
        
        Database.database()
            .reference()
            .child("likes")
            .child(post.id)
            .removeValue()
        
        Database.database()
            .reference()
            .child("comments")
            .child(post.id)
            .removeValue()
        
        myPosts.removeAll {
            $0.id == post.id
        }
    }
    
    func fetchFollowersUsers() {
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        Database.database()
            .reference()
            .child("followers")
            .child(currentUserId)
            .observeSingleEvent(of: .value) { snapshot in
                
                fetchUsersFromSnapshot(snapshot) { users in
                    followersUsers = users
                }
            }
    }
    
    func fetchFollowingUsers() {
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        Database.database()
            .reference()
            .child("following")
            .child(currentUserId)
            .observeSingleEvent(of: .value) { snapshot in
                
                fetchUsersFromSnapshot(snapshot) { users in
                    followingUsers = users
                }
            }
    }
    
    func fetchUsersFromSnapshot(
        _ snapshot: DataSnapshot,
        completion: @escaping ([ProfileListUserModel]) -> Void
    ) {
        
        var tempUsers: [ProfileListUserModel] = []
        let group = DispatchGroup()
        
        for child in snapshot.children {
            
            guard let snap = child as? DataSnapshot
            else { continue }
            
            let userId = snap.key
            
            group.enter()
            
            Database.database()
                .reference()
                .child("users")
                .child(userId)
                .observeSingleEvent(of: .value) { userSnap in
                    
                    if let data = userSnap.value as? [String: Any] {
                        
                        tempUsers.append(
                            ProfileListUserModel(
                                id: userId,
                                username: data["username"] as? String ?? "",
                                fullname: data["fullname"] as? String ?? "",
                                profileImage: data["profileImage"] as? String ?? ""
                            )
                        )
                    }
                    
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            completion(tempUsers.sorted { $0.username < $1.username })
        }
    }
    
    func fetchFollowersCount() {
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        Database.database()
            .reference()
            .child("followers")
            .child(currentUserId)
            .observe(.value) { snapshot in
                followersCount = Int(snapshot.childrenCount)
            }
    }
    
    func fetchFollowingCount() {
        
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        Database.database()
            .reference()
            .child("following")
            .child(currentUserId)
            .observe(.value) { snapshot in
                followingCount = Int(snapshot.childrenCount)
            }
    }
    
    func statView(count: String, title: String) -> some View {
        
        VStack(spacing: 2) {
            Text(count)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }
    
    func saveBio() {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId")
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
    
    func fetchCurrentUser() {
        
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        Database.database()
            .reference()
            .child("users")
            .child(userId)
            .observeSingleEvent(of: .value) { snapshot in
                
                guard let data = snapshot.value as? [String: Any]
                else { return }
                
                username = data["username"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                profileImageBase64 = data["profileImage"] as? String ?? ""
            }
    }
    
    func fetchMyPosts() {
        
        let currentUserId =
        UserDefaults.standard.string(forKey: "currentUserId") ?? ""
        
        Database.database()
            .reference()
            .child("posts")
            .observe(.value, with: { snapshot in
                
                var tempPosts: [PostModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    let userId = data["userId"] as? String ?? ""
                    
                    if userId == currentUserId {
                        
                        tempPosts.append(
                            PostModel(
                                id: snap.key,
                                userId: userId,
                                username: data["username"] as? String ?? "",
                                imageURL: data["imageURL"] as? String ?? "",
                                caption: data["caption"] as? String ?? ""
                            )
                        )
                    }
                }
                
                myPosts = tempPosts.reversed()
            })
    }
}

// MARK: - User List Sheet

struct ProfileUserListSheet: View {
    
    let title: String
    let users: [ProfileListUserModel]
    let onTapUser: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Divider()
                    .background(Color.gray)
                
                ScrollView {
                    
                    LazyVStack(spacing: 14) {
                        
                        ForEach(users) { user in
                            
                            Button {
                                onTapUser(user.id)
                            } label: {
                                
                                HStack(spacing: 12) {
                                    
                                    userDP(user.profileImage)
                                        .frame(width: 46, height: 46)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        
                                        Text(user.username)
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .semibold))
                                        
                                        Text(user.fullname)
                                            .foregroundColor(.gray)
                                            .font(.system(size: 13))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    @ViewBuilder
    private func userDP(_ base64Image: String) -> some View {
        
        if let imageData = Data(base64Encoded: base64Image),
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

// MARK: - Profile Comment Sheet

struct ProfileCommentSheet: View {
    
    let post: PostModel
    let currentUsername: String
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var comments: [ProfileCommentModel] = []
    @State private var commentText = ""
    @State private var userProfileImages: [String: String] = [:]
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    Text("Comments")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                Divider()
                    .background(Color.gray)
                
                ScrollView {
                    
                    LazyVStack(alignment: .leading, spacing: 14) {
                        
                        ForEach(comments) { comment in
                            
                            HStack(alignment: .top, spacing: 10) {
                                
                                commentUserDP(userId: comment.userId)
                                    .frame(width: 34, height: 34)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(comment.username)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(comment.text)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                
                HStack {
                    
                    TextField("Add a comment...", text: $commentText)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.25))
                        .cornerRadius(22)
                    
                    Button {
                        addComment()
                    } label: {
                        Text("Post")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .onAppear {
            fetchComments()
            fetchUserProfileImages()
        }
    }
    
    @ViewBuilder
    private func commentUserDP(userId: String) -> some View {
        
        let base64Image = userProfileImages[userId] ?? ""
        
        if let imageData = Data(base64Encoded: base64Image),
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
    
    func addComment() {
        
        let trimmedText = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty,
              let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        else { return }
        
        let ref = Database.database()
            .reference()
            .child("comments")
            .child(post.id)
            .childByAutoId()
        
        let data: [String: Any] = [
            "userId": currentUserId,
            "username": currentUsername,
            "text": trimmedText,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        ref.setValue(data)
        commentText = ""
    }
    
    func fetchComments() {
        
        Database.database()
            .reference()
            .child("comments")
            .child(post.id)
            .observe(.value) { snapshot in
                
                var temp: [ProfileCommentModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    temp.append(
                        ProfileCommentModel(
                            id: snap.key,
                            userId: data["userId"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            text: data["text"] as? String ?? "",
                            timestamp: data["timestamp"] as? Double ?? 0
                        )
                    )
                }
                
                comments = temp.sorted {
                    $0.timestamp < $1.timestamp
                }
            }
    }
    
    func fetchUserProfileImages() {
        
        Database.database()
            .reference()
            .child("users")
            .observe(.value) { snapshot in
                
                var temp: [String: String] = [:]
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    temp[snap.key] = data["profileImage"] as? String ?? ""
                }
                
                userProfileImages = temp
            }
    }
}

// MARK: - Story Viewer

struct StoryViewerView: View {
    
    let highlight: HighlightModel
    @Binding var isPresented: Bool
    
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
            
            if currentIndex < highlight.images.count,
               let imageData = Data(base64Encoded: highlight.images[currentIndex]),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                
            } else {
                Text("No image")
                    .foregroundColor(.white)
            }
            
            VStack {
                
                HStack(spacing: 4) {
                    
                    ForEach(0..<highlight.images.count, id: \.self) { index in
                        
                        Capsule()
                            .fill(index <= currentIndex ? Color.white : Color.white.opacity(0.3))
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
                        isPresented = false
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
            isPresented = false
        }
    }
    
    private func goToPrevious() {
        
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}

// MARK: - Post Popup View

struct PostPopupView: View {
    
    let post: PostModel
    @Binding var selectedPost: PostModel?
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
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
}

#Preview {
    ProfilePage()
}

//
//  homePage.swift
//  ChatApp
//
//  Created by CDMI on 28/05/26.
//

import SwiftUI
import FirebaseDatabase
import PhotosUI

struct StoryModel: Identifiable {
    
    let id: String
    let imageURL: String
    let timestamp: Double
}

struct StoryUserModel: Identifiable {
    
    let id: String
    let username: String
    let profileImage: String
    let stories: [StoryModel]
}

struct CommentModel: Identifiable {
    
    let id: String
    let userId: String
    let username: String
    let text: String
    let timestamp: Double
}

struct HomePage: View {
    
    @State private var posts: [PostModel] = []
    @State private var selectedPost: PostModel?
    @State private var selectedCommentPost: PostModel?
    
    @State private var likedPostIds: Set<String> = []
    @State private var likeCounts: [String: Int] = [:]
    @State private var commentCounts: [String: Int] = [:]
    
    @State private var userProfileImages: [String: String] = [:]
    @State private var usernames: [String: String] = [:]
    
    @State private var storyUsers: [StoryUserModel] = []
    @State private var seenStoryIds: Set<String> = []
    @State private var selectedStoryUser: StoryUserModel?
    
    @State private var selectedStoryItem: PhotosPickerItem?
    @State private var showDeleteStoryDialog = false
    
    @State private var gotoRequests = false
    
    // MARK: UI-only animation state
    @State private var reloadRotation: Double = 0
    @State private var heartBurstPostId: String? = nil
    @State private var headerAppear = false
    
    // MARK: Initial load state
    @State private var isInitialLoading = true
    @State private var spinnerRotation: Double = 0
    
    @State private var selectedSharePost: PostModel?
    
    var body: some View {
        
        NavigationStack {
            GeometryReader { geo in
                
                let screenWidth = geo.size.width
                
                ZStack(alignment: .top) {
                    
                    backgroundGradient
                    
                    if isInitialLoading {
                        
                        loadingView
                            .transition(.opacity)
                        
                    } else {
                        
                        VStack(spacing: 0) {
                            
                            header(screenWidth: screenWidth)
                                .opacity(headerAppear ? 1 : 0)
                                .offset(y: headerAppear ? 0 : -10)
                                .onAppear {
                                    withAnimation(.easeOut(duration: 0.4)) {
                                        headerAppear = true
                                    }
                                }
                            
                            ScrollView {
                                
                                VStack(spacing: 0) {
                                    
                                    storiesRow(screenWidth: screenWidth)
                                    
                                    fancyDivider
                                    
                                    LazyVStack(spacing: screenWidth * 0.07) {
                                        
                                        ForEach(posts) { post in
                                            
                                            postCard(
                                                post: post,
                                                screenWidth: screenWidth
                                            )
                                            .transition(
                                                .asymmetric(
                                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                                    removal: .opacity
                                                )
                                            )
                                        }
                                    }
                                    .padding(.top, 14)
                                    .padding(.bottom, 30)
                                    .animation(.easeOut(duration: 0.35), value: posts.map { $0.id })
                                }
                            }
                            .refreshable {
                                
                                await performReload()
                            }
                        }
                        .transition(.opacity)
                    }
                }
            }
            .onAppear {
                
                loadInitialData()
            }
            .onChange(of: selectedStoryItem) { item in
                
                Task {
                    
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        
                        uploadStory(uiImage)
                    }
                }
            }
            .navigationDestination(
                isPresented: $gotoRequests
            ) {
                
                FollowRequestsPage()
            }
            .fullScreenCover(item: $selectedStoryUser) { storyUser in
                
                HomeStoryViewer(
                    storyUser: storyUser,
                    selectedStoryUser: $selectedStoryUser,
                    onSeenStory: { storyId in
                        
                        markStoryAsSeen(storyId: storyId)
                    }
                )
            }
            .fullScreenCover(item: $selectedPost) { post in
                
                HomePostPopupView(
                    post: post,
                    profileImageBase64: userProfileImages[post.userId] ?? "",
                    selectedPost: $selectedPost
                )
            }
            .sheet(item: $selectedCommentPost) { post in
                
                HomeCommentSheet(
                    post: post,
                    currentUserId: currentUserId,
                    currentUsername: usernames[currentUserId] ?? "user",
                    userProfileImages: userProfileImages
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
            }
            .confirmationDialog(
                "Story",
                isPresented: $showDeleteStoryDialog,
                titleVisibility: .visible
            ) {
                
                Button(
                    "Delete",
                    role: .destructive
                ) {
                    deleteMyStories()
                }
                
                Button(
                    "Cancel",
                    role: .cancel
                ) { }
            }
            .sheet(item: $selectedSharePost) { post in

                SharePostSheet(post: post)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var currentUserId: String {
        
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
    }
    
    // MARK: Background
    
    private var backgroundGradient: some View {
        
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.06, green: 0.05, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: Loading View (shown while data first loads)
    
    private var loadingView: some View {
        
        VStack(spacing: 18) {
            
            Spacer()
            
            Text("Pulse")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ZStack {
                
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 42, height: 42)
                
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(spinnerRotation))
                    .onAppear {
                        
                        withAnimation(
                            .linear(duration: 0.9)
                            .repeatForever(autoreverses: false)
                        ) {
                            spinnerRotation = 360
                        }
                    }
            }
            
            Text("Loading your feed...")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: Load Initial Data (with min-display guard so it doesn't blink)
    
    private func loadInitialData() {
        
        isInitialLoading = true
        
        fetchPosts()
        fetchLikes()
        fetchCommentsCount()
        fetchUserProfileImages()
        fetchSeenStories()
        fetchStories()
        
        // Give listeners a brief moment to receive first data,
        // then reveal the feed with a smooth fade instead of a blank flash.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            
            withAnimation(.easeOut(duration: 0.4)) {
                isInitialLoading = false
            }
        }
    }
    
    // MARK: Header
    
    private func header(screenWidth: CGFloat) -> some View {
        
        HStack {
            
            PhotosPicker(
                selection: $selectedStoryItem,
                matching: .images
            ) {
                
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Pulse")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            Button {
                gotoRequests = true
            } label: {
                
                Image(systemName: "heart")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
    
    private var fancyDivider: some View {
        
        LinearGradient(
            colors: [.clear, Color.white.opacity(0.15), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.top, 10)
    }
    
    // MARK: Pull to Reload
    
    private func performReload() async {
        
        withAnimation(.linear(duration: 0.6)) {
            reloadRotation += 360
        }
        
        fetchPosts()
        fetchLikes()
        fetchCommentsCount()
        fetchUserProfileImages()
        fetchSeenStories()
        fetchStories()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    // MARK: Stories Row
    
    private func storiesRow(screenWidth: CGFloat) -> some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: screenWidth * 0.045) {
                
                myStoryCircle(screenWidth: screenWidth)
                
                ForEach(storyUsers) { storyUser in
                    
                    if storyUser.id != currentUserId {
                        
                        storyCircle(
                            storyUser: storyUser,
                            screenWidth: screenWidth
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 14)
    }
    
    // MARK: My Story Circle
    
    private func myStoryCircle(screenWidth: CGFloat) -> some View {
        
        let myStories =
        storyUsers.first {
            $0.id == currentUserId
        }
        
        let outerSize = screenWidth * 0.19
        let innerSize = outerSize - 9
        
        return VStack(spacing: 6) {
            
            ZStack {
                
                Circle()
                    .stroke(
                        storyRingGradient(
                            stories: myStories?.stories ?? []
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: outerSize, height: outerSize)
                
                loginUserDP
                    .frame(width: innerSize, height: innerSize)
                    .clipShape(Circle())
                
                if myStories == nil {
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: outerSize * 0.32, y: outerSize * 0.32)
                }
            }
            .onTapGesture {
                
                if let myStories {
                    selectedStoryUser = myStories
                }
            }
            .onLongPressGesture {
                
                if myStories != nil {
                    showDeleteStoryDialog = true
                }
            }
            
            Text("Your story")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
    }
    
    // MARK: Other User Story Circle
    
    private func storyCircle(
        storyUser: StoryUserModel,
        screenWidth: CGFloat
    ) -> some View {
        
        let outerSize = screenWidth * 0.19
        let innerSize = outerSize - 9
        
        return VStack(spacing: 6) {
            
            Circle()
                .stroke(
                    storyRingGradient(
                        stories: storyUser.stories
                    ),
                    lineWidth: 2.5
                )
                .frame(width: outerSize, height: outerSize)
                .overlay {
                    
                    storyUserDP(storyUser.profileImage)
                        .frame(width: innerSize, height: innerSize)
                        .clipShape(Circle())
                }
                .onTapGesture {
                    
                    selectedStoryUser = storyUser
                }
            
            Text(storyUser.username)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .frame(width: outerSize)
        }
    }
    
    // MARK: Story Ring Color
    
    private func storyRingGradient(
        stories: [StoryModel]
    ) -> LinearGradient {
        
        if stories.isEmpty {
            
            return LinearGradient(
                colors: [.gray.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        let allSeen =
        stories.allSatisfy {
            seenStoryIds.contains($0.id)
        }
        
        if allSeen {
            
            return LinearGradient(
                colors: [.gray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return LinearGradient(
            colors: [.purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: Login User DP
    
    @ViewBuilder
    private var loginUserDP: some View {
        
        let base64Image = userProfileImages[currentUserId] ?? ""
        
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
    
    // MARK: Story User DP
    
    @ViewBuilder
    private func storyUserDP(_ base64Image: String) -> some View {
        
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
    
    // MARK: Upload Story
    
    func uploadStory(_ image: UIImage) {
        
        guard !currentUserId.isEmpty else { return }
        
        guard let imageData =
                image.jpegData(compressionQuality: 0.3)
        else { return }
        
        let base64String =
        imageData.base64EncodedString()
        
        let ref = Database.database()
            .reference()
            .child("stories")
            .child(currentUserId)
            .childByAutoId()
        
        let data: [String: Any] = [
            
            "imageURL": base64String,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        ref.setValue(data)
    }
    
    // MARK: Fetch Stories
    
    func fetchStories() {
        
        Database.database()
            .reference()
            .child("stories")
            .observe(.value) { snapshot in
                
                var tempStoryUsers: [StoryUserModel] = []
                let now = Date().timeIntervalSince1970
                let twentyFourHours: Double = 24 * 60 * 60
                
                for child in snapshot.children {
                    
                    guard let userSnap = child as? DataSnapshot
                    else { continue }
                    
                    let userId = userSnap.key
                    var tempStories: [StoryModel] = []
                    
                    for storyChild in userSnap.children {
                        
                        guard let storySnap =
                                storyChild as? DataSnapshot,
                              let data =
                                storySnap.value as? [String: Any]
                        else { continue }
                        
                        let timestamp =
                        data["timestamp"] as? Double ?? 0
                        
                        if now - timestamp >= twentyFourHours {
                            
                            Database.database()
                                .reference()
                                .child("stories")
                                .child(userId)
                                .child(storySnap.key)
                                .removeValue()
                            
                        } else {
                            
                            tempStories.append(
                                StoryModel(
                                    id: storySnap.key,
                                    imageURL: data["imageURL"] as? String ?? "",
                                    timestamp: timestamp
                                )
                            )
                        }
                    }
                    
                    if !tempStories.isEmpty {
                        
                        let storyUser = StoryUserModel(
                            id: userId,
                            username: usernames[userId] ?? "user",
                            profileImage: userProfileImages[userId] ?? "",
                            stories: tempStories.sorted {
                                $0.timestamp < $1.timestamp
                            }
                        )
                        
                        tempStoryUsers.append(storyUser)
                    }
                }
                
                storyUsers = tempStoryUsers.sorted {
                    
                    if $0.id == currentUserId { return true }
                    if $1.id == currentUserId { return false }
                    return $0.username < $1.username
                }
            }
    }
    
    
    
    
    // MARK: Seen Stories
    
    func fetchSeenStories() {
        
        guard !currentUserId.isEmpty else { return }
        
        Database.database()
            .reference()
            .child("storyViews")
            .child(currentUserId)
            .observe(.value) { snapshot in
                
                var tempSeen: Set<String> = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot
                    else { continue }
                    
                    tempSeen.insert(snap.key)
                }
                
                seenStoryIds = tempSeen
            }
    }
    
    func markStoryAsSeen(storyId: String) {
        
        guard !currentUserId.isEmpty else { return }
        
        seenStoryIds.insert(storyId)
        
        Database.database()
            .reference()
            .child("storyViews")
            .child(currentUserId)
            .child(storyId)
            .setValue(true)
    }
    
    // MARK: Delete My Stories
    
    func deleteMyStories() {
        
        guard !currentUserId.isEmpty else { return }
        
        Database.database()
            .reference()
            .child("stories")
            .child(currentUserId)
            .removeValue()
    }
    
    // MARK: Post Card
    
    private func postCard(
        post: PostModel,
        screenWidth: CGFloat
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            HStack(spacing: 10) {
                
                postProfileImage(for: post)
                    .frame(
                        width: screenWidth * 0.095,
                        height: screenWidth * 0.095
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                
                Text(post.username)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            
            ZStack {
                
                postImage(for: post)
                    .frame(width: screenWidth, height: screenWidth)
                    .clipped()
                    .onTapGesture(count: 2) {
                        
                        doubleTapLike(post: post)
                    }
                    .onTapGesture {
                        
                        selectedPost = post
                    }
                
                if heartBurstPostId == post.id {
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                        .scaleEffect(heartBurstPostId == post.id ? 1 : 0.4)
                        .opacity(heartBurstPostId == post.id ? 1 : 0)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            HStack(spacing: 18) {
                
                Button {
                    
                    toggleLike(post: post)
                    
                } label: {
                    
                    Image(
                        systemName:
                            likedPostIds.contains(post.id)
                        ? "heart.fill"
                        : "heart"
                    )
                    .font(.system(size: 23))
                    .foregroundColor(
                        likedPostIds.contains(post.id)
                        ? .red
                        : .white
                    )
                    .scaleEffect(likedPostIds.contains(post.id) ? 1.05 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: likedPostIds.contains(post.id))
                }
                
                Button {
                    
                    selectedCommentPost = post
                    
                } label: {
                    
                    Image(systemName: "bubble.right")
                        .font(.system(size: 21))
                        .foregroundColor(.white)
                }
                
                Button {

                    selectedSharePost = post

                } label: {

                    Image(systemName: "paperplane")
                        .font(.system(size: 21))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            
            if (likeCounts[post.id] ?? 0) > 0 {
                
                Text("\(likeCounts[post.id] ?? 0) likes")
                    .foregroundColor(.white)
                    .font(.system(size: 13.5, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
            }
            
            if !post.caption.isEmpty {
                
                HStack(spacing: 4) {
                    
                    Text(post.username)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(post.caption)
                        .font(.system(size: 13.5))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
            }
            
            Button {
                
                selectedCommentPost = post
                
            } label: {
                
                Text(
                    (commentCounts[post.id] ?? 0) == 0
                    ? "Add a comment"
                    : "View all \(commentCounts[post.id] ?? 0) comments"
                )
                .foregroundColor(.white.opacity(0.5))
                .font(.system(size: 13))
                .padding(.horizontal, 14)
                .padding(.top, 5)
                .padding(.bottom, 12)
            }
        }
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 8)
    }
    
    // MARK: Double Tap Like Animation
    
    private func doubleTapLike(post: PostModel) {
        
        if !likedPostIds.contains(post.id) {
            
            toggleLike(post: post)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            heartBurstPostId = post.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            
            withAnimation(.easeOut(duration: 0.3)) {
                
                if heartBurstPostId == post.id {
                    heartBurstPostId = nil
                }
            }
        }
    }
    
    // MARK: Post User DP
    
    @ViewBuilder
    private func postProfileImage(for post: PostModel) -> some View {
        
        let base64Image = userProfileImages[post.userId] ?? ""
        
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
    
    // MARK: Post Image
    
    @ViewBuilder
    private func postImage(for post: PostModel) -> some View {
        
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
    
    // MARK: Likes
    
    func toggleLike(post: PostModel) {
        
        guard !currentUserId.isEmpty else { return }
        
        let ref = Database.database()
            .reference()
            .child("likes")
            .child(post.id)
            .child(currentUserId)
        
        if likedPostIds.contains(post.id) {
            
            ref.removeValue()
            
        } else {
            
            ref.setValue(true)
        }
    }
    
    func fetchLikes() {
        
        Database.database()
            .reference()
            .child("likes")
            .observe(.value) { snapshot in
                
                var tempLikeCounts: [String: Int] = [:]
                var tempLikedPostIds: Set<String> = []
                
                for child in snapshot.children {
                    
                    guard let postSnap = child as? DataSnapshot
                    else { continue }
                    
                    tempLikeCounts[postSnap.key] =
                    Int(postSnap.childrenCount)
                    
                    if postSnap.hasChild(currentUserId) {
                        
                        tempLikedPostIds.insert(postSnap.key)
                    }
                }
                
                likeCounts = tempLikeCounts
                likedPostIds = tempLikedPostIds
            }
    }
    
    // MARK: Comments Count
    
    func fetchCommentsCount() {
        
        Database.database()
            .reference()
            .child("comments")
            .observe(.value) { snapshot in
                
                var tempCommentCounts: [String: Int] = [:]
                
                for child in snapshot.children {
                    
                    guard let postSnap = child as? DataSnapshot
                    else { continue }
                    
                    tempCommentCounts[postSnap.key] =
                    Int(postSnap.childrenCount)
                }
                
                commentCounts = tempCommentCounts
            }
    }
    
    // MARK: Fetch Posts
    
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
    
    // MARK: Fetch User Profile Images
    
    func fetchUserProfileImages() {
        
        Database.database()
            .reference()
            .child("users")
            .observe(.value) { snapshot in
                
                var tempImages: [String: String] = [:]
                var tempUsernames: [String: String] = [:]
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    tempImages[snap.key] =
                    data["profileImage"] as? String ?? ""
                    
                    tempUsernames[snap.key] =
                    data["username"] as? String ?? "user"
                }
                
                userProfileImages = tempImages
                usernames = tempUsernames
                
                fetchStories()
            }
    }
}

// MARK: - Comment Sheet

struct HomeCommentSheet: View {
    
    let post: PostModel
    let currentUserId: String
    let currentUsername: String
    let userProfileImages: [String: String]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var comments: [CommentModel] = []
    @State private var commentText = ""
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                
                HStack {
                    
                    Text("Comments")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 22))
                    }
                }
                .padding()
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                ScrollView {
                    
                    LazyVStack(alignment: .leading, spacing: 18) {
                        
                        if comments.isEmpty {
                            
                            VStack(spacing: 8) {
                                
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("No comments yet")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 14))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                            
                        } else {
                            
                            ForEach(comments) { comment in
                                
                                HStack(alignment: .top, spacing: 10) {
                                    
                                    commentUserDP(userId: comment.userId)
                                        .frame(width: 34, height: 34)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        
                                        Text(comment.username)
                                            .font(.system(size: 13.5, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(comment.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
                
                HStack(spacing: 10) {
                    
                    TextField(
                        "Add a comment...",
                        text: $commentText
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    
                    Button {
                        
                        addComment()
                        
                    } label: {
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(
                                commentText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? .white.opacity(0.25)
                                : .blue
                            )
                    }
                    .disabled(
                        commentText.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }
                .padding()
            }
        }
        .onAppear {
            fetchComments()
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
        
        let trimmedText =
        commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty,
              !currentUserId.isEmpty
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
                
                var tempComments: [CommentModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    tempComments.append(
                        CommentModel(
                            id: snap.key,
                            userId: data["userId"] as? String ?? "",
                            username: data["username"] as? String ?? "",
                            text: data["text"] as? String ?? "",
                            timestamp: data["timestamp"] as? Double ?? 0
                        )
                    )
                }
                
                comments = tempComments.sorted {
                    $0.timestamp < $1.timestamp
                }
            }
    }
}

// MARK: - Post Popup View

struct HomePostPopupView: View {
    
    let post: PostModel
    let profileImageBase64: String
    @Binding var selectedPost: PostModel?
    
    @State private var appear = false
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    
                    postUserDP
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    Text(post.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        
                        selectedPost = nil
                        
                    } label: {
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.5))
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 6)
                        .scaleEffect(appear ? 1 : 0.9)
                        .opacity(appear ? 1 : 0)
                        .onAppear {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appear = true
                            }
                        }
                    
                } else {
                    
                    Text("No image")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if !post.caption.isEmpty {
                    
                    Text(post.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private var postUserDP: some View {
        
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
struct SharePostSheet: View {

    let post: PostModel

    @Environment(\.dismiss) var dismiss

    @State private var users: [UserModel] = []

    struct UserModel: Identifiable {

        let id: String
        let username: String
        let profileImage: String
    }

    let currentUserId =
        UserDefaults.standard.string(forKey: "currentUserId") ?? ""

    var body: some View {

        NavigationStack {

            List(users) { user in

                Button {

                    sendPost(to: user.id)

                    dismiss()

                } label: {

                    HStack {

                        if let data = Data(base64Encoded: user.profileImage),
                           let image = UIImage(data: data) {

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())

                        } else {

                            Image("profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())
                        }

                        Text(user.username)

                        Spacer()

                        Image(systemName: "paperplane.fill")
                    }
                }
            }
            .navigationTitle("Share")
            .onAppear {
                fetchUsers()
            }
        }
    }
   

       func sendPost(to receiverId: String) {

           let roomId = createRoomId(
               user1: currentUserId,
               user2: receiverId
           )

           let ref = Database.database()
               .reference()
               .child("chats")
               .child(roomId)
               .childByAutoId()

           ref.setValue([
               "senderId": currentUserId,
               "receiverId": receiverId,
               "type": "post",
               "postId": post.id,
               "postImage": post.imageURL,
               "postCaption": post.caption,
               "postUsername": post.username,
               "timestamp": Date().timeIntervalSince1970
           ])
       }
    func createRoomId(user1: String, user2: String) -> String {
        return [user1, user2].sorted().joined(separator: "_")
    }
    func fetchUsers() {

        Database.database()
            .reference()
            .child("followers")
            .child(currentUserId)
            .observeSingleEvent(of: .value) { snapshot in

                var temp: [UserModel] = []

                for child in snapshot.children {

                    guard let snap = child as? DataSnapshot else { continue }

                    let userId = snap.key

                    let roomId = createRoomId(
                        user1: currentUserId,
                        user2: userId
                    )

                    Database.database()
                        .reference()
                        .child("chats")
                        .child(roomId)
                        .observeSingleEvent(of: .value) { chatSnap in

                            if chatSnap.exists() {

                                Database.database()
                                    .reference()
                                    .child("users")
                                    .child(userId)
                                    .observeSingleEvent(of: .value) { userSnap in

                                        guard let data = userSnap.value as? [String: Any] else { return }

                                        temp.append(
                                            UserModel(
                                                id: userId,
                                                username: data["username"] as? String ?? "",
                                                profileImage: data["profileImage"] as? String ?? ""
                                            )
                                        )

                                        users = temp.sorted {
                                            $0.username < $1.username
                                        }
                                    }
                            }
                        }
                }
            }
    }
}

// MARK: - Story Viewer

struct HomeStoryViewer: View {
    
    let storyUser: StoryUserModel
    @Binding var selectedStoryUser: StoryUserModel?
    let onSeenStory: (String) -> Void
    
    @State private var currentIndex = 0
    
    private let timer = Timer.publish(
        every: 5,
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            if storyUser.stories.indices.contains(currentIndex),
               let imageData = Data(base64Encoded: storyUser.stories[currentIndex].imageURL),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                
                Text("Image not found")
                    .foregroundColor(.white)
            }
            
            LinearGradient(
                colors: [Color.black.opacity(0.5), .clear, Color.black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                
                HStack(spacing: 4) {
                    
                    ForEach(0..<max(storyUser.stories.count, 1), id: \.self) { index in
                        
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
                
                HStack(spacing: 10) {
                    
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    Text(storyUser.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        selectedStoryUser = nil
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
        .onAppear {
            markCurrentStorySeen()
        }
        .onChange(of: currentIndex) { _ in
            markCurrentStorySeen()
        }
        .onReceive(timer) { _ in
            goToNext()
        }
    }
    
    private func markCurrentStorySeen() {
        
        if storyUser.stories.indices.contains(currentIndex) {
            
            onSeenStory(storyUser.stories[currentIndex].id)
        }
    }
    
    private func goToNext() {
        
        if currentIndex < storyUser.stories.count - 1 {
            currentIndex += 1
        } else {
            selectedStoryUser = nil
        }
    }
    
    private func goToPrevious() {
        
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}

#Preview {
    HomePage()
}

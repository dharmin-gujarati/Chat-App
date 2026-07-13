//
//  MessagePage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI
import FirebaseDatabase

struct MessagePage: View {
    
    @State private var showProfilePage = false
    
    @State private var username = ""
    @State private var searchText = ""
    
    @State private var users: [UserModel] = []
    @State private var filteredUsers: [UserModel] = []
    
    @State private var chatUsers: [ChatUser] = []
    @State private var userProfileImages: [String: String] = [:]
    
    @State private var gotoChat = false
    @State private var selectedUserId = ""
    @State private var selectedUsername = ""
    
    @State private var isRefreshing = false
    
    // MARK: Initial load state
    @State private var isInitialLoading = true
    @State private var spinnerRotation: Double = 0
    @State private var headerAppear = false
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                backgroundGradient
                
                if isInitialLoading {
                    
                    loadingView
                        .transition(.opacity)
                    
                } else {
                    
                    VStack(spacing: 0) {
                        
                        header
                            .opacity(headerAppear ? 1 : 0)
                            .offset(y: headerAppear ? 0 : -10)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    headerAppear = true
                                }
                            }
                        
                        searchBar
                        
                        if !searchText.isEmpty {
                            
                            searchResultsList
                            
                        } else {
                            
                            chatListSection
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .transition(.opacity)
                }
            }
            .navigationDestination(
                isPresented: $showProfilePage
            ) {
                
                UserProfilePage(
                    userId: selectedUserId
                )
            }
            .navigationDestination(
                isPresented: $gotoChat
            ) {
                OpenMassegPage(
                    profileName: selectedUsername,
                    otherUserId: selectedUserId
                )
            }
        }
        .onAppear {
            
            loadInitialData()
        }
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
    
    // MARK: Loading View
    
    private var loadingView: some View {
        
        VStack(spacing: 18) {
            
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 30))
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
            
            Text("Loading messages...")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: Load Initial Data
    
    private func loadInitialData() {
        
        isInitialLoading = true
        
        fetchCurrentUser()
        fetchUsers()
        fetchChats()
        fetchUserProfileImages()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            
            withAnimation(.easeOut(duration: 0.4)) {
                isInitialLoading = false
            }
        }
    }
    
    // MARK: Header
    
    private var header: some View {
        
        HStack {
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(username)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Messages")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
    
    // MARK: Search Bar
    
    private var searchBar: some View {
        
        HStack(spacing: 8) {
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
                .font(.system(size: 15))
            
            TextField(
                "Search username",
                text: $searchText
            )
            .foregroundColor(.white)
            .font(.system(size: 15))
            .onChange(of: searchText) { value in
                
                searchUsers(text: value)
            }
            
            if !searchText.isEmpty {
                
                Button {
                    
                    searchText = ""
                    searchUsers(text: "")
                    
                } label: {
                    
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    // MARK: Search Results List
    
    private var searchResultsList: some View {
        
        ScrollView {
            
            LazyVStack(spacing: 4) {
                
                if filteredUsers.isEmpty {
                    
                    VStack(spacing: 10) {
                        
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No users found")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                    
                } else {
                    
                    ForEach(filteredUsers) { user in
                        
                        Button {
                            
                            selectedUserId = user.id
                            selectedUsername = user.username
                            
                            checkFollowStatus(userId: user.id)
                            
                        } label: {
                            
                            HStack(spacing: 12) {
                                
                                userDP(userId: user.id)
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                
                                VStack(
                                    alignment: .leading,
                                    spacing: 2
                                ) {
                                    
                                    Text(user.username)
                                        .font(.system(size: 14.5, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(user.fullname)
                                        .font(.system(size: 12.5))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: Chat List Section
    
    private var chatListSection: some View {
        
        VStack(spacing: 0) {
            
            if isRefreshing {
                
                HStack(spacing: 8) {
                    
                    ProgressView()
                        .tint(.white)
                    
                    Text("Refreshing...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 8)
                .transition(.opacity)
            }
            
            if chatUsers.isEmpty && !isRefreshing {
                
                emptyChatsState
                
            } else {
                
                ScrollView {
                    
                    LazyVStack(spacing: 4) {
                        
                        ForEach(chatUsers) { user in
                            
                            Button {
                                
                                selectedUserId = user.id
                                selectedUsername = user.username
                                gotoChat = true
                                
                            } label: {
                                
                                chatRow(user)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    
                    await refreshChats()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isRefreshing)
    }
    
    // MARK: Chat Row
    
    private func chatRow(_ user: ChatUser) -> some View {
        
        HStack(spacing: 12) {
            
            userDP(userId: user.id)
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                
                Text(user.username)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(
                    user.lastMessage.isEmpty
                    ? "Say hi 👋"
                    : user.lastMessage
                )
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
    }
    
    // MARK: Empty Chats State
    
    private var emptyChatsState: some View {
        
        VStack(spacing: 14) {
            
            Spacer()
            
            ZStack {
                
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("No messages yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Search a username above to\nstart a conversation.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: User DP
    
    @ViewBuilder
    private func userDP(userId: String) -> some View {
        
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
    
    // MARK: Fetch User Profile Images
    
    func fetchUserProfileImages() {
        
        Database.database()
            .reference()
            .child("users")
            .observe(.value) { snapshot in
                
                var tempImages: [String: String] = [:]
                
                for child in snapshot.children {
                    
                    guard let snap =
                            child as? DataSnapshot,
                          let data =
                            snap.value as? [String: Any]
                    else { continue }
                    
                    tempImages[snap.key] =
                    data["profileImage"] as? String ?? ""
                }
                
                userProfileImages = tempImages
            }
    }
    
    func refreshChats() async {
        
        isRefreshing = true
        
        chatUsers.removeAll()
        
        fetchChats()
        fetchUserProfileImages()
        
        try? await Task.sleep(
            nanoseconds: 1_000_000_000
        )
        
        isRefreshing = false
    }
    
    // MARK: Current User
    
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
            .observeSingleEvent(of: .value) { snapshot in
                
                guard let data =
                        snapshot.value as? [String: Any]
                else { return }
                
                username =
                data["username"] as? String ?? ""
            }
    }
    
    func checkFollowStatus(userId: String) {
        
        guard let currentUserId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("followers")
            .child(userId)
            .child(currentUserId)
            .observeSingleEvent(of: .value) { snapshot in
                
                if snapshot.exists() {
                    
                    // Request accepted
                    gotoChat = true
                    
                } else {
                    
                    // Not following yet
                    showProfilePage = true
                }
            }
    }
    
    // MARK: Fetch All Users
    
    func fetchUsers() {
        
        Database.database()
            .reference()
            .child("users")
            .observe(.value) { snapshot in
                
                var tempUsers: [UserModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap =
                            child as? DataSnapshot,
                          let data =
                            snap.value as? [String: Any]
                    else { continue }
                    
                    tempUsers.append(
                        
                        UserModel(
                            id: snap.key,
                            username:
                                data["username"] as? String ?? "",
                            fullname:
                                data["fullname"] as? String ?? ""
                        )
                    )
                }
                
                users = tempUsers
                filteredUsers = tempUsers
            }
    }
    
    // MARK: Search User
    
    func searchUsers(text: String) {
        
        if text.isEmpty {
            
            filteredUsers = users
            
        } else {
            
            filteredUsers = users.filter {
                
                $0.username
                    .lowercased()
                    .contains(text.lowercased())
            }
        }
    }
    
    // MARK: Fetch Chats
    
    func fetchChats() {
        
        guard let currentUserId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("chats")
            .observeSingleEvent(of: .value) { snapshot in
                
                var tempUsers: [ChatUser] = []
                
                for child in snapshot.children {
                    
                    guard let roomSnap =
                            child as? DataSnapshot
                    else { continue }
                    
                    let roomId = roomSnap.key
                    
                    if roomId.contains(currentUserId) {
                        
                        let ids = roomId.components(
                            separatedBy: "_"
                        )
                        
                        let otherId =
                        ids.first {
                            $0 != currentUserId
                        } ?? ""
                        
                        var lastMessage = ""
                        var lastTime: Double = 0
                        
                        for msg in roomSnap.children {
                            
                            guard let msgSnap =
                                    msg as? DataSnapshot,
                                  let msgData =
                                    msgSnap.value as? [String: Any]
                            else { continue }
                            
                            let text =
                            msgData["text"] as? String ?? ""
                            
                            let time =
                            msgData["timestamp"] as? Double ?? 0
                            
                            if time > lastTime {
                                
                                lastTime = time
                                lastMessage = text
                            }
                        }
                        
                        Database.database()
                            .reference()
                            .child("users")
                            .child(otherId)
                            .observeSingleEvent(of: .value) { userSnap in
                                
                                guard let userData =
                                        userSnap.value
                                        as? [String: Any]
                                else { return }
                                
                                let username =
                                userData["username"]
                                as? String ?? ""
                                
                                tempUsers.removeAll {
                                    $0.id == otherId
                                }
                                
                                tempUsers.append(
                                    
                                    ChatUser(
                                        id: otherId,
                                        username: username,
                                        lastMessage: lastMessage,
                                        timestamp: lastTime
                                    )
                                )
                                
                                chatUsers =
                                tempUsers.sorted {
                                    $0.timestamp > $1.timestamp
                                }
                            }
                    }
                }
            }
    }
}

#Preview {
    MessagePage()
}

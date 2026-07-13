//
//  SearchPage.swift
//  ChatApp
//

import SwiftUI
import FirebaseDatabase

struct SearchPage: View {
    
    @State private var searchText = ""
    
    @State private var users: [UserModel] = []
    @State private var filteredUsers: [UserModel] = []
    @State private var userProfileImages: [String: String] = [:]
    
    @State private var gotoProfile = false
    @State private var selectedUserId = ""
    
    @State private var isRefreshing = false
    @State private var isLoading = true
    @State private var spinnerRotation: Double = 0
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                backgroundGradient
                
                if isLoading {
                    
                    loadingView
                    
                } else {
                    
                    VStack(spacing: 0) {
                        
                        header
                        
                        searchBar
                        
                        usersList
                    }
                }
            }
            .navigationDestination(
                isPresented: $gotoProfile
            ) {
                
                UserProfilePage(
                    userId: selectedUserId
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
                Color(
                    red: 0.06,
                    green: 0.05,
                    blue: 0.10
                )
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
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .purple,
                            .pink,
                            .orange
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            ZStack {
                
                Circle()
                    .stroke(
                        Color.white.opacity(0.1),
                        lineWidth: 4
                    )
                    .frame(width: 44,height: 44)
                
                Circle()
                    .trim(from: 0,to: 0.25)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .purple,
                                .pink,
                                .orange
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .frame(width: 44,height: 44)
                    .rotationEffect(
                        .degrees(spinnerRotation)
                    )
                    .onAppear {
                        
                        withAnimation(
                            .linear(duration: 0.9)
                            .repeatForever(
                                autoreverses: false
                            )
                        ) {
                            
                            spinnerRotation = 360
                        }
                    }
            }
            
            Text("Loading users...")
                .foregroundColor(
                    .white.opacity(0.45)
                )
                .font(.system(size: 13))
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: Load
    
    private func loadInitialData() {
        
        isLoading = true
        
        fetchUsers()
        fetchUserProfileImages()
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.6
        ) {
            
            withAnimation(.easeOut) {
                
                isLoading = false
            }
        }
    }
    
    // MARK: Header
    
    private var header: some View {
        
        HStack {
            
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                
                Text("Search")
                    .font(
                        .system(
                            size: 28,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.white)
                
                Text("Find people")
                    .font(.system(size: 13))
                    .foregroundColor(
                        .white.opacity(0.45)
                    )
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top,12)
        .padding(.bottom,10)
    }
    
    // MARK: Search Bar
    
    private var searchBar: some View {
        
        HStack(spacing: 8) {
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(
                    .white.opacity(0.4)
                )
            
            TextField(
                "Search username",
                text: $searchText
            )
            .foregroundColor(.white)
            .onChange(of: searchText) { value in
                
                searchUsers(text: value)
            }
            
            if !searchText.isEmpty {
                
                Button {
                    
                    searchText = ""
                    searchUsers(text: "")
                    
                } label: {
                    
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(
                            .white.opacity(0.4)
                        )
                }
            }
        }
        .padding(.horizontal,15)
        .padding(.vertical,12)
        .background(
            Color.white.opacity(0.06)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
        .padding(.bottom,10)
    }
    
    // MARK: Users List
    
    private var usersList: some View {
        
        ScrollView {
            
            LazyVStack(spacing: 6) {
                
                if isRefreshing {
                    
                    ProgressView("Refreshing...")
                        .tint(.white)
                        .foregroundColor(.white)
                        .padding(.top)
                }
                
                if filteredUsers.isEmpty {
                    
                    VStack(spacing: 15) {
                        
                        Spacer()
                        
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 55))
                            .foregroundColor(
                                .white.opacity(0.3)
                            )
                        
                        Text("No users found")
                            .font(
                                .headline
                            )
                            .foregroundColor(.white)
                        
                        Text("Try another username.")
                            .foregroundColor(
                                .white.opacity(0.45)
                            )
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top,80)
                    
                } else {
                    
                    ForEach(filteredUsers) { user in
                        
                        Button {
                            
                            selectedUserId = user.id
                            gotoProfile = true
                            
                        } label: {
                            
                            HStack(spacing: 12) {
                                
                                userDP(userId: user.id)
                                    .frame(
                                        width: 55,
                                        height: 55
                                    )
                                    .clipShape(
                                        Circle()
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white.opacity(0.12),
                                                lineWidth: 1
                                            )
                                    )
                                
                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {
                                    
                                    Text(user.username)
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundColor(.white)
                                    
                                    Text(user.fullname)
                                        .font(.system(size: 13))
                                        .foregroundColor(
                                            .white.opacity(0.5)
                                        )
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(
                                        .white.opacity(0.25)
                                    )
                            }
                            .padding()
                            .background(
                                Color.white.opacity(0.04)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16
                                )
                            )
                            .padding(.horizontal,10)
                            .padding(.vertical,3)
                        }
                    }
                }
            }
            .padding(.bottom,20)
        }
        .refreshable {
            
            await refreshUsers()
        }
    }
    // MARK: Refresh
    
    func refreshUsers() async {
        
        isRefreshing = true
        
        users.removeAll()
        filteredUsers.removeAll()
        
        fetchUsers()
        fetchUserProfileImages()
        
        try? await Task.sleep(
            nanoseconds: 900_000_000
        )
        
        isRefreshing = false
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
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    tempImages[snap.key] =
                    data["profileImage"] as? String ?? ""
                }
                
                userProfileImages = tempImages
            }
    }
    
    // MARK: Fetch Users
    
    func fetchUsers() {
        
        Database.database()
            .reference()
            .child("users")
            .observe(.value) { snapshot in
                
                var tempUsers: [UserModel] = []
                
                for child in snapshot.children {
                    
                    guard let snap = child as? DataSnapshot,
                          let data = snap.value as? [String: Any]
                    else { continue }
                    
                    let username =
                    data["username"] as? String ?? ""
                    
                    let fullname =
                    data["fullname"] as? String ?? ""
                    
                    tempUsers.append(
                        UserModel(
                            id: snap.key,
                            username: username,
                            fullname: fullname
                        )
                    )
                }
                
                users = tempUsers
                filteredUsers = tempUsers
            }
    }
    
    // MARK: Search Users
    
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
}

#Preview {
    SearchPage()
}

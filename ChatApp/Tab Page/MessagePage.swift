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
    
    @State private var gotoChat = false
    @State private var selectedUserId = ""
    @State private var selectedUsername = ""
    
    @State private var isRefreshing = false
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    
                    // Header
                    Text(username)
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top)
                    
                    Divider()
                        .background(Color.gray)
                    
                    // Search Bar
                    HStack {
                        
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField(
                            "Search Username",
                            text: $searchText
                        )
                        .foregroundColor(.white)
                        .onChange(of: searchText) { value in
                            
                            searchUsers(text: value)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(40)
                    .padding()
                    
                    // Search Result
                    if !searchText.isEmpty {
                        
                        ScrollView {
                            
                            LazyVStack {
                                
                                ForEach(filteredUsers) { user in
                                    
                                    Button {
                                        
                                        selectedUserId = user.id
                                        selectedUsername = user.username
                                        
                                        checkFollowStatus(userId: user.id)
                                        
                                    } label: {
                                        
                                        HStack {
                                            
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 50, height: 50)
                                            
                                            VStack(
                                                alignment: .leading
                                            ) {
                                                
                                                Text(user.username)
                                                    .foregroundColor(.white)
                                                
                                                Text(user.fullname)
                                                    .foregroundColor(.gray)
                                                    .font(.caption)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                    } else {
                        
                        // Chat List
                        
                        VStack{
                            if isRefreshing {
                                
                                ProgressView("Refreshing...")
                                    .tint(.white)
                                    .foregroundColor(.white)
                            }
                            
                            ScrollView {
                                
                                LazyVStack {
                                    
                                    ForEach(chatUsers) { user in
                                        
                                        Button {
                                            
                                            selectedUserId = user.id
                                            selectedUsername = user.username
                                            gotoChat = true
                                            
                                        } label: {
                                            
                                            HStack {
                                                
                                                Circle()
                                                    .fill(Color.gray)
                                                    .frame(width: 55, height: 55)
                                                
                                                VStack(
                                                    alignment: .leading
                                                ) {
                                                    
                                                    Text(user.username)
                                                        .foregroundColor(.white)
                                                        .font(.headline)
                                                    
                                                    Text(user.lastMessage)
                                                        .foregroundColor(.gray)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding()
                                        }
                                    }
                                }
                                
                            }
                            .refreshable {
                                
                                await refreshChats()
                            }
                        }
                    }
                    
                    Spacer()
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
            
            fetchCurrentUser()
            fetchUsers()
            fetchChats()
        }
    }
    func refreshChats() async {
        
        isRefreshing = true
        
        chatUsers.removeAll()
        
        fetchChats()
        
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


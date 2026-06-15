//
//  SearchPage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI
import FirebaseDatabase

struct SearchPage: View {
    
    @State private var searchText = ""
    @State private var users: [UserModel] = []
    @State private var filteredUsers: [UserModel] = []
    
    @State private var gotoProfile = false
    @State private var selectedUserId = ""
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    
                    // Search Bar
                    HStack(spacing: 10) {
                        
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField(
                            "Search Username",
                            text: $searchText
                        )
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(40)
                    .padding(.horizontal)
                    .onChange(of: searchText) { value in
                        
                        searchUsers(text: value)
                    }
                    
                    // Users List
                    ScrollView {
                        
                        LazyVStack(spacing: 12) {
                            
                            ForEach(filteredUsers) { user in
                                
                                Button {
                                    
                                    selectedUserId = user.id
                                    gotoProfile = true
                                    
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
                                                .font(.headline)
                                            
                                            Text(user.fullname)
                                                .foregroundColor(.gray)
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
            .navigationDestination(
                isPresented: $gotoProfile
            ) {
                
                UserProfilePage(
                    userId: selectedUserId
                )
            }
        }
        .onAppear {
            
            fetchUsers()
        }
    }
    
    // MARK: Fetch Users
    
    func fetchUsers() {
        
        let ref = Database.database()
            .reference()
            .child("users")
        
        ref.observe(.value) { snapshot in
            
            var tempUsers: [UserModel] = []
            
            for child in snapshot.children {
                
                guard let snap =
                        child as? DataSnapshot,
                      let data =
                        snap.value as? [String: Any]
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


// MARK: Preview

#Preview {
    SearchPage()
}

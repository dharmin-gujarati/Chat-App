//
//  MessagePage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI
import FirebaseDatabase

struct MessagePage: View {

    @State private var username = ""
    @State private var searchText = ""
    @State private var chatUsers: [ChatUser] = []
    @State private var gotoChat = false
    @State private var selectedUserId = ""
    @State private var selectedUsername = ""
    var body: some View {

        NavigationStack{
            ZStack {

                Color.black
                    .ignoresSafeArea()

                VStack {
                    Text("\(username)")
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                    Divider()
                        .background(Color.gray)
                    HStack(spacing: 10) {

                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)

                                TextField(
                                    "Search",
                                    text: $searchText
                                )
                                .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(40)
                            .padding(.horizontal)
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

                                        VStack(alignment: .leading) {

                                            Text(user.username)
                                                .foregroundColor(.white)
                                                .font(.headline)

                                            Text("Tap to chat")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }

                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                fetchCurrentUser()
                fetchChats()
            }
            .navigationDestination(isPresented: $gotoChat) {

                OpenMassegPage(
                    profileName: selectedUsername,
                    otherUserId: selectedUserId
                )
            }
        }
        .navigationBarBackButtonHidden()
    }
    func fetchChats() {

        guard let currentUserId =
                UserDefaults.standard.string(forKey: "currentUserId")
        else { return }

        let ref = Database.database()
            .reference()
            .child("chats")

        ref.observeSingleEvent(of: .value) { snapshot in

            var users: [ChatUser] = []

            for child in snapshot.children {

                guard let roomSnap = child as? DataSnapshot else {
                    continue
                }

                let roomId = roomSnap.key

                if roomId.contains(currentUserId) {

                    let ids = roomId.components(separatedBy: "_")

                    let otherId = ids.first {
                        $0 != currentUserId
                    } ?? ""

                    Database.database()
                        .reference()
                        .child("users")
                        .child(otherId)
                        .observeSingleEvent(of: .value) { userSnap in

                            if let data =
                                userSnap.value as? [String: Any] {

                                let username =
                                data["username"] as? String ?? ""

                                if !users.contains(where: {
                                    $0.id == otherId
                                }) {

                                    users.append(
                                        ChatUser(
                                            id: otherId,
                                            username: username
                                        )
                                    )

                                    chatUsers = users
                                }
                            }
                        }
                }
            }
        }
    }
    func fetchCurrentUser() {

        guard let userId = UserDefaults.standard.string(forKey: "currentUserId") else {

            print("No user found in UserDefaults")

            print("Username:",
                  UserDefaults.standard.string(forKey: "currentUsername") ?? "nil")

            return
        }

        print("Fetching User ID:", userId)

        let ref = Database.database().reference()
            .child("users")
            .child(userId)

        ref.observeSingleEvent(of: .value) { snapshot in

            guard let data = snapshot.value as? [String: Any] else {
                print("User data not found in Firebase")
                return
            }

            username = data["username"] as? String ?? ""

            print("Current Username:", username)
        }
    }
}

#Preview {
    MessagePage()
}


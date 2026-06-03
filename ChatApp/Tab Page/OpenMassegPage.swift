//
//  OpenMassegPage.swift
//  ChatApp
//
//  Created by CDMI on 03/06/26.
//

import SwiftUI
import FirebaseDatabase

struct OpenMassegPage: View {

    @State private var searchText = ""
    @State private var gotoBack = false

    let profileName: String
    let otherUserId: String

    @State private var messages: [MessageModel] = []

    var body: some View {

        NavigationStack {

            ZStack {

                Color.black
                    .ignoresSafeArea()

                VStack {

                    // Header
                    HStack {

                        Button {
                            gotoBack = true
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.white)
                        }

                        Image("profile")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                        Text(profileName)
                            .foregroundColor(.white)
                            .font(.headline)

                        Spacer()
                    }
                    .padding()

                    Divider()
                        .background(Color.gray)

                    // Messages
                    ScrollView {

                        LazyVStack(spacing: 12) {

                            ForEach(messages) { message in

                                let currentUserId =
                                UserDefaults.standard.string(
                                    forKey: "currentUserId"
                                ) ?? ""

                                HStack {

                                    if message.senderId == currentUserId {

                                        Spacer()

                                        Text(message.text)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(18)

                                    } else {

                                        Text(message.text)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.gray.opacity(0.3))
                                            .cornerRadius(18)

                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }

                    // Bottom Message Box
                    HStack {

                        TextField(
                            "Message...",
                            text: $searchText
                        )
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Color.gray.opacity(0.25)
                        )
                        .cornerRadius(25)

                        Button {

                            if !searchText.isEmpty {
                                sendMessage()
                            }

                        } label: {

                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .overlay {

                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.white)
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $gotoBack) {
                PageManage()
            }
        }
        .onAppear {
            fetchMessages()
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Room ID

    func createRoomId(
        user1: String,
        user2: String
    ) -> String {

        [user1, user2]
            .sorted()
            .joined(separator: "_")
    }

    // MARK: - Send Message

    func sendMessage() {

        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""

        let roomId = createRoomId(
            user1: currentUserId,
            user2: otherUserId
        )

        let ref = Database.database()
            .reference()
            .child("chats")
            .child(roomId)
            .childByAutoId()

        let data: [String: Any] = [

            "senderId": currentUserId,
            "receiverId": otherUserId,
            "text": searchText,
            "timestamp": Date()
                .timeIntervalSince1970
        ]

        ref.setValue(data)

        searchText = ""
    }

    // MARK: - Fetch Messages

    func fetchMessages() {

        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""

        let roomId = createRoomId(
            user1: currentUserId,
            user2: otherUserId
        )

        let ref = Database.database()
            .reference()
            .child("chats")
            .child(roomId)

        ref.observe(.value) { snapshot in

            var tempMessages: [MessageModel] = []

            for child in snapshot.children {

                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any]
                else { continue }

                let message = MessageModel(
                    id: snap.key,
                    senderId: data["senderId"] as? String ?? "",
                    receiverId: data["receiverId"] as? String ?? "",
                    text: data["text"] as? String ?? "",
                    timestamp: data["timestamp"] as? Double ?? 0
                )

                tempMessages.append(message)
            }

            messages = tempMessages.sorted {
                $0.timestamp < $1.timestamp
            }
        }
    }
}



#Preview {
    OpenMassegPage(
        profileName: "John",
        otherUserId: "testUserId"
    )
}

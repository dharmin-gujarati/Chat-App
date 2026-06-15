//
//  OpenMassegPage.swift
//  ChatApp
//
//  Created by CDMI on 03/06/26.
//

import SwiftUI
import FirebaseDatabase

struct OpenMassegPage: View {
    @State private var showEditAlert = false
    @State private var editedText = ""
    @State private var selectedMessageId = ""
    
    let profileName: String
    let otherUserId: String
    
    @State private var gotoMessegPage = false
    @State private var messageText = ""
    @State private var messages: [MessageModel] = []
    
    
    var body: some View {
        
        NavigationStack{
            ZStack {
                
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Header
                    HStack {
                        
                        Button {
                            gotoMessegPage = true
                            
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
                    ScrollViewReader { proxy in
                        
                        ScrollView {
                            
                            LazyVStack(spacing: 12) {
                                
                                ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                    
                                    let currentUserId =
                                    UserDefaults.standard.string(
                                        forKey: "currentUserId"
                                    ) ?? ""
                                    
                                    let currentDate =
                                    formatDate(message.timestamp)
                                    
                                    let previousDate =
                                    index > 0
                                    ? formatDate(messages[index - 1].timestamp)
                                    : ""
                                    
                                    VStack {
                                        
                                        // Date Header
                                        if index == 0 || currentDate != previousDate {
                                            
                                            Text(currentDate)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 5)
                                                .background(Color.gray.opacity(0.4))
                                                .cornerRadius(10)
                                                .padding(.vertical, 8)
                                        }
                                        
                                        HStack {
                                            
                                            if message.senderId == currentUserId {
                                                
                                                Spacer()
                                                
                                                VStack(alignment: .trailing, spacing: 3) {
                                                    
                                                    Text(message.text)
                                                        .foregroundColor(.white)
                                                        .padding()
                                                        .background(Color.blue)
                                                        .cornerRadius(18)
                                                        .contextMenu {
                                                            
                                                            Button {
                                                                
                                                                selectedMessageId = message.id
                                                                editedText = message.text
                                                                showEditAlert = true
                                                                
                                                            } label: {
                                                                
                                                                Label(
                                                                    "Edit",
                                                                    systemImage: "pencil"
                                                                )
                                                            }
                                                            
                                                            Button(
                                                                role: .destructive
                                                            ) {
                                                                
                                                                deleteMessage(
                                                                    messageId: message.id
                                                                )
                                                                
                                                            } label: {
                                                                
                                                                Label(
                                                                    "Delete",
                                                                    systemImage: "trash"
                                                                )
                                                            }
                                                        }
                                                    
                                                    Text(formatTime(message.timestamp))
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                            } else {
                                                
                                                VStack(alignment: .leading, spacing: 3) {
                                                    
                                                    Text(message.text)
                                                        .foregroundColor(.white)
                                                        .padding()
                                                        .background(
                                                            Color.gray.opacity(0.3)
                                                        )
                                                        .cornerRadius(18)
                                                    
                                                    Text(formatTime(message.timestamp))
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                    .id(message.id)
                                }
                            }
                            .padding(.top)
                        }
                        .onChange(of: messages.count) { _ in
                            
                            if let last = messages.last {
                                
                                proxy.scrollTo(
                                    last.id,
                                    anchor: .bottom
                                )
                            }
                        }
                    }
                    
                    // Message Box
                    HStack {
                        
                        TextField(
                            "Message...",
                            text: $messageText
                        )
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Color.gray.opacity(0.25)
                        )
                        .cornerRadius(25)
                        
                        Button {
                            
                            if !messageText.isEmpty {
                                
                                sendMessage()
                            }
                            
                        } label: {
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .overlay {
                                    
                                    Image(
                                        systemName:
                                            "paperplane.fill"
                                    )
                                    .foregroundColor(.white)
                                }
                        }
                    }
                    .padding()
                }
                .alert(
                    "Edit Message",
                    isPresented: $showEditAlert
                ) {
                    
                    TextField(
                        "Message",
                        text: $editedText
                    )
                    
                    Button("Save") {
                        updateMessage()
                    }
                    
                    Button(
                        "Cancel",
                        role: .cancel
                    ) { }
                    
                }
            }
            .onAppear {
                fetchMessages()
            }
            .navigationDestination(isPresented: $gotoMessegPage) {
                PageManage(selectedTab: 2)
            }
        }
        .navigationBarBackButtonHidden()
    }
    func deleteMessage(
        messageId: String
    ) {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        let roomId = createRoomId(
            user1: currentUserId,
            user2: otherUserId
        )
        
        Database.database()
            .reference()
            .child("chats")
            .child(roomId)
            .child(messageId)
            .removeValue()
    }
    
    func updateMessage() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        let roomId = createRoomId(
            user1: currentUserId,
            user2: otherUserId
        )
        
        Database.database()
            .reference()
            .child("chats")
            .child(roomId)
            .child(selectedMessageId)
            .updateChildValues([
                "text": editedText
            ])
    }
    
    func formatTime(_ timestamp: Double) -> String {
        
        let date = Date(timeIntervalSince1970: timestamp)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        return formatter.string(from: date)
    }
    func formatDate(_ timestamp: Double) -> String {
        
        let date = Date(timeIntervalSince1970: timestamp)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        
        return formatter.string(from: date)
    }
    
    
    
    func createRoomId(
        user1: String,
        user2: String
    ) -> String {
        
        [user1, user2]
            .sorted()
            .joined(separator: "_")
    }
    
    // MARK: Send Message
    
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
            "text": messageText,
            "timestamp":
                Date().timeIntervalSince1970
        ]
        
        ref.setValue(data)
        
        messageText = ""
    }
    
    // MARK: Fetch Messages
    
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
                
                guard let snap =
                        child as? DataSnapshot,
                      let data =
                        snap.value as? [String: Any]
                else { continue }
                
                let message = MessageModel(
                    
                    id: snap.key,
                    
                    senderId:
                        data["senderId"] as? String ?? "",
                    
                    receiverId:
                        data["receiverId"] as? String ?? "",
                    
                    text:
                        data["text"] as? String ?? "",
                    
                    timestamp:
                        data["timestamp"] as? Double ?? 0
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
        otherUserId: "123"
    )
}

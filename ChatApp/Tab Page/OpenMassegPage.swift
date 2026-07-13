//
//  OpenMassegPage.swift
//  ChatApp
//
//  Created by CDMI on 03/06/26.
//

import SwiftUI
import FirebaseDatabase
import PhotosUI

struct OpenMassegPage: View {
    
    @State private var showEditAlert = false
    @State private var editedText = ""
    @State private var selectedMessageId = ""
    
    let profileName: String
    let otherUserId: String
    
    @State private var gotoMessegPage = false
    @State private var messageText = ""
    @State private var messages: [MessageModel] = []
    @State private var otherUserProfileImage = ""
    
    // MARK: Initial load state
    @State private var isInitialLoading = true
    @State private var spinnerRotation: Double = 0
    @State private var headerAppear = false
    @State private var sendBump = false
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
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
                            .offset(y: headerAppear ? 0 : -8)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.35)) {
                                    headerAppear = true
                                }
                            }
                        
                        messagesList
                        
                        inputBar
                    }
                    .transition(.opacity)
                }
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
            .onAppear {
                loadInitialData()
            }
            .navigationDestination(isPresented: $gotoMessegPage) {
                PageManage(selectedTab: 2)
            }
        }
        .navigationBarBackButtonHidden()
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
            
            otherUserDP
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            ZStack {
                
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
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
                    .frame(width: 40, height: 40)
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
            
            Text("Loading chat...")
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
        
        fetchMessages()
        fetchOtherUserProfileImage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            withAnimation(.easeOut(duration: 0.35)) {
                isInitialLoading = false
            }
        }
    }
    
    // MARK: Header
    
    private var header: some View {
        
        HStack(spacing: 10) {
            
            Button {
                gotoMessegPage = true
                
            } label: {
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            
            otherUserDP
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                
                Text(profileName)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Active now")
                    .font(.system(size: 11.5))
                    .foregroundColor(.green.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: Messages List
    
    private var messagesList: some View {
        
        ScrollViewReader { proxy in
            
            ScrollView {
                
                if messages.isEmpty {
                    
                    emptyChatState
                    
                } else {
                    
                    LazyVStack(spacing: 10) {
                        
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
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                        .padding(.vertical, 10)
                                }
                                
                                HStack(alignment: .bottom, spacing: 8) {
                                    
                                    if message.senderId == currentUserId {
                                        
                                        Spacer(minLength: 40)
                                        
                                        VStack(alignment: .trailing, spacing: 3) {
                                            
                                            messageContent(message)
                                                
                                                .clipShape(
                                                    RoundedCorner(
                                                        radius: 18,
                                                        corners: [.topLeft, .topRight, .bottomLeft]
                                                    )
                                                )
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
                                                .font(.system(size: 10.5))
                                                .foregroundColor(.white.opacity(0.35))
                                        }
                                        
                                    } else {
                                        
                                        otherUserDP
                                            .frame(width: 28, height: 28)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            
                                            messageContent(message)
                                                
                                            Text(formatTime(message.timestamp))
                                                .font(.system(size: 10.5))
                                                .foregroundColor(.white.opacity(0.35))
                                        }
                                        
                                        Spacer(minLength: 40)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .id(message.id)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                )
                            )
                            
                        }
                    }
                    .padding(.top)
                    .animation(.easeOut(duration: 0.25), value: messages.map { $0.id })
                }
            }
            .onAppear {

                DispatchQueue.main.async {

                    if let last = messages.last {

                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: messages.count) { _ in

                if let last = messages.last {

                    DispatchQueue.main.async {

                        withAnimation {

                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Empty Chat State
    
    private var emptyChatState: some View {
        
        VStack(spacing: 12) {
            
            Spacer(minLength: 100)
            
            otherUserDP
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            Text(profileName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Say hi and start the conversation 👋")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: Input Bar
    
    private var inputBar: some View {
        
        HStack(spacing: 10) {

            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {

                Image(systemName: "photo.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.purple)
            }

            TextField(
                "Message...",
                text: $messageText
            )
            .foregroundColor(.white)
            .padding(.horizontal,16)
            .padding(.vertical,12)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())

            Button {

                if let image = selectedImage {

                    sendImage(image)

                } else if !messageText.trimmingCharacters(in: .whitespaces).isEmpty {

                    sendMessage()
                }

            } label: {

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple,.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width:46,height:46)
                    .overlay {

                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                    }
            }
        }
        .onChange(of: selectedItem) { item in

            Task {

                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {

                    selectedImage = image
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    @ViewBuilder
    func senderBubble(_ message: MessageModel) -> some View {

        VStack(alignment: .trailing) {

            messageContent(message)

            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    func receiverBubble(_ message: MessageModel) -> some View {

        VStack(alignment: .leading) {

            messageContent(message)

            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    
    // MARK: Other User DP
    
    @ViewBuilder
    private var otherUserDP: some View {
        
        if let imageData = Data(base64Encoded: otherUserProfileImage),
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
    
    func sendImage(_ image: UIImage) {

        guard let imageData = image.jpegData(compressionQuality: 0.3) else {
            return
        }

        let base64 = imageData.base64EncodedString()

        let currentUserId =
        UserDefaults.standard.string(forKey: "currentUserId") ?? ""

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
            "text": "",
            "image": base64,
            "timestamp": Date().timeIntervalSince1970
        ]

        ref.setValue(data)

        selectedImage = nil
    }
    
    func fetchOtherUserProfileImage() {
        
        Database.database()
            .reference()
            .child("users")
            .child(otherUserId)
            .observe(.value) { snapshot in
                
                guard let data =
                        snapshot.value as? [String: Any]
                else { return }
                
                otherUserProfileImage =
                data["profileImage"] as? String ?? ""
            }
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
    
    @ViewBuilder
    func messageContent(_ message: MessageModel) -> some View {

        if message.type == "post" {

            VStack(alignment: .leading, spacing: 8) {

                if let data = Data(base64Encoded: message.postImage),
                   let uiImage = UIImage(data: data) {

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipped()
                        .cornerRadius(12)
                }

                Text(message.postUsername)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(message.postCaption)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)

        } else if !message.image.isEmpty {

            if let data = Data(base64Encoded: message.image),
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipped()
                    .cornerRadius(15)
            }

        } else {

            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
        }
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

                    senderId: data["senderId"] as? String ?? "",

                    receiverId: data["receiverId"] as? String ?? "",

                    text: data["text"] as? String ?? "",

                    image: data["image"] as? String ?? "",

                    type: data["type"] as? String ?? "text",

                    postId: data["postId"] as? String ?? "",

                    postImage: data["postImage"] as? String ?? "",

                    postCaption: data["postCaption"] as? String ?? "",

                    postUsername: data["postUsername"] as? String ?? "",

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

// MARK: - Rounded corner helper for chat bubbles

struct RoundedCorner: Shape {
    
    var radius: CGFloat = 18
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        
        return Path(path.cgPath)
    }
}

#Preview {
    
    OpenMassegPage(
        profileName: "John",
        otherUserId: "123"
    )
}

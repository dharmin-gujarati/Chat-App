//
//  FollowRequestsPage.swift
//  ChatApp
//
//  Created by CDMI on 05/06/26.
//

import SwiftUI
import FirebaseDatabase

struct FollowRequestsPage: View {
    
    @State private var isFollowing = false
    @State private var requests: [FollowRequestModel] = []
    @State private var requestProfileImages: [String: String] = [:]
    @State private var gotoBack = false
    
    @State private var headerAppear = false
    @State private var processingRequestId: String? = nil
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                
                backgroundGradient
                
                VStack(spacing: 0) {
                    
                    header
                        .opacity(headerAppear ? 1 : 0)
                        .offset(y: headerAppear ? 0 : -10)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.4)) {
                                headerAppear = true
                            }
                        }
                    
                    if requests.isEmpty {
                        
                        emptyState
                        
                    } else {
                        
                        ScrollView {
                            
                            LazyVStack(spacing: 12) {
                                
                                ForEach(requests) { request in
                                    
                                    requestCard(request)
                                        .transition(
                                            .asymmetric(
                                                insertion: .opacity.combined(with: .move(edge: .top)),
                                                removal: .opacity.combined(with: .scale(scale: 0.85))
                                            )
                                        )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 14)
                            .padding(.bottom, 30)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: requests.map { $0.id })
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                .onAppear {
                    checkFollowingStatus()
                    fetchRequests()
                }
                .navigationDestination(isPresented: $gotoBack) {
                    PageManage(selectedTab: 0)
                }
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
    
    // MARK: Header
    
    private var header: some View {
        
        HStack {
            
            Button {
                gotoBack = true
            } label: {
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                
                Text("Follow Requests")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                if !requests.isEmpty {
                    
                    Text("\(requests.count) pending")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // symmetry spacer to balance the back button
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }
    
    // MARK: Empty State
    
    private var emptyState: some View {
        
        VStack(spacing: 14) {
            
            Spacer()
            
            ZStack {
                
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 38))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("No pending requests")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            Text("When someone wants to follow you,\nit'll show up here.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: Request Card
    
    private func requestCard(_ request: FollowRequestModel) -> some View {
        
        HStack(spacing: 12) {
            
            ZStack {
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 52, height: 52)
                
                requestDP(userId: request.fromUserId)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(request.username)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("wants to follow you")
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if processingRequestId == request.id {
                
                ProgressView()
                    .tint(.white)
                    .frame(width: 70)
                
            } else {
                
                HStack(spacing: 8) {
                    
                    Button {
                        
                        handleAccept(request)
                        
                    } label: {
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 34, height: 34)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    
                    Button {
                        
                        handleReject(request)
                        
                    } label: {
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: Accept / Reject with mini loading animation
    
    private func handleAccept(_ request: FollowRequestModel) {
        
        withAnimation {
            processingRequestId = request.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            
            acceptRequest(request)
            processingRequestId = nil
        }
    }
    
    private func handleReject(_ request: FollowRequestModel) {
        
        withAnimation {
            processingRequestId = request.id
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            
            rejectRequest(request)
            processingRequestId = nil
        }
    }
    
    // MARK: Request User DP
    
    @ViewBuilder
    private func requestDP(userId: String) -> some View {
        
        let base64Image = requestProfileImages[userId] ?? ""
        
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
    
    func checkFollowingStatus() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        Database.database()
            .reference()
            .child("followers")
            .child(currentUserId)
            .observe(.value) { snapshot in
                
                isFollowing = snapshot.exists()
            }
    }
    
    // MARK: Fetch Requests
    
    func fetchRequests() {
        
        guard let currentUserId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        Database.database()
            .reference()
            .child("followRequests")
            .observe(.value) { snapshot in
                
                var tempRequests: [FollowRequestModel] = []
                var tempImages: [String: String] = [:]
                
                for child in snapshot.children {
                    
                    guard let snap =
                            child as? DataSnapshot,
                          let data =
                            snap.value as? [String: Any]
                    else { continue }
                    
                    let toUserId =
                    data["toUserId"] as? String ?? ""
                    
                    if toUserId == currentUserId {
                        
                        let fromUserId =
                        data["fromUserId"] as? String ?? ""
                        
                        Database.database()
                            .reference()
                            .child("users")
                            .child(fromUserId)
                            .observeSingleEvent(of: .value) { userSnap in
                                
                                if let userData =
                                    userSnap.value as? [String: Any] {
                                    
                                    let username =
                                    userData["username"] as? String ?? ""
                                    
                                    let profileImage =
                                    userData["profileImage"] as? String ?? ""
                                    
                                    let request =
                                    FollowRequestModel(
                                        id: snap.key,
                                        fromUserId: fromUserId,
                                        username: username
                                    )
                                    
                                    if !tempRequests.contains(where: {
                                        $0.id == request.id
                                    }) {
                                        
                                        tempRequests.append(request)
                                    }
                                    
                                    tempImages[fromUserId] = profileImage
                                    
                                    requests = tempRequests
                                    requestProfileImages = tempImages
                                }
                            }
                    }
                }
            }
    }
    
    // MARK: Accept Request
    
    func acceptRequest(_ request: FollowRequestModel) {
        
        guard let currentUserId =
                UserDefaults.standard.string(
                    forKey: "currentUserId"
                )
        else { return }
        
        let root = Database.database().reference()
        
        root.child("followers")
            .child(currentUserId)
            .child(request.fromUserId)
            .setValue(true)
        
        root.child("following")
            .child(request.fromUserId)
            .child(currentUserId)
            .setValue(true)
        
        root.child("followRequests")
            .child(request.id)
            .removeValue()
        
        requests.removeAll {
            $0.id == request.id
        }
    }
    
    // MARK: Reject Request
    
    func rejectRequest(
        _ request: FollowRequestModel
    ) {
        
        Database.database()
            .reference()
            .child("followRequests")
            .child(request.id)
            .removeValue()
        
        requests.removeAll {
            $0.id == request.id
        }
    }
}

#Preview {
    FollowRequestsPage()
}

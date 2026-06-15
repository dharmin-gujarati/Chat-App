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
    @State private var gotoBack = false
    var body: some View {
        
        NavigationStack {
            ZStack{
                Color.black
                    .ignoresSafeArea()
                VStack{
                    HStack{
                        Button(action:{
                            gotoBack = true
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                        }
                        .padding(.leading, 10)
                        Spacer()
                    }
                    ScrollView {
                        
                        LazyVStack {
                            
                            ForEach(requests) { request in
                                
                                HStack {
                                    
                                    Text(request.username)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button {
                                        
                                        acceptRequest(request)
                                        
                                    } label: {
                                        
                                        Text("Accept")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(10)
                                    }
                                    
                                    Button {
                                        
                                        rejectRequest(request)
                                        
                                    } label: {
                                        
                                        Text("Reject")
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 8)
                                            .background(Color.red)
                                            .cornerRadius(10)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            
                        }
                    }
                    .background(Color.black)
                    .onAppear {
                        checkFollowingStatus()
                        fetchRequests()
                    }
                    .navigationDestination(isPresented: $gotoBack) {
                        PageManage(selectedTab: 0)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
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
                            .observeSingleEvent(of: .value) {
                                
                                userSnap in
                                
                                if let userData =
                                    userSnap.value as? [String: Any] {
                                    
                                    let username =
                                    userData["username"] as? String ?? ""
                                    
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
                                    
                                    requests = tempRequests
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
        
        // requester becomes follower
        root.child("followers")
            .child(currentUserId)
            .child(request.fromUserId)
            .setValue(true)
        
        // current user becomes following
        root.child("following")
            .child(request.fromUserId)
            .child(currentUserId)
            .setValue(true)
        
        // delete request
        root.child("followRequests")
            .child(request.id)
            .removeValue()
        
        // remove from UI instantly
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
    }
}
#Preview {
    FollowRequestsPage()
}

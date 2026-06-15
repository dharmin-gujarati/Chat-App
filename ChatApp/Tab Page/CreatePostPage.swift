//
//  CreatePostPage.swift
//  ChatApp
//
//  Created by CDMI on 04/06/26.
//

import SwiftUI
import FirebaseDatabase

struct CreatePostPage: View {
    
    @State private var caption = ""
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            TextField(
                "Caption",
                text: $caption
            )
            .textFieldStyle(.roundedBorder)
            
            Button("Upload Test Post") {
                
                uploadPost()
            }
        }
        .padding()
    }
    
    func uploadPost() {
        
        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""
        
        let currentUsername =
        UserDefaults.standard.string(
            forKey: "currentUsername"
        ) ?? ""
        
        let ref = Database.database()
            .reference()
            .child("posts")
            .childByAutoId()
        
        let data: [String: Any] = [
            
            "userId": currentUserId,
            "username": currentUsername,
            
            "imageURL":
                "https://i.pinimg.com/736x/18/84/9c/18849c2f764959976f3fb884606e95b1.jpg",
            
            "caption": caption
        ]
        
        ref.setValue(data)
    }
}

#Preview {
    CreatePostPage()
}

//
//  MessageModel.swift
//  ChatApp
//
//  Created by CDMI on 03/06/26.
//

import Foundation

struct MessageModel: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Double
}

struct ChatUser: Identifiable {
    let id: String
    let username: String
}

struct UserModel: Identifiable {
    let id: String
    let username: String
    let fullname: String
}

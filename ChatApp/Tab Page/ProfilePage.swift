//
//  ProfilePage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI
import FirebaseDatabaseInternal

struct ProfilePage: View {
    @State private var username = ""
    let posts = Array(repeating: "profile", count: 12)
    @State private var logout = false

    var body: some View {

        NavigationStack{
            ScrollView {

                VStack(spacing: 16) {

                    // Header
                    HStack {

                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())

                        Spacer()

                        statView(count: "24", title: "Posts")

                        Spacer()

                        statView(count: "1.2K", title: "Followers")

                        Spacer()

                        statView(count: "345", title: "Following")
                    }
                    .padding(.horizontal)

                    // Name + Bio
                    VStack(alignment: .leading, spacing: 4) {

                        Text("\(username)")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("iOS Developer 📱")
                            .foregroundColor(.white)

                        Text("Building awesome apps with SwiftUI 🚀")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Buttons
                    HStack(spacing: 10) {

                        Button {

                        } label: {

                            Text("Edit Profile")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.25))
                                .cornerRadius(8)
                        }

                        Button {

                        } label: {

                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.white)
                                .frame(width: 50)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.25))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    // Story Highlights
                    ScrollView(.horizontal, showsIndicators: false) {

                        HStack(spacing: 15) {

                            ForEach(0..<2, id: \.self) { _ in

                                VStack {

                                    Circle()
                                        .stroke(Color.gray, lineWidth: 1)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Image("profile")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 62, height: 62)
                                                .clipShape(Circle())
                                        )

                                    Text("Story")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            Button(action:{
                                
                            }) {
                                VStack{
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 1)
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .frame(width: 62, height: 62)
                                                .clipShape(Circle())
                                        )
                                    Text("Story")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            }
                            
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .background(Color.gray)

                    // Tab Icons
                    HStack {

                        Spacer()

                        Image(systemName: "square.grid.3x3")
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "play.rectangle")
                            .foregroundColor(.gray)

                        Spacer()

                        Image(systemName: "person.crop.square")
                            .foregroundColor(.gray)

                        Spacer()
                    }

                    // Posts Grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                        spacing: 2
                    ) {

                        ForEach(posts.indices, id: \.self) { index in

                            Image(posts[index])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 130)
                                .clipped()
                        }
                    }
                    Button(action:{

                        UserDefaults.standard.removeObject(forKey: "currentUsername")
                        UserDefaults.standard.removeObject(forKey: "currentUserId")
                        logout = true
                        
                    }) {
                        Text("Log Out")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                }
                .navigationDestination(isPresented: $logout) {
                    SigninPage()
                }
                .onAppear {
                    fetchCurrentUser()
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func statView(count: String, title: String) -> some View {

        VStack {

            Text(count)
                .font(.headline)
                .foregroundColor(.white)

            Text(title)
                .foregroundColor(.white)
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
    NavigationStack {
        ProfilePage()
    }
}

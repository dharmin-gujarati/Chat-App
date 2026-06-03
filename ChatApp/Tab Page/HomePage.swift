//
//  homePage.swift
//  ChatApp
//
//  Created by CDMI on 28/05/26.
//

import SwiftUI

struct HomePage: View {
    let stories = Array(1...10)
        let posts = Array(1...5)

    var body: some View {

        ZStack(alignment: .top) {

            Color.black
                .ignoresSafeArea()
            VStack{
                HStack {

                    Button {

                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image("mff")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 40)

                    Spacer()

                    Button {

                    } label: {
                        Image(systemName: "heart")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .frame(height: 60)
                .background(Color.black)
                ScrollView {

                    VStack(spacing: 0) {

                                            // Stories
                                            ScrollView(.horizontal, showsIndicators: false) {

                                                HStack(spacing: 15) {

                                                    ForEach(stories, id: \.self) { _ in

                                                        VStack {

                                                            Circle()
                                                                .stroke(
                                                                    LinearGradient(
                                                                        colors: [.orange, .red, .purple],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    ),
                                                                    lineWidth: 3
                                                                )
                                                                .frame(width: 72, height: 72)
                                                                .overlay {

                                                                    Image("profile")
                                                                        .resizable()
                                                                        .scaledToFill()
                                                                        .frame(width: 64, height: 64)
                                                                        .clipShape(Circle())
                                                                }

                                                            Text("user")
                                                                .foregroundColor(.white)
                                                                .font(.caption)
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal)
                                            }
                                            .padding(.vertical)

                                            Divider()
                                                .background(Color.gray.opacity(0.5))

                                            // Posts
                                            LazyVStack(spacing: 25) {

                                                ForEach(posts, id: \.self) { _ in

                                                    PostCard()
                                                }
                                            }
                                            .padding(.top)
                                        }
                                    }
            }
            }

            
        }
//        .navigationBarBackButtonHidden()
    }

struct PostCard: View {

    @State private var isLiked = false

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack {

                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                Text("john_doe")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)

            // Post Image
            Image("profile")
                .resizable()
                .scaledToFill()
                .frame(height: 400)
                .clipped()

            // Actions
            HStack(spacing: 18) {

                Button {
                    isLiked.toggle()
                } label: {

                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isLiked ? .red : .white)
                }

                Image(systemName: "message")
                    .font(.title2)
                    .foregroundColor(.white)

                Image(systemName: "paperplane")
                    .font(.title2)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "bookmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 5) {

                Text("1,245 likes")
                    .foregroundColor(.white)
                    .fontWeight(.bold)

                (
                    Text("john_doe ")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    +
                    Text("Enjoying the sunset 🌅")
                        .foregroundColor(.white)
                )

                Text("View all 42 comments")
                    .foregroundColor(.gray)
                    .font(.caption)

                Text("2 hours ago")
                    .foregroundColor(.gray)
                    .font(.caption2)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    HomePage()
}

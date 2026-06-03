//
//  ContentView.swift
//  ChatApp
//
//  Created by CDMI on 26/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isVisible = false
    @State private var gotoNext = false
    var body: some View {
        NavigationStack{
            ZStack{
                Color.black
                    .ignoresSafeArea()
                VStack {
                    Image("Logo")
                        .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        .opacity(isVisible ? 1 : 0)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .onAppear {
                            withAnimation(.easeIn(duration: 2.0)) {
                                isVisible = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                gotoNext = true
                            }
                        }
                    Text("MFF Chats")
                        .bold()
                        .font(.system(size: 40))
                        .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                }
                .padding()
            }
            .navigationDestination(isPresented: $gotoNext) {
                            if UserDefaults.standard.string(forKey: "currentUsername") != nil {
                                PageManage()
                            } else {
                                SigninPage()
                            }
                        }
        }
        
    }
}

#Preview {
    ContentView()
}

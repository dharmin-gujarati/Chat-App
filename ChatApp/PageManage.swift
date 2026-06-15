//
//  PageManage.swift
//  ChatApp
//
//  Created by CDMI on 29/05/26.
//

import SwiftUI

struct PageManage: View {
    @State var selectedTab : Int
    var body: some View {
        
        NavigationStack{
            Rectangle()
                .fill(.white)
                .ignoresSafeArea()
                .overlay {
                    
                    VStack(spacing: 0.3) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 50)
                        
                        if selectedTab == 0 {
                            HomePage()
                        }
                        if selectedTab == 1 {
                            ReelsPage()
                        }
                        if selectedTab == 2 {
                            MessagePage()
                        }
                        if selectedTab == 3 {
                            SearchPage()
                        }
                        if selectedTab == 4 {
                            ProfilePage()
                        }
                        
                        ZStack{
                            HStack {
                                tabButton(icon: "house", index: 0)
                                Spacer()
                                tabButton(icon: "play.square", index: 1)
                                
                                Spacer()
                                tabButton(icon: "paperplane", index: 2)
                                
                                Spacer()
                                tabButton(icon: "magnifyingglass", index: 3)
                                
                                Spacer()
                                tabButton(icon: "circle", index: 4)
                                
                                
                                
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .padding(.top, 10)
                            .background(Color(.black))
                            .shadow(radius: 10)
                        }
                        .padding(.bottom, 1)
                    }
                    .ignoresSafeArea()
                }
        }
        .navigationBarBackButtonHidden()
        
    }
    func tabButton(icon: String, index: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .bold()
                    .font(.system(size: 30))
                    .foregroundColor(selectedTab == index ? Color.white : .gray)
            }
        }
    }
    
}

#Preview {
    PageManage(selectedTab: 0)
}

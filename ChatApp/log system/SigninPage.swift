//
//  SighupPage.swift
//  ChatApp
//
//  Created by CDMI on 26/05/26.
//

import SwiftUI
import FirebaseDatabase

struct SigninPage: View {
    @State private var id = ""
    @State private var password = ""
    @State private var gotoPageManage = false
    @State private var gotoSignupPage = false
    var body: some View {
        NavigationStack{
            ZStack{
                Color.black
                    .ignoresSafeArea()
                VStack{
                    VStack(spacing: 12) {
                        Text("See everyday moments from")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        (
                            Text("your ")
                                .foregroundColor(.white)
                            +
                            Text("close")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            +
                            Text(" friends")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            +
                            Text(".")
                                .foregroundColor(.white)
                        )
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                    }
                    .padding(.top,100)
                    Spacer()
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 61)
                        .cornerRadius(20)
                    
                        .overlay{
                            HStack{
                                TextField(
                                    "",
                                    text: $id,
                                    prompt: Text("username")
                                        .foregroundColor(.gray)
                                )
                                .foregroundColor(.white)
                                .bold()
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                                if !id.isEmpty {
                                    Button(action:{
                                        id = ""
                                    }){
                                        Image(systemName:"x.circle.fill")
                                            .resizable()
                                            .frame(width: 30 , height: 30)
                                            .padding()
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                        }
                        .padding(.horizontal, 20)
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 61)
                        .cornerRadius(20)
                    
                        .overlay{
                            HStack{
                                TextField(
                                    "",
                                    text: $password,
                                    prompt: Text("Password")
                                        .foregroundColor(.gray)
                                )
                                .foregroundColor(.white)
                                .bold()
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                                if !password.isEmpty {
                                    Button(action:{
                                        password = ""
                                    }){
                                        Image(systemName:"x.circle.fill")
                                            .resizable()
                                            .frame(width: 30 , height: 30)
                                            .padding()
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                        }
                        .padding(.horizontal, 20)
                    
                    Button(action:{
                        chackdata()
                    }){
                        Rectangle()
                            .fill(Color.blue.opacity(0.75))
                            .frame(height: 61)
                            .cornerRadius(30)
                            .overlay{
                                Text("Log in")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    HStack{
                        Spacer()
                        Button(action:{
                            gotoSignupPage = true
                            
                        }){
                           
                                    Text("Creat a new Account?")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                    }
                    Button(action:{
                        
                    }) {
                        HStack(spacing:25) {
                            Image("google")
                                .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                            Text("sign in with google")
                                .font(.system(size: 19))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(1))
                        )
                        .padding()
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $gotoPageManage) {
                PageManage()
            }
            .navigationDestination(isPresented: $gotoSignupPage) {
                SignupPage()
            }
        }
        .navigationBarBackButtonHidden()
    }
    func chackdata() {

        let ref = Database.database().reference().child("users")

        ref.observeSingleEvent(of: .value) { snapshot in

            var isLoginSuccess = false

            for child in snapshot.children {

                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any]
                else { continue }

                let dbUsername = data["username"] as? String ?? ""
                let dbPassword = data["password"] as? String ?? ""

                if dbUsername == id && dbPassword == password {

                    UserDefaults.standard.set(dbUsername, forKey: "currentUsername")
                    UserDefaults.standard.set(snap.key, forKey: "currentUserId")

                    print("Saved Username:", dbUsername)
                    print("Saved User ID:", snap.key)
                    if dbUsername == id && dbPassword == password {

                        UserDefaults.standard.set(dbUsername, forKey: "currentUsername")

                        let test = UserDefaults.standard.string(forKey: "currentUsername") ?? "NOT SAVED"
                        print("Saved username =", test)

                        gotoPageManage = true
                    }

                    isLoginSuccess = true
                    gotoPageManage = true
                    break
                }
            }

            if !isLoginSuccess {
                print("Invalid username or password")
            }
        }
    }
}

#Preview {
    SigninPage()
}

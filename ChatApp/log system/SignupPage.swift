//
//  SignupPage.swift
//  ChatApp
//
//  Created by CDMI on 28/05/26.
//

import SwiftUI
import FirebaseDatabase

struct SignupPage: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var selectedMonth = "Month"
    @State private var selectedDay = "Day"
    @State private var selectedYear = "Year"
    @State private var gotoLoginPage = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let months = [
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    ]
    
    let days = Array(1...31).map { "\($0)" }
    
    let years = Array(1980...2025).reversed().map { "\($0)" }
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
                    VStack(alignment: .leading){
                        Text("enter email")
                            .foregroundColor(.gray)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 50)
                            .cornerRadius(20)
                        
                            .overlay{
                                HStack{
                                    TextField(
                                        "",
                                        text: $email,
                                        prompt: Text("email")
                                            .foregroundColor(.gray)
                                    )
                                    .foregroundColor(.white)
                                    .bold()
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                                    if !email.isEmpty {
                                        Button(action:{
                                            email = ""
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
                    }
                    .padding(.horizontal, 20)
                    VStack(alignment: .leading){
                        Text("enter password")
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 50)
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
                    }
                    .padding(.horizontal, 20)
                    VStack(alignment: .leading){
                        Text("enter date of barth")
                            .foregroundColor(.gray)
                        HStack(spacing: 14) {
                            
                            Menu {
                                ForEach(months, id: \.self) { month in
                                    Button(month) {
                                        selectedMonth = month
                                    }
                                }
                            } label: {
                                
                                dropdownView(title: selectedMonth)
                            }
                            
                            Menu {
                                ForEach(days, id: \.self) { day in
                                    Button(day) {
                                        selectedDay = day
                                    }
                                }
                            } label: {
                                
                                dropdownView(title: selectedDay)
                            }
                            
                            Menu {
                                ForEach(years, id: \.self) { year in
                                    Button(year) {
                                        selectedYear = year
                                    }
                                }
                            } label: {
                                
                                dropdownView(title: selectedYear)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    VStack(alignment: .leading){
                        Text("enter Fulllname")
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 50)
                            .cornerRadius(20)
                        
                            .overlay{
                                HStack{
                                    TextField(
                                        "",
                                        text: $fullName,
                                        prompt: Text("Full Name")
                                            .foregroundColor(.gray)
                                    )
                                    .foregroundColor(.white)
                                    .bold()
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                                    if !fullName.isEmpty {
                                        Button(action:{
                                            fullName = ""
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
                    }
                    .padding(.horizontal, 20)
                    VStack(alignment: .leading){
                        Text("enter usrname")
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 50)
                            .cornerRadius(20)
                        
                            .overlay{
                                HStack{
                                    TextField(
                                        "",
                                        text: $username,
                                        prompt: Text("username")
                                            .foregroundColor(.gray)
                                    )
                                    .foregroundColor(.white)
                                    .bold()
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                                    if !username.isEmpty {
                                        Button(action:{
                                            username = ""
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
                    }
                    .padding(.horizontal, 20)
                    Button(action: {
                        
                        if validateFields() {
                            
                            Task {
                                await addUser()
                            }
                        }
                        
                    }) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.75))
                            .frame(height: 61)
                            .cornerRadius(30)
                            .overlay {
                                Text("Sign Up")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    HStack{
                        Spacer()
                        Button(action:{
                            
                            gotoLoginPage = true
                            
                        }){
                            
                            Text("I already have an Account")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                            
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $gotoLoginPage) {
                SigninPage()
            }
        }
        .navigationBarBackButtonHidden()
        .alert("Validation Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    func validateFields() -> Bool {
        
        // Empty fields check
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Email is required."
            showAlert = true
            return false
        }
        
        if password.isEmpty {
            alertMessage = "Password is required."
            showAlert = true
            return false
        }
        
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Full Name is required."
            showAlert = true
            return false
        }
        
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Username is required."
            showAlert = true
            return false
        }
        
        if selectedMonth == "Month" ||
            selectedDay == "Day" ||
            selectedYear == "Year" {
            
            alertMessage = "Please select your date of birth."
            showAlert = true
            return false
        }
        
        // Password validation
        if password.count < 8 {
            alertMessage = "Password must contain at least 8 characters."
            showAlert = true
            return false
        }
        
        // Full name validation (must contain first and last name)
        let nameParts = fullName
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
        
        if nameParts.count < 2 {
            alertMessage = "Please enter first name and surname."
            showAlert = true
            return false
        }
        
        // Username minimum length
        if username.count < 10 {
            alertMessage = "Username must contain at least 10 characters."
            showAlert = true
            return false
        }
        
        // Username must contain at least 3 numbers
        let digitCount = username.filter { $0.isNumber }.count
        
        if digitCount < 3 {
            alertMessage = "Username must contain at least 3 numbers."
            showAlert = true
            return false
        }
        
        return true
    }
    func dropdownView(title: String) -> some View {
        
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    func addUser() async {
        
        let ref = Database.database()
            .reference()
            .child("users")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            
            // Check if username already exists
            for child in snapshot.children {
                
                guard let snap = child as? DataSnapshot,
                      let data = snap.value as? [String: Any]
                else { continue }
                
                let dbUsername =
                (data["username"] as? String ?? "")
                    .lowercased()
                
                if dbUsername == username.lowercased() {
                    
                    alertMessage = "Username already exists. Please choose another username."
                    showAlert = true
                    return
                }
            }
            
            // Save new user
            let userData: [String: Any] = [
                
                "email": email,
                "fullname": fullName,
                "password": password,
                "username": username
            ]
            
            let newUserRef = ref.childByAutoId()
            
            newUserRef.setValue(userData) { error, _ in
                
                if let error = error {
                    
                    alertMessage = error.localizedDescription
                    showAlert = true
                    return
                }
                
                UserDefaults.standard.set(
                    username,
                    forKey: "currentUsername"
                )
                
                UserDefaults.standard.set(
                    newUserRef.key,
                    forKey: "currentUserId"
                )
                
                gotoLoginPage = true
            }
        }
    }
}


#Preview {
    SignupPage()
}

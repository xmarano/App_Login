//
//  Login.swift
//  Login
//
//  Created by Léo Grégori on 05/06/2024.
//

import SwiftUI
import Firebase
import Lottie

struct Login: View {
    // Propriétés visuels
    @State private var activeTab: Tab = .login
    @State private var isLoading: Bool = false
    @State private var showEmailVerificationView: Bool = false
    @State private var emailAddress: String = ""
    @State private var password: String = ""
    @State private var reEnterPassword: String = ""
    // Propriétés alertes
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @AppStorage("log_status") private var logStatus: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Email Adress", text: $emailAddress)
                        .keyboardType(.emailAddress)
                        .customTextField("person")
                    
                    SecureField("Password", text: $password)
                        .customTextField("person", 0, activeTab == .login ? 10 : 0)
                    
                    if activeTab == .SignUp {
                        SecureField("Re-Enter Password", text: $reEnterPassword)
                            .customTextField("person", 0, activeTab != .login ? 10 : 0)
                    }
                } header: {
                    Picker("", selection: $activeTab) {
                        ForEach(Tab.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(.init(top: 15, leading: 0, bottom: 15, trailing: 0))
                    .listRowSeparator(.hidden)
                } footer: {
                    VStack(alignment: .trailing, spacing: 12, content: {
                        if activeTab == .login{
                            Button("Forgot Password") {
                                
                            }
                            .font(.caption)
                            .tint(Color.accentColor)
                        }
                        Button(action: loginAndSignUp, label: {
                            HStack(spacing: 12) {
                                Text(activeTab == .login ? "Login" : "Create Account")
                                
                                Image(systemName: "arrow.right")
                                    .font(.callout)
                            }
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        .showLoadingIndicator(isLoading)
                        .disabled(buttonStatus)
                    })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .listRowInsets(.init(top: 15, leading: 0, bottom: 0, trailing: 0))
                }
                .disabled(isLoading)
            }
            .animation(.snappy, value: activeTab)
            .listStyle(.insetGrouped)
            .navigationTitle("Welcome Back!")
        }
        .sheet(isPresented: $showEmailVerificationView, content: {
            EmailVerificationView()
                .presentationDetents([.height(350)])
                .presentationCornerRadius(25)
                .interactiveDismissDisabled()
        })
        .alert(alertMessage, isPresented: $showAlert) {  }
        // 7:24 erase mdp lorsque switch login -> sign up
    }

    /// Email Verification View
    @ViewBuilder
    func EmailVerificationView() -> some View {
        VStack(spacing: 6) {
            GeometryReader { _ in
                if let bundle = Bundle.main.path(forResource: "EmailAnimation", ofType: "json") {
                    LottieView {
                        await LottieAnimation.loadedFrom(url: URL(filePath: bundle))
                    }
                    .playing(loopMode: .loop)
                }
            }
            
            Text("Verification")
                .font(.title.bold())
            
            Text("We have sent a verification email to your email address.\nPlease verify to continue.")
                .multilineTextAlignment(.center)
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 25)
        }
        .overlay(alignment: .topTrailing, content: {
            Button("Cancel") {
                showEmailVerificationView = false
                // ICI à
                isLoading = false
                /// Optional: you can delete the account in firebase
                if let user = Auth.auth().currentUser {
                    user.delete { _ in
                        
                    }
                }
                // ICI ^
            }
            .padding(15)
        })
        .padding(.bottom, 15)
        // Refresh status user every 2min to check if email verified
        .onReceive(Timer.publish(every: 2, on: .main, in: .default).autoconnect(), perform: { _ in
            if let user = Auth.auth().currentUser {
                user.reload()
                if user.isEmailVerified {
                    /// Email Successfully Verified
                    showEmailVerificationView = false
                    logStatus = true
                }
            }
        })
    }
    
    func loginAndSignUp() {
        Task {
            isLoading = true
            do {
                if activeTab == .login {
                    /// Loggin in
                    let result = try await Auth.auth().signIn(withEmail: emailAddress, password: password)
                    if result.user.isEmailVerified {
                        /// Verified User
                        /// Redirect to Home View
                        logStatus = true
                    } else {
                        /// Send Verification Email and Presenting Verification View
                        try await result.user.sendEmailVerification()
                        showEmailVerificationView = true
                    }
                } else {
                    /// Creating New Account
                    if password == reEnterPassword {
                        let result = try await Auth.auth().createUser(withEmail: emailAddress, password: password)
                        /// Sending Verification Email
                        try await result.user.sendEmailVerification()
                        /// Showing Email Verificatoin View
                        showEmailVerificationView = true
                    } else {
                        await presentAlert("Mismatching Password")
                    }
                }
            } catch {
                await presentAlert(error.localizedDescription)
            }
        }
    }

    /// Presenting Alerte
    func presentAlert(_ message: String) async {
        await MainActor.run {
            alertMessage = message
            showAlert = true
            isLoading = false
        }
    }
    
    /// Tab Type
    enum Tab: String, CaseIterable {
        case login = "Login"
        case SignUp = "Sign Up"
    }

    /// Button status
    var buttonStatus: Bool {
        if activeTab == .login {
            return emailAddress.isEmpty || password.isEmpty
        }
        
        return emailAddress.isEmpty || password.isEmpty || reEnterPassword.isEmpty
    }
}

fileprivate extension View {
    @ViewBuilder
    func showLoadingIndicator(_ status: Bool) -> some View {
        self
            .animation(.snappy) { content in
                content
                    .opacity(status ? 0 : 1)
            }
            .overlay {
                if status {
                    ZStack {
                        Capsule()
                            .fill(.bar)
                        
                        ProgressView()
                    }
                }
            }
    }
    
    @ViewBuilder
    func customTextField(_ icon: String? = nil, _ paddingTop: CGFloat = 0, _ paddingBottom: CGFloat = 0) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            self
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(.bar, in: .rect(cornerRadius: 10))
        .padding(.horizontal, 15)
        .padding(.top, paddingTop + 7)
        .padding(.bottom, paddingBottom + 7)
        .listRowInsets(.init(top: 10, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview {
    ContentView()
}

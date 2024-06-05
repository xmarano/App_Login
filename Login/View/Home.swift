//
//  Home.swift
//  Login
//
//  Created by Léo Grégori on 05/06/2024.
//

import SwiftUI
import Firebase

struct Home: View {
    @AppStorage("log_status") private var logStatus: Bool = false
    var body: some View {
        NavigationStack{
            Button("Logout") {
                try? Auth.auth().signOut()
                logStatus = false
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    Home()
}

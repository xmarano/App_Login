//
//  LoginApp.swift
//  Login
//
//  Created by Léo Grégori on 05/06/2024.
//

import SwiftUI
import Firebase

@main
struct LoginApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

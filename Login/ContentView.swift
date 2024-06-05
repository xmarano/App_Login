//
//  ContentView.swift
//  Login
//
//  Created by Léo Grégori on 05/06/2024.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @AppStorage("log_status") private var logStatus: Bool = false
    var body: some View {
        if logStatus {
            /// HomeView
            Home()
        } else {
            Login()
        }
    }
}

#Preview {
    ContentView()
}

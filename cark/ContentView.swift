//
//  ContentView.swift
//  cark
//
//  Created by Doğan Topcu on 16.06.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        if let url = URL(string: "https://example.com/default.png") {
            WheelSpinView(userName: "", profileImageURL: url)
        } else {
            Text("Geçersiz profil resmi URL'si")
                .foregroundColor(.red)
        }
    }
}

#Preview {
    ContentView()
}

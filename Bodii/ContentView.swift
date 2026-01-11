//
//  ContentView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

import SwiftUI

// MARK: - Content View

struct ContentView: View {

    // MARK: - Body

    var body: some View {
        VStack {
            Image(systemName: "heart.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Bodii")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Your Health Companion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

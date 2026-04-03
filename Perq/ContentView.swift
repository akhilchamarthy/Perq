//
//  ContentView.swift
//  Perq
//
//  Created by Akhil Chamarthy on 3/30/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = true

    var body: some View {
        ZStack {
            MainTabView()
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                SplashView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.4), value: isLoading)
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            isLoading = false
        }
    }
}

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.7
    @State private var iconOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.perqInk.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                PerqHero()
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer()

                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.perqLavender)

                    Text("Loading your wallet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(subtitleOpacity)
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                subtitleOpacity = 1.0
            }
        }
    }
}

#Preview {
    ContentView()
}

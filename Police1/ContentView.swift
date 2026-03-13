import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App icon placeholder
                Image(systemName: "shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                Text("Police 1")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)

                Text("Protecting & Serving")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                // Example button with glass effect
                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Get Started")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ContentView()
}

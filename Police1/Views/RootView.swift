import SwiftUI

// MARK: - Root View

/// Root view that handles enrollment and authentication state
struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var enrollmentService = EnrollmentService()
    @State private var isEnrolled: Bool?

    var body: some View {
        Group {
            if let enrolled = isEnrolled {
                if enrolled {
                    authStateView
                } else {
                    EnrollmentView { config in
                        // Enrollment complete - reinitialize auth with new config
                        Task {
                            await handleEnrollmentComplete(config)
                        }
                    }
                }
            } else {
                loadingView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEnrolled)
        .animation(.easeInOut(duration: 0.3), value: authManager.state.isAuthenticated)
        .task {
            // Check enrollment status on launch
            isEnrolled = enrollmentService.isEnrolled
            if enrollmentService.isEnrolled {
                await authManager.initialize()
            }
        }
    }

    @ViewBuilder
    private var authStateView: some View {
        switch authManager.state {
        case .unknown:
            loadingView

        case .unauthenticated, .authenticating, .error:
            LoginView()

        case .authenticated:
            MainTabView()
        }
    }

    private func handleEnrollmentComplete(_ config: AuthConfig) async {
        // Create new auth provider from config and update auth manager
        let provider = AuthProviderFactory.create(from: config)
        await authManager.reconfigure(with: provider, config: config)
        isEnrolled = true
        await authManager.initialize()
    }

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Preview

#Preview("Root - Loading") {
    RootView()
        .environmentObject(
            AuthManager(
                provider: MockAuthProvider(),
                sessionStorage: InMemorySessionStorage()
            )
        )
}

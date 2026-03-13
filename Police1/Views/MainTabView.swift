import SwiftUI

// MARK: - Main Tab View

/// Main app view shown after authentication
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    if let user = authManager.currentUser {
                        Text("Welcome, \(user.displayName)")
                            .font(.title2.weight(.semibold))
                    }

                    Text("Dashboard coming soon...")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Home")
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            List {
                if let user = authManager.currentUser {
                    Section {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.gradient)
                                    .frame(width: 60, height: 60)
                                Text(user.initials)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Account") {
                        if let deptId = user.departmentId {
                            LabeledContent("Department", value: deptId)
                        }
                        LabeledContent("Roles", value: user.roles.joined(separator: ", "))
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { await authManager.logout() }
                    } label: {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                            } else {
                                Text("Sign Out")
                            }
                            Spacer()
                        }
                    }
                    .disabled(authManager.isLoading)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Previews

#Preview("Main Tab View") {
    let authManager = AuthManager(
        provider: MockAuthProvider.instant,
        sessionStorage: InMemorySessionStorage()
    )
    // Simulate logged in state
    let session = AuthSession(
        userId: "1",
        accessToken: "token",
        refreshToken: nil,
        expiresAt: Date().addingTimeInterval(3600),
        user: AuthUser(
            id: "1",
            email: "officer@pd.local",
            displayName: "Officer Smith",
            departmentId: "DEPT-001",
            roles: ["officer"],
            avatarUrl: nil
        )
    )

    return MainTabView()
        .environmentObject(authManager)
        .onAppear {
            // Force authenticated state for preview
        }
}

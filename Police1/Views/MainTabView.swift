import SwiftUI

// MARK: - Main Tab View

/// Main app view shown after authentication
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            ReportsListView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }

            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "clock.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Activity View

struct ActivityView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    ActivityRow(
                        icon: "doc.text.fill",
                        title: "Report submitted",
                        subtitle: "Case #2026-45892 - Theft",
                        time: "2 hours ago",
                        color: .blue
                    )
                    ActivityRow(
                        icon: "checkmark.circle.fill",
                        title: "Report approved",
                        subtitle: "Case #2026-45801 - Traffic Accident",
                        time: "5 hours ago",
                        color: .green
                    )
                }

                Section("Yesterday") {
                    ActivityRow(
                        icon: "pencil.circle.fill",
                        title: "Report edited",
                        subtitle: "Case #2026-45756 - Domestic Disturbance",
                        time: "Yesterday at 3:45 PM",
                        color: .orange
                    )
                    ActivityRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Sync completed",
                        subtitle: "3 reports synced",
                        time: "Yesterday at 2:30 PM",
                        color: .purple
                    )
                }
            }
            .navigationTitle("Activity")
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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

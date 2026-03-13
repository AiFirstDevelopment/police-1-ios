import XCTest
@testable import Police1

@MainActor
final class AuthManagerTests: XCTestCase {

    // MARK: - Test Helpers

    private func createTestUser() -> AuthUser {
        AuthUser(
            id: "user-1",
            email: "officer@pd.local",
            displayName: "Test Officer",
            departmentId: "dept-1",
            roles: ["officer"],
            avatarUrl: nil
        )
    }

    private func createTestSession() -> AuthSession {
        AuthSession(
            userId: "user-1",
            accessToken: "existing-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(3600),
            user: createTestUser()
        )
    }

    // MARK: - Reconfigure Tests

    func testReconfigureClearsSession() async {
        // Given: An auth manager with a saved session
        let sessionStorage = InMemorySessionStorage()
        sessionStorage.save(createTestSession())

        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: .mock,
            sessionStorage: sessionStorage
        )

        // Verify session exists before reconfigure
        XCTAssertNotNil(sessionStorage.load())

        // When: Reconfigure with a new provider
        let newProvider = MockAuthProvider()
        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.badgeNumber],
            mfa: nil,
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )
        await authManager.reconfigure(with: newProvider, config: newConfig)

        // Then: Session should be cleared
        XCTAssertNil(sessionStorage.load())
    }

    func testReconfigureSetsStateToUnauthenticated() async {
        // Given: An auth manager
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )

        // When: Reconfigure with a new provider
        let newProvider = MockAuthProvider()
        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.email],
            mfa: nil,
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )
        await authManager.reconfigure(with: newProvider, config: newConfig)

        // Then: State should be unauthenticated
        XCTAssertEqual(authManager.state, .unauthenticated)
    }

    func testReconfigureClearsMFAPending() async {
        // Given: An auth manager (mfaPending would be set during MFA flow)
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )

        // When: Reconfigure with a new provider
        let newProvider = MockAuthProvider()
        await authManager.reconfigure(with: newProvider, config: .mock)

        // Then: MFA pending should be nil
        XCTAssertNil(authManager.mfaPending)
    }

    func testReconfigureUpdatesConfig() async {
        // Given: An auth manager with default config
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )

        // When: Reconfigure with a new config
        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.badgeNumber, .employeeId],
            mfa: MFAConfig(
                required: true,
                methods: [.biometric],
                graceperiodDays: 0,
                rememberDeviceDays: nil
            ),
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )
        await authManager.reconfigure(with: MockAuthProvider(), config: newConfig)

        // Then: Config should be updated
        XCTAssertEqual(authManager.loginIdentifiers, [.badgeNumber, .employeeId])
        XCTAssertTrue(authManager.isMFARequired)
    }

    // MARK: - Initialize Tests

    func testInitializeWithNoSessionSetsUnauthenticated() async {
        // Given: An auth manager with no saved session
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )

        // When: Initialize
        await authManager.initialize()

        // Then: State should be unauthenticated
        XCTAssertEqual(authManager.state, .unauthenticated)
    }

    func testInitializeWithValidSessionSetsAuthenticated() async {
        // Given: An auth manager with a valid saved session
        let sessionStorage = InMemorySessionStorage()
        sessionStorage.save(createTestSession())

        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: sessionStorage
        )

        // When: Initialize
        await authManager.initialize()

        // Then: State should be authenticated
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertEqual(authManager.currentUser?.email, "officer@pd.local")
    }

    // MARK: - Login Tests

    func testLoginWithValidCredentials() async {
        // Given: An auth manager
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )

        // When: Login with valid credentials
        await authManager.login(username: "officer@pd.local", password: "test-password")

        // Then: Should be authenticated
        XCTAssertTrue(authManager.isAuthenticated)
    }

    func testLoginWithInvalidCredentials() async {
        // Given: An auth manager
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )

        // When: Login with invalid credentials
        await authManager.login(username: "officer@pd.local", password: "wrong-password")

        // Then: Should be in error state
        if case .error = authManager.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
    }

    // MARK: - Logout Tests

    func testLogoutClearsSession() async {
        // Given: An authenticated auth manager
        let sessionStorage = InMemorySessionStorage()
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: sessionStorage
        )
        await authManager.login(username: "officer@pd.local", password: "test-password")
        XCTAssertTrue(authManager.isAuthenticated)

        // When: Logout
        await authManager.logout()

        // Then: Should be unauthenticated and session cleared
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(sessionStorage.load())
    }

    // MARK: - Clear Error Tests

    func testClearErrorResetsToUnauthenticated() async {
        // Given: An auth manager in error state
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            sessionStorage: InMemorySessionStorage()
        )
        await authManager.login(username: "officer@pd.local", password: "wrong-password")

        if case .error = authManager.state {
            // Good, we're in error state
        } else {
            XCTFail("Expected error state")
            return
        }

        // When: Clear error
        authManager.clearError()

        // Then: Should be unauthenticated
        XCTAssertEqual(authManager.state, .unauthenticated)
    }
}

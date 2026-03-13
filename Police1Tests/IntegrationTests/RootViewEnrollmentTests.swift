import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// MARK: - RootView Enrollment Tests

@MainActor
final class RootViewEnrollmentTests: XCTestCase {

    // MARK: - Test Helpers

    private func createAuthManager(
        provider: AuthProvider = MockAuthProvider(),
        config: AuthConfig = .mock,
        sessionStorage: SessionStorage = InMemorySessionStorage()
    ) -> AuthManager {
        AuthManager(provider: provider, config: config, sessionStorage: sessionStorage)
    }

    // MARK: - Gradient Background Tests

    func testRootViewHasGradientBackgroundWhenLoading() throws {
        let authManager = createAuthManager()
        let view = RootView()
            .environmentObject(authManager)

        let sut = try view.inspect()
        let gradient = try sut.find(ViewType.LinearGradient.self)
        XCTAssertNotNil(gradient)
    }

    // MARK: - Loading State Tests

    func testRootViewShowsImagesWhenLoading() throws {
        let authManager = createAuthManager()
        let view = RootView()
            .environmentObject(authManager)

        let sut = try view.inspect()
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testRootViewShowsProgressIndicatorWhenLoading() throws {
        let authManager = createAuthManager()
        let view = RootView()
            .environmentObject(authManager)

        let sut = try view.inspect()
        let progressView = try sut.find(ViewType.ProgressView.self)
        XCTAssertNotNil(progressView)
    }
}

// MARK: - AuthManager Reconfigure Tests

@MainActor
final class AuthManagerReconfigureTests: XCTestCase {

    func testReconfigureUpdatesProvider() async {
        let initialProvider = MockAuthProvider()
        let authManager = AuthManager(
            provider: initialProvider,
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )

        let newProvider = MockAuthProvider()
        newProvider.simulatedDelay = 0.1 // Different from default

        let newConfig = AuthConfig(
            providerType: .oauth,
            loginIdentifiers: [.email],
            mfa: nil,
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: BrandingConfig(
                departmentName: "Test Department",
                logoUrl: nil,
                primaryColor: nil,
                supportEmail: nil,
                supportPhone: nil
            )
        )

        await authManager.reconfigure(with: newProvider, config: newConfig)

        // Verify config was updated
        XCTAssertEqual(authManager.config.providerType, .oauth)
        XCTAssertEqual(authManager.config.branding?.departmentName, "Test Department")
    }

    func testReconfigureResetsStateToUnknown() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )

        // First authenticate
        await authManager.login(username: "officer@pd.local", password: "test-password")
        XCTAssertTrue(authManager.isAuthenticated)

        // Now reconfigure
        await authManager.reconfigure(with: MockAuthProvider(), config: .mock)

        // State should be reset
        XCTAssertFalse(authManager.isAuthenticated)
    }

    func testReconfigureClearsMFAPending() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )

        // Reconfigure clears mfaPending
        await authManager.reconfigure(with: MockAuthProvider(), config: .mock)

        // MFA pending should be nil
        XCTAssertNil(authManager.mfaPending)
    }

    func testReconfigureAllowsNewLogin() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )

        // Reconfigure with new provider
        let newProvider = MockAuthProvider()
        newProvider.simulatedDelay = 0
        await authManager.reconfigure(with: newProvider, config: .mock)

        // Should be able to initialize and login
        await authManager.initialize()
        await authManager.login(username: "officer@pd.local", password: "test-password")

        XCTAssertTrue(authManager.isAuthenticated)
    }

    func testReconfigureUpdatesLoginIdentifiers() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: AuthConfig(
                providerType: .mock,
                loginIdentifiers: [.email],
                mfa: nil,
                oauth: nil,
                saml: nil,
                ldap: nil,
                basic: nil,
                branding: nil
            ),
            sessionStorage: InMemorySessionStorage()
        )

        XCTAssertEqual(authManager.loginIdentifiers, [.email])

        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.badgeNumber, .employeeId],
            mfa: nil,
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )

        await authManager.reconfigure(with: MockAuthProvider(), config: newConfig)

        XCTAssertEqual(authManager.loginIdentifiers, [.badgeNumber, .employeeId])
    }

    func testReconfigureUpdatesPrimaryIdentifier() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: AuthConfig(
                providerType: .mock,
                loginIdentifiers: [.email, .badgeNumber],
                mfa: nil,
                oauth: nil,
                saml: nil,
                ldap: nil,
                basic: nil,
                branding: nil
            ),
            sessionStorage: InMemorySessionStorage()
        )

        XCTAssertEqual(authManager.primaryIdentifier, .email)

        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.badgeNumber, .email],
            mfa: nil,
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )

        await authManager.reconfigure(with: MockAuthProvider(), config: newConfig)

        XCTAssertEqual(authManager.primaryIdentifier, .badgeNumber)
    }

    func testReconfigureUpdatesMFARequired() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: AuthConfig(
                providerType: .mock,
                loginIdentifiers: [.email],
                mfa: nil,
                oauth: nil,
                saml: nil,
                ldap: nil,
                basic: nil,
                branding: nil
            ),
            sessionStorage: InMemorySessionStorage()
        )

        XCTAssertFalse(authManager.isMFARequired)

        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.email],
            mfa: MFAConfig(required: true, methods: [.biometric], graceperiodDays: 0, rememberDeviceDays: nil),
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )

        await authManager.reconfigure(with: MockAuthProvider(), config: newConfig)

        XCTAssertTrue(authManager.isMFARequired)
    }

    func testReconfigureUpdatesAvailableMFAMethods() async {
        let authManager = AuthManager(
            provider: MockAuthProvider(),
            config: AuthConfig(
                providerType: .mock,
                loginIdentifiers: [.email],
                mfa: MFAConfig(required: true, methods: [.otp], graceperiodDays: 0, rememberDeviceDays: nil),
                oauth: nil,
                saml: nil,
                ldap: nil,
                basic: nil,
                branding: nil
            ),
            sessionStorage: InMemorySessionStorage()
        )

        XCTAssertEqual(authManager.availableMFAMethods, [.otp])

        let newConfig = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.email],
            mfa: MFAConfig(required: true, methods: [.biometric, .pushNotification], graceperiodDays: 0, rememberDeviceDays: nil),
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )

        await authManager.reconfigure(with: MockAuthProvider(), config: newConfig)

        XCTAssertEqual(authManager.availableMFAMethods, [.biometric, .pushNotification])
    }
}

// MARK: - ViewInspector Extensions

extension RootView: @retroactive Inspectable {}

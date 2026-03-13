import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// MARK: - LoginView Tests

@MainActor
final class LoginViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func createAuthManager(
        loginIdentifiers: [LoginIdentifierType] = [.email, .badgeNumber],
        mfa: MFAConfig? = nil
    ) -> AuthManager {
        let config = AuthConfig(
            providerType: .mock,
            loginIdentifiers: loginIdentifiers,
            mfa: mfa,
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )
        return AuthManager(
            provider: MockAuthProvider(),
            config: config,
            sessionStorage: InMemorySessionStorage()
        )
    }

    // MARK: - Structure Tests

    func testLoginViewHasGradientBackground() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let gradient = try sut.find(ViewType.LinearGradient.self)
        XCTAssertNotNil(gradient)
    }

    func testLoginViewHasScrollView() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let scrollView = try sut.find(ViewType.ScrollView.self)
        XCTAssertNotNil(scrollView)
    }

    func testLoginViewHasShieldImage() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testLoginViewHasTextFields() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let textFields = sut.findAll(ViewType.TextField.self)
        XCTAssertGreaterThanOrEqual(textFields.count, 1)
    }

    func testLoginViewHasSecureField() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let secureFields = sut.findAll(ViewType.SecureField.self)
        XCTAssertGreaterThanOrEqual(secureFields.count, 1)
    }

    func testLoginViewHasButtons() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1)
    }

    func testLoginViewHasMultipleTexts() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        // Should have: "Police 1", "Protecting & Serving", field labels, button text, dev hints
        XCTAssertGreaterThanOrEqual(texts.count, 5)
    }

    // MARK: - Identifier Picker Tests

    func testLoginViewShowsIdentifierPickerWithMultipleTypes() throws {
        let authManager = createAuthManager(loginIdentifiers: [.email, .badgeNumber, .employeeId])
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        // Should have identifier type picker buttons
        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 3) // 3 picker buttons + login + show password
    }

    func testLoginViewHidesPickerWithSingleIdentifier() throws {
        let authManager = createAuthManager(loginIdentifiers: [.badgeNumber])
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        // Fewer buttons when only one identifier type
        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertLessThanOrEqual(buttons.count, 3) // login + show password + maybe clear
    }

    // MARK: - VStack Structure Tests

    func testLoginViewHasVStack() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testLoginViewHasHStack() throws {
        let authManager = createAuthManager()
        let view = LoginView().environmentObject(authManager)
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }
}

// MARK: - MFAVerificationView Tests

@MainActor
final class MFAVerificationViewTests: XCTestCase {

    private func createAuthManager(mfaMethods: [MFAMethodType] = [.biometric, .otp]) -> AuthManager {
        let config = AuthConfig(
            providerType: .mock,
            loginIdentifiers: [.email],
            mfa: MFAConfig(required: true, methods: mfaMethods, graceperiodDays: 0, rememberDeviceDays: nil),
            oauth: nil,
            saml: nil,
            ldap: nil,
            basic: nil,
            branding: nil
        )
        return AuthManager(
            provider: MockAuthProvider(),
            config: config,
            sessionStorage: InMemorySessionStorage()
        )
    }

    func testMFAVerificationViewHasNavigationStack() throws {
        let authManager = createAuthManager()
        let view = MFAVerificationView().environmentObject(authManager)
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testMFAVerificationViewHasVStack() throws {
        let authManager = createAuthManager()
        let view = MFAVerificationView().environmentObject(authManager)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testMFAVerificationViewHasImages() throws {
        let authManager = createAuthManager()
        let view = MFAVerificationView().environmentObject(authManager)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1) // lock.shield icon
    }

    func testMFAVerificationViewHasTexts() throws {
        let authManager = createAuthManager()
        let view = MFAVerificationView().environmentObject(authManager)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2) // Title and description
    }

    func testMFAVerificationViewWithOTPHasTextField() throws {
        let authManager = createAuthManager(mfaMethods: [.otp])
        let view = MFAVerificationView().environmentObject(authManager)
        let sut = try view.inspect()

        let textFields = sut.findAll(ViewType.TextField.self)
        XCTAssertGreaterThanOrEqual(textFields.count, 1)
    }

    func testMFAVerificationViewHasButtons() throws {
        let authManager = createAuthManager(mfaMethods: [.otp])
        let view = MFAVerificationView().environmentObject(authManager)
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1) // Verify button, Cancel in toolbar
    }
}

// MARK: - ViewInspector Extensions

extension LoginView: @retroactive Inspectable {}
extension MFAVerificationView: @retroactive Inspectable {}

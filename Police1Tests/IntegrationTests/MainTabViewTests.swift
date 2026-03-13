import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// MARK: - MainTabView Tests

@MainActor
final class MainTabViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func createAuthenticatedAuthManager() -> AuthManager {
        let provider = MockAuthProvider()
        provider.simulatedDelay = 0
        let authManager = AuthManager(
            provider: provider,
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )
        return authManager
    }

    // MARK: - Structure Tests

    func testMainTabViewHasTabView() throws {
        let authManager = createAuthenticatedAuthManager()
        let view = MainTabView().environmentObject(authManager)
        let sut = try view.inspect()

        let tabView = try sut.find(ViewType.TabView.self)
        XCTAssertNotNil(tabView)
    }
}

// MARK: - HomeView Tests

@MainActor
final class HomeViewTests: XCTestCase {

    private func createAuthManager() -> AuthManager {
        let provider = MockAuthProvider()
        provider.simulatedDelay = 0
        return AuthManager(
            provider: provider,
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )
    }

    func testHomeViewHasNavigationStack() throws {
        let authManager = createAuthManager()
        let view = HomeView().environmentObject(authManager)
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testHomeViewHasZStack() throws {
        let authManager = createAuthManager()
        let view = HomeView().environmentObject(authManager)
        let sut = try view.inspect()

        let zstack = try sut.find(ViewType.ZStack.self)
        XCTAssertNotNil(zstack)
    }

    func testHomeViewHasGradient() throws {
        let authManager = createAuthManager()
        let view = HomeView().environmentObject(authManager)
        let sut = try view.inspect()

        let gradient = try sut.find(ViewType.LinearGradient.self)
        XCTAssertNotNil(gradient)
    }

    func testHomeViewHasVStack() throws {
        let authManager = createAuthManager()
        let view = HomeView().environmentObject(authManager)
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    func testHomeViewHasTexts() throws {
        let authManager = createAuthManager()
        let view = HomeView().environmentObject(authManager)
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 1) // "Dashboard coming soon..."
    }
}

// MARK: - ProfileView Tests

@MainActor
final class ProfileViewTests: XCTestCase {

    private func createAuthManager() -> AuthManager {
        let provider = MockAuthProvider()
        provider.simulatedDelay = 0
        return AuthManager(
            provider: provider,
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )
    }

    func testProfileViewHasNavigationStack() throws {
        let authManager = createAuthManager()
        let view = ProfileView().environmentObject(authManager)
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testProfileViewHasList() throws {
        let authManager = createAuthManager()
        let view = ProfileView().environmentObject(authManager)
        let sut = try view.inspect()

        let list = try sut.find(ViewType.List.self)
        XCTAssertNotNil(list)
    }

    func testProfileViewHasSignOutButton() throws {
        let authManager = createAuthManager()
        let view = ProfileView().environmentObject(authManager)
        let sut = try view.inspect()

        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 1) // Sign Out button
    }

    func testProfileViewHasSections() throws {
        let authManager = createAuthManager()
        let view = ProfileView().environmentObject(authManager)
        let sut = try view.inspect()

        let sections = sut.findAll(ViewType.Section.self)
        XCTAssertGreaterThanOrEqual(sections.count, 1)
    }
}

// MARK: - AuthUser Extension Tests

final class AuthUserExtensionTests: XCTestCase {

    func testInitialsWithTwoWordName() {
        let user = AuthUser(
            id: "1",
            email: "test@test.com",
            displayName: "John Smith",
            departmentId: nil,
            roles: [],
            avatarUrl: nil
        )
        XCTAssertEqual(user.initials, "JS")
    }

    func testInitialsWithSingleWordName() {
        let user = AuthUser(
            id: "1",
            email: "test@test.com",
            displayName: "John",
            departmentId: nil,
            roles: [],
            avatarUrl: nil
        )
        XCTAssertEqual(user.initials, "J")
    }

    func testInitialsWithThreeWordName() {
        let user = AuthUser(
            id: "1",
            email: "test@test.com",
            displayName: "John Paul Smith",
            departmentId: nil,
            roles: [],
            avatarUrl: nil
        )
        XCTAssertEqual(user.initials, "JS") // First and last
    }

    func testInitialsWithEmptyName() {
        let user = AuthUser(
            id: "1",
            email: "test@test.com",
            displayName: "",
            departmentId: nil,
            roles: [],
            avatarUrl: nil
        )
        XCTAssertEqual(user.initials, "")
    }
}

// MARK: - ViewInspector Extensions

extension MainTabView: @retroactive Inspectable {}
extension HomeView: @retroactive Inspectable {}
extension ProfileView: @retroactive Inspectable {}

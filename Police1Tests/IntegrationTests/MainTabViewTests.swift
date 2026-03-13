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

// MARK: - ActivityView Tests

@MainActor
final class ActivityViewTests: XCTestCase {

    private func createAuthManager() -> AuthManager {
        let provider = MockAuthProvider()
        provider.simulatedDelay = 0
        return AuthManager(
            provider: provider,
            config: .mock,
            sessionStorage: InMemorySessionStorage()
        )
    }

    func testActivityViewHasNavigationStack() throws {
        let authManager = createAuthManager()
        let view = ActivityView().environmentObject(authManager)
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testActivityViewHasList() throws {
        let authManager = createAuthManager()
        let view = ActivityView().environmentObject(authManager)
        let sut = try view.inspect()

        let list = try sut.find(ViewType.List.self)
        XCTAssertNotNil(list)
    }

    func testActivityViewHasSections() throws {
        let authManager = createAuthManager()
        let view = ActivityView().environmentObject(authManager)
        let sut = try view.inspect()

        let sections = sut.findAll(ViewType.Section.self)
        XCTAssertGreaterThanOrEqual(sections.count, 2) // Today and Yesterday sections
    }

    func testActivityViewHasActivityRows() throws {
        let authManager = createAuthManager()
        let view = ActivityView().environmentObject(authManager)
        let sut = try view.inspect()

        // Activity rows contain HStacks with images and text
        let hstacks = sut.findAll(ViewType.HStack.self)
        XCTAssertGreaterThanOrEqual(hstacks.count, 4) // At least 4 activity items
    }

    func testActivityViewHasImages() throws {
        let authManager = createAuthManager()
        let view = ActivityView().environmentObject(authManager)
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 4) // Icons for each activity
    }
}

// MARK: - ActivityRow Tests

@MainActor
final class ActivityRowTests: XCTestCase {

    func testActivityRowHasHStack() throws {
        let view = ActivityRow(
            icon: "doc.text.fill",
            title: "Test Title",
            subtitle: "Test Subtitle",
            time: "2 hours ago",
            color: .blue
        )
        let sut = try view.inspect()

        let hstack = try sut.find(ViewType.HStack.self)
        XCTAssertNotNil(hstack)
    }

    func testActivityRowHasIcon() throws {
        let view = ActivityRow(
            icon: "doc.text.fill",
            title: "Test Title",
            subtitle: "Test Subtitle",
            time: "2 hours ago",
            color: .blue
        )
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testActivityRowHasTexts() throws {
        let view = ActivityRow(
            icon: "doc.text.fill",
            title: "Test Title",
            subtitle: "Test Subtitle",
            time: "2 hours ago",
            color: .blue
        )
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 3) // title, subtitle, time
    }

    func testActivityRowHasVStack() throws {
        let view = ActivityRow(
            icon: "doc.text.fill",
            title: "Test Title",
            subtitle: "Test Subtitle",
            time: "2 hours ago",
            color: .blue
        )
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
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
extension ActivityView: @retroactive Inspectable {}
extension ActivityRow: @retroactive Inspectable {}
extension ProfileView: @retroactive Inspectable {}

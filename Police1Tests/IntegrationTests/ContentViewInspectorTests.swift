import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// Make ContentView inspectable
extension ContentView: @retroactive Inspectable {}

/// ViewInspector tests - similar to Angular Testing Library
/// These tests query the view hierarchy like a user would see it
final class ContentViewInspectorTests: XCTestCase {

    // MARK: - Test that UI elements exist

    func testContentViewHasTitle() throws {
        let sut = ContentView()

        // Find the "Police 1" text
        let title = try sut.inspect().find(text: "Police 1")
        XCTAssertNotNil(title)
    }

    func testContentViewHasSubtitle() throws {
        let sut = ContentView()

        // Find the subtitle text
        let subtitle = try sut.inspect().find(text: "Protecting & Serving")
        XCTAssertNotNil(subtitle)
    }

    func testContentViewHasGetStartedButton() throws {
        let sut = ContentView()

        // Find button with "Get Started" text
        let buttonText = try sut.inspect().find(text: "Get Started")
        XCTAssertNotNil(buttonText)
    }

    func testContentViewHasShieldIcon() throws {
        let sut = ContentView()

        // Find the shield SF Symbol
        let image = try sut.inspect().find(ViewType.Image.self) { view in
            // Check if it's a system image named "shield.fill"
            let name = try? view.actualImage().name()
            return name == "shield.fill"
        }
        XCTAssertNotNil(image)
    }

    // MARK: - Test view hierarchy structure

    func testContentViewHasZStackAtRoot() throws {
        let sut = ContentView()

        // The root should be a ZStack
        let zStack = try sut.inspect().zStack()
        XCTAssertNotNil(zStack)
    }

    func testContentViewHasVStackForContent() throws {
        let sut = ContentView()

        // Should have a VStack inside the ZStack
        let vStack = try sut.inspect().find(ViewType.VStack.self)
        XCTAssertNotNil(vStack)
    }

    func testContentViewHasGradientBackground() throws {
        let sut = ContentView()

        // Should have a LinearGradient
        let gradient = try sut.inspect().find(ViewType.LinearGradient.self)
        XCTAssertNotNil(gradient)
    }

    // MARK: - Test button interaction

    func testGetStartedButtonIsTappable() throws {
        let sut = ContentView()

        // Find the button and verify it exists
        let button = try sut.inspect().find(ViewType.Button.self)
        XCTAssertNotNil(button)

        // Verify we can tap it (doesn't throw)
        XCTAssertNoThrow(try button.tap())
    }
}

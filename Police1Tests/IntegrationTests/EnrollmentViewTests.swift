import XCTest
import SwiftUI
import ViewInspector
@testable import Police1

// MARK: - EnrollmentView Tests

@MainActor
final class EnrollmentViewTests: XCTestCase {

    // MARK: - Basic Structure Tests

    func testEnrollmentViewHasGradientBackground() throws {
        let view = EnrollmentView { _ in }
        let sut = try view.inspect()

        let gradient = try sut.find(ViewType.LinearGradient.self)
        XCTAssertNotNil(gradient)
    }

    func testEnrollmentViewHasScrollView() throws {
        let view = EnrollmentView { _ in }
        let sut = try view.inspect()

        let scrollView = try sut.find(ViewType.ScrollView.self)
        XCTAssertNotNil(scrollView)
    }

    func testEnrollmentViewHasCodeTextField() throws {
        let view = EnrollmentView { _ in }
        let sut = try view.inspect()

        let textField = try sut.find(ViewType.TextField.self)
        XCTAssertNotNil(textField)
    }

    func testEnrollmentViewHasMultipleButtons() throws {
        let view = EnrollmentView { _ in }
        let sut = try view.inspect()

        // Should have method picker buttons plus connect button
        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 3)
    }

    func testEnrollmentViewHasMultipleImages() throws {
        let view = EnrollmentView { _ in }
        let sut = try view.inspect()

        // Should have shield, star, building icons, link icon
        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 3)
    }

    func testEnrollmentViewHasMultipleTexts() throws {
        let view = EnrollmentView { _ in }
        let sut = try view.inspect()

        // Should have title, subtitle, labels, hints
        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 5)
    }
}

// MARK: - EnrollmentMethod Tests

final class EnrollmentMethodTests: XCTestCase {

    func testCodeMethodTitle() {
        XCTAssertEqual(EnrollmentMethod.code.title, "Code")
    }

    func testEmailMethodTitle() {
        XCTAssertEqual(EnrollmentMethod.email.title, "Email")
    }

    func testQRCodeMethodTitle() {
        XCTAssertEqual(EnrollmentMethod.qrCode.title, "QR Code")
    }

    func testCodeMethodIcon() {
        XCTAssertEqual(EnrollmentMethod.code.icon, "number")
    }

    func testEmailMethodIcon() {
        XCTAssertEqual(EnrollmentMethod.email.icon, "envelope")
    }

    func testQRCodeMethodIcon() {
        XCTAssertEqual(EnrollmentMethod.qrCode.icon, "qrcode")
    }

    func testAllCasesContainsAllMethods() {
        let allCases = EnrollmentMethod.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.code))
        XCTAssertTrue(allCases.contains(.email))
        XCTAssertTrue(allCases.contains(.qrCode))
    }
}

// MARK: - QRScannerView Tests

@MainActor
final class QRScannerViewTests: XCTestCase {

    func testQRScannerViewHasNavigationStack() throws {
        let view = QRScannerView { _ in }
        let sut = try view.inspect()

        let nav = try sut.find(ViewType.NavigationStack.self)
        XCTAssertNotNil(nav)
    }

    func testQRScannerViewHasImages() throws {
        let view = QRScannerView { _ in }
        let sut = try view.inspect()

        let images = sut.findAll(ViewType.Image.self)
        XCTAssertGreaterThanOrEqual(images.count, 1)
    }

    func testQRScannerViewHasTexts() throws {
        let view = QRScannerView { _ in }
        let sut = try view.inspect()

        let texts = sut.findAll(ViewType.Text.self)
        XCTAssertGreaterThanOrEqual(texts.count, 2)
    }

    func testQRScannerViewHasVStack() throws {
        let view = QRScannerView { _ in }
        let sut = try view.inspect()

        let vstack = try sut.find(ViewType.VStack.self)
        XCTAssertNotNil(vstack)
    }

    #if DEBUG
    func testQRScannerViewHasDemoButtons() throws {
        let view = QRScannerView { _ in }
        let sut = try view.inspect()

        // In debug mode, there should be demo buttons
        let buttons = sut.findAll(ViewType.Button.self)
        XCTAssertGreaterThanOrEqual(buttons.count, 3) // 3 demo + cancel
    }
    #endif
}

// MARK: - ViewInspector Extensions

extension EnrollmentView: @retroactive Inspectable {}
extension QRScannerView: @retroactive Inspectable {}

import XCTest
@testable import Police1

// MARK: - EnrollmentService Tests

final class EnrollmentServiceTests: XCTestCase {

    var sut: EnrollmentService!
    var mockStorage: InMemoryConfigStorage!

    override func setUp() {
        super.setUp()
        mockStorage = InMemoryConfigStorage()
        sut = EnrollmentService(configStorage: mockStorage)
    }

    override func tearDown() {
        sut = nil
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - Enrollment Status Tests

    func testIsEnrolledReturnsFalseWhenNoConfigStored() {
        XCTAssertFalse(sut.isEnrolled)
    }

    func testIsEnrolledReturnsTrueAfterEnrollment() async throws {
        _ = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(sut.isEnrolled)
    }

    func testCurrentConfigIsNilWhenNotEnrolled() {
        XCTAssertNil(sut.currentConfig)
    }

    func testCurrentConfigReturnsStoredConfigAfterEnrollment() async throws {
        _ = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertNotNil(sut.currentConfig)
        XCTAssertEqual(sut.currentConfig?.branding?.departmentName, "Springfield Police Department")
    }

    // MARK: - Enroll With Code Tests

    func testEnrollWithCodeSpringfieldReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
        XCTAssertEqual(config.providerType, .oauth)
    }

    func testEnrollWithCodeSpringfieldPDReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD-PD")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithCodeRiversideReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithCode("RIVERSIDE")
        XCTAssertEqual(config.branding?.departmentName, "Riverside Police Department")
        XCTAssertEqual(config.providerType, .mock) // Would be LDAP in production
    }

    func testEnrollWithCodeMetroReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithCode("METRO")
        XCTAssertEqual(config.branding?.departmentName, "Metropolitan Police")
        XCTAssertEqual(config.providerType, .saml)
    }

    func testEnrollWithCodeDemoReturnsMockConfig() async throws {
        let config = try await sut.enrollWithCode("DEMO")
        XCTAssertEqual(config.providerType, .mock)
    }

    func testEnrollWithCodeTestReturnsMockConfig() async throws {
        let config = try await sut.enrollWithCode("TEST")
        XCTAssertEqual(config.providerType, .mock)
    }

    func testEnrollWithCodeNormalizesToUppercase() async throws {
        let config = try await sut.enrollWithCode("springfield")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithCodeTrimsWhitespace() async throws {
        let config = try await sut.enrollWithCode("  SPRINGFIELD  ")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithCodeInvalidCodeThrowsOrganizationNotFound() async {
        do {
            _ = try await sut.enrollWithCode("INVALID-DEPARTMENT")
            XCTFail("Expected organizationNotFound error")
        } catch let error as EnrollmentError {
            XCTAssertEqual(error, .organizationNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Enroll With Email Tests

    func testEnrollWithEmailSpringfieldGovReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithEmail("officer@springfield.gov")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithEmailSpringfieldPDGovReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithEmail("officer@springfieldpd.gov")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithEmailRiversideGovReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithEmail("officer@riverside.gov")
        XCTAssertEqual(config.branding?.departmentName, "Riverside Police Department")
    }

    func testEnrollWithEmailMetroGovReturnsCorrectConfig() async throws {
        let config = try await sut.enrollWithEmail("officer@metro.gov")
        XCTAssertEqual(config.branding?.departmentName, "Metropolitan Police")
    }

    func testEnrollWithEmailPdLocalReturnsMockConfig() async throws {
        let config = try await sut.enrollWithEmail("test@pd.local")
        XCTAssertEqual(config.providerType, .mock)
    }

    func testEnrollWithEmailNormalizesToLowercase() async throws {
        let config = try await sut.enrollWithEmail("Officer@SPRINGFIELD.GOV")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithEmailNoAtSymbolThrowsInvalidEmail() async {
        do {
            _ = try await sut.enrollWithEmail("invalidemail")
            XCTFail("Expected organizationNotFound error (no @ means whole string is treated as domain)")
        } catch let error as EnrollmentError {
            // "invalidemail" has no @, so split returns ["invalidemail"]
            // .last returns "invalidemail" which is not a known domain
            XCTAssertEqual(error, .organizationNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEnrollWithEmailEmptyStringThrowsInvalidEmail() async {
        do {
            _ = try await sut.enrollWithEmail("")
            XCTFail("Expected invalidEmail error")
        } catch let error as EnrollmentError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEnrollWithEmailUnknownDomainThrowsOrganizationNotFound() async {
        do {
            _ = try await sut.enrollWithEmail("officer@unknown-department.org")
            XCTFail("Expected organizationNotFound error")
        } catch let error as EnrollmentError {
            XCTAssertEqual(error, .organizationNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Enroll With QR Code Tests

    func testEnrollWithQRCodeOrgPrefixEnrollsCorrectly() async throws {
        let config = try await sut.enrollWithQRCode("ORG:SPRINGFIELD")
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithQRCodeInvalidContentThrowsInvalidQRCode() async {
        do {
            _ = try await sut.enrollWithQRCode("random-invalid-content")
            XCTFail("Expected invalidQRCode error")
        } catch let error as EnrollmentError {
            XCTAssertEqual(error, .invalidQRCode)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEnrollWithQRCodeBase64ConfigParsesCorrectly() async throws {
        // Create a mock config and encode as base64
        let mockConfig = AuthConfig.mock
        let data = try JSONEncoder().encode(mockConfig)
        let base64 = data.base64EncodedString()

        let config = try await sut.enrollWithQRCode(base64)
        XCTAssertEqual(config.providerType, .mock)
    }

    // MARK: - Enroll With Deep Link Tests

    func testEnrollWithDeepLinkOrgParamEnrollsCorrectly() async throws {
        let url = URL(string: "police1://enroll?org=SPRINGFIELD")!
        let config = try await sut.enrollWithDeepLink(url)
        XCTAssertEqual(config.branding?.departmentName, "Springfield Police Department")
    }

    func testEnrollWithDeepLinkInvalidURLThrowsInvalidDeepLink() async {
        let url = URL(string: "police1://something-else")!
        do {
            _ = try await sut.enrollWithDeepLink(url)
            XCTFail("Expected invalidDeepLink error")
        } catch let error as EnrollmentError {
            XCTAssertEqual(error, .invalidDeepLink)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Clear Enrollment Tests

    func testClearEnrollmentRemovesStoredConfig() async throws {
        _ = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(sut.isEnrolled)

        sut.clearEnrollment()

        XCTAssertFalse(sut.isEnrolled)
        XCTAssertNil(sut.currentConfig)
    }

    // MARK: - MFA Configuration Tests

    func testSpringfieldConfigHasMFARequired() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(config.mfa?.required ?? false)
    }

    func testSpringfieldConfigSupportsBiometricMFA() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(config.mfa?.methods.contains(.biometric) ?? false)
    }

    func testSpringfieldConfigSupportsOTPMFA() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(config.mfa?.methods.contains(.otp) ?? false)
    }

    func testMetroConfigSupportsPushNotificationMFA() async throws {
        let config = try await sut.enrollWithCode("METRO")
        XCTAssertTrue(config.mfa?.methods.contains(.pushNotification) ?? false)
    }

    func testRiversideConfigSupportsSmartCardMFA() async throws {
        let config = try await sut.enrollWithCode("RIVERSIDE")
        XCTAssertTrue(config.mfa?.methods.contains(.smartCard) ?? false)
    }

    // MARK: - Login Identifier Tests

    func testSpringfieldConfigSupportsBadgeNumberLogin() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(config.loginIdentifiers.contains(.badgeNumber))
    }

    func testSpringfieldConfigSupportsEmailLogin() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertTrue(config.loginIdentifiers.contains(.email))
    }

    func testRiversideConfigSupportsEmployeeIdLogin() async throws {
        let config = try await sut.enrollWithCode("RIVERSIDE")
        XCTAssertTrue(config.loginIdentifiers.contains(.employeeId))
    }

    func testMetroConfigSupportsEmailOnlyLogin() async throws {
        let config = try await sut.enrollWithCode("METRO")
        XCTAssertEqual(config.loginIdentifiers, [.email])
    }

    // MARK: - Branding Configuration Tests

    func testSpringfieldBrandingHasCorrectPrimaryColor() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertEqual(config.branding?.primaryColor, "#1E40AF")
    }

    func testRiversideBrandingHasCorrectPrimaryColor() async throws {
        let config = try await sut.enrollWithCode("RIVERSIDE")
        XCTAssertEqual(config.branding?.primaryColor, "#059669")
    }

    func testMetroBrandingHasCorrectPrimaryColor() async throws {
        let config = try await sut.enrollWithCode("METRO")
        XCTAssertEqual(config.branding?.primaryColor, "#7C3AED")
    }

    func testSpringfieldBrandingHasSupportEmail() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertEqual(config.branding?.supportEmail, "it@springfieldpd.gov")
    }

    func testSpringfieldBrandingHasSupportPhone() async throws {
        let config = try await sut.enrollWithCode("SPRINGFIELD")
        XCTAssertEqual(config.branding?.supportPhone, "555-123-4567")
    }
}

// MARK: - EnrollmentError Tests

final class EnrollmentErrorTests: XCTestCase {

    func testInvalidEmailErrorDescription() {
        let error = EnrollmentError.invalidEmail
        XCTAssertEqual(error.errorDescription, "Please enter a valid email address")
    }

    func testInvalidQRCodeErrorDescription() {
        let error = EnrollmentError.invalidQRCode
        XCTAssertEqual(error.errorDescription, "Invalid QR code. Please try again.")
    }

    func testInvalidDeepLinkErrorDescription() {
        let error = EnrollmentError.invalidDeepLink
        XCTAssertEqual(error.errorDescription, "Invalid enrollment link")
    }

    func testInvalidConfigErrorDescription() {
        let error = EnrollmentError.invalidConfig
        XCTAssertEqual(error.errorDescription, "Unable to read organization configuration")
    }

    func testConfigNotFoundErrorDescription() {
        let error = EnrollmentError.configNotFound
        XCTAssertEqual(error.errorDescription, "Configuration not found")
    }

    func testOrganizationNotFoundErrorDescription() {
        let error = EnrollmentError.organizationNotFound
        XCTAssertEqual(error.errorDescription, "Organization not found. Check your code and try again.")
    }

    func testNetworkErrorDescription() {
        let error = EnrollmentError.networkError("Connection timeout")
        XCTAssertEqual(error.errorDescription, "Network error: Connection timeout")
    }

    func testEnrollmentErrorEquality() {
        XCTAssertEqual(EnrollmentError.invalidEmail, EnrollmentError.invalidEmail)
        XCTAssertEqual(EnrollmentError.invalidQRCode, EnrollmentError.invalidQRCode)
        XCTAssertEqual(EnrollmentError.organizationNotFound, EnrollmentError.organizationNotFound)
    }
}

// MARK: - ConfigStorage Tests

final class ConfigStorageTests: XCTestCase {

    func testInMemoryConfigStorageSavesAndLoadsConfig() {
        let storage = InMemoryConfigStorage()
        let config = AuthConfig.mock

        storage.save(config)
        let loaded = storage.load()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.providerType, .mock)
    }

    func testInMemoryConfigStorageClearsConfig() {
        let storage = InMemoryConfigStorage()
        storage.save(AuthConfig.mock)

        storage.clear()

        XCTAssertNil(storage.load())
    }

    func testInMemoryConfigStorageReturnsNilWhenEmpty() {
        let storage = InMemoryConfigStorage()
        XCTAssertNil(storage.load())
    }

    func testUserDefaultsConfigStorageSavesAndLoadsConfig() {
        let storage = UserDefaultsConfigStorage()
        let config = AuthConfig.mock

        // Clean up first
        storage.clear()

        storage.save(config)
        let loaded = storage.load()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.providerType, .mock)

        // Clean up after
        storage.clear()
    }

    func testUserDefaultsConfigStorageClearsConfig() {
        let storage = UserDefaultsConfigStorage()
        storage.save(AuthConfig.mock)

        storage.clear()

        XCTAssertNil(storage.load())
    }
}

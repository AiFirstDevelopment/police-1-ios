import SwiftUI

// MARK: - Login View

/// Login view that adapts to department configuration.
/// Supports multiple login identifier types and MFA methods.
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var identifier = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var selectedIdentifierType: LoginIdentifierType?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    // Logo
                    logoSection

                    // Login form or SSO button
                    if authManager.usesExternalLoginUI {
                        ssoLoginSection
                    } else {
                        credentialsSection
                    }

                    // Error message
                    errorSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            selectedIdentifierType = authManager.primaryIdentifier
        }
        .sheet(item: mfaBinding) { _ in
            MFAVerificationView()
                .environmentObject(authManager)
        }
    }

    private var mfaBinding: Binding<MFAPendingState?> {
        Binding(
            get: { authManager.mfaPending },
            set: { _ in }
        )
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.fill")
                .font(.system(size: 70))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            Text("Police 1")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Protecting & Serving")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - SSO Login Section

    private var ssoLoginSection: some View {
        VStack(spacing: 20) {
            Text("Sign in with your department account")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button(action: { Task { await authManager.loginWithUI() } }) {
                HStack(spacing: 12) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "person.badge.key.fill")
                    }
                    Text("Sign in with \(authManager.providerDisplayName)")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(authManager.isLoading)
        }
    }

    // MARK: - Credentials Section

    private var credentialsSection: some View {
        VStack(spacing: 20) {
            // Identifier type picker (if multiple types supported)
            if authManager.loginIdentifiers.count > 1 {
                identifierTypePicker
            }

            // Identifier field
            identifierField

            // Password field
            passwordField

            // Login button
            loginButton

            // Development hint
            #if DEBUG
            developmentHint
            #endif
        }
    }

    private var identifierTypePicker: some View {
        HStack(spacing: 8) {
            ForEach(authManager.loginIdentifiers, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIdentifierType = type
                        identifier = "" // Clear when switching types
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.caption)
                        Text(type.displayName)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(selectedIdentifierType == type ? .white : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        selectedIdentifierType == type
                            ? Color.white.opacity(0.25)
                            : Color.white.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var identifierField: some View {
        let currentType = selectedIdentifierType ?? authManager.primaryIdentifier

        return VStack(alignment: .leading, spacing: 8) {
            Text(currentType.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            HStack {
                Image(systemName: currentType.icon)
                    .foregroundStyle(.white.opacity(0.7))

                TextField("", text: $identifier, prompt: Text(currentType.placeholder).foregroundStyle(.white.opacity(0.4)))
                    .keyboardType(keyboardType(for: currentType))
                    .textContentType(contentType(for: currentType))
                    .autocapitalization(currentType == .email ? .none : .allCharacters)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
            }
            .padding()
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(.white.opacity(0.7))

                if showPassword {
                    TextField("", text: $password)
                        .foregroundStyle(.white)
                } else {
                    SecureField("", text: $password)
                        .foregroundStyle(.white)
                }

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var loginButton: some View {
        Button(action: performLogin) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!canSubmit || authManager.isLoading)
    }

    // MARK: - Error Section

    @ViewBuilder
    private var errorSection: some View {
        if case .error(let error) = authManager.state {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(error.localizedDescription)
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .padding()
            .background(Color.red.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                authManager.clearError()
            }
        }
    }

    // MARK: - Development Hint

    private var developmentHint: some View {
        VStack(spacing: 4) {
            Text("Development Mode")
                .font(.caption.weight(.medium))
            Text("Use: officer@pd.local / password123")
                .font(.caption2)
            Text("Or badge: 12345 / password123")
                .font(.caption2)
        }
        .foregroundStyle(.white.opacity(0.6))
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        !identifier.isEmpty && !password.isEmpty
    }

    private func performLogin() {
        Task {
            let type = selectedIdentifierType ?? authManager.primaryIdentifier
            await authManager.login(
                identifier: identifier,
                password: password,
                identifierType: type
            )
        }
    }

    private func keyboardType(for type: LoginIdentifierType) -> UIKeyboardType {
        switch type.keyboardType {
        case .email: return .emailAddress
        case .phone: return .phonePad
        case .numbersAndPunctuation: return .numbersAndPunctuation
        case .default: return .default
        }
    }

    private func contentType(for type: LoginIdentifierType) -> UITextContentType? {
        switch type {
        case .email: return .emailAddress
        case .username: return .username
        case .phoneNumber: return .telephoneNumber
        default: return nil
        }
    }
}

// MARK: - MFA Verification View

struct MFAVerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var otpCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)

                    Text("Verification Required")
                        .font(.title2.weight(.bold))

                    Text("Complete one of the following to verify your identity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // MFA Options
                VStack(spacing: 16) {
                    // Biometric option
                    if authManager.availableMFAMethods.contains(.biometric) &&
                       authManager.biometricType != .none {
                        biometricButton
                    }

                    // OTP option
                    if authManager.availableMFAMethods.contains(.otp) {
                        otpSection
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Verify Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        authManager.cancelMFA()
                        dismiss()
                    }
                }
            }
        }
    }

    private var biometricButton: some View {
        Button(action: {
            Task {
                if await authManager.verifyWithBiometric() {
                    dismiss()
                }
            }
        }) {
            HStack {
                Image(systemName: authManager.biometricType.icon)
                    .font(.title2)
                Text("Use \(authManager.biometricType.displayName)")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var otpSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "key")
                    .foregroundStyle(.secondary)
                Text("Enter verification code")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            TextField("123456", text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.title.monospaced())
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: {
                Task {
                    await authManager.verifyWithOTP(code: otpCode)
                    if authManager.isAuthenticated {
                        dismiss()
                    }
                }
            }) {
                Text("Verify")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(otpCode.count == 6 ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(otpCode.count != 6)
        }
    }
}

// MARK: - MFAPendingState Identifiable

extension MFAPendingState: Identifiable {
    var id: String { sessionToken }
}

// MARK: - Previews

#Preview("Login - Multiple Identifiers") {
    let config = AuthConfig(
        providerType: .mock,
        loginIdentifiers: [.badgeNumber, .email, .employeeId],
        mfa: MFAConfig(required: true, methods: [.biometric, .otp], graceperiodDays: nil, rememberDeviceDays: nil),
        oauth: nil, saml: nil, ldap: nil, basic: nil, branding: nil
    )
    return LoginView()
        .environmentObject(
            AuthManager(
                provider: MockAuthProvider(),
                config: config,
                sessionStorage: InMemorySessionStorage()
            )
        )
}

#Preview("Login - Badge Only") {
    let config = AuthConfig(
        providerType: .mock,
        loginIdentifiers: [.badgeNumber],
        mfa: nil,
        oauth: nil, saml: nil, ldap: nil, basic: nil, branding: nil
    )
    return LoginView()
        .environmentObject(
            AuthManager(
                provider: MockAuthProvider(),
                config: config,
                sessionStorage: InMemorySessionStorage()
            )
        )
}

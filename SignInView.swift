import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentNonce: String?
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    var body: some View {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(red: 0.11, green: 0.13, blue: 0.18))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)

                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                }

                Spacer()
                    .frame(height: 40)

                // Welcome Text
                Text("Sign in to start")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)

                Text("your first brain dump 💭")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(white: 0.5))
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 50)

                // Apple Sign In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        guard let nonce = randomNonceString() else {
                            // If we can't generate a secure nonce, we shouldn't proceed with sign-in
                            errorMessage = "Unable to generate secure authentication token"
                            showError = true
                            return
                        }
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 56)
                .cornerRadius(16)
                .padding(.horizontal, 20)

                // Google Sign In Button
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack(spacing: 12) {
                        GoogleLogo()
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(white: 0.9), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color(white: 0.9))
                        .frame(height: 1)

                    Text("or")
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.5))
                        .padding(.horizontal, 12)

                    Rectangle()
                        .fill(Color(white: 0.9))
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)

                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    TextField("example@email.com", text: $email)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 56)
                        .background(Color(white: 0.97))
                        .cornerRadius(16)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding(.horizontal, 20)

                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    HStack {
                        if showPassword {
                            TextField("", text: $password)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        } else {
                            SecureField("", text: $password)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }

                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(white: 0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color(white: 0.97))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Forgot Password
                HStack {
                    Spacer()
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot Password")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Sign In Button
                Button(action: {
                    signIn()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.95),
                            Color(red: 0.45, green: 0.55, blue: 0.95)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // Sign Up Link
                HStack(spacing: 4) {
                    Text("New here?")
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.5))

                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("Create an account")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                    }
                }
                .padding(.top, 20)

                // Terms and Privacy Links
                HStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))

                    Button(action: {
                        showTermsOfService = true
                    }) {
                        Text("Terms")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.5))
                            .underline()
                    }
                    .buttonStyle(.plain)

                    Text("&")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))

                    Button(action: {
                        showPrivacyPolicy = true
                    }) {
                        Text("Privacy")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.5))
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 12)

                Spacer()
            }
            .background(Color.white)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }

        isLoading = true

        authService.signIn(email: email, password: password) { result in
            isLoading = false

            switch result {
            case .success:
                // Auth state change will automatically navigate to ContentView
                break
            case .failure(let error):
                errorMessage = friendlyErrorMessage(for: error)
                showError = true
            }
        }
    }

    // MARK: - Friendly Error Messages
    private func friendlyErrorMessage(for error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("password") && errorString.contains("wrong") || errorString.contains("invalid") {
            return "Email or password incorrect. Try again?"
        } else if errorString.contains("network") || errorString.contains("internet") {
            return "You're offline 🌐 Check your connection"
        } else if errorString.contains("user") && errorString.contains("not found") {
            return "No account found. Create one?"
        } else if errorString.contains("email") && errorString.contains("already") {
            return "This email is already in use. Sign in instead?"
        } else {
            return "Hmm, something went wrong. Try again?"
        }
    }

    // MARK: - Google Sign In
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            errorMessage = "Google Sign In not configured"
            showError = true
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        isLoading = true

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [self] result, error in
            isLoading = false

            if let error = error {
                // Log detailed error for debugging
                print("❌ Google Sign In Error:")
                print("   Error: \(error.localizedDescription)")
                print("   Domain: \(error._domain)")
                print("   Code: \(error._code)")
                print("   Client ID: \(clientID)")
                print("   Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

                errorMessage = friendlyErrorMessage(for: error)
                showError = true
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "Couldn't connect with Google. Try again?"
                showError = true
                return
            }

            let accessToken = user.accessToken.tokenString

            // Sign in with Firebase
            authService.signInWithGoogle(idToken: idToken, accessToken: accessToken) { result in
                switch result {
                case .success:
                    // Auth state change will automatically navigate to ContentView
                    break
                case .failure(let error):
                    errorMessage = friendlyErrorMessage(for: error)
                    showError = true
                }
            }
        }
    }

    // MARK: - Apple Sign In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    errorMessage = "Couldn't connect with Apple. Try again?"
                    showError = true
                    return
                }

                guard let appleIDToken = appleIDCredential.identityToken else {
                    errorMessage = "Couldn't connect with Apple. Try again?"
                    showError = true
                    return
                }

                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    errorMessage = "Couldn't connect with Apple. Try again?"
                    showError = true
                    return
                }

                // Extract full name (only available on first sign in)
                var fullName: String?
                if let givenName = appleIDCredential.fullName?.givenName,
                   let familyName = appleIDCredential.fullName?.familyName {
                    fullName = "\(givenName) \(familyName)"
                } else if let givenName = appleIDCredential.fullName?.givenName {
                    fullName = givenName
                }

                isLoading = true

                authService.signInWithApple(idToken: idTokenString, nonce: nonce, fullName: fullName) { result in
                    isLoading = false

                    switch result {
                    case .success:
                        // Auth state change will automatically navigate to ContentView
                        break
                    case .failure(let error):
                        errorMessage = friendlyErrorMessage(for: error)
                        showError = true
                    }
                }
            }

        case .failure(let error):
            errorMessage = friendlyErrorMessage(for: error)
            showError = true
        }
    }

    // MARK: - Nonce Generation
    private func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms: [UInt8] = []
            for _ in 0 ..< 16 {
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    // Failed to generate secure random - return nil instead of crashing
                    return nil
                }
                randoms.append(random)
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - Google Logo Component
struct GoogleLogo: View {
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)

            // Multicolor G letter
            ZStack {
                // Red arc (top)
                Circle()
                    .trim(from: 0.125, to: 0.625)
                    .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 2.5)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-45))

                // Yellow arc
                Circle()
                    .trim(from: 0.625, to: 0.875)
                    .stroke(Color(red: 0.98, green: 0.74, blue: 0.02), lineWidth: 2.5)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-45))

                // Green arc
                Circle()
                    .trim(from: 0.875, to: 1.0)
                    .stroke(Color(red: 0.0, green: 0.66, blue: 0.42), lineWidth: 2.5)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-45))

                // Red arc (bottom)
                Circle()
                    .trim(from: 0.0, to: 0.125)
                    .stroke(Color(red: 0.92, green: 0.26, blue: 0.22), lineWidth: 2.5)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-45))

                // Center bar (blue)
                Rectangle()
                    .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                    .frame(width: 8, height: 2.5)
                    .offset(x: 4, y: 0)
            }
        }
        .frame(width: 24, height: 24)
    }
}

#Preview {
    SignInView()
}

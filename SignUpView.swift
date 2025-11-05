import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentNonce: String?
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var agreedToTerms = false

    var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    // Back Button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 20)

                        Spacer()
                    }

                    Spacer()
                        .frame(height: 20)

                    // Title
                    Text("Create Account")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)

                    Text("Get started, it's free!")
                        .font(.system(size: 16))
                        .foregroundColor(Color(white: 0.5))
                        .padding(.top, 8)

                    Spacer()
                        .frame(height: 40)

                    // Apple Sign Up Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            let nonce = randomNonceString()
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

                    // Google Sign Up Button
                    Button(action: {
                        handleGoogleSignIn()
                    }) {
                        HStack(spacing: 12) {
                            GoogleLogo()
                            Text("Sign Up with Google")
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

                        Text("or with email")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 12)

                        Rectangle()
                            .fill(Color(white: 0.9))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)

                    // Full Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        TextField("Your Name", text: $fullName)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color(white: 0.97))
                            .cornerRadius(16)
                            .autocapitalization(.words)
                    }
                    .padding(.horizontal, 20)

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
                    .padding(.top, 16)

                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        HStack {
                            if showPassword {
                                TextField("At least 8 characters", text: $password)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            } else {
                                SecureField("At least 8 characters", text: $password)
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

                    // Terms & Conditions Checkbox
                    HStack(alignment: .top, spacing: 12) {
                        Button(action: {
                            agreedToTerms.toggle()
                        }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundColor(agreedToTerms ? Color(red: 0.35, green: 0.70, blue: 0.90) : Color(white: 0.6))
                        }
                        .padding(.top, 2)

                        HStack(alignment: .top, spacing: 4) {
                            Text("I agree to the")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))

                            Button(action: {
                                showTermsOfService = true
                            }) {
                                Text("Terms of Use")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                                    .underline()
                            }
                            .buttonStyle(.plain)

                            Text("and")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))

                            Button(action: {
                                showPrivacyPolicy = true
                            }) {
                                Text("Privacy Policy")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                                    .underline()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Sign Up Button
                    Button(action: {
                        signUp()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        } else {
                            Text("Create Account")
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
                    .disabled(isLoading || email.isEmpty || password.isEmpty || fullName.isEmpty || password.count < 8 || !agreedToTerms)
                    .opacity((isLoading || email.isEmpty || password.isEmpty || fullName.isEmpty || password.count < 8 || !agreedToTerms) ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // Sign In Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.5))

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.white)
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .fullScreenCover(isPresented: $showError) {
                ErrorView(
                    title: "Sign Up Failed",
                    message: errorMessage,
                    primaryButtonTitle: "OK",
                    secondaryButtonTitle: nil,
                    onPrimaryAction: {}
                )
                .background(ClearBackgroundViewForSignUp())
            }
    }

    private func signUp() {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty, password.count >= 8, agreedToTerms else { return }

        isLoading = true

        authService.signUp(email: email, password: password, fullName: fullName) { result in
            isLoading = false

            switch result {
            case .success:
                // Auth state change will automatically navigate to ContentView
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
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
                errorMessage = error.localizedDescription
                showError = true
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "Failed to get Google credentials"
                showError = true
                return
            }

            let accessToken = user.accessToken.tokenString

            // Sign in with Firebase
            authService.signInWithGoogle(idToken: idToken, accessToken: accessToken) { result in
                switch result {
                case .success:
                    // Auth state change will automatically navigate to ContentView
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
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
                    errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                    showError = true
                    return
                }

                guard let appleIDToken = appleIDCredential.identityToken else {
                    errorMessage = "Unable to fetch identity token"
                    showError = true
                    return
                }

                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    errorMessage = "Unable to serialize token string from data"
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
                        dismiss()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Nonce Generation
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
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

// Helper to make fullScreenCover background transparent
struct ClearBackgroundViewForSignUp: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    SignUpView()
}

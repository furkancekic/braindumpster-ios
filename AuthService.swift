import Foundation
import FirebaseAuth
import FirebaseCore

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false

    static let shared = AuthService()

    private init() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Check current user
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAuthenticated = true
        }

        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, fullName: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Step 1: Register user on backend API
        _Concurrency.Task {
            do {
                // Call backend API to register user
                let registerResponse = try await BraindumpsterAPI.shared.registerUser(
                    email: email,
                    password: password,
                    displayName: fullName
                )

                print("✅ User registered on backend: \(registerResponse.uid)")

                // Step 2: Sign in with Firebase Auth (backend already created the Firebase user)
                Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                    if let error = error {
                        // If sign in fails, the user was created but can't sign in
                        // This shouldn't happen since backend creates the user
                        print("❌ Firebase sign in failed after registration: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }

                    guard let user = authResult?.user else {
                        completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in failed after registration"])))
                        return
                    }

                    // Update display name on Firebase Auth profile
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = fullName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("⚠️ Error updating Firebase profile: \(error.localizedDescription)")
                        }
                    }

                    self?.user = user
                    self?.isAuthenticated = true

                    // Update timezone information
                    _Concurrency.Task {
                        await self?.updateUserTimezone()
                    }

                    print("✅ User signed in successfully: \(user.email ?? "")")
                    completion(.success(user))
                }

            } catch {
                // Backend registration failed
                print("❌ Backend registration failed: \(error.localizedDescription)")
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in failed"])))
                return
            }

            self?.user = user
            self?.isAuthenticated = true

            // Register FCM token with backend
            self?.registerFCMTokenIfAvailable()

            // Update timezone information
            _Concurrency.Task {
                await self?.updateUserTimezone()
            }

            completion(.success(user))
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }

        try await user.delete()
        self.user = nil
        self.isAuthenticated = false
        print("✅ Firebase account deleted successfully")
    }

    // MARK: - Reset Password
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }

    // MARK: - Get ID Token
    func getIdToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
            return
        }

        user.getIDToken { token, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let token = token else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get token"])))
                return
            }

            completion(.success(token))
        }
    }

    // Async/await version for modern Swift concurrency
    func getIdToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            user.getIDToken { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token = token else {
                    continuation.resume(throwing: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get token"]))
                    return
                }

                continuation.resume(returning: token)
            }
        }
    }

    // MARK: - Update User Timezone
    /// Update user's timezone information in backend
    /// Call this after sign in/sign up and when app becomes active
    func updateUserTimezone() async {
        guard let user = self.user else {
            print("⚠️ Cannot update timezone: No user signed in")
            return
        }

        let timezoneInfo = TimezoneService.shared.getTimezoneContext()

        print("🌍 Updating user timezone...")
        print("   User ID: \(user.uid)")
        print("   Timezone: \(timezoneInfo["userTimezone"] ?? "Unknown")")

        do {
            try await BraindumpsterAPI.shared.updateUserTimezone(timezoneInfo: timezoneInfo)
            print("✅ Timezone updated successfully")
        } catch {
            print("⚠️ Failed to update timezone: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign In with Apple
    func signInWithApple(idToken: String, nonce: String, fullName: String?, completion: @escaping (Result<User, Error>) -> Void) {
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idToken,
            rawNonce: nonce
        )

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple sign in failed"])))
                return
            }

            // Update display name if provided (only available on first sign in)
            if let fullName = fullName, !fullName.isEmpty {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("⚠️ Error updating display name: \(error.localizedDescription)")
                    } else {
                        print("✅ Display name updated to: \(fullName)")
                    }
                }
            }

            self?.user = user
            self?.isAuthenticated = true

            // Ensure user exists in backend (for OAuth users)
            _Concurrency.Task {
                do {
                    try await BraindumpsterAPI.shared.ensureUserExists(displayName: fullName)
                } catch {
                    print("⚠️ Failed to sync user with backend: \(error.localizedDescription)")
                    // Don't fail the sign in, just log the error
                }
            }

            // Register FCM token with backend
            self?.registerFCMTokenIfAvailable()

            // Update timezone information
            _Concurrency.Task {
                await self?.updateUserTimezone()
            }

            completion(.success(user))
        }
    }

    // MARK: - Sign In with Google
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google sign in failed"])))
                return
            }

            self?.user = user
            self?.isAuthenticated = true

            // Ensure user exists in backend (for OAuth users)
            _Concurrency.Task {
                do {
                    try await BraindumpsterAPI.shared.ensureUserExists(displayName: user.displayName)
                } catch {
                    print("⚠️ Failed to sync user with backend: \(error.localizedDescription)")
                    // Don't fail the sign in, just log the error
                }
            }

            // Register FCM token with backend
            self?.registerFCMTokenIfAvailable()

            // Update timezone information
            _Concurrency.Task {
                await self?.updateUserTimezone()
            }

            completion(.success(user))
        }
    }

    // MARK: - FCM Token Registration
    private func registerFCMTokenIfAvailable() {
        // Try to get FCM token from UserDefaults (saved by AppDelegate)
        guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            print("⚠️ No FCM token available yet, will register when token is received")
            return
        }

        // Register token with backend
        _Concurrency.Task {
            do {
                try await BraindumpsterAPI.shared.registerFCMToken(token: fcmToken)
                print("✅ FCM token registered after login")
            } catch {
                print("❌ Failed to register FCM token after login: \(error.localizedDescription)")
            }
        }
    }
}

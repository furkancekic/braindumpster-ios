import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct BraindumpsterApp: App {
    @StateObject private var authService = AuthService.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .onOpenURL { url in
                        // Handle Google Sign In callback
                        GIDSignIn.sharedInstance.handle(url)
                    }
            } else {
                SignInView()
                    .onOpenURL { url in
                        // Handle Google Sign In callback
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
    }
}

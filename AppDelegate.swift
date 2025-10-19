import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Set FCM messaging delegate
        Messaging.messaging().delegate = self

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permission
        requestNotificationPermission()

        // Register for remote notifications
        application.registerForRemoteNotifications()

        print("📱 AppDelegate: Did finish launching")

        return true
    }

    // MARK: - Notification Permission

    func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                    return
                }

                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("⚠️ Notification permission denied")
                }
            }
        )
    }

    // MARK: - Remote Notifications Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNs device token received")

        // Pass APNs token to Firebase
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("❌ FCM token is nil")
            return
        }

        print("🔑 FCM Token received: \(fcmToken.prefix(50))...")

        // Save token locally
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")

        // Post notification to inform app that FCM token is available
        NotificationCenter.default.post(name: NSNotification.Name("FCMTokenRefreshed"), object: nil, userInfo: ["token": fcmToken])

        // Try to register token with backend if user is authenticated
        if let userId = AuthService.shared.user?.uid {
            print("📤 Registering FCM token with backend for user: \(userId)")
            _Concurrency.Task {
                do {
                    try await BraindumpsterAPI.shared.registerFCMToken(token: fcmToken)
                    print("✅ FCM token registered with backend")
                } catch {
                    print("❌ Failed to register FCM token with backend: \(error.localizedDescription)")
                }
            }
        } else {
            print("⚠️ User not authenticated yet, will register token after login")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        print("📬 Notification received in foreground")
        print("📋 UserInfo: \(userInfo)")

        // Show notification even when app is in foreground
        completionHandler([[.banner, .sound, .badge]])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        print("👆 Notification tapped")
        print("📋 UserInfo: \(userInfo)")

        // Handle notification action based on type
        if let action = userInfo["action"] as? String {
            switch action {
            case "open_task":
                // Open specific task
                if let taskId = userInfo["task_id"] as? String {
                    print("📝 Opening task: \(taskId)")
                    NotificationCenter.default.post(name: NSNotification.Name("OpenTask"), object: nil, userInfo: ["taskId": taskId])
                }

            case "open_dashboard":
                // Refresh task list (for completion notification)
                print("🔄 Refreshing task list - task completed")
                NotificationCenter.default.post(name: NSNotification.Name("RefreshTasks"), object: nil)

            default:
                // Fallback: if task_id exists, open it
                if let taskId = userInfo["task_id"] as? String {
                    print("📝 Opening task: \(taskId)")
                    NotificationCenter.default.post(name: NSNotification.Name("OpenTask"), object: nil, userInfo: ["taskId": taskId])
                }
            }
        } else if let taskId = userInfo["task_id"] as? String {
            // Backward compatibility: if no action but task_id exists
            print("📝 Opening task: \(taskId)")
            NotificationCenter.default.post(name: NSNotification.Name("OpenTask"), object: nil, userInfo: ["taskId": taskId])
        }

        completionHandler()
    }
}

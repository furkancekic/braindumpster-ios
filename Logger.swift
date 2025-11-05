import Foundation
import os.log

/// Centralized logging system for the app
/// Replaces print() statements with proper os.log for better performance and privacy
enum Logger {

    // MARK: - Log Categories
    private static let apiLog = OSLog(subsystem: "com.braindumpster.app", category: "API")
    private static let authLog = OSLog(subsystem: "com.braindumpster.app", category: "Auth")
    private static let audioLog = OSLog(subsystem: "com.braindumpster.app", category: "Audio")
    private static let purchaseLog = OSLog(subsystem: "com.braindumpster.app", category: "Purchase")
    private static let uiLog = OSLog(subsystem: "com.braindumpster.app", category: "UI")
    private static let dataLog = OSLog(subsystem: "com.braindumpster.app", category: "Data")
    private static let generalLog = OSLog(subsystem: "com.braindumpster.app", category: "General")

    // MARK: - API Logging
    static func api(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: apiLog, type: type, message)
    }

    static func apiRequest(_ endpoint: String, method: String = "GET") {
        os_log("🌐 %{public}@ %{public}@", log: apiLog, type: .info, method, endpoint)
    }

    static func apiResponse(_ status: Int, endpoint: String) {
        let emoji = status < 400 ? "✅" : "❌"
        os_log("%{public}@ Response %d from %{public}@", log: apiLog, type: .info, emoji, status, endpoint)
    }

    static func apiError(_ error: Error, context: String = "") {
        let contextStr = context.isEmpty ? "" : " (\(context))"
        os_log("❌ API Error%{public}@: %{public}@", log: apiLog, type: .error, contextStr, error.localizedDescription)
    }

    // MARK: - Auth Logging
    static func auth(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: authLog, type: type, message)
    }

    static func authSuccess(_ action: String) {
        os_log("✅ Auth: %{public}@", log: authLog, type: .info, action)
    }

    static func authError(_ error: Error, context: String = "") {
        let contextStr = context.isEmpty ? "" : " (\(context))"
        os_log("❌ Auth Error%{public}@: %{public}@", log: authLog, type: .error, contextStr, error.localizedDescription)
    }

    // MARK: - Audio Logging
    static func audio(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: audioLog, type: type, message)
    }

    static func audioRecording(_ state: String) {
        os_log("🎤 Recording: %{public}@", log: audioLog, type: .info, state)
    }

    static func audioError(_ error: Error, context: String = "") {
        let contextStr = context.isEmpty ? "" : " (\(context))"
        os_log("❌ Audio Error%{public}@: %{public}@", log: audioLog, type: .error, contextStr, error.localizedDescription)
    }

    // MARK: - Purchase Logging
    static func purchase(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: purchaseLog, type: type, message)
    }

    static func purchaseSuccess(_ product: String) {
        os_log("✅ Purchase successful: %{public}@", log: purchaseLog, type: .info, product)
    }

    static func purchaseError(_ error: Error, context: String = "") {
        let contextStr = context.isEmpty ? "" : " (\(context))"
        os_log("❌ Purchase Error%{public}@: %{public}@", log: purchaseLog, type: .error, contextStr, error.localizedDescription)
    }

    // MARK: - UI Logging
    static func ui(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: uiLog, type: type, message)
    }

    static func viewLifecycle(_ view: String, event: String) {
        os_log("📱 %{public}@: %{public}@", log: uiLog, type: .debug, view, event)
    }

    // MARK: - Data Logging
    static func data(_ message: String, type: OSLogType = .default) {
        os_log("%{public}@", log: dataLog, type: type, message)
    }

    static func dataOperation(_ operation: String, success: Bool) {
        let emoji = success ? "✅" : "❌"
        os_log("%{public}@ Data: %{public}@", log: dataLog, type: .info, emoji, operation)
    }

    // MARK: - General Logging
    static func info(_ message: String) {
        os_log("ℹ️ %{public}@", log: generalLog, type: .info, message)
    }

    static func debug(_ message: String) {
        os_log("🐛 %{public}@", log: generalLog, type: .debug, message)
    }

    static func warning(_ message: String) {
        os_log("⚠️ %{public}@", log: generalLog, type: .default, message)
    }

    static func error(_ message: String) {
        os_log("❌ %{public}@", log: generalLog, type: .error, message)
    }

    static func error(_ error: Error, context: String = "") {
        let contextStr = context.isEmpty ? "" : " (\(context))"
        os_log("❌ Error%{public}@: %{public}@", log: generalLog, type: .error, contextStr, error.localizedDescription)
    }

    // MARK: - Performance Logging
    static func startMeasure(_ operation: String) -> Date {
        os_log("⏱️ Starting: %{public}@", log: generalLog, type: .debug, operation)
        return Date()
    }

    static func endMeasure(_ operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        os_log("⏱️ Completed %{public}@ in %.3f seconds", log: generalLog, type: .debug, operation, duration)
    }
}

// MARK: - Debug-only Print
/// Use this for temporary debugging that should never go to production
func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
    #endif
}

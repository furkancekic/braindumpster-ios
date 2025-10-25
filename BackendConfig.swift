import Foundation

/// Backend configuration for receipt verification
struct BackendConfig {
    /// Backend base URL (same as BraindumpsterAPI)
    static var baseURL: String {
        // Production API - braindumpster.io domain
        return "https://api.braindumpster.io/api"
    }

    /// Auth token for backend API
    static var authToken: String {
        // In production, securely store in Keychain
        // For now, placeholder
        return "YOUR_BACKEND_AUTH_TOKEN"
    }

    /// Request timeout (seconds)
    static let requestTimeout: TimeInterval = 30.0

    /// Maximum retry attempts for failed requests
    static let maxRetryAttempts = 2

    /// Exponential backoff delays (seconds)
    static let retryDelays: [TimeInterval] = [2.0, 4.0]
}

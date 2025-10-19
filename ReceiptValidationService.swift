import Foundation
import StoreKit
import CommonCrypto
import ObjectiveC

// MARK: - Receipt Refresh Delegate

private class ReceiptRefreshDelegate: NSObject, SKRequestDelegate {
    private let completion: (Error?) -> Void

    init(completion: @escaping (Error?) -> Void) {
        self.completion = completion
        super.init()
    }

    func requestDidFinish(_ request: SKRequest) {
        completion(nil)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        completion(error)
    }
}

/// Receipt verification response from backend
struct ReceiptVerificationResponse: Codable {
    let success: Bool
    let isPremium: Bool
    let productId: String?
    let expirationDate: Date?
    let message: String?
    let environment: String? // "sandbox" or "production"
}

/// Receipt verification request payload
struct ReceiptVerificationRequest: Codable {
    let receiptData: String // base64 encoded
    let userId: String?
    let deviceInfo: DeviceInfo
    let appVersion: String
    let bundleId: String
}

struct DeviceInfo: Codable {
    let model: String
    let osVersion: String
    let locale: String
}

enum ReceiptValidationError: Error, LocalizedError {
    case noReceiptAvailable
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case timeout
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .noReceiptAvailable:
            return "No receipt available for validation"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .invalidResponse:
            return "Invalid response from server"
        case .timeout:
            return "Request timed out"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}

@MainActor
class ReceiptValidationService {
    static let shared = ReceiptValidationService()

    private init() {}

    // MARK: - Verify Receipt with Backend

    /// Verify receipt with backend server
    /// - Parameters:
    ///   - transaction: StoreKit transaction
    ///   - userId: Optional user ID
    /// - Returns: Verification response from backend
    func verifyReceipt(transaction: Transaction, userId: String?) async throws -> ReceiptVerificationResponse {
        // Check receipt availability FIRST
        guard let receiptData = try? await getReceiptData() else {
            throw ReceiptValidationError.noReceiptAvailable
        }

        // Receipt exists, start verification
        print("🔐 [ReceiptValidation] Starting receipt verification")

        // Hash for logging (DO NOT log full receipt)
        let receiptHash = sha256Hash(receiptData).prefix(8)
        print("   Receipt hash (first 8): \(receiptHash)")
        print("   Transaction ID: \(transaction.id)")
        print("   Product ID: \(transaction.productID)")

        // Prepare request payload
        let request = ReceiptVerificationRequest(
            receiptData: receiptData.base64EncodedString(),
            userId: userId,
            deviceInfo: DeviceInfo(
                model: getDeviceModel(),
                osVersion: getOSVersion(),
                locale: Locale.current.identifier
            ),
            appVersion: getAppVersion(),
            bundleId: Bundle.main.bundleIdentifier ?? ""
        )

        // Try with retries
        return try await verifyWithRetry(request: request, attempt: 1)
    }

    // MARK: - Retry Logic

    private func verifyWithRetry(request: ReceiptVerificationRequest, attempt: Int) async throws -> ReceiptVerificationResponse {
        do {
            return try await sendVerificationRequest(request: request)
        } catch let error as ReceiptValidationError {
            // Check if we should retry
            if shouldRetry(error: error, attempt: attempt) {
                let delay = BackendConfig.retryDelays[min(attempt - 1, BackendConfig.retryDelays.count - 1)]

                print("⚠️ [ReceiptValidation] Retry attempt \(attempt + 1)/\(BackendConfig.maxRetryAttempts + 1)")
                print("   Waiting \(delay)s before retry...")

                try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await verifyWithRetry(request: request, attempt: attempt + 1)
            } else {
                throw error
            }
        } catch {
            throw ReceiptValidationError.networkError(error)
        }
    }

    private func shouldRetry(error: ReceiptValidationError, attempt: Int) -> Bool {
        guard attempt <= BackendConfig.maxRetryAttempts else {
            return false
        }

        switch error {
        case .serverError(let code, _):
            // Retry on 5xx errors
            return code >= 500
        case .timeout, .networkError:
            return true
        default:
            return false
        }
    }

    // MARK: - Network Request

    private func sendVerificationRequest(request: ReceiptVerificationRequest) async throws -> ReceiptVerificationResponse {
        let url = URL(string: "\(BackendConfig.baseURL)/verify-receipt")!

        // Get Firebase auth token
        let authToken: String
        do {
            authToken = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                AuthService.shared.getIdToken { result in
                    continuation.resume(with: result)
                }
            }
            print("✅ [ReceiptValidation] Got Firebase auth token")
        } catch {
            print("❌ [ReceiptValidation] Failed to get auth token: \(error)")
            throw ReceiptValidationError.networkError(error)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = BackendConfig.requestTimeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Encode request body
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)

        print("📤 [ReceiptValidation] Sending request to: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReceiptValidationError.invalidResponse
        }

        print("📥 [ReceiptValidation] Response status: \(httpResponse.statusCode)")

        // Handle response codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let verificationResponse = try decoder.decode(ReceiptVerificationResponse.self, from: data)

            print("✅ [ReceiptValidation] Verification successful")
            print("   Premium: \(verificationResponse.isPremium)")
            print("   Product ID: \(verificationResponse.productId ?? "N/A")")
            print("   Environment: \(verificationResponse.environment ?? "N/A")")

            return verificationResponse

        case 400...499:
            // Client error (don't retry)
            let message = String(data: data, encoding: .utf8)
            print("❌ [ReceiptValidation] Client error (\(httpResponse.statusCode))")
            print("   Message: \(message ?? "No message")")
            throw ReceiptValidationError.serverError(statusCode: httpResponse.statusCode, message: message)

        case 500...599:
            // Server error (retry)
            let message = String(data: data, encoding: .utf8)
            print("❌ [ReceiptValidation] Server error (\(httpResponse.statusCode))")
            print("   Message: \(message ?? "No message")")
            throw ReceiptValidationError.serverError(statusCode: httpResponse.statusCode, message: message)

        default:
            throw ReceiptValidationError.invalidResponse
        }
    }

    // MARK: - Helper Methods

    private func getReceiptData() async throws -> Data {
        // Get app store receipt URL
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            throw ReceiptValidationError.noReceiptAvailable
        }

        // Check if receipt exists
        if !FileManager.default.fileExists(atPath: receiptURL.path) {
            print("⚠️ [ReceiptValidation] Receipt file not found, refreshing...")

            // Refresh receipt from App Store
            do {
                try await refreshReceipt()

                // Check again after refresh
                if !FileManager.default.fileExists(atPath: receiptURL.path) {
                    print("❌ [ReceiptValidation] Receipt still not available after refresh")
                    throw ReceiptValidationError.noReceiptAvailable
                }

                print("✅ [ReceiptValidation] Receipt refreshed successfully")
            } catch {
                print("❌ [ReceiptValidation] Receipt refresh failed: \(error)")
                throw ReceiptValidationError.noReceiptAvailable
            }
        }

        return try Data(contentsOf: receiptURL)
    }

    private func refreshReceipt() async throws {
        // Request receipt refresh from App Store
        let request = SKReceiptRefreshRequest()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var didComplete = false

            let delegate = ReceiptRefreshDelegate { error in
                guard !didComplete else { return }
                didComplete = true

                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }

            request.delegate = delegate

            // Retain delegate until request completes
            objc_setAssociatedObject(request, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

            request.start()
        }
    }

    private func sha256Hash(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? "Unknown"
    }

    private func getOSVersion() -> String {
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

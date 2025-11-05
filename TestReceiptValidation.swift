import Foundation
import SwiftUI

/// Test view for receipt validation endpoint
struct TestReceiptValidationView: View {
    @State private var authToken: String = ""
    @State private var response: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Receipt Validation Test")
                .font(.title)

            Button("Get Auth Token") {
                getAuthToken()
            }
            .buttonStyle(.borderedProminent)

            if !authToken.isEmpty {
                Text("Token: \(authToken.prefix(20))...")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Button("Test /verify-receipt") {
                testVerifyReceipt()
            }
            .buttonStyle(.borderedProminent)
            .disabled(authToken.isEmpty || isLoading)

            if isLoading {
                ProgressView()
            }

            ScrollView {
                Text(response)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
        }
        .padding()
    }

    private func getAuthToken() {
        AuthService.shared.getIdToken { result in
            switch result {
            case .success(let token):
                authToken = token
                response = "✅ Got auth token successfully!\nToken: \(token.prefix(50))..."
                print("🔑 Auth Token: \(token)")
            case .failure(let error):
                response = "❌ Failed to get auth token: \(error.localizedDescription)"
            }
        }
    }

    private func testVerifyReceipt() {
        isLoading = true
        response = "⏳ Testing backend endpoint..."

        Task {
            do {
                // Get receipt data
                guard let receiptURL = Bundle.main.appStoreReceiptURL,
                      FileManager.default.fileExists(atPath: receiptURL.path) else {
                    await MainActor.run {
                        response = "❌ No receipt found\nRun on device or with StoreKit configuration"
                        isLoading = false
                    }
                    return
                }

                let receiptData = try Data(contentsOf: receiptURL)
                let receiptBase64 = receiptData.base64EncodedString()

                print("📦 Receipt size: \(receiptData.count) bytes")
                print("📦 Receipt hash: \(sha256(receiptData).prefix(8))")

                // Prepare request
                guard let url = URL(string: "\(BackendConfig.baseURL)/verify-receipt") else {
                    print("❌ Invalid URL configuration")
                    return
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

                let payload: [String: Any] = [
                    "receiptData": receiptBase64,
                    "userId": AuthService.shared.user?.uid ?? "test_user",
                    "deviceInfo": [
                        "model": getDeviceModel(),
                        "osVersion": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
                        "locale": Locale.current.identifier
                    ],
                    "appVersion": getAppVersion(),
                    "bundleId": Bundle.main.bundleIdentifier ?? "com.braindumpster.app"
                ]

                request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                print("📤 Sending request to: \(url.absoluteString)")
                print("📤 User ID: \(AuthService.shared.user?.uid ?? "nil")")
                print("📤 Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")

                // Send request
                let (data, httpResponse) = try await URLSession.shared.data(for: request)

                guard let httpResponse = httpResponse as? HTTPURLResponse else {
                    throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }

                let statusCode = httpResponse.statusCode
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"

                print("📥 Response status: \(statusCode)")
                print("📥 Response body: \(responseString)")

                await MainActor.run {
                    var result = "📥 Backend Response\n"
                    result += "Status: \(statusCode)\n"
                    result += "---\n"

                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        result += "Success: \(json["success"] ?? "N/A")\n"
                        result += "Is Premium: \(json["isPremium"] ?? "N/A")\n"
                        result += "Product ID: \(json["productId"] ?? "N/A")\n"
                        result += "Expiration: \(json["expirationDate"] ?? "N/A")\n"
                        result += "Environment: \(json["environment"] ?? "N/A")\n"
                        result += "Message: \(json["message"] ?? "N/A")\n"
                        result += "---\n"
                        result += "Full JSON:\n\(responseString)"

                        if statusCode == 200 {
                            result = "✅ " + result
                        } else {
                            result = "⚠️ " + result
                        }
                    } else {
                        result += responseString
                    }

                    response = result
                    isLoading = false
                }

            } catch {
                await MainActor.run {
                    response = "❌ Error: \(error.localizedDescription)"
                    isLoading = false
                }
                print("❌ Test error: \(error)")
            }
        }
    }

    private func sha256(_ data: Data) -> String {
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

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}

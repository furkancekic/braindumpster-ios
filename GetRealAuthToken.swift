import Foundation
import SwiftUI

/// Quick script to get Firebase auth token for testing
struct GetRealAuthTokenView: View {
    @State private var token: String = ""
    @State private var status: String = "Tap button to get token"

    var body: some View {
        VStack(spacing: 20) {
            Text("Get Firebase Auth Token")
                .font(.title)

            Button("Get Token") {
                getToken()
            }
            .buttonStyle(.borderedProminent)

            Text(status)
                .font(.caption)
                .foregroundColor(token.isEmpty ? .gray : .green)

            if !token.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Token (copy this):")
                        .font(.headline)

                    ScrollView {
                        Text(token)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Button("Copy to Clipboard") {
                        UIPasteboard.general.string = token
                        status = "✅ Copied to clipboard!"
                    }
                    .buttonStyle(.bordered)

                    Divider()

                    Text("cURL Test Command:")
                        .font(.headline)

                    ScrollView {
                        Text(generateCurlCommand(token: token))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .padding()
    }

    private func getToken() {
        status = "⏳ Getting token..."

        AuthService.shared.getIdToken { result in
            switch result {
            case .success(let authToken):
                token = authToken
                status = "✅ Token retrieved successfully!"
                print("🔑 Auth Token: \(authToken)")

                // Also print cURL command
                print("\n📋 Copy this cURL command:\n")
                print(generateCurlCommand(token: authToken))

            case .failure(let error):
                status = "❌ Error: \(error.localizedDescription)"
                print("❌ Failed to get token: \(error)")
            }
        }
    }

    private func generateCurlCommand(token: String) -> String {
        return """
        curl -X POST http://57.129.81.193:5001/api/verify-receipt \\
          -H "Content-Type: application/json" \\
          -H "Authorization: Bearer \(token)" \\
          -d '{
            "receiptData": "test_receipt",
            "userId": "\(AuthService.shared.user?.uid ?? "test_user")",
            "deviceInfo": {
              "model": "iPhone15,3",
              "osVersion": "iOS 18.0",
              "locale": "en_US"
            },
            "appVersion": "1.0 (7)",
            "bundleId": "com.braindumpster.app"
          }'
        """
    }
}

// MARK: - Quick Test Function
func testVerifyReceiptEndpoint() async {
    print("🧪 Testing /verify-receipt endpoint...")

    // Get auth token
    guard let token = try? await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
        AuthService.shared.getIdToken { result in
            continuation.resume(with: result)
        }
    }) else {
        print("❌ Failed to get auth token")
        return
    }

    print("✅ Got auth token")

    // Get receipt (if available)
    guard let receiptURL = Bundle.main.appStoreReceiptURL,
          FileManager.default.fileExists(atPath: receiptURL.path) else {
        print("⚠️ No receipt available (run on device or enable StoreKit Configuration)")
        return
    }

    do {
        let receiptData = try Data(contentsOf: receiptURL)
        let receiptBase64 = receiptData.base64EncodedString()

        print("📦 Receipt size: \(receiptData.count) bytes")

        // Prepare request
        let url = URL(string: "http://57.129.81.193:5001/api/verify-receipt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload: [String: Any] = [
            "receiptData": receiptBase64,
            "userId": AuthService.shared.user?.uid ?? "test_user",
            "deviceInfo": [
                "model": "iPhone15,3",
                "osVersion": "iOS 18.0",
                "locale": "en_US"
            ],
            "appVersion": "1.0 (7)",
            "bundleId": "com.braindumpster.app"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        print("📤 Sending request...")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response")
            return
        }

        let statusCode = httpResponse.statusCode
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"

        print("📥 Response:")
        print("   Status: \(statusCode)")
        print("   Body: \(responseString)")

        if statusCode == 200 {
            print("✅ Endpoint working correctly!")
        } else {
            print("⚠️ Endpoint returned error")
        }

    } catch {
        print("❌ Error: \(error)")
    }
}

import SwiftUI

/// Helper for displaying friendly error alerts throughout the app
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    let onDismiss: (() -> Void)?
    let onRetry: (() -> Void)?

    init(error: Binding<Error?>, onDismiss: (() -> Void)? = nil, onRetry: (() -> Void)? = nil) {
        self._error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }

    func body(content: Content) -> some View {
        content
            .alert(errorTitle, isPresented: .constant(error != nil)) {
                if let onRetry = onRetry {
                    Button("Try Again") {
                        onRetry()
                        error = nil
                    }
                }

                Button("OK", role: .cancel) {
                    error = nil
                    onDismiss?()
                }
            } message: {
                Text(errorMessage)
            }
    }

    private var errorTitle: String {
        if let apiError = error as? APIError {
            return apiError.friendlyTitle
        }
        return "Oops!"
    }

    private var errorMessage: String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Something went wrong"
        }

        // Handle other common error types
        let errorString = error?.localizedDescription.lowercased() ?? ""

        if errorString.contains("network") || errorString.contains("internet") || errorString.contains("offline") {
            return "You're offline 🌐 Check your connection and try again"
        } else if errorString.contains("timeout") {
            return "That's taking too long ⏰ Check your connection?"
        } else if errorString.contains("decode") || errorString.contains("json") {
            return "Got some weird data back 🤔 Try again?"
        } else if errorString.contains("permission") || errorString.contains("denied") {
            return "Permission denied 🚫 Check your settings"
        } else {
            return error?.localizedDescription ?? "Something unexpected happened 😕"
        }
    }
}

extension View {
    /// Display error alert with friendly message
    /// - Parameters:
    ///   - error: Binding to optional Error
    ///   - onDismiss: Optional closure called when alert is dismissed
    ///   - onRetry: Optional closure that adds a "Try Again" button
    func errorAlert(_ error: Binding<Error?>, onDismiss: (() -> Void)? = nil, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onDismiss: onDismiss, onRetry: onRetry))
    }
}

// MARK: - Inline Error View
/// Show errors inline instead of in an alert
struct InlineErrorView: View {
    let error: Error
    let onRetry: (() -> Void)?

    init(error: Error, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: errorIcon)
                    .font(.system(size: 24))
                    .foregroundColor(errorColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)

                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(errorColor)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(errorColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(errorColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var errorIcon: String {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                return "wifi.slash"
            case .unauthorized:
                return "lock.fill"
            case .serverError, .httpError:
                return "exclamationmark.triangle.fill"
            case .invalidResponse:
                return "questionmark.circle.fill"
            }
        }
        return "exclamationmark.triangle.fill"
    }

    private var errorColor: Color {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                return Color.orange
            case .unauthorized:
                return Color.red
            default:
                return Color.red
            }
        }
        return Color.red
    }

    private var errorTitle: String {
        if let apiError = error as? APIError {
            return apiError.friendlyTitle
        }
        return "Error"
    }

    private var errorMessage: String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Something went wrong"
        }

        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("network") || errorString.contains("internet") {
            return "You're offline 🌐 Check your connection"
        } else if errorString.contains("timeout") {
            return "That's taking too long ⏰ Check your connection?"
        } else {
            return error.localizedDescription
        }
    }
}

// MARK: - Loading with Error State
/// Combined loading and error view
struct LoadingErrorView: View {
    let isLoading: Bool
    let error: Error?
    let loadingMessage: String
    let onRetry: (() -> Void)?

    init(
        isLoading: Bool,
        error: Error?,
        loadingMessage: String = "Loading...",
        onRetry: (() -> Void)? = nil
    ) {
        self.isLoading = isLoading
        self.error = error
        self.loadingMessage = loadingMessage
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryBlue))
                    .scaleEffect(1.2)

                Text(loadingMessage)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
            } else if let error = error {
                InlineErrorView(error: error, onRetry: onRetry)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview("Error Alert") {
    struct PreviewView: View {
        @State private var error: Error? = APIError.networkError(URLError(.notConnectedToInternet))

        var body: some View {
            VStack {
                Button("Show Error") {
                    error = APIError.httpError(500)
                }
            }
            .errorAlert($error)
        }
    }

    return PreviewView()
}

#Preview("Inline Error") {
    VStack {
        InlineErrorView(
            error: APIError.networkError(URLError(.notConnectedToInternet)),
            onRetry: {
                print("Retry tapped")
            }
        )
        .padding()

        InlineErrorView(
            error: APIError.httpError(500)
        )
        .padding()
    }
    .background(AppColors.lightBackground)
}

#Preview("Loading Error View") {
    VStack {
        LoadingErrorView(
            isLoading: false,
            error: APIError.networkError(URLError(.notConnectedToInternet)),
            onRetry: {
                print("Retry")
            }
        )
    }
}

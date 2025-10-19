import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var showSuccessMessage = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
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
                .frame(height: 100)

            // Lock Icon
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 0.88, green: 0.96, blue: 1.0))
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.open")
                    .font(.system(size: 52))
                    .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.85))
            }

            Spacer()
                .frame(height: 40)

            // Title
            Text("Forgot Password?")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            // Description
            Text("Don't worry! Enter your email address and we'll send you a password reset link.")
                .font(.system(size: 16))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()
                .frame(height: 50)

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
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

            // Send Reset Link Button
            Button(action: {
                resetPassword()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text("Send Reset Link")
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
            .disabled(isLoading || email.isEmpty)
            .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
            .padding(.horizontal, 20)
            .padding(.top, 24)

            // Back to Sign In Button
            Button(action: {
                dismiss()
            }) {
                Text("Back to Sign In")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
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

            Spacer()
        }
        .background(Color(white: 0.98))
        .overlay(
            // Success Toast
            VStack {
                if showSuccessMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)

                        Text("Reset link sent to your email!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccessMessage)
        )
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else { return }

        isLoading = true

        authService.resetPassword(email: email) { result in
            isLoading = false

            switch result {
            case .success:
                withAnimation {
                    showSuccessMessage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}

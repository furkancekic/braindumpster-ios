import SwiftUI

struct ProfileCompletionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var displayName: String = ""
    @State private var notificationTime = Date()
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success

    var body: some View {
        ZStack {
            Color(white: 0.98)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Let's make")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        +
                        Text("\nBraindumpster feel")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        +
                        Text("\nlike yours 💡")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 60)
                    .padding(.horizontal, 30)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Display Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What should we call you?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)

                            TextField("Your name", text: $displayName)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(white: 0.9), lineWidth: 1)
                                )
                        }

                        // Notification Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When should we remind you to check in?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)

                            DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(white: 0.9), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                    // Buttons
                    VStack(spacing: 16) {
                        // Continue Button
                        Button(action: {
                            saveProfile()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                            } else {
                                Text("Let's go →")
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
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.6 : 1.0)

                        // Skip Button (Always visible, equally prominent)
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Skip for now")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.35, green: 0.70, blue: 0.90), lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, type: toastType)
        .onAppear {
            loadCurrentUserInfo()
        }
    }

    private func loadCurrentUserInfo() {
        if let user = authService.user {
            displayName = user.displayName ?? ""
        }
        // Set default notification time to 9:00 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        notificationTime = calendar.date(from: components) ?? Date()
    }

    private func saveProfile() {
        // Allow saving with empty name (optional field)
        isLoading = true

        // Create profile
        let profile = UserProfile(
            displayName: displayName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : displayName.trimmingCharacters(in: .whitespaces),
            email: authService.user?.email,
            birthDate: nil,
            photoURL: nil,
            bio: nil
        )

        _Concurrency.Task {
            do {
                // Try to update profile
                try await BraindumpsterAPI.shared.updateUserProfile(profile: profile)

                // Update Firebase display name
                if let user = authService.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    try await changeRequest.commitChanges()
                }

                await MainActor.run {
                    isLoading = false
                    toastMessage = "You're all set! 🎉"
                    toastType = .success
                    showToast = true

                    // Dismiss after showing toast
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                // Check if error is 404 (user document doesn't exist in backend)
                let errorDescription = error.localizedDescription
                if errorDescription.contains("404") || errorDescription.contains("no document") {
                    // User doesn't exist in backend, try to sync first
                    do {
                        print("⚠️ User not found in backend, syncing...")
                        try await BraindumpsterAPI.shared.ensureUserExists(displayName: displayName)

                        // Now retry updating profile
                        try await BraindumpsterAPI.shared.updateUserProfile(profile: profile)

                        // Update Firebase display name
                        if let user = authService.user {
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.displayName = displayName
                            try await changeRequest.commitChanges()
                        }

                        await MainActor.run {
                            isLoading = false
                            toastMessage = "You're all set! 🎉"
                            toastType = .success
                            showToast = true

                            // Dismiss after showing toast
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isLoading = false
                            toastMessage = "Couldn't save right now. Try again?"
                            toastType = .error
                            showToast = true
                        }
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                        toastMessage = "Hmm, something went wrong. Try again?"
                        toastType = .error
                        showToast = true
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileCompletionView()
}

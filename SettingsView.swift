import SwiftUI

extension DateFormatter {
    static let premiumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var notificationsEnabled = true
    @State private var emailNotificationsEnabled = false
    @State private var soundEnabled = true
    @State private var showSignOutAlert = false
    @State private var showProfileCompletion = false
    @State private var userProfile: UserProfile?
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var showDeleteAccountAlert = false
    @State private var isDeleting = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var showPremium = false
    @StateObject private var storeManager = NativeStoreManager.shared

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color(white: 0.96))
                            .cornerRadius(12)
                    }
                    .padding(.leading, 20)

                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.leading, 12)

                    Spacer()
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color(white: 0.98))

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        Button(action: {
                            showProfileCompletion = true
                        }) {
                            HStack(spacing: 16) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.35, green: 0.75, blue: 0.95),
                                                    Color(red: 0.45, green: 0.55, blue: 0.95)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 70, height: 70)

                                    Text(getInitials())
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(authService.user?.displayName ?? "Complete Profile")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)

                                    Text(authService.user?.email ?? "No email")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(white: 0.5))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // PREMIUM Section
                        if !storeManager.isPremium {
                            Button(action: {
                                showPremium = true
                            }) {
                                HStack(spacing: 16) {
                                    // Crown Icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 1.0, green: 0.84, blue: 0.0),
                                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 70, height: 70)

                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Go Premium ✨")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.black)

                                        Text("Unlimited tasks & power features")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(white: 0.5))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(white: 0.6))
                                }
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.98, blue: 0.9),
                                            Color(red: 1.0, green: 0.95, blue: 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                                                    Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), radius: 10, x: 0, y: 5)
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Premium Badge (when user is premium)
                            HStack(spacing: 16) {
                                // Crown Icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 70, height: 70)

                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Premium Member 👑")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)

                                    if let expirationDate = storeManager.premiumExpirationDate {
                                        // Subscription with expiration
                                        Text("Active until \(expirationDate, formatter: DateFormatter.premiumDate)")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(white: 0.5))
                                    } else {
                                        // Lifetime premium
                                        Text("Lifetime Access")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(white: 0.5))
                                    }
                                }

                                Spacer()
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.98, blue: 0.9),
                                        Color(red: 1.0, green: 0.95, blue: 0.85)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                                                Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 16)
                        }

                        // NOTIFICATIONS Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("NOTIFICATIONS")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    iconColor: Color(red: 0.4, green: 0.75, blue: 0.88),
                                    iconBackgroundColor: Color(red: 0.85, green: 0.95, blue: 0.98),
                                    title: "Notifications",
                                    subtitle: "Task reminders",
                                    isOn: $notificationsEnabled
                                )

                                Divider()
                                    .padding(.leading, 80)

                                SettingsToggleRow(
                                    icon: "envelope.fill",
                                    iconColor: Color(red: 0.55, green: 0.6, blue: 0.88),
                                    iconBackgroundColor: Color(red: 0.9, green: 0.91, blue: 0.97),
                                    title: "Email Notifications",
                                    subtitle: "Daily summary email",
                                    isOn: $emailNotificationsEnabled
                                )

                                Divider()
                                    .padding(.leading, 80)

                                SettingsToggleRow(
                                    icon: "speaker.wave.2.fill",
                                    iconColor: Color(red: 0.65, green: 0.5, blue: 0.88),
                                    iconBackgroundColor: Color(red: 0.93, green: 0.89, blue: 0.97),
                                    title: "Sound",
                                    subtitle: "Notification sound",
                                    isOn: $soundEnabled
                                )
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }

                        // DATA & PRIVACY Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DATA & PRIVACY")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                Button(action: {
                                    exportUserData()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(red: 0.35, green: 0.78, blue: 0.52))
                                            .frame(width: 48, height: 48)
                                            .background(Color(red: 0.88, green: 0.97, blue: 0.91))
                                            .cornerRadius(12)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Download My Data")
                                                .font(.system(size: 17, weight: .medium))
                                                .foregroundColor(.black)

                                            Text(isExporting ? "Exporting..." : "Export all your tasks")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(white: 0.5))
                                        }

                                        Spacer()

                                        if isExporting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(white: 0.6))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                .disabled(isExporting)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }

                        // LEGAL Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("LEGAL")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                Button(action: {
                                    showPrivacyPolicy = true
                                }) {
                                    SettingsSimpleRow(
                                        icon: "shield.fill",
                                        title: "Privacy Policy",
                                        hasIconBackground: false
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()
                                    .padding(.leading, 80)

                                Button(action: {
                                    showTermsOfService = true
                                }) {
                                    SettingsSimpleRow(
                                        icon: "doc.text.fill",
                                        title: "Terms of Service",
                                        hasIconBackground: false
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }

                        // ABOUT Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ABOUT")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                HStack {
                                    Text("Version")
                                        .font(.system(size: 17))
                                        .foregroundColor(.black)

                                    Spacer()

                                    Text("1.0.0")
                                        .font(.system(size: 17))
                                        .foregroundColor(Color(white: 0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)

                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }

                        // DANGER ZONE Section
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DANGER ZONE")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red.opacity(0.7))
                                .padding(.horizontal, 28)
                                .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                Button(action: {
                                    showSignOutAlert = true
                                }) {
                                    SettingsNavigationRow(
                                        icon: "rectangle.portrait.and.arrow.right",
                                        iconColor: .orange,
                                        iconBackgroundColor: Color.orange.opacity(0.1),
                                        title: "Sign Out",
                                        subtitle: "Log out of your account",
                                        titleColor: .orange
                                    )
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading, 80)

                                Button(action: {
                                    showDeleteAccountAlert = true
                                }) {
                                    SettingsNavigationRow(
                                        icon: "trash.fill",
                                        iconColor: .red,
                                        iconBackgroundColor: Color.red.opacity(0.1),
                                        title: "Delete Account",
                                        subtitle: "Permanently delete everything",
                                        titleColor: .red
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isDeleting)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        }
                        .alert("Sign Out?", isPresented: $showSignOutAlert) {
                            Button("Cancel", role: .cancel) {}
                            Button("Sign Out", role: .destructive) {
                                signOut()
                            }
                        } message: {
                            Text("You can always sign back in anytime 👋")
                        }

                        // Footer
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text("Made with")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                                Text("❤️")
                                    .font(.system(size: 14))
                                Text("by Braindumpster Team")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }

                            Text("© 2025 All rights reserved")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.6))
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showProfileCompletion) {
            ProfileCompletionView()
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Error", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
        .alert("Delete Everything?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all your tasks. This can't be undone. Are you sure? 😢")
        }
        .alert("Delete Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }

    private func exportUserData() {
        isExporting = true

        _Concurrency.Task {
            do {
                let data = try await BraindumpsterAPI.shared.exportUserData()

                // Create temporary file
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
                let dateString = dateFormatter.string(from: Date())
                let filename = "braindumpster_export_\(dateString).json"

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try data.write(to: tempURL)

                await MainActor.run {
                    exportedFileURL = tempURL
                    isExporting = false
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportErrorMessage = error.localizedDescription
                    showExportError = true
                }
            }
        }
    }

    private func getInitials() -> String {
        guard let name = authService.user?.displayName else {
            return "?"
        }

        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else if let firstInitial = components.first?.prefix(1) {
            return String(firstInitial).uppercased()
        }
        return "?"
    }

    private func signOut() {
        do {
            try authService.signOut()
            dismiss()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() {
        isDeleting = true

        _Concurrency.Task {
            do {
                // Call API to delete account from backend
                try await BraindumpsterAPI.shared.deleteAccount()

                // Delete Firebase account
                try await authService.deleteAccount()

                await MainActor.run {
                    isDeleting = false
                    // User will be automatically logged out after account deletion
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteErrorMessage = error.localizedDescription
                    showDeleteError = true
                    print("❌ Failed to delete account: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Setting Row Components
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let iconBackgroundColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconBackgroundColor)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.4, green: 0.75, blue: 0.88))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let iconColor: Color
    let iconBackgroundColor: Color
    let title: String
    let subtitle: String
    var titleColor: Color = .black

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconBackgroundColor)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(titleColor)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsSimpleRow: View {
    let icon: String?
    let title: String
    var hasIconBackground: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            if let icon = icon {
                if hasIconBackground {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(white: 0.4))
                        .frame(width: 48, height: 48)
                        .background(Color(white: 0.95))
                        .cornerRadius(12)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 28, height: 28)
                }
            }

            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.black)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}

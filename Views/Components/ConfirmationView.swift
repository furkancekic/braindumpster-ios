import SwiftUI

struct ConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let message: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    let isDestructive: Bool
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?

    init(
        title: String,
        message: String,
        confirmButtonTitle: String = "Confirm",
        cancelButtonTitle: String = "Cancel",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.confirmButtonTitle = confirmButtonTitle
        self.cancelButtonTitle = cancelButtonTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                    onCancel?()
                }

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: iconName)
                        .font(.system(size: 36))
                        .foregroundColor(iconColor)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.4))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)

                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                        onConfirm()
                    }) {
                        Text(confirmButtonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(confirmButtonColor)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        dismiss()
                        onCancel?()
                    }) {
                        Text(cancelButtonTitle)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(white: 0.95))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 340)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }

    private var iconName: String {
        isDestructive ? "exclamationmark.triangle.fill" : "questionmark.circle.fill"
    }

    private var iconColor: Color {
        isDestructive ? Color(red: 1.0, green: 0.58, blue: 0.0) : Color(red: 0.35, green: 0.61, blue: 0.95)
    }

    private var iconBackgroundColor: Color {
        isDestructive ? Color(red: 1.0, green: 0.58, blue: 0.0) : Color(red: 0.35, green: 0.61, blue: 0.95)
    }

    private var confirmButtonColor: LinearGradient {
        if isDestructive {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.23, blue: 0.19),
                    Color(red: 0.93, green: 0.13, blue: 0.14)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.75, blue: 0.95),
                    Color(red: 0.45, green: 0.55, blue: 0.95)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConfirmationView(
            title: "Sign Out?",
            message: "Are you sure you want to sign out of your account?",
            confirmButtonTitle: "Sign Out",
            cancelButtonTitle: "Cancel",
            isDestructive: true,
            onConfirm: {}
        )
    }
}

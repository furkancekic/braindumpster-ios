import SwiftUI

struct ErrorView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let message: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let onPrimaryAction: () -> Void
    let onSecondaryAction: (() -> Void)?

    init(
        title: String,
        message: String,
        primaryButtonTitle: String = "Try Again",
        secondaryButtonTitle: String? = "Dismiss",
        onPrimaryAction: @escaping () -> Void = {},
        onSecondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Error card
            VStack(spacing: 24) {
                // Error icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                }
                .padding(.top, 8)

                // Title and message
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

                // Buttons
                VStack(spacing: 12) {
                    // Primary button
                    Button(action: {
                        dismiss()
                        onPrimaryAction()
                    }) {
                        Text(primaryButtonTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
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
                            .cornerRadius(12)
                    }

                    // Secondary button (optional)
                    if let secondaryTitle = secondaryButtonTitle {
                        Button(action: {
                            dismiss()
                            onSecondaryAction?()
                        }) {
                            Text(secondaryTitle)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(white: 0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(white: 0.95))
                                .cornerRadius(12)
                        }
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
}

#Preview {
    ErrorView(
        title: "Analysis Failed",
        message: "Analysis is taking longer than expected. Please try uploading a shorter audio file or check your internet connection.",
        primaryButtonTitle: "Try Again",
        secondaryButtonTitle: "Dismiss"
    )
}

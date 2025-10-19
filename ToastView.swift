import SwiftUI

// MARK: - Toast Type
enum ToastType {
    case success
    case error
    case info
    case warning

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .success:
            return [Color(red: 0.2, green: 0.78, blue: 0.35), Color(red: 0.15, green: 0.68, blue: 0.28)]
        case .error:
            return [Color(red: 0.92, green: 0.26, blue: 0.22), Color(red: 0.82, green: 0.16, blue: 0.18)]
        case .info:
            return [Color(red: 0.35, green: 0.75, blue: 0.95), Color(red: 0.45, green: 0.55, blue: 0.95)]
        case .warning:
            return [Color(red: 0.98, green: 0.74, blue: 0.02), Color(red: 0.88, green: 0.64, blue: 0.0)]
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)

                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: type.colors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isShowing = false
                    }
                }
                .onAppear {
                    // Haptic feedback based on toast type
                    switch type {
                    case .success:
                        HapticFeedback.success()
                    case .error:
                        HapticFeedback.error()
                    case .warning:
                        HapticFeedback.warning()
                    case .info:
                        HapticFeedback.light()
                    }

                    // Auto dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isShowing = false
                        }
                    }
                }
            }

            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastType

    func body(content: Content) -> some View {
        ZStack {
            content

            ToastView(message: message, type: type, isShowing: $isShowing)
        }
    }
}

// MARK: - View Extension
extension View {
    func toast(isShowing: Binding<Bool>, message: String, type: ToastType = .info) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, type: type))
    }
}

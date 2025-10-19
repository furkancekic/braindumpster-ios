import UIKit

/// Helper class to provide haptic feedback throughout the app
enum HapticFeedback {

    /// Light impact haptic (for button presses, toggles)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact haptic (for selection changes, swipes)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact haptic (for important actions)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success haptic (for task completion, successful saves)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning haptic (for caution actions)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error haptic (for failures, errors)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Selection haptic (for picker changes, segmented control)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

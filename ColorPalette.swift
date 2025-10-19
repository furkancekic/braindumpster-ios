import SwiftUI

/// Centralized color palette for Braindumpster app
/// Ensures consistent design system across all views
enum AppColors {

    // MARK: - Primary Colors
    static let primaryBlue = Color(red: 0.4, green: 0.75, blue: 0.95)
    static let primaryBlueDark = Color(red: 0.45, green: 0.55, blue: 0.95)
    static let accentBlue = Color(red: 0.45, green: 0.75, blue: 1.0)

    // MARK: - Success & Positive
    static let successGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let successGreenDark = Color(red: 0.15, green: 0.68, blue: 0.28)

    // MARK: - Warning & Attention
    static let warningOrange = Color.orange
    static let warningYellow = Color(red: 0.98, green: 0.74, blue: 0.02)
    static let warningYellowDark = Color(red: 0.88, green: 0.64, blue: 0.0)

    // MARK: - Error & Destructive
    static let errorRed = Color.red
    static let errorRedBright = Color(red: 0.92, green: 0.26, blue: 0.22)
    static let errorRedDark = Color(red: 0.82, green: 0.16, blue: 0.18)

    // MARK: - Premium & Special
    static let premiumGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let premiumGoldDark = Color(red: 1.0, green: 0.65, blue: 0.0)

    // MARK: - Backgrounds
    static let darkBackground = Color(red: 0.11, green: 0.13, blue: 0.18)
    static let lightBackground = Color(white: 0.98)
    static let cardBackground = Color.white
    static let systemBackground = Color(UIColor.systemGroupedBackground)

    // MARK: - Text Colors
    static let textPrimary = Color.black
    static let textSecondary = Color(white: 0.5)
    static let textTertiary = Color(white: 0.7)
    static let textLight = Color.white

    // MARK: - Overlay & Borders
    static let overlayLight = Color.white.opacity(0.15)
    static let overlayDark = Color.black.opacity(0.4)
    static let borderLight = Color(white: 0.9)
    static let borderMedium = Color(white: 0.75)

    // MARK: - Gradients
    static func primaryGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primaryBlue, primaryBlueDark]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func successGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [successGreen, successGreenDark]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func warningGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [warningYellow, warningYellowDark]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func errorGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [errorRedBright, errorRedDark]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func premiumGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [premiumGold, premiumGoldDark]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Priority Colors
    static func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high", "urgent":
            return errorRed
        case "medium":
            return warningOrange
        case "low":
            return successGreen
        default:
            return Color.gray
        }
    }

    // MARK: - Task Density Colors (for heatmap)
    static func densityColor(taskCount: Int) -> Color {
        switch taskCount {
        case 0:
            return Color.clear
        case 1...2:
            return primaryBlue.opacity(0.3)
        case 3...4:
            return primaryBlue.opacity(0.6)
        default:
            return primaryBlue.opacity(0.9)
        }
    }
}

// MARK: - Semantic Color Names
/// Provides semantic names for common color use cases
extension AppColors {
    // Button colors
    static let buttonPrimary = primaryGradient()
    static let buttonSuccess = successGradient()
    static let buttonDestructive = errorRed

    // Card colors
    static let cardHighlight = primaryBlue.opacity(0.1)
    static let cardShadow = Color.black.opacity(0.1)

    // Icon backgrounds
    static let iconBackgroundBlue = primaryBlue.opacity(0.15)
    static let iconBackgroundGreen = successGreen.opacity(0.15)
    static let iconBackgroundOrange = warningOrange.opacity(0.15)
    static let iconBackgroundRed = errorRed.opacity(0.15)

    // Special states
    static let overdueBackground = errorRed.opacity(0.05)
    static let overdueBorder = errorRed.opacity(0.2)
    static let completedOpacity: Double = 0.6
}

// MARK: - Design System Constants
/// Other design system constants like spacing, corner radius, etc.
enum AppDesign {
    // Corner radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24

    // Spacing
    static let spacingTiny: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16
    static let spacingXLarge: CGFloat = 20
    static let spacingXXLarge: CGFloat = 24

    // Padding
    static let paddingSmall: CGFloat = 12
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 20

    // Shadow
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowOpacity: Double = 0.15

    // Animation
    static let animationDuration: Double = 0.3
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.7
}

// MARK: - Font System
/// Consistent typography across the app
enum AppFonts {
    // Headlines
    static func largeTitle(weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight)
    }

    static func title(weight: Font.Weight = .bold) -> Font {
        .system(size: 28, weight: weight)
    }

    static func title2(weight: Font.Weight = .bold) -> Font {
        .system(size: 24, weight: weight)
    }

    static func title3(weight: Font.Weight = .semibold) -> Font {
        .system(size: 20, weight: weight)
    }

    // Body text
    static func body(weight: Font.Weight = .regular) -> Font {
        .system(size: 16, weight: weight)
    }

    static func bodyLarge(weight: Font.Weight = .regular) -> Font {
        .system(size: 18, weight: weight)
    }

    static func callout(weight: Font.Weight = .medium) -> Font {
        .system(size: 15, weight: weight)
    }

    // Small text
    static func footnote(weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight)
    }

    static func caption(weight: Font.Weight = .regular) -> Font {
        .system(size: 12, weight: weight)
    }
}

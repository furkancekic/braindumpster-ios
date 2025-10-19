import SwiftUI

/// Reusable empty state component for consistent UX across the app
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.primaryBlue.opacity(0.1),
                                AppColors.primaryBlue.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primaryBlue)
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.title3())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)

            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFonts.callout(weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryGradient())
                        .cornerRadius(AppDesign.cornerRadiusMedium)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Predefined Empty States
extension EmptyStateView {
    /// Empty state for no tasks
    static func noTasks() -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All clear! 🎉",
            message: "No tasks yet — that's either peace or procrastination 😅\nTap the buttons below to get started!"
        )
    }

    /// Empty state for completed tasks
    static func noCompletedTasks() -> EmptyStateView {
        EmptyStateView(
            icon: "star.circle",
            title: "Nothing completed yet",
            message: "Complete a task to see it here!\nYou got this 💪"
        )
    }

    /// Empty state for calendar day with no tasks
    static func noDayTasks(date: String = "this day") -> EmptyStateView {
        EmptyStateView(
            icon: "sun.max",
            title: "Free day! 🌳",
            message: "No tasks scheduled for \(date)\nTime for a walk?"
        )
    }

    /// Empty state for search with no results
    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results found",
            message: "Couldn't find anything for \"\(query)\"\nTry a different search term"
        )
    }

    /// Empty state for conversation history
    static func noConversations() -> EmptyStateView {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "No conversations yet",
            message: "Start chatting with the AI assistant\nto create your first conversation 💬"
        )
    }

    /// Empty state for reminders
    static func noReminders() -> EmptyStateView {
        EmptyStateView(
            icon: "bell.slash",
            title: "No reminders set",
            message: "Add reminders to tasks so you\nnever forget what's important ⏰"
        )
    }

    /// Empty state for network error
    static func networkError(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "You're offline 🌐",
            message: "Check your internet connection\nand try again",
            actionTitle: "Retry",
            action: onRetry
        )
    }

    /// Empty state for general error
    static func generalError(message: String, onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Something went wrong 😕",
            message: message,
            actionTitle: "Try Again",
            action: onRetry
        )
    }

    /// Empty state for loading failure
    static func loadingFailed(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "arrow.clockwise.circle",
            title: "Couldn't load data",
            message: "Something went wrong on our end\nLet's try that again",
            actionTitle: "Reload",
            action: onRetry
        )
    }

    /// Empty state for no notifications
    static func noNotifications() -> EmptyStateView {
        EmptyStateView(
            icon: "bell.badge",
            title: "All caught up! ✨",
            message: "No new notifications\nYou're on top of everything"
        )
    }
}

// MARK: - Compact Empty State
/// Smaller empty state for inline use
struct CompactEmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.textSecondary)

            Text(message)
                .font(AppFonts.callout())
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }
}

extension CompactEmptyStateView {
    static func noTasks() -> CompactEmptyStateView {
        CompactEmptyStateView(
            icon: "checkmark.circle",
            message: "No tasks — you're all clear! 🎉"
        )
    }

    static func noResults() -> CompactEmptyStateView {
        CompactEmptyStateView(
            icon: "magnifyingglass",
            message: "No results found"
        )
    }

    static func noItems() -> CompactEmptyStateView {
        CompactEmptyStateView(
            icon: "tray",
            message: "Nothing here yet"
        )
    }
}

// MARK: - Preview
#Preview("Full Empty State") {
    VStack {
        EmptyStateView.noTasks()
    }
    .background(AppColors.lightBackground)
}

#Preview("Empty State with Action") {
    VStack {
        EmptyStateView.networkError {
            print("Retry tapped")
        }
    }
    .background(AppColors.lightBackground)
}

#Preview("Compact Empty State") {
    VStack {
        CompactEmptyStateView.noTasks()
    }
    .background(Color.white)
}

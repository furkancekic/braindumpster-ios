import SwiftUI

struct SnoozeOptionsView: View {
    @Environment(\.dismiss) var dismiss
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @State private var showToast = false
    @State private var toastMessage = ""

    // Snooze options
    let snoozeOptions: [(title: String, icon: String, duration: TimeInterval)] = [
        ("30 minutes", "clock", 30 * 60),
        ("1 hour", "clock.fill", 60 * 60),
        ("2 hours", "hourglass", 2 * 60 * 60),
        ("3 hours", "hourglass.circle", 3 * 60 * 60),
        ("Tomorrow morning", "sunrise.fill", 0), // Special handling
        ("Tomorrow afternoon", "sun.max.fill", 0), // Special handling
        ("This evening", "moon.stars.fill", 0), // Special handling
        ("Next week", "calendar", 7 * 24 * 60 * 60)
    ]

    var body: some View {
        ZStack {
            Color(white: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(white: 0.5))
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    Spacer()

                    Text("Snooze Task")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                    // Invisible placeholder to center the title
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Task preview
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13))
                        Text("Currently due: \(task.time)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(white: 0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Subtitle
                Text("Choose when to be reminded again:")
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                // Snooze options
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(snoozeOptions.enumerated()), id: \.offset) { index, option in
                            SnoozeOptionButton(
                                title: option.title,
                                icon: option.icon,
                                action: {
                                    snoozeTask(option: option)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, type: .success)
    }

    private func snoozeTask(option: (title: String, icon: String, duration: TimeInterval)) {
        HapticFeedback.success()

        var newDueDate: Date

        switch option.title {
        case "Tomorrow morning":
            // Tomorrow at 9 AM
            newDueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            newDueDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: newDueDate) ?? newDueDate

        case "Tomorrow afternoon":
            // Tomorrow at 2 PM
            newDueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            newDueDate = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: newDueDate) ?? newDueDate

        case "This evening":
            // Today at 6 PM, or tomorrow if past 6 PM
            let calendar = Calendar.current
            newDueDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
            if newDueDate < Date() {
                // If 6 PM has passed, schedule for tomorrow at 6 PM
                newDueDate = calendar.date(byAdding: .day, value: 1, to: newDueDate) ?? newDueDate
            }

        default:
            // For duration-based options
            newDueDate = Date().addingTimeInterval(option.duration)
        }

        // Update task via API
        viewModel.snoozeTask(task, until: newDueDate)

        toastMessage = "Snoozed until \(option.title.lowercased()) 💤"
        showToast = true

        // Dismiss after showing toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - Snooze Option Button
struct SnoozeOptionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.7))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SnoozeOptionsView(
        task: Task(
            id: "preview",
            title: "Test Task",
            time: "2:00 PM",
            category: "Work",
            notificationCount: 1,
            isCompleted: false,
            description: "This is a test task",
            priority: "medium",
            dueDate: "2025-10-11",
            reminders: [],
            suggestions: []
        ),
        viewModel: TaskViewModel()
    )
}

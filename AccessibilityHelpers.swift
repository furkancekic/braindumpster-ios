import SwiftUI

/// Accessibility helpers for consistent VoiceOver support throughout the app
enum AccessibilityLabels {

    // MARK: - Navigation
    static let closeButton = "Close"
    static let backButton = "Back"
    static let menuButton = "Menu"
    static let settingsButton = "Settings"
    static let profileButton = "Profile"

    // MARK: - Task Actions
    static let completeTask = "Complete task"
    static let uncompleteTask = "Mark task as incomplete"
    static let deleteTask = "Delete task"
    static let editTask = "Edit task"
    static let snoozeTask = "Snooze task"
    static let viewTaskDetails = "View task details"

    // MARK: - Task Creation
    static let addTaskButton = "Add new task"
    static let voiceInputButton = "Voice input - Add task by speaking"
    static let chatButton = "Chat with AI assistant"
    static let saveTaskButton = "Save task"
    static let cancelButton = "Cancel"

    // MARK: - Calendar
    static let calendarDay = "Calendar day"
    static let todayButton = "Today"
    static let viewCalendarButton = "View calendar"

    // MARK: - Streak
    static let streakCard = "Daily streak card"

    // MARK: - Premium
    static let premiumButton = "Go premium"
    static let restorePurchases = "Restore previous purchases"

    // MARK: - Auth
    static let signInButton = "Sign in"
    static let signUpButton = "Sign up"
    static let signOutButton = "Sign out"
    static let forgotPasswordButton = "Forgot password"

    // MARK: - Input Fields
    static let emailField = "Email address"
    static let passwordField = "Password"
    static let taskTitleField = "Task title"
    static let taskDescriptionField = "Task description"
    static let messageField = "Type a message"
}

/// Accessibility hints provide additional context
enum AccessibilityHints {

    // MARK: - Task Actions
    static let completeTask = "Double tap to mark this task as complete and add it to your streak"
    static let deleteTask = "Double tap to permanently delete this task"
    static let snoozeTask = "Double tap to reschedule this task for later"
    static let editTask = "Double tap to edit task details"

    // MARK: - Navigation
    static let closeView = "Double tap to close this view"
    static let openSettings = "Double tap to open settings"

    // MARK: - Task Creation
    static let voiceInput = "Double tap to record a voice message and let AI create tasks for you"
    static let chatAssistant = "Double tap to chat with AI assistant to create and manage tasks"
    static let addTask = "Double tap to create a new task"

    // MARK: - Calendar
    static let selectDate = "Double tap to view tasks for this date"

    // MARK: - Premium
    static let viewPremium = "Double tap to see premium features and pricing"
}

/// Helper functions for creating accessibility strings
enum AccessibilityHelpers {

    /// Create accessibility label for a task
    static func taskLabel(title: String, dueDate: String?, time: String, priority: String, isCompleted: Bool) -> String {
        let status = isCompleted ? "Completed" : "Not completed"
        if let dueDate = dueDate {
            return "\(title), due \(dueDate) at \(time), \(priority) priority, \(status)"
        } else {
            return "\(title), \(priority) priority, \(status)"
        }
    }

    /// Create accessibility label for streak
    static func streakLabel(currentStreak: Int, longestStreak: Int) -> String {
        if currentStreak == 0 {
            return "No active streak. Complete a task to start your streak. Longest streak: \(longestStreak) days"
        } else if currentStreak == 1 {
            return "1 day streak. Keep going! Longest streak: \(longestStreak) days"
        } else {
            return "\(currentStreak) day streak. You're on fire! Longest streak: \(longestStreak) days"
        }
    }

    /// Create accessibility label for progress
    static func progressLabel(completed: Int, total: Int) -> String {
        if total == 0 {
            return "No tasks today"
        } else {
            let percentage = Int((Double(completed) / Double(total)) * 100)
            return "\(completed) of \(total) tasks completed, \(percentage) percent progress"
        }
    }

    /// Create accessibility label for calendar day
    static func calendarDayLabel(day: Int, month: String, taskCount: Int) -> String {
        if taskCount == 0 {
            return "\(month) \(day), no tasks"
        } else if taskCount == 1 {
            return "\(month) \(day), 1 task"
        } else {
            return "\(month) \(day), \(taskCount) tasks"
        }
    }

    /// Create accessibility value for time picker
    static func timeValue(hour: Int, minute: Int) -> String {
        let amPm = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour):\(String(format: "%02d", minute)) \(amPm)"
    }

    /// Create accessibility label for notification setting
    static func notificationLabel(enabled: Bool, time: String?) -> String {
        if enabled, let time = time {
            return "Notifications enabled, daily reminder at \(time)"
        } else {
            return "Notifications disabled"
        }
    }
}

// MARK: - View Extensions for Easy Accessibility
extension View {
    /// Add standard accessibility for a button with label and hint
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Add accessibility for a task card
    func accessibleTask(task: Task, index: Int, totalTasks: Int) -> some View {
        let label = AccessibilityHelpers.taskLabel(
            title: task.title,
            dueDate: task.dueDate,
            time: task.time,
            priority: task.priority,
            isCompleted: task.isCompleted
        )

        return self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label). Task \(index + 1) of \(totalTasks)")
            .accessibilityAddTraits([.isButton])
    }

    /// Add accessibility for input field
    func accessibleTextField(label: String, value: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isSearchField)
    }

    /// Add accessibility for toggle
    func accessibleToggle(label: String, isOn: Bool) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to toggle")
    }

    /// Mark element as header for better navigation
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(label)
    }

    /// Group related elements together
    func accessibleGroup(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }

    /// Hide decorative elements from VoiceOver
    func decorative() -> some View {
        self
            .accessibilityHidden(true)
    }
}

// MARK: - Accessibility Announcement Helper
struct AccessibilityAnnouncement {
    /// Post an announcement for VoiceOver users
    static func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: priority, argument: message)
        }
    }

    /// Announce task completed
    static func taskCompleted(_ taskTitle: String) {
        announce("\(taskTitle) completed. Great job!")
    }

    /// Announce task created
    static func taskCreated(_ taskTitle: String) {
        announce("\(taskTitle) created successfully")
    }

    /// Announce task deleted
    static func taskDeleted() {
        announce("Task deleted")
    }

    /// Announce error
    static func error(_ message: String) {
        announce("Error: \(message)")
    }

    /// Announce loading started
    static func loadingStarted(_ message: String = "Loading") {
        announce(message)
    }

    /// Announce loading completed
    static func loadingCompleted() {
        announce("Loading completed")
    }

    /// Announce milestone reached
    static func milestone(_ days: Int) {
        announce("\(days) day streak milestone reached! Congratulations!")
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Button("Complete Task") {
            AccessibilityAnnouncement.taskCompleted("Buy groceries")
        }
        .accessibleButton(
            label: AccessibilityLabels.completeTask,
            hint: AccessibilityHints.completeTask
        )

        Button("Settings") {}
            .accessibleButton(
                label: AccessibilityLabels.settingsButton,
                hint: AccessibilityHints.openSettings
            )

        Text("Daily Progress")
            .accessibleHeader("Daily Progress")
    }
    .padding()
}

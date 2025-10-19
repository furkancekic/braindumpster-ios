import Foundation
import FirebaseAuth

// MARK: - User Profile
struct UserProfile: Codable {
    var displayName: String?
    var email: String?
    var birthDate: String?
    var photoURL: String?
    var bio: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case email
        case birthDate = "birth_date"
        case photoURL = "photo_url"
        case bio
    }
}

struct TaskReminder: Identifiable {
    let id: String
    let reminderTime: String
    let message: String
    let sent: Bool

    var formattedReminderTime: String {
        DateFormatterHelper.formatReminderTime(reminderTime)
    }

    var isUpcoming: Bool {
        DateFormatterHelper.isReminderUpcoming(reminderTime)
    }
}

// MARK: - Date Formatter Helper
class DateFormatterHelper {
    static func formatReminderTime(_ dateString: String) -> String {
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ssZ",           // ISO 8601 with timezone: 2025-10-16T20:50:00+00:00
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            // Parse with UTC timezone (backend sends UTC)
            formatter.timeZone = TimeZone(abbreviation: "UTC")

            if let date = formatter.date(from: dateString) {
                let now = Date()
                let calendar = Calendar.current

                // Check if today
                if calendar.isDateInToday(date) {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    timeFormatter.timeZone = TimeZone.current  // Display in user's timezone
                    return "Today at \(timeFormatter.string(from: date))"
                }

                // Check if tomorrow
                if calendar.isDateInTomorrow(date) {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    timeFormatter.timeZone = TimeZone.current  // Display in user's timezone
                    return "Tomorrow at \(timeFormatter.string(from: date))"
                }

                // Check if this week
                let daysUntil = calendar.dateComponents([.day], from: now, to: date).day ?? 0
                if daysUntil > 0 && daysUntil <= 7 {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "EEEE 'at' HH:mm"
                    timeFormatter.timeZone = TimeZone.current  // Display in user's timezone
                    return timeFormatter.string(from: date)
                }

                // Check if this year
                if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "MMM d 'at' HH:mm"
                    timeFormatter.timeZone = TimeZone.current  // Display in user's timezone
                    return timeFormatter.string(from: date)
                }

                // Full date
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
                timeFormatter.timeZone = TimeZone.current  // Display in user's timezone
                return timeFormatter.string(from: date)
            }
        }

        // If parsing fails, return original
        return dateString
    }

    static func isReminderUpcoming(_ dateString: String) -> Bool {
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ssZ",           // ISO 8601 with timezone: 2025-10-16T20:50:00+00:00
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = formatter.date(from: dateString) {
                return date > Date()
            }
        }

        return false
    }
}

struct Task: Identifiable {
    let id: String
    var title: String
    var time: String
    var category: String
    var notificationCount: Int
    var isCompleted: Bool
    var description: String
    var priority: String
    var dueDate: String?
    var reminders: [TaskReminder]  // Mutable for deletion
    var suggestions: [Suggestion]  // AI-generated suggestions

    // Convert TaskModel to Task
    static func from(_ taskModel: TaskModel) -> Task {
        let time = extractTime(from: taskModel.dueDate) ?? ""
        let isCompleted = taskModel.status.lowercased() == "completed"

        // Convert reminders - keep full datetime
        let reminders = taskModel.reminders?.map { reminder in
            TaskReminder(
                id: reminder.id,
                reminderTime: reminder.reminderTime,
                message: reminder.message,
                sent: reminder.sent ?? false
            )
        } ?? []

        // Count unsent reminders
        let reminderCount = reminders.filter { !$0.sent }.count

        return Task(
            id: taskModel.id,
            title: taskModel.title,
            time: time,
            category: taskModel.category ?? "General",
            notificationCount: reminderCount,
            isCompleted: isCompleted,
            description: taskModel.description,
            priority: taskModel.priority,
            dueDate: taskModel.dueDate,
            reminders: reminders,
            suggestions: taskModel.suggestions ?? []
        )
    }

    private static func extractTime(from dateString: String?) -> String? {
        guard let dateString = dateString else { return nil }

        // Try multiple date formats
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")

            if let date = formatter.date(from: dateString) {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                return timeFormatter.string(from: date)
            }
        }

        return nil
    }
}

struct SuggestedTask: Identifiable {
    let id = UUID()
    var title: String
    var date: String
    var time: String
    var category: String
    var reminders: [String]
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completedTasks: [Task] = []
    @Published var overdueTasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var dailyProgress: (completed: Int, total: Int) {
        let total = tasks.count + completedTasks.count + overdueTasks.count
        let completed = completedTasks.count
        return (completed, total)
    }

    var activeTasks: [Task] {
        tasks.filter { !isTaskOverdue($0) }
    }

    init() {
        fetchTasks()
    }

    func isTaskOverdue(_ task: Task) -> Bool {
        guard let dueDateString = task.dueDate else { return false }

        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")

            if let dueDate = formatter.date(from: dueDateString) {
                return dueDate < Date() && !task.isCompleted
            }
        }

        return false
    }

    func fetchTasks() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user")
            return
        }

        isLoading = true

        _Concurrency.Task {
            do {
                // Fetch approved, pending and completed tasks
                let tasksResponse = try await BraindumpsterAPI.shared.getUserTasks(userId: userId, status: "approved,pending,completed")

                await MainActor.run {
                    // Separate active, overdue and completed tasks
                    let allTasks = tasksResponse.tasks.map { Task.from($0) }
                    self.completedTasks = allTasks.filter { $0.isCompleted }

                    let incompleteTasks = allTasks.filter { !$0.isCompleted }
                    self.overdueTasks = incompleteTasks.filter { self.isTaskOverdue($0) }
                    self.tasks = incompleteTasks.filter { !self.isTaskOverdue($0) }

                    self.isLoading = false

                    print("✅ Loaded \(self.tasks.count) active, \(self.overdueTasks.count) overdue, and \(self.completedTasks.count) completed tasks")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("❌ Failed to fetch tasks: \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteTask(_ task: Task) {
        _Concurrency.Task {
            do {
                try await BraindumpsterAPI.shared.deleteTask(taskId: task.id)

                await MainActor.run {
                    self.tasks.removeAll { $0.id == task.id }
                    self.overdueTasks.removeAll { $0.id == task.id }
                    self.completedTasks.removeAll { $0.id == task.id }
                    print("✅ Task deleted: \(task.title)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to delete task: \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteReminder(taskId: String, reminderId: String) {
        _Concurrency.Task {
            do {
                try await BraindumpsterAPI.shared.deleteReminder(taskId: taskId, reminderId: reminderId)

                await MainActor.run {
                    // Update the task in the list by removing the reminder
                    if let taskIndex = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[taskIndex].reminders.removeAll { $0.id == reminderId }
                        // Update notification count
                        self.tasks[taskIndex].notificationCount = self.tasks[taskIndex].reminders.filter { !$0.sent }.count
                        print("✅ Reminder deleted from task")
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to delete reminder: \(error.localizedDescription)")
                }
            }
        }
    }

    func toggleTaskComplete(_ task: Task) {
        _Concurrency.Task {
            do {
                let newStatus = task.isCompleted ? "approved" : "completed"
                try await BraindumpsterAPI.shared.updateTaskStatus(taskId: task.id, status: newStatus)

                await MainActor.run {
                    if task.isCompleted {
                        // Move from completed to active or overdue
                        self.completedTasks.removeAll { $0.id == task.id }
                        var updatedTask = task
                        updatedTask.isCompleted = false

                        if self.isTaskOverdue(updatedTask) {
                            self.overdueTasks.append(updatedTask)
                        } else {
                            self.tasks.append(updatedTask)
                        }
                        print("✅ Task marked as active")
                    } else {
                        // Move from active/overdue to completed
                        self.tasks.removeAll { $0.id == task.id }
                        self.overdueTasks.removeAll { $0.id == task.id }
                        var updatedTask = task
                        updatedTask.isCompleted = true
                        self.completedTasks.append(updatedTask)

                        // Record streak
                        StreakManager.shared.recordTaskCompletion()

                        print("✅ Task marked as completed")
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to update task status: \(error.localizedDescription)")
                }
            }
        }
    }

    func snoozeTask(_ task: Task, until newDueDate: Date) {
        _Concurrency.Task {
            do {
                // Format the new due date
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: newDueDate)

                formatter.dateFormat = "h:mm a"
                let timeString = formatter.string(from: newDueDate)

                // Update task via API
                try await BraindumpsterAPI.shared.updateTask(
                    taskId: task.id,
                    dueDate: dateString,
                    time: timeString
                )

                await MainActor.run {
                    // Update task in the appropriate list
                    var updatedTask = task
                    updatedTask.dueDate = dateString
                    updatedTask.time = timeString

                    // Remove from current list
                    self.tasks.removeAll { $0.id == task.id }
                    self.overdueTasks.removeAll { $0.id == task.id }
                    self.completedTasks.removeAll { $0.id == task.id }

                    // Add to appropriate list based on new due date
                    if self.isTaskOverdue(updatedTask) {
                        self.overdueTasks.append(updatedTask)
                    } else {
                        self.tasks.append(updatedTask)
                    }

                    print("✅ Task snoozed to \(dateString) at \(timeString)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to snooze task: \(error.localizedDescription)")
                }
            }
        }
    }
}

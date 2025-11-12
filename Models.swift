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

// MARK: - Meeting Recorder Models

enum RecordingType: String, Codable {
    case meeting = "meeting"
    case lecture = "lecture"
    case personal = "personal"
    case unknown = "unknown"

    var icon: String {
        switch self {
        case .meeting: return "👥"
        case .lecture: return "📚"
        case .personal: return "✏️"
        case .unknown: return "🎙️"
        }
    }

    var displayName: String {
        switch self {
        case .meeting: return "Meeting"
        case .lecture: return "Lecture"
        case .personal: return "Personal"
        case .unknown: return "Recording"
        }
    }
}

enum RecordingStatus: String, Codable {
    case processing = "processing"
    case transcribing = "transcribing"
    case transcriptReady = "transcript_ready"
    case analyzingQuick = "analyzing_quick"
    case previewReady = "preview_ready"
    case analyzingDeep = "analyzing_deep"
    case completed = "completed"
    case failed = "failed"

    var displayText: String {
        switch self {
        case .processing: return "Processing..."
        case .transcribing: return "Transcribing audio..."
        case .transcriptReady: return "Transcript ready"
        case .analyzingQuick: return "Analyzing..."
        case .previewReady: return "Preview ready"
        case .analyzingDeep: return "Deep analysis..."
        case .completed: return "Complete"
        case .failed: return "Failed"
        }
    }

    var progressPercentage: Double {
        switch self {
        case .processing: return 0.1
        case .transcribing: return 0.3
        case .transcriptReady: return 0.5
        case .analyzingQuick: return 0.6
        case .previewReady: return 0.75
        case .analyzingDeep: return 0.9
        case .completed: return 1.0
        case .failed: return 0.0
        }
    }
}

struct Recording: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let date: Date
    let duration: TimeInterval // in seconds
    let type: RecordingType
    let aiDetected: Bool
    let status: RecordingStatus
    let summary: RecordingSummary?
    let sentiment: SentimentData?
    let transcript: [TranscriptSegment]
    let actionItems: [ActionItem]
    let keyPoints: [KeyPoint]
    let decisions: [Decision]
    let audioFileURL: String?
    let language: String? // Detected language (tr, en, de, etc.)

    // New fields for progressive loading
    let transcriptText: String? // Full transcript as single string
    let transcriptProgress: Double? // 0.0-1.0 for transcription progress
    let analysisStage: String? // Current analysis stage

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var speakerCount: Int {
        Set(transcript.map { $0.speaker }).count
    }

    var taskCount: Int {
        actionItems.count
    }

    // Custom decoder to handle missing fields during processing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)

        // Decode date from ISO8601 string (Firestore stores dates as strings)
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsedDate = formatter.date(from: dateString) {
                date = parsedDate
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                date = formatter.date(from: dateString) ?? Date()
            }
        } else {
            // Fallback to Date type if it's stored as Timestamp
            date = try container.decode(Date.self, forKey: .date)
        }

        duration = try container.decode(TimeInterval.self, forKey: .duration)
        type = try container.decode(RecordingType.self, forKey: .type)
        status = try container.decode(RecordingStatus.self, forKey: .status)
        summary = try container.decodeIfPresent(RecordingSummary.self, forKey: .summary)
        audioFileURL = try container.decodeIfPresent(String.self, forKey: .audioFileURL)

        // Provide defaults for optional fields during processing
        aiDetected = try container.decodeIfPresent(Bool.self, forKey: .aiDetected) ?? false
        sentiment = try container.decodeIfPresent(SentimentData.self, forKey: .sentiment)
        transcript = try container.decodeIfPresent([TranscriptSegment].self, forKey: .transcript) ?? []
        actionItems = try container.decodeIfPresent([ActionItem].self, forKey: .actionItems) ?? []
        keyPoints = try container.decodeIfPresent([KeyPoint].self, forKey: .keyPoints) ?? []
        decisions = try container.decodeIfPresent([Decision].self, forKey: .decisions) ?? []
        language = try container.decodeIfPresent(String.self, forKey: .language)

        // New progressive loading fields
        transcriptText = try container.decodeIfPresent(String.self, forKey: .transcriptText)
        transcriptProgress = try container.decodeIfPresent(Double.self, forKey: .transcriptProgress)
        analysisStage = try container.decodeIfPresent(String.self, forKey: .analysisStage)
    }

    // Keep standard init for creating Recording objects in code
    init(id: String, title: String, date: Date, duration: TimeInterval, type: RecordingType,
         aiDetected: Bool, status: RecordingStatus, summary: RecordingSummary?,
         sentiment: SentimentData?, transcript: [TranscriptSegment],
         actionItems: [ActionItem], keyPoints: [KeyPoint],
         decisions: [Decision], audioFileURL: String?, language: String? = nil,
         transcriptText: String? = nil, transcriptProgress: Double? = nil,
         analysisStage: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.type = type
        self.aiDetected = aiDetected
        self.status = status
        self.summary = summary
        self.sentiment = sentiment
        self.transcript = transcript
        self.actionItems = actionItems
        self.keyPoints = keyPoints
        self.decisions = decisions
        self.audioFileURL = audioFileURL
        self.language = language
        self.transcriptText = transcriptText
        self.transcriptProgress = transcriptProgress
        self.analysisStage = analysisStage
    }
}

struct RecordingSummary: Codable, Equatable {
    let brief: String // 1-2 sentences
    let detailed: String // 3-4 paragraphs
    let keyTakeaways: [String]
}

struct SentimentData: Codable, Equatable {
    let overall: String // positive, neutral, negative, mixed
    let score: Int // 0-100
    let moments: [SentimentMoment]
    let speakerMoods: [SpeakerMood]
}

struct SentimentMoment: Codable, Identifiable, Equatable {
    let id = UUID()
    let timestamp: String // "MM:SS"
    let type: String // positive, tension, negative, neutral
    let description: String

    enum CodingKeys: String, CodingKey {
        case timestamp, type, description
    }

    static func == (lhs: SentimentMoment, rhs: SentimentMoment) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.type == rhs.type && lhs.description == rhs.description
    }
}

struct SpeakerMood: Codable, Identifiable, Equatable {
    let id = UUID()
    let speaker: String
    let mood: String // positive, neutral, negative
    let energy: Int // 0-100
    let talkTimePercentage: Double // Backend sends decimal values like 28.5

    enum CodingKeys: String, CodingKey {
        case speaker, mood, energy, talkTimePercentage
    }

    static func == (lhs: SpeakerMood, rhs: SpeakerMood) -> Bool {
        lhs.speaker == rhs.speaker && lhs.mood == rhs.mood && lhs.energy == rhs.energy && lhs.talkTimePercentage == rhs.talkTimePercentage
    }
}

struct TranscriptSegment: Codable, Identifiable, Equatable {
    let id = UUID()
    let speaker: String
    let timestamp: String // "MM:SS"
    let text: String
    let sentiment: String? // positive, neutral, negative

    enum CodingKeys: String, CodingKey {
        case speaker, timestamp, text, sentiment
    }

    static func == (lhs: TranscriptSegment, rhs: TranscriptSegment) -> Bool {
        lhs.speaker == rhs.speaker && lhs.timestamp == rhs.timestamp && lhs.text == rhs.text && lhs.sentiment == rhs.sentiment
    }
}

struct ActionItem: Codable, Identifiable, Equatable {
    let id = UUID()
    let task: String
    let assignee: String // Name or "You"
    let dueDate: String? // relative date like "2 days later"
    let priority: String // high, medium, low
    let timestamp: String // "MM:SS"
    let context: String // Why this task came up
    var isCompleted: Bool = false

    enum CodingKeys: String, CodingKey {
        case task, assignee, dueDate, priority, timestamp, context, isCompleted
    }

    static func == (lhs: ActionItem, rhs: ActionItem) -> Bool {
        lhs.task == rhs.task && lhs.assignee == rhs.assignee && lhs.dueDate == rhs.dueDate && lhs.priority == rhs.priority && lhs.timestamp == rhs.timestamp && lhs.context == rhs.context && lhs.isCompleted == rhs.isCompleted
    }
}

struct KeyPoint: Codable, Identifiable, Equatable {
    let id = UUID()
    let timestamp: String // "MM:SS"
    let point: String
    let category: String // decision, discussion, information
    let sentiment: String? // positive, neutral, negative

    enum CodingKeys: String, CodingKey {
        case timestamp, point, category, sentiment
    }

    var emoji: String {
        switch sentiment?.lowercased() {
        case "positive":
            return "😊"
        case "negative":
            return "😔"
        default:
            return "😐"
        }
    }

    static func == (lhs: KeyPoint, rhs: KeyPoint) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.point == rhs.point && lhs.category == rhs.category && lhs.sentiment == rhs.sentiment
    }
}

struct Decision: Codable, Identifiable, Equatable {
    let id = UUID()
    let decision: String
    let timestamp: String // "MM:SS"
    let participants: [String]
    let impact: String // high, medium, low

    enum CodingKeys: String, CodingKey {
        case decision, timestamp, participants, impact
    }

    static func == (lhs: Decision, rhs: Decision) -> Bool {
        lhs.decision == rhs.decision && lhs.timestamp == rhs.timestamp && lhs.participants == rhs.participants && lhs.impact == rhs.impact
    }
}

// For API responses
struct RecordingAnalysisResponse: Codable {
    let recordingId: String
    let analysis: Recording
}

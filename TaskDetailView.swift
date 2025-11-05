import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) var dismiss
    let taskId: String
    @ObservedObject var viewModel: TaskViewModel
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastType = .success
    @State private var showConfetti = false

    // Inline editing states
    @State private var isEditingTitle = false
    @State private var isEditingDescription = false
    @State private var editedTitle = ""
    @State private var editedDescription = ""
    @FocusState private var titleFieldFocused: Bool
    @FocusState private var descriptionFieldFocused: Bool

    // Get current task from viewModel (always up-to-date)
    private var task: Task? {
        viewModel.tasks.first(where: { $0.id == taskId }) ??
        viewModel.completedTasks.first(where: { $0.id == taskId }) ??
        viewModel.overdueTasks.first(where: { $0.id == taskId })
    }

    var body: some View {
        Group {
            if let task = task {
                taskDetailContent(task: task)
            } else {
                // Task not found (deleted or error)
                VStack {
                    Text("Task not found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Button("Close") {
                        dismiss()
                    }
                    .padding(.top)
                }
            }
        }
    }

    @ViewBuilder
    private func taskDetailContent(task: Task) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color(red: 0.11, green: 0.13, blue: 0.18)

                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                            }

                            Spacer()

                            Text("Task Details")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Menu {
                                Button(role: .destructive, action: {
                                    viewModel.deleteTask(task)
                                    toastMessage = "Deleted! One less thing on your plate 🗑️"
                                    toastType = .success
                                    showToast = true

                                    // Dismiss after a short delay to show the toast
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        dismiss()
                                    }
                                }) {
                                    Label("Delete Task", systemImage: "trash")
                                }

                                Button(action: {
                                    // If completing (not uncompleting), show confetti
                                    if !task.isCompleted {
                                        showConfetti = true
                                    }

                                    viewModel.toggleTaskComplete(task)
                                    if task.isCompleted {
                                        toastMessage = "Unmarked! Back on the list 📋"
                                    } else {
                                        toastMessage = "Done! You're crushing it 🎯"
                                    }
                                    toastType = .success
                                    showToast = true

                                    // Dismiss after a short delay to show the toast
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        dismiss()
                                    }
                                }) {
                                    Label(task.isCompleted ? "Mark as Active" : "Mark as Complete",
                                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Task Title (Tap to Edit)
                        if isEditingTitle {
                            TextField("", text: $editedTitle)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .focused($titleFieldFocused)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                                .onAppear {
                                    titleFieldFocused = true
                                }
                                .onChange(of: titleFieldFocused) { focused in
                                    if !focused && !editedTitle.isEmpty && editedTitle != task.title {
                                        // Auto-save when focus lost
                                        saveTitle()
                                    }
                                    if !focused {
                                        isEditingTitle = false
                                    }
                                }
                        } else {
                            Text(task.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                                .onTapGesture {
                                    editedTitle = task.title
                                    isEditingTitle = true
                                }
                        }

                        // Hint text
                        if !isEditingTitle {
                            Text("Tap to edit")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.bottom, 16)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    // Task Info Card
                    VStack(spacing: 16) {
                        // Status & Priority
                        HStack(spacing: 12) {
                            StatusBadge(isCompleted: task.isCompleted)

                            Spacer()

                            PriorityBadge(priority: task.priority)
                        }

                        Divider()

                        // Time & Category
                        HStack(spacing: 20) {
                            InfoRow(icon: "clock.fill", title: "Time", value: task.time)

                            Divider()
                                .frame(height: 40)

                            InfoRow(icon: "tag.fill", title: "Category", value: task.category)
                        }

                        if let dueDate = task.dueDate {
                            Divider()

                            InfoRow(icon: "calendar", title: "Due Date", value: formatDate(dueDate))
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Description Card (Tap to Edit)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        if isEditingDescription {
                            TextEditor(text: $editedDescription)
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.3))
                                .focused($descriptionFieldFocused)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(white: 0.97))
                                .cornerRadius(8)
                                .onAppear {
                                    descriptionFieldFocused = true
                                }
                                .onChange(of: descriptionFieldFocused) { focused in
                                    if !focused && editedDescription != task.description {
                                        // Auto-save when focus lost
                                        saveDescription()
                                    }
                                    if !focused {
                                        isEditingDescription = false
                                    }
                                }
                        } else if !task.description.isEmpty {
                            Text(task.description)
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.3))
                                .lineSpacing(4)
                                .onTapGesture {
                                    editedDescription = task.description
                                    isEditingDescription = true
                                }
                        } else {
                            Text("Tap to add a description...")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.5))
                                .italic()
                                .onTapGesture {
                                    editedDescription = ""
                                    isEditingDescription = true
                                }
                        }

                        if !isEditingDescription {
                            Text("Tap to edit")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Reminders Card
                    if !task.reminders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Reminders", systemImage: "bell.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)

                                Spacer()

                                Text("\(task.reminders.count)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color(red: 0.4, green: 0.75, blue: 0.95))
                                    .cornerRadius(14)
                            }

                            ForEach(task.reminders) { reminder in
                                ReminderDetailRow(reminder: reminder, taskId: task.id, viewModel: viewModel)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }

                    // AI Suggestions Card
                    if !task.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("AI Suggestions", systemImage: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)

                                Spacer()

                                Text("\(task.suggestions.count)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color(red: 0.95, green: 0.75, blue: 0.25))
                                    .cornerRadius(14)
                            }

                            ForEach(task.suggestions) { suggestion in
                                TaskDetailSuggestionCard(
                                    title: suggestion.title,
                                    description: suggestion.description,
                                    type: suggestion.type
                                )
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color(white: 0.98))
        .navigationBarHidden(true)
        .toast(isShowing: $showToast, message: toastMessage, type: toastType)
        .confetti(isPresented: $showConfetti)
    }

    // MARK: - Inline Editing Functions
    private func saveTitle() {
        guard let task = task, !editedTitle.isEmpty else { return }

        // Note: This is a simplified version. In a full implementation,
        // you would call an API to update the task title
        // For now, we'll just show a toast indicating the save action
        toastMessage = "Title updated! 📝"
        toastType = .success
        showToast = true

        // TODO: Call API to update task
        // viewModel.updateTaskTitle(taskId: taskId, newTitle: editedTitle)
    }

    private func saveDescription() {
        guard let task = task else { return }

        // Note: This is a simplified version. In a full implementation,
        // you would call an API to update the task description
        toastMessage = "Description updated! 📝"
        toastType = .success
        showToast = true

        // TODO: Call API to update task
        // viewModel.updateTaskDescription(taskId: taskId, newDescription: editedDescription)
    }

    func formatDate(_ dateString: String) -> String {
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

            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
                return displayFormatter.string(from: date)
            }
        }

        return dateString
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 14))
            Text(isCompleted ? "Completed" : "Active")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isCompleted ? Color.green : Color(red: 0.4, green: 0.75, blue: 0.95))
        .cornerRadius(20)
    }
}

struct PriorityBadge: View {
    let priority: String

    var priorityColor: Color {
        switch priority.lowercased() {
        case "high", "urgent":
            return Color.red
        case "medium":
            return Color.orange
        case "low":
            return Color.green
        default:
            return Color.gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.fill")
                .font(.system(size: 14))
            Text(priority.capitalized)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(priorityColor)
        .cornerRadius(20)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.95))

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.5))

            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReminderDetailRow: View {
    let reminder: TaskReminder
    let taskId: String
    @ObservedObject var viewModel: TaskViewModel
    @State private var showDeleteConfirmation = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showEditSheet = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(reminder.sent ? Color.green.opacity(0.15) : Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: reminder.sent ? "checkmark.circle.fill" : "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(reminder.sent ? .green : Color(red: 0.4, green: 0.75, blue: 0.95))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)

                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundColor(reminder.isUpcoming ? Color(red: 0.4, green: 0.75, blue: 0.95) : Color.orange)

                    Text(reminder.formattedReminderTime)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(reminder.isUpcoming ? Color(red: 0.4, green: 0.75, blue: 0.95) : Color.orange)

                    if !reminder.isUpcoming && !reminder.sent {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("Past Due")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }
                }

                if reminder.sent {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Sent")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()

            if !reminder.sent {
                HStack(spacing: 8) {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.95))
                            .frame(width: 36, height: 36)
                            .background(Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.1))
                            .cornerRadius(18)
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(18)
                    }
                    .confirmationDialog("Delete Reminder", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteReminder(taskId: taskId, reminderId: reminder.id)
                            toastMessage = "Reminder removed! 🔕"
                            showToast = true
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.97))
        .cornerRadius(12)
        .toast(isShowing: $showToast, message: toastMessage, type: .success)
        .sheet(isPresented: $showEditSheet) {
            EditReminderView(
                reminder: reminder,
                taskId: taskId,
                viewModel: viewModel,
                onSuccess: {
                    toastMessage = "Reminder updated! ⏰"
                    showToast = true
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
}

struct ConversationCard: View {
    let conversation: ConversationDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AI Analysis", systemImage: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)

            // Original Message
            if let originalMessage = conversation.originalMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Request")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.5))

                    Text(originalMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color(white: 0.97))
                        .cornerRadius(12)
                }
            }

            // AI Analysis
            if let analysis = conversation.analysis {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Understanding")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.5))

                    Text(analysis)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.1))
                        .cornerRadius(12)
                }
            }

            // Suggestions (using proper SuggestionCard design)
            if !conversation.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Suggestions")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.5))

                    ForEach(conversation.suggestions) { suggestion in
                        TaskDetailSuggestionCard(
                            title: suggestion.title,
                            description: suggestion.description,
                            type: suggestion.type
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Data Models

struct ConversationDetail {
    let originalMessage: String?
    let analysis: String?
    let suggestions: [Suggestion]
}

// MARK: - Task Detail Suggestion Card
struct TaskDetailSuggestionCard: View {
    let title: String
    let description: String
    let type: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Title
            HStack(spacing: 12) {
                Image(systemName: iconForType(type))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorForType(type))
                    .frame(width: 36, height: 36)
                    .background(colorForType(type).opacity(0.1))
                    .cornerRadius(8)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Spacer()
            }

            // Description
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.3))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(white: 0.97))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorForType(type).opacity(0.2), lineWidth: 1.5)
        )
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "warning":
            return "exclamationmark.triangle.fill"
        case "info", "information":
            return "info.circle.fill"
        case "additional":
            return "lightbulb.fill"
        default:
            return "lightbulb.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "warning":
            return Color(red: 0.95, green: 0.61, blue: 0.07)
        case "info", "information":
            return Color(red: 0.35, green: 0.75, blue: 0.95)
        case "additional":
            return Color(red: 0.58, green: 0.40, blue: 0.93)
        default:
            return Color(red: 0.35, green: 0.75, blue: 0.95)
        }
    }
}

// MARK: - Edit Reminder View
struct EditReminderView: View {
    @Environment(\.dismiss) var dismiss
    let reminder: TaskReminder
    let taskId: String
    @ObservedObject var viewModel: TaskViewModel
    let onSuccess: () -> Void

    @State private var reminderMessage: String
    @State private var reminderDate: Date
    @State private var recurrence: String = "none" // none, daily, weekly, monthly
    @State private var priority: String = "normal" // low, normal, high
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Collapsible sections
    @State private var showQuickSelect = false
    @State private var showCalendar = false

    init(reminder: TaskReminder, taskId: String, viewModel: TaskViewModel, onSuccess: @escaping () -> Void) {
        self.reminder = reminder
        self.taskId = taskId
        self.viewModel = viewModel
        self.onSuccess = onSuccess

        // Initialize state with current reminder values
        _reminderMessage = State(initialValue: reminder.message)

        // Parse the reminder time to a Date
        let parsedDate = Self.parseReminderTime(reminder.reminderTime) ?? Date()
        _reminderDate = State(initialValue: parsedDate)
    }

    static func parseReminderTime(_ timeString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "UTC")

            if let date = formatter.date(from: timeString) {
                return date
            }
        }

        return nil
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header (mavi)
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.95),
                            Color(red: 0.45, green: 0.65, blue: 0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Text("Edit Reminder")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Balance için boş view
                        Color.clear.frame(width: 18)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 60)

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Hızlı Seç (Collapsible)
                        VStack(spacing: 0) {
                            Button(action: { withAnimation { showQuickSelect.toggle() } }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                    Text("Quick Select")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(showQuickSelect ? 16 : 16, corners: showQuickSelect ? [.topLeft, .topRight] : .allCorners)
                            }

                            if showQuickSelect {
                                VStack(spacing: 0) {
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                        QuickSelectButton(icon: "⚡", title: "15 min later", action: { setQuickTime(minutes: 15) })
                                        QuickSelectButton(icon: "⏰", title: "1 hour later", action: { setQuickTime(hours: 1) })
                                        QuickSelectButton(icon: "🏙️", title: "Evening 6 PM", action: { setQuickTime(hour: 18) })
                                        QuickSelectButton(icon: "☀️", title: "Tomorrow 9 AM", action: { setQuickTime(hour: 9, tomorrow: true) })
                                    }
                                    .padding(16)
                                }
                                .background(Color.white)
                                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                            }
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // 2. Mesaj
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                Text("Message")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }

                            TextField("Complete the application form", text: $reminderMessage)
                                .font(.system(size: 16))
                                .padding(16)
                                .background(Color(white: 0.97))
                                .cornerRadius(12)

                            HStack {
                                Spacer()
                                Text("\(reminderMessage.count)/500")
                                    .font(.system(size: 12))
                                    .foregroundColor(reminderMessage.count > 500 ? .red : Color(white: 0.5))
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        // 3. Tarih & Saat (Collapsible)
                        VStack(spacing: 0) {
                            Button(action: { withAnimation { showCalendar.toggle() } }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                        Text("Date & Time")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                        Spacer()
                                    }
                                    .padding(16)

                                    // Seçilen zaman önizlemesi (border ile)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Selected Time")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(white: 0.5))
                                            Text(formattedDateTime)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.black)
                                        }
                                        Spacer()
                                        Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                                            .foregroundColor(Color(white: 0.5))
                                    }
                                    .padding(16)
                                    .background(Color(white: 0.97))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(red: 0.95, green: 0.75, blue: 0.25), lineWidth: 2)
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                                }
                                .background(Color.white)
                                .cornerRadius(showCalendar ? 16 : 16, corners: showCalendar ? [.topLeft, .topRight] : .allCorners)
                            }

                            if showCalendar {
                                VStack(spacing: 16) {
                                    DatePicker("", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.graphical)
                                        .accentColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                        .padding(.horizontal, 16)
                                }
                                .padding(.bottom, 16)
                                .background(Color.white)
                                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                            }
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        // 4. Tekrar
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "repeat")
                                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                Text("Recurrence")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }

                            HStack(spacing: 12) {
                                RecurrenceButton(title: "None", isSelected: recurrence == "none") { recurrence = "none" }
                                RecurrenceButton(title: "Daily", isSelected: recurrence == "daily") { recurrence = "daily" }
                                RecurrenceButton(title: "Weekly", isSelected: recurrence == "weekly") { recurrence = "weekly" }
                                RecurrenceButton(title: "Monthly", isSelected: recurrence == "monthly") { recurrence = "monthly" }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        // 5. Öncelik
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                Text("Priority")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }

                            HStack(spacing: 12) {
                                PriorityButton(title: "Low", isSelected: priority == "low") { priority = "low" }
                                PriorityButton(title: "Normal", isSelected: priority == "normal") { priority = "normal" }
                                PriorityButton(title: "High", isSelected: priority == "high") { priority = "high" }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 20)

                        // 6. Kaydet Butonu
                        Button(action: { updateReminder() }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save Changes")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.35, green: 0.75, blue: 0.95),
                                        Color(red: 0.45, green: 0.65, blue: 0.95)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(reminderMessage.isEmpty || reminderMessage.count > 500 || isLoading)
                        .opacity((reminderMessage.isEmpty || reminderMessage.count > 500 || isLoading) ? 0.5 : 1.0)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // 7. Sil Butonu
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Reminder")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showError) {
            ErrorView(
                title: "Error",
                message: errorMessage,
                primaryButtonTitle: "OK",
                secondaryButtonTitle: nil,
                onPrimaryAction: {}
            )
            .background(ClearBackgroundViewForTaskDetail())
        }
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, d MMMM HH:mm"
        return formatter.string(from: reminderDate)
    }

    private func setQuickTime(minutes: Int? = nil, hours: Int? = nil, hour: Int? = nil, tomorrow: Bool = false) {
        var date = Date()

        if let mins = minutes {
            date = date.addingTimeInterval(TimeInterval(mins * 60))
        } else if let hrs = hours {
            date = date.addingTimeInterval(TimeInterval(hrs * 3600))
        } else if let hr = hour {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            if tomorrow {
                components.day! += 1
            }
            components.hour = hr
            components.minute = 0
            date = Calendar.current.date(from: components) ?? Date()
        }

        withAnimation {
            reminderDate = date
            showQuickSelect = false
        }
    }

    private func updateReminder() {
        isLoading = true

        _Concurrency.Task {
            do {
                // Format the date for API
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.timeZone = TimeZone.current
                let reminderTimeString = formatter.string(from: reminderDate)

                try await BraindumpsterAPI.shared.updateReminder(
                    taskId: taskId,
                    reminderId: reminder.id,
                    reminderTime: reminderTimeString,
                    message: reminderMessage,
                    recurrence: recurrence,
                    priority: priority
                )

                await MainActor.run {
                    isLoading = false
                    dismiss()
                    onSuccess()

                    // Refresh tasks to get updated reminder
                    viewModel.fetchTasks()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    TaskDetailView(
        taskId: "1",
        viewModel: TaskViewModel()
    )
}

// MARK: - Helper Components for EditReminderView

// QuickSelectButton
struct QuickSelectButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 28))
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(white: 0.97))
            .cornerRadius(12)
        }
    }
}

// RecurrenceButton
struct RecurrenceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color(red: 0.45, green: 0.75, blue: 1.0) : .black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color(red: 0.45, green: 0.75, blue: 1.0).opacity(0.15) : Color(white: 0.97))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color(red: 0.45, green: 0.75, blue: 1.0) : Color.clear, lineWidth: 2)
                )
        }
    }
}

// PriorityButton
struct PriorityButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? Color(red: 0.45, green: 0.75, blue: 1.0) : .black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color(red: 0.45, green: 0.75, blue: 1.0).opacity(0.15) : Color(white: 0.97))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color(red: 0.45, green: 0.75, blue: 1.0) : Color.clear, lineWidth: 2)
                )
        }
    }
}

// RoundedCorner extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Helper to make fullScreenCover background transparent
struct ClearBackgroundViewForTaskDetail: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

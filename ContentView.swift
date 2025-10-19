import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @StateObject private var streakManager = StreakManager.shared
    @State private var showVoiceInput = false
    @State private var showChat = false
    @State private var showSettings = false
    @State private var showCalendarDetail = false
    @State private var selectedCalendarDate: Int = 0
    @State private var expandedTaskIds: Set<String> = []
    @State private var selectedTask: Task?
    @State private var showConfetti = false
    @State private var showSnoozeSheet = false
    @State private var taskToSnooze: Task?
    @State private var showUndoToast = false
    @State private var deletedTask: Task?
    @State private var undoWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HeaderView(showSettings: $showSettings)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        // Daily Progress Card
                        DailyProgressCard(completed: viewModel.dailyProgress.completed, total: viewModel.dailyProgress.total)
                            .padding(.horizontal, 18)
                            .padding(.top, 16)

                        // Streak Card
                        StreakCardView()
                            .padding(.horizontal, 18)

                        // AI Assistant Card
                        AIAssistantCard()
                            .padding(.horizontal, 18)

                        // Calendar Widget
                        CalendarWidget(
                            onDateSelected: { date in
                                selectedCalendarDate = date
                                showCalendarDetail = true
                            },
                            onViewAll: {
                                // Don't set a specific date, let CalendarDetailView use today
                                showCalendarDetail = true
                            },
                            viewModel: viewModel
                        )
                        .padding(.horizontal, 18)

                        // Active Tasks
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Active Tasks")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)

                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            } else if viewModel.tasks.isEmpty {
                                Text("No tasks yet — that's either peace or procrastination 😅")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.5))
                                    .multilineTextAlignment(.center)
                                    .padding()
                            } else {
                                List {
                                    ForEach(viewModel.tasks) { task in
                                        TaskCardView(
                                            task: task,
                                            viewModel: viewModel,
                                            isExpanded: Binding(
                                                get: { expandedTaskIds.contains(task.id) },
                                                set: { isExpanded in
                                                    if isExpanded {
                                                        expandedTaskIds.insert(task.id)
                                                    } else {
                                                        expandedTaskIds.remove(task.id)
                                                    }
                                                }
                                            ),
                                            onTap: {
                                                selectedTask = task
                                            },
                                            onComplete: {
                                                showConfetti = true
                                            }
                                        )
                                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                HapticFeedback.light()
                                                taskToSnooze = task
                                                showSnoozeSheet = true
                                            } label: {
                                                Label("Snooze", systemImage: "clock.fill")
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                handleTaskDeletion(task)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(height: calculateTaskListHeight(tasks: viewModel.tasks, expandedTaskIds: expandedTaskIds))
                                .padding(.horizontal, 18)
                            }
                        }
                        .padding(.top, 4)

                        // Overdue Tasks
                        if !viewModel.overdueTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)

                                    Text("Overdue Tasks")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.red)

                                    Spacer()

                                    Text("\(viewModel.overdueTasks.count)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.red)
                                        .cornerRadius(14)
                                }
                                .padding(.horizontal, 18)

                                List {
                                    ForEach(viewModel.overdueTasks) { task in
                                        TaskCardView(
                                            task: task,
                                            viewModel: viewModel,
                                            isExpanded: Binding(
                                                get: { expandedTaskIds.contains(task.id) },
                                                set: { isExpanded in
                                                    if isExpanded {
                                                        expandedTaskIds.insert(task.id)
                                                    } else {
                                                        expandedTaskIds.remove(task.id)
                                                    }
                                                }
                                            ),
                                            onTap: {
                                                selectedTask = task
                                            },
                                            onComplete: {
                                                showConfetti = true
                                            }
                                        )
                                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                HapticFeedback.light()
                                                taskToSnooze = task
                                                showSnoozeSheet = true
                                            } label: {
                                                Label("Snooze", systemImage: "clock.fill")
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                handleTaskDeletion(task)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(height: calculateTaskListHeight(tasks: viewModel.overdueTasks, expandedTaskIds: expandedTaskIds))
                                .padding(.horizontal, 18)
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.red.opacity(0.05))
                            )
                            .padding(.horizontal, 18)
                        }

                        // Completed Tasks
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Completed")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(white: 0.55))
                                .padding(.horizontal, 18)

                            if !viewModel.completedTasks.isEmpty {
                                List {
                                    ForEach(viewModel.completedTasks) { task in
                                        CompletedTaskCard(task: task, viewModel: viewModel)
                                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    handleTaskDeletion(task)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                                Button {
                                                    HapticFeedback.medium()
                                                    withAnimation {
                                                        viewModel.toggleTaskComplete(task)
                                                    }
                                                } label: {
                                                    Label("Undo", systemImage: "arrow.uturn.backward")
                                                }
                                                .tint(.orange)
                                            }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(height: CGFloat(viewModel.completedTasks.count) * 70)
                                .padding(.horizontal, 18)
                            }
                        }
                        .padding(.top, 4)

                        Spacer(minLength: 140)
                    }
                    .refreshable {
                        await refreshTasks()
                    }
                }

                Spacer()
            }

            // Bottom Action Buttons
            VStack {
                Spacer()
                BottomActionButtons(showVoiceInput: $showVoiceInput, showChat: $showChat)
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showVoiceInput, onDismiss: {
            // Refresh tasks when voice input is dismissed
            viewModel.fetchTasks()
        }) {
            VoiceInputView()
        }
        .sheet(isPresented: $showChat, onDismiss: {
            // Refresh tasks when chat is dismissed
            viewModel.fetchTasks()
        }) {
            ChatView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCalendarDetail) {
            // Pass selected date if coming from calendar widget, nil for "View All"
            if selectedCalendarDate > 0 {
                CalendarDetailView(viewModel: viewModel, selectedDate: selectedCalendarDate)
            } else {
                CalendarDetailView(viewModel: viewModel)
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(taskId: task.id, viewModel: viewModel)
        }
        .sheet(isPresented: $showSnoozeSheet) {
            if let task = taskToSnooze {
                SnoozeOptionsView(task: task, viewModel: viewModel)
            }
        }
        .overlay {
            if streakManager.showMilestone, let milestone = streakManager.milestoneReached {
                MilestoneCelebrationView(
                    isPresented: $streakManager.showMilestone,
                    milestone: milestone
                )
            }
        }
        .confetti(isPresented: $showConfetti)
        .overlay(alignment: .bottom) {
            if showUndoToast, let task = deletedTask {
                UndoToastView(taskTitle: task.title, onUndo: undoDelete)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showUndoToast)
            }
        }
    }

    // MARK: - Refresh Tasks
    private func refreshTasks() async {
        await withCheckedContinuation { continuation in
            viewModel.fetchTasks()
            // Small delay to ensure smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }

    // MARK: - Undo Delete
    private func handleTaskDeletion(_ task: Task) {
        // Cancel any existing undo work item
        undoWorkItem?.cancel()

        // Store the deleted task
        deletedTask = task

        // Remove from UI immediately with animation
        withAnimation {
            viewModel.tasks.removeAll { $0.id == task.id }
            viewModel.overdueTasks.removeAll { $0.id == task.id }
            viewModel.completedTasks.removeAll { $0.id == task.id }
        }

        // Show undo toast
        showUndoToast = true

        // Create a new work item that will perform the actual deletion
        let workItem = DispatchWorkItem { [weak viewModel] in
            if let task = self.deletedTask {
                viewModel?.deleteTask(task)
            }
            self.showUndoToast = false
            self.deletedTask = nil
        }

        undoWorkItem = workItem

        // Execute after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)

        HapticFeedback.light()
    }

    private func undoDelete() {
        // Cancel the pending deletion
        undoWorkItem?.cancel()

        // Restore the task
        if let task = deletedTask {
            withAnimation {
                if task.isCompleted {
                    viewModel.completedTasks.append(task)
                } else if viewModel.isTaskOverdue(task) {
                    viewModel.overdueTasks.append(task)
                } else {
                    viewModel.tasks.append(task)
                }
            }
        }

        // Hide toast
        showUndoToast = false
        deletedTask = nil

        HapticFeedback.success()
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var showSettings: Bool
    @StateObject private var authService = AuthService.shared

    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, EEEE"
        return formatter.string(from: Date())
    }

    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = authService.user?.displayName?.components(separatedBy: " ").first ?? "there"

        switch hour {
        case 5..<12:
            return "Good morning, \(name) ☀️"
        case 12..<17:
            return "Good afternoon, \(name) 👋"
        case 17..<21:
            return "Good evening, \(name) 🌆"
        default:
            return "Still up, \(name)? 🌙"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeBasedGreeting)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                Text(currentDateString)
                    .font(.system(size: 16))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(Color(white: 0.4))
                        .frame(width: 48, height: 48)
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .accessibleButton(
                    label: AccessibilityLabels.settingsButton,
                    hint: AccessibilityHints.openSettings
                )

                Button(action: {}) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                        .frame(width: 48, height: 48)
                        .background(Color(red: 0.17, green: 0.19, blue: 0.26))
                        .cornerRadius(14)
                }
            }
        }
    }
}

// MARK: - Daily Progress Card
struct DailyProgressCard: View {
    let completed: Int
    let total: Int

    var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }

    var motivationalMessage: String {
        let percentage = Int(progress * 100)

        switch percentage {
        case 0:
            return "Let's do this! 💪"
        case 1..<50:
            return "Getting there... 🎯"
        case 50..<80:
            return "Crushing it! 🔥"
        case 80..<100:
            return "Almost done! 🚀"
        default:
            return "All done! Time to chill 😎"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Daily Progress")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                Spacer()

                Text("\(completed)/\(total)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.9))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.35, green: 0.75, blue: 0.95),
                                    Color(red: 0.45, green: 0.55, blue: 0.95)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            // Motivational message
            Text(motivationalMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(white: 0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(18)
    }
}

// MARK: - AI Assistant Card
struct AIAssistantCard: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                .frame(width: 64, height: 64)
                .background(Color(red: 0.2, green: 0.25, blue: 0.32))
                .cornerRadius(18)

            Text("AI Assistant Ready")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("Tell me your tasks by voice or text, I'll handle them")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
        .cornerRadius(22)
    }
}

// MARK: - Task Card View
struct TaskCardView: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isExpanded: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    var priorityColor: Color {
        switch task.priority.lowercased() {
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
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 14) {
                // Checkbox button
                Button(action: {
                    HapticFeedback.success()
                    onComplete()
                    withAnimation {
                        viewModel.toggleTaskComplete(task)
                    }
                }) {
                    Circle()
                        .stroke(Color(white: 0.75), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())

                // Task details button
                Button(action: {
                    onTap()
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)

                        HStack(spacing: 10) {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 13))
                                Text(task.time)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(Color(white: 0.5))

                            Text(task.category)
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))

                            HStack(spacing: 3) {
                                Image(systemName: "bell")
                                    .font(.system(size: 13))
                                Text("\(task.notificationCount)")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))

                            // Priority indicator
                            Text(task.priority.capitalized)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(priorityColor)
                                .cornerRadius(6)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            // Expanded reminders section
            if isExpanded && !task.reminders.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        ForEach(task.reminders) { reminder in
                            SwipeableReminderRow(
                                reminder: reminder,
                                taskId: task.id,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Swipeable Reminder Row (for nested contexts)
struct SwipeableReminderRow: View {
    let reminder: TaskReminder
    let taskId: String
    @ObservedObject var viewModel: TaskViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        ReminderRowView(reminder: reminder)
            .contextMenu {
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Delete Reminder", systemImage: "trash")
                }
            }
            .confirmationDialog("Delete Reminder", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        viewModel.deleteReminder(taskId: taskId, reminderId: reminder.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this reminder?")
            }
    }
}

// MARK: - Reminder Row View
struct ReminderRowView: View {
    let reminder: TaskReminder

    var body: some View {
        HStack(spacing: 12) {
            // Bell icon with status
            ZStack {
                Circle()
                    .fill(reminder.sent ? Color.green.opacity(0.1) : Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: reminder.sent ? "checkmark.circle.fill" : "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(reminder.sent ? .green : Color(red: 0.4, green: 0.75, blue: 0.95))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11))
                    Text(reminder.formattedReminderTime)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(reminder.isUpcoming ? Color(red: 0.4, green: 0.75, blue: 0.95) : Color.orange)
            }

            Spacer()

            if reminder.sent {
                Text("Sent")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
            } else {
                Text("Pending")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reminder.isUpcoming ? Color(red: 0.4, green: 0.75, blue: 0.95) : Color.orange)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(white: 0.97))
        .cornerRadius(12)
    }
}

// MARK: - Completed Task Card
struct CompletedTaskCard: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox with undo functionality
            Button(action: {
                HapticFeedback.medium()
                withAnimation {
                    viewModel.toggleTaskComplete(task)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.3, green: 0.85, blue: 0.4))
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Text(task.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(white: 0.55))
                .strikethrough(true, color: Color(white: 0.55))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Calendar Widget
struct CalendarWidget: View {
    let onDateSelected: (Int) -> Void
    let onViewAll: () -> Void
    @ObservedObject var viewModel: TaskViewModel

    var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    // Calculate days with tasks dynamically (only active tasks, not completed)
    var daysWithTasks: Set<Int> {
        var days = Set<Int>()
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.year, .month], from: now)

        // Only show active tasks (not completed) in calendar
        for task in viewModel.tasks {
            // Add task due date
            if let dueDate = task.dueDate {
                if let date = parseDateString(dueDate) {
                    let taskComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    if taskComponents.year == currentComponents.year &&
                       taskComponents.month == currentComponents.month {
                        days.insert(taskComponents.day!)
                    }
                }
            }

            // Also add reminder dates
            for reminder in task.reminders {
                if let reminderDate = parseDateString(reminder.reminderTime) {
                    let reminderComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
                    if reminderComponents.year == currentComponents.year &&
                       reminderComponents.month == currentComponents.month {
                        days.insert(reminderComponents.day!)
                    }
                }
            }
        }
        return days
    }

    // Current selected day (today)
    var selectedDay: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now)
        return components.day ?? 1
    }

    // Calculate calendar days dynamically
    var calendarDays: [[Int?]] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)

        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let daysCount = range.count
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        // Adjust to Monday=0, Sunday=6
        let startDay = (firstWeekday + 5) % 7

        var days: [[Int?]] = []
        var week: [Int?] = Array(repeating: nil, count: startDay)

        for day in 1...daysCount {
            week.append(day)
            if week.count == 7 {
                days.append(week)
                week = []
            }
        }

        if !week.isEmpty {
            while week.count < 7 {
                week.append(nil)
            }
            days.append(week)
        }

        return days
    }

    let dayAbbreviations = ["M", "T", "W", "T", "F", "S", "S"]

    func parseDateString(_ dateString: String) -> Date? {
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
                return date
            }
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)

                Spacer()

                Button(action: {
                    onViewAll()
                }) {
                    Text("View All")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.35, green: 0.7, blue: 0.95))
                }
            }

            // Calendar Card
            VStack(spacing: 16) {
                // Month/Year Header
                HStack {
                    Text("\(currentMonth) \(currentYear)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.95))
                }

                // Day Headers
                HStack(spacing: 0) {
                    ForEach(Array(dayAbbreviations.enumerated()), id: \.offset) { index, day in
                        Text(day)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar Grid
                VStack(spacing: 8) {
                    ForEach(0..<calendarDays.count, id: \.self) { weekIndex in
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                if let day = calendarDays[weekIndex][dayIndex] {
                                    Button(action: {
                                        onDateSelected(day)
                                    }) {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                if day == selectedDay {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [
                                                                    Color(red: 0.35, green: 0.75, blue: 0.95),
                                                                    Color(red: 0.45, green: 0.65, blue: 0.95)
                                                                ]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 44, height: 44)
                                                } else if daysWithTasks.contains(day) {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(white: 0.95))
                                                        .frame(width: 44, height: 44)
                                                }

                                                Text("\(day)")
                                                    .font(.system(size: 16, weight: day == selectedDay ? .semibold : .regular))
                                                    .foregroundColor(day == selectedDay ? .white : .black)
                                            }

                                            // Blue dot for days with tasks
                                            if daysWithTasks.contains(day) {
                                                Circle()
                                                    .fill(Color(red: 0.4, green: 0.75, blue: 0.95))
                                                    .frame(width: 4, height: 4)
                                            } else {
                                                Circle()
                                                    .fill(Color.clear)
                                                    .frame(width: 4, height: 4)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    VStack(spacing: 4) {
                                        Text("")
                                            .frame(width: 44, height: 44)
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 4, height: 4)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(18)
        }
    }
}

// MARK: - Bottom Action Buttons
struct BottomActionButtons: View {
    @Binding var showVoiceInput: Bool
    @Binding var showChat: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Button(action: {
                    showVoiceInput = true
                }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                        .frame(width: 62, height: 62)
                        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                        .cornerRadius(18)
                }
                .accessibleButton(
                    label: AccessibilityLabels.voiceInputButton,
                    hint: AccessibilityHints.voiceInput
                )

                Button(action: {
                    showChat = true
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .frame(width: 62, height: 62)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.65, blue: 0.95),
                                    Color(red: 0.45, green: 0.55, blue: 0.95)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                }
                .accessibleButton(
                    label: AccessibilityLabels.chatButton,
                    hint: AccessibilityHints.chatAssistant
                )
            }

            Text("Add task by voice or text")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.5))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Helper Functions
func calculateTaskListHeight(tasks: [Task], expandedTaskIds: Set<String>) -> CGFloat {
    var totalHeight: CGFloat = 0

    for task in tasks {
        // Base task card height
        totalHeight += 90

        // If task is expanded and has reminders, add their height
        if expandedTaskIds.contains(task.id) && !task.reminders.isEmpty {
            // Add divider height
            totalHeight += 1

            // Add reminders VStack height (each reminder ~70px + 8px spacing)
            totalHeight += CGFloat(task.reminders.count) * 78

            // Add vertical padding
            totalHeight += 16
        }

        // Add spacing between cards
        totalHeight += 10
    }

    return totalHeight
}

// MARK: - Undo Toast View
struct UndoToastView: View {
    let taskTitle: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)

            Text("Deleted: \(taskTitle)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button(action: onUndo) {
                Text("UNDO")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color(red: 0.17, green: 0.19, blue: 0.26))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ContentView()
}

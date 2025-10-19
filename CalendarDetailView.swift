import SwiftUI

struct CalendarDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TaskViewModel
    @State private var selectedDate: Int
    @State private var currentMonthIndex = 9 // October = 9 (0-indexed)
    @State private var currentYear = 2025
    @State private var expandedTaskIds: Set<String> = []
    @State private var showVoiceInput = false
    @State private var showChat = false
    @State private var selectedTask: Task?

    // Computed properties for dynamic data
    var daysWithTasks: Set<Int> {
        var days = Set<Int>()
        let calendar = Calendar.current

        // Only show active tasks (not completed) in calendar
        for task in viewModel.tasks {
            // Add task due date
            if let dueDate = task.dueDate {
                if let date = parseDateString(dueDate) {
                    // Check if task is in the current month/year
                    let components = calendar.dateComponents([.year, .month, .day], from: date)
                    if components.month == currentMonthIndex + 1 && components.year == currentYear {
                        days.insert(components.day!)
                    }
                }
            }

            // Also add reminder dates
            for reminder in task.reminders {
                if let reminderDate = parseDateString(reminder.reminderTime) {
                    let reminderComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
                    if reminderComponents.month == currentMonthIndex + 1 && reminderComponents.year == currentYear {
                        days.insert(reminderComponents.day!)
                    }
                }
            }
        }
        return days
    }

    // Task density heatmap: returns task count per day
    var taskDensityByDay: [Int: Int] {
        var densityMap: [Int: Int] = [:]
        let calendar = Calendar.current

        // Only count active tasks (not completed)
        for task in viewModel.tasks {
            // Count task due date
            if let dueDate = task.dueDate {
                if let date = parseDateString(dueDate) {
                    let components = calendar.dateComponents([.year, .month, .day], from: date)
                    if components.month == currentMonthIndex + 1 && components.year == currentYear {
                        let day = components.day!
                        densityMap[day, default: 0] += 1
                    }
                }
            }

            // Count reminder dates
            for reminder in task.reminders {
                if let reminderDate = parseDateString(reminder.reminderTime) {
                    let reminderComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
                    if reminderComponents.month == currentMonthIndex + 1 && reminderComponents.year == currentYear {
                        let day = reminderComponents.day!
                        densityMap[day, default: 0] += 1
                    }
                }
            }
        }
        return densityMap
    }

    // Get heatmap color based on task count
    func heatmapColor(for day: Int) -> Color {
        guard let taskCount = taskDensityByDay[day] else {
            return Color.clear
        }

        switch taskCount {
        case 1...2:
            return Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.3) // Light blue
        case 3...4:
            return Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.6) // Medium blue
        default:
            return Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.9) // Dark blue
        }
    }

    var today: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now)
        return components.day ?? 1
    }

    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        return components.month == currentMonthIndex + 1 && components.year == currentYear
    }

    let dayAbbreviations = ["M", "T", "W", "T", "F", "S", "S"]

    let monthNames = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]

    let daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    // Starting day of week for each month in 2025 (0=Monday, 6=Sunday)
    let monthStartDays = [2, 5, 5, 1, 3, 6, 1, 4, 0, 2, 5, 0] // 2025 calendar

    var currentMonth: String {
        monthNames[currentMonthIndex]
    }

    var calendarDays: [[Int?]] {
        let daysCount = daysInMonth[currentMonthIndex]
        let startDay = monthStartDays[currentMonthIndex]

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

    init(viewModel: TaskViewModel, selectedDate: Int? = nil) {
        self.viewModel = viewModel

        // Initialize with current date if not provided
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)

        _currentYear = State(initialValue: components.year ?? 2025)
        _currentMonthIndex = State(initialValue: (components.month ?? 10) - 1) // 0-indexed
        _selectedDate = State(initialValue: selectedDate ?? components.day ?? 1)
    }

    var dayName: String {
        // Simple day name calculation for display
        let dayOfWeek = (monthStartDays[currentMonthIndex] + selectedDate - 1) % 7
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return dayNames[dayOfWeek]
    }

    func previousMonth() {
        if currentMonthIndex > 0 {
            currentMonthIndex -= 1
        } else {
            currentMonthIndex = 11
            currentYear -= 1
        }
        // Reset selected date to 1st of new month
        selectedDate = 1
    }

    func nextMonth() {
        if currentMonthIndex < 11 {
            currentMonthIndex += 1
        } else {
            currentMonthIndex = 0
            currentYear += 1
        }
        // Reset selected date to 1st of new month
        selectedDate = 1
    }

    var tasksForSelectedDate: [Task] {
        // Filter only active tasks for the selected date (not completed)
        // Include tasks where either the due date OR any reminder matches the selected date
        return viewModel.tasks.filter { task in
            let calendar = Calendar.current

            // Check if task's due date matches
            if let dueDate = task.dueDate,
               let date = parseDateString(dueDate) {
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                if components.year == currentYear &&
                   components.month == currentMonthIndex + 1 &&
                   components.day == selectedDate {
                    return true
                }
            }

            // Check if any reminder date matches
            for reminder in task.reminders {
                if let reminderDate = parseDateString(reminder.reminderTime) {
                    let reminderComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
                    if reminderComponents.year == currentYear &&
                       reminderComponents.month == currentMonthIndex + 1 &&
                       reminderComponents.day == selectedDate {
                        return true
                    }
                }
            }

            return false
        }
    }

    // Helper function to parse date strings
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
            formatter.timeZone = TimeZone(identifier: "UTC")

            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(white: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color(white: 0.96))
                            .cornerRadius(12)
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Text("Calendar Detail")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                    Button(action: {
                        // Go to today's date
                        let calendar = Calendar.current
                        let now = Date()
                        let components = calendar.dateComponents([.year, .month, .day], from: now)
                        currentYear = components.year ?? 2025
                        currentMonthIndex = (components.month ?? 10) - 1 // 0-indexed
                        selectedDate = components.day ?? 1
                    }) {
                        Text("Today")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.35, green: 0.75, blue: 0.95))
                            .cornerRadius(12)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 20) {
                        // Calendar Widget
                        VStack(spacing: 16) {
                            // Month Navigation
                            HStack {
                                Button(action: {
                                    previousMonth()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(Color(white: 0.96))
                                        .cornerRadius(12)
                                }

                                Spacer()

                                Text("\(currentMonth) \(String(currentYear))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)

                                Spacer()

                                Button(action: {
                                    nextMonth()
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: 44, height: 44)
                                        .background(Color(white: 0.96))
                                        .cornerRadius(12)
                                }
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
                            VStack(spacing: 12) {
                                ForEach(0..<calendarDays.count, id: \.self) { weekIndex in
                                    HStack(spacing: 0) {
                                        ForEach(0..<7, id: \.self) { dayIndex in
                                            if let day = calendarDays[weekIndex][dayIndex] {
                                                Button(action: {
                                                    selectedDate = day
                                                }) {
                                                    VStack(spacing: 4) {
                                                        ZStack {
                                                            if day == selectedDate {
                                                                RoundedRectangle(cornerRadius: 14)
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
                                                                    .frame(width: 48, height: 48)
                                                                    .overlay(
                                                                        RoundedRectangle(cornerRadius: 14)
                                                                            .stroke(Color.orange, lineWidth: 3)
                                                                    )
                                                            } else if day == today && isCurrentMonth {
                                                                RoundedRectangle(cornerRadius: 14)
                                                                    .stroke(Color(red: 0.45, green: 0.8, blue: 0.95), lineWidth: 2)
                                                                    .frame(width: 48, height: 48)
                                                            } else if daysWithTasks.contains(day) {
                                                                RoundedRectangle(cornerRadius: 14)
                                                                    .fill(heatmapColor(for: day))
                                                                    .frame(width: 48, height: 48)
                                                            }

                                                            Text("\(day)")
                                                                .font(.system(size: 17, weight: day == selectedDate ? .bold : .regular))
                                                                .foregroundColor(day == selectedDate ? .white : .black)
                                                        }

                                                        // Blue dot for days with tasks
                                                        if daysWithTasks.contains(day) && day != selectedDate {
                                                            Circle()
                                                                .fill(Color(red: 0.4, green: 0.75, blue: 0.95))
                                                                .frame(width: 5, height: 5)
                                                        } else {
                                                            Circle()
                                                                .fill(Color.clear)
                                                                .frame(width: 5, height: 5)
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            } else {
                                                VStack(spacing: 4) {
                                                    Text("")
                                                        .frame(width: 48, height: 48)
                                                    Circle()
                                                        .fill(Color.clear)
                                                        .frame(width: 5, height: 5)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Selected Date Card
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.45, green: 0.8, blue: 0.95))

                                Text("\(selectedDate)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(currentMonth) \(currentYear)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(dayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            .padding(.leading, 4)

                            Spacer()

                            Text("\(tasksForSelectedDate.count) task")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.45, green: 0.8, blue: 0.95))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.2, green: 0.3, blue: 0.35))
                                .cornerRadius(20)
                        }
                        .padding(20)
                        .background(Color(red: 0.11, green: 0.13, blue: 0.18))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)

                        // Tasks Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Tasks")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)

                                Spacer()

                                Menu {
                                    Button(action: {
                                        showVoiceInput = true
                                    }) {
                                        Label("Voice Input", systemImage: "mic.fill")
                                    }

                                    Button(action: {
                                        showChat = true
                                    }) {
                                        Label("Text Input", systemImage: "message.fill")
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 15, weight: .semibold))
                                        Text("New")
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
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
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 20)

                            // Task Cards
                            if tasksForSelectedDate.isEmpty {
                                Text("Free day! Time for a walk? 🌳")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(white: 0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(tasksForSelectedDate) { task in
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
                                                // Task completed - nothing additional needed here
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
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
        .sheet(item: $selectedTask) { task in
            TaskDetailView(taskId: task.id, viewModel: viewModel)
        }
        .onAppear {
            // Refresh tasks when calendar view appears
            viewModel.fetchTasks()
        }
    }
}

#Preview {
    CalendarDetailView(viewModel: TaskViewModel(), selectedDate: 15)
}

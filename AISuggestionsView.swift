import SwiftUI

struct AISuggestionsView: View {
    @Environment(\.dismiss) var dismiss
    let apiResponse: AudioMessageResponse
    var onAllTasksAccepted: (() -> Void)? = nil

    @State private var showSuccessToast = false
    @State private var showCompletionToast = false
    @State private var acceptedTaskTitle = ""
    @State private var acceptedTasksCount = 0
    @State private var suggestedTasks: [TaskSuggestion]
    @State private var showConfetti = false

    init(apiResponse: AudioMessageResponse, onAllTasksAccepted: (() -> Void)? = nil) {
        self.apiResponse = apiResponse
        self.onAllTasksAccepted = onAllTasksAccepted
        _suggestedTasks = State(initialValue: apiResponse.tasks)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Here's what I caught")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        +
                        Text("\nfrom your voice note 👇")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    // Accept All Button (top-right)
                    if !suggestedTasks.isEmpty {
                        Button(action: {
                            HapticFeedback.success()
                            showConfetti = true

                            // Create all tasks via API
                            createTasksViaAPI(suggestedTasks)

                            // Accept all tasks
                            acceptedTasksCount = suggestedTasks.count
                            showAllTasksCompleted()
                        }) {
                            Text("Accept All ✓")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)

                // Suggested Tasks
                if suggestedTasks.isEmpty {
                    // No tasks found
                    VStack(spacing: 20) {
                        Text("🤷")
                            .font(.system(size: 64))

                        VStack(spacing: 12) {
                            Text("Couldn't extract tasks from that")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)

                            Text("Try rephrasing or add more details like dates and times")
                                .font(.system(size: 16))
                                .foregroundColor(Color(white: 0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Show suggestions if available
                            if let suggestions = apiResponse.response?.suggestions, !suggestions.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(suggestions) { suggestion in
                                        AISuggestionCard(suggestion: suggestion)
                                    }
                                }
                            }

                            // Task cards
                            VStack(spacing: 12) {
                                ForEach(suggestedTasks) { task in
                                    APITaskCard(
                                        task: task,
                                        onAccept: { taskTitle in
                                            HapticFeedback.success()
                                            showConfetti = true

                                            // Create task via API
                                            createTasksViaAPI([task])

                                            acceptedTaskTitle = taskTitle
                                            acceptedTasksCount += 1
                                            showSuccessToast = true

                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                showSuccessToast = false

                                                // Check if all tasks are accepted
                                                if acceptedTasksCount >= suggestedTasks.count {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        showAllTasksCompleted()
                                                    }
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }

            }
            .background(Color(white: 0.98))

            // Success Toast
            VStack {
                if showSuccessToast {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)

                        Text("Task added successfully 🎯")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
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
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSuccessToast)

            // Completion Modal
            if showCompletionToast {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissAll()
                    }

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
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
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        Text("All tasks added! 🎯")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)

                        Text("Back to the grind 💪")
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.5))
                    }

                    Button(action: {
                        dismissAll()
                    }) {
                        Text("Let's go")
                            .font(.system(size: 17, weight: .semibold))
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
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showCompletionToast)
        .confetti(isPresented: $showConfetti)
    }

    func showAllTasksCompleted() {
        withAnimation {
            showCompletionToast = true
        }
    }

    // MARK: - API Integration
    func createTasksViaAPI(_ tasks: [TaskSuggestion]) {
        print("🔵 createTasksViaAPI called with \(tasks.count) tasks")

        _Concurrency.Task {
            do {
                print("🔵 About to call createTasks API")
                // Pass suggestions from API response
                let suggestions = apiResponse.response?.suggestions
                let response = try await BraindumpsterAPI.shared.createTasks(tasks: tasks, suggestions: suggestions, autoApprove: true)
                print("✅ Tasks created successfully: \(response.count) tasks created")
                print("✅ Created task IDs: \(response.tasks.map { $0.id })")
            } catch {
                print("❌ Failed to create tasks: \(error)")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error localizedDescription: \(error.localizedDescription)")
                if let apiError = error as? APIError {
                    print("❌ API Error: \(apiError)")
                }
            }
        }
    }

    func dismissAll() {
        withAnimation {
            showCompletionToast = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onAllTasksAccepted?()
            dismiss()
        }
    }
}

// MARK: - API Task Card
struct APITaskCard: View {
    let task: TaskSuggestion
    let onAccept: (String) -> Void

    @State private var isAccepted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Task Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)

                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.5))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Priority badge
                    Text(task.priority.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(priorityColor(task.priority))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(priorityColor(task.priority).opacity(0.15))
                        .cornerRadius(8)
                }

                // Date and time
                if let dueDate = task.dueDate {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))

                        Text(formatDate(dueDate))
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.5))
                    }
                }

                // Category
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon(task.category))
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))

                    Text(task.category)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.1))
                .cornerRadius(8)
            }

            // Reminders
            if !task.reminders.isEmpty {
                FlexibleView(
                    availableWidth: UIScreen.main.bounds.width - 80,
                    data: task.reminders,
                    spacing: 8,
                    alignment: .leading
                ) { reminder in
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))

                        Text(formatReminderTime(reminder.reminderTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.88, green: 0.96, blue: 1.0))
                    .cornerRadius(8)
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    // Reject task
                }) {
                    Text("Reject")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(white: 0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(white: 0.95))
                        .cornerRadius(12)
                }

                Button(action: {
                    if !isAccepted {
                        isAccepted = true
                        onAccept(task.title)
                    }
                }) {
                    HStack(spacing: 8) {
                        if isAccepted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text(isAccepted ? "Accepted" : "Accept")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isAccepted
                                ? [Color(red: 0.3, green: 0.85, blue: 0.4), Color(red: 0.2, green: 0.75, blue: 0.3)]
                                : [Color(red: 0.35, green: 0.75, blue: 0.95), Color(red: 0.45, green: 0.65, blue: 0.95)]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isAccepted)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent":
            return Color.red
        case "high":
            return Color.orange
        case "medium":
            return Color.blue
        default:
            return Color.gray
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "work":
            return "briefcase.fill"
        case "personal":
            return "person.fill"
        case "health":
            return "heart.fill"
        case "learning":
            return "book.fill"
        case "social":
            return "person.2.fill"
        default:
            return "star.fill"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        // Parse ISO date string and format it
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func formatReminderTime(_ timeString: String) -> String {
        // Parse and format reminder time
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"
            return displayFormatter.string(from: date)
        }
        return timeString
    }
}

// MARK: - Flexible View (for wrapping reminders)
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var elementsSize: [Data.Element: CGSize] = [:]

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }

    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]

            if remainingWidth - (elementSize.width + spacing) >= 0 {
                rows[currentRow].append(element)
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth
            }

            remainingWidth -= (elementSize.width + spacing)
        }

        return rows
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - AI Suggestion Card
struct AISuggestionCard: View {
    let suggestion: Suggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Title
            HStack(spacing: 12) {
                Image(systemName: iconForSuggestionType(suggestion.type))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorForSuggestionType(suggestion.type))
                    .frame(width: 36, height: 36)
                    .background(colorForSuggestionType(suggestion.type).opacity(0.1))
                    .cornerRadius(8)

                Text(suggestion.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Spacer()
            }

            // Description
            Text(suggestion.description)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.3))
                .fixedSize(horizontal: false, vertical: true)

            // Reasoning (if available)
            if let reasoning = suggestion.reasoning, !reasoning.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.06))

                    Text(reasoning)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.4))
                        .italic()
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(white: 0.97))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorForSuggestionType(suggestion.type).opacity(0.2), lineWidth: 1.5)
        )
    }

    private func iconForSuggestionType(_ type: String) -> String {
        switch type.lowercased() {
        case "warning":
            return "exclamationmark.triangle.fill"
        case "info", "information":
            return "info.circle.fill"
        case "optimization":
            return "slider.horizontal.3"
        case "alternative":
            return "arrow.triangle.branch"
        case "additional":
            return "lightbulb.fill"
        default:
            return "info.circle.fill"
        }
    }

    private func colorForSuggestionType(_ type: String) -> Color {
        switch type.lowercased() {
        case "warning":
            return Color(red: 0.95, green: 0.61, blue: 0.07)
        case "info", "information":
            return Color(red: 0.35, green: 0.75, blue: 0.95)
        case "optimization":
            return Color(red: 0.20, green: 0.78, blue: 0.35)
        case "alternative":
            return Color(red: 0.69, green: 0.32, blue: 0.87)
        case "additional":
            return Color(red: 0.58, green: 0.40, blue: 0.93)
        default:
            return Color(red: 0.35, green: 0.75, blue: 0.95)
        }
    }
}

#Preview {
    let mockResponse = AudioMessageResponse(
        conversationId: "123",
        response: AIResponse(
            success: true,
            transcription: "Yarın saat 3'te doktora gitmem lazım",
            analysis: nil,
            tasks: [],
            suggestions: nil,
            detectedLanguage: "tr"
        ),
        transcribedText: "Yarın saat 3'te doktora gitmem lazım",
        tasks: [],
        confidence: 0.9,
        audioStored: true,
        messageCount: 2
    )

    AISuggestionsView(apiResponse: mockResponse)
}

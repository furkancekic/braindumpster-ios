import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromAI: Bool
    let tasks: [TaskSuggestion]?
    let suggestions: [Suggestion]?
}

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! I'm your AI task assistant. Tell me what you need to do and I'll help you organize it! 🎯", isFromAI: true, tasks: nil, suggestions: nil)
    ]
    @State private var conversationId: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showTaskSuggestions = false
    @State private var currentTaskSuggestions: [TaskSuggestion] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Color(red: 0.11, green: 0.13, blue: 0.18)

                HStack(spacing: 16) {
                    // Close Button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                    }

                    // AI Icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(16)

                    // Title
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Assistant")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Always active")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .frame(height: 100)

            // Messages
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(messages) { message in
                        if message.isFromAI {
                            VStack(alignment: .leading, spacing: 12) {
                                AIMessageBubble(text: message.text)

                                // Show AI suggestions if available
                                if let suggestions = message.suggestions, !suggestions.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(suggestions) { suggestion in
                                            SuggestionCard(suggestion: suggestion)
                                        }
                                    }
                                }

                                // Show task suggestions if available
                                if let tasks = message.tasks, !tasks.isEmpty {
                                    TaskSuggestionsCard(tasks: tasks, onApprove: {
                                        approveAndCreateTasks(tasks, suggestions: message.suggestions)
                                    })
                                }
                            }
                        } else {
                            UserMessageBubble(text: message.text)
                        }
                    }

                    // Loading indicator
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.45, green: 0.75, blue: 1.0)))
                            Text("AI is thinking...")
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.5))
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }

            // Error message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Spacer()
                    Button("Dismiss") {
                        errorMessage = nil
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            Spacer()

            // Input Area
            HStack(spacing: 12) {
                TextField("Write your tasks...", text: $messageText)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color(white: 0.96))
                    .cornerRadius(26)
                    .disabled(isLoading)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: isLoading ? "stop.circle.fill" : "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.35, green: 0.75, blue: 0.95),
                                    Color(red: 0.45, green: 0.55, blue: 0.95)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(26)
                }
                .disabled(isLoading || messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity((isLoading || messageText.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.5 : 1.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .background(Color(white: 0.98))
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = ChatMessage(text: messageText, isFromAI: false, tasks: nil, suggestions: nil)
        messages.append(userMessage)

        let userText = messageText
        messageText = ""
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                let response = try await BraindumpsterAPI.shared.sendTextMessage(
                    message: userText,
                    conversationId: conversationId
                )

                await MainActor.run {
                    isLoading = false
                    conversationId = response.conversationId

                    // Create AI response message
                    let aiText = response.response.analysis?.userIntent ?? "I've analyzed your request and created tasks for you."
                    let tasks = response.response.tasks
                    let suggestions = response.response.suggestions

                    let aiMessage = ChatMessage(
                        text: aiText,
                        isFromAI: true,
                        tasks: tasks.isEmpty ? nil : tasks,
                        suggestions: suggestions
                    )
                    messages.append(aiMessage)

                    print("✅ Received \(tasks.count) task suggestions")
                    if let suggestions = suggestions {
                        print("✅ Received \(suggestions.count) AI suggestions")
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                    print("❌ Chat error: \(error)")
                }
            }
        }
    }

    func approveAndCreateTasks(_ tasks: [TaskSuggestion], suggestions: [Suggestion]? = nil) {
        print("🔵 approveAndCreateTasks called with \(tasks.count) tasks and \(suggestions?.count ?? 0) suggestions")
        isLoading = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                let response = try await BraindumpsterAPI.shared.createTasks(tasks: tasks, suggestions: suggestions, autoApprove: true)

                await MainActor.run {
                    isLoading = false
                    let successMessage = ChatMessage(
                        text: "✅ Successfully created \(response.count) task(s)! You can view them in your task list.",
                        isFromAI: true,
                        tasks: nil,
                        suggestions: nil
                    )
                    messages.append(successMessage)

                    print("✅ Created \(response.count) tasks")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create tasks: \(error.localizedDescription)"
                    print("❌ Task creation error: \(error)")
                }
            }
        }
    }
}

struct AIMessageBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Icon
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                .frame(width: 32, height: 32)

            // Message Bubble
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserMessageBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.95),
                            Color(red: 0.45, green: 0.55, blue: 0.95)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .frame(maxWidth: .infinity * 0.75, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Task Suggestions Card (VoiceInputView style)
struct TaskSuggestionsCard: View {
    let tasks: [TaskSuggestion]
    let onApprove: () -> Void
    @State private var acceptedTasks: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with lightbulb
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                Text("Task Suggestions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }

            // Individual task cards (like APITaskCard from VoiceInputView)
            ForEach(tasks) { task in
                ChatTaskCard(
                    task: task,
                    isAccepted: acceptedTasks.contains(task.id ?? UUID().uuidString),
                    onAccept: {
                        // Mark as accepted
                        acceptedTasks.insert(task.id ?? UUID().uuidString)
                    },
                    onReject: {
                        // Just visual feedback, don't create
                    }
                )
            }

            // Create All button
            Button(action: onApprove) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Create All Tasks")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.95),
                            Color(red: 0.45, green: 0.55, blue: 0.95)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    func priorityColor(_ priority: String) -> Color {
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

    func formatDate(_ dateString: String) -> String {
        // Use the same formatter as TaskReminder
        return DateFormatterHelper.formatReminderTime(dateString)
    }
}

// MARK: - Chat Task Card (matches APITaskCard from VoiceInputView)
struct ChatTaskCard: View {
    let task: TaskSuggestion
    let isAccepted: Bool
    let onAccept: () -> Void
    let onReject: () -> Void

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

            // Reminders (wrapped pills like in VoiceInputView)
            if !task.reminders.isEmpty {
                FlexibleWrapView(
                    data: task.reminders,
                    spacing: 8
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

            // Action Buttons (Reject + Accept)
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Reject")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(white: 0.4))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(white: 0.95))
                        .cornerRadius(12)
                }

                Button(action: onAccept) {
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
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func formatReminderTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"
            return displayFormatter.string(from: date)
        }
        return timeString
    }
}

// MARK: - Flexible Wrap View for Reminders
struct FlexibleWrapView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= lastHeight
                        }
                        lastHeight = d.height
                        let result = width
                        if item == data.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == data.last {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

// MARK: - Suggestion Card (from AISuggestionsView)
struct SuggestionCard: View {
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
    ChatView()
}

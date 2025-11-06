import SwiftUI

struct AskAISheet: View {
    @Environment(\.dismiss) var dismiss
    let recording: Recording

    @State private var messages: [AIMessage] = []
    @State private var userInput = ""
    @State private var isLoading = false

    // Suggested questions
    private let suggestedQuestions = [
        "What was decided about budget?",
        "List all action items",
        "Who needs to do what?",
        "Timeline overview?"
    ]

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.85))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)

                    HStack(spacing: 12) {
                        // AI Icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                Color(red: 0.17, green: 0.19, blue: 0.25)
                            )
                            .cornerRadius(12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask AI")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)

                            Text("About this recording")
                                .font(.system(size: 14))
                                .foregroundColor(Color(white: 0.5))
                        }

                        Spacer()

                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                                .frame(width: 32, height: 32)
                                .background(Color(white: 0.95))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    Divider()
                }

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Suggested Questions (if no messages yet)
                        if messages.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Try asking:")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.5))
                                    .padding(.horizontal, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(suggestedQuestions, id: \.self) { question in
                                            Button(action: {
                                                userInput = question
                                                sendMessage()
                                            }) {
                                                Text(question)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.black)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(Color(white: 0.96))
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 16)
                        }

                        // Messages
                        VStack(spacing: 16) {
                            ForEach(messages) { message in
                                if message.isUser {
                                    UserMessageBubble(text: message.text)
                                } else {
                                    AIMessageBubble(text: message.text)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Loading indicator
                        if isLoading {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.35, green: 0.61, blue: 0.95)))

                                Text("AI is thinking...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.5))
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(.bottom, 100)
                }

                Spacer()

                // Input Area
                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 12) {
                        TextField("Ask anything about this recording...", text: $userInput)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.96))
                            .cornerRadius(24)
                            .disabled(isLoading)

                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(
                                    userInput.trimmingCharacters(in: .whitespaces).isEmpty || isLoading ?
                                    Color(white: 0.85) :
                                    Color(red: 0.35, green: 0.61, blue: 0.95)
                                )
                        }
                        .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }
            }
        }
        .onAppear {
            // Add welcome message
            if messages.isEmpty {
                messages.append(AIMessage(
                    text: "Hi! I'm here to help you understand this recording. Ask me anything about the content, decisions, or action items.",
                    isUser: false
                ))
            }
        }
    }

    private func sendMessage() {
        let question = userInput.trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty else { return }

        // Add user message
        messages.append(AIMessage(text: question, isUser: true))
        userInput = ""
        isLoading = true

        // Call backend API
        _Concurrency.Task {
            do {
                let answer = try await BraindumpsterAPI.shared.chatWithRecording(
                    recordingId: recording.id,
                    message: question
                )

                await MainActor.run {
                    messages.append(AIMessage(text: answer, isUser: false))
                    isLoading = false
                }
            } catch {
                print("❌ Error chatting with AI: \(error.localizedDescription)")

                // Fallback to mock answer
                await MainActor.run {
                    let answer = generateMockAnswer(for: question)
                    messages.append(AIMessage(text: answer, isUser: false))
                    isLoading = false
                }
            }
        }
    }

    private func generateMockAnswer(for question: String) -> String {
        let questionLower = question.lowercased()

        // Search for relevant info in recording
        if questionLower.contains("budget") || questionLower.contains("bütçe") {
            if let budgetDecision = recording.keyPoints.first(where: { $0.point.lowercased().contains("budget") || $0.point.lowercased().contains("bütçe") }) {
                return "At \(budgetDecision.timestamp), it was mentioned: \(budgetDecision.point)"
            }
        }

        if questionLower.contains("action") || questionLower.contains("task") || questionLower.contains("görev") {
            if !recording.actionItems.isEmpty {
                var response = "Here are the action items from this recording:\n\n"
                for (index, item) in recording.actionItems.prefix(3).enumerated() {
                    response += "\(index + 1). \(item.task) (assigned to \(item.assignee))\n"
                }
                return response
            }
        }

        if questionLower.contains("timeline") || questionLower.contains("zaman") {
            return "The recording lasted \(recording.durationFormatted) with \(recording.speakerCount) speakers. Key moments occurred at: " +
                recording.keyPoints.prefix(3).map { $0.timestamp }.joined(separator: ", ")
        }

        if questionLower.contains("who") || questionLower.contains("kim") {
            let speakers = Set(recording.transcript.map { $0.speaker })
            return "The speakers in this recording were: \(speakers.joined(separator: ", "))"
        }

        // Default response
        return "Based on the recording, I can help you with specific questions about decisions, action items, key points, or timeline. Could you please be more specific about what you'd like to know?"
    }
}

// MARK: - AI Message Model
struct AIMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

#Preview {
    let mockRecording = Recording(
        id: "1",
        title: "Q4 Strategi Toplantısı",
        date: Date(),
        duration: 2732,
        type: .meeting,
        aiDetected: true,
        status: .completed,
        summary: RecordingSummary(
            brief: "Q4 hedefleri ve yeni ürün lansmanı tartışıldı",
            detailed: "Test summary",
            keyTakeaways: []
        ),
        sentiment: nil,
        transcript: [
            TranscriptSegment(speaker: "Ahmet", timestamp: "00:00", text: "Test", sentiment: nil)
        ],
        actionItems: [
            ActionItem(task: "Prepare budget", assignee: "Ahmet", dueDate: "Nov 5", priority: "high", timestamp: "05:23", context: "Budget discussion")
        ],
        keyPoints: [
            KeyPoint(timestamp: "05:23", point: "Q4 growth target set at 30%", category: "decision", sentiment: "positive")
        ],
        decisions: [],
        audioFileURL: nil
    )

    AskAISheet(recording: mockRecording)
}

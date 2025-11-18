import SwiftUI

struct RecordingDetailView: View {
    @Environment(\.dismiss) var dismiss
    let recording: Recording

    @State private var showAskAI = false
    @State private var showInsightsExpanded = false
    @State private var actionItems: [ActionItem]
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    init(recording: Recording) {
        self.recording = recording
        _actionItems = State(initialValue: recording.actionItems)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.98)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 16) {
                            // Back button and menu
                            HStack {
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: 48, height: 48)
                                        .background(Color(white: 0.95))
                                        .cornerRadius(14)
                                }

                                Spacer()

                                Menu {
                                    Button(action: {
                                        showShareSheet = true
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    Button(action: {
                                        // TODO: Export
                                    }) {
                                        Label("Export", systemImage: "arrow.down.doc")
                                    }
                                    Button(role: .destructive, action: {
                                        showDeleteConfirmation = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                        .frame(width: 48, height: 48)
                                        .background(Color(white: 0.95))
                                        .cornerRadius(14)
                                }
                            }

                            // Title
                            Text(recording.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)

                            // Date and duration
                            Text("\(recording.date, formatter: dateFormatter) • \(recording.durationFormatted)")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.5))

                            // Badges
                            HStack(spacing: 12) {
                                // Type badge
                                HStack(spacing: 4) {
                                    Text(recording.type.icon)
                                        .font(.system(size: 13))

                                    Text(recording.type.displayName)
                                        .font(.system(size: 14, weight: .medium))

                                    if recording.aiDetected {
                                        Text("• AI Detected")
                                            .font(.system(size: 14))
                                    }
                                }
                                .foregroundColor(Color(white: 0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(white: 0.94))
                                .cornerRadius(8)

                                // Sentiment badge
                                if let sentiment = recording.sentiment {
                                    HStack(spacing: 4) {
                                        Text(sentimentEmoji(sentiment.overall))
                                            .font(.system(size: 13))

                                        Text("\(sentiment.score)% \(sentiment.overall)")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(sentimentColor(sentiment.overall))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(sentimentColor(sentiment.overall).opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // AI Summary Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Color(red: 0.26, green: 0.30, blue: 0.38)
                                    )
                                    .cornerRadius(10)

                                Text("AI Summary")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()
                            }

                            Text(recording.summary?.detailed ?? recording.summary?.brief ?? "Analysis in progress...")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)

                            // Ask AI Button
                            Button(action: {
                                showAskAI = true
                            }) {
                                HStack {
                                    Image(systemName: "message")
                                        .font(.system(size: 16))

                                    Text("Ask AI about this recording")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Color(red: 0.26, green: 0.30, blue: 0.38)
                                )
                                .cornerRadius(12)
                            }
                        }
                        .padding(20)
                        .background(
                            Color(red: 0.17, green: 0.19, blue: 0.25)
                        )
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        // Meeting Insights (Collapsible)
                        if let sentiment = recording.sentiment {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    showInsightsExpanded.toggle()
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        HStack(spacing: 12) {
                                            Image(systemName: "chart.bar")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color(red: 0.58, green: 0.40, blue: 0.93))
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Color(red: 0.58, green: 0.40, blue: 0.93).opacity(0.15)
                                                )
                                                .cornerRadius(10)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Meeting Insights")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.black)

                                                Text("Tone & sentiment analysis")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color(white: 0.5))
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: showInsightsExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(white: 0.6))
                                    }

                                    if showInsightsExpanded {
                                        Divider()
                                            .padding(.vertical, 4)

                                        // Speaker Moods
                                        if !sentiment.speakerMoods.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Speaker Energy")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.black)

                                                ForEach(sentiment.speakerMoods) { speakerMood in
                                                    SpeakerEnergyBar(speakerMood: speakerMood)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(18)
                                .background(Color(red: 0.96, green: 0.95, blue: 1.0))
                                .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        }

                        // Stats Row
                        HStack(spacing: 16) {
                            StatCard(
                                value: "\(recording.speakerCount)",
                                label: "Speakers"
                            )

                            StatCard(
                                value: "\(recording.taskCount)",
                                label: "Tasks"
                            )

                            StatCard(
                                value: recording.durationFormatted.components(separatedBy: ":")[0] + "m",
                                label: "Duration"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        // Action Items Section
                        if !actionItems.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Action Items")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.black)

                                    Spacer()

                                    Button(action: {
                                        // TODO: Add to calendar
                                    }) {
                                        Text("Add to Calendar")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(red: 0.95, green: 0.61, blue: 0.07))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color(red: 0.95, green: 0.61, blue: 0.07), lineWidth: 1.5)
                                            )
                                    }
                                }

                                ForEach($actionItems) { $item in
                                    ActionItemCard(actionItem: $item)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        }

                        // Key Points Section
                        if !recording.keyPoints.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Key Points")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)

                                ForEach(recording.keyPoints) { keyPoint in
                                    KeyPointCard(keyPoint: keyPoint)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        }

                        // Full Transcript Section
                        if !recording.transcript.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Full Transcript")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)

                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(recording.transcript) { segment in
                                        TranscriptSegmentView(segment: segment)
                                    }
                                }
                                .padding(18)
                                .background(Color(white: 0.97))
                                .cornerRadius(16)

                                // Share and Export Buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showShareSheet = true
                                    }) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 16))

                                            Text("Share")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            Color(red: 0.35, green: 0.61, blue: 0.95)
                                        )
                                        .cornerRadius(12)
                                    }

                                    Button(action: {
                                        // TODO: Export
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.doc")
                                                .font(.system(size: 16))

                                            Text("Export")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(white: 0.94))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAskAI) {
                AskAISheet(recording: recording)
            }
            .fullScreenCover(isPresented: $showDeleteConfirmation) {
                ConfirmationView(
                    title: "Delete Recording?",
                    message: "This recording and all its data will be permanently deleted. This action cannot be undone.",
                    confirmButtonTitle: "Delete",
                    cancelButtonTitle: "Cancel",
                    isDestructive: true,
                    onConfirm: {
                        deleteRecording()
                    },
                    onCancel: {}
                )
                .background(ClearBackgroundViewForRecordingDetail())
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)

                            Text("Deleting...")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(white: 0.2))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    private func deleteRecording() {
        isDeleting = true

        _Concurrency.Task {
            do {
                try await BraindumpsterAPI.shared.deleteRecording(recording.id)

                print("✅ Recording deleted successfully")

                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Error deleting recording: \(error.localizedDescription)")

                await MainActor.run {
                    isDeleting = false
                    // TODO: Show error toast
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }

    private func sentimentEmoji(_ sentiment: String) -> String {
        switch sentiment.lowercased() {
        case "positive": return "😊"
        case "negative": return "😔"
        case "mixed": return "😐"
        default: return "😐"
        }
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "positive": return Color(red: 0.30, green: 0.69, blue: 0.31)
        case "negative": return Color(red: 0.96, green: 0.26, blue: 0.21)
        case "mixed": return Color(red: 0.95, green: 0.61, blue: 0.07)
        default: return Color(white: 0.5)
        }
    }
}

// MARK: - Speaker Energy Bar
struct SpeakerEnergyBar: View {
    let speakerMood: SpeakerMood

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(speakerMood.speaker)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)

                Spacer()

                Text("\(speakerMood.energy)%")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(white: 0.92))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(energyColor(speakerMood.energy))
                        .frame(width: geometry.size.width * CGFloat(speakerMood.energy) / 100.0, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }

    private func energyColor(_ energy: Int) -> Color {
        if energy >= 70 {
            return Color(red: 0.30, green: 0.69, blue: 0.31)
        } else if energy >= 40 {
            return Color(red: 0.95, green: 0.61, blue: 0.07)
        } else {
            return Color(red: 0.96, green: 0.26, blue: 0.21)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Action Item Card
struct ActionItemCard: View {
    @Binding var actionItem: ActionItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: {
                actionItem.isCompleted = !(actionItem.isCompleted ?? false)
            }) {
                ZStack {
                    if actionItem.isCompleted == true {
                        Circle()
                            .fill(Color(red: 0.30, green: 0.69, blue: 0.31))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color(white: 0.75), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 6) {
                Text(actionItem.task)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(actionItem.isCompleted == true ? Color(white: 0.6) : .black)
                    .strikethrough(actionItem.isCompleted == true)

                HStack(spacing: 8) {
                    Text(actionItem.assignee)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))

                    if let dueDate = actionItem.dueDate {
                        Text("•")
                            .foregroundColor(Color(white: 0.7))

                        Text(dueDate)
                            .font(.system(size: 13))
                            .foregroundColor(Color(white: 0.5))
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color(white: 0.97))
        .cornerRadius(12)
    }
}

// MARK: - Key Point Card
struct KeyPointCard: View {
    let keyPoint: KeyPoint

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(keyPoint.timestamp)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(keyPoint.point)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text(keyPoint.emoji)
                .font(.system(size: 18))
        }
        .padding(16)
        .background(Color(white: 0.97))
        .cornerRadius(12)
    }
}

// MARK: - Transcript Segment View
struct TranscriptSegmentView: View {
    let segment: TranscriptSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(segment.speaker)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                Text(segment.timestamp)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(segment.text)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.3))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    // Mock data for preview
    let mockRecording = Recording(
        id: "1",
        title: "Q4 Strategi Toplantısı",
        date: Date(),
        duration: 2732, // 45:32
        type: .meeting,
        aiDetected: true,
        status: .completed,
        summary: RecordingSummary(
            brief: "Q4 hedefleri ve yeni ürün lansmanı tartışıldı",
            detailed: "Q4 hedefleri ve yeni ürün lansmanı tartışıldı. The team discussed various strategic initiatives and aligned on key deliverables for the upcoming quarter.",
            keyTakeaways: ["Budget increase approved", "New product launch planned"]
        ),
        sentiment: SentimentData(
            overall: "positive",
            score: 78,
            moments: [],
            speakerMoods: [
                SpeakerMood(speaker: "Ahmet", mood: "positive", energy: 85, talkTimePercentage: 45.0),
                SpeakerMood(speaker: "Elif", mood: "positive", energy: 75, talkTimePercentage: 35.0),
                SpeakerMood(speaker: "Mehmet", mood: "neutral", energy: 60, talkTimePercentage: 20.0)
            ]
        ),
        transcript: [
            TranscriptSegment(speaker: "Ahmet", timestamp: "00:00", text: "Good morning everyone. Today we'll discuss our Q4 objectives.", sentiment: "neutral"),
            TranscriptSegment(speaker: "Elif", timestamp: "00:15", text: "Good morning. I'd like to share the Q3 analysis first.", sentiment: "positive")
        ],
        actionItems: [
            ActionItem(task: "Prepare Q4 budget plan", assignee: "Ahmet", dueDate: "Nov 5", priority: "high", timestamp: "05:23", context: "Budget discussion")
        ],
        keyPoints: [
            KeyPoint(timestamp: "05:23", point: "Q4 growth target set at 30%", category: "decision", sentiment: "positive"),
            KeyPoint(timestamp: "18:45", point: "New product launch planned for December", category: "decision", sentiment: "positive")
        ],
        decisions: [],
        audioFileURL: nil
    )

    RecordingDetailView(recording: mockRecording)
}

// Helper to make fullScreenCover background transparent
struct ClearBackgroundViewForRecordingDetail: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

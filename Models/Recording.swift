import Foundation

enum RecordingType: String, Codable {
    case meeting = "meeting"
    case lecture = "lecture"
    case personal = "personal"

    var icon: String {
        switch self {
        case .meeting: return "👥"
        case .lecture: return "📚"
        case .personal: return "✏️"
        }
    }

    var displayName: String {
        switch self {
        case .meeting: return "Meeting"
        case .lecture: return "Lecture"
        case .personal: return "Personal"
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

struct Recording: Identifiable, Codable {
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

    enum CodingKeys: String, CodingKey {
        case id, title, date, duration, type, aiDetected, status
        case summary, sentiment, transcript, actionItems, keyPoints, decisions
        case audioFileURL, transcriptText, transcriptProgress, analysisStage
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
         decisions: [Decision], audioFileURL: String?,
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
        self.transcriptText = transcriptText
        self.transcriptProgress = transcriptProgress
        self.analysisStage = analysisStage
    }

    // Encoder to match the custom decoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)

        // Encode date as ISO8601 string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: date), forKey: .date)

        try container.encode(duration, forKey: .duration)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(audioFileURL, forKey: .audioFileURL)
        try container.encode(aiDetected, forKey: .aiDetected)
        try container.encodeIfPresent(sentiment, forKey: .sentiment)
        try container.encode(transcript, forKey: .transcript)
        try container.encode(actionItems, forKey: .actionItems)
        try container.encode(keyPoints, forKey: .keyPoints)
        try container.encode(decisions, forKey: .decisions)
        try container.encodeIfPresent(transcriptText, forKey: .transcriptText)
        try container.encodeIfPresent(transcriptProgress, forKey: .transcriptProgress)
        try container.encodeIfPresent(analysisStage, forKey: .analysisStage)
    }
}

struct RecordingSummary: Codable {
    let brief: String // 1-2 sentences
    let detailed: String // 3-4 paragraphs
    let keyTakeaways: [String]
}

struct SentimentData: Codable {
    let overall: String // positive, neutral, negative, mixed
    let score: Int // 0-100
    let moments: [SentimentMoment]
    let speakerMoods: [SpeakerMood]
}

struct SentimentMoment: Codable, Identifiable {
    let id = UUID()
    let timestamp: String // "MM:SS"
    let type: String // positive, tension, negative, neutral
    let description: String

    enum CodingKeys: String, CodingKey {
        case timestamp, type, description
    }
}

struct SpeakerMood: Codable, Identifiable {
    let id = UUID()
    let speaker: String
    let mood: String // positive, neutral, negative
    let energy: Int // 0-100
    let talkTimePercentage: Double // Backend sends decimal values like 28.5

    enum CodingKeys: String, CodingKey {
        case speaker, mood, energy, talkTimePercentage
    }
}

struct TranscriptSegment: Codable, Identifiable {
    let id = UUID()
    let speaker: String
    let timestamp: String // "MM:SS"
    let text: String
    let sentiment: String? // positive, neutral, negative

    enum CodingKeys: String, CodingKey {
        case speaker, timestamp, text, sentiment
    }
}

struct ActionItem: Codable, Identifiable {
    let id = UUID()
    let task: String
    let assignee: String // Name or "You"
    let dueDate: String? // relative date like "2 days later"
    let priority: String // high, medium, low
    let timestamp: String // "MM:SS"
    let context: String // Why this task came up
    var isCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case task, assignee, dueDate, priority, timestamp, context, isCompleted
    }

    // Provide default value for isCompleted if not present in JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        task = try container.decode(String.self, forKey: .task)
        assignee = try container.decode(String.self, forKey: .assignee)
        dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)
        priority = try container.decode(String.self, forKey: .priority)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        context = try container.decode(String.self, forKey: .context)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted)
    }
}

struct KeyPoint: Codable, Identifiable {
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
}

struct Decision: Codable, Identifiable {
    let id = UUID()
    let decision: String
    let timestamp: String // "MM:SS"
    let participants: [String]
    let impact: String // high, medium, low

    enum CodingKeys: String, CodingKey {
        case decision, timestamp, participants, impact
    }
}

// For API responses
struct RecordingAnalysisResponse: Codable {
    let recordingId: String
    let analysis: Recording
}

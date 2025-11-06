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
    case completed = "completed"
    case failed = "failed"
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
    let talkTimePercentage: Int

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
    var isCompleted: Bool = false

    enum CodingKeys: String, CodingKey {
        case task, assignee, dueDate, priority, timestamp, context, isCompleted
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

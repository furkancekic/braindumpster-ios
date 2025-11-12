//
//  StreamingTranscriptView.swift
//  Braindumpster
//
//  Created by Claude Code on 2025-11-13.
//  Displays transcript with streaming effect and blinking cursor
//

import SwiftUI

struct StreamingTranscriptView: View {
    let transcript: [TranscriptSegment]
    let progress: Double
    let isStreaming: Bool

    @State private var autoScroll = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Transcript")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Progress indicator
                if isStreaming {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)

                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()

            // Transcript content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(transcript) { segment in
                            TranscriptSegmentRow(segment: segment)
                                .id(segment.id)
                        }

                        // Blinking cursor when streaming
                        if isStreaming {
                            HStack(spacing: 8) {
                                BlinkingCursor()

                                Text("Transcribing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 16)
                            .id("cursor")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: transcript.count) { _ in
                    if autoScroll && isStreaming {
                        withAnimation {
                            proxy.scrollTo("cursor", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(Color(white: 0.98))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct TranscriptSegmentRow: View {
    let segment: TranscriptSegment

    var speakerColor: Color {
        // Generate consistent color based on speaker name
        let hash = segment.speaker.hashValue
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .cyan]
        return colors[abs(hash) % colors.count]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Speaker badge
            VStack(spacing: 4) {
                Circle()
                    .fill(speakerColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(speakerInitials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(speakerColor)
                    )

                Text(segment.timestamp)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.speaker)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(speakerColor)

                Text(segment.text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }

    var speakerInitials: String {
        let words = segment.speaker.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        } else if let first = words.first {
            return String(first.prefix(2))
        }
        return "?"
    }
}

struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

// MARK: - Preview

struct StreamingTranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingTranscriptView(
            transcript: [
                TranscriptSegment(
                    id: UUID().uuidString,
                    speaker: "Project Manager",
                    timestamp: "00:15",
                    text: "Let's start by discussing the Q4 roadmap. We have several key initiatives to review.",
                    sentiment: "neutral"
                ),
                TranscriptSegment(
                    id: UUID().uuidString,
                    speaker: "Developer",
                    timestamp: "00:32",
                    text: "I've been working on the new authentication system. It's almost ready for testing.",
                    sentiment: "positive"
                ),
                TranscriptSegment(
                    id: UUID().uuidString,
                    speaker: "Designer",
                    timestamp: "00:48",
                    text: "The UI mockups are ready. I'll share them with the team after this meeting.",
                    sentiment: "positive"
                )
            ],
            progress: 0.65,
            isStreaming: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

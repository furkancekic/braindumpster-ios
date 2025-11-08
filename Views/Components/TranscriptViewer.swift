import SwiftUI

/// A beautiful component to display transcript text with streaming animation
struct TranscriptViewer: View {
    let transcript: String
    let progress: Double? // 0.0-1.0 for streaming progress
    let isStreaming: Bool

    @State private var displayedText: String = ""
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "text.quote")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))

                Text("Transcript")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                if isStreaming, let progress = progress {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                    }
                }
            }

            // Transcript Text
            ScrollView {
                Text(isStreaming ? displayedText : transcript)
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.2))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(white: 0.97))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 400)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            if isStreaming {
                animateText()
            } else {
                displayedText = transcript
            }
        }
        .onChange(of: transcript) { newValue in
            if isStreaming {
                // Update displayed text as new content arrives
                animateNewContent(from: displayedText, to: newValue)
            } else {
                displayedText = newValue
            }
        }
    }

    /// Animate the typing effect for initial load
    private func animateText() {
        guard !isAnimating else { return }
        isAnimating = true
        displayedText = ""

        let characters = Array(transcript)
        var index = 0

        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if index < characters.count {
                displayedText.append(characters[index])
                index += 1
            } else {
                timer.invalidate()
                isAnimating = false
            }
        }
    }

    /// Animate new content being added
    private func animateNewContent(from old: String, to new: String) {
        guard new.count > old.count else {
            displayedText = new
            return
        }

        let newCharacters = String(new.dropFirst(old.count))
        let characters = Array(newCharacters)
        var index = 0

        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if index < characters.count {
                displayedText.append(characters[index])
                index += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

/// Compact version for preview in list
struct TranscriptPreviewCard: View {
    let snippet: String // First 100 characters
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                    .frame(width: 40, height: 40)
                    .background(Color(red: 0.35, green: 0.61, blue: 0.95).opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    Text("View Full Transcript")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)

                    Text(snippet)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.7))
            }
            .padding(16)
            .background(Color(white: 0.97))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Loading state view for transcription
struct TranscriptLoadingView: View {
    let progress: Double // 0.0-1.0

    var body: some View {
        VStack(spacing: 20) {
            // Animated waveform
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.35, green: 0.61, blue: 0.95))
                        .frame(width: 6)
                        .frame(height: CGFloat.random(in: 20...50))
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: progress
                        )
                }
            }
            .frame(height: 60)

            VStack(spacing: 12) {
                Text("Transcribing audio...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.9))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.35, green: 0.61, blue: 0.95))
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 8)

                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 32)
    }
}

#Preview {
    VStack(spacing: 20) {
        TranscriptViewer(
            transcript: "This is a sample transcript text that demonstrates how the transcript viewer component looks with some content. It includes multiple sentences and paragraphs to show the scrolling behavior.",
            progress: 0.75,
            isStreaming: false
        )

        TranscriptPreviewCard(
            snippet: "This is a preview of the transcript...",
            onTap: {}
        )

        TranscriptLoadingView(progress: 0.45)
    }
    .padding()
    .background(Color(white: 0.98))
}

import SwiftUI
import AVFoundation

// Helper to make fullScreenCover background transparent
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct RecordingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showStopConfirmation = false
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var analyzedRecording: Recording?
    @State private var showRecordingDetail = false

    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.19, blue: 0.25)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: {
                        if isRecording {
                            showStopConfirmation = true
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                if isProcessing {
                    // Processing state with progress bar
                    VStack(spacing: 30) {
                        // Circular progress indicator
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 12)
                                .frame(width: 160, height: 160)

                            // Progress circle
                            Circle()
                                .trim(from: 0, to: processingProgress)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.45, green: 0.75, blue: 1.0),
                                            Color(red: 0.35, green: 0.60, blue: 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: processingProgress)

                            // Percentage text
                            VStack(spacing: 4) {
                                Text("\(Int(processingProgress * 100))%")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)

                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                            }
                        }

                        VStack(spacing: 12) {
                            Text("Analyzing recording...")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)

                            Text("AI is transcribing and analyzing")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                } else if !isRecording {
                    // Ready state
                    VStack(spacing: 40) {
                        // Microphone icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 140, height: 140)

                            Image(systemName: "mic.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 16) {
                            Text("Ready to record")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Tap the button below to start")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                } else {
                    // Recording state
                    VStack(spacing: 50) {
                        // Recording indicator
                        VStack(spacing: 24) {
                            // Pulsing red circle
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.5))
                                    .frame(width: 140, height: 140)
                                    .scaleEffect(1.1)
                                    .animation(
                                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                        value: isRecording
                                    )

                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "waveform")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }

                            // Timer
                            Text(formattedDuration)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            Text("Recording...")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }

                Spacer()

                // Control buttons
                if !isProcessing {
                    VStack(spacing: 12) {
                        if isRecording {
                            // Stop button
                            Button(action: {
                                showStopConfirmation = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: 80, height: 80)
                                        .background(Color.red)
                                        .cornerRadius(40)

                                    Text("Stop Recording")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        } else {
                            // Start recording button
                            Button(action: {
                                startRecording()
                            }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 80, height: 80)

                                        Circle()
                                            .stroke(Color.red.opacity(0.3), lineWidth: 8)
                                            .frame(width: 96, height: 96)
                                    }

                                    Text("Start Recording")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .alert("Stop Recording?", isPresented: $showStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop & Process", role: .destructive) {
                stopRecording()
            }
        } message: {
            Text("Your recording will be processed by AI to generate transcripts, summaries, and action items.")
        }
        .fullScreenCover(isPresented: $showError) {
            ErrorView(
                title: "Analysis Failed",
                message: errorMessage ?? "Unable to analyze recording. Please try again.",
                primaryButtonTitle: "Try Again",
                secondaryButtonTitle: "Dismiss",
                onPrimaryAction: {
                    errorMessage = nil
                    dismiss()
                },
                onSecondaryAction: {
                    errorMessage = nil
                    dismiss()
                }
            )
            .background(ClearBackgroundView())
        }
        .fullScreenCover(isPresented: $showRecordingDetail, onDismiss: {
            // When detail view is dismissed, go back to home
            dismiss()
        }) {
            if let recording = analyzedRecording {
                RecordingDetailView(recording: recording)
            }
        }
    }

    private var formattedDuration: String {
        let hours = Int(recordingDuration) / 3600
        let minutes = (Int(recordingDuration) % 3600) / 60
        let seconds = Int(recordingDuration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func startRecording() {
        audioRecorder.startRecording()
        isRecording = true
        recordingDuration = 0

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        isRecording = false

        // Get audio file URL before stopping
        guard let audioURL = audioRecorder.getRecordingURL() else {
            print("❌ No recording URL found")
            dismiss()
            return
        }

        audioRecorder.stopRecording()

        // Check file size (limit to 100MB for long recordings)
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? UInt64 {
            let fileSizeMB = Double(fileSize) / (1024 * 1024)
            print("📊 Recording file size: \(String(format: "%.2f", fileSizeMB)) MB")

            if fileSizeMB > 100 {
                print("❌ Recording too large: \(fileSizeMB) MB")
                errorMessage = "Recording is too large (\(String(format: "%.1f", fileSizeMB)) MB). Please try recording a shorter clip."
                showError = true
                return
            }
        }

        // Show processing state and start progress animation
        isProcessing = true
        processingProgress = 0.0

        // Start simulating progress
        simulateProgress()

        // Upload to backend and get analysis
        _Concurrency.Task {
            do {
                print("📤 Uploading recording to backend...")
                let recording = try await BraindumpsterAPI.shared.analyzeRecording(
                    audioFileURL: audioURL,
                    duration: recordingDuration
                )

                print("✅ Recording analyzed successfully: \(recording.title)")

                // Complete progress to 100%
                await MainActor.run {
                    processingProgress = 1.0
                }

                // Small delay to show 100% before transitioning
                try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 300ms

                // Show recording detail view
                await MainActor.run {
                    isProcessing = false
                    analyzedRecording = recording
                    showRecordingDetail = true
                }
            } catch {
                print("❌ Error analyzing recording: \(error.localizedDescription)")

                // Show error message to user
                await MainActor.run {
                    isProcessing = false

                    // Create user-friendly error message
                    if error.localizedDescription.contains("timed out") {
                        errorMessage = "Analysis is taking longer than expected. Your recording was saved locally. Please try uploading a shorter audio file or check your internet connection."
                    } else if error.localizedDescription.contains("offline") || error.localizedDescription.contains("internet") {
                        errorMessage = "No internet connection. Please check your network and try again."
                    } else {
                        errorMessage = "Unable to analyze recording. Please try again later."
                    }

                    showError = true
                }
            }
        }
    }

    private func simulateProgress() {
        _Concurrency.Task {
            // Simulate progress up to 95% while waiting for response
            for i in 1...95 {
                try? await _Concurrency.Task.sleep(nanoseconds: 40_000_000) // 40ms per step
                await MainActor.run {
                    processingProgress = Double(i) / 100.0
                }
            }
        }
    }
}

#Preview {
    RecordingView()
}

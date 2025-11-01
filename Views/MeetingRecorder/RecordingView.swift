import SwiftUI
import AVFoundation

struct RecordingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showStopConfirmation = false
    @State private var isProcessing = false

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
                    // Processing state (after stopping)
                    VStack(spacing: 30) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)

                        Text("Processing recording...")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("AI is transcribing and analyzing")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
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

        // Show processing state
        isProcessing = true

        // Upload to backend and get analysis
        _Concurrency.Task {
            do {
                print("📤 Uploading recording to backend...")
                let recording = try await BraindumpsterAPI.shared.analyzeRecording(
                    audioFileURL: audioURL,
                    duration: recordingDuration
                )

                print("✅ Recording analyzed successfully: \(recording.title)")

                // Close view - home screen will refresh and show new recording
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Error analyzing recording: \(error.localizedDescription)")

                // Show error and close
                await MainActor.run {
                    // TODO: Show error toast
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    RecordingView()
}

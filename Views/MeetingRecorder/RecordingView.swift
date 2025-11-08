import SwiftUI
import AVFoundation
import FirebaseAuth

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
    @StateObject private var statusListener = RecordingStatusListener()
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
    @State private var processingMessage: String = "Uploading..."

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
                            Text(processingMessage)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)

                            Text(processingProgress < 0.7 ? "Uploading audio..." : "AI is analyzing in background...")
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
        .onReceive(statusListener.$recording) { newRecording in
            guard let recording = newRecording else { return }

            print("📥 Recording status updated: \(recording.status.rawValue)")

            _Concurrency.Task {
                if recording.status == .completed {
                    // Analysis completed
                    await MainActor.run {
                        processingProgress = 1.0
                        processingMessage = "Analysis complete!"
                    }

                    // Small delay to show 100%
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                    await MainActor.run {
                        isProcessing = false
                        analyzedRecording = recording
                        showRecordingDetail = true
                    }

                    print("✅ [RecordingView] Opening detail view for recording: \(recording.title)")
                } else if recording.status == .failed {
                    // Analysis failed
                    await MainActor.run {
                        isProcessing = false
                        processingProgress = 0.0
                        errorMessage = "Analysis failed. Please try again."
                        showError = true
                    }
                }
            }
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
        var fileSizeMB: Double = 1.0  // Default to 1MB if we can't determine size
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? UInt64 {
            fileSizeMB = Double(fileSize) / (1024 * 1024)
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

        // Upload to backend and get analysis with real-time progress
        _Concurrency.Task {
            do {
                print("📤 Uploading recording to backend...")
                let recording = try await BraindumpsterAPI.shared.analyzeRecording(
                    audioFileURL: audioURL,
                    duration: recordingDuration
                ) { progress in
                    _Concurrency.Task { @MainActor in
                        self.processingProgress = progress
                        print("📊 Upload progress: \(Int(progress * 100))%")
                    }
                }

                print("✅ Recording received: \(recording.title), status: \(recording.status.rawValue)")

                // Complete upload progress to 70%
                await MainActor.run {
                    processingProgress = 0.7
                }

                // Check recording status
                if recording.status == .processing {
                    // Start listening for Firestore updates
                    await MainActor.run {
                        processingMessage = "Processing on server..."
                        guard let userId = Auth.auth().currentUser?.uid else { return }
                        statusListener.startListening(recordingId: recording.id, userId: userId)
                    }

                    print("⏳ Recording is processing in background, waiting for updates...")

                    // Progress simulation while waiting (70% -> 95%)
                    for i in 70...95 {
                        try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        await MainActor.run {
                            processingProgress = Double(i) / 100.0
                        }
                    }

                } else if recording.status == .completed {
                    // Already completed (fast response)
                    await MainActor.run {
                        processingProgress = 1.0
                    }

                    try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 300ms

                    await MainActor.run {
                        isProcessing = false
                        analyzedRecording = recording
                        showRecordingDetail = true
                    }
                } else {
                    // Failed status
                    throw NSError(domain: "RecordingError", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Recording analysis failed on server"
                    ])
                }
            } catch {
                print("❌ Error analyzing recording: \(error)")
                print("   Error type: \(type(of: error))")
                print("   Localized description: \(error.localizedDescription)")

                if let urlError = error as? URLError {
                    print("   URLError code: \(urlError.code.rawValue)")
                    print("   URLError description: \(urlError.localizedDescription)")
                }

                // Show error message to user
                await MainActor.run {
                    isProcessing = false
                    processingProgress = 0.0

                    // Create user-friendly error message
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .timedOut:
                            errorMessage = "Upload timed out. The recording may be too large or your connection is slow."
                        case .notConnectedToInternet, .networkConnectionLost:
                            errorMessage = "No internet connection. Please check your network and try again."
                        case .cannotConnectToHost, .cannotFindHost:
                            errorMessage = "Cannot reach server. Please check your internet connection."
                        default:
                            errorMessage = "Upload failed: \(urlError.localizedDescription)"
                        }
                    } else if error.localizedDescription.contains("timed out") {
                        errorMessage = "Analysis is taking longer than expected. Your recording was saved locally. Please try uploading a shorter audio file or check your internet connection."
                    } else if error.localizedDescription.contains("offline") || error.localizedDescription.contains("internet") {
                        errorMessage = "No internet connection. Please check your network and try again."
                    } else {
                        errorMessage = "Unable to analyze recording: \(error.localizedDescription)"
                    }

                    showError = true
                }
            }
        }
    }

}

#Preview {
    RecordingView()
}

import SwiftUI
import AVFoundation

struct VoiceInputView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 0.6
    @State private var showSuggestions = false
    @State private var shouldDismiss = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var apiResponse: AudioMessageResponse?
    @State private var currentExampleIndex = 0

    // Rotating example prompts
    private let examplePrompts = [
        "Try saying: 'Remind me to call Alex tomorrow at 2pm'",
        "Try: 'Buy groceries on Saturday morning'",
        "Try: 'Submit report by Friday end of day'"
    ]

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.11, green: 0.13, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: {
                        if isRecording {
                            audioRecorder.cancelRecording()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)

                    Spacer()
                }

                Spacer()

                if isProcessing {
                    // Processing state
                    VStack(spacing: 30) {
                        // Brain icon with animation
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.45, green: 0.75, blue: 1.0),
                                            Color(red: 0.35, green: 0.60, blue: 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(animationScale)
                                .opacity(animationOpacity)

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 56))
                                .foregroundColor(.white)
                        }
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                animationScale = 1.1
                                animationOpacity = 0.8
                            }
                        }

                        VStack(spacing: 12) {
                            Text("Thinking it through… 🧠")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Turning your words into action 🎯")
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                } else if !isRecording {
                    // Ready state - Microphone icon
                    VStack(spacing: 40) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.15, green: 0.2, blue: 0.28))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 0.25, green: 0.35, blue: 0.45), lineWidth: 2)
                                )

                            Image(systemName: "mic.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                        }

                        VStack(spacing: 16) {
                            Text("Dump a new thought")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Or tap 🎤 to speak your mind")
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)

                            // Rotating example prompt
                            Text(examplePrompts[currentExampleIndex])
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .padding(.top, 8)
                        }
                    }
                    .onAppear {
                        // Rotate examples every 3 seconds
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                            withAnimation {
                                currentExampleIndex = (currentExampleIndex + 1) % examplePrompts.count
                            }
                        }
                    }
                } else {
                    // Listening state - Animated microphone
                    VStack(spacing: 30) {
                        ZStack {
                            // Outer pulsing border
                            RoundedRectangle(cornerRadius: 60)
                                .stroke(Color(red: 0.20, green: 0.30, blue: 0.40).opacity(animationOpacity * 0.3), lineWidth: 3)
                                .frame(width: 380, height: 380)
                                .scaleEffect(animationScale)

                            // Middle microphone container with pulsing border
                            ZStack {
                                RoundedRectangle(cornerRadius: 40)
                                    .fill(Color(red: 0.16, green: 0.24, blue: 0.32))
                                    .frame(width: 200, height: 200)

                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color(red: 0.35, green: 0.60, blue: 0.75), lineWidth: 3 + (animationOpacity * 2))
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(1.0 + (1.0 - animationScale) * 0.1)

                                Image(systemName: "mic")
                                    .font(.system(size: 80, weight: .medium))
                                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                            }
                        }

                        VStack(spacing: 12) {
                            Text("I'm listening 👂")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Say what's on your mind...")
                                .font(.system(size: 16))
                                .foregroundColor(Color.white.opacity(0.7))
                                .multilineTextAlignment(.center)

                            Text(formatDuration(recordingDuration))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                                .monospacedDigit()
                                .padding(.top, 8)
                        }
                    }
                }

                Spacer()

                // Microphone button (only show when not recording and not processing)
                if !isRecording && !isProcessing {
                    Button(action: {
                        startRecording()
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color(red: 0.11, green: 0.13, blue: 0.18))
                            .frame(width: 120, height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(Color.white)
                            )
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onTapGesture {
            // Tap anywhere to stop recording
            if isRecording {
                stopRecording()
            }
        }
        .sheet(isPresented: $showSuggestions, onDismiss: {
            if shouldDismiss {
                dismiss()
            }
        }) {
            if let response = apiResponse {
                AISuggestionsView(
                    apiResponse: response,
                    onAllTasksAccepted: {
                        shouldDismiss = true
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showError) {
            ErrorView(
                title: "Oops!",
                message: errorMessage,
                primaryButtonTitle: "OK",
                secondaryButtonTitle: nil,
                onPrimaryAction: {}
            )
            .background(ClearBackgroundViewForVoiceInput())
        }
    }

    // MARK: - Recording Functions
    private func startRecording() {
        // Request microphone permission
        AudioRecorder.requestRecordPermission { granted in
            if granted {
                HapticFeedback.heavy()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRecording = true
                }
                audioRecorder.startRecording()
                startPulseAnimation()
                startDurationTimer()
            } else {
                HapticFeedback.error()
                errorMessage = "Microphone access needed 🎤\nEnable in Settings to use voice input"
                showError = true
            }
        }
    }

    private func stopRecording() {
        HapticFeedback.medium()
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = false
        }
        stopDurationTimer()
        audioRecorder.stopRecording()

        // Get recording URL and send to API
        if let audioURL = audioRecorder.getRecordingURL() {
            sendAudioToAPI(audioURL: audioURL)
        } else {
            HapticFeedback.error()
            errorMessage = "Didn't catch that. Try again?"
            showError = true
        }
    }

    private func sendAudioToAPI(audioURL: URL) {
        isProcessing = true

        _Concurrency.Task {
            do {
                let response = try await BraindumpsterAPI.shared.sendAudioMessage(audioFileURL: audioURL)

                await MainActor.run {
                    isProcessing = false
                    apiResponse = response
                    showSuggestions = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    let errorString = error.localizedDescription.lowercased()
                    if errorString.contains("network") || errorString.contains("internet") {
                        errorMessage = "Can't reach AI brain 🧠 Check your connection"
                    } else {
                        errorMessage = "AI took a coffee break ☕ Try again or type your task"
                    }
                    showError = true
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func startPulseAnimation() {
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animationScale = 1.15
            animationOpacity = 1.0
        }
    }

    private func startDurationTimer() {
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration = audioRecorder.recordingDuration
        }
    }

    private func stopDurationTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// Helper to make fullScreenCover background transparent
struct ClearBackgroundViewForVoiceInput: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    VoiceInputView()
}

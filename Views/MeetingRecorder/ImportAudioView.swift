import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import CoreMedia
import FirebaseAuth

// Helper to make fullScreenCover background transparent
struct ClearBackgroundViewForImport: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ImportAudioView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var statusListener = RecordingStatusListener()
    @State private var showFilePicker = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var selectedFileURL: URL?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var analyzedRecording: Recording?
    @State private var showRecordingDetail = false
    @State private var processingMessage: String = "Uploading..."
    @State private var currentFact: String = DidYouKnowFacts.randomFact()
    @State private var factRotationTimer: Timer?

    // Timing measurements
    @State private var uploadStartTime: Date?
    @State private var uploadEndTime: Date?
    @State private var analysisStartTime: Date?

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

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import Audio")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)

                            Text("Upload existing audio files")
                                .font(.system(size: 15))
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

                if isUploading {
                    // Upload Progress
                    VStack(spacing: 24) {
                        Spacer()

                        // Circular progress indicator with gradient
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(Color(white: 0.9), lineWidth: 12)
                                .frame(width: 160, height: 160)

                            // Progress circle with gradient
                            Circle()
                                .trim(from: 0, to: uploadProgress)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.35, green: 0.61, blue: 0.95),
                                            Color(red: 0.25, green: 0.51, blue: 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: uploadProgress)

                            // Percentage text and icon
                            VStack(spacing: 4) {
                                Text("\(Int(uploadProgress * 100))%")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.black)

                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                            }
                        }

                        VStack(spacing: 12) {
                            Text("Analyzing audio...")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.black)

                            Text(uploadProgress < 0.7 ? "Uploading audio..." : "AI is transcribing and creating insights")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.5))
                        }

                        // Did you know? section
                        if uploadProgress >= 0.7 {
                            VStack(spacing: 8) {
                                Text("Did you know?")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                                    .textCase(.uppercase)
                                    .tracking(1.2)

                                Text(currentFact)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.3))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    .id(currentFact) // Force re-render on change
                            }
                            .padding(.top, 20)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                } else {
                    // Main Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Hero Icon
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.35, green: 0.61, blue: 0.95).opacity(0.1))
                                        .frame(width: 120, height: 120)

                                    Image(systemName: "waveform")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                                }

                                VStack(spacing: 8) {
                                    Text("Upload Audio File")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)

                                    Text("Select an audio file to analyze")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                            .padding(.top, 40)

                            // Supported Formats
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Supported Formats")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(white: 0.5))
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    FormatRow(icon: "music.note", format: "M4A", description: "MPEG-4 Audio")
                                    FormatRow(icon: "music.note", format: "MP3", description: "MPEG Audio Layer 3")
                                    FormatRow(icon: "music.note", format: "WAV", description: "Waveform Audio")
                                    FormatRow(icon: "music.note", format: "AAC", description: "Advanced Audio Coding")
                                }
                                .padding(.horizontal, 20)
                            }

                            // Select File Button
                            Button(action: {
                                showFilePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                        .font(.system(size: 20))

                                    Text("Browse Files")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.35, green: 0.61, blue: 0.95))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker(
                supportedTypes: [
                    UTType.audio,
                    UTType(filenameExtension: "m4a")!,
                    UTType(filenameExtension: "mp3")!,
                    UTType(filenameExtension: "wav")!
                ],
                onDocumentPicked: { url in
                    selectedFileURL = url
                    uploadAudioFile(url)
                }
            )
        }
        .fullScreenCover(isPresented: $showError) {
            ErrorView(
                title: "Upload Failed",
                message: errorMessage ?? "Unable to analyze audio file. Please try again.",
                primaryButtonTitle: "OK",
                secondaryButtonTitle: nil,
                onPrimaryAction: {
                    errorMessage = nil
                }
            )
            .background(ClearBackgroundViewForImport())
        }
        .onReceive(statusListener.$recording) { newRecording in
            print("🔔 [ImportAudioView.onReceive] Firestore update received")

            guard let recording = newRecording else {
                print("⚠️ [ImportAudioView.onReceive] Recording is nil, ignoring")
                return
            }

            print("📥 [ImportAudioView.onReceive] Recording status: \(recording.status.rawValue)")
            print("   Recording ID: \(recording.id)")
            print("   Recording title: \(recording.title)")
            print("   Has summary: \(recording.summary != nil)")

            _Concurrency.Task {
                if recording.status == .completed {
                    print("✅ [ImportAudioView.Task] Status is COMPLETED, updating UI")

                    // Analysis completed
                    await MainActor.run {
                        print("🎯 [ImportAudioView.MainActor] Setting progress to 100%")
                        uploadProgress = 1.0
                        processingMessage = "Analysis complete!"
                        factRotationTimer?.invalidate()

                        // Calculate and log timing
                        let analysisEndTime = Date()
                        print("⏱️ ========================================")
                        print("⏱️ ANALYSIS COMPLETED")
                        print("⏱️ ========================================")

                        if let analysisStart = analysisStartTime {
                            let analysisDuration = analysisEndTime.timeIntervalSince(analysisStart)
                            print("⏱️ Analysis duration: \(String(format: "%.2f", analysisDuration))s (\(String(format: "%.1f", analysisDuration / 60))min)")
                        }

                        if let uploadStart = uploadStartTime {
                            let totalDuration = analysisEndTime.timeIntervalSince(uploadStart)
                            print("⏱️ Total duration (upload + analysis): \(String(format: "%.2f", totalDuration))s (\(String(format: "%.1f", totalDuration / 60))min)")
                        }

                        if let uploadStart = uploadStartTime, let uploadEnd = uploadEndTime {
                            let uploadDuration = uploadEnd.timeIntervalSince(uploadStart)
                            print("⏱️ Upload duration: \(String(format: "%.2f", uploadDuration))s")
                        }

                        print("⏱️ ========================================")
                    }

                    // Small delay to show 100%
                    print("⏱️ [ImportAudioView.Task] Waiting 0.5s before showing detail view")
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                    await MainActor.run {
                        print("🎯 [ImportAudioView.MainActor] Setting state to show detail view")
                        print("   isUploading: \(self.isUploading) -> false")
                        print("   showRecordingDetail: \(self.showRecordingDetail) -> true")

                        isUploading = false
                        analyzedRecording = recording
                        showRecordingDetail = true

                        print("✅ [ImportAudioView.MainActor] State updated successfully")
                        print("   isUploading: \(self.isUploading)")
                        print("   showRecordingDetail: \(self.showRecordingDetail)")
                        print("   analyzedRecording: \(self.analyzedRecording?.title ?? "nil")")
                    }

                    print("🎉 [ImportAudioView] Opening detail view for recording: \(recording.title)")
                } else if recording.status == .failed {
                    print("❌ [ImportAudioView.Task] Status is FAILED, showing error")

                    // Analysis failed
                    await MainActor.run {
                        print("🎯 [ImportAudioView.MainActor] Setting error state")
                        isUploading = false
                        uploadProgress = 0.0
                        errorMessage = "Analysis failed. Please try again."
                        showError = true
                        factRotationTimer?.invalidate()
                        print("✅ [ImportAudioView.MainActor] Error state set")
                    }
                } else {
                    print("ℹ️ [ImportAudioView.Task] Status is \(recording.status.rawValue), no action needed")
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

    private func uploadAudioFile(_ url: URL) {
        isUploading = true
        uploadProgress = 0.0
        uploadStartTime = Date()

        print("⏱️ ========================================")
        print("⏱️ UPLOAD STARTED at \(uploadStartTime!)")
        print("⏱️ ========================================")
        print("📤 Starting upload for file: \(url.lastPathComponent)")

        // Check file size (limit to 100MB for long recordings)
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 else {
            print("❌ Could not determine file size")
            showErrorMessage("Unable to read file. Please try again.")
            return
        }

        let fileSizeMB = Double(fileSize) / (1024 * 1024)
        print("📊 File size: \(String(format: "%.2f", fileSizeMB)) MB")

        if fileSizeMB > 100 {
            print("❌ File too large: \(fileSizeMB) MB")
            showErrorMessage("File is too large (\(String(format: "%.1f", fileSizeMB)) MB). Please upload files smaller than 100 MB.")
            return
        }

        // Get audio file duration
        let duration = getAudioDuration(url: url)
        print("⏱️ Detected duration: \(duration) seconds")

        // Warn if duration is very long (>90 minutes / 1.5 hours)
        if duration > 5400 {
            let durationMinutes = Int(duration / 60)
            print("⚠️ Very long recording detected: \(durationMinutes) minutes - analysis may take several minutes")
        } else if duration > 3600 {
            let durationMinutes = Int(duration / 60)
            print("⏱️ Long recording detected: \(durationMinutes) minutes")
        }

        _Concurrency.Task {
            do {
                // Upload to backend with real-time progress tracking
                print("📤 [ImportAudioView.Task] Uploading audio file to backend...")
                print("   File: \(url.lastPathComponent)")
                print("   Duration: \(duration)s")
                print("   Size: \(String(format: "%.2f", fileSizeMB))MB")

                let recording = try await BraindumpsterAPI.shared.analyzeRecording(
                    audioFileURL: url,
                    duration: duration
                ) { progress in
                    _Concurrency.Task { @MainActor in
                        self.uploadProgress = progress
                        if Int(progress * 100) % 10 == 0 {
                            print("📊 [ImportAudioView.Upload] Upload progress: \(Int(progress * 100))%")
                        }
                    }
                }

                print("✅ [ImportAudioView.Task] Recording received from backend:")
                print("   ID: \(recording.id)")
                print("   Title: \(recording.title)")
                print("   Status: \(recording.status.rawValue)")
                print("   Has summary: \(recording.summary != nil)")

                // Complete upload progress to 70%
                await MainActor.run {
                    uploadProgress = 0.7
                    uploadEndTime = Date()
                    if let start = uploadStartTime {
                        let uploadDuration = uploadEndTime!.timeIntervalSince(start)
                        print("⏱️ ========================================")
                        print("⏱️ UPLOAD COMPLETED in \(String(format: "%.2f", uploadDuration))s")
                        print("⏱️ ========================================")
                    }
                    print("📊 [ImportAudioView.MainActor] Upload complete (70%)")
                }

                // Check recording status
                if recording.status == .processing {
                    print("⏳ [ImportAudioView.Task] Status is PROCESSING, starting Firestore listener")

                    // Start listening for Firestore updates
                    await MainActor.run {
                        processingMessage = "Processing on server..."
                        analysisStartTime = Date()

                        print("⏱️ ========================================")
                        print("⏱️ ANALYSIS STARTED at \(analysisStartTime!)")
                        print("⏱️ ========================================")

                        guard let userId = Auth.auth().currentUser?.uid else {
                            print("❌ [ImportAudioView.MainActor] No authenticated user found!")
                            return
                        }

                        print("👤 [ImportAudioView.MainActor] Starting Firestore listener:")
                        print("   User ID: \(userId)")
                        print("   Recording ID: \(recording.id)")
                        print("   Path: users/\(userId)/recordings/\(recording.id)")
                        print("   Listener is listening: \(statusListener.isListening)")

                        statusListener.startListening(recordingId: recording.id, userId: userId)

                        print("✅ [ImportAudioView.MainActor] Firestore listener started")
                        print("   Listener is listening: \(statusListener.isListening)")

                        // Start fact rotation timer (change fact every 8 seconds)
                        factRotationTimer?.invalidate()
                        factRotationTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentFact = DidYouKnowFacts.randomFact()
                            }
                        }
                    }

                    print("⏳ [ImportAudioView.Task] Recording is processing in background, waiting for Firestore updates...")

                    // Calculate realistic processing time based on duration
                    // Typical processing: ~10-15 seconds per minute of audio
                    let estimatedProcessingSeconds = max(60, Int(duration * 0.15)) // minimum 60s
                    print("⏱️ [ImportAudioView.Task] Estimated processing time: \(estimatedProcessingSeconds)s for \(Int(duration))s audio")

                    // Progress simulation while waiting (70% -> 95%)
                    // Spread over estimated time
                    let totalSteps = 25 // 70% to 95% is 25 steps
                    let delayPerStep = Double(estimatedProcessingSeconds) / Double(totalSteps)

                    for i in 70...95 {
                        try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delayPerStep * 1_000_000_000))
                        await MainActor.run {
                            uploadProgress = Double(i) / 100.0
                        }
                        if i % 5 == 0 {
                            print("📊 [ImportAudioView.Task] Simulated progress: \(i)% (elapsed: ~\(Int((Double(i - 70) / Double(totalSteps)) * Double(estimatedProcessingSeconds)))s)")
                        }
                    }

                    print("⏸️ [ImportAudioView.Task] Reached 95%, waiting for Firestore update...")

                } else if recording.status == .completed {
                    print("⚡ [ImportAudioView.Task] Status is COMPLETED (fast response)")

                    // Already completed (fast response)
                    await MainActor.run {
                        uploadProgress = 1.0
                        print("📊 [ImportAudioView.MainActor] Progress set to 100%")
                    }

                    try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 300ms

                    await MainActor.run {
                        print("🎯 [ImportAudioView.MainActor] Setting state to show detail view")
                        isUploading = false
                        analyzedRecording = recording
                        showRecordingDetail = true
                        print("✅ [ImportAudioView.MainActor] Detail view triggered")
                    }
                } else {
                    print("❌ [ImportAudioView.Task] Unexpected status: \(recording.status.rawValue)")

                    // Failed status
                    throw NSError(domain: "RecordingError", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Recording analysis failed on server"
                    ])
                }
            } catch {
                print("❌ Error uploading audio: \(error)")
                print("   Error type: \(type(of: error))")
                print("   Localized description: \(error.localizedDescription)")

                // Log more details about URLError if available
                if let urlError = error as? URLError {
                    print("   URLError code: \(urlError.code.rawValue)")
                    print("   URLError description: \(urlError.localizedDescription)")
                }

                await MainActor.run {
                    isUploading = false
                    uploadProgress = 0.0

                    // Create user-friendly error message based on error type
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .timedOut:
                            errorMessage = "Upload timed out. The file may be too large or your connection is slow. Try a shorter recording."
                        case .notConnectedToInternet, .networkConnectionLost:
                            errorMessage = "No internet connection. Please check your network and try again."
                        case .cannotConnectToHost, .cannotFindHost:
                            errorMessage = "Cannot reach server. Please check your internet connection."
                        default:
                            errorMessage = "Upload failed: \(urlError.localizedDescription)"
                        }
                    } else if error.localizedDescription.contains("timed out") {
                        errorMessage = "Analysis is taking longer than expected. Please try uploading a shorter audio file or check your internet connection."
                    } else if error.localizedDescription.contains("offline") || error.localizedDescription.contains("internet") || error.localizedDescription.contains("network") {
                        errorMessage = "No internet connection. Please check your network and try again."
                    } else if error.localizedDescription.contains("unsupported") || error.localizedDescription.contains("format") {
                        errorMessage = "This audio format is not supported. Please use M4A, MP3, WAV, or AAC files."
                    } else {
                        errorMessage = "Unable to analyze audio file: \(error.localizedDescription)"
                    }

                    showError = true
                }
            }
        }
    }

    private func showErrorMessage(_ message: String) {
        isUploading = false
        errorMessage = message
        showError = true
    }

    private func getAudioDuration(url: URL) -> TimeInterval {
        do {
            // Use synchronous approach for AVAsset duration
            let asset = AVURLAsset(url: url)
            let duration = asset.duration

            guard duration.isValid && !duration.isIndefinite else {
                print("⚠️ Invalid audio duration, using default")
                return 0
            }

            let seconds = CMTimeGetSeconds(duration)
            guard seconds.isFinite && seconds > 0 else {
                print("⚠️ Audio duration is not finite or is zero")
                return 0
            }

            print("✅ Audio duration: \(seconds) seconds")
            return seconds
        } catch {
            print("❌ Error getting audio duration: \(error.localizedDescription)")
            return 0
        }
    }
}

// MARK: - Format Row
struct FormatRow: View {
    let icon: String
    let format: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.35, green: 0.61, blue: 0.95).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(format)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.30, green: 0.69, blue: 0.31))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.97))
        .cornerRadius(12)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let supportedTypes: [UTType]
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            print("📁 Selected file: \(url.lastPathComponent)")

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Could not access file")
                return
            }

            // Sanitize filename to avoid issues with special characters
            let originalFileName = url.lastPathComponent
            let sanitizedFileName = sanitizeFileName(originalFileName)
            print("🔄 Sanitized filename: \(originalFileName) → \(sanitizedFileName)")

            // Copy to temp location with sanitized name
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(sanitizedFileName)

            do {
                // Remove existing file if present
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }

                // Copy file to temp location
                try FileManager.default.copyItem(at: url, to: tempURL)
                print("✅ File copied to: \(tempURL.path)")

                onDocumentPicked(tempURL)
            } catch {
                print("❌ Error copying file: \(error.localizedDescription)")
            }

            url.stopAccessingSecurityScopedResource()
        }

        private func sanitizeFileName(_ fileName: String) -> String {
            // Get file extension
            let fileExtension = (fileName as NSString).pathExtension
            let nameWithoutExtension = (fileName as NSString).deletingPathExtension

            // Remove Turkish and special characters, keep only ASCII alphanumeric, dash, underscore
            let sanitized = nameWithoutExtension
                .replacingOccurrences(of: "ı", with: "i")
                .replacingOccurrences(of: "İ", with: "I")
                .replacingOccurrences(of: "ş", with: "s")
                .replacingOccurrences(of: "Ş", with: "S")
                .replacingOccurrences(of: "ğ", with: "g")
                .replacingOccurrences(of: "Ğ", with: "G")
                .replacingOccurrences(of: "ü", with: "u")
                .replacingOccurrences(of: "Ü", with: "U")
                .replacingOccurrences(of: "ö", with: "o")
                .replacingOccurrences(of: "Ö", with: "O")
                .replacingOccurrences(of: "ç", with: "c")
                .replacingOccurrences(of: "Ç", with: "C")
                .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ ")).inverted)
                .joined()
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: " ", with: "_")

            // If sanitization resulted in empty string, use timestamp
            let finalName = sanitized.isEmpty ? "audio_\(Int(Date().timeIntervalSince1970))" : sanitized

            return "\(finalName).\(fileExtension)"
        }
    }
}

#Preview {
    ImportAudioView()
}

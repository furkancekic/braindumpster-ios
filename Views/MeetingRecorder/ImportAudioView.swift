import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import CoreMedia

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

                            Text("AI is transcribing and creating insights")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.5))
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
        .onChange(of: statusListener.recording) {
            guard let recording = statusListener.recording else { return }

            print("📥 Recording status updated: \(recording.status.rawValue)")

            if recording.status == .completed {
                // Analysis completed
                uploadProgress = 1.0
                processingMessage = "Analysis complete!"

                // Small delay to show 100%
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isUploading = false
                    analyzedRecording = recording
                    showRecordingDetail = true
                }
            } else if recording.status == .failed {
                // Analysis failed
                isUploading = false
                uploadProgress = 0.0
                errorMessage = "Analysis failed. Please try again."
                showError = true
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
                print("📤 Uploading audio file: \(url.lastPathComponent)")
                let recording = try await BraindumpsterAPI.shared.analyzeRecording(
                    audioFileURL: url,
                    duration: duration
                ) { progress in
                    _Concurrency.Task { @MainActor in
                        self.uploadProgress = progress
                        print("📊 Upload progress: \(Int(progress * 100))%")
                    }
                }

                print("✅ Recording received: \(recording.title), status: \(recording.status.rawValue)")

                // Complete upload progress to 70%
                await MainActor.run {
                    uploadProgress = 0.7
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
                            uploadProgress = Double(i) / 100.0
                        }
                    }

                } else if recording.status == .completed {
                    // Already completed (fast response)
                    await MainActor.run {
                        uploadProgress = 1.0
                    }

                    try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 300ms

                    await MainActor.run {
                        isUploading = false
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

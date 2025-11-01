import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct ImportAudioView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showFilePicker = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var selectedFileURL: URL?
    @State private var errorMessage: String?
    @State private var showError = false

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

                        // Progress Circle
                        ZStack {
                            Circle()
                                .stroke(Color(white: 0.9), lineWidth: 8)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: uploadProgress)
                                .stroke(
                                    Color(red: 0.35, green: 0.61, blue: 0.95),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: uploadProgress)

                            VStack(spacing: 4) {
                                Text("\(Int(uploadProgress * 100))%")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)

                                Text("Uploading")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.5))
                            }
                        }

                        VStack(spacing: 8) {
                            Text("Analyzing audio...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            Text("AI is transcribing and creating insights")
                                .font(.system(size: 14))
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
        .alert("Upload Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }

    private func uploadAudioFile(_ url: URL) {
        isUploading = true
        uploadProgress = 0.0

        // Get audio file duration
        let duration = getAudioDuration(url: url)

        _Concurrency.Task {
            do {
                // Simulate progress updates
                await simulateProgress()

                // Upload to backend
                print("📤 Uploading audio file: \(url.lastPathComponent)")
                let recording = try await BraindumpsterAPI.shared.analyzeRecording(
                    audioFileURL: url,
                    duration: duration
                )

                print("✅ Audio file analyzed successfully: \(recording.title)")

                await MainActor.run {
                    isUploading = false
                    dismiss()
                }
            } catch {
                print("❌ Error uploading audio: \(error.localizedDescription)")

                await MainActor.run {
                    isUploading = false
                    errorMessage = "Failed to analyze audio file. Please try again."
                    showError = true
                }
            }
        }
    }

    private func simulateProgress() async {
        // Simulate upload progress
        for i in 1...100 {
            await MainActor.run {
                uploadProgress = Double(i) / 100.0
            }
            try? await _Concurrency.Task.sleep(nanoseconds: 30_000_000) // 30ms
        }
    }

    private func getAudioDuration(url: URL) -> TimeInterval {
        do {
            let asset = AVURLAsset(url: url)
            let duration = try asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            print("⚠️ Could not get audio duration: \(error.localizedDescription)")
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

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Could not access file")
                return
            }

            // Copy to temp location
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)

                onDocumentPicked(tempURL)
            } catch {
                print("❌ Error copying file: \(error.localizedDescription)")
            }

            url.stopAccessingSecurityScopedResource()
        }
    }
}

#Preview {
    ImportAudioView()
}

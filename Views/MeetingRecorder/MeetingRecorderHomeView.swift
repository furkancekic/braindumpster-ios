import SwiftUI

struct MeetingRecorderHomeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showRecordingView = false
    @State private var showAllRecordings = false
    @State private var showImportAudio = false
    @State private var recentRecordings: [Recording] = []
    @State private var isLoadingRecordings = false
    @State private var selectedRecording: Recording? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.98)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(greetingText)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)
                                    +
                                    Text(" 👋")
                                        .font(.system(size: 32))

                                    Text(currentDateFormatted)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(white: 0.5))
                                }

                                Spacer()

                                // Settings button
                                Button(action: {
                                    // TODO: Navigate to settings
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black)
                                        .frame(width: 48, height: 48)
                                        .background(Color(white: 0.95))
                                        .cornerRadius(14)
                                }

                                // AI button (back)
                                Button(action: {
                                    dismiss()
                                }) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Color(red: 0.17, green: 0.19, blue: 0.25)
                                        )
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Main CTA - Start Recording
                        Button(action: {
                            showRecordingView = true
                        }) {
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .frame(width: 64, height: 64)
                                        .background(
                                            Color(red: 0.93, green: 0.26, blue: 0.26)
                                        )
                                        .cornerRadius(16)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Start Recording")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)

                                        Text("Tap to record • AI will detect type")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.white.opacity(0.7))
                                    }

                                    Spacer()
                                }

                                Text("Record meetings, lectures, or personal notes. Gemini will transcribe, summarize, and create action items automatically.")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                Color(red: 0.17, green: 0.19, blue: 0.25)
                            )
                            .cornerRadius(20)
                        }
                        .padding(.horizontal, 20)

                        // Quick Actions
                        HStack(spacing: 12) {
                            // Import Audio
                            Button(action: {
                                showImportAudio = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "icloud.and.arrow.up")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: 64, height: 64)
                                        .background(
                                            Color(red: 0.35, green: 0.61, blue: 0.95)
                                        )
                                        .cornerRadius(16)

                                    VStack(spacing: 4) {
                                        Text("Import Audio")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)

                                        Text("Upload existing files")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.5))
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Color(white: 0.96))
                                .cornerRadius(16)
                            }

                            // All Recordings
                            Button(action: {
                                showAllRecordings = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .frame(width: 64, height: 64)
                                        .background(
                                            Color(red: 0.58, green: 0.40, blue: 0.93)
                                        )
                                        .cornerRadius(16)

                                    VStack(spacing: 4) {
                                        Text("All Recordings")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)

                                        Text("Browse \(recentRecordings.count) items")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.5))
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Color(white: 0.96))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Recent Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)

                                Spacer()

                                Button(action: {
                                    showAllRecordings = true
                                }) {
                                    Text("View All")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                                }
                            }
                            .padding(.horizontal, 20)

                            if isLoadingRecordings {
                                // Loading skeleton screens
                                VStack(spacing: 12) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        RecordingCardSkeleton()
                                            .padding(.horizontal, 20)
                                    }
                                }
                            } else if recentRecordings.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "mic.slash")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(white: 0.7))

                                    Text("No recordings yet")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(white: 0.5))

                                    Text("Tap 'Start Recording' to create your first recording")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(white: 0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(recentRecordings.prefix(3)) { recording in
                                        Button(action: {
                                            selectedRecording = recording
                                        }) {
                                            RecordingCard(recording: recording)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRecordingView, onDismiss: {
                // Small delay to allow Firestore to index new recording
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 500ms
                    await MainActor.run {
                        loadRecentRecordings()
                    }
                }
            }) {
                RecordingView()
            }
            .fullScreenCover(isPresented: $showAllRecordings, onDismiss: {
                loadRecentRecordings()
            }) {
                AllRecordingsView()
            }
            .fullScreenCover(item: $selectedRecording) { recording in
                RecordingDetailView(recording: recording)
            }
            .sheet(isPresented: $showImportAudio, onDismiss: {
                // Small delay to allow Firestore to index new recording
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 500ms
                    await MainActor.run {
                        loadRecentRecordings()
                    }
                }
            }) {
                ImportAudioView()
            }
        }
        .onAppear {
            loadRecentRecordings()
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning, there"
        case 12..<17:
            return "Good afternoon, there"
        default:
            return "Good evening, there"
        }
    }

    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, EEEE"
        return formatter.string(from: Date())
    }

    private func loadRecentRecordings() {
        print("🔄 [MeetingRecorderHomeView] Loading recent recordings...")
        isLoadingRecordings = true

        _Concurrency.Task {
            do {
                print("📡 [MeetingRecorderHomeView] Calling API...")
                let recordings = try await BraindumpsterAPI.shared.getRecordings(limit: 3)

                print("✅ [MeetingRecorderHomeView] API returned \(recordings.count) recordings")
                if recordings.isEmpty {
                    print("   ⚠️ [MeetingRecorderHomeView] No recordings found - list is empty")
                } else {
                    for (index, recording) in recordings.enumerated() {
                        print("   \(index + 1). \(recording.title)")
                        print("      ID: \(recording.id)")
                        print("      Status: \(recording.status.rawValue)")
                        print("      Date: \(recording.date)")
                    }
                }

                await MainActor.run {
                    print("🎯 [MeetingRecorderHomeView] Updating state with \(recordings.count) recordings")
                    recentRecordings = recordings
                    isLoadingRecordings = false
                    print("✅ [MeetingRecorderHomeView] State updated. recentRecordings.count = \(self.recentRecordings.count)")
                }
            } catch {
                print("❌ [MeetingRecorderHomeView] Error loading recordings:")
                print("   Error: \(error.localizedDescription)")
                print("   Error type: \(type(of: error))")

                if let apiError = error as? URLError {
                    print("   URLError code: \(apiError.code.rawValue)")
                }

                await MainActor.run {
                    recentRecordings = []
                    isLoadingRecordings = false
                    print("⚠️ [MeetingRecorderHomeView] State cleared due to error")
                }
            }
        }
    }
}

// MARK: - Recording Card Component
struct RecordingCard: View {
    let recording: Recording

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)

                    Text(recording.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                Text(recording.durationFormatted)
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(recording.summary?.brief ?? "Processing...")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.4))
                .lineLimit(2)

            HStack(spacing: 12) {
                // Type badge
                HStack(spacing: 4) {
                    Text(recording.type.icon)
                        .font(.system(size: 12))

                    Text(recording.type.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                }

                Text("•")
                    .foregroundColor(Color(white: 0.7))

                Text("\(recording.taskCount) tasks")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Recording Card Skeleton (Loading State)
struct RecordingCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Title skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.9))
                        .frame(width: 200, height: 18)
                        .shimmer(isAnimating: isAnimating)

                    // Date skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(white: 0.9))
                        .frame(width: 120, height: 14)
                        .shimmer(isAnimating: isAnimating)
                }

                Spacer()

                // Duration skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.9))
                    .frame(width: 50, height: 15)
                    .shimmer(isAnimating: isAnimating)
            }

            // Summary skeleton (2 lines)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.9))
                    .frame(height: 14)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.9))
                    .frame(width: 180, height: 14)
                    .shimmer(isAnimating: isAnimating)
            }

            // Badges skeleton
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.9))
                    .frame(width: 80, height: 13)
                    .shimmer(isAnimating: isAnimating)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.9))
                    .frame(width: 60, height: 13)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isAnimating {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.5),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

#Preview {
    MeetingRecorderHomeView()
}

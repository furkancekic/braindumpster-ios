import SwiftUI

struct MeetingRecorderHomeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showRecordingView = false
    @State private var showAllRecordings = false
    @State private var showImportAudio = false
    @State private var recentRecordings: [Recording] = [] // TODO: Load from backend

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

                            if recentRecordings.isEmpty {
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
                                        RecordingCard(recording: recording)
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
            .fullScreenCover(isPresented: $showRecordingView) {
                RecordingView()
            }
            .fullScreenCover(isPresented: $showAllRecordings) {
                AllRecordingsView()
            }
            .sheet(isPresented: $showImportAudio) {
                // TODO: Import audio sheet
                Text("Import Audio")
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
        // TODO: Load from backend
        // For now, empty
        recentRecordings = []
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

            Text(recording.summary.brief)
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
        .background(Color(white: 0.97))
        .cornerRadius(16)
    }
}

#Preview {
    MeetingRecorderHomeView()
}

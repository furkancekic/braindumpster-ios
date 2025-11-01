import SwiftUI

struct AllRecordingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: RecordingType? = nil
    @State private var recordings: [Recording] = [] // TODO: Load from backend
    @State private var selectedRecording: Recording? = nil

    var filteredRecordings: [Recording] {
        var result = recordings

        // Apply type filter
        if let filter = selectedFilter {
            result = result.filter { $0.type == filter }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.brief.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(white: 0.98)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 20) {
                        // Back button and title
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(width: 48, height: 48)
                                    .background(Color(white: 0.95))
                                    .cornerRadius(14)
                            }

                            Spacer()
                        }

                        Text("All Recordings")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        // Search bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(Color(white: 0.5))

                            TextField("Search recordings...", text: $searchText)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(white: 0.96))
                        .cornerRadius(14)

                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // All filter
                                FilterChip(
                                    title: "All",
                                    icon: nil,
                                    isSelected: selectedFilter == nil,
                                    action: {
                                        selectedFilter = nil
                                    }
                                )

                                // Meeting filter
                                FilterChip(
                                    title: "Meetings",
                                    icon: "👥",
                                    isSelected: selectedFilter == .meeting,
                                    action: {
                                        selectedFilter = .meeting
                                    }
                                )

                                // Lecture filter
                                FilterChip(
                                    title: "Lectures",
                                    icon: "📚",
                                    isSelected: selectedFilter == .lecture,
                                    action: {
                                        selectedFilter = .lecture
                                    }
                                )

                                // Personal filter
                                FilterChip(
                                    title: "Personal",
                                    icon: "✏️",
                                    isSelected: selectedFilter == .personal,
                                    action: {
                                        selectedFilter = .personal
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    // Recordings List
                    if filteredRecordings.isEmpty {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "folder")
                                .font(.system(size: 48))
                                .foregroundColor(Color(white: 0.7))

                            Text("No recordings found")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))

                            if !searchText.isEmpty {
                                Text("Try adjusting your search or filters")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.6))
                            }
                        }

                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredRecordings) { recording in
                                    Button(action: {
                                        selectedRecording = recording
                                    }) {
                                        RecordingListCard(recording: recording)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedRecording) { recording in
                RecordingDetailView(recording: recording)
            }
        }
        .onAppear {
            loadRecordings()
        }
    }

    private func loadRecordings() {
        // TODO: Load from backend
        // For now, empty
        recordings = []
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 14))
                }

                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                Color(red: 0.17, green: 0.19, blue: 0.25) :
                Color(white: 0.96)
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Recording List Card Component
struct RecordingListCard: View {
    let recording: Recording

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recording.title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(recording.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                Text(recording.durationFormatted)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(recording.summary.brief)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.4))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                // Type badge
                HStack(spacing: 4) {
                    Text(recording.type.icon)
                        .font(.system(size: 13))

                    Text(recording.type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.35, green: 0.61, blue: 0.95))
                }

                Text("•")
                    .foregroundColor(Color(white: 0.7))

                Text("\(recording.taskCount) tasks")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    AllRecordingsView()
}

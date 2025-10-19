import Foundation
import SwiftUI

/// Manages user streak tracking and milestone celebrations
class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastCompletionDate: Date?
    @Published var showMilestone = false
    @Published var milestoneReached: StreakMilestone?

    private let streakKey = "user_current_streak"
    private let longestStreakKey = "user_longest_streak"
    private let lastCompletionKey = "user_last_completion_date"

    init() {
        loadStreak()
    }

    // MARK: - Streak Management
    func recordTaskCompletion() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = lastCompletionDate {
            let lastDateStart = Calendar.current.startOfDay(for: lastDate)
            let daysSinceLastCompletion = Calendar.current.dateComponents([.day], from: lastDateStart, to: today).day ?? 0

            if daysSinceLastCompletion == 0 {
                // Already completed a task today, no streak update needed
                return
            } else if daysSinceLastCompletion == 1 {
                // Consecutive day! Increase streak
                currentStreak += 1
                lastCompletionDate = today
            } else {
                // Streak broken - reset to 1
                currentStreak = 1
                lastCompletionDate = today
            }
        } else {
            // First task ever completed
            currentStreak = 1
            lastCompletionDate = today
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        saveStreak()
        checkForMilestone()
    }

    func checkForMilestone() {
        // Check if current streak hits a milestone
        if let milestone = StreakMilestone.milestone(for: currentStreak) {
            milestoneReached = milestone
            showMilestone = true
        }
    }

    // MARK: - Persistence
    private func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        if let date = lastCompletionDate {
            UserDefaults.standard.set(date, forKey: lastCompletionKey)
        }
    }

    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        lastCompletionDate = UserDefaults.standard.object(forKey: lastCompletionKey) as? Date

        // Check if streak should be reset (missed yesterday)
        if let lastDate = lastCompletionDate {
            let today = Calendar.current.startOfDay(for: Date())
            let lastDateStart = Calendar.current.startOfDay(for: lastDate)
            let daysSinceLastCompletion = Calendar.current.dateComponents([.day], from: lastDateStart, to: today).day ?? 0

            if daysSinceLastCompletion > 1 {
                // Streak broken - reset
                currentStreak = 0
                saveStreak()
            }
        }
    }

    // MARK: - Helpers
    var streakEmoji: String {
        switch currentStreak {
        case 0:
            return "💪"
        case 1...2:
            return "🔥"
        case 3...6:
            return "🔥🔥"
        case 7...13:
            return "🔥🔥🔥"
        default:
            return "🚀"
        }
    }

    var streakMessage: String {
        switch currentStreak {
        case 0:
            return "Complete a task to start your streak!"
        case 1:
            return "Great start! Keep it going tomorrow"
        case 2:
            return "Two days strong! You're on a roll"
        case 3:
            return "Three day streak! You're crushing it"
        case 7:
            return "One week streak! Incredible!"
        case 14:
            return "Two weeks! You're unstoppable"
        case 30:
            return "30 days! You're a productivity legend"
        default:
            return "\(currentStreak) days strong! Keep going"
        }
    }
}

// MARK: - Streak Milestones
struct StreakMilestone: Identifiable {
    let id = UUID()
    let days: Int
    let title: String
    let message: String
    let emoji: String
    let color: Color

    static func milestone(for days: Int) -> StreakMilestone? {
        switch days {
        case 3:
            return StreakMilestone(
                days: 3,
                title: "3 Day Streak!",
                message: "You're building momentum 💪",
                emoji: "🔥",
                color: Color.orange
            )
        case 7:
            return StreakMilestone(
                days: 7,
                title: "One Week Streak!",
                message: "A whole week of crushing it! 🎯",
                emoji: "🔥🔥",
                color: Color.orange
            )
        case 14:
            return StreakMilestone(
                days: 14,
                title: "Two Week Streak!",
                message: "You're unstoppable! 🚀",
                emoji: "🔥🔥🔥",
                color: Color.red
            )
        case 30:
            return StreakMilestone(
                days: 30,
                title: "30 Day Streak!",
                message: "Legend status unlocked! 👑",
                emoji: "🏆",
                color: Color(red: 1.0, green: 0.84, blue: 0.0)
            )
        case 60:
            return StreakMilestone(
                days: 60,
                title: "60 Day Streak!",
                message: "Productivity master! 🌟",
                emoji: "⭐",
                color: Color(red: 1.0, green: 0.84, blue: 0.0)
            )
        case 100:
            return StreakMilestone(
                days: 100,
                title: "100 Day Streak!",
                message: "You're in the hall of fame! 🎖️",
                emoji: "💎",
                color: Color.purple
            )
        default:
            return nil
        }
    }

    static var allMilestones: [StreakMilestone] {
        [3, 7, 14, 30, 60, 100].compactMap { milestone(for: $0) }
    }
}

// MARK: - Streak Card View
struct StreakCardView: View {
    @ObservedObject var streakManager = StreakManager.shared

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(streakManager.streakEmoji)
                            .font(.system(size: 32))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(streakManager.currentStreak) day streak")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)

                            Text(streakManager.streakMessage)
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    if streakManager.longestStreak > streakManager.currentStreak {
                        Text("Longest: \(streakManager.longestStreak) days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                            .padding(.top, 4)
                    }
                }

                Spacer()

                // Milestone indicator
                if let nextMilestone = StreakMilestone.allMilestones.first(where: { $0.days > streakManager.currentStreak }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color(white: 0.9), lineWidth: 3)
                                .frame(width: 50, height: 50)

                            Circle()
                                .trim(from: 0, to: min(CGFloat(streakManager.currentStreak) / CGFloat(nextMilestone.days), 1.0))
                                .stroke(nextMilestone.color, lineWidth: 3)
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))

                            Text(nextMilestone.emoji)
                                .font(.system(size: 20))
                        }

                        Text("\(nextMilestone.days - streakManager.currentStreak) to go")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(white: 0.6))
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.1),
                    Color.red.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Milestone Celebration View
struct MilestoneCelebrationView: View {
    @Binding var isPresented: Bool
    let milestone: StreakMilestone
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 24) {
                Text(milestone.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                    .opacity(opacity)

                VStack(spacing: 12) {
                    Text(milestone.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)

                    Text(milestone.message)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Amazing! 🎉")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [milestone.color, milestone.color.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
            .padding(.horizontal, 40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .confetti(isPresented: $showConfetti, pieceCount: 100)
        .onAppear {
            HapticFeedback.success()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            // Trigger confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.8
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    StreakCardView()
}

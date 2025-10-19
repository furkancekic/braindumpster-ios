import Foundation
import UserNotifications

/**
 NOTIFICATION COPY GUIDE FOR BRAINDUMPSTER

 This file documents the friendly, encouraging notification copy that should be used
 throughout the app. These messages are sent from the backend, but this guide ensures
 consistency with the app's friendly UX tone.

 ## Tone Guidelines:
 - Friendly and encouraging
 - Short and actionable
 - Use emojis sparingly (one per notification)
 - Focus on the "why" not just the "what"
 - Celebrate wins, gently remind of tasks

 ## Technical Implementation:
 - Notifications are sent via Firebase Cloud Messaging from the Python backend
 - Title: Short (max 30 chars), punchy
 - Body: Helpful context (max 90 chars)
 - Badge: Task count
 - Sound: Default
 */

/// Notification copy templates for all app scenarios
enum NotificationCopyTemplates {

    // MARK: - Task Reminders

    /// When a task is due soon (15 minutes before)
    static let taskDueSoon = NotificationTemplate(
        title: "Heads up! 👋",
        body: "{task_title} is due in 15 minutes",
        action: "open_task"
    )

    /// When a task is due now
    static let taskDueNow = NotificationTemplate(
        title: "Time to act! ⏰",
        body: "{task_title} is due now",
        action: "open_task"
    )

    /// When a task is overdue
    static let taskOverdue = NotificationTemplate(
        title: "Hey, don't forget! 🔔",
        body: "{task_title} needs your attention",
        action: "open_task"
    )

    /// Daily reminder (morning)
    static let dailyMorningReminder = NotificationTemplate(
        title: "Good morning! ☀️",
        body: "You have {count} tasks today. Let's crush them!",
        action: "open_dashboard"
    )

    /// Daily reminder (afternoon)
    static let dailyAfternoonReminder = NotificationTemplate(
        title: "Afternoon check-in 👋",
        body: "{count} tasks left. You're doing great!",
        action: "open_dashboard"
    )

    /// Daily reminder (evening)
    static let dailyEveningReminder = NotificationTemplate(
        title: "Evening wind-down 🌙",
        body: "{count} tasks remaining. Almost there!",
        action: "open_dashboard"
    )

    // MARK: - Streak & Motivation

    /// Streak is about to break (no task completed today)
    static let streakAtRisk = NotificationTemplate(
        title: "Don't break the streak! 🔥",
        body: "Complete one task to keep your {streak_days} day streak alive",
        action: "open_dashboard"
    )

    /// Streak milestone reached
    static let streakMilestone = NotificationTemplate(
        title: "Milestone reached! 🎉",
        body: "{streak_days} day streak! You're crushing it!",
        action: "open_dashboard"
    )

    /// Weekly progress summary
    static let weeklyProgress = NotificationTemplate(
        title: "Weekly wins! 🌟",
        body: "You completed {count} tasks this week. Keep going!",
        action: "open_dashboard"
    )

    // MARK: - AI Suggestions

    /// AI created tasks from voice/chat
    static let aiTasksCreated = NotificationTemplate(
        title: "Tasks created! ✓",
        body: "I created {count} tasks from your message",
        action: "open_dashboard"
    )

    /// AI has a suggestion
    static let aiSuggestion = NotificationTemplate(
        title: "Smart suggestion 💡",
        body: "Based on your tasks, try {suggestion}",
        action: "open_dashboard"
    )

    // MARK: - Completed Tasks

    /// Task marked complete (for collaboration/shared tasks)
    static let taskCompleted = NotificationTemplate(
        title: "Task done! 🎯",
        body: "{task_title} is now complete",
        action: "open_dashboard"
    )

    /// All tasks for the day completed
    static let allTasksComplete = NotificationTemplate(
        title: "All done! Time to chill 😎",
        body: "Every task is checked off. You earned a break!",
        action: "open_dashboard"
    )

    // MARK: - Recurring Tasks

    /// Recurring task created
    static let recurringTaskCreated = NotificationTemplate(
        title: "New task added 📝",
        body: "{task_title} is ready for you",
        action: "open_task"
    )

    // MARK: - Premium & Features

    /// Premium trial ending
    static let premiumTrialEnding = NotificationTemplate(
        title: "Trial ending soon ⏰",
        body: "3 days left to try premium. Loving it?",
        action: "open_premium"
    )

    /// New feature available
    static let newFeature = NotificationTemplate(
        title: "New feature! ✨",
        body: "{feature_name} is now available. Check it out!",
        action: "open_dashboard"
    )

    // MARK: - Gentle Nudges

    /// User hasn't opened app in 3 days
    static let comeBackNudge = NotificationTemplate(
        title: "We miss you! 👋",
        body: "Your tasks are waiting. Come back when you're ready",
        action: "open_dashboard"
    )

    /// User hasn't completed tasks in a while
    static let motivationalNudge = NotificationTemplate(
        title: "You got this! 💪",
        body: "Small steps add up. Complete one task today?",
        action: "open_dashboard"
    )

    // MARK: - Priority Escalation

    /// High priority task due soon
    static let highPriorityDue = NotificationTemplate(
        title: "Urgent! 🚨",
        body: "{task_title} needs attention now",
        action: "open_task"
    )

    /// Multiple overdue tasks
    static let multipleOverdue = NotificationTemplate(
        title: "Catching up time 📚",
        body: "{count} tasks are overdue. Let's tackle them!",
        action: "open_dashboard"
    )
}

/// Notification template structure
struct NotificationTemplate {
    let title: String
    let body: String
    let action: String // Action identifier for deep linking

    /// Replace placeholders with actual values
    func format(replacements: [String: String]) -> (title: String, body: String) {
        var formattedTitle = title
        var formattedBody = body

        for (key, value) in replacements {
            formattedTitle = formattedTitle.replacingOccurrences(of: "{\(key)}", with: value)
            formattedBody = formattedBody.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return (formattedTitle, formattedBody)
    }
}

/**
 BACKEND IMPLEMENTATION NOTES:

 When sending notifications from Python backend, use these templates:

 ```python
 # Example: Task due soon
 message = messaging.Message(
     notification=messaging.Notification(
         title="Heads up! 👋",
         body=f"{task_title} is due in 15 minutes"
     ),
     data={
         "action": "open_task",
         "task_id": task_id
     },
     token=fcm_token
 )
 ```

 ## Frequency Guidelines:
 - Task reminders: At scheduled time + 15min before
 - Daily summary: Once per day (morning or evening based on user pref)
 - Streak reminders: Once per day if at risk
 - Come back nudges: Max once per 3 days
 - Motivation: Max once per week

 ## Quiet Hours:
 - Respect user's quiet hours (default: 10 PM - 8 AM)
 - Only send urgent notifications during quiet hours

 ## Personalization:
 - Use user's first name when available
 - Adapt time-based greetings (morning/afternoon/evening)
 - Reference specific tasks when relevant

 ## A/B Testing:
 Keep these variations for testing:
 - Emoji vs no emoji
 - "You" vs name-based
 - Action-focused vs celebration-focused
 */

/// Notification categories for iOS (define in AppDelegate if needed)
enum NotificationCategories {
    static let taskReminder = "TASK_REMINDER"
    static let dailySummary = "DAILY_SUMMARY"
    static let streakMilestone = "STREAK_MILESTONE"
    static let aiSuggestion = "AI_SUGGESTION"
    static let motivation = "MOTIVATION"

    /// Actions for quick replies
    static let completeTaskAction = UNNotificationAction(
        identifier: "COMPLETE_ACTION",
        title: "Mark Complete ✓",
        options: [.foreground]
    )

    static let snoozeTaskAction = UNNotificationAction(
        identifier: "SNOOZE_ACTION",
        title: "Snooze 1 hour",
        options: []
    )

    static let viewTaskAction = UNNotificationAction(
        identifier: "VIEW_ACTION",
        title: "View Task",
        options: [.foreground]
    )
}

/**
 USAGE EXAMPLES:

 // Get notification template
 let template = NotificationCopyTemplates.taskDueSoon

 // Format with actual values
 let (title, body) = template.format(replacements: [
     "task_title": "Buy groceries"
 ])

 // Result:
 // title: "Heads up! 👋"
 // body: "Buy groceries is due in 15 minutes"
 */

import Foundation

/// Service to handle timezone information for tasks and reminders
class TimezoneService {
    static let shared = TimezoneService()

    private init() {}

    // MARK: - Get Current Timezone Info

    /// Get user's current timezone identifier (e.g., "Europe/Brussels")
    func getUserTimezone() -> String {
        return TimeZone.current.identifier
    }

    /// Get timezone offset in seconds from UTC
    func getTimezoneOffset() -> Int {
        return TimeZone.current.secondsFromGMT()
    }

    /// Get timezone abbreviation (e.g., "CET", "EST")
    func getTimezoneAbbreviation() -> String {
        return TimeZone.current.abbreviation() ?? "UTC"
    }

    // MARK: - Format Dates

    /// Get current date/time in ISO 8601 format with timezone
    /// Returns: "2025-10-16T15:30:00+01:00"
    func getCurrentTimeISO8601() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.string(from: Date())
    }

    /// Convert Date to ISO 8601 string with user's timezone
    func dateToISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.string(from: date)
    }

    /// Parse ISO 8601 string to Date
    func parseISO8601(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.date(from: dateString)
    }

    // MARK: - Display Formatting

    /// Format date for display in user's timezone
    /// - Parameters:
    ///   - date: Date to format
    ///   - style: DateFormatter style
    /// - Returns: Formatted string (e.g., "Oct 16, 2025, 3:30 PM")
    func formatForDisplay(_ date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// Format date with custom format in user's timezone
    func formatCustom(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    // MARK: - Timezone Context for API

    /// Get complete timezone context to send to backend
    /// Returns dictionary with timezone info for API requests
    func getTimezoneContext() -> [String: Any] {
        return [
            "userTimezone": getUserTimezone(),
            "timezoneOffset": getTimezoneOffset(),
            "timezoneAbbreviation": getTimezoneAbbreviation(),
            "currentLocalTime": getCurrentTimeISO8601()
        ]
    }

    // MARK: - Debug Info

    /// Print timezone information for debugging
    func printTimezoneInfo() {
        print("🌍 TIMEZONE INFO")
        print("   Timezone: \(getUserTimezone())")
        print("   Offset: \(getTimezoneOffset() / 3600) hours from UTC")
        print("   Abbreviation: \(getTimezoneAbbreviation())")
        print("   Current time: \(getCurrentTimeISO8601())")
    }
}

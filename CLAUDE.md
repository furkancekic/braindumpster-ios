# Claude Code Instructions for Braindumpster iOS App

This file contains important patterns, conventions, and directives that should be followed when working on this codebase.

## 🎨 Custom UI Components - Alert & Confirmation Pattern

### ⚠️ NEVER USE DEFAULT APPLE ALERTS

**CRITICAL RULE:** This app uses custom-branded UI for all alerts, errors, and confirmations.
**NEVER** use Apple's default `.alert()` modifier.

### Available Custom Components

#### 1. ErrorView - For Error Messages
Located: `/Views/Components/ErrorView.swift`

**Use when:** Displaying errors, failures, or informational messages that require user acknowledgment.

**Features:**
- Red warning icon with gradient circle background
- White card with 24px rounded corners
- Blue gradient primary button (matches app theme)
- Optional gray secondary button
- Semi-transparent overlay (0.4 opacity)
- Custom typography (22pt bold title, 15pt message)

**Usage Example:**
```swift
.fullScreenCover(isPresented: $showError) {
    ErrorView(
        title: "Upload Failed",
        message: errorMessage,
        primaryButtonTitle: "Try Again",
        secondaryButtonTitle: "Dismiss", // Optional
        onPrimaryAction: {
            // Handle primary action
        },
        onSecondaryAction: {
            // Handle secondary action (optional)
        }
    )
    .background(ClearBackgroundViewForXXX())
}
```

#### 2. ConfirmationView - For User Confirmations
Located: `/Views/Components/ConfirmationView.swift`

**Use when:** Asking user to confirm destructive or important actions.

**Features:**
- Orange warning icon for destructive actions (delete, sign out, etc.)
- Blue question icon for normal confirmations
- Same card design as ErrorView
- Two buttons: Cancel (gray) and Confirm (red for destructive, blue for normal)
- `isDestructive` parameter to control styling

**Usage Example:**
```swift
.fullScreenCover(isPresented: $showDeleteConfirmation) {
    ConfirmationView(
        title: "Delete Everything?",
        message: "This will permanently delete your account and all data. This cannot be undone.",
        confirmButtonTitle: "Delete Forever",
        cancelButtonTitle: "Cancel",
        isDestructive: true, // Use orange icon and red button
        onConfirm: {
            // Perform destructive action
        },
        onCancel: {
            // Handle cancellation
        }
    )
    .background(ClearBackgroundViewForXXX())
}
```

### Required Helper Struct

Each view that uses these custom components needs a unique ClearBackgroundView helper to make the fullScreenCover background transparent:

```swift
// Helper to make fullScreenCover background transparent
struct ClearBackgroundViewForYourView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
```

**Important:** Use a unique name for each view (e.g., `ClearBackgroundViewForSettings`, `ClearBackgroundViewForSignIn`) to avoid naming conflicts.

### Migration Checklist

When replacing an Apple alert:

1. ✅ Change `.alert()` to `.fullScreenCover(isPresented:)`
2. ✅ Replace with `ErrorView` or `ConfirmationView`
3. ✅ Add unique `ClearBackgroundViewForXXX` helper struct
4. ✅ Ensure state variable names match (e.g., `$showError`)
5. ✅ Test that overlay dismisses correctly
6. ✅ Verify button actions work as expected

### Views Already Migrated

These views have been updated with custom UI:
- ✅ RecordingView (ErrorView)
- ✅ ImportAudioView (ErrorView)
- ✅ SettingsView (2x ErrorView + 2x ConfirmationView)
- ✅ VoiceInputView (ErrorView)
- ✅ SignInView (ErrorView)
- ✅ ForgotPasswordView (ErrorView)
- ✅ SignUpView (ErrorView)
- ✅ SubscriptionManagementView (ErrorView + ConfirmationView)
- ✅ TaskDetailView (ErrorView)
- ✅ RecordingDetailView (ConfirmationView)

### Design Tokens

Use these exact values to maintain consistency:

**Colors:**
- Error icon: `.red`
- Warning icon (destructive): `Color(red: 1.0, green: 0.58, blue: 0.0)` (orange)
- Info icon (normal): `Color(red: 0.35, green: 0.61, blue: 0.95)` (blue)
- Overlay: `Color.black.opacity(0.4)`
- Card background: `.white`
- Primary button gradient:
  - `Color(red: 0.35, green: 0.75, blue: 0.95)` to `Color(red: 0.45, green: 0.55, blue: 0.95)`
- Destructive button gradient:
  - `Color(red: 1.0, green: 0.23, blue: 0.19)` to `Color(red: 0.93, green: 0.13, blue: 0.14)`
- Secondary button: `Color(white: 0.95)`

**Typography:**
- Title: `.system(size: 22, weight: .bold)`
- Message: `.system(size: 15)`, `Color(white: 0.4)`
- Button text: `.system(size: 17, weight: .semibold)`

**Spacing:**
- Card corner radius: `24`
- Card max width: `340`
- Card padding: `32`
- Button corner radius: `12`
- Button vertical padding: `16`
- Icon circle size: `80x80`
- Icon size: `36`

## 📝 General Coding Conventions

### NO TODO Comments
- Never leave TODO comments in code
- Complete all implementations before committing
- If something can't be done immediately, create a GitHub issue instead

### Error Handling
- Always use user-friendly error messages
- Provide actionable guidance in error messages
- Example: "No internet connection. Please check your network and try again." (not just "Network error")

### Backend Integration
- Use `_Concurrency.Task` for async operations (not `Task` alone to avoid naming conflicts)
- Always handle errors with specific error types
- Log errors with context: `print("❌ Error uploading: \(error.localizedDescription)")`
- Use emojis in logs for easy scanning: ✅ 📤 ❌ ⚠️

### Date/Time Handling
- Backend returns ISO8601 dates WITHOUT microseconds
- iOS uses `.iso8601` decoder
- Format: `"2025-11-05T20:18:21"` (no `.326883` suffix)

### Language Detection
- Backend AI (Gemini) automatically detects audio/text language
- AI responses match the input language:
  - Turkish input → Turkish analysis
  - English input → English analysis
  - German input → German analysis
- Never translate or mix languages in responses

## 🔧 Build & Testing

### Adding New Files to Xcode
When creating new Swift files (like ErrorView.swift, ConfirmationView.swift):
1. Create the file in the correct directory
2. **IMPORTANT:** Manually add to Xcode project:
   - Right-click project in Xcode navigator
   - "Add Files to Braindumpster..."
   - Select the file
   - Ensure "Copy items if needed" is checked
   - Ensure target "Braindumpster" is selected

### Build Command
```bash
xcodebuild -project Braindumpster.xcodeproj -scheme Braindumpster \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=6E595095-0E85-4170-A297-B7C1D02DE536' \
  build
```

## 🎯 Project-Specific Rules

### Meeting Recorder Feature
- Audio uploads timeout after 300 seconds (5 minutes)
- Use `audio/mp4` MIME type for iOS m4a files
- Always return valid JSON from Gemini, even for empty/noise audio
- Show progress indicators during upload/analysis

### Subscription Management
- Backend handles all subscription validation
- iOS uses RevenueCat for IAP
- Always check subscription status before premium features
- Handle billing retry scenarios gracefully

### Authentication
- Firebase Auth for user management
- Google Sign-In and Apple Sign-In supported
- Email/password with password reset
- Store user display name and email

## 📚 Key Documentation Files

- `DESIGN_SPECIFICATION.md` - Complete UI/UX specifications
- `BACKEND_IMPLEMENTATION_GUIDE.md` - Backend API documentation
- `IMPLEMENTATION_SUMMARY.md` - Feature implementation details
- `IAP_SERVER_SIDE_VALIDATION_README.md` - Subscription validation flow

## 🚀 Development Workflow

1. **Read existing code patterns** before implementing new features
2. **Use custom UI components** for all user-facing alerts
3. **Handle errors gracefully** with user-friendly messages
4. **Test on real devices** when possible, especially for audio/permissions
5. **Commit frequently** with clear, descriptive commit messages
6. **Document new patterns** in this file for future reference

---

**Last Updated:** 2025-11-05
**Updated By:** Claude Code (Custom Alert UI Pattern)

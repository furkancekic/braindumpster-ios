import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Text("Last updated: October 10, 2025")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.5))
                    }
                    .padding(.bottom, 8)

                    // Introduction
                    SectionView(
                        title: "Introduction",
                        content: """
                        Welcome to Braindumpster. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our task management application.
                        """
                    )

                    // Information We Collect
                    SectionView(
                        title: "Information We Collect",
                        content: """
                        We collect information that you provide directly to us:

                        • Account Information: Name, email address, and authentication credentials
                        • Task Data: Tasks, reminders, and notes you create
                        • Usage Information: How you interact with our app
                        • Device Information: Device type, operating system, and unique identifiers
                        • Push Notification Tokens: For sending task reminders
                        """
                    )

                    // How We Use Your Information
                    SectionView(
                        title: "How We Use Your Information",
                        content: """
                        We use your information to:

                        • Provide and maintain our services
                        • Send you task reminders and notifications
                        • Improve and personalize your experience
                        • Communicate with you about updates and changes
                        • Ensure the security and integrity of our services
                        • Comply with legal obligations
                        """
                    )

                    // AI-Powered Features
                    SectionView(
                        title: "AI-Powered Features",
                        content: """
                        Braindumpster uses AI (Google Gemini) to help you create tasks from voice input. When you use voice features:

                        • Your voice recordings are processed to convert speech to text
                        • The text is sent to Google Gemini to intelligently create tasks
                        • Audio files are temporarily stored and then deleted after processing
                        • No voice recordings are permanently stored on our servers
                        """
                    )

                    // Data Storage and Security
                    SectionView(
                        title: "Data Storage and Security",
                        content: """
                        Your data is stored securely using:

                        • Firebase Authentication for secure login
                        • Firebase Firestore for encrypted data storage
                        • Industry-standard encryption (HTTPS/TLS)
                        • Regular security audits and updates

                        We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.
                        """
                    )

                    // Third-Party Services
                    SectionView(
                        title: "Third-Party Services",
                        content: """
                        We use the following third-party services:

                        • Firebase (Google): Authentication and data storage
                        • Google Gemini AI: Voice processing and task creation
                        • Apple Push Notification Service: iOS notifications
                        • Google Sign-In: OAuth authentication
                        • Sign in with Apple: OAuth authentication

                        These services have their own privacy policies and may collect data as described in their respective policies.
                        """
                    )

                    // Your Rights
                    SectionView(
                        title: "Your Rights",
                        content: """
                        You have the right to:

                        • Access your personal data
                        • Correct inaccurate data
                        • Request deletion of your data
                        • Export your data
                        • Opt-out of notifications
                        • Withdraw consent at any time

                        To exercise these rights, please contact us through the app's support section or email us.
                        """
                    )

                    // Data Retention
                    SectionView(
                        title: "Data Retention",
                        content: """
                        We retain your data for as long as your account is active. When you delete your account:

                        • All personal data is permanently deleted within 30 days
                        • Task data and reminders are removed from our servers
                        • Backup copies are purged during the next scheduled cycle
                        • Anonymous analytics data may be retained for service improvement
                        """
                    )

                    // Children's Privacy
                    SectionView(
                        title: "Children's Privacy",
                        content: """
                        Braindumpster is not intended for children under 16 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.
                        """
                    )

                    // Changes to This Policy
                    SectionView(
                        title: "Changes to This Policy",
                        content: """
                        We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last updated" date.
                        """
                    )

                    // Contact Us
                    SectionView(
                        title: "Contact Us",
                        content: """
                        If you have any questions about this Privacy Policy, please contact us:

                        Email: furkancekic46@icloud.com

                        We will respond to your inquiries within 30 days.
                        """
                    )
                }
                .padding(20)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(white: 0.6))
                    }
                }
            }
        }
    }
}

// Section component for privacy policy
struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text(content)
                .font(.system(size: 16))
                .foregroundColor(Color(white: 0.3))
                .lineSpacing(4)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}

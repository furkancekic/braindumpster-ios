import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Service")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Text("Last updated: October 10, 2025")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.5))
                    }
                    .padding(.bottom, 8)

                    // Introduction
                    SectionView(
                        title: "1. Agreement to Terms",
                        content: """
                        By accessing and using Braindumpster ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.
                        """
                    )

                    // Description of Service
                    SectionView(
                        title: "2. Description of Service",
                        content: """
                        Braindumpster is a task management application that helps you organize your tasks, set reminders, and boost productivity. The App uses artificial intelligence to help you create tasks from voice input and provides intelligent task management features.

                        Key Features:
                        • Voice-powered task creation
                        • AI-assisted task organization
                        • Smart reminders and notifications
                        • Task categorization and prioritization
                        • Calendar integration
                        """
                    )

                    // User Accounts
                    SectionView(
                        title: "3. User Accounts",
                        content: """
                        To use Braindumpster, you must create an account. You agree to:

                        • Provide accurate and complete information
                        • Maintain the security of your account
                        • Notify us immediately of any unauthorized access
                        • Be responsible for all activities under your account
                        • Not share your account credentials with others

                        You may sign in using email/password, Apple Sign In, or Google Sign In.
                        """
                    )

                    // Acceptable Use
                    SectionView(
                        title: "4. Acceptable Use",
                        content: """
                        You agree NOT to:

                        • Use the App for any illegal purpose
                        • Violate any laws or regulations
                        • Impersonate another person or entity
                        • Transmit malicious code or viruses
                        • Attempt to gain unauthorized access to our systems
                        • Interfere with or disrupt the service
                        • Use automated systems to access the App
                        • Abuse or harass other users or our support team
                        • Store or share inappropriate or offensive content
                        """
                    )

                    // AI-Generated Content
                    SectionView(
                        title: "5. AI-Generated Content",
                        content: """
                        Braindumpster uses Google Gemini AI to process voice input and create tasks. By using this feature:

                        • You grant us permission to process your voice input
                        • You understand that AI-generated suggestions may not always be accurate
                        • You are responsible for reviewing and editing AI-generated content
                        • We do not guarantee the accuracy of AI interpretations
                        • Voice recordings are temporarily processed and not permanently stored
                        """
                    )

                    // Intellectual Property
                    SectionView(
                        title: "6. Intellectual Property",
                        content: """
                        Braindumpster and its content, features, and functionality are owned by Braindumpster Team and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.

                        Your Content:
                        • You retain all rights to your task data and content
                        • You grant us a license to use, store, and display your content solely to provide our services
                        • You can delete your content at any time
                        • Upon account deletion, your content will be permanently removed
                        """
                    )

                    // Notifications
                    SectionView(
                        title: "7. Notifications and Reminders",
                        content: """
                        The App sends push notifications for task reminders. By using Braindumpster:

                        • You consent to receive notifications
                        • You can disable notifications in your device settings
                        • We are not liable for missed notifications due to device settings or technical issues
                        • Notification delivery depends on Apple Push Notification Service availability
                        """
                    )

                    // Data Usage
                    SectionView(
                        title: "8. Data and Privacy",
                        content: """
                        Your privacy is important to us. Our collection and use of personal information is described in our Privacy Policy. By using the App, you consent to our data practices as described in the Privacy Policy.

                        Data Security:
                        • We use industry-standard security measures
                        • Your data is encrypted in transit and at rest
                        • We regularly update our security protocols
                        • No system is 100% secure; use at your own risk
                        """
                    )

                    // Subscription and Payments
                    SectionView(
                        title: "9. Subscription and Payments",
                        content: """
                        Braindumpster may offer premium features through subscriptions:

                        • Subscriptions are billed through Apple App Store
                        • Pricing is displayed in the App before purchase
                        • Subscriptions auto-renew unless cancelled
                        • Cancel anytime through your Apple App Store account
                        • No refunds for partial subscription periods
                        • Free trial terms will be specified at sign-up
                        """
                    )

                    // Service Availability
                    SectionView(
                        title: "10. Service Availability",
                        content: """
                        We strive to provide reliable service, but:

                        • The App may be temporarily unavailable for maintenance
                        • We do not guarantee 100% uptime
                        • We may modify or discontinue features with notice
                        • Third-party services (Firebase, Gemini AI) may affect availability
                        • We are not liable for service interruptions
                        """
                    )

                    // Disclaimer of Warranties
                    SectionView(
                        title: "11. Disclaimer of Warranties",
                        content: """
                        THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.

                        We do not warrant that:
                        • The App will meet your requirements
                        • The App will be uninterrupted or error-free
                        • AI-generated content will be accurate
                        • Reminders will always be delivered on time
                        """
                    )

                    // Limitation of Liability
                    SectionView(
                        title: "12. Limitation of Liability",
                        content: """
                        TO THE MAXIMUM EXTENT PERMITTED BY LAW, BRAINDUMPSTER SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOST PROFITS, DATA LOSS, OR OTHER INTANGIBLE LOSSES.

                        This includes damages arising from:
                        • Use or inability to use the App
                        • Unauthorized access to your data
                        • Missed reminders or notifications
                        • Errors in AI-generated content
                        • Service interruptions
                        """
                    )

                    // Account Termination
                    SectionView(
                        title: "13. Account Termination",
                        content: """
                        We may terminate or suspend your account immediately, without prior notice:

                        • For violations of these Terms
                        • For suspected fraudulent activity
                        • At your request
                        • For prolonged inactivity

                        Upon termination:
                        • Your right to use the App will cease
                        • Your data will be deleted within 30 days
                        • Paid subscription benefits will end immediately
                        """
                    )

                    // Governing Law
                    SectionView(
                        title: "14. Governing Law",
                        content: """
                        These Terms shall be governed by and construed in accordance with the laws of the jurisdiction where Braindumpster operates, without regard to its conflict of law provisions.
                        """
                    )

                    // Changes to Terms
                    SectionView(
                        title: "15. Changes to Terms",
                        content: """
                        We reserve the right to modify these Terms at any time. We will notify you of any changes by:

                        • Posting the new Terms in the App
                        • Updating the "Last updated" date
                        • Sending an in-app notification

                        Continued use of the App after changes constitutes acceptance of the new Terms.
                        """
                    )

                    // Contact Information
                    SectionView(
                        title: "16. Contact Us",
                        content: """
                        If you have any questions about these Terms, please contact us:

                        Email: furkancekic46@icloud.com

                        We aim to respond to all inquiries within 3-5 business days.
                        """
                    )

                    // Acknowledgment
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Acknowledgment")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        Text("BY USING BRAINDUMPSTER, YOU ACKNOWLEDGE THAT YOU HAVE READ THESE TERMS OF SERVICE AND AGREE TO BE BOUND BY THEM.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.70, blue: 0.90))
                            .lineSpacing(4)
                    }
                    .padding(.top, 8)
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

#Preview {
    TermsOfServiceView()
}

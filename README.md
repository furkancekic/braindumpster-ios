# 🎤 Brain Dumpster

**AI-Powered Task Management iOS App with Voice-to-Task Conversion**

[![Platform](https://img.shields.io/badge/platform-iOS%2018.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 📱 Overview

Brain Dumpster is a modern iOS application that transforms the way you manage tasks. Simply speak your thoughts, and our AI converts them into actionable tasks with smart reminders and intelligent scheduling.

### ✨ Key Features

- 🎤 **Voice-to-Task Conversion** - Speak your tasks naturally, AI does the rest
- 🤖 **AI Assistant** - Intelligent chat interface for task management
- 📅 **Smart Calendar** - Visual timeline of your tasks and reminders
- 🔔 **Intelligent Reminders** - Context-aware notifications that actually help
- 💎 **Premium Plans** - Monthly, Yearly, and Lifetime subscriptions
- 🔐 **Secure Authentication** - Firebase-powered auth with Google Sign-In
- 🌐 **Cloud Sync** - Your tasks everywhere, always in sync
- 🎨 **Modern Design** - Beautiful SwiftUI interface with smooth animations

## 🏗️ Architecture

### Tech Stack

**Frontend (iOS)**
- SwiftUI for modern, declarative UI
- StoreKit 2 for in-app purchases
- Firebase Authentication
- Combine for reactive programming
- AVFoundation for audio recording

**Backend**
- Python Flask API
- Firebase Admin SDK
- Apple Receipt Validation
- RESTful API architecture

### Project Structure

```
braindumpster-ios/
├── Views/
│   ├── ChatView.swift           # AI chat interface
│   ├── PremiumView.swift        # Subscription UI
│   ├── ContentView.swift        # Main dashboard
│   ├── CalendarDetailView.swift # Calendar view
│   └── TaskDetailView.swift     # Task details
├── Services/
│   ├── AuthService.swift        # Firebase auth
│   ├── BraindumpsterAPI.swift   # Backend API client
│   ├── NativeStoreManager.swift # IAP manager
│   └── ReceiptValidationService.swift
├── Models/
│   └── Models.swift             # Data models
├── Utils/
│   ├── ColorPalette.swift       # Design system
│   ├── HapticFeedback.swift     # Touch feedback
│   └── ToastView.swift          # Toast notifications
└── Backend/
    └── receipt_validation_endpoint.py
```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 18.0+ deployment target
- CocoaPods or Swift Package Manager
- Firebase project setup
- Apple Developer Account (for IAP testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/furkancekic/braindumpster-ios.git
   cd braindumpster-ios
   ```

2. **Open in Xcode**
   ```bash
   open Braindumpster.xcodeproj
   ```

3. **Configure Firebase**
   - Add your `GoogleService-Info.plist` to the project
   - Update Firebase configuration in `AuthService.swift`

4. **Configure Backend**
   - Update `BackendConfig.swift` with your backend URL
   - Set up Python backend (see backend documentation)

5. **Build and Run**
   - Select your target device/simulator
   - Press `⌘R` to build and run

### StoreKit Configuration

For testing in-app purchases in Xcode:
1. Open `Products.storekit` in Xcode
2. Ensure all products are configured:
   - `brain_dumpster_monthly_premium` - $9.99/month
   - `brain_dumpster_yearly_premium` - $49.99/year
   - `brain_dumpster_lifetime_premium` - $99.99 one-time

## 💎 In-App Purchases

### Subscription Tiers

| Plan | Price | Period | Features |
|------|-------|--------|----------|
| Monthly | $9.99 | 1 month | All premium features |
| Yearly | $49.99 | 1 year | Save 58%, best value |
| Lifetime | $99.99 | One-time | Unlimited access forever |

### Purchase Flow

1. **StoreKit Validation** - Apple's cryptographic signature verification
2. **Backend Validation** (optional) - Server-side receipt validation with Apple
3. **Premium Unlock** - Features unlocked immediately
4. **Cloud Sync** - Subscription status synced across devices

**Note:** Backend validation is non-blocking. Purchases succeed based on StoreKit verification, ensuring reliability even if backend is temporarily unavailable.

## 🔐 Security

- ✅ Firebase Authentication with secure token validation
- ✅ Server-side receipt validation with Apple
- ✅ No sensitive data stored locally
- ✅ HTTPS for all network requests (production)
- ✅ Receipt data never logged in plain text

## 📊 Backend API

### Endpoints

```
GET  /api/health                      # Health check
POST /api/verify-receipt               # Receipt validation
POST /api/subscriptions/sync-status    # Sync subscription
GET  /api/subscriptions/status         # Get subscription status
```

### Receipt Validation

```swift
// iOS sends receipt to backend
let receipt = try await getReceiptData()
let response = try await ReceiptValidationService.shared.verifyReceipt(
    transaction: transaction,
    userId: userId
)

// Backend verifies with Apple
// Returns: { success, isPremium, productId, expirationDate }
```

## 🧪 Testing

### Local Testing

```bash
# Run unit tests
⌘U in Xcode

# Test IAP with sandbox
# Use StoreKit configuration file in Xcode
```

### Backend Testing

```bash
# Test Firebase auth and backend
python3 test_firebase_auth.py

# Expected output:
# ✅ Firebase authentication successful
# ✅ Backend health check passed
# ✅ Receipt verification working
```

## 📱 App Store

**Version:** 1.0 (Build 9)
**Status:** In Review
**Platform:** iOS 18.0+
**Category:** Productivity

## 📖 Documentation

- [Backend Implementation Guide](BACKEND_IMPLEMENTATION_GUIDE.md)
- [IAP Server-Side Validation](IAP_SERVER_SIDE_VALIDATION_README.md)
- [App Store Metadata](APP_STORE_METADATA.md)
- [Design Specification](DESIGN_SPECIFICATION.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Firebase for authentication and cloud services
- OpenAI for AI-powered task processing
- Apple StoreKit for in-app purchases
- RevenueCat for subscription management (alternative implementation)

## 📧 Contact

**Developer:** Furkan Cekic
**Email:** sabutay@sabutayhun.com
**GitHub:** [@furkancekic](https://github.com/furkancekic)

---

**Made with ❤️ using SwiftUI**

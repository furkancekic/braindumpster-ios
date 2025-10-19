# Server-Side IAP Receipt Validation - Implementation Guide

## 📋 Overview

iOS app now uses **server-side receipt validation** for In-App Purchases. All receipt verification is done by the Python backend, not the iOS client.

---

## 🎯 What Changed (iOS Side)

### Files Added/Modified:

#### 1. **BackendConfig.swift** (NEW)
- Backend URL configuration: `http://57.129.81.193:5001/api`
- Auth token placeholder
- Retry logic configuration (max 2 retries, exponential backoff)

#### 2. **ReceiptValidationService.swift** (NEW)
- Handles all communication with backend for receipt verification
- **POST /verify-receipt** endpoint
- Sends: `receipt_data` (base64), `userId`, `device_info`, `app_version`
- Receives: `success`, `isPremium`, `productId`, `expirationDate`, `environment`
- **Security**: NEVER logs full receipt, only SHA256 hash (first 8 chars)
- **Retry logic**: Max 2 retries with exponential backoff (2s, 4s)
- **Error handling**: Client errors (4xx) don't retry, server errors (5xx) retry

#### 3. **NativeStoreManager.swift** (MODIFIED)
- Purchase flow now:
  1. StoreKit verification (Apple signature check)
  2. **Backend verification** (server-side validation)
  3. Finish transaction only if both succeed
- Temporary errors (network, 5xx) → still finish transaction (avoid stuck state)
- Permanent errors (4xx) → don't finish transaction

#### 4. **Braindumpster-Bridging-Header.h** (NEW)
- Imports CommonCrypto for SHA256 hashing

---

## 📤 Request Format

### Endpoint:
```
POST http://57.129.81.193:5001/api/verify-receipt
```

### Headers:
```
Content-Type: application/json
Authorization: Bearer YOUR_BACKEND_AUTH_TOKEN
```

### Body:
```json
{
  "receiptData": "BASE64_ENCODED_RECEIPT_STRING",
  "userId": "firebase_user_id_optional",
  "deviceInfo": {
    "model": "iPhone15,3",
    "osVersion": "iOS 18.0",
    "locale": "en_US"
  },
  "appVersion": "1.0 (7)",
  "bundleId": "com.braindumpster.app"
}
```

**IMPORTANT**:
- `receiptData` is the full App Store receipt, base64 encoded
- DO NOT log this in backend! Only log hash for debugging
- `userId` can be null for unauthenticated users

---

## 📥 Expected Response Format

### Success (200):
```json
{
  "success": true,
  "isPremium": true,
  "productId": "brain_dumpster_yearly_premium",
  "expirationDate": "2026-10-14T12:00:00Z",
  "environment": "sandbox",
  "message": "Receipt verified successfully"
}
```

### Client Error (400-499):
```json
{
  "success": false,
  "isPremium": false,
  "message": "Invalid receipt format"
}
```
**iOS behavior**: Shows error to user, NO retry

### Server Error (500-599):
```json
{
  "success": false,
  "isPremium": false,
  "message": "Temporary server error"
}
```
**iOS behavior**: Shows temp error, RETRIES up to 2 times

---

## 🔐 Security Requirements

### iOS Side (DONE):
- ✅ Only logs SHA256 hash (first 8 hex chars) of receipt
- ✅ Uses HTTPS when available (current: HTTP for dev)
- ✅ Auth token in Authorization header
- ✅ Secure error messages (no sensitive data)

### Backend Side (TODO by you):
- ⚠️ NEVER log full receipt in plain text
- ⚠️ Use Apple's verification API: `https://buy.itunes.apple.com/verifyReceipt` (production)
- ⚠️ Fallback to sandbox: `https://sandbox.itunes.apple.com/verifyReceipt` (if status 21007)
- ⚠️ Store receipt hash only in database for audit
- ⚠️ Implement rate limiting (prevent abuse)
- ⚠️ Validate Firebase auth token from `Authorization` header

---

## 🧪 Testing (iOS)

### Console Logs You'll See:

#### Successful Purchase:
```
🛍️ [NativeStore] Initiating purchase for: Yearly Premium
   Product ID: brain_dumpster_yearly_premium
   Price: $49.99
   Environment: Xcode/Simulator (Sandbox)

✅ [NativeStore] Purchase successful
   ✅ StoreKit verification passed (Apple signature valid)
   Transaction ID: 2000000XXXXXX
   Product ID: brain_dumpster_yearly_premium
   Environment: Xcode

🔐 [NativeStore] Verifying receipt with backend...
🔐 [ReceiptValidation] Starting receipt verification
   Receipt hash (first 8): a1b2c3d4
   Transaction ID: 2000000XXXXXX
   Product ID: brain_dumpster_yearly_premium

📤 [ReceiptValidation] Sending request to: http://57.129.81.193:5001/api/verify-receipt
📥 [ReceiptValidation] Response status: 200
✅ [ReceiptValidation] Verification successful
   Premium: true
   Product ID: brain_dumpster_yearly_premium
   Environment: sandbox

✅ [NativeStore] Backend verification successful!
🎉 [NativeStore] Transaction finished
```

#### Failed Verification:
```
❌ [NativeStore] Backend verification failed
   Message: Receipt expired

OR

❌ [ReceiptValidation] Server error (503)
   Message: Service temporarily unavailable
⚠️ [NativeStore] Temporary error, finishing transaction anyway
```

---

## 🔄 Flow Diagram

```
User Taps "Subscribe"
       ↓
StoreKit Purchase Flow
       ↓
✅ Apple Returns Transaction
       ↓
✅ Client Verifies Apple Signature
       ↓
📤 Send Receipt to Backend
       ↓
   [BACKEND VALIDATION]
       ↓
✅ Success? → Unlock Premium → Finish Transaction
       ↓
❌ Temp Error? → Retry (max 2x) → Still finish transaction
       ↓
❌ Permanent Error? → Show error → DON'T finish transaction
```

---

## 🛠️ Configuration

### Before Building:

1. **Set Auth Token** (BackendConfig.swift line 13):
```swift
static var authToken: String {
    return "YOUR_ACTUAL_BACKEND_AUTH_TOKEN"
}
```

2. **Optional: Change Backend URL** (if needed):
```swift
static var baseURL: String {
    return "https://your-production-backend.com/api"
}
```

3. **Add Bridging Header to Xcode**:
- Project Settings → Build Settings
- Search "Objective-C Bridging Header"
- Set to: `Braindumpster-Bridging-Header.h`

---

## 📊 Error Handling Matrix

| Scenario | iOS Action | Backend Retry | Transaction Finish |
|----------|-----------|---------------|-------------------|
| Backend returns 200 success | Unlock premium | No | Yes |
| Backend returns 400 (invalid) | Show error | No | No |
| Backend returns 500 | Show temp error | Yes (2x) | Yes (avoid stuck) |
| Network timeout | Show temp error | Yes (2x) | Yes (avoid stuck) |
| Backend unreachable | Show temp error | Yes (2x) | Yes (avoid stuck) |

---

## 🚀 Deployment Checklist

### iOS:
- [x] BackendConfig.swift created
- [x] ReceiptValidationService.swift created
- [x] NativeStoreManager.swift updated
- [x] Bridging header added
- [ ] Set real auth token in BackendConfig
- [ ] Test with mock backend
- [ ] Test with real backend
- [ ] Update build number (currently 7)
- [ ] Archive and upload to TestFlight

### Backend:
- [ ] Implement `/verify-receipt` endpoint (see next section)
- [ ] Add Apple receipt validation
- [ ] Add sandbox fallback logic
- [ ] Store subscription status in database
- [ ] Add rate limiting
- [ ] Add logging (hash only!)
- [ ] Deploy to production

---

## 📝 Next Steps

1. **iOS**: Build and test in Xcode (simulator or device)
2. **Backend**: Implement Python endpoint (see PYTHON_BACKEND_REQUIREMENTS.md)
3. **Integration Test**: End-to-end purchase flow
4. **Submit to App Store Review**

---

## 🐛 Troubleshooting

### "No receipt available"
- Run on real device or simulator with StoreKit Configuration enabled
- Check Products.storekit file exists

### "Backend verification failed" (400)
- Check receipt format is base64
- Check bundleId matches app
- Check backend logs for validation errors

### "Network error" / "Timeout"
- Check backend URL is reachable
- Check auth token is valid
- Check firewall/network settings

### "Transaction stuck in pending"
- Clear app data and reinstall
- Restore purchases
- Check App Store Connect for transaction status

---

**Build Version**: 1.0 (7)
**Last Updated**: October 14, 2025

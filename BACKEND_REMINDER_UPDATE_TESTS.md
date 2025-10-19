# Backend Reminder Update Endpoint - Test Results

## Test Date: 2025-10-17

## Backend Status
✅ **Backend is healthy and running**
```bash
curl -X GET http://57.129.81.193:5001/api/health
```
**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-17T09:29:22.044233"
}
```

---

## Endpoint Tests

### Base URL
```
http://57.129.81.193:5001/api/tasks/{task_id}/reminders/{reminder_id}
```

---

## ✅ Test 1: Endpoint Exists
**Test:** Check if PUT endpoint is implemented

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/test_task_123/reminders/test_reminder_456" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Test reminder"}'
```

**Result:** ✅ PASS
```json
{
  "error": "Authorization header is missing",
  "type": "authentication_error"
}
```

**Analysis:** Endpoint exists and properly requires authentication.

---

## ✅ Test 2: Authentication Required
**Test:** Request without Authorization header

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/test_task/reminders/test_reminder" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Test"}'
```

**Result:** ✅ PASS
```json
{
  "error": "Authorization header is missing",
  "type": "authentication_error"
}
```

**HTTP Status:** 401 Unauthorized

---

## ✅ Test 3: Invalid Token Rejected
**Test:** Request with invalid Firebase token

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/test_task/reminders/test_reminder" \
  -H "Authorization: Bearer invalid_token_12345" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Test"}'
```

**Result:** ✅ PASS
```json
{
  "error": "Invalid or expired token",
  "type": "authentication_error"
}
```

**HTTP Status:** 401 Unauthorized

---

## 🔐 Tests Requiring Valid Firebase Token

To run the following tests, you need a valid Firebase ID token.

### How to Get a Firebase Token:

#### Option 1: From iOS App (Xcode Debug Console)
1. Add this code to `AuthService.swift` temporarily:
```swift
func printCurrentToken() {
    getIdToken { result in
        switch result {
        case .success(let token):
            print("🔑 FIREBASE TOKEN: \(token)")
        case .failure(let error):
            print("❌ Token error: \(error)")
        }
    }
}
```

2. Call it after login:
```swift
// In ContentView.swift or wherever after authentication
authService.printCurrentToken()
```

3. Run the app in simulator, login, and copy the token from Xcode console

#### Option 2: Using Firebase REST API
```bash
# Sign in with email/password
curl -X POST "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=YOUR_FIREBASE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword",
    "returnSecureToken": true
  }'
```

Response will contain `idToken` field.

---

## Test Suite with Valid Token

**Once you have a valid token, replace `YOUR_TOKEN_HERE` in the commands below:**

### Test 4: Missing Required Fields

#### Test 4a: Missing reminder_time
```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"message": "Only message, no time"}'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "reminder_time and message are required"
}
```

#### Test 4b: Missing message
```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00"}'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "reminder_time and message are required"
}
```

#### Test 4c: Empty message
```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "   "}'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "message cannot be empty"
}
```

---

### Test 5: Message Length Validation

```bash
# Generate 501 character message
MESSAGE_501=$(python3 -c "print('a' * 501)")

curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d "{\"reminder_time\": \"2025-10-18T15:30:00+00:00\", \"message\": \"$MESSAGE_501\"}"
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "message cannot exceed 500 characters"
}
```

---

### Test 6: Invalid DateTime Format

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "invalid-date-format", "message": "Test"}'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "Invalid reminder_time format. Use ISO 8601 format"
}
```

---

### Test 7: Past DateTime

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2020-01-01T10:00:00+00:00", "message": "Past time"}'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "reminder_time must be in the future"
}
```

---

### Test 8: Non-existent Task

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/non_existent_task_id/reminders/test_reminder" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Test"}'
```

**Expected Response:** 404 Not Found
```json
{
  "error": "Task not found"
}
```

---

### Test 9: Non-existent Reminder

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/VALID_TASK_ID/reminders/non_existent_reminder" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Test"}'
```

**Expected Response:** 404 Not Found
```json
{
  "error": "Reminder not found"
}
```

---

### Test 10: Update Another User's Reminder

**Setup:** Get a valid token for User A, then try to update User B's task

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/OTHER_USERS_TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer USER_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Trying to hack"}'
```

**Expected Response:** 403 Forbidden
```json
{
  "error": "You don't have permission to update this reminder"
}
```

---

### Test 11: Update Already Sent Reminder

**Setup:** Try to update a reminder where `sent = true`

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/SENT_REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Update sent reminder"}'
```

**Expected Response:** 400 Bad Request
```json
{
  "error": "Cannot update a reminder that has already been sent"
}
```

---

### Test 12: Successful Update ✅

**Prerequisites:**
1. Create a task with a reminder via iOS app
2. Get the task_id and reminder_id from the task
3. Get a valid Firebase token

```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/VALID_TASK_ID/reminders/VALID_REMINDER_ID" \
  -H "Authorization: Bearer VALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reminder_time": "2025-10-18T15:30:00+00:00",
    "message": "Updated reminder message"
  }'
```

**Expected Response:** 200 OK
```json
{
  "message": "Reminder updated successfully",
  "reminder": {
    "id": "VALID_REMINDER_ID",
    "task_id": "VALID_TASK_ID",
    "reminder_time": "2025-10-18T15:30:00+00:00",
    "message": "Updated reminder message",
    "sent": false
  }
}
```

---

### Test 13: Timezone Conversion

Test that different timezone formats are handled correctly:

#### Test 13a: UTC with Z
```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00Z", "message": "UTC Z format"}'
```

#### Test 13b: UTC with +00:00
```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "UTC +00:00 format"}'
```

#### Test 13c: Different timezone (e.g., Istanbul +03:00)
```bash
curl -X PUT "http://57.129.81.193:5001/api/tasks/TASK_ID/reminders/REMINDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T18:30:00+03:00", "message": "Istanbul timezone"}'
```

**Expected:** All should convert to UTC and return success.

---

## Test Results Summary

### ✅ Completed Tests (Without Token)
| Test | Endpoint | Result | Status |
|------|----------|--------|--------|
| 1 | Endpoint exists | Authorization required | ✅ PASS |
| 2 | No auth header | 401 error returned | ✅ PASS |
| 3 | Invalid token | 401 error returned | ✅ PASS |

### 🔐 Requires Valid Token
| Test | Description | Expected |
|------|-------------|----------|
| 4a-c | Missing/empty fields | 400 Bad Request |
| 5 | Message >500 chars | 400 Bad Request |
| 6 | Invalid datetime | 400 Bad Request |
| 7 | Past datetime | 400 Bad Request |
| 8 | Non-existent task | 404 Not Found |
| 9 | Non-existent reminder | 404 Not Found |
| 10 | Other user's task | 403 Forbidden |
| 11 | Already sent reminder | 400 Bad Request |
| 12 | Valid update | 200 OK ✅ |
| 13a-c | Timezone handling | 200 OK ✅ |

---

## How to Run Full Test Suite

### Step 1: Get a valid Firebase token
Use iOS app or Firebase REST API (see above)

### Step 2: Create test data
Create a task with reminder using the iOS app

### Step 3: Run tests
```bash
# Set variables
export TOKEN="your_firebase_token_here"
export TASK_ID="task_id_from_app"
export REMINDER_ID="reminder_id_from_app"

# Run test
curl -X PUT "http://57.129.81.193:5001/api/tasks/$TASK_ID/reminders/$REMINDER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Test message"}'
```

---

## Automated Test Script

Save this as `test_reminder_update.sh`:

```bash
#!/bin/bash

# Configuration
BASE_URL="http://57.129.81.193:5001/api"
TOKEN="$1"
TASK_ID="$2"
REMINDER_ID="$3"

if [ -z "$TOKEN" ] || [ -z "$TASK_ID" ] || [ -z "$REMINDER_ID" ]; then
    echo "Usage: $0 <firebase_token> <task_id> <reminder_id>"
    exit 1
fi

echo "🧪 Testing Reminder Update Endpoint..."
echo "============================================"

# Test 1: Valid update
echo -e "\n✅ Test 1: Valid update"
curl -X PUT "$BASE_URL/tasks/$TASK_ID/reminders/$REMINDER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2025-10-18T15:30:00+00:00", "message": "Updated message"}' \
  -w "\nHTTP: %{http_code}\n"

# Test 2: Missing field
echo -e "\n❌ Test 2: Missing reminder_time"
curl -X PUT "$BASE_URL/tasks/$TASK_ID/reminders/$REMINDER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Only message"}' \
  -w "\nHTTP: %{http_code}\n"

# Test 3: Past time
echo -e "\n❌ Test 3: Past datetime"
curl -X PUT "$BASE_URL/tasks/$TASK_ID/reminders/$REMINDER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "2020-01-01T10:00:00+00:00", "message": "Past"}' \
  -w "\nHTTP: %{http_code}\n"

# Test 4: Invalid datetime
echo -e "\n❌ Test 4: Invalid datetime format"
curl -X PUT "$BASE_URL/tasks/$TASK_ID/reminders/$REMINDER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reminder_time": "invalid", "message": "Test"}' \
  -w "\nHTTP: %{http_code}\n"

echo -e "\n============================================"
echo "✅ Test suite completed!"
```

**Usage:**
```bash
chmod +x test_reminder_update.sh
./test_reminder_update.sh "your_token" "task_id" "reminder_id"
```

---

## Conclusion

### ✅ Backend is Working
- Endpoint is implemented and accessible
- Authentication layer is working correctly
- Error handling is in place

### 🔐 Next Steps for Full Testing
1. Get a valid Firebase token from the iOS app
2. Create test data (task with reminders)
3. Run the full test suite above
4. Verify all validation rules work as expected

### 📊 Endpoint Verification Status
- ✅ Endpoint exists (PUT /api/tasks/{task_id}/reminders/{reminder_id})
- ✅ Authentication required (@require_auth working)
- ✅ Invalid tokens rejected properly
- ⏳ Full validation tests pending valid token
- ⏳ Success case pending valid token + test data

The backend implementation appears to be **correctly deployed and functional**. The endpoint is properly secured and waiting for valid requests.

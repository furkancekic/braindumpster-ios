# Python Backend - IAP Receipt Validation Implementation

## 🎯 Overview

Your Python backend (`http://57.129.81.193:5001/api`) needs to implement server-side Apple receipt validation for iOS In-App Purchases.

---

## 📍 Endpoint to Implement

```
POST /api/verify-receipt
```

### Required Headers:
```
Content-Type: application/json
Authorization: Bearer <firebase_auth_token>
```

### Request Body Schema:
```json
{
  "receiptData": "BASE64_ENCODED_RECEIPT",
  "userId": "firebase_uid_or_null",
  "deviceInfo": {
    "model": "iPhone15,3",
    "osVersion": "iOS 18.0",
    "locale": "en_US"
  },
  "appVersion": "1.0 (7)",
  "bundleId": "com.braindumpster.app"
}
```

### Response Schema:
```json
{
  "success": true|false,
  "isPremium": true|false,
  "productId": "brain_dumpster_yearly_premium",
  "expirationDate": "2026-10-14T12:00:00Z",
  "environment": "sandbox|production",
  "message": "Success or error message"
}
```

---

## 🔐 Implementation Steps

### 1. Parse and Validate Request

```python
from flask import Flask, request, jsonify
import base64
import hashlib
import requests
from datetime import datetime

app = Flask(__name__)

@app.route('/api/verify-receipt', methods=['POST'])
def verify_receipt():
    # 1. Authenticate request
    auth_header = request.headers.get('Authorization')
    if not auth_header or not verify_firebase_token(auth_header):
        return jsonify({
            'success': False,
            'isPremium': False,
            'message': 'Unauthorized'
        }), 401

    # 2. Parse request
    data = request.json
    receipt_data = data.get('receiptData')
    user_id = data.get('userId')
    device_info = data.get('deviceInfo', {})
    app_version = data.get('appVersion')
    bundle_id = data.get('bundleId')

    # 3. Validate required fields
    if not receipt_data:
        return jsonify({
            'success': False,
            'isPremium': False,
            'message': 'Missing receipt data'
        }), 400

    # 4. Security: Log only hash (NOT full receipt!)
    receipt_hash = hashlib.sha256(receipt_data.encode()).hexdigest()[:8]
    print(f"[ReceiptValidation] Processing receipt {receipt_hash} for user {user_id}")

    # 5. Verify with Apple
    try:
        result = verify_with_apple(receipt_data, bundle_id)
        return jsonify(result), 200 if result['success'] else 400
    except Exception as e:
        print(f"[ReceiptValidation] Error: {str(e)}")
        return jsonify({
            'success': False,
            'isPremium': False,
            'message': 'Internal server error'
        }), 500
```

---

### 2. Verify with Apple's API

```python
def verify_with_apple(receipt_data, bundle_id):
    """
    Verify receipt with Apple's servers.
    IMPORTANT: Try production first, fallback to sandbox.
    """

    # Apple's receipt verification endpoints
    PRODUCTION_URL = "https://buy.itunes.apple.com/verifyReceipt"
    SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt"

    # Your app's shared secret (get from App Store Connect)
    # NOTE: Only needed for auto-renewable subscriptions
    SHARED_SECRET = "your_app_shared_secret_here"

    payload = {
        "receipt-data": receipt_data,
        "password": SHARED_SECRET,
        "exclude-old-transactions": True  # Only get latest transactions
    }

    # Try production first
    print("[ReceiptValidation] Verifying with Apple production")
    response = requests.post(PRODUCTION_URL, json=payload, timeout=30)
    apple_response = response.json()

    status = apple_response.get('status')

    # Status 21007 = Sandbox receipt sent to production
    # This is EXPECTED during development/TestFlight
    if status == 21007:
        print("[ReceiptValidation] Sandbox receipt detected, trying sandbox")
        response = requests.post(SANDBOX_URL, json=payload, timeout=30)
        apple_response = response.json()
        status = apple_response.get('status')

    # Status 0 = Success
    if status == 0:
        return parse_apple_response(apple_response, bundle_id)
    else:
        error_message = APPLE_STATUS_CODES.get(status, f"Unknown error ({status})")
        print(f"[ReceiptValidation] Apple verification failed: {error_message}")
        return {
            'success': False,
            'isPremium': False,
            'message': error_message
        }
```

---

### 3. Parse Apple's Response

```python
def parse_apple_response(apple_response, expected_bundle_id):
    """
    Parse and validate Apple's receipt response.
    """

    receipt = apple_response.get('receipt', {})
    bundle_id = receipt.get('bundle_id')
    environment = apple_response.get('environment', 'Production')

    # Validate bundle ID
    if bundle_id != expected_bundle_id:
        print(f"[ReceiptValidation] Bundle ID mismatch: {bundle_id} != {expected_bundle_id}")
        return {
            'success': False,
            'isPremium': False,
            'message': 'Bundle ID mismatch'
        }

    # Get in-app purchases
    in_app_purchases = receipt.get('in_app', [])
    latest_receipts = apple_response.get('latest_receipt_info', [])

    # Combine both (latest_receipt_info has most recent subscriptions)
    all_purchases = in_app_purchases + latest_receipts

    if not all_purchases:
        print("[ReceiptValidation] No purchases found in receipt")
        return {
            'success': True,
            'isPremium': False,
            'message': 'No active purchases'
        }

    # Find active premium subscription/purchase
    active_product = find_active_premium(all_purchases)

    if active_product:
        return {
            'success': True,
            'isPremium': True,
            'productId': active_product['product_id'],
            'expirationDate': active_product.get('expires_date'),
            'environment': environment.lower(),
            'message': 'Receipt verified successfully'
        }
    else:
        return {
            'success': True,
            'isPremium': False,
            'message': 'No active subscriptions'
        }
```

---

### 4. Find Active Premium Subscription

```python
def find_active_premium(purchases):
    """
    Check if user has an active premium subscription.
    """

    PREMIUM_PRODUCT_IDS = [
        "brain_dumpster_monthly_premium",
        "brain_dumpster_yearly_premium",
        "brain_dumpster_lifetime_premium"
    ]

    now = datetime.utcnow()

    for purchase in purchases:
        product_id = purchase.get('product_id')

        # Check if it's a premium product
        if product_id not in PREMIUM_PRODUCT_IDS:
            continue

        # Lifetime purchase (no expiration)
        if product_id == "brain_dumpster_lifetime_premium":
            print(f"[ReceiptValidation] Found active lifetime purchase")
            return purchase

        # Subscription (check expiration)
        expires_date_ms = purchase.get('expires_date_ms')
        if expires_date_ms:
            expires_date = datetime.utcfromtimestamp(int(expires_date_ms) / 1000)

            # Check if still active
            if expires_date > now:
                print(f"[ReceiptValidation] Found active subscription: {product_id}")
                print(f"   Expires: {expires_date.isoformat()}")
                return {
                    'product_id': product_id,
                    'expires_date': expires_date.isoformat() + 'Z'
                }
            else:
                print(f"[ReceiptValidation] Subscription expired: {product_id}")

    return None
```

---

### 5. Apple Status Codes

```python
APPLE_STATUS_CODES = {
    0: "Success",
    21000: "The App Store could not read the JSON object you provided.",
    21002: "The data in the receipt-data property was malformed or missing.",
    21003: "The receipt could not be authenticated.",
    21004: "The shared secret you provided does not match the shared secret on file for your account.",
    21005: "The receipt server is not currently available.",
    21006: "This receipt is valid but the subscription has expired.",
    21007: "This receipt is from the test environment, but it was sent to the production environment for verification.",
    21008: "This receipt is from the production environment, but it was sent to the test environment for verification.",
    21009: "Internal data access error. Try again later.",
    21010: "The user account cannot be found or has been deleted."
}
```

---

### 6. Save to Database

```python
def save_subscription_status(user_id, product_id, expires_date, environment):
    """
    Save subscription status to your database.
    """

    # Example with MongoDB
    db.subscriptions.update_one(
        {'user_id': user_id},
        {
            '$set': {
                'product_id': product_id,
                'expires_date': expires_date,
                'environment': environment,
                'updated_at': datetime.utcnow(),
                'is_premium': True
            }
        },
        upsert=True
    )

    # Example with PostgreSQL
    # cursor.execute("""
    #     INSERT INTO subscriptions (user_id, product_id, expires_date, environment, is_premium)
    #     VALUES (%s, %s, %s, %s, %s)
    #     ON CONFLICT (user_id) DO UPDATE SET
    #         product_id = EXCLUDED.product_id,
    #         expires_date = EXCLUDED.expires_date,
    #         environment = EXCLUDED.environment,
    #         is_premium = EXCLUDED.is_premium,
    #         updated_at = NOW()
    # """, (user_id, product_id, expires_date, environment, True))

    print(f"[ReceiptValidation] Saved subscription for user {user_id}")
```

---

## 🔒 Security Checklist

### ✅ MUST DO:

1. **NEVER log full receipt data**
   ```python
   # ❌ BAD
   print(f"Receipt: {receipt_data}")

   # ✅ GOOD
   receipt_hash = hashlib.sha256(receipt_data.encode()).hexdigest()[:8]
   print(f"Receipt hash: {receipt_hash}")
   ```

2. **Validate bundle ID**
   ```python
   if bundle_id != "com.braindumpster.app":
       return error_response("Invalid bundle ID")
   ```

3. **Verify Firebase auth token**
   ```python
   def verify_firebase_token(auth_header):
       token = auth_header.replace('Bearer ', '')
       # Use Firebase Admin SDK to verify
       try:
           decoded_token = auth.verify_id_token(token)
           return decoded_token
       except:
           return None
   ```

4. **Use HTTPS for Apple API calls** (requests library handles this)

5. **Rate limit the endpoint**
   ```python
   from flask_limiter import Limiter

   limiter = Limiter(app, key_func=lambda: request.headers.get('Authorization'))

   @app.route('/api/verify-receipt', methods=['POST'])
   @limiter.limit("10 per minute")  # Max 10 requests per minute per user
   def verify_receipt():
       # ...
   ```

6. **Set request timeout**
   ```python
   response = requests.post(PRODUCTION_URL, json=payload, timeout=30)
   ```

---

## 🧪 Testing

### 1. Test with cURL:

```bash
curl -X POST http://57.129.81.193:5001/api/verify-receipt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer FIREBASE_AUTH_TOKEN" \
  -d '{
    "receiptData": "BASE64_RECEIPT_STRING",
    "userId": "test_user_123",
    "deviceInfo": {
      "model": "iPhone15,3",
      "osVersion": "iOS 18.0",
      "locale": "en_US"
    },
    "appVersion": "1.0 (7)",
    "bundleId": "com.braindumpster.app"
  }'
```

### 2. Expected Responses:

**Success (active subscription):**
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

**Success (no active subscription):**
```json
{
  "success": true,
  "isPremium": false,
  "message": "No active subscriptions"
}
```

**Error (invalid receipt):**
```json
{
  "success": false,
  "isPremium": false,
  "message": "The receipt could not be authenticated."
}
```

---

## 📦 Required Dependencies

```bash
pip install flask requests firebase-admin flask-limiter
```

### Import in your code:
```python
from flask import Flask, request, jsonify
import requests
import hashlib
import base64
from datetime import datetime
from firebase_admin import auth
from flask_limiter import Limiter
```

---

## 🚀 Deployment Steps

1. **Get Shared Secret from App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - App Store → Braindumpster → App Information
   - App-Specific Shared Secret → Generate

2. **Add endpoint to your Flask app**:
   - Copy code above
   - Update `SHARED_SECRET` with real value
   - Deploy to your server

3. **Test endpoint**:
   - Use cURL to test
   - Check logs for errors
   - Verify database updates

4. **Monitor in production**:
   - Log all requests (hash only!)
   - Monitor Apple API response times
   - Alert on high error rates

---

## 📊 Database Schema (Optional)

```sql
CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL,
    product_id VARCHAR(255) NOT NULL,
    expires_date TIMESTAMP,
    environment VARCHAR(50),
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_id ON subscriptions(user_id);
CREATE INDEX idx_is_premium ON subscriptions(is_premium);
```

---

## 🐛 Common Issues

### "Status 21007" in production
- This is NORMAL during TestFlight testing
- Fallback to sandbox automatically
- Will go away once app is live on App Store

### "The receipt could not be authenticated" (21003)
- Receipt is invalid or tampered with
- Ask user to restore purchases
- Check if receipt is actually from your app

### "Receipt server not available" (21005)
- Apple's servers are down (rare)
- Return 503 error to iOS
- iOS will retry automatically

### Timeout errors
- Apple's API can be slow sometimes
- Set timeout to 30s
- Return 504 error to iOS for retry

---

## 📝 Example Full Implementation

See attached: `receipt_validation_endpoint.py` (complete working example)

---

**Last Updated**: October 14, 2025
**iOS Build**: 1.0 (7)
**Backend URL**: http://57.129.81.193:5001/api

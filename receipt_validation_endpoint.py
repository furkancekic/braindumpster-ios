"""
Python Backend - Apple IAP Receipt Validation Endpoint
For Braindumpster iOS App

This is a complete working example for server-side receipt validation.
"""

from flask import Flask, request, jsonify
import requests
import hashlib
from datetime import datetime
from functools import wraps

# Initialize Flask app
app = Flask(__name__)

# Configuration
APPLE_PRODUCTION_URL = "https://buy.itunes.apple.com/verifyReceipt"
APPLE_SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt"
APP_SHARED_SECRET = "your_app_specific_shared_secret_here"  # Get from App Store Connect
EXPECTED_BUNDLE_ID = "com.braindumpster.app"

# Premium product IDs
PREMIUM_PRODUCTS = [
    "brain_dumpster_monthly_premium",
    "brain_dumpster_yearly_premium",
    "brain_dumpster_lifetime_premium"
]

# Apple status codes
APPLE_STATUS_CODES = {
    0: "Success",
    21000: "The App Store could not read the JSON object you provided",
    21002: "The data in the receipt-data property was malformed or missing",
    21003: "The receipt could not be authenticated",
    21004: "The shared secret you provided does not match",
    21005: "The receipt server is not currently available",
    21006: "This receipt is valid but the subscription has expired",
    21007: "This receipt is from the test environment",
    21008: "This receipt is from the production environment",
    21009: "Internal data access error. Try again later",
    21010: "The user account cannot be found or has been deleted"
}


def require_auth(f):
    """
    Decorator to require Firebase authentication.
    Replace with your actual Firebase auth verification.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')

        if not auth_header:
            return jsonify({
                'success': False,
                'isPremium': False,
                'message': 'Missing authorization header'
            }), 401

        # TODO: Verify Firebase token
        # try:
        #     token = auth_header.replace('Bearer ', '')
        #     decoded_token = firebase_admin.auth.verify_id_token(token)
        #     request.user_id = decoded_token['uid']
        # except Exception as e:
        #     return jsonify({
        #         'success': False,
        #         'isPremium': False,
        #         'message': 'Invalid authorization token'
        #     }), 401

        return f(*args, **kwargs)

    return decorated_function


@app.route('/api/verify-receipt', methods=['POST'])
@require_auth
def verify_receipt():
    """
    Main endpoint for receipt verification.
    """
    try:
        # Parse request body
        data = request.json
        if not data:
            return jsonify({
                'success': False,
                'isPremium': False,
                'message': 'Missing request body'
            }), 400

        receipt_data = data.get('receiptData')
        user_id = data.get('userId')
        device_info = data.get('deviceInfo', {})
        app_version = data.get('appVersion')
        bundle_id = data.get('bundleId')

        # Validate required fields
        if not receipt_data:
            return jsonify({
                'success': False,
                'isPremium': False,
                'message': 'Missing receipt data'
            }), 400

        # Security: Log only hash (NEVER log full receipt!)
        receipt_hash = hashlib.sha256(receipt_data.encode()).hexdigest()[:8]
        print(f"[ReceiptValidation] Receipt hash: {receipt_hash}")
        print(f"[ReceiptValidation] User: {user_id}")
        print(f"[ReceiptValidation] Device: {device_info.get('model')} - {device_info.get('osVersion')}")
        print(f"[ReceiptValidation] App version: {app_version}")

        # Verify bundle ID
        if bundle_id and bundle_id != EXPECTED_BUNDLE_ID:
            print(f"[ReceiptValidation] Bundle ID mismatch: {bundle_id}")
            return jsonify({
                'success': False,
                'isPremium': False,
                'message': 'Invalid bundle ID'
            }), 400

        # Verify with Apple
        result = verify_with_apple(receipt_data)

        # Save to database if successful
        if result['success'] and result['isPremium'] and user_id:
            save_subscription_status(
                user_id=user_id,
                product_id=result.get('productId'),
                expires_date=result.get('expirationDate'),
                environment=result.get('environment')
            )

        return jsonify(result), 200 if result['success'] else 400

    except requests.Timeout:
        print("[ReceiptValidation] Request to Apple timed out")
        return jsonify({
            'success': False,
            'isPremium': False,
            'message': 'Request timed out'
        }), 504

    except Exception as e:
        print(f"[ReceiptValidation] Error: {str(e)}")
        import traceback
        traceback.print_exc()

        return jsonify({
            'success': False,
            'isPremium': False,
            'message': 'Internal server error'
        }), 500


def verify_with_apple(receipt_data):
    """
    Verify receipt with Apple's servers.
    Tries production first, falls back to sandbox if needed.
    """
    payload = {
        "receipt-data": receipt_data,
        "password": APP_SHARED_SECRET,
        "exclude-old-transactions": True
    }

    # Try production first
    print("[ReceiptValidation] Verifying with Apple production")
    try:
        response = requests.post(APPLE_PRODUCTION_URL, json=payload, timeout=30)
        apple_response = response.json()
        status = apple_response.get('status')

        # Status 21007 = Sandbox receipt sent to production
        if status == 21007:
            print("[ReceiptValidation] Sandbox receipt detected, trying sandbox")
            response = requests.post(APPLE_SANDBOX_URL, json=payload, timeout=30)
            apple_response = response.json()
            status = apple_response.get('status')

        # Status 0 = Success
        if status == 0:
            print("[ReceiptValidation] Apple verification successful")
            return parse_apple_response(apple_response)
        else:
            error_message = APPLE_STATUS_CODES.get(status, f"Unknown error (status {status})")
            print(f"[ReceiptValidation] Apple verification failed: {error_message}")
            return {
                'success': False,
                'isPremium': False,
                'message': error_message
            }

    except requests.Timeout:
        print("[ReceiptValidation] Request to Apple timed out")
        raise

    except Exception as e:
        print(f"[ReceiptValidation] Error calling Apple API: {str(e)}")
        raise


def parse_apple_response(apple_response):
    """
    Parse Apple's response and extract subscription status.
    """
    receipt = apple_response.get('receipt', {})
    bundle_id = receipt.get('bundle_id')
    environment = apple_response.get('environment', 'Production')

    print(f"[ReceiptValidation] Bundle ID: {bundle_id}")
    print(f"[ReceiptValidation] Environment: {environment}")

    # Validate bundle ID
    if bundle_id != EXPECTED_BUNDLE_ID:
        print(f"[ReceiptValidation] Bundle ID mismatch")
        return {
            'success': False,
            'isPremium': False,
            'message': 'Bundle ID mismatch'
        }

    # Get in-app purchases
    in_app_purchases = receipt.get('in_app', [])
    latest_receipts = apple_response.get('latest_receipt_info', [])
    all_purchases = in_app_purchases + latest_receipts

    print(f"[ReceiptValidation] Found {len(all_purchases)} purchases")

    if not all_purchases:
        return {
            'success': True,
            'isPremium': False,
            'message': 'No purchases found'
        }

    # Find active premium subscription
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


def find_active_premium(purchases):
    """
    Check if user has an active premium subscription or lifetime purchase.
    """
    now = datetime.utcnow()

    for purchase in purchases:
        product_id = purchase.get('product_id')

        # Check if it's a premium product
        if product_id not in PREMIUM_PRODUCTS:
            continue

        print(f"[ReceiptValidation] Checking product: {product_id}")

        # Lifetime purchase (no expiration)
        if product_id == "brain_dumpster_lifetime_premium":
            print(f"[ReceiptValidation] ✅ Found active lifetime purchase")
            return {
                'product_id': product_id,
                'expires_date': None
            }

        # Subscription (check expiration)
        expires_date_ms = purchase.get('expires_date_ms')
        if expires_date_ms:
            expires_date = datetime.utcfromtimestamp(int(expires_date_ms) / 1000)

            # Check if still active
            if expires_date > now:
                print(f"[ReceiptValidation] ✅ Found active subscription: {product_id}")
                print(f"[ReceiptValidation]    Expires: {expires_date.isoformat()}")
                return {
                    'product_id': product_id,
                    'expires_date': expires_date.isoformat() + 'Z'
                }
            else:
                print(f"[ReceiptValidation] ❌ Subscription expired: {product_id}")

    print("[ReceiptValidation] No active subscriptions found")
    return None


def save_subscription_status(user_id, product_id, expires_date, environment):
    """
    Save subscription status to database.
    Replace with your actual database implementation.
    """
    print(f"[ReceiptValidation] Saving subscription for user: {user_id}")
    print(f"[ReceiptValidation]    Product: {product_id}")
    print(f"[ReceiptValidation]    Expires: {expires_date}")
    print(f"[ReceiptValidation]    Environment: {environment}")

    # TODO: Save to your database
    # Example with MongoDB:
    # db.subscriptions.update_one(
    #     {'user_id': user_id},
    #     {
    #         '$set': {
    #             'product_id': product_id,
    #             'expires_date': expires_date,
    #             'environment': environment,
    #             'is_premium': True,
    #             'updated_at': datetime.utcnow()
    #         }
    #     },
    #     upsert=True
    # )

    # Example with PostgreSQL:
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

    pass


# Health check endpoint
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200


if __name__ == '__main__':
    print("🚀 Starting Receipt Validation Server")
    print(f"   Backend URL: http://57.129.81.193:5001/api")
    print(f"   Endpoint: POST /api/verify-receipt")
    print(f"   Bundle ID: {EXPECTED_BUNDLE_ID}")
    print()
    print("⚠️  IMPORTANT: Set APP_SHARED_SECRET before deploying!")
    print()

    app.run(host='0.0.0.0', port=5001, debug=True)

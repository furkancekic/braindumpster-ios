#!/usr/bin/env python3
"""
Deploy Firestore Security Rules using the Firebase REST API
"""
import json
import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# Set up credentials
CREDENTIALS_PATH = "/Users/furkancekic/projects/braindumpster_python/firebase_config.json"
PROJECT_ID = "voicereminder-e1c91"
RULES_FILE = "/Users/furkancekic/projects/last_tasks/firestore.rules"

def get_access_token():
    """Get OAuth2 access token from service account credentials"""
    print("🔐 Loading service account credentials...")
    credentials = service_account.Credentials.from_service_account_file(
        CREDENTIALS_PATH,
        scopes=['https://www.googleapis.com/auth/cloud-platform']
    )

    # Refresh the credentials to get an access token
    credentials.refresh(Request())
    return credentials.token

def deploy_firestore_rules():
    print("📖 Reading Firestore rules...")
    with open(RULES_FILE, 'r') as f:
        rules_content = f.read()

    print("🔑 Getting access token...")
    access_token = get_access_token()

    print("🚀 Deploying Firestore rules...")

    # Step 1: Create a new ruleset
    create_ruleset_url = f"https://firebaserules.googleapis.com/v1/projects/{PROJECT_ID}/rulesets"

    ruleset_payload = {
        "source": {
            "files": [
                {
                    "name": "firestore.rules",
                    "content": rules_content
                }
            ]
        }
    }

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }

    response = requests.post(create_ruleset_url, headers=headers, json=ruleset_payload)

    if response.status_code != 200:
        print(f"❌ Failed to create ruleset: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

    ruleset_data = response.json()
    ruleset_name = ruleset_data.get("name")
    print(f"✅ Ruleset created: {ruleset_name}")

    # Step 2: Create a release that points to this ruleset
    release_url = f"https://firebaserules.googleapis.com/v1/projects/{PROJECT_ID}/releases"

    # For Firebase Rules API, the release payload structure is different
    release_payload = {
        "release": {
            "name": f"projects/{PROJECT_ID}/releases/cloud.firestore",
            "rulesetName": ruleset_name
        }
    }

    # Use PATCH to update the existing release
    patch_url = f"https://firebaserules.googleapis.com/v1/projects/{PROJECT_ID}/releases/cloud.firestore"

    response = requests.patch(patch_url, headers=headers, json=release_payload)

    if response.status_code != 200:
        print(f"❌ Failed to create/update release: {response.status_code}")
        print(f"   Response: {response.text}")
        return False

    release_data = response.json()
    print(f"✅ Rules deployed successfully!")
    print(f"   Release: {release_data.get('name')}")
    print(f"   Ruleset: {release_data.get('rulesetName')}")
    print(f"   Update time: {release_data.get('updateTime')}")

    return True

if __name__ == "__main__":
    try:
        success = deploy_firestore_rules()
        exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Error: {e}")
        print(f"   Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        exit(1)

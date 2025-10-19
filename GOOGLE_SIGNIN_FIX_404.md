# 🔧 Google Sign In 404 Error - Fix Guide

## Problem
Google Sign In gives a 404 error when users try to sign in.

## Root Cause
The 404 error means Google's OAuth servers cannot find your OAuth client configuration. This happens when:
1. iOS OAuth client is not created in Google Cloud Console
2. Bundle ID doesn't match
3. OAuth consent screen is not configured/published
4. Client ID is incorrect or deleted

---

## ✅ Solution: Configure Google Cloud Console

### Step 1: Go to Google Cloud Console

1. Open: https://console.cloud.google.com
2. Select project: **voicereminder-e1c91**
3. If you don't have access, you need to use the Google account that owns this Firebase project

**⚠️ NOT**: API Library'de arama yapmana gerek yok! Firebase Authentication zaten Google Sign-In'i destekliyor. Direkt OAuth consent screen'e geç.

---

### Step 2: Configure OAuth Consent Screen

1. Go to: **APIs & Services** → **OAuth consent screen**
2. Select **User Type**:
   - **External** (for public users)
   - Click **CREATE**

3. Fill in **App Information**:
   - **App name**: `Braindumpster`
   - **User support email**: Your email
   - **App logo**: (optional) Upload app icon
   - **Developer contact email**: Your email

4. **Scopes**:
   - Click **ADD OR REMOVE SCOPES**
   - Add these scopes:
     - `userinfo.email`
     - `userinfo.profile`
     - `openid`
   - Click **SAVE AND CONTINUE**

5. **Test users** (if app is not published):
   - Click **ADD USERS**
   - Add your email and test user emails
   - Click **SAVE AND CONTINUE**

6. **Summary**:
   - Review everything
   - Click **BACK TO DASHBOARD**

7. **Publish App** (important!):
   - Click **PUBLISH APP** button
   - Confirm publication
   - Status should change to **"In production"**

---

### Step 3: Create iOS OAuth Client

1. Go to: **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS**
3. Select **OAuth client ID**
4. **Application type**: Select **iOS**
5. Fill in details:
   - **Name**: `Braindumpster iOS`
   - **Bundle ID**: `com.braindumpster.app`
     - ⚠️ MUST match exactly with your Xcode bundle ID!
   - **App Store ID**: Leave empty (not needed for testing)
   - **Team ID**: Leave empty (not needed for testing)
6. Click **CREATE**

7. **Download the client ID**:
   - You'll see a client ID like: `28669271299-xxxxx.apps.googleusercontent.com`
   - ✅ This should match the one in your `Info.plist`

---

### Step 4: Verify Configuration

After creating the iOS OAuth client, verify these settings:

#### In Google Cloud Console:
1. **Credentials** page should show:
   - ✅ iOS OAuth client with Bundle ID: `com.braindumpster.app`
   - ✅ Web OAuth client (created by Firebase)
   - ✅ OAuth consent screen status: **Published**

#### In Xcode Info.plist:
1. `GIDClientID` should be:
   ```
   28669271299-u56r6vaqfqc95fmm28ojivl64qpbvbfi.apps.googleusercontent.com
   ```

2. `CFBundleURLSchemes` should contain:
   ```
   com.googleusercontent.apps.28669271299-u56r6vaqfqc95fmm28ojivl64qpbvbfi
   ```

3. `CFBundleIdentifier` should be:
   ```
   com.braindumpster.app
   ```

---

### Step 5: Test Google Sign In

1. **Clean Build**:
   ```
   ⌘ + Shift + K
   ```

2. **Run on Simulator**:
   ```
   ⌘ + R
   ```

3. **Test Sign In**:
   - Tap **"Sign in with Google"**
   - Google sign in popup should appear
   - Select a Google account
   - Should authenticate successfully

4. **Check Console Logs**:
   ```
   ✅ Successful logs:
   - No 404 errors
   - User signed in successfully

   ❌ If still failing:
   - Check error domain and code in console
   - Verify Bundle ID matches exactly
   - Wait 5-10 minutes for Google to propagate changes
   ```

---

## 🐛 Common Issues

### Issue 1: "OAuth consent screen not published"
**Solution**: Go to OAuth consent screen → Click **PUBLISH APP**

### Issue 2: "Bundle ID mismatch"
**Error**: `Bundle ID does not match`
**Solution**:
1. Check Bundle ID in Xcode: `com.braindumpster.app`
2. Check OAuth client in Google Cloud Console
3. They must match EXACTLY (case-sensitive)

### Issue 3: "Client ID not found"
**Solution**:
1. Verify iOS OAuth client exists in Credentials
2. Copy the iOS client ID
3. Update `GIDClientID` in Info.plist if different

### Issue 4: "Still getting 404 after configuration"
**Solution**:
1. Wait 5-10 minutes for Google's servers to propagate changes
2. Clear app cache: Delete app from simulator and reinstall
3. Try again

### Issue 5: "App is not verified"
**This is normal for testing!**
- During development, Google shows "This app isn't verified"
- Users can click "Advanced" → "Go to Braindumpster (unsafe)"
- This warning disappears after app verification (takes a few days after publishing consent screen)

---

## 📱 Testing on Real Device

After fixing Google Cloud Console:

1. **Archive & Install** on real iPhone
2. **Tap "Sign in with Google"**
3. **Safari will open** for Google authentication
4. **Sign in with Google account**
5. **App will open** and authenticate successfully

---

## ✅ Success Criteria

You've fixed the issue when:
- ✅ No 404 errors in console
- ✅ Google sign in popup appears
- ✅ Can select Google account
- ✅ Returns to app after authentication
- ✅ User is signed in successfully
- ✅ Console shows: `✅ User signed in successfully: [email]`

---

## 📞 Still Not Working?

1. **Share Console Logs**:
   - Run the app
   - Tap "Sign in with Google"
   - Copy ALL console output starting with:
     ```
     ❌ Google Sign In Error:
        Error: ...
        Domain: ...
        Code: ...
     ```

2. **Check These**:
   - Bundle ID in Xcode matches Google Cloud Console
   - OAuth consent screen is **Published** (not in draft/testing)
   - iOS OAuth client exists with correct Bundle ID
   - GIDClientID in Info.plist matches iOS client ID from Google Cloud

3. **Wait**:
   - After making changes in Google Cloud Console, wait 5-10 minutes
   - Google's OAuth servers need time to propagate configuration

---

**Current Configuration**:
- **Project ID**: voicereminder-e1c91
- **Bundle ID**: com.braindumpster.app
- **Client ID**: 28669271299-u56r6vaqfqc95fmm28ojivl64qpbvbfi.apps.googleusercontent.com

**Last Updated**: October 13, 2025

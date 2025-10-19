# App Store Connect Metadata - Required Updates

## ❌ PROBLEM: Terms of Use (EULA) Missing

Apple requires that apps with auto-renewable subscriptions include a link to Terms of Use (EULA) in the App Store metadata.

---

## ✅ SOLUTION: Add to App Description

### Go to App Store Connect:
1. Open: https://appstoreconnect.apple.com
2. Select **Braindumpster**
3. Go to **App Store** tab
4. Edit **App Description**

### Add This Text to the END of Your App Description:

```
Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: [Your app already has this in-app]

Subscriptions:
• Monthly Premium: $9.99/month - Billed monthly, auto-renews
• Yearly Premium: $49.99/year - Billed annually, auto-renews, save 50%
• Lifetime Premium: $99.99 - One-time payment, lifetime access

Payment will be charged to your iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period. Your account will be charged for renewal within 24-hours prior to the end of the current period. Subscriptions may be managed by the user and auto-renewal may be turned off by going to the user's Account Settings after purchase.
```

---

## ALTERNATIVE: Upload Custom EULA (Optional)

If you want a custom EULA instead of Apple's standard one:

1. Go to **App Information** section in App Store Connect
2. Scroll to **License Agreement** section
3. Click **Edit**
4. Paste your custom Terms of Service text (from TermsOfServiceView.swift)
5. Click **Save**

**Recommended**: Use Apple's standard EULA (easier and faster approval).

---

## ✅ Privacy Policy

Your app already has Privacy Policy in-app (PrivacyPolicyView), which is good!

But also add to App Store Connect:
1. **App Privacy** tab → Review privacy details
2. Make sure all fields are filled correctly

---

## Next Steps After Metadata Update:

1. ✅ Add Terms of Use link to App Description
2. ✅ Add subscription details to App Description
3. ✅ Fix IAP receipt validation bug (see below)
4. ✅ Resubmit build to App Store Review

---

# IAP Receipt Validation Fix

See NativeStoreManager updates in the code.

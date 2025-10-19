# Response to Apple App Review - IAP Issue

## Message to Send via App Store Connect Resolution Center:

---

**Subject:** In-App Purchases Implementation Clarification

Dear App Review Team,

Thank you for reviewing our app submission. We'd like to clarify the in-app purchase implementation:

### **In-App Purchases ARE Implemented**

Our app implements in-app purchases using **RevenueCat SDK with StoreKit**, and the purchases can be accessed through the following navigation:

**Navigation Steps:**
1. Launch app and sign in
2. Tap Settings icon (⚙️) in top-right corner
3. Scroll to "Premium" section
4. Tap "Upgrade to Premium" button (with 👑 icon)
5. Premium screen displays all 3 subscription options with pricing

### **Product IDs:**
- **Monthly Premium:** `brain_dumpster_monthly_premium`
- **Yearly Premium:** `brain_dumpster_yearly_premium`
- **Lifetime Premium:** `brain_dumpster_lifetime_premium`

### **Current Issue:**

We submitted these in-app purchase products separately for review (they are currently in "Waiting for Review" status), before understanding they must be submitted together with the app version.

We believe this is why the reviewer could not see the products, as they are:
1. Not yet approved by Apple
2. Not linked to this app version submission

### **Resolution Request:**

Could you please either:

**Option A:** Approve the in-app purchase products currently in "Waiting for Review" status, so they become available for the app to fetch via StoreKit

**OR**

**Option B:** Allow us to cancel the separate IAP submissions and resubmit them properly linked to this app version

### **Technical Details:**

- **SDK:** RevenueCat 4.43.8 with StoreKit 2
- **Implementation:** StoreManager.swift (Lines 1-400+)
- **Entitlement ID:** "Pro"
- **Configuration:** All products correctly configured in both RevenueCat dashboard and App Store Connect
- **Testing:** Verified working in sandbox environment with StoreKit Configuration file

### **Code Verification:**

The implementation is complete and functional. The only blocker is that the products are pending Apple's approval and not yet fetchable via StoreKit in the production environment.

We apologize for the confusion regarding the submission workflow. We're happy to provide any additional information, screenshots, or make any adjustments needed.

Thank you for your patience and assistance.

Best regards,
Braindumpster Development Team

---

## Attachments to Include:

1. Screenshot of Premium screen showing the 3 subscription options (take from simulator with StoreKit Configuration)
2. Screenshot showing navigation: Settings → "Upgrade to Premium" button
3. Screenshot of App Store Connect showing the 3 IAPs in "Waiting for Review" status

---

## Alternative: If You Can Cancel IAP Submissions

If you're able to cancel the IAP submissions:

1. Go to App Store Connect → In-App Purchases
2. Open each product (Monthly, Yearly, Lifetime)
3. Scroll to bottom and click "Cancel Submission"
4. Once all are back to "Ready to Submit"
5. Go to your app version page (1.0 Prepare for Submission)
6. In "In-App Purchases and Subscriptions" section, click "Select In-App Purchases or Subscriptions"
7. Select all 3 products
8. Save and resubmit the entire app version

Then send a much simpler message:

"Dear App Review Team,

We have now correctly linked our in-app purchases to this app version.
Please re-review the submission.

Thank you!"

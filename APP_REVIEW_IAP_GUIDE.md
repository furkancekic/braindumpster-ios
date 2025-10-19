# In-App Purchase Location Guide for App Review

## How to Find In-App Purchases in Braindumpster

### Navigation Steps:

1. **Launch the app** and complete sign-in
2. **Tap the Settings icon** (gear icon) in the top-right corner of the main screen
3. **Scroll down** to the "Premium" section
4. **Tap "Upgrade to Premium"** button (has a crown icon 👑)
5. **Premium screen appears** with 3 subscription options:
   - Monthly Premium ($9.99/month)
   - Yearly Premium ($49.99/year) - Shows "MOST POPULAR" badge
   - Lifetime Premium ($99.99 one-time) - Shows "BEST VALUE" badge

### Product IDs:
- Monthly: `brain_dumpster_monthly_premium`
- Yearly: `brain_dumpster_yearly_premium`
- Lifetime: `brain_dumpster_lifetime_premium`

### Features Unlocked:
- Unlimited task creation
- AI-powered suggestions
- Voice input
- Advanced analytics
- Smart reminders
- Cloud sync

### Testing Notes:
- Uses RevenueCat SDK for subscription management
- Supports purchase restoration via "Restore Purchases" button
- All transactions go through StoreKit
- Entitlement ID: "Pro"

## Screenshot Locations:
Settings → Premium Button → Premium Screen with 3 plans

## Contact:
If you need a demo account or have questions, please let us know.

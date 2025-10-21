# App Review Testing Instructions

## Testing In-App Purchases

### Sandbox Test Account
**Email:** braindumpster-sandbox@test.com
**Password:** TestBrain2025!

### Testing Steps

1. **Sign out from your personal App Store account**
   - Settings → App Store → Tap your name → Sign Out

2. **Launch Braindumpster app**
   - The app should open normally

3. **Navigate to Premium**
   - Tap "Settings" from the home screen
   - Tap "Go Premium" or the Premium section

4. **Select a subscription plan**
   - Choose any plan (Yearly, Monthly, or Lifetime)
   - Tap "Start Your Premium Journey"

5. **Sign in with sandbox account**
   - When prompted, use the sandbox credentials above
   - Complete the test purchase (no charge)

6. **Verify premium access**
   - Premium features should unlock immediately
   - Settings should show "Premium Member" badge

### Expected Behavior
- ✅ Products load successfully
- ✅ Purchase flow completes without errors
- ✅ Premium status updates immediately
- ✅ User can access all premium features

### Account Deletion Testing

1. **Navigate to Settings**
2. **Scroll to "Danger Zone" section**
3. **Tap "Delete Account"**
4. **Confirm deletion**
5. **Expected:** User is logged out and all data is deleted

---

## Important Notes

### Backend Integration
- The app uses server-side receipt validation
- Backend URL: http://57.129.81.193:5001
- All purchases are validated with Apple's servers
- Webhook integration for real-time subscription updates

### Privacy & Data
- Users can delete their account from Settings
- Account deletion removes all user data
- Privacy Policy: https://braindumpster.com/privacy
- Terms of Service: https://braindumpster.com/terms

### Subscription Management
- Users can manage subscriptions through Settings → Manage Subscription
- Subscriptions can be cancelled anytime
- Access continues until expiration date

---

## Contact Information
For any questions during review:
- Developer Email: support@braindumpster.com
- Technical Support: Available 24/7

Thank you for reviewing Braindumpster! 🙏

# HeartLog In-App Purchase Setup Guide

This guide covers the remaining manual steps needed to complete the In-App Purchase implementation.

## ✅ Already Implemented

The following code changes have been completed:

- ✅ `PurchaseManager.swift` - StoreKit 2 integration
- ✅ `PaywallView.swift` - Premium upgrade UI
- ✅ `Configuration.storekit` - Local testing configuration
- ✅ `HeartLogApp.swift` - PurchaseManager injection
- ✅ `CalendarView.swift` - Statistics feature gating
- ✅ `NoteSheet.swift` - Emotion Tags feature gating
- ✅ `ConflictEditorView.swift` - Emotion display gating
- ✅ `SettingsView.swift` - Premium section
- ✅ `Localizable.xcstrings` - All premium strings

---

## 📋 Required Manual Steps

### Step 1: Add Files to Xcode Project

If the new files aren't visible in Xcode:

1. Open `HeartLog.xcodeproj` in Xcode
2. Right-click on the "HeartLog" folder in the Project Navigator
3. Select "Add Files to HeartLog..."
4. Navigate to the HeartLog folder and add:
   - `PurchaseManager.swift`
   - `PaywallView.swift`
   - `Configuration.storekit`
5. Ensure "Copy items if needed" is checked
6. Click "Add"

### Step 2: Add In-App Purchase Capability

1. In Xcode, select the **HeartLog** target (top of the project navigator)
2. Go to the **"Signing & Capabilities"** tab
3. Click the **"+ Capability"** button
4. Search for and add **"In-App Purchase"**

### Step 3: Configure StoreKit Testing

1. In Xcode menu, go to **Product → Scheme → Edit Scheme...**
2. Select **"Run"** from the left sidebar
3. Go to the **"Options"** tab
4. Under **"StoreKit Configuration"**, select **"Configuration.storekit"**
5. Click "Close"

---

## 🧪 Local Testing (Simulator/Device)

### Build and Run

1. Build and run the app in the iOS Simulator or on a device
2. The StoreKit configuration will simulate the purchase flow

### Testing Free User Experience

As a free user, verify:

- [ ] Tap "Total Conflicts" → Shows paywall with lock icon and purple border
- [ ] Open NoteSheet → Shows "Unlock Emotion Tags" button
- [ ] Emotion tags section shows lock icon
- [ ] Settings shows "Upgrade to Premium" and "Restore Purchases"
- [ ] ConflictEditorView doesn't display emotion tags

### Testing Purchase Flow

1. Tap "Upgrade to Premium" or any locked feature
2. Paywall appears with three features listed
3. Product loads showing "$4.99"
4. Tap "Purchase Premium"
5. Confirm the simulated purchase
6. Paywall dismisses automatically
7. All premium features unlock

### Testing Premium User Experience

After purchasing, verify:

- [ ] "Total Conflicts" button has normal border (no lock icon)
- [ ] Tapping "Total Conflicts" opens StatisticsView
- [ ] NoteSheet shows emotion tag chips
- [ ] Can select and save emotion tags
- [ ] Emotion tags display in ConflictEditorView
- [ ] Settings shows "Premium: Active" with checkmark

### Testing Persistence

1. Force quit the app (swipe up in App Switcher)
2. Relaunch the app
3. Verify premium status is still active
4. All premium features should remain unlocked

### Testing Restore Purchases

1. In Xcode, go to **Debug → StoreKit → Manage Transactions...**
2. Delete all transactions
3. Relaunch the app (premium status should be gone)
4. Go to Settings → Tap "Restore Purchases"
5. Alert shows "No previous purchases found"
6. Re-purchase premium
7. Force quit and relaunch
8. Go to Settings → Tap "Restore Purchases"
9. Alert shows "Purchases successfully restored!"

---

## 🚀 App Store Connect Setup

**Complete these steps before submitting to the App Store:**

### 1. Create In-App Purchase Product

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **HeartLog** app
3. Go to **"In-App Purchases"** section
4. Click the **"+"** button to create a new product
5. Select **"Non-Consumable"**

### 2. Configure Product Details

Fill in the following information:

**Product Information:**
- **Product ID**: `com.jeongpei.knotnot.premium.lifetime`
- **Reference Name**: `HeartLog Premium`
- **Product ID**: Must match exactly (this is what the code uses)

**Pricing:**
- Select **"Price Schedule"**
- Set price to **$4.99 USD** (Tier 5)
- Or adjust as desired

**Localization (English):**
- **Display Name**: `HeartLog Premium`
- **Description**:
  ```
  Unlock all premium features with a one-time purchase. Get iCloud sync, detailed statistics, and emotion tracking.
  ```

**Optional - Add Chinese Localization:**
- **Display Name**: `HeartLog 高级版`
- **Description**: `一次性购买解锁所有高级功能。获得 iCloud 同步、详细统计和情绪追踪。`

### 3. Review Information

**Screenshot:**
- Take a screenshot of the PaywallView showing the three features
- Upload to "Review Information" section

**Review Notes:**
```
Premium features unlocked with this purchase:
1. Statistics & Analytics - Detailed charts and insights
2. Emotion Tags - Track emotional states in notes
3. iCloud Sync - Synchronize across devices

Test flow:
1. Tap "Total Conflicts" or "Upgrade to Premium" in Settings
2. Complete purchase
3. All features unlock immediately
```

### 4. Submit for Review

1. Click **"Submit for Review"**
2. Wait for Apple's approval (typically 24-48 hours)
3. Once approved, the IAP will be live when your app is approved

---

## 🔍 Troubleshooting

### Product Not Loading

**Symptom:** Paywall shows loading spinner forever

**Solution:**
- Ensure Configuration.storekit is selected in scheme settings
- Clean build folder (Product → Clean Build Folder)
- Restart Xcode

### Premium Status Not Persisting

**Symptom:** Premium unlocks but resets after app restart

**Solution:**
- Check that UserDefaults is saving correctly
- Verify transaction listener is active
- Check Console for error messages

### Build Errors

**Symptom:** Cannot find 'PurchaseManager' in scope

**Solution:**
- Ensure all new files are added to the Xcode target
- Clean build folder and rebuild
- Check that files are in the correct directory

### StoreKit Testing Issues

**Symptom:** "Configuration file not found" error

**Solution:**
1. Go to Product → Scheme → Edit Scheme
2. Verify Configuration.storekit is selected
3. If not listed, close Xcode and reopen
4. Re-add Configuration.storekit to scheme

---

## 📱 Production Release Checklist

Before releasing to App Store:

- [ ] In-App Purchase created in App Store Connect
- [ ] Product ID matches: `com.jeongpei.knotnot.premium.lifetime`
- [ ] Price set to desired amount ($4.99 recommended)
- [ ] Review information submitted
- [ ] Screenshot uploaded
- [ ] All features tested in TestFlight
- [ ] Restore purchases tested
- [ ] Tested on multiple devices/OS versions

---

## 💡 Product Information

**Product ID:** `com.jeongpei.knotnot.premium.lifetime`

**Type:** Non-Consumable (one-time purchase)

**Pricing:** $4.99 USD (Tier 5) - Adjustable

**Features Unlocked:**
1. **Statistics & Analytics** - Detailed charts and insights
2. **Emotion Tags** - Track emotional states in notes
3. **iCloud Sync** - Seamless device synchronization

---

## 📞 Support

If you encounter issues:

1. Check the Console logs in Xcode for error messages
2. Review the PurchaseManager implementation
3. Verify StoreKit configuration is correct
4. Test in both Simulator and real device

---

## 🎉 Success Criteria

Your implementation is working correctly when:

✅ Free users see lock icons on premium features
✅ Paywall appears when tapping locked features
✅ Purchase flow completes successfully
✅ Premium status persists after app restart
✅ Restore purchases works reliably
✅ All three features unlock after purchase
✅ Settings shows correct premium status

---

**Last Updated:** January 2026
**Implementation Status:** Code Complete - Manual Setup Required

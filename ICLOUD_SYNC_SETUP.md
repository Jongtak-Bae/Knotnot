# iCloud Sync Setup Guide

**Branch:** `feature/icloud-sync`
**Date:** 2026-01-17

---

## Overview

This branch implements iCloud sync for the Knotnot app, allowing conflict data to automatically sync across devices signed in with the same iCloud account.

---

## ✅ Code Changes Completed

The following code changes have been implemented:

1. **Persistence.swift** - Upgraded to use `NSPersistentCloudKitContainer`
   - Switched from local-only Core Data to CloudKit-enabled storage
   - Added CloudKit container configuration
   - Implemented automatic merge policies for conflict resolution
   - Added CloudKit sync event monitoring
   - Added iCloud status checking method

---

## 🔧 Required Xcode Configuration

**IMPORTANT:** You must complete these steps in Xcode for iCloud sync to work:

### Step 1: Enable iCloud Capability

1. Open `Knotnot.xcodeproj` in Xcode
2. Select your project in the navigator
3. Select the **HeartLog** target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability** button
6. Select **iCloud**
7. In the iCloud section, ensure these are checked:
   - ☑️ **CloudKit**
   - ☑️ **CloudKit Dashboard** (optional, for viewing data)
8. Xcode will automatically create a CloudKit container like:
   - `iCloud.com.yourteam.Knotnot` (or similar)
   - **Write down this exact container ID**

### Step 2: Enable Background Modes

1. While still in **Signing & Capabilities**
2. Click **+ Capability** button again
3. Select **Background Modes**
4. In the Background Modes section, check:
   - ☑️ **Remote notifications**

**Why:** CloudKit needs this to notify your app when data changes on other devices.

### Step 3: Update CloudKit Container Identifier

1. Open `HeartLog/Persistence.swift`
2. Find line 32:
   ```swift
   containerIdentifier: "iCloud.com.yourteam.Knotnot"
   ```
3. Replace `"iCloud.com.yourteam.Knotnot"` with your **actual container ID** from Step 1
4. For example, if Xcode created `iCloud.com.example.Knotnot`, use:
   ```swift
   containerIdentifier: "iCloud.com.example.Knotnot"
   ```

### Step 4: Configure Team & Signing

1. Still in **Signing & Capabilities**
2. Ensure **Team** is set to your Apple Developer account
3. Ensure **Automatically manage signing** is checked
4. Verify no signing errors appear

---

## 📱 Testing iCloud Sync

### Testing Checklist

- [ ] Build and run on Device/Simulator 1
- [ ] Create a conflict entry
- [ ] Build and run on Device/Simulator 2 (signed in with SAME iCloud account)
- [ ] Verify the conflict appears on Device 2 (may take a few seconds)
- [ ] Edit the conflict on Device 2
- [ ] Verify the change appears on Device 1
- [ ] Delete a conflict on either device
- [ ] Verify it deletes on the other device

### Testing Requirements

1. **Two devices or simulators** both signed in with the **same iCloud account**
2. **Internet connection** on both devices
3. **iCloud Drive enabled** in device settings

### Console Monitoring

When sync happens, you'll see console logs:
```
☁️ CloudKit sync event: import
☁️ CloudKit sync event: export
```

If there are errors:
```
⚠️ CloudKit sync error: [error description]
```

---

## 🚨 Common Issues & Solutions

### Issue: "No iCloud account" error

**Solution:**
- Go to Settings → [Your Name] → iCloud
- Ensure you're signed in
- Enable iCloud Drive

### Issue: Container identifier error

**Solution:**
- Double-check the container ID in `Persistence.swift` line 32 matches exactly what's in Xcode capabilities
- No typos, correct capitalization

### Issue: Sync not happening

**Solutions:**
1. Check internet connection
2. Verify both devices use the same iCloud account
3. Check console for CloudKit errors
4. Try clean build (Cmd+Shift+K)
5. Check iCloud storage isn't full

### Issue: Build errors after adding capabilities

**Solution:**
- Clean build folder (Cmd+Shift+K)
- Restart Xcode
- Ensure Signing & Capabilities shows no errors

---

## 📊 CloudKit Dashboard

You can view and manage your CloudKit data:

1. Go to https://icloud.developer.apple.com/dashboard
2. Sign in with your Apple Developer account
3. Select your container
4. View **Schema** (data structure)
5. View **Data** (actual records)
6. Monitor **Logs** (sync activity)

**Note:** Use the Development environment during testing.

---

## 🔒 Privacy & Security

- All data is **encrypted** in iCloud
- Only accessible to devices signed in with **the same iCloud account**
- You should update your **App Privacy Policy** to mention:
  - "This app uses iCloud to sync your data across your devices"
  - "Data is stored securely in your personal iCloud account"

---

## 📝 User-Facing Features to Consider

### Optional: Add iCloud Status UI

You could add a settings screen showing:
- ✅ "iCloud Sync: Active"
- ⚠️ "iCloud Sync: Not signed in"
- ℹ️ Last sync time

Use the `checkiCloudStatus()` method in `Persistence.swift`:

```swift
PersistenceController.shared.checkiCloudStatus { available, message in
    if available {
        print("✅ iCloud available")
    } else {
        print("⚠️ \(message ?? "Unknown error")")
        // Show alert to user
    }
}
```

---

## 🔄 Migration for Existing Users

When users update to this version:

1. **Existing local data is preserved**
2. On first launch, local data automatically uploads to iCloud
3. From then on, data syncs bidirectionally
4. **No data loss** - it's additive

---

## 📋 Checklist Before Merging

- [ ] Xcode capabilities configured (iCloud + Background Modes)
- [ ] CloudKit container ID updated in `Persistence.swift`
- [ ] Tested on at least 2 devices with same iCloud account
- [ ] Verified create/edit/delete all sync correctly
- [ ] No CloudKit errors in console
- [ ] App Privacy Policy updated

---

## 🚀 Deployment Notes

### TestFlight / App Store

When you submit to App Store:

1. CloudKit will automatically use **Production** environment
2. Development and Production have separate databases
3. Test data won't appear in production
4. Users need iOS 13+ (you're targeting 17.0, so ✅)

---

## 📞 Support

If you encounter issues:

1. Check console logs for CloudKit errors
2. Verify all setup steps completed
3. Check Apple's CloudKit status: https://www.apple.com/support/systemstatus/
4. Review CloudKit Dashboard for errors

---

## 🎯 Next Steps

1. Complete Xcode configuration (Steps 1-4 above)
2. Update container ID in `Persistence.swift`
3. Test sync between devices
4. Verify all functionality works
5. If all good, merge to main branch

---

**Questions?** Refer to Apple's documentation:
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CloudKit Documentation](https://developer.apple.com/icloud/cloudkit/)

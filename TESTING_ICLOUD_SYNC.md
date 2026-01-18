# iCloud Sync Testing Guide

**Date:** 2026-01-17
**CloudKit Container:** `iCloud.com.jeongpei.Knotnot`

---

## Pre-Testing Checklist

Before you start testing, verify:

- [ ] ✅ Xcode capabilities configured (iCloud + CloudKit + Background Modes)
- [ ] ✅ Container ID updated to `iCloud.com.jeongpei.Knotnot` (DONE)
- [ ] ✅ App builds without errors
- [ ] You have 2 devices OR 2 simulators ready
- [ ] Both devices will be signed in with THE SAME iCloud account

---

## Setup Test Environment

### Option A: Two Physical Devices (Recommended)

1. **Device 1 (e.g., your iPhone)**
   - Go to Settings → [Your Name] → iCloud
   - Verify you're signed in
   - Enable **iCloud Drive**
   - Note the email address

2. **Device 2 (e.g., iPad or another iPhone)**
   - Go to Settings → [Your Name] → iCloud
   - **Must be signed in with SAME email as Device 1**
   - Enable **iCloud Drive**

### Option B: Two Simulators

1. **Simulator 1:**
   - Open Xcode → Window → Devices and Simulators
   - Boot a simulator (e.g., iPhone 15 Pro)
   - Settings → Sign in with iCloud (use your test Apple ID)

2. **Simulator 2:**
   - Boot another simulator (e.g., iPhone 15)
   - Settings → Sign in with iCloud (**SAME Apple ID as Simulator 1**)

**⚠️ Important:** Both must use the EXACT same iCloud account!

---

## Testing Procedure

### Test 1: Initial Sync (Create)

**On Device 1:**

1. Build and run the app from Xcode
2. Watch the **Xcode console** - you should see:
   ```
   ☁️ CloudKit sync event: setup
   ☁️ CloudKit sync event: export
   ```
3. Create a new conflict:
   - Tap a date in calendar view
   - Set intensity (e.g., Moderate)
   - Add a note: "Test conflict from Device 1"
   - Save

4. **Watch console** - should see:
   ```
   ☁️ CloudKit sync event: export
   ```

**On Device 2:**

5. Build and run the app
6. **Wait 5-10 seconds** (sync may take a moment)
7. Watch console for:
   ```
   ☁️ CloudKit sync event: import
   ```
8. **Verify:** The conflict you created on Device 1 appears!

**✅ Pass Criteria:**
- Conflict appears on Device 2 within 10 seconds
- Same date, intensity, and note text
- No errors in console

---

### Test 2: Edit Sync

**On Device 2:**

1. Tap the conflict that synced from Device 1
2. Edit the note: "Updated from Device 2"
3. Save
4. Watch console for: `☁️ CloudKit sync event: export`

**On Device 1:**

5. **Wait 5-10 seconds**
6. Watch console for: `☁️ CloudKit sync event: import`
7. **Verify:** The note updates to "Updated from Device 2"

**✅ Pass Criteria:**
- Edit appears on Device 1 within 10 seconds
- Changes are correct

---

### Test 3: Delete Sync

**On Device 1:**

1. Go to Calendar view
2. Tap a conflict to select it
3. Tap the delete button (trash icon)
4. Confirm deletion
5. Watch console for: `☁️ CloudKit sync event: export`

**On Device 2:**

6. **Wait 5-10 seconds**
7. Watch console for: `☁️ CloudKit sync event: import`
8. **Verify:** The conflict disappears from Device 2

**✅ Pass Criteria:**
- Deletion syncs to Device 2 within 10 seconds

---

### Test 4: Conflict Resolution (Both devices edit same data)

**Setup:**
1. Create a conflict on Device 1
2. Wait for it to sync to Device 2

**On Device 1 (OFFLINE):**
3. Turn OFF WiFi/Airplane mode
4. Edit the conflict: "Changed on Device 1 offline"
5. Save
6. Console should show: (may queue for sync)

**On Device 2 (ONLINE):**
7. Edit the SAME conflict: "Changed on Device 2 online"
8. Save
9. Should sync immediately

**On Device 1:**
10. Turn WiFi back ON
11. App will sync
12. **Verify:** Due to merge policy, changes should merge
    - The most recent edit wins (Device 2's change)
    - OR both edits are preserved depending on timing

**✅ Pass Criteria:**
- No app crash
- Data doesn't get corrupted
- Eventually both devices show consistent data

---

### Test 5: Offline Queue

**On Device 1:**

1. Turn ON Airplane mode
2. Create 3 new conflicts
3. Console may show errors (expected - no network)

**Still on Device 1:**

4. Turn OFF Airplane mode
5. **Wait 10-20 seconds**
6. Watch console - should see multiple `export` events
7. All 3 conflicts should upload

**On Device 2:**

8. Watch console for `import` events
9. **Verify:** All 3 conflicts appear

**✅ Pass Criteria:**
- Offline changes queue and sync when network returns
- No data loss

---

## Console Monitoring

### Expected Console Logs

**Success:**
```
☁️ CloudKit sync event: setup
☁️ CloudKit sync event: export
☁️ CloudKit sync event: import
```

**Errors (Investigate these):**
```
⚠️ CloudKit sync error: "CKErrorDomain Code=9"
```

---

## Common Issues & Solutions

### Issue: No sync happening

**Debug Steps:**

1. Check console for errors
2. Verify BOTH devices use SAME iCloud account:
   ```
   Settings → [Your Name] → iCloud → Check email
   ```
3. Verify iCloud Drive is ON
4. Check internet connection
5. Try:
   - Kill app completely
   - Restart device
   - Rebuild from Xcode

### Issue: "CKErrorDomain Code=9" (Not Authenticated)

**Solution:**
- Device is not signed into iCloud
- Sign in: Settings → Sign in to [Device]

### Issue: "CKErrorDomain Code=11" (Unknown Item)

**Solution:**
- CloudKit schema might not be set up yet
- Wait a few minutes for CloudKit to initialize
- Try creating a conflict again

### Issue: Sync is slow (>30 seconds)

**Reasons:**
- Poor network connection
- CloudKit servers busy
- Too much data to sync

**Normal behavior:**
- First sync: 5-15 seconds
- Subsequent syncs: 2-10 seconds

### Issue: Data appears then disappears

**Reason:**
- Merge conflict - check merge policy
- Or another device deleted it

---

## Advanced Testing

### Test iCloud Status Check

Add this temporarily to `CalendarView.swift` in `onAppear`:

```swift
.onAppear {
    PersistenceController.shared.checkiCloudStatus { available, message in
        if available {
            print("✅ iCloud available and ready")
        } else {
            print("⚠️ iCloud issue: \(message ?? "Unknown")")
        }
    }
}
```

**Expected output:**
```
✅ iCloud available and ready
```

If you see errors, investigate the message.

---

## CloudKit Dashboard Verification

You can also verify data in CloudKit Dashboard:

1. Go to: https://icloud.developer.apple.com/dashboard
2. Sign in with your developer account
3. Select container: `iCloud.com.jeongpei.Knotnot`
4. Click **Development** environment
5. Go to **Data** tab
6. You should see your `CD_Conflict` records

**Note:**
- Development vs Production environments are separate
- When testing locally, data goes to Development
- When on TestFlight/App Store, data goes to Production

---

## Testing Checklist

Complete this checklist:

- [ ] Test 1: Create on Device 1 → Appears on Device 2
- [ ] Test 2: Edit on Device 2 → Updates on Device 1
- [ ] Test 3: Delete on Device 1 → Deletes on Device 2
- [ ] Test 4: Conflict resolution works without crash
- [ ] Test 5: Offline queue syncs when back online
- [ ] Console shows CloudKit sync events
- [ ] No persistent errors in console
- [ ] iCloud status check returns "available"

---

## Success Criteria

Your iCloud sync is working correctly if:

✅ All 5 tests pass
✅ Data syncs within 10 seconds
✅ No crashes or data corruption
✅ Console shows sync events, no errors
✅ Works both online and offline (with queue)

---

## If All Tests Pass

Congratulations! Your iCloud sync is working. You can now:

1. **Commit the working feature:**
   ```bash
   git add -A
   git commit -m "Verify iCloud sync working - all tests passed"
   ```

2. **Merge to main:**
   ```bash
   git checkout main
   git merge feature/icloud-sync
   ```

3. **Consider adding:**
   - Settings screen showing sync status
   - User-facing "Last synced" timestamp
   - Manual sync trigger button

---

## If Tests Fail

1. Note which specific test failed
2. Copy the console error messages
3. Check the "Common Issues" section above
4. Verify Xcode capabilities are correct
5. Double-check iCloud account is the same on both devices

---

**Good luck with testing!** 🧪☁️

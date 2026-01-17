# Calendar Sheet Blank Issue - Fix Documentation

**Date:** 2026-01-17
**Component:** CalendarView sheet presentation
**Status:** ✅ Fixed

---

## Problem Description

### Symptoms
When tapping a date without conflict in CalendarView to open the ConflictEditorView sheet:
- **First tap:** Sheet appears completely blank, no console logs
- **Close sheet and tap the SAME date again:** Still blank
- **Close sheet and tap a DIFFERENT date:** Works normally, displays correctly
- **After app restart:** Issue returns on first tap

### User Experience Impact
- Users had to tap two different dates to get the sheet to display properly
- Confusing and poor UX - appeared broken on first use

---

## Investigation Process

### Initial Hypotheses (Incorrect)
1. ❌ Thought it was a timing issue with LazyHStack rendering
2. ❌ Thought subsequent taps within the open sheet were fixing it
3. ❌ Tried using `.task` with delays, custom `init` - didn't fix the root cause

### Key Discovery
When user clarified they were **closing the sheet** and tapping from calendar again:
- **Same date:** Blank ❌
- **Different date:** Works ✅

This revealed it wasn't just a timing issue - it was a **view identity/caching issue**.

---

## Root Cause Analysis

### The Problem with `.sheet(isPresented:)`

```swift
// Original problematic code
@State private var showAddConflictSheet = false
@State private var dateForNewConflict: Date? = nil

.onTapGesture {
    dateForNewConflict = date
    showAddConflictSheet = true  // Triggers sheet
}

.sheet(isPresented: $showAddConflictSheet) {
    if let date = dateForNewConflict {  // This could fail!
        ConflictEditorView(...)
    }
}
```

### Why It Failed

1. **Timing Issue:** When `showAddConflictSheet = true`, the sheet's content closure may evaluate **before** `dateForNewConflict` fully propagates through SwiftUI's state system

2. **View Caching:** When tapping the same date repeatedly:
   - `generateDatesAround(date: dateX)` produces identical arrays
   - SwiftUI recognizes this as the "same view structure"
   - **Reuses the failed/blank view** from the previous attempt

3. **Why Different Dates Worked:**
   - `generateDatesAround(date: dateY)` produces a different array
   - SwiftUI sees it as a **new view** and properly creates it

---

## The Solution

### Switch to `.sheet(item:)`

Created an `IdentifiableDate` wrapper:

```swift
struct IdentifiableDate: Identifiable {
    let id = UUID()  // New UUID on every creation
    let date: Date
}
```

Updated state and presentation:

```swift
@State private var dateForNewConflict: IdentifiableDate? = nil

.onTapGesture {
    dateForNewConflict = IdentifiableDate(date: date)  // New UUID each time
}

.sheet(item: $dateForNewConflict) { identifiableDate in
    // This closure ONLY evaluates when item is non-nil
    NavigationStack {
        ConflictEditorView(
            dates: generateDatesAround(date: identifiableDate.date),
            initialDate: identifiableDate.date
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dateForNewConflict = nil  // Dismisses sheet
                }
            }
        }
    }
}
```

---

## Why This Fix Works

1. ✅ **No timing issues:** `.sheet(item:)` guarantees content closure only evaluates when the binding is non-nil

2. ✅ **No view caching:** Each tap creates a **new UUID**, forcing SwiftUI to treat it as a completely new view instance

3. ✅ **Cleaner state management:** No separate boolean flag needed

4. ✅ **Consistent behavior:** Works on first tap, same date re-taps, different dates, and after app restart

---

## Code Changes

### Files Modified
- `HeartLog/CalendarView.swift`

### Lines Changed
- Added `IdentifiableDate` struct (lines 9-12)
- Changed state variable type from `Date?` to `IdentifiableDate?` (line 25)
- Updated tap gesture to create `IdentifiableDate(date: date)` (line 237)
- Replaced `.sheet(isPresented:)` with `.sheet(item:)` (line 247)
- Removed `showAddConflictSheet` boolean flag

---

## Lessons Learned

### SwiftUI Sheet Presentation Best Practices

1. **Use `.sheet(item:)` when presenting with optional data**
   - More reliable than `.sheet(isPresented:)` + optional binding
   - Better state management
   - No timing issues

2. **Beware of SwiftUI view identity caching**
   - Same view structure can be reused unexpectedly
   - Use unique identifiers when you need fresh view instances

3. **Debug by testing edge cases:**
   - Same vs. different data
   - First time vs. subsequent times
   - After app restart

---

## Testing Checklist

- [x] First tap on any date shows sheet correctly
- [x] Close and tap the same date again - works
- [x] Close and tap different dates - works
- [x] Console logs appear on every sheet opening
- [x] Works after app restart
- [x] No blank sheets ever appear

---

## References

- SwiftUI `.sheet(item:)` documentation
- View identity and structural identity in SwiftUI
- State update timing and batching in SwiftUI

# Knotnot (HeartLog) — Project Overview

## Build Rules
- Do NOT run `xcode-select` or `xcodebuild` commands. The user will build in Xcode themselves.

## App Identity
- **App Name:** Knot Not
- **Bundle ID:** com.jeongpei.knotnot
- **App Store ID:** 6753355545
- **Version:** 1.1
- **Deployment Target:** iOS 17.6
- **Developer:** Jeong (@JeongTaeBae)
- **Contact:** peizhengze@gmail.com

## Purpose
A relationship conflict tracker using a "knot" metaphor. Users log daily conflicts, track intensity, tag emotions, and write notes. Calendar-based UI shows conflict history with custom shape indicators.

---

## Architecture

### Entry Point
`HeartLogApp.swift` — `@main` struct. Initializes Core Data, managers, checks onboarding state.

### View Hierarchy
```
HeartLogApp
  └─ ContentView (just wraps CalendarView, no tab bar)
       └─ CalendarView (main screen)
            ├─ Top bar: Statistics pill + Settings button
            ├─ Month nav: Year/Month + chevron buttons
            ├─ Calendar grid with conflict shape indicators
            ├─ ConflictDetailView (when conflict selected)
            ├─ "A peaceful day" text (when non-conflict date selected)
            ├─ Plus button (opens ConflictEditorView sheet)
            └─ Half-sheet: ConflictEditorView (3 pages)
                 ├─ Page 1: Knot (green line, drag to adjust intensity)
                 ├─ Page 2: Emotions (flow layout tags)
                 └─ Page 3: Notes (text editor + checkmark save/close)
```

### Other Views
- `SettingsView` — Settings page (navigated from gear button)
- `StatisticsView` — Charts and analytics (premium)
- `PaywallView` — Premium upgrade screen
- `OnboardingView` — 3-page intro with Lottie animations
- `NoteSheet` — Legacy note editor (may still be referenced)
- `MainView` — Legacy main view (unused after tab bar removal)

---

## Data Layer

### Core Data Entity: `Conflict`
| Attribute | Type | Notes |
|-----------|------|-------|
| id | UUID | Optional |
| date | Date | Optional, normalized to start-of-day |
| person | String | Default "Him" |
| intensity | String | "Minor", "Moderate", or "Severe" |
| notes | String | Optional, 200 char limit for free users |
| emotions | String | Comma-separated tags |

### Persistence
- `PersistenceController` — Singleton, `NSPersistentCloudKitContainer`
- iCloud sync via CloudKit (premium-gated)
- Container: `iCloud.com.jeongpei.Knotnot`
- Merge policy: `NSMergeByPropertyObjectTrumpMergePolicy`

---

## Managers

### ConflictManager
- CRUD: `saveConflict`, `fetchConflict`, `deleteConflict`, `toggleConflict`
- Analytics extension: monthly aggregations, intensity distribution, streaks

### PurchaseManager
- StoreKit 2, lifetime IAP: `com.jeongpei.knotnot.premium.lifetime`
- Cached in UserDefaults key `isPremiumUser`

### NoteAccessManager
- Free: 200 char limit; Premium: unlimited
- Grandfathering for users before v1.1

---

## Conflict Intensity

### Enum: `ConflictIntensity` (in Helpers.swift)
| Case | Asset Color | Knot Asset | Calendar Shape |
|------|------------|------------|----------------|
| minor | `Color("Yellow")` | `conflict-minor` | Yellow diamond (ConflictMinorShape) |
| moderate | `Color("Orange")` | `conflict-moderate` | Orange clover (ConflictModerateShape) |
| severe | `Color("Purple")` | `conflict-major` | Purple cross (ConflictSevereShape) |

### Knot Interaction (ConflictEditorView)
- Tap green line → logs conflict as minor
- Drag knot to right end → increase intensity
- Drag knot to left end → decrease intensity
- Boundaries respected (minor can't decrease, severe can't increase)
- On release: knot snaps to center, line resets to green
- Knot asset and line color change at 85% drag threshold

---

## Color Assets (Assets.xcassets)

| Name | Light | Dark |
|------|-------|------|
| BackgroundPrimary | #FFF8EE | #242321 |
| BackgroundSecondary | #F8E7CE | #2E2D2C |
| LabelPrimary | #22201E | #FFFFFF |
| LabelSecondary | #22201E (70%) | #FFFFFF (70%) |
| LabelTertiary | #22201E (50%) | #FFFFFF (50%) |
| White | #FFFFFF | #000000 |
| Purple | #CB41EA | #CB41EA |
| Orange | #FF5421 | #FF5421 |
| Yellow | #FFD621 | #FFD621 |
| Green | #4FA65B | #4FA65B |

---

## Image Assets
- `conflict-minor.imageset` — PDF vector (yellow knot shape)
- `conflict-moderate.imageset` — PDF vector (orange knot shape)
- `conflict-major.imageset` — PDF vector (purple knot shape)
- `Onboarding/Knot Heart.imageset` — PNG with light/dark variants
- `Onboarding/Center Circle.imageset` — PNG
- `Onboarding/Slider.imageset` — PNG

---

## Localization
- **Source:** English (en)
- **Translated:** Simplified Chinese (zh-Hans)
- **File:** `Localizable.xcstrings`
- **Emotion tags are localized** via `LocalizedStringKey`

### Emotion Tags
Anger, Sadness, Misunderstanding, Disappointment, Avoidance, Resentment, Neglect, Unappreciated, Controlled, Blamed, Distrust, Hurt, Exhausted

---

## Premium Features
1. Statistics & charts (ConflictFrequencyChart, IntensityDistributionChart, StreakVisualizationChart)
2. Emotion tags
3. iCloud sync
4. Unlimited note length

---

## Dependencies
- **Lottie** (SPM, from airbnb/lottie-spm) — onboarding animations
- **Apple frameworks:** SwiftUI, CoreData, CloudKit, StoreKit, Charts, UIKit

---

## Key Files Quick Reference
| File | Purpose |
|------|---------|
| `HeartLogApp.swift` | App entry, manager init |
| `ContentView.swift` | Root view (CalendarView) |
| `CalendarView.swift` | Main screen, calendar grid, detail view, sync banner |
| `ConflictEditorView.swift` | 3-page conflict logger (knot/emotions/notes), FlowLayout |
| `Helpers.swift` | Color(hex:), ConflictIntensity enum, Calendar extension |
| `Persistence.swift` | Core Data + CloudKit stack |
| `ConflictManager.swift` | Conflict CRUD operations |
| `PurchaseManager.swift` | StoreKit 2 IAP |
| `NoteAccessManager.swift` | Note character limits |
| `NoteSheet.swift` | TextEditorRepresentable, EmotionChip |
| `StatisticsView.swift` | Premium analytics |
| `PaywallView.swift` | Upgrade screen |
| `SettingsView.swift` | App settings |
| `SteppedSlider.swift` | Legacy intensity slider |

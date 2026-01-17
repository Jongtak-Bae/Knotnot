# HeartLog (Knotnot)

A SwiftUI-based iOS application for tracking and managing relationship conflicts with awareness and mindfulness.

## Overview

HeartLog helps users track conflicts in their relationships by logging incidents with varying intensity levels and notes. The app provides a visual interface for logging conflicts across days and a calendar view for reviewing conflict history.

**Tagline:** "Awareness is the first step to harmony" / "记录靠闹闹，关系更牢靠"

## Features

- **Date Carousel Interface**: Browse and log conflicts for the last 5 days with an intuitive horizontal carousel
- **Conflict Intensity Tracking**: Three intensity levels (Minor ☹️, Moderate 😡, Severe 👿)
- **Notes**: Add detailed notes to each conflict entry
- **Calendar View**: Monthly calendar showing all conflicts with color-coded intensity indicators
- **Conflict Details**: View and delete conflicts from the calendar
- **Onboarding**: 3-page onboarding flow for new users
- **Bilingual Support**: English and Simplified Chinese (zh-Hans)
- **Settings**: App version, contact info, social links, privacy policy

## Project Structure

### Main Views

```
HeartLog/
├── HeartLogApp.swift              # App entry point, manages onboarding state
├── ContentView.swift              # Tab view container (Log & Calendar tabs)
├── MainView.swift                 # Main logging view (wraps ConflictEditorView)
├── ConflictEditorView.swift       # Primary UI: date carousel + intensity slider + notes
├── CalendarView.swift             # Monthly calendar with conflict visualization
├── OnboardingView.swift           # 3-page onboarding experience
├── SettingsView.swift             # Settings and about page
└── NoteSheet.swift                # Modal sheet for adding/editing notes
```

### Data Layer

```
├── ConflictManager.swift          # Core Data manager (CRUD operations)
├── Persistence.swift              # Core Data stack setup
├── ConflictModel.xcdatamodeld/    # Core Data model definition
    └── ConflictModel.xcdatamodel/
        └── contents               # Entity: Conflict (id, date, person, intensity, notes)
```

### Supporting Components

```
├── SteppedSlider.swift            # Custom 3-step intensity slider
├── Helpers.swift                  # Extensions & enums (Color, Calendar, ConflictIntensity)
├── Localizable.xcstrings          # Localization strings (EN/ZH)
└── Assets.xcassets/               # Images, colors, icons
```

## Data Model

### Conflict Entity (Core Data)

| Attribute  | Type      | Description                           |
|------------|-----------|---------------------------------------|
| id         | UUID      | Unique identifier                     |
| date       | Date      | Date of the conflict                  |
| person     | String    | Person involved (default: "Him")      |
| intensity  | String    | "Minor", "Moderate", or "Severe"      |
| notes      | String    | Optional notes about the conflict     |

### ConflictIntensity Enum

```swift
enum ConflictIntensity: Int {
    case minor = 0      // ☹️  Color: #FFC35D (yellow-orange)
    case moderate = 1   // 😡  Color: #FF8D5D (orange)
    case severe = 2     // 👿  Color: #E75DFF (purple)
}
```

## Architecture

- **Framework**: SwiftUI
- **Persistence**: Core Data with lightweight migration
- **State Management**:
  - `@EnvironmentObject` for ConflictManager
  - `@FetchRequest` for reactive Core Data queries
  - `@State` for local UI state
- **Navigation**: NavigationStack with TabView

## Key Components Explained

### ConflictEditorView

The main conflict logging interface featuring:
- Horizontal scrolling date carousel (last 5 days)
- Tap-to-toggle conflict logging
- 3-step intensity slider with haptic feedback
- Notes button and display
- Real-time sync with Core Data

### CalendarView

Monthly calendar visualization with:
- Grid layout showing all days
- Color-coded conflict indicators
- Conflict detail panel
- Month navigation
- Total conflicts counter
- Delete functionality

### ConflictManager

Handles all Core Data operations:
- `saveConflict()` - Create or update conflict
- `fetchConflict(for:)` - Get conflict for specific date
- `deleteConflict(for:)` - Remove conflict
- `toggleConflict()` - Add or remove conflict

## User Flow

1. **First Launch**: Onboarding flow (3 pages)
2. **Main Screen**: Date carousel on "Log" tab
   - Scroll to browse dates
   - Tap centered circle to log/remove conflict
   - Adjust intensity with slider
   - Add notes via "Add Notes" button
3. **Calendar Tab**: View all conflicts
   - Navigate months
   - Tap dates to view/delete conflicts
   - See total conflict count

## Localization

- **Source Language**: English (en)
- **Supported Languages**: English, Simplified Chinese (zh-Hans)
- **Localization File**: `Localizable.xcstrings`

## Color Palette

- **Primary Purple**: `#A640BC`
- **Yellow**: `#EAAB04`
- **Minor Intensity**: `#FFC35D`
- **Moderate Intensity**: `#FF8D5D`
- **Severe Intensity**: `#E75DFF`

## Technical Details

- **Minimum iOS Version**: iOS 17.0+ (uses MeshGradient for iOS 18.0+)
- **Xcode Project**: HeartLog.xcodeproj
- **App ID**: 6753355545
- **Developer**: Jeong (@JeongTaeBae, @JeongPei)
- **Contact**: peizhengze@gmail.com

## Recent Fixes

- Fixed notes not updating instantly when changed through NoteSheet (ConflictEditorView.swift:151)

## Development Notes

- Uses `UserDefaults` to track onboarding completion
- Haptic feedback on conflict toggle and intensity changes
- Custom UITextView wrapper (`TextEditorRepresentable`) for reliable keyboard focus
- Date normalization to start of day for conflict matching
- Lightweight Core Data migration enabled

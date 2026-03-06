# HeartLog - Simple Solo Developer Workflow

## Context

**Project**: HeartLog (Knotnot) - iOS relationship conflict tracking app
**Version**: 1.1.0
**Tech**: SwiftUI, CoreData + CloudKit, StoreKit 2
**Status**: Live on App Store ✅

**What's Already Great**:
- Clean MVVM architecture
- CloudKit sync working
- IAP ($4.99 premium) working
- Good manual testing docs
- English + Chinese localization

---

## 1. Planning (Simple!)

### New Feature
1. Quick note in `/FeaturePlans/feature-name.md`:
   - What problem?
   - Premium or free?

2. Use Claude Code: "Plan implementation for [feature]"
   - It reviews existing code
   - Suggests approach
   - Shows which files to edit

**That's it.** No complex tracking needed.

### Ideas List
Optional: Create `/ROADMAP.md` to track ideas
```markdown
## Next (1.2)
- Conflict categories
- Data export

## Maybe Later
- Dark mode
- Apple Watch
```

### Bugs
Keep using `/BugFixes/[name].md` (you already do this!) ✅

---

## 2. Design

### Figma → SwiftUI
1. Design in Figma
2. Give Claude the Figma URL
3. Claude generates SwiftUI using Figma MCP
4. You adapt to your patterns

**Useful Figma Tools**:
- `get_design_context` - Generates SwiftUI from design
- `get_screenshot` - Visual reference

### Your Colors
```swift
Purple: #A640BC
Yellow: #EAAB04
```

### Localization
- Already set up (English + Chinese) ✅
- Add strings: Edit `/HeartLog/Localizable.xcstrings`
- Test: Switch simulator language

---

## 3. Implementation

### Git (Keep It Simple)
```bash
# Option 1: Work on main
git add [files]
git commit -m "Add feature"
git push

# Option 2: Use branches
git checkout -b feature/name
# ... work ...
git checkout main
git merge feature/name
```

**Choose whatever feels natural!**

### Code Structure (Already Good!)
```
HeartLog/
├── Views/ - UI
├── Managers/ - Business logic
├── Charts/ - Charts
└── Models/ - Data
```

### Adding Premium Features
Copy pattern from CalendarView.swift:
```swift
if purchaseManager.isPremium {
    // Show feature
} else {
    showPaywall = true
}
```

---

## 4. Testing (Manual Only)

### Your Current Docs (Keep Using!)
- ✅ `/TESTING_ICLOUD_SYNC.md` - CloudKit testing
- ✅ `/IAP_SETUP_GUIDE.md` - Purchase testing

### Simple Checklist
Create `/TESTING_CHECKLIST.md`:

**Before Every Release**:
- [ ] Onboarding works (new user)
- [ ] Can log conflicts (all 3 intensities)
- [ ] Notes & emotions work
- [ ] Calendar navigation smooth
- [ ] IAP purchase works (sandbox)
- [ ] Restore purchases works
- [ ] CloudKit syncs (2 devices)
- [ ] Test in Chinese language
- [ ] No crashes (use app for 10 min)

**Test Devices**:
- iPhone SE (small screen)
- iPhone 15 Pro
- iOS 17.6 + latest iOS

**That's all you need!** Manual testing works great for solo dev.

---

## 5. Release to App Store

### Simple Release Process

**1. Prepare**
- [ ] All features done
- [ ] Manual testing passed
- [ ] No crashes

**2. Version Bump**
```
Xcode → Project → General
Version: 1.1 → 1.2
Build: Increment by 1
```

**3. Git Tag** (NEW - start doing this!)
```bash
git tag -a v1.2.0 -m "Version 1.2.0"
git push origin v1.2.0
```

**4. App Store Assets**
Prepare in `/AppStoreAssets/`:
- Screenshots (use iOS Simulator MCP!)
- Description updates (English + Chinese)
- Release notes

**5. Upload to App Store**
```
Xcode → Product → Archive
Organizer → Distribute → App Store Connect
```

**6. Submit**
- App Store Connect → Select build
- Add release notes
- Submit for review
- Wait 1-3 days

**7. Monitor After Launch**
- Xcode Organizer → Crashes
- App Store Connect → Analytics
- User reviews

### Changelog

Create `/CHANGELOG.md`:
```markdown
# Changelog

## [1.2.0] - 2026-XX-XX
### Added
- Conflict categories
- CSV export

### Fixed
- Calendar scroll lag

## [1.1.0] - 2026-01-26
### Added
- Emotion tags
- Note limits

## [1.0.0] - 2026-01-15
- Initial release
```

Update this as you build features!

---

## 6. Helpful Claude Code Tools

### Subagents
- **Explore Agent**: "Find all places where premium features are checked"
- **Plan Agent**: "Plan implementation for conflict categories"
- Use before starting any medium/large feature

### iOS Simulator MCP
Super useful for App Store:
- `screenshot` - Capture perfect screenshots
- `record_video` - Create preview videos
- `ui_describe_all` - Check accessibility

**Example**:
```
"Take App Store screenshots of all main screens"
Claude will:
1. Launch app in simulator
2. Navigate through screens
3. Capture screenshots
4. Save to /AppStoreAssets/
```

### Figma MCP
- `get_design_context` - Generate SwiftUI from designs
- Works with Figma URLs

---

## 7. Quick Start: Next Steps

**This Week** (Do These First!):

1. **Add Git Tags** (5 min)
   ```bash
   git tag -a v1.1.0 -m "Current version"
   git push origin v1.1.0
   ```

2. **Create CHANGELOG.md** (10 min)
   - Document v1.0 and v1.1
   - Template above

3. **Create TESTING_CHECKLIST.md** (15 min)
   - Copy your manual testing steps
   - Check before each release

4. **Optional: ROADMAP.md** (5 min)
   - List feature ideas
   - Prioritize

**That's it!** You're set up.

---

## 8. Key Files Reference

**Your Current Code** (Keep as Reference):
- `/HeartLog/ConflictManager.swift` - CRUD patterns
- `/HeartLog/PurchaseManager.swift` - IAP patterns
- `/HeartLog/CalendarView.swift` - Premium gating examples
- `/HeartLog/Persistence.swift` - CoreData + CloudKit

**Existing Docs** (Already Great!):
- `/TESTING_ICLOUD_SYNC.md` ✅
- `/IAP_SETUP_GUIDE.md` ✅
- `/BugFixes/` directory ✅

**To Create** (This Week):
- `/CHANGELOG.md` - Track changes
- `/TESTING_CHECKLIST.md` - Pre-release checklist
- `/ROADMAP.md` - Feature ideas (optional)

---

## Summary

**What You're Already Doing Well**:
- Good architecture
- Manual testing with docs
- Bug tracking in /BugFixes
- Production app on App Store

**Simple Improvements**:
1. Git tags for versions
2. CHANGELOG.md for release notes
3. Testing checklist
4. Use Claude Code for feature planning

**Skip These** (Not needed for solo dev):
- Unit tests (manual testing works!)
- CI/CD pipelines (manual is fine)
- SwiftLint (optional, adds friction)
- Complex project management

**Result**: Ship features faster with confidence, keep it simple!

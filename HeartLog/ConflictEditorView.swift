import SwiftUI
import UIKit

// MARK: - ConflictEditorView (Half Sheet with 3 Pages)
struct ConflictEditorView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var noteAccessManager: NoteAccessManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>

    let dates: [Date]
    let initialDate: Date

    @State private var currentPage: Int = 0 // 0=Knot, 1=Emotions, 2=Notes
    @State private var intensity: ConflictIntensity = .minor
    @State private var selectedEmotions: Set<String> = []
    @State private var userText: String = ""
    @State private var draftText: String = ""
    @State private var hasLoggedConflict: Bool = false

    // Knot drag state
    @State private var dragOffset: CGFloat = 0
    @State private var verticalDragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var dragStartIntensity: ConflictIntensity = .minor
    @State private var lineColor: Color = Color("Green")
    @State private var currentKnotAsset: String = "conflict-minor"

    @FocusState private var isTextEditorFocused: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall: Bool = false
    @State private var showCharacterLimitError = false
    @State private var showUpgradePrompt = false
    @State private var showDiscardWarning = false
    @State private var showDeleteWarning = false
    @State private var showEmotionTip = false
    @State private var isEditingExisting: Bool = false

    // Knot onboarding: 0=tap, 1=drag intensity, 2=drag delete, 3=mastered, 4=done
    @State private var knotOnboardingStep: Int = 0
    @State private var hasDraggedLeft: Bool = false
    @State private var hasDraggedRight: Bool = false
    private var isKnotOnboarding: Bool { !UserDefaults.standard.bool(forKey: "hasCompletedKnotOnboarding") }

    init(dates: [Date], initialDate: Date) {
        self.dates = dates
        self.initialDate = initialDate
    }

    private var pageTitle: String {
        switch currentPage {
        case 0: return NSLocalizedString("Knot", comment: "")
        case 1: return NSLocalizedString("How are you feeling?", comment: "")
        case 2: return NSLocalizedString("Notes", comment: "")
        default: return ""
        }
    }

    private var screenCornerRadius: CGFloat {
        (UIScreen.main.value(forKey: ["_display", "Corner", "Radius"].joined()) as? CGFloat) ?? 55
    }

    var body: some View {
        VStack(spacing: 0) {
            // Shared header
            HStack {
                // Left button — always present, hidden on page 0
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("LabelPrimary"))
                        .frame(width: 48, height: 48)
                        .background(Color("BackgroundPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .opacity(currentPage > 0 ? 1 : 0)
                .disabled(currentPage == 0)

                Spacer()

                // Right button — chevron or checkmark, always same frame
                if currentPage < 2 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentPage += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("LabelPrimary"))
                            .frame(width: 48, height: 48)
                            .background(Color("BackgroundPrimary"))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .opacity(hasLoggedConflict ? 1 : 0)
                    .disabled(!hasLoggedConflict)
                } else {
                    Button(action: {
                        if !hasLoggedConflict {
                            if !selectedEmotions.isEmpty || !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                showDiscardWarning = true
                            } else {
                                dismiss()
                            }
                        } else if noteAccessManager.canSaveNote(withLength: draftText.count) {
                            userText = draftText
                            saveConflict()
                            dismiss()
                        } else {
                            showCharacterLimitError = true
                        }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("Green"))
                            .frame(width: 48, height: 48)
                            .background(Color("BackgroundPrimary"))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .overlay(
                HStack(spacing: 4) {
                    Text(pageTitle)
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.43)
                        .foregroundColor(Color("LabelPrimary"))

                    if currentPage == 1 {
                        Button(action: { showEmotionTip.toggle() }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(Color("LabelTertiary"))
                        }
                        .popover(isPresented: $showEmotionTip, arrowEdge: .top) {
                            Text(NSLocalizedString("Research shows that naming your emotions — called \"affect labeling\" — reduces their intensity and helps you respond more thoughtfully. In relationships, this awareness builds empathy and clearer communication, turning conflicts into opportunities for understanding.", comment: "Emotion tagging benefit tooltip"))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color("LabelPrimary"))
                                .padding(16)
                                .frame(width: 280)
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                }
            )
            .animation(nil, value: currentPage)
            .padding(.horizontal, 20)
            .padding(.top, 24)

            // Page content
            Group {
                switch currentPage {
                case 0:
                    knotPage
                case 1:
                    emotionPage
                case 2:
                    notesPage
                default:
                    knotPage
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(screenCornerRadius)
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: screenCornerRadius))
        .onAppear {
            refreshUIState()
        }
        .onDisappear {
            if hasLoggedConflict {
                userText = draftText
                saveConflict()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(feature: .emotionTags)
                .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showUpgradePrompt) {
            PaywallView(feature: .unlimitedNotes)
                .environmentObject(purchaseManager)
        }
        .alert("Character Limit Reached", isPresented: $showCharacterLimitError) {
            Button("Upgrade to Premium") {
                showUpgradePrompt = true
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Free users can write up to 200 characters. Upgrade to Premium for unlimited notes.")
        }
        .alert(NSLocalizedString("Discard Changes?", comment: ""), isPresented: $showDiscardWarning) {
            Button(NSLocalizedString("Discard", comment: ""), role: .destructive) {
                dismiss()
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("You haven't logged a conflict. Your emotion tags and notes will be discarded.", comment: ""))
        }
        .alert(NSLocalizedString("Delete this conflict?", comment: ""), isPresented: $showDeleteWarning) {
            Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                performDelete()
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("Your emotion tags and notes will also be deleted.", comment: "Alert message when deleting a conflict that has emotions or notes"))
        }
    }

    // MARK: - Page 1: Knot
    private var knotPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Intensity label / onboarding instructions
            VStack(spacing: 6) {
                Text(knotLabelText)
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.43)
                    .foregroundColor(Color("LabelSecondary"))

                if isKnotOnboarding && hasLoggedConflict && knotOnboardingStep >= 1 && knotOnboardingStep <= 2 {
                    Text(intensity.displayName)
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.23)
                        .foregroundColor(Color("LabelTertiary"))
                }
            }
            .padding(.bottom, 16)
                .animation(.easeInOut(duration: 0.2), value: knotLabelText)

            // Knot line with draggable knot
            knotLineView
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Knot Line View
    private let deleteThreshold: CGFloat = 120

    private var knotLineView: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let endCapWidth: CGFloat = 9
            let endCapHeight: CGFloat = 27
            let lineHeight: CGFloat = 15
            let knotSize: CGFloat = 50
            let halfTrack = (totalWidth - endCapWidth * 2) / 2
            let lineY: CGFloat = knotSize / 2
            let knotX = totalWidth / 2 + dragOffset
            let knotY = lineY + verticalDragOffset
            let isDeleting = verticalDragOffset >= deleteThreshold

            ZStack {
                // Main line — broken line (two segments meeting at knot)
                BrokenLineShape(
                    bendX: knotX,
                    bendY: knotY,
                    lineY: lineY,
                    leftX: endCapWidth / 2,
                    rightX: totalWidth - endCapWidth / 2
                )
                .stroke(lineColor, style: StrokeStyle(lineWidth: lineHeight, lineCap: .round, lineJoin: .round))

                // Left end cap
                RoundedRectangle(cornerRadius: 7)
                    .fill(lineColor.opacity(0.8))
                    .frame(width: endCapWidth, height: endCapHeight)
                    .position(x: endCapWidth / 2, y: lineY)

                // Right end cap
                RoundedRectangle(cornerRadius: 7)
                    .fill(lineColor.opacity(0.8))
                    .frame(width: endCapWidth, height: endCapHeight)
                    .position(x: totalWidth - endCapWidth / 2, y: lineY)

                // Knot image (shown after tapping)
                if hasLoggedConflict {
                    Image(currentKnotAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: knotSize, height: knotSize)
                        .position(x: knotX, y: knotY)
                        .gesture(
                            DragGesture()
                                .onChanged { drag in
                                    if !isDragging {
                                        isDragging = true
                                        dragStartIntensity = intensity
                                    }
                                    let clampedOffset = min(max(drag.translation.width, -halfTrack), halfTrack)
                                    dragOffset = clampedOffset
                                    verticalDragOffset = (isKnotOnboarding && knotOnboardingStep == 1) ? 0 : max(0, drag.translation.height)
                                    updateIntensityFromDrag(halfTrack: halfTrack)

                                    // Track drag directions for onboarding
                                    if isKnotOnboarding && knotOnboardingStep == 1 {
                                        let progress = clampedOffset / halfTrack
                                        if progress <= -0.45 { hasDraggedLeft = true }
                                        if progress >= 0.45 { hasDraggedRight = true }
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    if verticalDragOffset >= deleteThreshold {
                                        if !selectedEmotions.isEmpty || !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            // Has emotions or notes — show warning first
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                dragOffset = 0
                                                verticalDragOffset = 0
                                            }
                                            showDeleteWarning = true
                                        } else {
                                            performDelete()
                                        }
                                    } else {
                                        saveConflict()
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            dragOffset = 0
                                            verticalDragOffset = 0
                                            lineColor = intensity.color
                                            currentKnotAsset = knotAssetForIntensity(intensity)
                                        }

                                        if isKnotOnboarding && knotOnboardingStep == 1 && hasDraggedLeft && hasDraggedRight {
                                            knotOnboardingStep = 2
                                        }
                                    }
                                }
                        )
                        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: intensity)
                }

                // Trash icon — appears when dragging down
                if hasLoggedConflict && verticalDragOffset > 20 {
                    Image(systemName: isDeleting ? "trash.circle.fill" : "trash.circle")
                        .font(.system(size: isDeleting ? 40 : 32))
                        .foregroundColor(isDeleting ? .red : Color("LabelSecondary"))
                        .position(x: totalWidth / 2, y: lineY + deleteThreshold + 40)
                        .opacity(min(1, Double(verticalDragOffset - 20) / 40))
                        .scaleEffect(isDeleting ? 1.2 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: isDeleting)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !hasLoggedConflict {
                    hasLoggedConflict = true
                    intensity = .moderate
                    currentKnotAsset = "conflict-moderate"
                    lineColor = Color("Orange")
                    saveConflict()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    if isKnotOnboarding {
                        if knotOnboardingStep == 0 {
                            knotOnboardingStep = 1
                        } else if knotOnboardingStep == 3 {
                            knotOnboardingStep = 4
                            UserDefaults.standard.set(true, forKey: "hasCompletedKnotOnboarding")
                        }
                    }
                }
            }
        }
        .frame(height: knotLineHeight)
    }

    private var knotLineHeight: CGFloat {
        50 + deleteThreshold + 60
    }

    private var knotLabelText: String {
        if isKnotOnboarding {
            switch knotOnboardingStep {
            case 0:
                return NSLocalizedString("Tap to log a conflict", comment: "")
            case 1:
                return NSLocalizedString("Drag left or right to adjust intensity", comment: "Onboarding hint for adjusting intensity")
            case 2:
                return NSLocalizedString("Drag down to delete", comment: "Onboarding hint for deleting")
            case 3:
                return NSLocalizedString("Great! Now start logging", comment: "Onboarding completion message")
            default:
                return intensity.displayName
            }
        }
        if hasLoggedConflict {
            return intensity.displayName
        }
        return NSLocalizedString("Tap to log a conflict", comment: "")
    }

    private func updateIntensityFromDrag(halfTrack: CGFloat) {
        let progress = dragOffset / halfTrack // -1 (full left) to 1 (full right)
        let midThreshold: CGFloat = 0.45
        let endThreshold: CGFloat = 0.85

        if progress >= endThreshold {
            // Dragged to right end → jump to severe
            intensity = .severe
        } else if progress >= midThreshold {
            // Dragged to mid-right → one step up from start
            switch dragStartIntensity {
            case .minor: intensity = .moderate
            case .moderate, .severe: intensity = .severe
            }
        } else if progress <= -endThreshold {
            // Dragged to left end → jump to minor
            intensity = .minor
        } else if progress <= -midThreshold {
            // Dragged to mid-left → one step down from start
            switch dragStartIntensity {
            case .severe: intensity = .moderate
            case .moderate, .minor: intensity = .minor
            }
        } else {
            // Near center → revert to starting intensity
            intensity = dragStartIntensity
        }

        currentKnotAsset = knotAssetForIntensity(intensity)
        lineColor = intensity.color
    }

    private func knotAssetForIntensity(_ intensity: ConflictIntensity) -> String {
        switch intensity {
        case .minor: return "conflict-minor"
        case .moderate: return "conflict-moderate"
        case .severe: return "conflict-major"
        }
    }

    // MARK: - Page 2: Emotions
    private var emotionPage: some View {
        VStack(spacing: 0) {
            if purchaseManager.isPremium {
                unlockedEmotionTags
            } else {
                lockedEmotionTags
            }
            Spacer()
        }
    }

    private var unlockedEmotionTags: some View {
        let emotions = ["Anger", "Sadness", "Misunderstanding", "Disappointment", "Avoidance", "Resentment", "Neglect", "Unappreciated", "Controlled", "Blamed", "Distrust", "Hurt", "Exhausted"]

        return FlowLayout(spacing: 10) {
            ForEach(emotions, id: \.self) { emotion in
                Button(action: {
                    if selectedEmotions.contains(emotion) {
                        selectedEmotions.remove(emotion)
                    } else {
                        selectedEmotions.insert(emotion)
                    }
                    saveConflict()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Text(LocalizedStringKey(emotion))
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.23)
                        .foregroundColor(Color("LabelPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedEmotions.contains(emotion) ? Color("LabelPrimary").opacity(0.1) : Color("BackgroundPrimary"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(selectedEmotions.contains(emotion) ? Color("LabelPrimary").opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var lockedEmotionTags: some View {
        let emotions = ["Anger", "Sadness", "Misunderstanding", "Disappointment", "Avoidance", "Resentment", "Neglect", "Unappreciated", "Controlled", "Blamed", "Distrust", "Hurt", "Exhausted"]

        return ZStack() {
            FlowLayout(spacing: 10) {
                ForEach(emotions, id: \.self) { emotion in
                    Text(LocalizedStringKey(emotion))
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.23)
                        .foregroundColor(Color("LabelPrimary"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("BackgroundPrimary"))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .allowsHitTesting(false)

            LinearGradient(
                stops: [
                    .init(color: Color("BackgroundSecondary").opacity(0), location: 0),
                    .init(color: Color("BackgroundSecondary"), location: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            Button(action: { showPaywall = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                    Text(NSLocalizedString("Unlock", comment: ""))
                        .font(.system(size: 24, weight: .light))
                }
                .foregroundColor(Color("White"))
                .padding(.horizontal, 34)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(Color("LabelPrimary"))
                )
            }
//            .padding(.bottom, 16)
        }
    }

    // MARK: - Page 3: Notes
    private var notesPage: some View {
        VStack(spacing: 0) {
            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditorRepresentable(
                    text: $draftText,
                    placeholder: "Write something down",
                    characterLimit: noteAccessManager.characterLimit
                )
                .frame(minHeight: 110)
                .focused($isTextEditorFocused)

                if draftText.isEmpty {
                    Text("Write something down")
                        .font(.system(size: 17))
                        .tracking(-0.43)
                        .foregroundColor(Color("LabelTertiary"))
                        .padding(.top, 8)
                        .padding(.leading, 10)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("BackgroundPrimary"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)

            // Character counter
            if let limit = noteAccessManager.characterLimit {
                HStack {
                    Spacer()
                    Text("\(draftText.count) / \(limit)")
                        .font(.caption)
                        .foregroundColor(charCountColor())
                        .padding(.trailing, 24)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .onAppear {
            draftText = userText
        }
    }

    // MARK: - Helpers

    private func refreshUIState() {
        if let conflict = conflicts.first(where: {
            Calendar.current.isDate($0.date!, inSameDayAs: initialDate)
        }) {
            intensity = ConflictIntensity(string: conflict.intensity) ?? .moderate
            userText = conflict.notes ?? ""
            draftText = conflict.notes ?? ""
            if let emotionsString = conflict.emotions, !emotionsString.isEmpty {
                selectedEmotions = Set(emotionsString.split(separator: ",").map(String.init))
            } else {
                selectedEmotions = []
            }
            hasLoggedConflict = true
            isEditingExisting = true
            currentKnotAsset = knotAssetForIntensity(intensity)
            lineColor = intensity.color
        } else {
            intensity = .minor
            userText = ""
            draftText = ""
            selectedEmotions = []
            hasLoggedConflict = false
        }
    }

    private func saveConflict() {
        try? conflictManager.saveConflict(
            date: initialDate,
            person: "Him",
            notes: userText,
            intensity: intensity,
            emotions: Array(selectedEmotions)
        )
    }

    private func performDelete() {
        try? conflictManager.deleteConflict(for: initialDate)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            hasLoggedConflict = false
            dragOffset = 0
            verticalDragOffset = 0
            intensity = .minor
            selectedEmotions = []
            userText = ""
            draftText = ""
            lineColor = Color("Green")
            currentKnotAsset = "conflict-minor"
        }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        if isKnotOnboarding && knotOnboardingStep == 2 {
            knotOnboardingStep = 3
        }
    }

    private func charCountColor() -> Color {
        guard let limit = noteAccessManager.characterLimit else { return .secondary }
        let percentage = Double(draftText.count) / Double(limit)
        if percentage >= 1.0 { return .red }
        if percentage >= 0.9 { return .orange }
        return .secondary
    }
}

// MARK: - Animatable Broken Line Shape
struct BrokenLineShape: Shape {
    var bendX: CGFloat
    var bendY: CGFloat
    var lineY: CGFloat
    var leftX: CGFloat
    var rightX: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bendX, bendY) }
        set {
            bendX = newValue.first
            bendY = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: leftX, y: lineY))
        path.addLine(to: CGPoint(x: bendX, y: bendY))
        path.addLine(to: CGPoint(x: rightX, y: lineY))
        return path
    }
}

// MARK: - Flow Layout for Emotion Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

// MARK: - Date Circle View (kept for backwards compatibility)
struct DateCircleView: View {
    let date: Date
    let index: Int
    let centeredIndex: Int
    let conflicts: FetchedResults<Conflict>
    @Binding var selectedDateIndex: Int?
    @Binding var scrollPosition: Int?
    let onTap: () -> Void

    private func hasConflict() -> Bool {
        conflicts.contains { Calendar.current.isDate($0.date!, inSameDayAs: date) }
    }

    private func conflictIntensity() -> ConflictIntensity {
        conflicts.first { Calendar.current.isDate($0.date!, inSameDayAs: date) }
            .flatMap { ConflictIntensity(string: $0.intensity) } ?? .moderate
    }

    var body: some View {
        ZStack {
            Text(dayOfWeek(from: date))
                .offset(x: 0, y: -75)
                .font(.title)
                .foregroundStyle(Color(hex: "#7F809E"))

            ZStack {
                let circleColor: Color = hasConflict() ? conflictIntensity().color : .clear
                let circleText: String = {
                    switch conflictIntensity() {
                    case .minor: return "☹️"
                    case .moderate: return "😡"
                    case .severe: return "👿"
                    }
                }()

                Circle()
                    .fill(circleColor)
                    .stroke(hasConflict() ? circleColor : Color(hex: "#7F809E").opacity(0.5), lineWidth: 2)
                    .frame(width: 100, height: 100)

                Text(hasConflict() ? circleText : "\(Calendar.current.component(.day, from: date))")
                    .font(.largeTitle)
                    .foregroundStyle(hasConflict() ? Color.white : Color(hex: "#7F809E"))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if index == centeredIndex {
                onTap()
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
            } else {
                withAnimation(.spring()) {
                    scrollPosition = index
                    selectedDateIndex = index
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: selectedDateIndex)
    }

    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct TruncatedSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct FullSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct LimitedText: View {
    let text: String
    let lineLimit: Int
    let font: Font
    let onViewMore: () -> Void

    @State private var truncatedSize: CGSize = .zero
    @State private var fullSize: CGSize = .zero

    var isTruncated: Bool {
        truncatedSize.height < fullSize.height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                Text(text)
                    .font(font)
                    .lineLimit(lineLimit)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TruncatedSizeKey.self, value: geo.size)
                    })
                    .onPreferenceChange(TruncatedSizeKey.self) { truncatedSize = $0 }

                Text(text)
                    .font(font)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: FullSizeKey.self, value: geo.size)
                    })
                    .onPreferenceChange(FullSizeKey.self) { fullSize = $0 }
            }

            if isTruncated {
                Button("View more") {
                    onViewMore()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - FullNoteView
struct FullNoteView: View {
    let note: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(note)
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Note")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

//// MARK: - Preview
//#Preview {
//    ConflictEditorView(dates: [Date()], initialDate: Date())
//        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
//        .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
//        .environmentObject(PurchaseManager.shared)
//        .environmentObject(NoteAccessManager.shared)
//        .preferredColorScheme(.dark)
//}

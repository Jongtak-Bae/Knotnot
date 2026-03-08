import SwiftUI
import CoreData
import CloudKit

struct CalendarDayItem: Identifiable {
    let id = UUID()
    let date: Date?
}

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

enum SyncStatus {
    case available
    case syncing
    case notAvailable(String)
    case error(String)
}

// MARK: - Conflict Shape Views
struct ConflictMinorShape: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.37)
                .fill(Color("Yellow"))
                .frame(width: size * 0.8, height: size * 0.8)
                .rotationEffect(.degrees(45))
            RoundedRectangle(cornerRadius: size * 0.37)
                .fill(Color("Yellow").opacity(0.8))
                .frame(width: size * 0.8, height: size * 0.8)
                .rotationEffect(.degrees(0))
        }
        .frame(width: size, height: size)
    }
}

struct ConflictModerateShape: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            // Four overlapping circles to make a clover
            let offset = size * 0.18
            Circle()
                .fill(Color("Orange"))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: -offset, y: -offset)
            Circle()
                .fill(Color("Orange"))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: offset, y: -offset)
            Circle()
                .fill(Color("Orange"))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: -offset, y: offset)
            Circle()
                .fill(Color("Orange"))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: offset, y: offset)
        }
        .frame(width: size, height: size)
    }
}

struct ConflictSevereShape: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            // Cross/plus shape with rounded rectangles
            RoundedRectangle(cornerRadius: size * 0.37)
                .fill(Color("Purple"))
                .frame(width: size * 0.35, height: size * 0.85)
            RoundedRectangle(cornerRadius: size * 0.37)
                .fill(Color("Purple"))
                .frame(width: size * 0.85, height: size * 0.35)
            // Center diamond overlay for depth
            RoundedRectangle(cornerRadius: size * 0.37)
                .fill(Color("Purple").opacity(0.8))
                .frame(width: size * 0.6, height: size * 0.6)
                .rotationEffect(.degrees(45))
        }
        .frame(width: size, height: size)
    }
}

@ViewBuilder
func conflictShapeView(for intensity: ConflictIntensity, size: CGFloat = 34) -> some View {
    switch intensity {
    case .minor:
        Image("conflict-minor")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    case .moderate:
        Image("conflict-moderate")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    case .severe:
        Image("conflict-major")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>

    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var selectedConflict: Conflict? = nil
    @State private var showSettings: Bool = false
    @State private var showStatistics: Bool = false
    @State private var showPaywall: Bool = false
    @State private var dateForNewConflict: IdentifiableDate? = nil
    @State private var lastNewConflictDate: Date? = nil
    @State private var tappedDate: Date? = nil
    @State private var syncStatus: SyncStatus = .syncing
    @State private var lastSyncTime: Date?
    @State private var showSyncBanner: Bool = false
    @State private var bannerDismissTask: Task<Void, Never>?

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }

    private var weekdayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let firstWeek = calendar.firstWeekday - 1
        return Array(symbols[firstWeek...] + symbols[..<firstWeek])
    }

    private var monthDays: [CalendarDayItem] {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [CalendarDayItem] = []
        for _ in 0..<offsetDays {
            days.append(CalendarDayItem(date: nil))
        }
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDay) {
                days.append(CalendarDayItem(date: date))
            }
        }
        let totalSlots = ((days.count + 6) / 7) * 7
        for _ in days.count..<totalSlots {
            days.append(CalendarDayItem(date: nil))
        }
        return days
    }

    private var yearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy")
        return formatter.string(from: currentMonth)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: currentMonth)
    }

    private var totalConflicts: Int {
        conflicts.filter { $0.date != nil }.count
    }

    private func hasConflict(on date: Date) -> Bool {
        conflicts.contains { conflict in
            guard let conflictDate = conflict.date else { return false }
            return Calendar.current.isDate(conflictDate, inSameDayAs: date)
        }
    }

    private func hasNote(on date: Date) -> Bool {
        conflicts.first { conflict in
            guard let conflictDate = conflict.date else { return false }
            return Calendar.current.isDate(conflictDate, inSameDayAs: date)
        }.flatMap { $0.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false } ?? false
    }

    private func conflictIntensity(on date: Date) -> ConflictIntensity {
        conflicts.first { conflict in
            guard let conflictDate = conflict.date else { return false }
            return Calendar.current.isDate(conflictDate, inSameDayAs: date)
        }
        .flatMap { ConflictIntensity(string: $0.intensity) } ?? .moderate
    }

    private func isFutureDate(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let compareDate = calendar.startOfDay(for: date)
        return compareDate > today
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Whether today is in the currently displayed month
    private var isTodayOnScreen: Bool {
        calendar.isDate(Date(), equalTo: currentMonth, toGranularity: .month)
    }

    /// The effective date to consider as "active" (explicit selection or today if on screen)
    private var effectiveDate: Date? {
        if selectedDate != nil || selectedConflict != nil {
            return nil // explicit selection takes priority
        }
        return isTodayOnScreen ? calendar.startOfDay(for: Date()) : nil
    }

    /// The conflict to show in the detail card (explicit or today's)
    private var activeConflict: Conflict? {
        if let conflict = selectedConflict { return conflict }
        if let today = effectiveDate {
            return conflicts.first { conflict in
                guard let d = conflict.date else { return false }
                return calendar.isDate(d, inSameDayAs: today)
            }
        }
        return nil
    }

    /// Whether to show "A peaceful day" text
    private var showPeacefulDay: Bool {
        if selectedDate != nil { return true }
        if let today = effectiveDate, !hasConflict(on: today) { return true }
        return false
    }

    /// The target date for the + button, or nil to hide it
    private var plusButtonDate: Date? {
        if activeConflict != nil { return nil }
        if let date = selectedDate { return date }
        if let today = effectiveDate, !hasConflict(on: today) { return today }
        return nil
    }

    private func generateDatesAround(date: Date) -> [Date] {
        var dates: [Date] = []
        let today = calendar.startOfDay(for: Date())

        for offset in -5...5 {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                let compareDate = calendar.startOfDay(for: newDate)
                if compareDate <= today {
                    dates.append(newDate)
                }
            }
        }
        return dates
    }

    private func checkiCloudStatus() {
        PersistenceController.shared.checkiCloudStatus { available, message in
            if available {
                syncStatus = .available
            } else {
                syncStatus = .notAvailable(message ?? "iCloud not available")
            }
        }
    }

    private func scheduleBannerDismissal() {
        bannerDismissTask?.cancel()

        withAnimation(.easeInOut(duration: 0.3)) {
            showSyncBanner = true
        }

        bannerDismissTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)

            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSyncBanner = false
                }
            }
        }
    }

    private func observeSyncEvents() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: PersistenceController.shared.container,
            queue: .main
        ) { notification in
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event {

                if event.type == .import || event.type == .export {
                    if event.type == .import {
                        syncStatus = .syncing
                        scheduleBannerDismissal()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if event.error == nil {
                            syncStatus = .available
                            lastSyncTime = Date()
                        } else {
                            syncStatus = .error(event.error?.localizedDescription ?? "Sync error")
                        }

                        if event.type == .import {
                            scheduleBannerDismissal()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("BackgroundPrimary")
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // Top bar: Statistics + Settings
                    HStack {
                        Button(action: {
                            if purchaseManager.isPremium {
                                showStatistics = true
                            } else {
                                showPaywall = true
                            }
                        }) {
                            HStack(spacing: 9) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color("LabelPrimary"))
                                Text("Total Conflict")
                                    .font(.system(size: 17, weight: .regular))
                                    .tracking(-0.43)
                                    .foregroundColor(Color("LabelPrimary"))
                                Text("\(totalConflicts)")
                                    .font(.system(size: 17, weight: .regular))
                                    .tracking(-0.43)
                                    .foregroundColor(Color("LabelPrimary"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(height: 48)
                            .background(Color("BackgroundSecondary"))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color("LabelPrimary"))
                                .frame(width: 48, height: 48)
                                .background(Color("BackgroundSecondary"))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Month navigation
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(yearString)
                                .font(.system(size: 17, weight: .regular))
                                .tracking(-0.43)
                                .foregroundColor(Color("LabelPrimary"))
                            Text(monthString)
                                .font(.system(size: 34, weight: .bold))
                                .tracking(0.4)
                                .foregroundColor(Color("LabelPrimary"))
                        }

                        Spacer()

                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color("LabelPrimary"))
                                    .frame(width: 48, height: 48)
                                    .background(Color("BackgroundSecondary"))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                withAnimation {
                                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color("LabelPrimary"))
                                    .frame(width: 48, height: 48)
                                    .background(Color("BackgroundSecondary"))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)

                    // Weekday headers
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(Array(weekdayNames.enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(-0.08)
                                .foregroundColor(Color("LabelTertiary"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                        ForEach(monthDays, id: \.id) { dayItem in
                            if let date = dayItem.date {
                                let isFuture = isFutureDate(date)
                                let isTodayDate = isToday(date)
                                let hasConflictOnDate = hasConflict(on: date)
                                let isConflictSelected = selectedConflict != nil && selectedConflict?.date != nil && Calendar.current.isDate(date, inSameDayAs: selectedConflict!.date!)
                                let isDateSelected = selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
                                ZStack {
                                    if hasConflictOnDate {
                                        conflictShapeView(for: conflictIntensity(on: date), size: 34)
                                            .overlay(alignment: .bottom) {
                                                if hasNote(on: date) {
                                                    Circle()
                                                        .fill(Color("Orange"))
                                                        .frame(width: 5, height: 5)
                                                        .offset(y: 4)
                                                }
                                            }
                                            .opacity(isFuture ? 0.3 : 1.0)
                                    } else if isDateSelected || (isTodayDate && selectedDate == nil && selectedConflict == nil) {
                                        // Selected date or today as default selection: solid fill
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color("LabelPrimary"))
                                            .frame(width: 48, height: 48)
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.system(size: 15, weight: .regular))
                                            .tracking(-0.23)
                                            .foregroundColor(Color("White"))
                                    } else if isTodayDate {
                                        // Today when another date is selected: outline ring
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color("LabelPrimary"), lineWidth: 2)
                                            .frame(width: 48, height: 48)
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.system(size: 15, weight: .semibold))
                                            .tracking(-0.23)
                                            .foregroundColor(Color("LabelPrimary"))
                                    } else {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(.system(size: 15, weight: .regular))
                                            .tracking(-0.23)
                                            .foregroundColor(Color("LabelPrimary"))
                                            .opacity(isFuture ? 0.3 : 1.0)
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .background(
                                    (isConflictSelected || (isTodayDate && hasConflictOnDate && selectedDate == nil && selectedConflict == nil)) ?
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color("LabelTertiary"), lineWidth: 2)
                                        .frame(width: 48, height: 48) : nil
                                )
                                .contentShape(Rectangle())
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            guard !isFuture else { return }
                                            tappedDate = date
                                        }
                                        .onEnded { _ in
                                            guard !isFuture else {
                                                tappedDate = nil
                                                return
                                            }
                                            tappedDate = nil
                                            if hasConflictOnDate {
                                                selectedDate = nil
                                                selectedConflict = conflicts.first {
                                                    Calendar.current.isDate($0.date!, inSameDayAs: date)
                                                }
                                            } else {
                                                selectedConflict = nil
                                                selectedDate = date
                                            }
                                        }
                                )
                            } else {
                                Color.clear
                                    .frame(height: 48)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                let horizontalTranslation = value.translation.width
                                if horizontalTranslation > 50 {
                                    withAnimation {
                                        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
                                            currentMonth = previousMonth
                                        }
                                    }
                                } else if horizontalTranslation < -50 {
                                    withAnimation {
                                        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
                                            currentMonth = nextMonth
                                        }
                                    }
                                }
                            }
                    )
                    .sheet(item: $dateForNewConflict, onDismiss: {
                        if let date = dateForNewConflict?.date ?? lastNewConflictDate {
                            if let conflict = conflicts.first(where: {
                                guard let d = $0.date else { return false }
                                return Calendar.current.isDate(d, inSameDayAs: date)
                            }) {
                                selectedDate = nil
                                selectedConflict = conflict
                            }
                            lastNewConflictDate = nil
                        }
                    }) { identifiableDate in
                        ConflictEditorView(
                            dates: generateDatesAround(date: identifiableDate.date),
                            initialDate: identifiableDate.date
                        )
                        .environmentObject(conflictManager)
                        .presentationBackground(Color("BackgroundSecondary"))
                        .interactiveDismissDisabled()
                        .onAppear { lastNewConflictDate = identifiableDate.date }
                    }

                    // Conflict details or peaceful day message
                    if let conflict = activeConflict {
                        ConflictDetailView(
                            conflict: conflict,
                            onDelete: {
                                Task { @MainActor in
                                    do {
                                        guard let conflictDate = conflict.date else {
                                            selectedConflict = nil
                                            return
                                        }
                                        try conflictManager.deleteConflict(for: conflictDate)
                                        selectedConflict = nil
                                    } catch {
                                        print("Error deleting conflict: \(error)")
                                    }
                                }
                            },
                            onRefresh: {
                                if let conflictDate = conflict.date {
                                    selectedConflict = conflicts.first {
                                        Calendar.current.isDate($0.date!, inSameDayAs: conflictDate)
                                    }
                                }
                            }
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("BackgroundSecondary"))
                        )
                        .padding(.horizontal)
                        .padding(.top, 16)
                    } else if showPeacefulDay {
                   
                        HStack {
                            Spacer()
                            Text("A peaceful day")
                                .font(.system(size: 17, weight: .regular))
                                .tracking(-0.43)
                                .foregroundColor(Color("LabelSecondary"))
                                .padding(.top,48)
                            Spacer()
                        }
                    }

                    Spacer()
                }

                // Plus button
                if let targetDate = plusButtonDate {
                    Button(action: {
                        dateForNewConflict = IdentifiableDate(date: targetDate)
                    }) {
                        if #available(iOS 26.0, *) {
                            Text("+")
                                .font(.system(size: 22, weight: .regular))
                                .tracking(-0.26)
                                .foregroundColor(Color("LabelPrimary"))
                                .frame(width: 75, height: 60)
                                .background(Color("BackgroundSecondary"))
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                                .glassEffect(in: .capsule)
                        } else {
                            Text("+")
                                .font(.system(size: 22, weight: .regular))
                                .tracking(-0.26)
                                .foregroundColor(Color("LabelPrimary"))
                                .frame(width: 75, height: 60)
                                .background(Color("BackgroundSecondary"))
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                                
                        }
                            
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 16)
                }
            }
            .onChange(of: currentMonth) { _, _ in
                selectedConflict = nil
                selectedDate = nil
            }
            .onAppear {
                if purchaseManager.isPremium {
                    checkiCloudStatus()
                    observeSyncEvents()
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showStatistics) {
                StatisticsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .statistics)
                    .environmentObject(purchaseManager)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .top) {
                if showSyncBanner {
                    SyncStatusBanner(status: syncStatus, lastSyncTime: lastSyncTime)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: Conflict Detail View
struct ConflictDetailView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    let conflict: Conflict
    let onDelete: () -> Void
    let onRefresh: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var showEditSheet: IdentifiableDate? = nil

    private var calendar: Calendar {
        Calendar.current
    }

    private func generateDatesAround(date: Date) -> [Date] {
        var dates: [Date] = []
        let today = calendar.startOfDay(for: Date())

        for offset in -5...5 {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                let compareDate = calendar.startOfDay(for: newDate)
                if compareDate <= today {
                    dates.append(newDate)
                }
            }
        }
        return dates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: details + menu button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    // Date
                    HStack {
                        Text(NSLocalizedString("Date:", comment: ""))
                            .font(.headline)
                            .foregroundColor(Color("LabelTertiary"))
                        Text(dateFormatter.string(from: conflict.date ?? Date()))
                            .font(.body)
                            .foregroundColor(Color("LabelPrimary"))
                    }

                    // Intensity
                    HStack {
                        Text(NSLocalizedString("Intensity:", comment: ""))
                            .font(.headline)
                            .foregroundColor(Color("LabelTertiary"))
                        Text(ConflictIntensity(string: conflict.intensity)?.displayName ?? NSLocalizedString("unknown_intensity", comment: "Unknown intensity"))
                            .font(.body)
                            .foregroundColor(Color("LabelPrimary"))
                    }

                    // Emotions
                    HStack(alignment: .top){
                        Text(NSLocalizedString("Emotions:", comment: ""))
                            .font(.headline)
                            .foregroundColor(Color("LabelTertiary"))
                        if let emotionsString = conflict.emotions, !emotionsString.isEmpty {
                            Text(emotionsString.split(separator: ",").map { NSLocalizedString(String($0), comment: "") }.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(Color("LabelPrimary"))
                        } else {
                            Text(NSLocalizedString("None", comment: ""))
                                .font(.body)
                                .foregroundColor(Color("LabelTertiary"))
                        }
                    }
                }

                Spacer()

                Menu {
                    Button(action: {
                        if let date = conflict.date {
                            showEditSheet = IdentifiableDate(date: date)
                        }
                    }) {
                        Label(NSLocalizedString("Edit", comment: ""), systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color("LabelSecondary"))
                        .font(.body)
                        .padding(12)
                        .background(Circle().fill(Color("BackgroundSecondary")))
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Notes:", comment: ""))
                    .font(.headline)
                    .foregroundColor(Color("LabelTertiary"))

                if let notes = conflict.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(notes)
                        .font(.system(size: 15, weight: .regular))
                        .tracking(-0.23)
                        .foregroundColor(Color("LabelPrimary").opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(NSLocalizedString("None", comment: ""))
                        .font(.body)
                        .tracking(-0.23)
                        .foregroundColor(Color("LabelTertiary"))
                }
            }
        }
        .confirmationDialog(
            "Delete this conflict?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(item: $showEditSheet, onDismiss: {
            onRefresh()
        }) { identifiableDate in
            ConflictEditorView(
                dates: generateDatesAround(date: identifiableDate.date),
                initialDate: identifiableDate.date
            )
            .environmentObject(conflictManager)
            .presentationBackground(Color("BackgroundSecondary"))
            .interactiveDismissDisabled()
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Sync Status Banner
struct SyncStatusBanner: View {
    let status: SyncStatus
    let lastSyncTime: Date?

    private var bannerConfig: (icon: String, text: String, color: Color) {
        switch status {
        case .available:
            if let lastSync = lastSyncTime {
                let timeAgo = timeAgoString(from: lastSync)
                return ("checkmark.icloud.fill", "Synced \(timeAgo)", Color("Green"))
            }
            return ("checkmark.icloud.fill", "iCloud Synced", Color("Green"))
        case .syncing:
            return ("arrow.triangle.2.circlepath.icloud.fill", "Syncing...", Color("LabelPrimary"))
        case .notAvailable(let message):
            return ("exclamationmark.icloud.fill", message, Color("Orange"))
        case .error(let message):
            return ("xmark.icloud.fill", message, Color("Orange"))
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: bannerConfig.icon)
                .font(.system(size: 14))
                .foregroundColor(bannerConfig.color)

            Text(bannerConfig.text)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color("BackgroundSecondary"))
    }

    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}

// MARK: Preview
#Preview {
   
    CalendarView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
        .environmentObject(PurchaseManager.shared)
        .preferredColorScheme(.light)
    SyncStatusBanner(status: .syncing, lastSyncTime: Date())
}

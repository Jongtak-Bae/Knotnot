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

struct CalendarView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>

    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var selectedConflict: Conflict? = nil
    @State private var showSettings: Bool = false
    @State private var showStatistics: Bool = false
    @State private var dateForNewConflict: IdentifiableDate? = nil
    @State private var tappedDate: Date? = nil
    @State private var syncStatus: SyncStatus = .syncing
    @State private var lastSyncTime: Date?
    @State private var showSyncBanner: Bool = false
    @State private var bannerDismissTask: Task<Void, Never>?

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // Start week on Sunday
        return cal
    }
    // Localized weekday names
        private var weekdayNames: [String] {
            let formatter = DateFormatter()
            formatter.locale = Locale.current // Use device's current locale
            // Use veryShortWeekdaySymbols to match "Sun", "Mon", etc.
            let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            // Rotate array to start with the first weekday
            let firstWeek = calendar.firstWeekday - 1 // Convert to 0-indexed
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
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter.string(from: currentMonth)
    }
    
    private var detailDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    private var totalConflicts: Int {
        conflicts.count
    }
    
    private func hasConflict(on date: Date) -> Bool {
        conflicts.contains { conflict in
            guard let conflictDate = conflict.date else {
                print("Warning: Conflict with id \(conflict.id?.uuidString ?? "unknown") has nil date")
                return false
            }
            return Calendar.current.isDate(conflictDate, inSameDayAs: date)
        }
    }
    
    private func conflictIntensity(on date: Date) -> ConflictIntensity {
        conflicts.first { conflict in
            guard let conflictDate = conflict.date else {
                print("Warning: Conflict with id \(conflict.id?.uuidString ?? "unknown") has nil date")
                return false
            }
            return Calendar.current.isDate(conflictDate, inSameDayAs: date)
        }
        .flatMap { ConflictIntensity(string: $0.intensity) } ?? .moderate
    }
    
    private func conflictEmoji(on date: Date) -> String {
        switch conflictIntensity(on: date) {
        case .minor: return "☹️"
        case .moderate: return "😡"
        case .severe: return "👿"
        }
    }
    
    private func hasNote(on date: Date) -> Bool {
        if let conflict = conflicts.first(where: { conflict in
            guard let conflictDate = conflict.date else { return false }
            return Calendar.current.isDate(conflictDate, inSameDayAs: date)
        }) {
            return !(conflict.notes ?? "").isEmpty
        }
        return false
    }

    private func isFutureDate(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let compareDate = calendar.startOfDay(for: date)
        return compareDate > today
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func generateDatesAround(date: Date) -> [Date] {
        var dates: [Date] = []
        for offset in -5...5 {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                dates.append(newDate)
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
            // Don't show banner on initial status check, only on actual import events
        }
    }

    private func scheduleBannerDismissal() {
        // Cancel existing task
        bannerDismissTask?.cancel()

        // Show banner
        withAnimation(.easeInOut(duration: 0.3)) {
            showSyncBanner = true
        }

        // Schedule auto-dismiss after 5 seconds
        bannerDismissTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

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
                    // Only show banner for import events (receiving from iCloud)
                    if event.type == .import {
                        syncStatus = .syncing
                        scheduleBannerDismissal()
                    }

                    // Update to available after sync completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if event.error == nil {
                            syncStatus = .available
                            lastSyncTime = Date()
                        } else {
                            syncStatus = .error(event.error?.localizedDescription ?? "Sync error")
                        }

                        // Only show banner for import events
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
            VStack(alignment: .leading, spacing: 0) {
                // Total conflicts display with settings gear
                HStack {
                    Button(action: {
                        showStatistics = true
                    }) {
                        VStack(alignment: .leading) {
                            Text("Total Conflicts")
                                .foregroundStyle(.gray)
                            Text("\(totalConflicts)")
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.top, 6)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                
                Divider()
                
                // Month navigation
                HStack {
                    Button(action: {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text(monthName)
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Weekday headers
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                                    ForEach(Array(weekdayNames.enumerated()), id: \.offset) { index, day in
                                        Text(day)
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding()
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 20) {
                    ForEach(monthDays, id: \.id) { dayItem in
                        if let date = dayItem.date {
                            ZStack(alignment: .bottom) {
                                // Tap indicator background
                                if let tappedDate = tappedDate, Calendar.current.isDate(date, inSameDayAs: tappedDate) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                }

                                ZStack {
                                    let isFuture = isFutureDate(date)
                                    let isTodayDate = isToday(date)
                                    let circleColor: Color = hasConflict(on: date) ? conflictIntensity(on: date).color : .clear

                                    Circle()
                                        .fill(circleColor)
                                        .stroke(
                                            // Safely check if selectedConflict and its date are non-nil
                                            selectedConflict != nil && selectedConflict?.date != nil && Calendar.current.isDate(date, inSameDayAs: selectedConflict!.date!) ? Color.gray : Color.gray.opacity(0.5),
                                            lineWidth: selectedConflict != nil && selectedConflict?.date != nil && Calendar.current.isDate(date, inSameDayAs: selectedConflict!.date!) ? 3 : 0
                                        )
                                        .frame(width: 40, height: 40)
                                        .opacity(isFuture ? 0.3 : 1.0)

                                    // Today indicator border
                                    if isTodayDate {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                                            .frame(width: 40, height: 40)
                                    }

                                    Text(hasConflict(on: date) ? conflictEmoji(on: date) : "\(calendar.component(.day, from: date))")
                                        .font(.body)
                                        .foregroundColor(hasConflict(on: date) ? .white : .primary)
                                        .opacity(isFuture ? 0.3 : 1.0)
                                }
                                if hasNote(on: date) {
                                    Circle()
                                        .fill(conflictIntensity(on: date).color)
                                        .frame(width: 4, height: 4)
                                        .offset(y: 8)
                                }
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        guard !isFutureDate(date) else { return }
                                        tappedDate = date
                                    }
                                    .onEnded { _ in
                                        guard !isFutureDate(date) else {
                                            tappedDate = nil
                                            return
                                        }
                                        tappedDate = nil
                                        if hasConflict(on: date) {
                                            selectedConflict = conflicts.first {
                                                Calendar.current.isDate($0.date!, inSameDayAs: date)
                                            }
                                        } else {
                                            dateForNewConflict = IdentifiableDate(date: date)
                                        }
                                    }
                            )
                        } else {
                            Text("") // Empty cell for padding
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)
                .sheet(item: $dateForNewConflict) { identifiableDate in
                    NavigationStack {
                        ConflictEditorView(
                            dates: generateDatesAround(date: identifiableDate.date),
                            initialDate: identifiableDate.date
                        )
                        .environmentObject(conflictManager)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    dateForNewConflict = nil
                                }
                            }
                        }
                    }
                }


                // Conflict details
                if let conflict = selectedConflict {
                    ConflictDetailView(
                        conflict: conflict,
                        onDelete: {
                            Task { @MainActor in
                                do {
                                    guard let conflictDate = conflict.date else {
                                        print("Error: Conflict date is nil for id \(conflict.id?.uuidString ?? "unknown")")
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
                            // Refresh selectedConflict with updated data
                            if let conflictDate = conflict.date {
                                selectedConflict = conflicts.first {
                                    Calendar.current.isDate($0.date!, inSameDayAs: conflictDate)
                                }
                            }
                        }
                    )
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .onChange(of: currentMonth) { _, _ in
                selectedConflict = nil
            }
            .onAppear {
                checkiCloudStatus()
                observeSyncEvents()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showStatistics) {
                StatisticsView()
                    .environmentObject(conflictManager)
            }
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if showSyncBanner {
                    SyncStatusBanner(status: syncStatus, lastSyncTime: lastSyncTime)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
//            #if canImport(SwiftUI)
//            .background {
//                if #available(iOS 18.0, *) {
//                    MeshGradient(
//                        width: 3,
//                        height: 3,
//                        points: [
//                            .init(x: 0, y: 0), .init(x: 0.8, y: 0), .init(x: 1, y: 0),
//                            .init(x: 0, y: 0.2), .init(x: 0.1, y: 0.5), .init(x: 1, y: 0.5),
//                            .init(x: 0, y: 1), .init(x: 0, y: 1), .init(x: 1, y: 1)
//                        ],
//                        colors: [
//                            Color(hex: "#EAAB04").opacity(0.2), Color(hex: "#A640BC").opacity(0.2), Color(hex: "#A640BC").opacity(0.2),
//                            .clear, .clear, .clear,
//                            .clear, .clear, .clear
//                        ]
//                    )
//                }
//            }
//            #endif
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
        for offset in -5...5 {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                dates.append(newDate)
            }
        }
        return dates
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Date:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(dateFormatter.string(from: conflict.date ?? Date()))
                            .font(.body)
                    }
                    HStack {
                        Text("Intensity:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(ConflictIntensity(string: conflict.intensity)?.displayName ?? NSLocalizedString("unknown_intensity", comment: "Unknown intensity"))
                            .font(.body)
                    }
                    VStack(alignment: .leading) {
                        Text("Note:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(conflict.notes ?? "")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()

                VStack(spacing: 10) {
                    Button(action: {
                        if let date = conflict.date {
                            showEditSheet = IdentifiableDate(date: date)
                        }
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                            .font(.body)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 50.0)
                                .stroke(.gray.opacity(0.5)))
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.body)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 50.0)
                                .stroke(.red.opacity(0.5)))
                    }
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
            NavigationStack {
                ConflictEditorView(
                    dates: generateDatesAround(date: identifiableDate.date),
                    initialDate: identifiableDate.date
                )
                .environmentObject(conflictManager)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showEditSheet = nil
                        }
                    }
                }
            }
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
                return ("checkmark.icloud.fill", "Synced \(timeAgo)", .green)
            }
            return ("checkmark.icloud.fill", "iCloud Synced", .green)
        case .syncing:
            return ("arrow.triangle.2.circlepath.icloud.fill", "Syncing...", .blue)
        case .notAvailable(let message):
            return ("exclamationmark.icloud.fill", message, .orange)
        case .error(let message):
            return ("xmark.icloud.fill", message, .red)
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
        .background(bannerConfig.color.opacity(0.1))
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
        .preferredColorScheme(.dark)
}

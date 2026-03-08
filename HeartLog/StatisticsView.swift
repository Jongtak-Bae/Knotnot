import SwiftUI
import CoreData

struct StatisticsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: false)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>

    @EnvironmentObject private var conflictManager: ConflictManager
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var showPaywall = false

    // MARK: - Computed Properties

    private var conflictArray: [Conflict] { Array(conflicts) }

    private var currentStreakDays: Int {
        conflictManager.currentStreak(from: conflictArray)
    }

    private var monthComparisonData: (thisMonth: Int, lastMonth: Int) {
        conflictManager.monthComparison(from: conflictArray)
    }

    private var avgRecovery: Int? {
        conflictManager.averageRecoveryDays(from: conflictArray)
    }

    private var intensityTrendValue: Double? {
        conflictManager.intensityTrend(from: conflictArray)
    }

    private var weekdayCounts: [Int] {
        conflictManager.weekdayDistribution(from: conflictArray)
    }

    private var conflictsWithNotes: [Conflict] {
        conflicts.filter { conflict in
            guard let notes = conflict.notes else { return false }
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Chart Data

    private var intensityData: [(month: Date, minor: Int, moderate: Int, severe: Int)] {
        let calendar = Calendar.current
        let endDate = Date()
        let months = 8
        guard let startDate = calendar.date(byAdding: .month, value: -(months - 1), to: calendar.startOfMonth(for: endDate)) else {
            return []
        }

        var monthIntensity: [Date: (minor: Int, moderate: Int, severe: Int)] = [:]
        for conflict in conflicts {
            guard let date = conflict.date, date >= startDate, date <= endDate else { continue }
            let monthStart = calendar.startOfMonth(for: date)
            let intensity = ConflictIntensity(string: conflict.intensity) ?? .minor
            var current = monthIntensity[monthStart, default: (0, 0, 0)]
            switch intensity {
            case .minor: current.minor += 1
            case .moderate: current.moderate += 1
            case .severe: current.severe += 1
            }
            monthIntensity[monthStart] = current
        }

        return calendar.lastMonths(months, from: endDate).map { month in
            let counts = monthIntensity[month, default: (0, 0, 0)]
            return (month: month, minor: counts.minor, moderate: counts.moderate, severe: counts.severe)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Stat Cards (2x2 grid)
                statCardsSection

                // MARK: - Day of Week Pattern
                dayOfWeekSection
                    .padding(.top, 40)

                // MARK: - Monthly Conflicts
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("Monthly Conflicts", comment: ""))
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.43)
                        .foregroundColor(Color("LabelPrimary"))
                        .padding(.horizontal, 28)

                    MonthlyConflictsChart(data: intensityData)
                        .padding(.horizontal, 28)
                }
                .padding(.top, 40)

                // MARK: - Top Emotions (Premium)
                topEmotionsSection
                    .padding(.top, 40)

                // MARK: - Conflict-Free Streaks
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("Conflict-Free Streaks", comment: ""))
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(-0.43)
                        .foregroundColor(Color("LabelPrimary"))
                        .padding(.horizontal, 28)

                    StreakTimelineView(
                        conflicts: conflictArray,
                        months: 4
                    )
                    .padding(.horizontal, 28)
                }
                .padding(.top, 40)

                // MARK: - Notes
                notesSection
                    .padding(.top, 40)

                Spacer(minLength: 40)
            }
        }
        .background(Color("BackgroundPrimary"))
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(feature: .emotionTags)
        }
    }

    // MARK: - Stat Cards

    private var allStatThresholdsMet: Bool {
        !conflicts.isEmpty
            && (monthComparisonData.thisMonth > 0 || monthComparisonData.lastMonth > 0)
            && avgRecovery != nil
            && intensityTrendValue != nil
    }

    private var encouragementBannerText: String {
        if conflicts.isEmpty {
            return NSLocalizedString("Start logging to see trends!", comment: "Encouragement for new users with no data")
        }
        if avgRecovery == nil {
            return NSLocalizedString("Keep logging to see trends", comment: "Encouragement when not enough data for recovery calculation")
        }
        if intensityTrendValue == nil {
            return NSLocalizedString("Keep logging to see trends", comment: "Encouragement when not enough data for intensity trend")
        }
        return NSLocalizedString("Keep logging to see trends", comment: "Encouragement when no conflicts in 60-day window")
    }

    private var statCardsSection: some View {
        VStack(spacing: 24) {
            if !allStatThresholdsMet {
                Text(encouragementBannerText)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color("LabelTertiary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color("BackgroundSecondary"))
                    )
            }

            HStack(spacing: 24) {
                // Current Streak
                StatCard(
                    label: NSLocalizedString("Current Streak", comment: ""),
                    value: conflicts.isEmpty
                        ? "—"
                        : (currentStreakDays > 0
                            ? String.localizedStringWithFormat(
                                NSLocalizedString("%d days", comment: "Number of days in streak"),
                                currentStreakDays)
                            : NSLocalizedString("0 days", comment: "Zero days streak")),
                    accent: !conflicts.isEmpty && currentStreakDays > 0 ? Color("Green") : nil
                )

                // Last 30 Days vs Previous 30
                StatCard(
                    label: NSLocalizedString("Last 30 Days", comment: ""),
                    value: (monthComparisonData.thisMonth == 0 && monthComparisonData.lastMonth == 0)
                        ? "—"
                        : monthComparisonText,
                    accent: (monthComparisonData.thisMonth == 0 && monthComparisonData.lastMonth == 0)
                        ? nil
                        : monthComparisonAccent
                )
            }
            HStack(spacing: 24) {
                // Avg Recovery
                StatCard(
                    label: NSLocalizedString("Avg Recovery", comment: ""),
                    value: avgRecovery.map {
                        String.localizedStringWithFormat(
                            NSLocalizedString("%d days", comment: "Average recovery days"),
                            $0)
                    } ?? "—"
                )

                // Intensity Trend
                StatCard(
                    label: NSLocalizedString("Intensity", comment: ""),
                    value: intensityTrendText,
                    accent: intensityTrendAccent
                )
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 32)
    }

    private var monthComparisonText: String {
        let diff = monthComparisonData.lastMonth - monthComparisonData.thisMonth
        if diff > 0 {
            return String.localizedStringWithFormat(
                NSLocalizedString("%d fewer", comment: "Fewer conflicts than last month"),
                diff) + " ↓"
        } else if diff < 0 {
            return String.localizedStringWithFormat(
                NSLocalizedString("%d more", comment: "More conflicts than last month"),
                -diff) + " ↑"
        } else {
            return NSLocalizedString("Same", comment: "Same as last month")
        }
    }

    private var monthComparisonAccent: Color? {
        let diff = monthComparisonData.lastMonth - monthComparisonData.thisMonth
        if diff > 0 { return Color("Green") }
        if diff < 0 { return Color("Orange") }
        return nil
    }

    private var intensityTrendText: String {
        guard let trend = intensityTrendValue else {
            return "—"
        }
        if trend < -0.15 {
            return NSLocalizedString("Milder", comment: "Intensity getting milder") + " ↓"
        } else if trend > 0.15 {
            return NSLocalizedString("Rising", comment: "Intensity rising") + " ↑"
        } else {
            return NSLocalizedString("Stable", comment: "Intensity stable")
        }
    }

    private var intensityTrendAccent: Color? {
        guard let trend = intensityTrendValue else { return nil }
        if trend < -0.15 { return Color("Green") }
        if trend > 0.15 { return Color("Orange") }
        return nil
    }

    // MARK: - Day of Week

    private var dayOfWeekSection: some View {
        let counts = weekdayCounts
        let totalConflicts = counts.reduce(0, +)

        return VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("When do conflicts happen?", comment: ""))
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))

            if totalConflicts < 5 {
                Text(NSLocalizedString("Log a few more to see patterns", comment: "Encouragement when not enough data for weekly pattern"))
                    .font(.system(size: 15))
                    .foregroundColor(Color("LabelTertiary"))
                    .padding(.top, 4)
            } else {
                WeekdayBarChart(counts: counts)

                // Insight text — only show when ≥10 conflicts for confidence
                if totalConflicts >= 10, let day = busiestWeekday(counts: counts) {
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("%@ is your toughest day", comment: "Busiest day insight"),
                        day))
                        .font(.system(size: 13))
                        .foregroundColor(Color("LabelSecondary"))
                        .padding(.top, 4)
                } else if totalConflicts >= 10 {
                    Text(NSLocalizedString("No clear pattern yet", comment: "When data exists but no dominant day"))
                        .font(.system(size: 13))
                        .foregroundColor(Color("LabelSecondary"))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 28)
    }

    private func busiestWeekday(counts: [Int]) -> String? {
        let maxCount = counts.max() ?? 0
        guard maxCount > 0 else { return nil }

        // Check if distribution is roughly even (no clear pattern)
        let total = counts.reduce(0, +)
        let avg = Double(total) / 7.0
        let maxRatio = Double(maxCount) / max(avg, 1)
        guard maxRatio > 1.3 else { return nil } // Need at least 30% above average

        guard let maxIndex = counts.firstIndex(of: maxCount) else { return nil }

        let formatter = DateFormatter()
        // weekdaySymbols[0] = Sunday, matches our index
        return formatter.weekdaySymbols[maxIndex]
    }

    // MARK: - Top Emotions

    private var topEmotionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Your most common emotions", comment: ""))
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))

            if purchaseManager.isPremium {
                let topEmotions = conflictManager.topEmotions(from: conflictArray, limit: 5)

                if topEmotions.isEmpty {
                    Text(NSLocalizedString("No emotion data yet", comment: ""))
                        .font(.system(size: 15))
                        .foregroundColor(Color("LabelTertiary"))
                        .padding(.top, 4)
                } else {
                    TopEmotionsChart(emotions: topEmotions)

                    // Co-occurrence insight
                    if let pair = conflictManager.topEmotionCoOccurrence(from: conflictArray), pair.count >= 2 {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("'%@' and '%@' often appear together", comment: "Emotion co-occurrence insight"),
                            NSLocalizedString(pair.emotion1, comment: ""),
                            NSLocalizedString(pair.emotion2, comment: "")))
                            .font(.system(size: 13))
                            .foregroundColor(Color("LabelSecondary"))
                            .padding(.top, 4)
                    }
                }
            } else {
                // Locked state for free users
                ZStack {
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color("Orange").opacity(0.3))
                                    .frame(width: CGFloat.random(in: 80...200), height: 24)
                                Spacer()
                            }
                        }
                    }
                    .blur(radius: 4)

                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13))
                            Text(NSLocalizedString("Unlock", comment: ""))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color("LabelPrimary"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color("BackgroundSecondary"))
                        )
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Notes", comment: ""))
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary"))

            // Reflection rate
            let rate = conflictManager.notesReflectionRate(from: conflictArray)
            if rate.total > 0 {
                let pct = rate.total > 0 ? Int(Double(rate.withNotes) / Double(rate.total) * 100) : 0
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("You reflected on %d of %d conflicts (%d%%)", comment: "Notes reflection rate"),
                    rate.withNotes, rate.total, pct))
                    .font(.system(size: 13))
                    .foregroundColor(Color("LabelSecondary"))
            }

            if conflictsWithNotes.isEmpty {
                Text(NSLocalizedString("No notes yet", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(Color("LabelTertiary"))
                    .padding(.top, 8)
            } else {
                ForEach(conflictsWithNotes, id: \.id) { conflict in
                    NoteCard(conflict: conflict)
                }
            }
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let label: String
    let value: String
    var accent: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .tracking(-0.23)
                .foregroundColor(Color("LabelPrimary"))

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .tracking(0.38)
                .foregroundColor(accent ?? Color("LabelPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
        )
    }
}

// MARK: - Weekday Bar Chart

struct WeekdayBarChart: View {
    let counts: [Int] // 7 elements, index 0 = Sunday

    // Reorder to Mon–Sun for display
    private var displayOrder: [(index: Int, label: String)] {
        let formatter = DateFormatter()
        let symbols = formatter.shortWeekdaySymbols! // Sun, Mon, ..., Sat
        // Mon(1), Tue(2), Wed(3), Thu(4), Fri(5), Sat(6), Sun(0)
        let order = [1, 2, 3, 4, 5, 6, 0]
        return order.map { (index: $0, label: symbols[$0]) }
    }

    var body: some View {
        let maxCount = counts.max() ?? 1

        VStack(spacing: 8) {
            ForEach(displayOrder, id: \.index) { item in
                HStack(spacing: 10) {
                    Text(item.label)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color("LabelPrimary"))
                        .frame(width: 36, alignment: .leading)

                    GeometryReader { geo in
                        let count = counts[item.index]
                        let ratio = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                        let isBusiest = count == maxCount && count > 0

                        RoundedRectangle(cornerRadius: 6)
                            .fill(isBusiest ? Color("Orange") : Color("Orange").opacity(0.35))
                            .frame(width: max(ratio * geo.size.width, count > 0 ? 4 : 0), height: 24)
                    }
                    .frame(height: 24)

                    let count = counts[item.index]
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color("LabelSecondary"))
                            .frame(width: 24, alignment: .trailing)
                    } else {
                        Color.clear.frame(width: 24)
                    }
                }
            }
        }
    }
}

// MARK: - Top Emotions Chart

struct TopEmotionsChart: View {
    let emotions: [(emotion: String, count: Int)]

    var body: some View {
        let maxCount = emotions.first?.count ?? 1

        VStack(spacing: 10) {
            ForEach(emotions, id: \.emotion) { item in
                HStack(spacing: 10) {
                    Text(LocalizedStringKey(item.emotion))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("LabelPrimary"))
                        .frame(width: 100, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geo in
                        let ratio = maxCount > 0 ? CGFloat(item.count) / CGFloat(maxCount) : 0

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("Orange"))
                            .frame(width: max(ratio * geo.size.width, 4), height: 24)
                    }
                    .frame(height: 24)

                    Text("\(item.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color("LabelSecondary"))
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Monthly Conflicts Chart (Custom stacked bars)
struct MonthlyConflictsChart: View {
    let data: [(month: Date, minor: Int, moderate: Int, severe: Int)]

    private var maxCount: Int {
        data.map { $0.minor + $0.moderate + $0.severe }.max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 6) {
                    StackedBar(
                        minor: item.minor,
                        moderate: item.moderate,
                        severe: item.severe,
                        maxCount: max(maxCount, 1)
                    )
                    .frame(height: 164)

                    Text(monthLabel(item.month))
                        .font(.system(size: 11, weight: .regular))
                        .tracking(-0.08)
                        .foregroundColor(Color("LabelPrimary"))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func monthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Stacked Bar
struct StackedBar: View {
    let minor: Int
    let moderate: Int
    let severe: Int
    let maxCount: Int

    private var total: Int { minor + moderate + severe }

    var body: some View {
        GeometryReader { geo in
            let barHeight = geo.size.height
            let fillRatio = total > 0 ? CGFloat(total) / CGFloat(maxCount) : 0
            let filledHeight = barHeight * fillRatio

            ZStack(alignment: .bottom) {
                // Track background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("BackgroundSecondary"))
                    .frame(width: 32, height: barHeight)

                // Stacked segments
                if total > 0 {
                    VStack(spacing: 0) {
                        // Severe (top — purple)
                        if severe > 0 {
                            let h = filledHeight * CGFloat(severe) / CGFloat(total)
                            UnevenRoundedRectangle(
                                topLeadingRadius: (moderate == 0 && minor == 0) ? 16 : 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: (moderate == 0 && minor == 0) ? 16 : 0
                            )
                            .fill(Color("Purple"))
                            .frame(width: 32, height: h)
                        }

                        // Moderate (middle — orange)
                        if moderate > 0 {
                            let h = filledHeight * CGFloat(moderate) / CGFloat(total)
                            UnevenRoundedRectangle(
                                topLeadingRadius: (severe == 0 && minor == 0) ? 16 : 0,
                                bottomLeadingRadius: (minor == 0) ? 16 : 0,
                                bottomTrailingRadius: (minor == 0) ? 16 : 0,
                                topTrailingRadius: (severe == 0 && minor == 0) ? 16 : 0
                            )
                            .fill(Color("Orange"))
                            .frame(width: 32, height: h)
                        }

                        // Minor (bottom — yellow)
                        if minor > 0 {
                            let h = filledHeight * CGFloat(minor) / CGFloat(total)
                            UnevenRoundedRectangle(
                                topLeadingRadius: (severe == 0 && moderate == 0) ? 16 : 0,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: (severe == 0 && moderate == 0) ? 16 : 0
                            )
                            .fill(Color("Yellow"))
                            .frame(width: 32, height: h)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Streak Timeline View
struct StreakTimelineView: View {
    let conflicts: [Conflict]
    let months: Int

    private var calendar: Calendar { Calendar.current }

    private struct DayEntry: Identifiable {
        let id = UUID()
        let date: Date
        let hasConflict: Bool
        let intensity: ConflictIntensity?
    }

    private var dateRange: (start: Date, end: Date) {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .month, value: -(months - 1), to: calendar.startOfMonth(for: today))!
        return (start, today)
    }

    private var days: [DayEntry] {
        let range = dateRange
        let conflictMap: [Date: ConflictIntensity] = {
            var map: [Date: ConflictIntensity] = [:]
            for conflict in conflicts {
                guard let date = conflict.date else { continue }
                let day = calendar.startOfDay(for: date)
                if day >= range.start && day <= range.end {
                    map[day] = ConflictIntensity(string: conflict.intensity) ?? .minor
                }
            }
            return map
        }()

        var entries: [DayEntry] = []
        var current = range.start
        while current <= range.end {
            let intensity = conflictMap[current]
            entries.append(DayEntry(
                date: current,
                hasConflict: intensity != nil,
                intensity: intensity
            ))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return entries
    }

    private var monthLabels: [(label: String, position: CGFloat)] {
        let range = dateRange
        let totalDays = CGFloat(calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
        var labels: [(String, CGFloat)] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var current = range.start
        while current <= range.end {
            let monthStart = calendar.startOfMonth(for: current)
            if monthStart >= range.start {
                let dayOffset = CGFloat(calendar.dateComponents([.day], from: range.start, to: monthStart).day ?? 0)
                let position = dayOffset / totalDays
                labels.append((formatter.string(from: monthStart), position))
            }
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else { break }
            current = nextMonth
        }
        return labels
    }

    var body: some View {
        let dayEntries = days
        let runs = buildRuns(from: dayEntries)
        let totalDayCount = dayEntries.count

        GeometryReader { geo in
            let availableWidth = geo.size.width
            VStack(alignment: .leading, spacing: 8) {
                // Timeline bar
                HStack(spacing: 1) {
                    ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                        let proportion = CGFloat(run.days) / CGFloat(max(totalDayCount, 1))
                        let segmentWidth = max(proportion * availableWidth, run.isConflict ? 6 : 2)
                        if run.isConflict {
                            Circle()
                                .fill(run.color)
                                .frame(width: 6, height: 6)
                                .frame(width: segmentWidth, height: 25)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("Green"))
                                .frame(width: segmentWidth, height: 25)
                        }
                    }
                }

                // Month labels
                ZStack(alignment: .leading) {
                    ForEach(Array(monthLabels.enumerated()), id: \.offset) { _, entry in
                        Text(entry.label)
                            .font(.system(size: 11, weight: .regular))
                            .tracking(-0.08)
                            .foregroundColor(Color("LabelPrimary"))
                            .offset(x: entry.position * availableWidth)
                    }
                }
                .frame(height: 18)
            }
        }
        .frame(height: 51)
    }

    private struct Run {
        let days: Int
        let isConflict: Bool
        let color: Color
    }

    private func buildRuns(from dayEntries: [DayEntry]) -> [Run] {
        guard !dayEntries.isEmpty else { return [] }

        var runs: [Run] = []
        var i = 0

        while i < dayEntries.count {
            let entry = dayEntries[i]
            if entry.hasConflict {
                let color: Color = {
                    switch entry.intensity {
                    case .minor: return Color("Yellow")
                    case .moderate: return Color("Orange")
                    case .severe: return Color("Purple")
                    case .none: return Color("Orange")
                    }
                }()
                runs.append(Run(days: 1, isConflict: true, color: color))
                i += 1
            } else {
                var count = 0
                while i < dayEntries.count && !dayEntries[i].hasConflict {
                    count += 1
                    i += 1
                }
                runs.append(Run(days: count, isConflict: false, color: Color("Green")))
            }
        }
        return runs
    }
}

// MARK: - Note Card
struct NoteCard: View {
    let conflict: Conflict

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(conflict.notes ?? "")
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.43)
                .foregroundColor(Color("LabelPrimary").opacity(0.7))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(conflict.date.map { dateFormatter.string(from: $0) } ?? "")
                .font(.system(size: 13, weight: .regular))
                .tracking(-0.08)
                .foregroundColor(Color("LabelPrimary").opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("BackgroundSecondary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StatisticsView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
            .environmentObject(PurchaseManager.shared)
            .preferredColorScheme(.dark)
    }
}

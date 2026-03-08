import Foundation
import CoreData

// MARK: - Analytics Extension
extension ConflictManager {

    // MARK: - Monthly Aggregations

    /// Get conflict counts grouped by month
    /// - Parameter months: Number of months to look back (default: 6)
    /// - Returns: Array of tuples containing month start date and count
    func monthlyConflictCounts(last months: Int = 6) -> [(month: Date, count: Int)] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -(months - 1), to: calendar.startOfMonth(for: endDate)) else {
            return []
        }

        // Fetch all conflicts in range
        let request: NSFetchRequest<Conflict> = Conflict.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                       startDate as NSDate,
                                       endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)]

        guard let conflicts = try? context.fetch(request) else {
            return []
        }

        // Group by month
        var monthCounts: [Date: Int] = [:]
        for conflict in conflicts {
            guard let date = conflict.date else { continue }
            let monthStart = calendar.startOfMonth(for: date)
            monthCounts[monthStart, default: 0] += 1
        }

        // Generate all months in range (including months with 0 conflicts)
        let monthsArray = calendar.lastMonths(months, from: endDate)
        return monthsArray.map { month in
            (month: month, count: monthCounts[month, default: 0])
        }
    }

    /// Get intensity distribution per month
    /// - Parameter months: Number of months to look back (default: 6)
    /// - Returns: Array of tuples with month and intensity counts
    func monthlyIntensityDistribution(last months: Int = 6) -> [(month: Date, minor: Int, moderate: Int, severe: Int)] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -(months - 1), to: calendar.startOfMonth(for: endDate)) else {
            return []
        }

        // Fetch all conflicts in range
        let request: NSFetchRequest<Conflict> = Conflict.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                       startDate as NSDate,
                                       endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conflict.date, ascending: true)]

        guard let conflicts = try? context.fetch(request) else {
            return []
        }

        // Group by month and intensity
        var monthIntensity: [Date: (minor: Int, moderate: Int, severe: Int)] = [:]
        for conflict in conflicts {
            guard let date = conflict.date else { continue }
            let monthStart = calendar.startOfMonth(for: date)

            let intensity = ConflictIntensity(string: conflict.intensity) ?? .minor
            var current = monthIntensity[monthStart, default: (0, 0, 0)]

            switch intensity {
            case .minor:
                current.minor += 1
            case .moderate:
                current.moderate += 1
            case .severe:
                current.severe += 1
            }

            monthIntensity[monthStart] = current
        }

        // Generate all months in range
        let monthsArray = calendar.lastMonths(months, from: endDate)
        return monthsArray.map { month in
            let counts = monthIntensity[month, default: (0, 0, 0)]
            return (month: month, minor: counts.minor, moderate: counts.moderate, severe: counts.severe)
        }
    }

    /// Calculate all conflict-free streaks
    /// - Parameter conflicts: Array of conflicts to analyze
    /// - Returns: Array of streak information (start, end, days)
    func calculateStreaks(from conflicts: [Conflict]) -> [(start: Date, end: Date, days: Int)] {
        guard !conflicts.isEmpty else { return [] }

        let calendar = Calendar.current
        let conflictDates = Set(conflicts.compactMap { conflict -> Date? in
            guard let date = conflict.date else { return nil }
            return calendar.startOfDay(for: date)
        })

        guard let earliestDate = conflictDates.min(),
              let latestDate = conflictDates.max() else { return [] }

        var streaks: [(start: Date, end: Date, days: Int)] = []
        var streakStart: Date?
        var currentDate = earliestDate

        while currentDate <= latestDate {
            if !conflictDates.contains(currentDate) {
                // Start or continue streak
                if streakStart == nil {
                    streakStart = currentDate
                }
            } else {
                // Conflict found, end current streak
                if let start = streakStart {
                    let end = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                    let days = calendar.dateComponents([.day], from: start, to: currentDate).day ?? 0
                    if days > 0 {
                        streaks.append((start: start, end: end, days: days))
                    }
                    streakStart = nil
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Handle ongoing streak
        if let start = streakStart {
            let days = calendar.dateComponents([.day], from: start, to: currentDate).day ?? 0
            if days > 0 {
                streaks.append((start: start, end: latestDate, days: days))
            }
        }

        return streaks
    }

    /// Get current active streak (if any)
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: Number of days in current streak
    func currentStreak(from conflicts: [Conflict]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let conflictDates = Set(conflicts.compactMap { conflict -> Date? in
            guard let date = conflict.date else { return nil }
            return calendar.startOfDay(for: date)
        })

        // If there's a conflict today, streak is 0
        if conflictDates.contains(today) {
            return 0
        }

        // Count back from today
        var streakDays = 0
        var checkDate = today

        while !conflictDates.contains(checkDate) {
            streakDays += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay

            // Limit check to reasonable range (e.g., 1 year back)
            if streakDays > 365 {
                break
            }
        }

        return streakDays
    }

    // MARK: - Month Comparison

    /// Compare last 30 days vs the 30 days before that
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: (recent, previous) counts for each 30-day window
    func monthComparison(from conflicts: [Conflict]) -> (thisMonth: Int, lastMonth: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyAgo = calendar.date(byAdding: .day, value: -30, to: today),
              let sixtyAgo = calendar.date(byAdding: .day, value: -60, to: today) else {
            return (0, 0)
        }

        var recentCount = 0
        var previousCount = 0

        for conflict in conflicts {
            guard let date = conflict.date else { continue }
            let day = calendar.startOfDay(for: date)
            if day >= thirtyAgo && day <= today {
                recentCount += 1
            } else if day >= sixtyAgo && day < thirtyAgo {
                previousCount += 1
            }
        }

        return (recentCount, previousCount)
    }

    // MARK: - Average Recovery Days

    /// Average days between conflicts in the last 90 days
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: Average gap in days, or nil if not enough data
    func averageRecoveryDays(from conflicts: [Conflict]) -> Int? {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        guard let cutoff = calendar.date(byAdding: .day, value: -90, to: now) else { return nil }

        let recentDates = conflicts.compactMap { conflict -> Date? in
            guard let date = conflict.date else { return nil }
            let day = calendar.startOfDay(for: date)
            return day >= cutoff ? day : nil
        }.sorted()

        guard recentDates.count >= 2 else { return nil }

        let uniqueDates = Array(Set(recentDates)).sorted()
        guard uniqueDates.count >= 2 else { return nil }

        var totalGap = 0
        for i in 1..<uniqueDates.count {
            let gap = calendar.dateComponents([.day], from: uniqueDates[i - 1], to: uniqueDates[i]).day ?? 0
            totalGap += gap
        }

        return totalGap / (uniqueDates.count - 1)
    }

    // MARK: - Intensity Trend

    /// Compare average intensity this month vs last 3 months
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: trend direction: negative = getting milder, positive = getting more intense, 0 = stable, nil = not enough data
    func intensityTrend(from conflicts: [Conflict]) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let thisMonthStart = calendar.startOfMonth(for: now)
        guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: thisMonthStart) else { return nil }

        var thisMonthValues: [Double] = []
        var prevValues: [Double] = []

        for conflict in conflicts {
            guard let date = conflict.date else { continue }
            let intensity = ConflictIntensity(string: conflict.intensity) ?? .minor
            let value = Double(intensity.rawValue)
            let day = calendar.startOfDay(for: date)

            if day >= thisMonthStart {
                thisMonthValues.append(value)
            } else if day >= threeMonthsAgo && day < thisMonthStart {
                prevValues.append(value)
            }
        }

        guard !thisMonthValues.isEmpty, !prevValues.isEmpty else { return nil }

        let thisAvg = thisMonthValues.reduce(0, +) / Double(thisMonthValues.count)
        let prevAvg = prevValues.reduce(0, +) / Double(prevValues.count)

        return thisAvg - prevAvg
    }

    // MARK: - Weekday Distribution

    /// Count conflicts by day of week
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: Array of 7 counts, index 0 = Sunday, 6 = Saturday
    func weekdayDistribution(from conflicts: [Conflict]) -> [Int] {
        let calendar = Calendar.current
        var counts = [Int](repeating: 0, count: 7)

        for conflict in conflicts {
            guard let date = conflict.date else { continue }
            let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
            counts[weekday - 1] += 1
        }

        return counts
    }

    // MARK: - Top Emotions

    /// Get top emotions by frequency
    /// - Parameters:
    ///   - conflicts: Array of all conflicts
    ///   - limit: Max number of emotions to return
    /// - Returns: Array of (emotion, count) sorted descending
    func topEmotions(from conflicts: [Conflict], limit: Int = 5) -> [(emotion: String, count: Int)] {
        var emotionCounts: [String: Int] = [:]

        for conflict in conflicts {
            guard let emotionString = conflict.emotions, !emotionString.isEmpty else { continue }
            let tags = emotionString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            for tag in tags where !tag.isEmpty {
                emotionCounts[tag, default: 0] += 1
            }
        }

        return emotionCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (emotion: $0.key, count: $0.value) }
    }

    // MARK: - Emotion Co-occurrence

    /// Find the top co-occurring emotion pair
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: Top pair and count, or nil if no pairs
    func topEmotionCoOccurrence(from conflicts: [Conflict]) -> (emotion1: String, emotion2: String, count: Int)? {
        var pairCounts: [String: Int] = [:]

        for conflict in conflicts {
            guard let emotionString = conflict.emotions, !emotionString.isEmpty else { continue }
            let tags = emotionString.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            guard tags.count >= 2 else { continue }

            for i in 0..<tags.count {
                for j in (i + 1)..<tags.count {
                    let pair = [tags[i], tags[j]].sorted()
                    let key = pair.joined(separator: "|")
                    pairCounts[key, default: 0] += 1
                }
            }
        }

        guard let topPair = pairCounts.max(by: { $0.value < $1.value }) else { return nil }
        let parts = topPair.key.components(separatedBy: "|")
        guard parts.count == 2 else { return nil }
        return (emotion1: parts[0], emotion2: parts[1], count: topPair.value)
    }

    // MARK: - Notes Reflection Rate

    /// Count conflicts with and without notes
    /// - Parameter conflicts: Array of all conflicts
    /// - Returns: (withNotes, total) counts
    func notesReflectionRate(from conflicts: [Conflict]) -> (withNotes: Int, total: Int) {
        let total = conflicts.filter { $0.date != nil }.count
        let withNotes = conflicts.filter { conflict in
            guard let notes = conflict.notes else { return false }
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
        return (withNotes, total)
    }
}

// MARK: - Calendar Extensions
extension Calendar {
    /// Get start of month for a date
    func startOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }

    /// Generate array of last N months (as start-of-month dates)
    func lastMonths(_ count: Int, from date: Date = Date()) -> [Date] {
        let endMonth = startOfMonth(for: date)
        var months: [Date] = []

        for i in (0..<count).reversed() {
            if let month = self.date(byAdding: .month, value: -i, to: endMonth) {
                months.append(month)
            }
        }

        return months
    }

    /// Get month abbreviation for a date
    func monthAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

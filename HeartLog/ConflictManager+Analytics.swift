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

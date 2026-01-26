import SwiftUI
import CoreData

struct StatisticsView: View {
    @EnvironmentObject private var conflictManager: ConflictManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conflict.date, ascending: false)],
        animation: .default)
    private var conflicts: FetchedResults<Conflict>

    private var totalConflicts: Int {
        conflicts.filter { $0.date != nil }.count
    }

    private var conflictsThisYear: Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return conflicts.filter { conflict in
            guard let date = conflict.date else { return false }
            return calendar.component(.year, from: date) == currentYear
        }.count
    }

    private var monthAverage: Int {
        guard !conflicts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let dates = conflicts.compactMap { $0.date }

        guard let earliestDate = dates.min(),
              let latestDate = dates.max() else { return 0 }

        let components = calendar.dateComponents([.month], from: earliestDate, to: latestDate)
        let months = max((components.month ?? 0) + 1, 1)

        return conflicts.count / months
    }

    private var streakRecord: Int {
        guard !conflicts.isEmpty else { return 0 }

        let calendar = Calendar.current
        let conflictDates = Set(conflicts.compactMap { conflict -> Date? in
            guard let date = conflict.date else { return nil }
            return calendar.startOfDay(for: date)
        })

        guard let earliestDate = conflictDates.min(),
              let latestDate = conflictDates.max() else { return 0 }

        var currentStreak = 0
        var maxStreak = 0
        var currentDate = earliestDate

        while currentDate <= latestDate {
            if !conflictDates.contains(currentDate) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return maxStreak
    }

    private var conflictsWithNotes: [Conflict] {
        conflicts.filter { conflict in
            guard let notes = conflict.notes else { return false }
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - Chart Data

    private var monthlyData: [(month: Date, count: Int)] {
        conflictManager.monthlyConflictCounts(last: 6)
    }

    private var intensityData: [(month: Date, minor: Int, moderate: Int, severe: Int)] {
        conflictManager.monthlyIntensityDistribution(last: 6)
    }

    private var streakData: [StreakData] {
        let allStreaks = conflictManager.calculateStreaks(from: Array(conflicts))
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return allStreaks.map { streak in
            // Check if this is the current streak (ends today or in the future)
            let isCurrent = streak.end >= today
            return StreakData(
                start: streak.start,
                end: streak.end,
                days: streak.days,
                isCurrent: isCurrent
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statistics Cards
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        StatCard(label: NSLocalizedString("Total Conflicts", comment: "Total conflicts stat label"), value: "\(totalConflicts)")
                        StatCard(label: NSLocalizedString("This Year", comment: "This year stat label"), value: "\(conflictsThisYear)")
                    }

                    HStack(spacing: 12) {
                        StatCard(label: NSLocalizedString("Month Avg", comment: "Month average stat label"), value: "\(monthAverage)")
                        StatCard(label: NSLocalizedString("Streak", comment: "Streak record stat label"), value: "\(streakRecord)", showInfoIcon: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Trend Charts
                if #available(iOS 16.0, *) {
                    VStack(spacing: 16) {
                        ConflictFrequencyChart(data: monthlyData)

                        IntensityDistributionChart(data: intensityData)

                        StreakVisualizationChart(
                            streaks: streakData,
                            conflicts: Array(conflicts)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                } else {
                    Text(NSLocalizedString("Trends require iOS 16 or later", comment: "iOS version requirement message"))
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                }

                // Notes Section
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("Notes", comment: "Notes section header"))
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.horizontal, 30)

                    if conflictsWithNotes.isEmpty {
                        Text(NSLocalizedString("No notes yet", comment: "Empty notes message"))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                    } else {
                        ForEach(conflictsWithNotes, id: \.id) { conflict in
                            NoteCard(conflict: conflict)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 32)

                Spacer(minLength: 20)
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let label: String
    let value: String
    var showInfoIcon: Bool = false
    @State private var showInfoPopover: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 17))
                    .foregroundColor(.primary.opacity(0.5))
                    .padding(.top, 24)
                    .padding(.leading, 19)

                if showInfoIcon {
                    Spacer()
                    Button(action: {
                        showInfoPopover = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundColor(.primary.opacity(0.5))
                            .padding(.top, 24)
                            .padding(.trailing, 19)
                    }
                    .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                        Text(NSLocalizedString("The longest number of consecutive days without any conflicts.", comment: "Streak record explanation"))
                            .font(.system(size: 15))
                            .padding()
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }

            Text(value)
                .font(.system(size: 34, weight: .semibold))
                .padding(.top, 15)
                .padding(.leading, 19)
                .padding(.bottom, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Note Card Component
struct NoteCard: View {
    let conflict: Conflict
    @State private var isExpanded: Bool = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(conflict.date.map { dateFormatter.string(from: $0) } ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary.opacity(0.5))
                .padding(.top, 14)
                .padding(.leading, 27)

            HStack(alignment: .top) {
                Text(conflict.notes ?? "")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(isExpanded ? nil : 4)
                    .truncationMode(.tail)
                    .padding(.top, 29)
                    .padding(.leading, 27)
                    .padding(.trailing, 27)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }

            // Emotion Tags
            if let emotionsString = conflict.emotions, !emotionsString.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emotionsString.split(separator: ",").map(String.init), id: \.self) { emotion in
                            Text(emotion)
                                .font(.system(size: 13))
                                .tracking(-0.08)
                                .foregroundColor(Color(hex: "#9c36b2"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "#9c36b2").opacity(0.2))
                                )
                        }
                    }
                    .padding(.horizontal, 27)
                }
                .padding(.top, 8)
            }

            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 17))
                        .foregroundColor(.primary.opacity(0.5))
                        .padding(.trailing, 27)
                        .padding(.bottom, 14)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(minHeight: 145)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StatisticsView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(ConflictManager(context: PersistenceController.shared.container.viewContext))
    }
}

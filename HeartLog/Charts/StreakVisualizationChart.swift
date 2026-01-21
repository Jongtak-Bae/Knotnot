import SwiftUI
import Charts
import CoreData

// MARK: - Data Model
@available(iOS 16.0, *)
struct StreakData: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let days: Int
    let isCurrent: Bool
}

@available(iOS 16.0, *)
struct StreakVisualizationChart: View {
    let streaks: [StreakData]
    let conflicts: [Conflict]

    private var hasData: Bool {
        !streaks.isEmpty || !conflicts.isEmpty
    }

    private var currentStreak: StreakData? {
        streaks.first(where: { $0.isCurrent })
    }

    private var longestStreak: StreakData? {
        streaks.max(by: { $0.days < $1.days })
    }

    // Get conflicts from last 6 months for visualization
    private var recentConflicts: [Conflict] {
        let calendar = Calendar.current
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) else {
            return []
        }
        return conflicts.filter { conflict in
            guard let date = conflict.date else { return false }
            return date >= sixMonthsAgo
        }
    }

    // Get streaks from last 6 months
    private var recentStreaks: [StreakData] {
        let calendar = Calendar.current
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) else {
            return streaks
        }
        return streaks.filter { streak in
            streak.end >= sixMonthsAgo
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("Conflict-Free Streaks", comment: "Streak chart title"))
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                if let current = currentStreak, current.days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("\(current.days) \(current.days == 1 ? NSLocalizedString("day", comment: "Singular day") : NSLocalizedString("days", comment: "Plural days"))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                }
            }

            if !hasData {
                // Empty state
                Text(NSLocalizedString("No conflict history yet", comment: "No streak data message"))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    // Streak bars
                    ForEach(recentStreaks) { streak in
                        BarMark(
                            xStart: .value("Start", streak.start),
                            xEnd: .value("End", streak.end),
                            y: .value("Type", "Streaks")
                        )
                        .foregroundStyle(
                            streak.isCurrent ?
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.4), Color.green.opacity(0.2)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .cornerRadius(4)
                    }

                    // Conflict markers
                    ForEach(recentConflicts, id: \.id) { conflict in
                        if let date = conflict.date {
                            PointMark(
                                x: .value("Date", date),
                                y: .value("Type", "Conflicts")
                            )
                            .foregroundStyle(Color.red)
                            .symbolSize(60)
                        }
                    }
                }
                .frame(height: 120)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Color.primary.opacity(0.6))
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(.clear)
                }

                // Legend
                HStack(spacing: 24) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text(NSLocalizedString("Conflict-free", comment: "Conflict-free legend"))
                            .font(.system(size: 14))
                            .foregroundColor(Color.primary.opacity(0.6))
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text(NSLocalizedString("Conflict", comment: "Conflict legend"))
                            .font(.system(size: 14))
                            .foregroundColor(Color.primary.opacity(0.6))
                    }

                    if let longest = longestStreak {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text(NSLocalizedString("Record:", comment: "Record streak prefix"))
                                .font(.system(size: 13))
                                .foregroundColor(Color.primary.opacity(0.6))
                            Text("\(longest.days)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    let calendar = Calendar.current

    // Sample streaks
    let sampleStreaks = [
        StreakData(
            start: calendar.date(byAdding: .day, value: -90, to: Date())!,
            end: calendar.date(byAdding: .day, value: -70, to: Date())!,
            days: 20,
            isCurrent: false
        ),
        StreakData(
            start: calendar.date(byAdding: .day, value: -50, to: Date())!,
            end: calendar.date(byAdding: .day, value: -30, to: Date())!,
            days: 20,
            isCurrent: false
        ),
        StreakData(
            start: calendar.date(byAdding: .day, value: -10, to: Date())!,
            end: Date(),
            days: 10,
            isCurrent: true
        )
    ]

    // Empty conflicts array for preview
    let sampleConflicts: [Conflict] = []

    StreakVisualizationChart(streaks: sampleStreaks, conflicts: sampleConflicts)
        .padding()
}

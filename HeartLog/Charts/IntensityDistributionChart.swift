import SwiftUI
import Charts

// MARK: - Data Model
@available(iOS 16.0, *)
struct MonthlyIntensity: Identifiable {
    let id = UUID()
    let month: Date
    let intensity: ConflictIntensity
    let count: Int
}

@available(iOS 16.0, *)
struct IntensityDistributionChart: View {
    let data: [(month: Date, minor: Int, moderate: Int, severe: Int)]

    private var chartData: [MonthlyIntensity] {
        data.flatMap { item in
            [
                MonthlyIntensity(month: item.month, intensity: .minor, count: item.minor),
                MonthlyIntensity(month: item.month, intensity: .moderate, count: item.moderate),
                MonthlyIntensity(month: item.month, intensity: .severe, count: item.severe)
            ]
        }
    }

    private var hasData: Bool {
        data.contains { $0.minor > 0 || $0.moderate > 0 || $0.severe > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Conflict Intensity", comment: "Conflict intensity chart title"))
                .font(.system(size: 20, weight: .semibold))

            if !hasData {
                // Empty state
                Text(NSLocalizedString("No conflicts in this period", comment: "No conflicts chart message"))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(item.intensity.color)
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(Color.primary.opacity(0.6))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.primary.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.primary.opacity(0.6))
                    }
                }
                .chartLegend(position: .bottom, spacing: 12) {
                    HStack(spacing: 16) {
                        ForEach(ConflictIntensity.allCases, id: \.self) { intensity in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(intensity.color)
                                    .frame(width: 12, height: 12)
                                Text(intensity.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.primary.opacity(0.6))
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea.background(.clear)
                }
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
    let sampleData = (0..<6).map { i in
        let month = calendar.date(byAdding: .month, value: -i, to: Date())!
        let monthStart = calendar.startOfMonth(for: month)
        return (
            month: monthStart,
            minor: Int.random(in: 0...3),
            moderate: Int.random(in: 0...3),
            severe: Int.random(in: 0...2)
        )
    }.reversed()

    IntensityDistributionChart(data: Array(sampleData))
        .padding()
}

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct ConflictFrequencyChart: View {
    let data: [(month: Date, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Monthly Conflicts", comment: "Monthly conflicts chart title"))
                .font(.system(size: 20, weight: .semibold))

            if data.allSatisfy({ $0.count == 0 }) {
                // Empty state
                Text(NSLocalizedString("No conflicts in this period", comment: "No conflicts chart message"))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data, id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Conflicts", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#A640BC"),
                                Color(hex: "#9c36b2")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 200)
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
        return (month: calendar.startOfMonth(for: month), count: Int.random(in: 0...8))
    }.reversed()

    ConflictFrequencyChart(data: Array(sampleData))
        .padding()
}

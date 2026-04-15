import SwiftUI
import Charts

struct ForecastChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let temperature: Double
}

struct ForecastChartView: View {
    let points: [ForecastChartPoint]

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Time", point.label),
                y: .value("Temperature", point.temperature)
            )
            PointMark(
                x: .value("Time", point.label),
                y: .value("Temperature", point.temperature)
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic)
        }
        .padding()
    }
}

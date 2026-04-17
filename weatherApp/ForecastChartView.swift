import SwiftUI
import Charts

struct ForecastChartPoint: Identifiable {
    let id = UUID()
    let label: String
    let temperature: Double
}

struct ForecastChartView: View {
    let points: [ForecastChartPoint]

    var minTemp: Double {
        (points.map { $0.temperature }.min() ?? 0) - 2
    }

    var maxTemp: Double {
        (points.map { $0.temperature }.max() ?? 0) + 2
    }

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.label),
                    y: .value("Temperature", point.temperature)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                PointMark(
                    x: .value("Time", point.label),
                    y: .value("Temperature", point.temperature)
                )
                .symbolSize(50)
            }
        }
        .chartYScale(domain: minTemp...maxTemp)
        .chartXAxis {
            AxisMarks(values: points.map { $0.label }) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let temp = value.as(Double.self) {
                        Text("\(Int(temp))°")
                    }
                }
            }
        }
        .frame(height: 220)
        .padding()
        .background(Color.clear)
    }
}

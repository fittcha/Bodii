//
//  MuscleMassTrendChart.swift
//  Bodii
//

import SwiftUI
import Charts

// MARK: - MuscleMassTrendChart

/// 근육량 트렌드 라인 차트
/// - 실측값 + 5일 이동평균 + 20일 이동평균 + 예측선
/// - 체중/체지방률 트렌드 차트와 동일한 스타일 기조
struct MuscleMassTrendChart: View {

    // MARK: - Properties

    let dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint]
    let period: FetchBodyTrendsUseCase.TrendPeriod
    let isInteractive: Bool
    let height: CGFloat
    let gender: Gender?

    // MARK: - State

    @State private var selectedDate: Date?

    private var selectedDataPoint: FetchBodyTrendsUseCase.TrendDataPoint? {
        guard let date = selectedDate else { return nil }
        return validDataPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    // MARK: - Computed Properties

    /// 근육량이 nil이 아니고 0보다 큰 유효 데이터만 필터링
    private var validDataPoints: [FetchBodyTrendsUseCase.TrendDataPoint] {
        dataPoints.filter { ($0.muscleMass ?? 0) > 0 }
    }

    private var isEmpty: Bool { validDataPoints.isEmpty }

    /// Y축 최소값 (10kg 고정)
    private var yAxisMinimum: Double { 10.0 }

    /// Y축 최대값 (50kg 고정)
    private var yAxisMaximum: Double { 50.0 }

    /// Y축 눈금 (5kg 간격)
    private var yAxisTicks: [Double] {
        var ticks: [Double] = []
        var value = yAxisMinimum
        while value <= yAxisMaximum {
            ticks.append(value)
            value += 5
        }
        return ticks
    }

    /// X축 시작 날짜
    private var xAxisStart: Date {
        Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()
    }

    /// X축 종료 날짜 (미래 예측 포함)
    private var xAxisEnd: Date {
        Calendar.current.date(byAdding: .day, value: period.predictionDays, to: Date()) ?? Date()
    }

    /// 근육량 변화량
    private var muscleMassChange: Decimal? {
        guard let first = validDataPoints.first?.muscleMass,
              let last = validDataPoints.last?.muscleMass else { return nil }
        return last - first
    }

    /// 5일 이동평균
    private var movingAverage5: [MovingAveragePoint] {
        computeMovingAverage(window: 5)
    }

    /// 20일 이동평균
    private var movingAverage20: [MovingAveragePoint] {
        computeMovingAverage(window: 20)
    }

    /// 예측선
    private var predictionLine: [MovingAveragePoint] {
        computePrediction(daysAhead: period.predictionDays)
    }

    /// X축 간격
    private var xAxisStride: Int {
        period.xAxisStride
    }

    // MARK: - Initialization

    init(
        dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint],
        period: FetchBodyTrendsUseCase.TrendPeriod = .month,
        isInteractive: Bool = true,
        height: CGFloat = 280,
        gender: Gender? = nil
    ) {
        self.dataPoints = dataPoints
        self.period = period
        self.isInteractive = isInteractive
        self.height = height
        self.gender = gender
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더 + 범례
            HStack {
                Text("근육량 트렌드")
                    .font(.headline)
                    .fontWeight(.semibold)

                if let change = muscleMassChange {
                    changeBadge(change)
                }

                Spacer()

                // 범례
                HStack(spacing: 10) {
                    legendItem(color: .green, label: "실측", style: .solid)
                    legendItem(color: .teal.opacity(0.7), label: "5일", style: .solid)
                    legendItem(color: .indigo.opacity(0.6), label: "20일", style: .solid)
                    legendItem(color: .green.opacity(0.4), label: "예측", style: .dashed)
                }
            }

            if isEmpty {
                emptyStateView
            } else {
                // 차트
                chartView

                // 선택된 포인트 상세
                if let selected = selectedDataPoint {
                    selectedDetail(selected)
                }
            }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            // 오늘 기준선 (세로 점선)
            RuleMark(x: .value("오늘", Date()))
                .foregroundStyle(.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

            // 20일 이동평균 (배경, 먼저 그림)
            ForEach(movingAverage20) { point in
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("20일", point.value),
                    series: .value("종류", "MA20")
                )
                .foregroundStyle(.indigo.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            }

            // 5일 이동평균
            ForEach(movingAverage5) { point in
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("5일", point.value),
                    series: .value("종류", "MA5")
                )
                .foregroundStyle(.teal.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            }

            // 실측값 라인
            ForEach(validDataPoints) { point in
                if let mm = point.muscleMass {
                    LineMark(
                        x: .value("날짜", point.date),
                        y: .value("근육량", NSDecimalNumber(decimal: mm).doubleValue),
                        series: .value("종류", "실측")
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }

            // 실측값 포인트
            ForEach(validDataPoints) { point in
                if let mm = point.muscleMass {
                    PointMark(
                        x: .value("날짜", point.date),
                        y: .value("근육량", NSDecimalNumber(decimal: mm).doubleValue)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(20)
                }
            }

            // 예측선 (점선)
            ForEach(predictionLine) { point in
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("예측", point.value),
                    series: .value("종류", "예측")
                )
                .foregroundStyle(.green.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .interpolationMethod(.catmullRom)
            }

            // 선택 인디케이터
            if let selected = selectedDataPoint, let mm = selected.muscleMass {
                RuleMark(x: .value("날짜", selected.date))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("날짜", selected.date),
                    y: .value("근육량", NSDecimalNumber(decimal: mm).doubleValue)
                )
                .foregroundStyle(.white)
                .symbolSize(80)
                .symbol {
                    Circle()
                        .fill(.green)
                        .strokeBorder(.white, lineWidth: 2)
                }
            }
        }
        .chartXScale(domain: xAxisStart...xAxisEnd)
        .chartYScale(domain: yAxisMinimum...yAxisMaximum)
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisTicks) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatShortDate(date))
                            .font(.system(size: 9))
                    }
                }
                AxisGridLine()
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.border(Color(.systemGray4), width: 0.5)
        }
        .chartXSelection(value: $selectedDate)
        .frame(height: height)
        .disabled(!isInteractive)
    }

    // MARK: - Subviews

    /// 변화량 뱃지
    private func changeBadge(_ change: Decimal) -> some View {
        let isIncrease = change > 0
        let color: Color = isIncrease ? .green : .orange
        let icon = isIncrease ? "arrow.up.right" : "arrow.down.right"

        return HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(formatMuscleMassChange(change))
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .cornerRadius(6)
    }

    private func legendItem(color: Color, label: String, style: LineStyle) -> some View {
        HStack(spacing: 3) {
            if style == .dashed {
                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(color).frame(width: 3, height: 1.5)
                    }
                }
                .frame(width: 12)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 1.5)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    /// 선택된 포인트 상세
    private func selectedDetail(_ point: FetchBodyTrendsUseCase.TrendDataPoint) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(point.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 근육량
            if let mm = point.muscleMass {
                detailItem(label: "근육량", value: formatMuscleMass(mm), color: .green)
            }

            // 체중
            if point.weight > 0 {
                detailItem(label: "체중", value: formatWeight(point.weight), color: .blue)
            }

            Button { selectedDate = nil } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
    }

    private func detailItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.3))

            Text("근육량 데이터가 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Moving Average & Prediction

    private func computeMovingAverage(window: Int) -> [MovingAveragePoint] {
        guard validDataPoints.count >= window else { return [] }

        let sorted = validDataPoints.sorted { $0.date < $1.date }
        var result: [MovingAveragePoint] = []

        for i in (window - 1)..<sorted.count {
            let windowSlice = sorted[(i - window + 1)...i]
            let avg = windowSlice.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.muscleMass ?? 0).doubleValue } / Double(window)
            result.append(MovingAveragePoint(date: sorted[i].date, value: avg))
        }

        return result
    }

    private func computePrediction(daysAhead: Int) -> [MovingAveragePoint] {
        guard validDataPoints.count >= 3 else { return [] }

        let sorted = validDataPoints.sorted { $0.date < $1.date }
        let n = sorted.count
        let lastDate = sorted.last!.date

        let firstDate = sorted.first!.date
        let xs = sorted.map { $0.date.timeIntervalSince(firstDate) / 86400.0 }
        let ys = sorted.map { NSDecimalNumber(decimal: $0.muscleMass ?? 0).doubleValue }

        let xMean = xs.reduce(0, +) / Double(n)
        let yMean = ys.reduce(0, +) / Double(n)

        var numerator = 0.0
        var denominator = 0.0
        for i in 0..<n {
            numerator += (xs[i] - xMean) * (ys[i] - yMean)
            denominator += (xs[i] - xMean) * (xs[i] - xMean)
        }

        guard denominator != 0 else { return [] }
        let b = numerator / denominator
        let a = yMean - b * xMean

        let lastX = lastDate.timeIntervalSince(firstDate) / 86400.0
        var points: [MovingAveragePoint] = [
            MovingAveragePoint(date: lastDate, value: a + b * lastX)
        ]

        let calendar = Calendar.current
        for day in 1...daysAhead {
            let futureDate = calendar.date(byAdding: .day, value: day, to: lastDate)!
            let futureX = futureDate.timeIntervalSince(firstDate) / 86400.0
            let predicted = a + b * futureX
            let clamped = max(0, min(100, predicted))
            points.append(MovingAveragePoint(date: futureDate, value: clamped))
        }

        return points
    }

    // MARK: - Formatters

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    private func formatMuscleMass(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        let number = NSDecimalNumber(decimal: value)
        return (formatter.string(from: number) ?? "\(value)") + " kg"
    }

    private func formatMuscleMassChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + " kg"
    }

    private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        let number = NSDecimalNumber(decimal: weight)
        return (formatter.string(from: number) ?? "\(weight)") + " kg"
    }
}

// MARK: - Convenience Initializers

extension MuscleMassTrendChart {
    init(
        viewModel: BodyTrendsViewModel,
        isInteractive: Bool = true,
        height: CGFloat = 280,
        gender: Gender? = nil
    ) {
        self.dataPoints = viewModel.dataPoints
        self.period = viewModel.selectedPeriod
        self.isInteractive = isInteractive
        self.height = height
        self.gender = gender
    }
}

// MARK: - Preview

#Preview("30일 데이터") {
    ScrollView {
        MuscleMassTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .month,
            gender: .female
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        MuscleMassTrendChart(dataPoints: [], period: .month)
            .padding()
    }
}

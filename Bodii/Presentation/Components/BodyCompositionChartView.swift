//
//  BodyCompositionChartView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-28.
//

import SwiftUI
import Charts

// MARK: - Body Composition Chart View

/// 체성분 변화 그래프 뷰
///
/// **표시 항목**:
/// - 체중 (kg) - 파란색 선 (좌측 Y축)
/// - 체지방률 (%) - 주황색 선 (우측 Y축, 항상 표시)
///
/// **Y축 범위**:
/// - 남성: 체중 50/75/100 kg / 체지방률 0/25/50%
/// - 여성: 체중 25/50/75 kg / 체지방률 0/25/50%
///
/// **X축 규칙** (30칸 = 6구간, 5일 간격 눈금):
/// - 최초 데이터가 오늘로부터 20일 이내: 첫 데이터를 1번째 칸에 배치
/// - 최초 데이터가 20일 이상 전: 오늘을 20번째 칸에 고정, 뒤 10칸은 비어있음
struct BodyCompositionChartView: View {

    // MARK: - Properties

    /// 체성분 데이터
    let data: [BodyChartData]

    /// 사용자 성별 (Y축 범위 결정)
    var gender: Gender = .male

    // MARK: - Computed

    /// 체지방 데이터가 있는 항목만
    private var bodyFatData: [BodyChartData] {
        data.filter { $0.bodyFat != nil }
    }

    /// 체중 Y축 범위
    private var weightRange: (min: Double, max: Double) {
        switch gender {
        case .male: return (50, 100)
        case .female: return (25, 75)
        }
    }

    /// 체중 Y축 눈금 (3단계)
    private var weightTicks: [Double] {
        let r = weightRange
        let mid = (r.min + r.max) / 2
        return [r.min, mid, r.max]
    }

    /// 체지방률 Y축 범위
    private var bodyFatRange: (min: Double, max: Double) {
        (0, 50)
    }

    /// 체지방률 Y축 눈금
    private var bodyFatTicks: [Double] {
        [0, 25, 50]
    }

    /// 체중 값을 체지방률 Y축 범위로 정규화
    private func normalizedWeight(_ weight: Double) -> Double {
        let wRange = weightRange
        let bfRange = bodyFatRange
        let normalized = (weight - wRange.min) / (wRange.max - wRange.min)
        return bfRange.min + normalized * (bfRange.max - bfRange.min)
    }

    /// X축 날짜 범위 (30칸)
    ///
    /// - 최초 데이터 ≤ 20일 전: 첫 데이터를 시작점으로, 거기서 +29일이 끝점
    /// - 최초 데이터 > 20일 전: 오늘이 20번째 칸 → 시작 = 오늘 - 19일, 끝 = 시작 + 29일
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let firstData = data.sorted(by: { $0.date < $1.date }).first else {
            // 데이터 없으면 오늘 기준 30일
            let start = calendar.date(byAdding: .day, value: -29, to: today)!
            return start...today
        }

        let firstDate = calendar.startOfDay(for: firstData.date)
        let daysSinceFirst = calendar.dateComponents([.day], from: firstDate, to: today).day ?? 0

        if daysSinceFirst <= 20 {
            // 20일 이내: 첫 데이터를 1번째 칸에, 거기서 +29일이 끝
            let end = calendar.date(byAdding: .day, value: 29, to: firstDate)!
            return firstDate...end
        } else {
            // 20일 초과: 오늘 = 20번째 칸 → 시작 = 오늘 - 19일, 끝 = 시작 + 29일
            let start = calendar.date(byAdding: .day, value: -19, to: today)!
            let end = calendar.date(byAdding: .day, value: 29, to: start)!
            return start...end
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 헤더
            HStack {
                Text("체성분 변화")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // 범례 (항상 둘 다 표시)
                HStack(spacing: 12) {
                    legendItem(color: .blue, label: "체중(kg)")
                    legendItem(color: .orange, label: "체지방(%)")
                }
            }

            // 차트
            if data.isEmpty {
                emptyStateView
            } else {
                dualAxisChartView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Chart

    private var dualAxisChartView: some View {
        HStack(spacing: 0) {
            // 좌측 Y축 (체중)
            VStack {
                ForEach(weightTicks.reversed(), id: \.self) { tick in
                    Text("\(Int(tick))")
                        .font(.system(size: 9))
                        .foregroundStyle(.blue.opacity(0.7))
                    if tick != weightTicks.first {
                        Spacer()
                    }
                }
            }
            .frame(width: 28)

            // 차트 본체
            Chart {
                // 체중 라인 (정규화된 값으로 표시)
                ForEach(data) { item in
                    LineMark(
                        x: .value("날짜", item.date, unit: .day),
                        y: .value("체중(정규화)", normalizedWeight(item.weight)),
                        series: .value("종류", "체중")
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                ForEach(data) { item in
                    PointMark(
                        x: .value("날짜", item.date, unit: .day),
                        y: .value("체중(정규화)", normalizedWeight(item.weight))
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(20)
                }

                // 체지방률 라인 (데이터 있는 항목만)
                ForEach(bodyFatData) { item in
                    LineMark(
                        x: .value("날짜", item.date, unit: .day),
                        y: .value("체지방률", item.bodyFat!),
                        series: .value("종류", "체지방")
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                ForEach(bodyFatData) { item in
                    PointMark(
                        x: .value("날짜", item.date, unit: .day),
                        y: .value("체지방률", item.bodyFat!)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(20)
                }
            }
            .chartYScale(domain: bodyFatRange.min...bodyFatRange.max)
            .chartYAxis(.hidden)
            .chartXScale(domain: dateRange)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatDate(date))
                                .font(.system(size: 9))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .border(Color(.systemGray4), width: 0.5)
            }

            // 우측 Y축 (체지방률) — 항상 표시
            VStack {
                ForEach(bodyFatTicks.reversed(), id: \.self) { tick in
                    Text("\(Int(tick))")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.7))
                    if tick != bodyFatTicks.first {
                        Spacer()
                    }
                }
            }
            .frame(width: 24)
        }
        .frame(height: 120)
    }

    /// 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("데이터가 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("체성분을 기록하면 변화를 확인할 수 있습니다")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    /// 범례 아이템
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 날짜 포맷
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Body Chart Data Model

/// 체성분 차트 데이터
struct BodyChartData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let bodyFat: Double?
    let muscleMass: Double?

    init(date: Date, weight: Double, bodyFat: Double? = nil, muscleMass: Double? = nil) {
        self.date = date
        self.weight = weight
        self.bodyFat = bodyFat
        self.muscleMass = muscleMass
    }
}

// MARK: - Preview Data

extension BodyChartData {
    /// 샘플 데이터 생성 (30일, 간헐적)
    static func sampleData() -> [BodyChartData] {
        let calendar = Calendar.current
        let today = Date()

        return stride(from: 0, to: 30, by: 3).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let weight = 70.0 + Double.random(in: -2.0...2.0)
            let hasBodyFat = Bool.random()
            let bodyFat: Double? = hasBodyFat ? 20.0 + Double.random(in: -2.0...2.0) : nil

            return BodyChartData(
                date: date,
                weight: weight,
                bodyFat: bodyFat
            )
        }
    }

    /// 최근 10일만 데이터 (20일 이내 케이스 테스트)
    static func recentData() -> [BodyChartData] {
        let calendar = Calendar.current
        let today = Date()

        return stride(from: 0, to: 10, by: 2).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let weight = 65.0 + Double.random(in: -1.5...1.5)
            return BodyChartData(date: date, weight: weight, bodyFat: 22.0 + Double.random(in: -1.0...1.0))
        }
    }
}

// MARK: - Preview

#Preview("체성분 - 남성 30일") {
    BodyCompositionChartView(data: BodyChartData.sampleData(), gender: .male)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("체성분 - 여성 최근") {
    BodyCompositionChartView(data: BodyChartData.recentData(), gender: .female)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("빈 상태") {
    BodyCompositionChartView(data: [])
        .padding()
        .background(Color(.systemGroupedBackground))
}

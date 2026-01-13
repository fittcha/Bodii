//
//  BodyFatTrendChart.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Swift Charts with Color-Coded Zones
// Swift Charts 프레임워크를 사용한 체지방률 트렌드 라인 차트 + 건강 구간 표시
// 💡 Java 비교: Android의 MPAndroidChart, iOS Charts와 유사하지만 구간별 색상 구분 기능 포함

import SwiftUI
import Charts

// MARK: - BodyFatTrendChart

/// 체지방률 트렌드를 표시하는 라인 차트 컴포넌트
/// 📚 학습 포인트: Swift Charts Integration with Health Zones
/// - Swift Charts를 사용한 라인 그래프
/// - 건강 구간별 색상 표시 (Essential Fat, Athletes, Fitness, Average, Obese)
/// - 목표선 표시 지원
/// - 인터랙티브 선택 기능
/// - 빈 상태 처리
/// 💡 Java 비교: MPAndroidChart LineChart + LimitLines와 유사하지만 더 선언적
struct BodyFatTrendChart: View {

    // MARK: - Types

    /// 체지방률 건강 구간
    /// 📚 학습 포인트: Health Zone Classification
    /// - 성별에 따라 건강한 체지방률 범위가 다름
    /// - 각 구간마다 색상 지정으로 시각적 피드백 제공
    /// 💡 참고: American Council on Exercise (ACE) 기준
    enum BodyFatZone {
        case essentialFat    // 필수 지방 (남성: 2-5%, 여성: 10-13%)
        case athletes        // 운동선수 (남성: 6-13%, 여성: 14-20%)
        case fitness         // 피트니스 (남성: 14-17%, 여성: 21-24%)
        case average         // 평균 (남성: 18-24%, 여성: 25-31%)
        case obese          // 비만 (남성: 25%+, 여성: 32%+)

        /// 구간 색상
        /// 📚 학습 포인트: Color Coding for Health Indicators
        var color: Color {
            switch self {
            case .essentialFat:
                return .blue
            case .athletes:
                return .green
            case .fitness:
                return .mint
            case .average:
                return .yellow
            case .obese:
                return .orange
            }
        }

        /// 구간 이름
        var displayName: String {
            switch self {
            case .essentialFat:
                return "필수 지방"
            case .athletes:
                return "운동선수"
            case .fitness:
                return "피트니스"
            case .average:
                return "평균"
            case .obese:
                return "비만"
            }
        }

        /// 남성 기준 구간 판별
        /// 📚 학습 포인트: Classification Logic
        /// - 체지방률에 따라 해당하는 건강 구간 반환
        ///
        /// - Parameter bodyFatPercent: 체지방률 (%)
        /// - Returns: 건강 구간
        static func forMale(_ bodyFatPercent: Decimal) -> BodyFatZone {
            let value = NSDecimalNumber(decimal: bodyFatPercent).doubleValue
            if value < 6 { return .essentialFat }
            if value < 14 { return .athletes }
            if value < 18 { return .fitness }
            if value < 25 { return .average }
            return .obese
        }

        /// 여성 기준 구간 판별
        static func forFemale(_ bodyFatPercent: Decimal) -> BodyFatZone {
            let value = NSDecimalNumber(decimal: bodyFatPercent).doubleValue
            if value < 14 { return .essentialFat }
            if value < 21 { return .athletes }
            if value < 25 { return .fitness }
            if value < 32 { return .average }
            return .obese
        }
    }

    // MARK: - Properties

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Data Input
    /// - FetchBodyTrendsUseCase.TrendDataPoint 배열
    /// - 날짜 오름차순 정렬되어 있음
    let dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint]

    /// 목표 체지방률 (%)
    /// 📚 학습 포인트: Optional Goal Line
    /// - nil이면 목표선 표시 안 함
    /// - 값이 있으면 점선으로 표시
    let goalBodyFat: Decimal?

    /// 선택된 트렌드 기간
    /// 📚 학습 포인트: Period Context
    /// - 차트 제목 및 X축 레이블 결정
    let period: FetchBodyTrendsUseCase.TrendPeriod

    /// 인터랙션 활성화 여부
    /// 📚 학습 포인트: Interactive Feature Toggle
    /// - true: 탭하여 상세 정보 표시
    /// - false: 정적 차트
    let isInteractive: Bool

    /// 차트 높이
    /// 📚 학습 포인트: Customizable Height
    /// - 대시보드에서는 작게, 상세 화면에서는 크게
    let height: CGFloat

    /// 사용자 성별 (건강 구간 판별용)
    /// 📚 학습 포인트: Gender-Based Classification
    /// - 남성과 여성의 건강 체지방률 범위가 다름
    /// - nil이면 성별 구분 없이 일반적인 색상 사용
    let gender: Gender?

    /// 건강 구간 배경 표시 여부
    /// 📚 학습 포인트: Optional Zone Background
    /// - true: 차트 배경에 건강 구간별 색상 표시
    /// - false: 구간 표시 없이 단순 라인 차트
    let showHealthZones: Bool

    // MARK: - State

    /// 선택된 날짜
    /// 📚 학습 포인트: Chart Selection State
    /// - 사용자가 탭한 데이터 포인트의 날짜
    /// - nil이면 선택 없음
    /// 💡 Java 비교: selectedEntry in MPAndroidChart
    @State private var selectedDate: Date?

    /// 선택된 데이터 포인트
    /// 📚 학습 포인트: Computed Property for Selection
    /// - selectedDate를 기반으로 실제 데이터 포인트 조회
    private var selectedDataPoint: FetchBodyTrendsUseCase.TrendDataPoint? {
        guard let date = selectedDate else { return nil }
        // 날짜가 가장 가까운 데이터 포인트 찾기
        return dataPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    private var isEmpty: Bool {
        dataPoints.isEmpty
    }

    /// Y축 최소값
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 최소 체지방률보다 약간 작은 값 (여백)
    /// - 목표 체지방률도 고려
    /// - 0% 이하로는 내려가지 않음
    private var yAxisMinimum: Double {
        let minBodyFat = dataPoints.map { $0.bodyFatPercent }.min() ?? Decimal(10)
        let goalBodyFatValue = goalBodyFat ?? minBodyFat
        let minimum = min(minBodyFat, goalBodyFatValue)

        // 5% 단위로 내림, 최소 0%
        let minDouble = NSDecimalNumber(decimal: minimum).doubleValue
        return max(0, floor(minDouble / 5.0) * 5.0)
    }

    /// Y축 최대값
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 최대 체지방률보다 약간 큰 값 (여백)
    /// - 목표 체지방률도 고려
    private var yAxisMaximum: Double {
        let maxBodyFat = dataPoints.map { $0.bodyFatPercent }.max() ?? Decimal(30)
        let goalBodyFatValue = goalBodyFat ?? maxBodyFat
        let maximum = max(maxBodyFat, goalBodyFatValue)

        // 5% 단위로 올림
        let maxDouble = NSDecimalNumber(decimal: maximum).doubleValue
        return ceil(maxDouble / 5.0) * 5.0
    }

    /// 체지방률 변화량 (첫 기록 대비 마지막 기록)
    /// 📚 학습 포인트: Trend Calculation
    /// - 양수: 체지방률 증가
    /// - 음수: 체지방률 감소
    private var bodyFatChange: Decimal? {
        guard let first = dataPoints.first?.bodyFatPercent,
              let last = dataPoints.last?.bodyFatPercent else {
            return nil
        }
        return last - first
    }

    // MARK: - Initialization

    /// BodyFatTrendChart 초기화
    /// 📚 학습 포인트: Flexible Initializer
    /// - 기본값을 제공하여 편리하게 사용
    ///
    /// - Parameters:
    ///   - dataPoints: 차트 데이터 포인트
    ///   - goalBodyFat: 목표 체지방률 (기본값: nil)
    ///   - period: 선택된 기간 (기본값: .week)
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    ///   - gender: 사용자 성별 (기본값: nil)
    ///   - showHealthZones: 건강 구간 표시 여부 (기본값: true)
    init(
        dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint],
        goalBodyFat: Decimal? = nil,
        period: FetchBodyTrendsUseCase.TrendPeriod = .week,
        isInteractive: Bool = true,
        height: CGFloat = 300,
        gender: Gender? = nil,
        showHealthZones: Bool = true
    ) {
        self.dataPoints = dataPoints
        self.goalBodyFat = goalBodyFat
        self.period = period
        self.isInteractive = isInteractive
        self.height = height
        self.gender = gender
        self.showHealthZones = showHealthZones
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 차트 헤더
            chartHeader

            if isEmpty {
                // 빈 상태
                emptyStateView
            } else {
                // 차트
                chartView

                // 범례
                chartLegend

                // 선택된 데이터 포인트 상세 정보
                if let selected = selectedDataPoint {
                    selectedDataPointDetail(selected)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 차트 헤더
    /// 📚 학습 포인트: Header with Statistics
    /// - 제목, 기간, 변화량 표시
    private var chartHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.orange)

                    Text("체지방률 트렌드")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                // 기간
                Text(period.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 변화량 표시
            if let change = bodyFatChange {
                bodyFatChangeBadge(change)
            }
        }
    }

    /// 체지방률 변화량 뱃지
    /// 📚 학습 포인트: Visual Indicator
    /// - 증가는 주황색 (부정적), 감소는 파랑 (긍정적)
    ///
    /// - Parameter change: 체지방률 변화량
    /// - Returns: 뱃지 뷰
    private func bodyFatChangeBadge(_ change: Decimal) -> some View {
        let isIncrease = change > 0
        let color: Color = isIncrease ? .orange : .blue
        let icon = isIncrease ? "arrow.up.right" : "arrow.down.right"

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(formatBodyFatChange(change))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    /// 차트 뷰
    /// 📚 학습 포인트: Swift Charts Implementation with Health Zones
    /// - Chart { } 블록 내에 Mark 정의
    /// - RectangleMark: 건강 구간 배경 표시
    /// - LineMark: 라인 그래프
    /// - PointMark: 데이터 포인트 표시
    /// - RuleMark: 목표선 표시
    private var chartView: some View {
        Chart {
            // 📚 학습 포인트: Health Zone Backgrounds
            // 건강 구간을 배경에 표시 (선택적)
            if showHealthZones {
                healthZoneBackgrounds
            }

            // 📚 학습 포인트: ForEach in Chart
            // 각 데이터 포인트를 LineMark로 변환
            ForEach(dataPoints) { dataPoint in
                // 라인 그래프
                LineMark(
                    x: .value("날짜", dataPoint.date),
                    y: .value("체지방률", NSDecimalNumber(decimal: dataPoint.bodyFatPercent).doubleValue)
                )
                .foregroundStyle(lineColor(for: dataPoint.bodyFatPercent))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom) // 부드러운 곡선

                // 데이터 포인트 표시
                PointMark(
                    x: .value("날짜", dataPoint.date),
                    y: .value("체지방률", NSDecimalNumber(decimal: dataPoint.bodyFatPercent).doubleValue)
                )
                .foregroundStyle(lineColor(for: dataPoint.bodyFatPercent))
                .symbolSize(60)

                // 영역 채우기 (선 아래 부분)
                // 📚 학습 포인트: Area Chart with Gradient
                // AreaMark를 추가하여 라인 아래를 그라데이션으로 채움
                AreaMark(
                    x: .value("날짜", dataPoint.date),
                    y: .value("체지방률", NSDecimalNumber(decimal: dataPoint.bodyFatPercent).doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [lineColor(for: dataPoint.bodyFatPercent).opacity(0.3), lineColor(for: dataPoint.bodyFatPercent).opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // 목표선 표시
            // 📚 학습 포인트: RuleMark for Goal Line
            if let goal = goalBodyFat {
                RuleMark(
                    y: .value("목표", NSDecimalNumber(decimal: goal).doubleValue)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5])) // 점선
                .annotation(position: .top, alignment: .trailing) {
                    Text("목표: \(formatBodyFat(goal))")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // 선택된 데이터 포인트 강조
            // 📚 학습 포인트: Selection Indicator
            if let selected = selectedDataPoint {
                RuleMark(
                    x: .value("날짜", selected.date)
                )
                .foregroundStyle(.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("날짜", selected.date),
                    y: .value("체지방률", NSDecimalNumber(decimal: selected.bodyFatPercent).doubleValue)
                )
                .foregroundStyle(.white)
                .symbolSize(120)
                .symbol {
                    Circle()
                        .fill(lineColor(for: selected.bodyFatPercent))
                        .strokeBorder(.white, lineWidth: 3)
                        .shadow(color: lineColor(for: selected.bodyFatPercent).opacity(0.3), radius: 4)
                }
            }
        }
        .chartXAxis {
            // 📚 학습 포인트: Custom X Axis
            // 날짜 레이블 표시
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            // 📚 학습 포인트: Custom Y Axis
            // 체지방률 레이블 표시 (% 단위)
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisMinimum...yAxisMaximum)
        .chartXSelection(value: $selectedDate)
        .frame(height: height)
        .padding(.vertical, 8)
        .disabled(!isInteractive) // 인터랙션 비활성화 시 탭 불가
    }

    /// 건강 구간 배경
    /// 📚 학습 포인트: Zone Background with RectangleMark
    /// - 성별에 따른 건강 구간을 배경에 표시
    /// - 투명도를 낮춰서 라인이 잘 보이도록 함
    @ChartContentBuilder
    private var healthZoneBackgrounds: some ChartContent {
        // 📚 학습 포인트: Gender-Based Zone Display
        // 성별이 지정되지 않은 경우 일반적인 구간 사용 (남성 기준)
        let isMale = gender == .male || gender == nil

        if isMale {
            // 남성 기준 구간
            // 필수 지방: 0-6%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 0),
                yEnd: .value("Zone End", 6)
            )
            .foregroundStyle(BodyFatZone.essentialFat.color.opacity(0.1))

            // 운동선수: 6-14%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 6),
                yEnd: .value("Zone End", 14)
            )
            .foregroundStyle(BodyFatZone.athletes.color.opacity(0.1))

            // 피트니스: 14-18%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 14),
                yEnd: .value("Zone End", 18)
            )
            .foregroundStyle(BodyFatZone.fitness.color.opacity(0.1))

            // 평균: 18-25%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 18),
                yEnd: .value("Zone End", 25)
            )
            .foregroundStyle(BodyFatZone.average.color.opacity(0.1))

            // 비만: 25%+
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 25),
                yEnd: .value("Zone End", 100)
            )
            .foregroundStyle(BodyFatZone.obese.color.opacity(0.1))
        } else {
            // 여성 기준 구간
            // 필수 지방: 0-14%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 0),
                yEnd: .value("Zone End", 14)
            )
            .foregroundStyle(BodyFatZone.essentialFat.color.opacity(0.1))

            // 운동선수: 14-21%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 14),
                yEnd: .value("Zone End", 21)
            )
            .foregroundStyle(BodyFatZone.athletes.color.opacity(0.1))

            // 피트니스: 21-25%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 21),
                yEnd: .value("Zone End", 25)
            )
            .foregroundStyle(BodyFatZone.fitness.color.opacity(0.1))

            // 평균: 25-32%
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 25),
                yEnd: .value("Zone End", 32)
            )
            .foregroundStyle(BodyFatZone.average.color.opacity(0.1))

            // 비만: 32%+
            RectangleMark(
                xStart: nil,
                xEnd: nil,
                yStart: .value("Zone Start", 32),
                yEnd: .value("Zone End", 100)
            )
            .foregroundStyle(BodyFatZone.obese.color.opacity(0.1))
        }
    }

    /// 체지방률에 따른 라인 색상 결정
    /// 📚 학습 포인트: Dynamic Color Based on Value
    /// - 건강 구간에 따라 다른 색상 반환
    ///
    /// - Parameter bodyFat: 체지방률
    /// - Returns: 색상
    private func lineColor(for bodyFat: Decimal) -> Color {
        guard let gender = gender else {
            // 성별 정보 없으면 기본 색상 (주황색)
            return .orange
        }

        let zone: BodyFatZone = gender == .male ? .forMale(bodyFat) : .forFemale(bodyFat)
        return zone.color
    }

    /// 범례
    /// 📚 학습 포인트: Legend Component with Health Zones
    /// - 차트 요소 설명
    /// - 건강 구간 표시
    private var chartLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 20) {
                // 체지방률 라인
                HStack(spacing: 6) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 10, height: 10)

                    Text("체지방률")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 목표선
                if goalBodyFat != nil {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(.green)
                            .frame(width: 20, height: 2)

                        Text("목표")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 건강 구간 범례 (활성화된 경우에만)
            if showHealthZones {
                Divider()
                    .padding(.vertical, 4)

                Text("건강 구간" + (gender != nil ? " (\(gender == .male ? "남성" : "여성") 기준)" : ""))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    healthZoneLegendItem(.essentialFat)
                    healthZoneLegendItem(.athletes)
                    healthZoneLegendItem(.fitness)
                    healthZoneLegendItem(.average)
                    healthZoneLegendItem(.obese)
                }
            }
        }
    }

    /// 건강 구간 범례 아이템
    /// 📚 학습 포인트: Reusable Legend Item
    ///
    /// - Parameter zone: 건강 구간
    /// - Returns: 범례 아이템 뷰
    private func healthZoneLegendItem(_ zone: BodyFatZone) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(zone.color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)

            Text(zone.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 선택된 데이터 포인트 상세 정보
    /// 📚 학습 포인트: Selection Detail
    /// - 선택한 포인트의 정보를 카드로 표시
    ///
    /// - Parameter dataPoint: 선택된 데이터 포인트
    /// - Returns: 상세 정보 뷰
    private func selectedDataPointDetail(_ dataPoint: FetchBodyTrendsUseCase.TrendDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 날짜
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text(formatDate(dataPoint.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                // 선택 해제 버튼
                Button(action: {
                    selectedDate = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Divider()

            // 측정 값
            HStack(spacing: 24) {
                // 체지방률
                measurementItem(
                    icon: "percent",
                    label: "체지방률",
                    value: formatBodyFat(dataPoint.bodyFatPercent),
                    color: lineColor(for: dataPoint.bodyFatPercent)
                )

                // 체중
                measurementItem(
                    icon: "scalemass",
                    label: "체중",
                    value: formatWeight(dataPoint.weight),
                    color: .blue
                )

                // 근육량 (있는 경우)
                if let muscleMass = dataPoint.muscleMass {
                    measurementItem(
                        icon: "figure.strengthtraining.traditional",
                        label: "근육량",
                        value: formatWeight(muscleMass),
                        color: .purple
                    )
                }
            }

            // 건강 구간 표시
            if let gender = gender {
                let zone: BodyFatZone = gender == .male ? .forMale(dataPoint.bodyFatPercent) : .forFemale(dataPoint.bodyFatPercent)

                HStack(spacing: 6) {
                    Image(systemName: "heart.circle.fill")
                        .font(.caption)
                        .foregroundStyle(zone.color)

                    Text("건강 구간: \(zone.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            // 대사율 정보 (있는 경우)
            if let bmr = dataPoint.bmr, let tdee = dataPoint.tdee {
                Divider()

                HStack(spacing: 24) {
                    measurementItem(
                        icon: "flame",
                        label: "BMR",
                        value: formatCalories(bmr),
                        color: .red
                    )

                    measurementItem(
                        icon: "figure.walk",
                        label: "TDEE",
                        value: formatCalories(tdee),
                        color: .green
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
    }

    /// 측정 값 아이템
    /// 📚 학습 포인트: Reusable Component Function
    /// - 반복되는 측정값 표시 패턴을 재사용
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘 이름
    ///   - label: 레이블 텍스트
    ///   - value: 측정 값
    ///   - color: 강조 색상
    /// - Returns: 측정 값 표시 뷰
    private func measurementItem(
        icon: String,
        label: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))

            VStack(spacing: 8) {
                Text("체지방률 데이터가 없습니다")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("신체 구성 데이터를 입력하면\n체지방률 트렌드를 확인할 수 있습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    /// - "2024년 1월 15일 (월)" 형식
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 체중 포맷팅
    /// 📚 학습 포인트: Weight Formatting
    /// - 소수점 1자리 + "kg" 단위
    ///
    /// - Parameter weight: 체중
    /// - Returns: 포맷된 문자열 (예: "70.5 kg")
    private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: weight)
        return (formatter.string(from: number) ?? "\(weight)") + " kg"
    }

    /// 체지방률 포맷팅
    /// 📚 학습 포인트: Percentage Formatting
    /// - 소수점 1자리 + "%" 기호
    ///
    /// - Parameter bodyFat: 체지방률
    /// - Returns: 포맷된 문자열 (예: "18.5%")
    private func formatBodyFat(_ bodyFat: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: bodyFat)
        return (formatter.string(from: number) ?? "\(bodyFat)") + "%"
    }

    /// 체지방률 변화량 포맷팅
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+1.5%", "-0.8%")
    private func formatBodyFatChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + "%"
    }

    /// 칼로리 포맷팅
    /// 📚 학습 포인트: Calorie Formatting
    /// - 정수 + "kcal" 단위
    ///
    /// - Parameter calories: 칼로리 값
    /// - Returns: 포맷된 문자열 (예: "1,650 kcal")
    private func formatCalories(_ calories: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        let number = NSDecimalNumber(decimal: calories)
        return (formatter.string(from: number) ?? "\(calories)") + " kcal"
    }
}

// MARK: - Convenience Initializers

extension BodyFatTrendChart {
    /// 📚 학습 포인트: Convenience Initializer with ViewModel
    /// - BodyTrendsViewModel에서 직접 값을 가져오는 편의 생성자
    /// - View에서 쉽게 사용 가능
    ///
    /// - Parameters:
    ///   - viewModel: BodyTrendsViewModel 인스턴스
    ///   - goalBodyFat: 목표 체지방률 (기본값: nil)
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    ///   - gender: 사용자 성별 (기본값: nil)
    ///   - showHealthZones: 건강 구간 표시 여부 (기본값: true)
    init(
        viewModel: BodyTrendsViewModel,
        goalBodyFat: Decimal? = nil,
        isInteractive: Bool = true,
        height: CGFloat = 300,
        gender: Gender? = nil,
        showHealthZones: Bool = true
    ) {
        self.dataPoints = viewModel.dataPoints
        self.goalBodyFat = goalBodyFat
        self.period = viewModel.selectedPeriod
        self.isInteractive = isInteractive
        self.height = height
        self.gender = gender
        self.showHealthZones = showHealthZones
    }
}

// MARK: - Preview

#Preview("7일 데이터") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week
        )
        .padding()
    }
}

#Preview("7일 데이터 + 목표선") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            goalBodyFat: Decimal(15.0),
            period: .week
        )
        .padding()
    }
}

#Preview("건강 구간 표시 (남성)") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week,
            gender: .male,
            showHealthZones: true
        )
        .padding()
    }
}

#Preview("건강 구간 표시 (여성)") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week,
            gender: .female,
            showHealthZones: true
        )
        .padding()
    }
}

#Preview("건강 구간 숨김") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week,
            showHealthZones: false
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: [],
            period: .week
        )
        .padding()
    }
}

#Preview("인터랙션 비활성화") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week,
            isInteractive: false,
            height: 200
        )
        .padding()
    }
}

#Preview("다크 모드") {
    ScrollView {
        BodyFatTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            goalBodyFat: Decimal(15.0),
            period: .month,
            gender: .male,
            showHealthZones: true
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("대시보드 크기 (작게)") {
    ScrollView {
        VStack(spacing: 16) {
            Text("대시보드 카드 크기 예시")
                .font(.headline)

            BodyFatTrendChart(
                dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
                period: .week,
                isInteractive: false,
                height: 180,
                showHealthZones: false
            )
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8)
            )
        }
        .padding()
    }
}

#Preview("30일 데이터 - 다양한 구간") {
    ScrollView {
        let now = Date()
        let dataPoints = stride(from: -29, through: 0, by: 3).map { dayOffset in
            // 체지방률을 점진적으로 변화시켜 다양한 건강 구간 표시
            let progress = Double(dayOffset + 29) / 29.0
            let bodyFat = 25.0 - (progress * 10.0) // 25% → 15%로 감소

            return FetchBodyTrendsUseCase.TrendDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: now)!,
                weight: Decimal(72.0 + Double(dayOffset) * 0.05),
                bodyFatPercent: Decimal(bodyFat),
                muscleMass: Decimal(31.0 - Double(dayOffset) * 0.02),
                bmr: Decimal(1680),
                tdee: Decimal(2280)
            )
        }

        BodyFatTrendChart(
            dataPoints: dataPoints,
            goalBodyFat: Decimal(15.0),
            period: .month,
            gender: .male,
            showHealthZones: true
        )
        .padding()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: BodyFatTrendChart 사용법
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct BodyTrendsView: View {
///     @StateObject private var viewModel: BodyTrendsViewModel
///
///     var body: some View {
///         BodyFatTrendChart(
///             viewModel: viewModel,
///             goalBodyFat: Decimal(15.0),
///             gender: .male,
///             showHealthZones: true
///         )
///     }
/// }
/// ```
///
/// 데이터 직접 전달:
/// ```swift
/// struct MyView: View {
///     let dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint]
///
///     var body: some View {
///         BodyFatTrendChart(
///             dataPoints: dataPoints,
///             goalBodyFat: Decimal(15.0),
///             period: .month,
///             isInteractive: true,
///             height: 300,
///             gender: .male,
///             showHealthZones: true
///         )
///     }
/// }
/// ```
///
/// 대시보드 크기 (건강 구간 숨김):
/// ```swift
/// BodyFatTrendChart(
///     dataPoints: dataPoints,
///     period: .week,
///     isInteractive: false,
///     height: 180,
///     showHealthZones: false
/// )
/// ```
///
/// 주요 기능:
/// - Swift Charts 기반 라인 차트
/// - 부드러운 곡선 (Catmull-Rom interpolation)
/// - 그라데이션 영역 채우기
/// - 건강 구간별 배경 색상 표시 (남성/여성 기준 다름)
/// - 건강 구간에 따른 동적 라인 색상
/// - 목표선 표시 (점선)
/// - 인터랙티브 선택 (탭하여 상세 정보 표시)
/// - 체지방률 변화량 뱃지
/// - 빈 상태 처리
/// - 라이트/다크 모드 자동 대응
/// - 커스터마이즈 가능한 높이
///
/// 차트 구성 요소:
/// - RectangleMark: 건강 구간 배경
/// - LineMark: 체지방률 트렌드 라인
/// - PointMark: 데이터 포인트 표시
/// - AreaMark: 라인 아래 영역 채우기
/// - RuleMark: 목표선 및 선택 인디케이터
///
/// 건강 구간 (남성):
/// - 필수 지방: 0-6% (파랑)
/// - 운동선수: 6-14% (초록)
/// - 피트니스: 14-18% (민트)
/// - 평균: 18-25% (노랑)
/// - 비만: 25%+ (주황)
///
/// 건강 구간 (여성):
/// - 필수 지방: 0-14% (파랑)
/// - 운동선수: 14-21% (초록)
/// - 피트니스: 21-25% (민트)
/// - 평균: 25-32% (노랑)
/// - 비만: 32%+ (주황)
///
/// 인터랙션 기능:
/// - 데이터 포인트 탭하여 선택
/// - 선택한 포인트의 상세 정보 표시 (체지방률, 체중, 근육량, 건강 구간, BMR, TDEE)
/// - 선택 해제 버튼
///
/// 💡 Android 비교:
/// - Android: MPAndroidChart LineChart + LimitLines
/// - SwiftUI: Swift Charts LineMark + RectangleMark
/// - Android: LineDataSet + custom colors
/// - SwiftUI: ForEach + dynamic colors (선언적)
/// - Android: setOnChartValueSelectedListener
/// - SwiftUI: @State + chartXSelection
///
/// 성능 최적화:
/// - 최대 90일 데이터 권장 (TrendPeriod.quarter)
/// - 건강 구간 표시는 선택적 (showHealthZones)
/// - 인터랙션 비활성화 시 더 가볍게 렌더링
/// - 날짜순 정렬된 데이터 사용 (Use Case에서 처리)
///

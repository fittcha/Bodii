//
//  FetchSleepStatsUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Statistics Use Case Pattern
// 수면 통계 및 차트 데이터 계산을 캡슐화하는 Use Case 패턴
// 💡 Java 비교: Service layer의 통계 계산 메서드와 유사

import Foundation

// MARK: - FetchSleepStatsUseCase

/// 수면 통계 조회 Use Case
/// 차트 및 대시보드 표시를 위해 수면 통계 데이터를 계산합니다.
/// 📚 학습 포인트: Clean Architecture - Use Case Layer
/// - 특정 비즈니스 로직(통계 데이터 계산)을 독립적인 유닛으로 캡슐화
/// - Repository의 raw data를 통계 및 차트에 최적화된 형태로 변환
/// - UI나 데이터베이스에 의존하지 않는 순수한 비즈니스 로직
/// 💡 Java 비교: Interactor 또는 Service 클래스의 단일 책임 메서드
struct FetchSleepStatsUseCase {

    // MARK: - Types

    /// 통계 기간 열거형
    /// 📚 학습 포인트: Enum with Associated Values
    /// - 사용자가 선택할 수 있는 차트 기간 정의
    /// - 각 케이스가 days 값을 가짐
    /// 💡 Java 비교: Enum with fields와 유사
    enum StatsPeriod: Int, CaseIterable, Codable {
        /// 최근 7일
        case week = 7

        /// 최근 30일
        case month = 30

        /// 최근 90일
        case quarter = 90

        /// 일수 값
        /// 📚 학습 포인트: Computed Property
        /// rawValue를 days로 명시적으로 표현
        var days: Int {
            return self.rawValue
        }

        /// 표시 이름
        /// 📚 학습 포인트: Localization
        /// UI에 표시할 한글 이름
        var displayName: String {
            switch self {
            case .week:
                return "7일"
            case .month:
                return "30일"
            case .quarter:
                return "90일"
            }
        }

        /// 시작 날짜 계산
        /// 📚 학습 포인트: Date Manipulation
        /// 현재 날짜에서 days만큼 이전 날짜 계산
        /// - Parameter from: 기준 날짜 (기본값: 현재)
        /// - Returns: 시작 날짜
        func startDate(from date: Date = Date()) -> Date {
            Calendar.current.date(byAdding: .day, value: -days, to: date) ?? date
        }
    }

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Value Object
    /// - 차트에 표시할 단일 데이터 포인트
    /// - 날짜와 수면 데이터를 그룹화
    /// 💡 Java 비교: Record (Java 14+) 또는 DTO와 유사
    struct SleepDataPoint: Codable, Identifiable, Equatable {
        /// 고유 식별자 (차트 렌더링 최적화)
        let id: UUID

        /// 측정 날짜
        let date: Date

        /// 수면 시간 (분)
        let duration: Int32

        /// 수면 상태
        let status: SleepStatus

        /// 수면 시간을 시:분 형식으로 반환
        /// 📚 학습 포인트: Computed Property
        /// UI에서 표시할 때 사용하기 쉬운 형태로 제공
        /// - Returns: (hours, minutes) 튜플
        var durationFormatted: (hours: Int, minutes: Int) {
            let hours = Int(duration) / 60
            let minutes = Int(duration) % 60
            return (hours, minutes)
        }

        /// 표시용 날짜 문자열
        /// 📚 학습 포인트: Date Formatting
        /// UI에서 사용할 수 있는 포맷된 날짜 문자열
        func formattedDate(style: DateFormatter.Style = .short) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = style
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        }
    }

    /// 수면 상태별 통계
    /// 📚 학습 포인트: Nested Statistics Type
    /// 각 수면 상태별 발생 빈도와 비율을 담는 타입
    struct StatusStats: Codable, Equatable, Identifiable {
        /// 수면 상태
        let status: SleepStatus

        /// 발생 횟수
        let count: Int

        /// 전체 대비 비율 (0.0 ~ 1.0)
        /// 📚 학습 포인트: Percentage Calculation
        /// 차트나 통계 표시에 사용
        let percentage: Double

        /// Identifiable을 위한 id
        var id: SleepStatus { status }

        /// 비율을 백분율 문자열로 반환
        /// 📚 학습 포인트: Formatted String
        /// UI에서 바로 사용할 수 있는 포맷된 문자열
        func percentageFormatted() -> String {
            return String(format: "%.1f%%", percentage * 100)
        }
    }

    /// 통계 조회에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 FetchSleepStatsUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 조회 기간
        let period: StatsPeriod

        /// 종료 날짜 (기본값: 현재)
        /// 📚 학습 포인트: Default Parameter
        /// 대부분의 경우 현재까지의 데이터를 조회하지만, 특정 시점까지의 데이터도 조회 가능
        let endDate: Date

        /// 시작 날짜 계산
        /// 📚 학습 포인트: Computed Property
        /// period와 endDate를 기반으로 시작 날짜 자동 계산
        var startDate: Date {
            period.startDate(from: endDate)
        }

        /// 초기화
        /// - Parameters:
        ///   - period: 조회 기간
        ///   - endDate: 종료 날짜 (기본값: 현재)
        init(period: StatsPeriod, endDate: Date = Date()) {
            self.period = period
            self.endDate = endDate
        }
    }

    /// 통계 조회 결과
    /// 📚 학습 포인트: Result Type
    /// 조회된 데이터와 통계 정보를 함께 반환
    /// 💡 Java 비교: DTO (Data Transfer Object)와 유사
    struct Output {
        /// 차트 데이터 포인트 배열 (날짜 오름차순 정렬)
        /// 📚 학습 포인트: Collection Type
        /// - 차트 라이브러리가 요구하는 형태로 정렬
        /// - Swift Charts는 날짜순 정렬을 권장
        let dataPoints: [SleepDataPoint]

        /// 조회 기간
        let period: StatsPeriod

        /// 시작 날짜
        let startDate: Date

        /// 종료 날짜
        let endDate: Date

        /// 데이터 존재 여부
        /// 📚 학습 포인트: Computed Property
        /// UI에서 empty state 표시 여부 판단에 사용
        var isEmpty: Bool {
            dataPoints.isEmpty
        }

        /// 데이터 포인트 개수 (총 수면 기록 횟수)
        var count: Int {
            dataPoints.count
        }

        // MARK: - Duration Statistics

        /// 총 수면 시간 (분)
        /// 📚 학습 포인트: Aggregate Calculation
        /// 기간 내 전체 수면 시간 합계
        var totalDuration: Int32 {
            dataPoints.reduce(0) { $0 + $1.duration }
        }

        /// 평균 수면 시간 (분)
        /// 📚 학습 포인트: Average Calculation
        /// 차트 요약 정보로 표시
        var averageDuration: Int32? {
            guard !isEmpty else { return nil }
            return totalDuration / Int32(count)
        }

        /// 평균 수면 시간을 시:분 형식으로 반환
        /// 📚 학습 포인트: Computed Property
        /// UI에서 표시할 때 사용하기 쉬운 형태로 제공
        var averageDurationFormatted: (hours: Int, minutes: Int)? {
            guard let avg = averageDuration else { return nil }
            let hours = Int(avg) / 60
            let minutes = Int(avg) % 60
            return (hours, minutes)
        }

        /// 최소 수면 시간 (분)
        var minDuration: Int32? {
            dataPoints.map { $0.duration }.min()
        }

        /// 최대 수면 시간 (분)
        var maxDuration: Int32? {
            dataPoints.map { $0.duration }.max()
        }

        /// 중간값 수면 시간 (분)
        /// 📚 학습 포인트: Median Calculation
        /// 평균보다 이상치에 덜 민감한 중심 경향치
        var medianDuration: Int32? {
            guard !isEmpty else { return nil }
            let sorted = dataPoints.map { $0.duration }.sorted()
            let middleIndex = sorted.count / 2
            if sorted.count % 2 == 0 {
                // 짝수 개인 경우 중간 두 값의 평균
                return (sorted[middleIndex - 1] + sorted[middleIndex]) / 2
            } else {
                // 홀수 개인 경우 중간값
                return sorted[middleIndex]
            }
        }

        /// 수면 시간 변화량 (분) - 기간 내 첫 기록과 마지막 기록의 차이
        /// 📚 학습 포인트: Trend Calculation
        /// 양수: 수면 시간 증가, 음수: 수면 시간 감소
        var durationChange: Int32? {
            guard let first = dataPoints.first?.duration,
                  let last = dataPoints.last?.duration else {
                return nil
            }
            return last - first
        }

        /// 수면 시간 표준편차 (분)
        /// 📚 학습 포인트: Standard Deviation
        /// 수면 시간의 일관성을 측정 (낮을수록 규칙적)
        var durationStandardDeviation: Double? {
            guard !isEmpty, let avg = averageDuration else { return nil }
            let variance = dataPoints.reduce(0.0) { result, point in
                let diff = Double(point.duration) - Double(avg)
                return result + (diff * diff)
            } / Double(count)
            return sqrt(variance)
        }

        // MARK: - Status Statistics

        /// 수면 상태별 분포 (원시 데이터)
        /// 📚 학습 포인트: Dictionary Grouping
        /// 차트나 통계 표시에 사용
        /// - Returns: [SleepStatus: 개수]
        var statusDistribution: [SleepStatus: Int] {
            Dictionary(grouping: dataPoints) { $0.status }
                .mapValues { $0.count }
        }

        /// 수면 상태별 통계 (비율 포함)
        /// 📚 학습 포인트: Complex Statistics
        /// UI에서 바로 사용할 수 있는 포맷된 통계
        var statusStats: [StatusStats] {
            guard !isEmpty else { return [] }
            return statusDistribution.map { status, count in
                StatusStats(
                    status: status,
                    count: count,
                    percentage: Double(count) / Double(self.count)
                )
            }.sorted { $0.count > $1.count } // 빈도 높은 순으로 정렬
        }

        /// 가장 많은 수면 상태
        /// 📚 학습 포인트: Max By Value
        /// 사용자의 주된 수면 상태 표시
        var mostCommonStatus: SleepStatus? {
            statusDistribution.max(by: { $0.value < $1.value })?.key
        }

        /// 가장 적은 수면 상태
        var leastCommonStatus: SleepStatus? {
            statusDistribution.min(by: { $0.value < $1.value })?.key
        }

        /// 좋은 수면 비율 (good + excellent)
        /// 📚 학습 포인트: Quality Metric
        /// 수면 품질의 전반적인 평가 지표
        var goodSleepPercentage: Double {
            guard !isEmpty else { return 0.0 }
            let goodCount = (statusDistribution[.good] ?? 0) + (statusDistribution[.excellent] ?? 0)
            return Double(goodCount) / Double(count)
        }

        /// 나쁜 수면 비율 (bad)
        var poorSleepPercentage: Double {
            guard !isEmpty else { return 0.0 }
            let badCount = statusDistribution[.bad] ?? 0
            return Double(badCount) / Double(count)
        }

        // MARK: - Trend Analysis

        /// 최근 7일 vs 이전 7일 평균 수면 시간 비교
        /// 📚 학습 포인트: Comparative Analysis
        /// 수면 패턴의 개선/악화 추세 분석
        /// - Returns: (최근 평균, 이전 평균, 변화량) 또는 nil
        func recentTrend() -> (recent: Int32, previous: Int32, change: Int32)? {
            guard count >= 14 else { return nil } // 최소 14일 데이터 필요

            let midPoint = count / 2
            let recentPoints = Array(dataPoints.suffix(midPoint))
            let previousPoints = Array(dataPoints.prefix(midPoint))

            let recentAvg = recentPoints.reduce(0) { $0 + $1.duration } / Int32(recentPoints.count)
            let previousAvg = previousPoints.reduce(0) { $0 + $1.duration } / Int32(previousPoints.count)

            return (recent: recentAvg, previous: previousAvg, change: recentAvg - previousAvg)
        }

        /// 수면 일관성 점수 (0.0 ~ 1.0, 높을수록 규칙적)
        /// 📚 학습 포인트: Consistency Score
        /// 표준편차를 정규화하여 0~1 점수로 변환
        var consistencyScore: Double? {
            guard let stdDev = durationStandardDeviation,
                  let avg = averageDuration else { return nil }

            // 표준편차가 평균의 25% 이하면 1.0 (매우 일관적)
            // 표준편차가 평균의 50% 이상이면 0.0 (매우 불규칙적)
            let coefficientOfVariation = stdDev / Double(avg)
            let normalizedScore = max(0.0, min(1.0, 1.0 - (coefficientOfVariation / 0.5)))
            return normalizedScore
        }

        // MARK: - Summary

        /// 요약 문자열
        /// 📚 학습 포인트: UI Helper Method
        /// UI에서 바로 사용할 수 있는 요약 정보
        func summary() -> String {
            guard !isEmpty else {
                return "수면 기록이 없습니다."
            }

            var summary = """
            기간: \(period.displayName)
            총 \(count)회 수면 기록
            """

            if let avg = averageDurationFormatted {
                summary += "\n평균 수면: \(avg.hours)시간 \(avg.minutes)분"
            }

            if let median = medianDuration {
                let hours = Int(median) / 60
                let minutes = Int(median) % 60
                summary += "\n중간값: \(hours)시간 \(minutes)분"
            }

            if let mostCommon = mostCommonStatus {
                let countForStatus = statusDistribution[mostCommon] ?? 0
                let percentage = Double(countForStatus) / Double(count) * 100
                summary += "\n가장 많은 상태: \(mostCommon.displayName) (\(String(format: "%.0f", percentage))%)"
            }

            if let consistency = consistencyScore {
                let consistencyPercent = consistency * 100
                summary += "\n일관성 점수: \(String(format: "%.0f", consistencyPercent))%"
            }

            let goodPercent = goodSleepPercentage * 100
            summary += "\n좋은 수면 비율: \(String(format: "%.0f", goodPercent))%"

            if let trend = recentTrend() {
                let trendHours = abs(trend.change) / 60
                let trendMinutes = abs(trend.change) % 60
                let direction = trend.change >= 0 ? "증가" : "감소"
                summary += "\n최근 추세: \(trendHours)시간 \(trendMinutes)분 \(direction)"
            }

            return summary
        }
    }

    // MARK: - Error

    /// 통계 조회 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum StatsError: Error, LocalizedError {
        /// 조회 실패
        case fetchFailed(Error)

        /// 유효하지 않은 날짜 범위
        case invalidDateRange

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .fetchFailed(let error):
                return "통계 데이터 조회 실패: \(error.localizedDescription)"
            case .invalidDateRange:
                return "유효하지 않은 날짜 범위입니다."
            }
        }
    }

    // MARK: - Dependencies

    /// 수면 데이터 저장소
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 사용 (테스트 가능성 향상)
    /// 💡 Java 비교: @Autowired Repository와 유사
    private let sleepRepository: SleepRepositoryProtocol

    // MARK: - Initialization

    /// FetchSleepStatsUseCase 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Autowired constructor injection과 유사
    ///
    /// - Parameter sleepRepository: 수면 데이터 저장소 (필수)
    init(sleepRepository: SleepRepositoryProtocol) {
        self.sleepRepository = sleepRepository
    }

    // MARK: - Execute

    /// 통계 데이터 조회 실행
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// 📚 학습 포인트: Statistics Calculation Flow
    /// 1. Repository에서 기간 내 데이터 조회
    /// 2. 차트 데이터 포인트로 변환
    /// 3. 날짜 오름차순 정렬 (차트 라이브러리 요구사항)
    /// 4. Output에서 자동으로 통계 계산 (computed properties)
    ///
    /// - Parameter input: 통계 조회 입력 데이터
    /// - Returns: 수면 통계 데이터
    /// - Throws: StatsError - 조회 실패 시
    func execute(input: Input) async throws -> Output {
        // 📚 학습 포인트: Date Range Validation
        // 시작 날짜가 종료 날짜보다 이후인 경우 에러
        guard input.startDate <= input.endDate else {
            throw StatsError.invalidDateRange
        }

        // Step 1: Repository에서 기간 내 데이터 조회
        // 📚 학습 포인트: Error Handling with do-catch
        // Repository 에러를 StatsError로 래핑하여 계층별 에러 분리
        let records: [SleepRecord]
        do {
            records = try await sleepRepository.fetch(from: input.startDate, to: input.endDate)
        } catch {
            throw StatsError.fetchFailed(error)
        }

        // Step 2: 차트 데이터 포인트로 변환
        // 📚 학습 포인트: Map Transformation
        // Domain entity를 View에 최적화된 형태로 변환
        let dataPoints = records.compactMap { record -> SleepDataPoint? in
            guard let recordId = record.id,
                  let recordDate = record.date else {
                return nil
            }

            let sleepStatus = SleepStatus(rawValue: record.status) ?? .soso

            return SleepDataPoint(
                id: recordId,
                date: recordDate,
                duration: record.duration,
                status: sleepStatus
            )
        }

        // Step 3: 날짜 오름차순 정렬
        // 📚 학습 포인트: Sorting
        // Swift Charts는 데이터가 시간순으로 정렬되어 있어야 올바르게 표시됨
        let sortedDataPoints = dataPoints.sorted { $0.date < $1.date }

        // Step 4: 결과 반환
        // 📚 학습 포인트: Computed Statistics
        // Output의 computed properties가 자동으로 통계를 계산
        return Output(
            dataPoints: sortedDataPoints,
            period: input.period,
            startDate: input.startDate,
            endDate: input.endDate
        )
    }

    // MARK: - Convenience Methods

    /// 기간만 지정한 간편 조회 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 가장 일반적인 사용 케이스를 위한 간편 메서드
    /// 💡 사용처: ViewModel에서 쉽게 호출 가능
    ///
    /// - Parameter period: 조회 기간
    /// - Returns: 수면 통계 데이터
    /// - Throws: StatsError
    func execute(period: StatsPeriod) async throws -> Output {
        let input = Input(period: period)
        return try await execute(input: input)
    }

    /// 일수를 직접 지정한 조회 메서드
    /// 📚 학습 포인트: Flexible API
    /// 표준 기간 외의 커스텀 기간 조회 가능
    ///
    /// - Parameters:
    ///   - days: 조회할 일수
    ///   - endDate: 종료 날짜 (기본값: 현재)
    /// - Returns: 수면 통계 데이터
    /// - Throws: StatsError
    func execute(days: Int, endDate: Date = Date()) async throws -> Output {
        // 📚 학습 포인트: Dynamic Period Creation
        // StatsPeriod enum에 없는 커스텀 기간도 지원
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let records = try await sleepRepository.fetch(from: startDate, to: endDate)

        let dataPoints = records.compactMap { record -> SleepDataPoint? in
            guard let recordId = record.id,
                  let recordDate = record.date else {
                return nil
            }

            let sleepStatus = SleepStatus(rawValue: record.status) ?? .soso

            return SleepDataPoint(
                id: recordId,
                date: recordDate,
                duration: record.duration,
                status: sleepStatus
            )
        }.sorted { $0.date < $1.date }

        // 커스텀 기간을 위해 가장 가까운 StatsPeriod 사용
        let period: StatsPeriod = {
            if days <= 7 { return .week }
            if days <= 30 { return .month }
            return .quarter
        }()

        return Output(
            dataPoints: dataPoints,
            period: period,
            startDate: startDate,
            endDate: endDate
        )
    }
}

// MARK: - Sample Usage

extension FetchSleepStatsUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - 최근 7일
    static let sampleInputWeek = Input(period: .week)

    /// 샘플 입력 - 최근 30일
    static let sampleInputMonth = Input(period: .month)

    /// 샘플 출력 - 7일 데이터
    static func sampleOutput() -> Output {
        let now = Date()
        let dataPoints = [
            SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -6, to: now)!,
                duration: 420, // 7시간
                status: .good
            ),
            SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -5, to: now)!,
                duration: 480, // 8시간
                status: .excellent
            ),
            SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -4, to: now)!,
                duration: 360, // 6시간
                status: .soso
            ),
            SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -3, to: now)!,
                duration: 450, // 7.5시간
                status: .excellent
            ),
            SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -2, to: now)!,
                duration: 390, // 6.5시간
                status: .good
            ),
            SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -1, to: now)!,
                duration: 300, // 5시간
                status: .bad
            ),
            SleepDataPoint(
                id: UUID(),
                date: now,
                duration: 420, // 7시간
                status: .good
            )
        ]

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        return Output(
            dataPoints: dataPoints,
            period: .week,
            startDate: startDate,
            endDate: now
        )
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: FetchSleepStatsUseCase 이해
///
/// FetchSleepStatsUseCase의 역할:
/// - Repository의 raw data를 통계 및 차트에 최적화된 형태로 변환
/// - 다양한 통계 지표 자동 계산 (평균, 중간값, 표준편차, 분포 등)
/// - 추세 분석 및 수면 품질 평가
/// - 차트 렌더링에 최적화된 데이터 제공
///
/// 제공하는 통계:
/// 1. Duration Statistics (수면 시간 통계):
///    - 평균, 최소, 최대, 중간값
///    - 총 수면 시간
///    - 시간 변화량 (첫 기록 vs 마지막 기록)
///    - 표준편차 (일관성 측정)
///
/// 2. Status Statistics (수면 상태 통계):
///    - 상태별 분포 (개수 및 비율)
///    - 가장 많은/적은 상태
///    - 좋은 수면 비율 (good + excellent)
///    - 나쁜 수면 비율 (bad)
///
/// 3. Trend Analysis (추세 분석):
///    - 최근 vs 이전 기간 비교
///    - 일관성 점수 (0~1, 높을수록 규칙적)
///    - 수면 패턴 개선/악화 여부
///
/// 지원하는 기간:
/// - 7일: 주간 통계 (빠른 변화 추적)
/// - 30일: 월간 통계 (중기 변화 추적)
/// - 90일: 분기 통계 (장기 변화 추적)
/// - 커스텀: execute(days:) 메서드로 임의 기간 조회
///
/// FetchSleepHistoryUseCase와의 차이:
/// - FetchSleepHistoryUseCase: 리스트 표시용 (날짜 내림차순)
/// - FetchSleepStatsUseCase: 차트/통계 표시용 (날짜 오름차순)
/// - FetchSleepHistoryUseCase: 기본 통계만 제공
/// - FetchSleepStatsUseCase: 고급 통계 및 추세 분석 제공
///
/// FetchBodyTrendsUseCase와의 유사점:
/// - 둘 다 차트 데이터에 최적화
/// - 날짜 오름차순 정렬
/// - 기간별 조회 (week/month/quarter)
/// - 통계 정보 자동 계산
///
/// Clean Architecture에서의 위치:
/// - Domain Layer의 Use Case
/// - SleepRepositoryProtocol에 의존
/// - Presentation Layer (ViewModel)에서 호출됨
///
/// 💡 Java Spring과의 비교:
/// - Spring: @Service class with statistics method
/// - Swift: Struct with async/await
/// - Spring: Repository를 @Autowired로 주입
/// - Swift: 생성자로 의존성 주입
///
/// 사용 예시:
/// ```swift
/// let useCase = FetchSleepStatsUseCase(sleepRepository: repository)
///
/// // 간단한 조회
/// let stats = try await useCase.execute(period: .week)
/// print(stats.summary())
///
/// // 차트에 표시
/// Chart(stats.dataPoints) { dataPoint in
///     BarMark(
///         x: .value("Date", dataPoint.date),
///         y: .value("Duration", dataPoint.duration)
///     )
///     .foregroundStyle(by: .value("Status", dataPoint.status.displayName))
/// }
///
/// // 대시보드에 통계 표시
/// if let avg = stats.averageDurationFormatted {
///     Text("평균 수면: \(avg.hours)시간 \(avg.minutes)분")
/// }
/// Text("좋은 수면 비율: \(String(format: "%.0f", stats.goodSleepPercentage * 100))%")
/// if let consistency = stats.consistencyScore {
///     Text("일관성: \(String(format: "%.0f", consistency * 100))%")
/// }
///
/// // 상태별 분포 표시
/// ForEach(stats.statusStats) { stat in
///     HStack {
///         Image(systemName: stat.status.iconName)
///             .foregroundColor(stat.status.color)
///         Text(stat.status.displayName)
///         Spacer()
///         Text("\(stat.count)회 (\(stat.percentageFormatted()))")
///     }
/// }
/// ```
///
/// 💡 실무 팁:
/// - 차트 뷰에서는 FetchSleepStatsUseCase 사용
/// - 리스트 뷰에서는 FetchSleepHistoryUseCase 사용
/// - 대시보드에서는 FetchSleepStatsUseCase로 요약 정보 표시
/// - 일관성 점수를 활용하여 수면 패턴 규칙성 평가
/// - 추세 분석으로 수면 개선/악화 여부 판단
/// - statusStats를 활용하여 상태별 분포 차트 구성
///

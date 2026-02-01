//
//  FetchBodyTrendsUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Query Use Case Pattern
// 데이터 조회 및 변환을 캡슐화하는 Use Case 패턴
// 💡 Java 비교: Service layer의 조회 메서드와 유사하지만 더 세분화됨

import Foundation

// MARK: - FetchBodyTrendsUseCase

/// 신체 구성 트렌드 조회 Use Case
/// 차트 표시를 위해 지정된 기간의 신체 구성 데이터를 조회하고 변환합니다.
/// 📚 학습 포인트: Clean Architecture - Use Case Layer
/// - 특정 비즈니스 로직(트렌드 데이터 조회)을 독립적인 유닛으로 캡슐화
/// - Repository의 raw data를 차트에 최적화된 형태로 변환
/// - UI나 데이터베이스에 의존하지 않는 순수한 비즈니스 로직
/// 💡 Java 비교: Interactor 또는 Service 클래스의 단일 책임 메서드
struct FetchBodyTrendsUseCase {

    // MARK: - Types

    /// 트렌드 기간 열거형
    /// 📚 학습 포인트: Enum with Associated Values
    /// - 사용자가 선택할 수 있는 차트 기간 정의
    /// - 각 케이스가 days 값을 가짐
    /// 💡 Java 비교: Enum with fields와 유사
    enum TrendPeriod: Int, CaseIterable, Codable {
        /// 최근 30일
        case month = 30

        /// 최근 60일
        case twoMonths = 60

        /// 최근 120일
        case fourMonths = 120

        /// 일수 값
        var days: Int {
            return self.rawValue
        }

        /// 표시 이름
        var displayName: String {
            switch self {
            case .month:
                return "30일"
            case .twoMonths:
                return "60일"
            case .fourMonths:
                return "120일"
            }
        }

        /// 예측 일수 (미래 추세선)
        var predictionDays: Int {
            switch self {
            case .month: return 20
            case .twoMonths: return 30
            case .fourMonths: return 30
            }
        }

        /// 차트 총 표시 일수 (과거 + 미래)
        var totalChartDays: Int {
            return days + predictionDays
        }

        /// X축 눈금 간격 (일수)
        var xAxisStride: Int {
            switch self {
            case .month: return 7
            case .twoMonths: return 15
            case .fourMonths: return 30
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
    /// - 날짜와 측정값을 그룹화
    /// 💡 Java 비교: Record (Java 14+) 또는 DTO와 유사
    struct TrendDataPoint: Codable, Identifiable, Equatable {
        /// 고유 식별자 (차트 렌더링 최적화)
        let id: UUID

        /// 측정 날짜
        let date: Date

        /// 체중 (kg)
        let weight: Decimal

        /// 체지방률 (%)
        let bodyFatPercent: Decimal

        /// 근육량 (kg) - 선택적 데이터
        let muscleMass: Decimal?

        /// BMR (kcal/day) - 선택적 데이터
        let bmr: Decimal?

        /// TDEE (kcal/day) - 선택적 데이터
        let tdee: Decimal?

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

    /// 트렌드 조회에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 FetchBodyTrendsUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 조회 기간
        let period: TrendPeriod

        /// 종료 날짜 (기본값: 현재)
        /// 📚 학습 포인트: Default Parameter
        /// 대부분의 경우 현재까지의 데이터를 조회하지만, 특정 시점까지의 데이터도 조회 가능
        let endDate: Date

        /// 대사율 데이터 포함 여부 (기본값: false)
        /// 📚 학습 포인트: Performance Optimization
        /// - 필요한 경우에만 추가 데이터 조회하여 성능 최적화
        /// - 차트에 BMR/TDEE를 표시하지 않는 경우 불필요한 조회 방지
        let includeMetabolismData: Bool

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
        ///   - includeMetabolismData: 대사율 데이터 포함 여부 (기본값: false)
        init(period: TrendPeriod, endDate: Date = Date(), includeMetabolismData: Bool = false) {
            self.period = period
            self.endDate = endDate
            self.includeMetabolismData = includeMetabolismData
        }
    }

    /// 트렌드 조회 결과
    /// 📚 학습 포인트: Result Type
    /// 조회된 데이터와 통계 정보를 함께 반환
    /// 💡 Java 비교: DTO (Data Transfer Object)와 유사
    struct Output {
        /// 차트 데이터 포인트 배열 (날짜 오름차순 정렬)
        /// 📚 학습 포인트: Collection Type
        /// - 차트 라이브러리가 요구하는 형태로 정렬
        /// - Swift Charts는 날짜순 정렬을 권장
        let dataPoints: [TrendDataPoint]

        /// 조회 기간
        let period: TrendPeriod

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

        /// 데이터 포인트 개수
        var count: Int {
            dataPoints.count
        }

        /// 평균 체중 (kg)
        /// 📚 학습 포인트: Aggregate Calculation
        /// 차트 요약 정보로 표시
        var averageWeight: Decimal? {
            guard !isEmpty else { return nil }
            let sum = dataPoints.reduce(Decimal(0)) { $0 + $1.weight }
            return sum / Decimal(count)
        }

        /// 평균 체지방률 (%)
        var averageBodyFatPercent: Decimal? {
            guard !isEmpty else { return nil }
            let sum = dataPoints.reduce(Decimal(0)) { $0 + $1.bodyFatPercent }
            return sum / Decimal(count)
        }

        /// 최소 체중 (kg)
        var minWeight: Decimal? {
            dataPoints.map { $0.weight }.min()
        }

        /// 최대 체중 (kg)
        var maxWeight: Decimal? {
            dataPoints.map { $0.weight }.max()
        }

        /// 최소 체지방률 (%)
        var minBodyFatPercent: Decimal? {
            dataPoints.map { $0.bodyFatPercent }.min()
        }

        /// 최대 체지방률 (%)
        var maxBodyFatPercent: Decimal? {
            dataPoints.map { $0.bodyFatPercent }.max()
        }

        /// 체중 변화량 (kg) - 기간 내 첫 기록과 마지막 기록의 차이
        /// 📚 학습 포인트: Trend Calculation
        /// 양수: 체중 증가, 음수: 체중 감소
        var weightChange: Decimal? {
            guard let first = dataPoints.first?.weight,
                  let last = dataPoints.last?.weight else {
                return nil
            }
            return last - first
        }

        /// 체지방률 변화량 (%) - 기간 내 첫 기록과 마지막 기록의 차이
        var bodyFatPercentChange: Decimal? {
            guard let first = dataPoints.first?.bodyFatPercent,
                  let last = dataPoints.last?.bodyFatPercent else {
                return nil
            }
            return last - first
        }

        /// 근육량 변화량 (kg) - 유효 데이터의 첫 기록과 마지막 기록의 차이
        var muscleMassChange: Decimal? {
            let valid = dataPoints.filter { ($0.muscleMass ?? 0) > 0 }
            guard let first = valid.first?.muscleMass,
                  let last = valid.last?.muscleMass else {
                return nil
            }
            return last - first
        }

        /// 요약 문자열
        /// 📚 학습 포인트: UI Helper Method
        /// UI에서 바로 사용할 수 있는 요약 정보
        func summary() -> String {
            guard !isEmpty else {
                return "데이터 없음"
            }

            let avgWeightStr = String(format: "%.1f", NSDecimalNumber(decimal: averageWeight ?? 0).doubleValue)
            let avgBfStr = String(format: "%.1f", NSDecimalNumber(decimal: averageBodyFatPercent ?? 0).doubleValue)

            var summary = """
            기간: \(period.displayName)
            측정 횟수: \(count)회
            평균 체중: \(avgWeightStr) kg
            평균 체지방률: \(avgBfStr)%
            """

            if let weightChange = weightChange {
                let changeStr = String(format: "%+.1f", NSDecimalNumber(decimal: weightChange).doubleValue)
                summary += "\n체중 변화: \(changeStr) kg"
            }

            if let bfChange = bodyFatPercentChange {
                let changeStr = String(format: "%+.1f", NSDecimalNumber(decimal: bfChange).doubleValue)
                summary += "\n체지방률 변화: \(changeStr)%"
            }

            return summary
        }
    }

    // MARK: - Error

    /// 트렌드 조회 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum TrendsError: Error, LocalizedError {
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
                return "트렌드 데이터 조회 실패: \(error.localizedDescription)"
            case .invalidDateRange:
                return "유효하지 않은 날짜 범위입니다."
            }
        }
    }

    // MARK: - Dependencies

    /// 신체 데이터 저장소
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 사용 (테스트 가능성 향상)
    /// 💡 Java 비교: @Autowired Repository와 유사
    private let bodyRepository: BodyRepositoryProtocol

    // MARK: - Initialization

    /// FetchBodyTrendsUseCase 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Autowired constructor injection과 유사
    ///
    /// - Parameter bodyRepository: 신체 데이터 저장소 (필수)
    init(bodyRepository: BodyRepositoryProtocol) {
        self.bodyRepository = bodyRepository
    }

    // MARK: - Execute

    /// 트렌드 데이터 조회 실행
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// 📚 학습 포인트: Query Optimization
    /// 1. Repository에서 날짜 범위로 데이터 조회
    /// 2. 차트에 최적화된 형태로 변환
    /// 3. 날짜 오름차순 정렬 (차트 라이브러리 요구사항)
    /// 4. 선택적으로 대사율 데이터 포함
    ///
    /// - Parameter input: 트렌드 조회 입력 데이터
    /// - Returns: 차트용 트렌드 데이터
    /// - Throws: TrendsError - 조회 실패 시
    func execute(input: Input) async throws -> Output {
        // 📚 학습 포인트: Date Range Validation
        // 시작 날짜가 종료 날짜보다 이후인 경우 에러
        guard input.startDate <= input.endDate else {
            throw TrendsError.invalidDateRange
        }

        // Step 1: Repository에서 기간 내 데이터 조회
        // 📚 학습 포인트: Error Handling with do-catch
        // Repository 에러를 TrendsError로 래핑하여 계층별 에러 분리
        let entries: [BodyCompositionEntry]
        do {
            entries = try await bodyRepository.fetch(from: input.startDate, to: input.endDate)
        } catch {
            throw TrendsError.fetchFailed(error)
        }

        // Step 2: 대사율 데이터 조회 (필요한 경우)
        // 📚 학습 포인트: Conditional Data Loading
        // 성능 최적화를 위해 필요한 경우에만 추가 데이터 로드
        var metabolismDataMap: [UUID: MetabolismData] = [:]
        if input.includeMetabolismData {
            // 각 entry에 대한 대사율 데이터 조회
            for entry in entries {
                if let metabolismData = try? await bodyRepository.fetchMetabolismData(for: entry.id) {
                    metabolismDataMap[entry.id] = metabolismData
                }
            }
        }

        // Step 3: 차트 데이터 포인트로 변환
        // 📚 학습 포인트: Map Transformation
        // Domain entity를 View에 최적화된 형태로 변환
        let dataPoints = entries.map { entry -> TrendDataPoint in
            let metabolism = metabolismDataMap[entry.id]
            return TrendDataPoint(
                id: entry.id,
                date: entry.date,
                weight: entry.weight,
                bodyFatPercent: entry.bodyFatPercent,
                muscleMass: entry.muscleMass,
                bmr: metabolism?.bmr,
                tdee: metabolism?.tdee
            )
        }

        // Step 4: 날짜 오름차순 정렬
        // 📚 학습 포인트: Sorting
        // Swift Charts는 데이터가 시간순으로 정렬되어 있어야 올바르게 표시됨
        let sortedDataPoints = dataPoints.sorted { $0.date < $1.date }

        // Step 5: 결과 반환
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
    /// - Returns: 차트용 트렌드 데이터
    /// - Throws: TrendsError
    func execute(period: TrendPeriod) async throws -> Output {
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
    ///   - includeMetabolismData: 대사율 데이터 포함 여부 (기본값: false)
    /// - Returns: 차트용 트렌드 데이터
    /// - Throws: TrendsError
    func execute(
        days: Int,
        endDate: Date = Date(),
        includeMetabolismData: Bool = false
    ) async throws -> Output {
        // 📚 학습 포인트: Dynamic Period Creation
        // TrendPeriod enum에 없는 커스텀 기간도 지원
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let entries = try await bodyRepository.fetch(from: startDate, to: endDate)

        var metabolismDataMap: [UUID: MetabolismData] = [:]
        if includeMetabolismData {
            for entry in entries {
                if let metabolismData = try? await bodyRepository.fetchMetabolismData(for: entry.id) {
                    metabolismDataMap[entry.id] = metabolismData
                }
            }
        }

        let dataPoints = entries.map { entry -> TrendDataPoint in
            let metabolism = metabolismDataMap[entry.id]
            return TrendDataPoint(
                id: entry.id,
                date: entry.date,
                weight: entry.weight,
                bodyFatPercent: entry.bodyFatPercent,
                muscleMass: entry.muscleMass,
                bmr: metabolism?.bmr,
                tdee: metabolism?.tdee
            )
        }.sorted { $0.date < $1.date }

        // 커스텀 기간을 위해 가장 가까운 TrendPeriod 사용
        let period: TrendPeriod = {
            if days <= 30 { return .month }
            if days <= 60 { return .twoMonths }
            return .fourMonths
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

extension FetchBodyTrendsUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - 최근 30일
    static let sampleInputMonth = Input(period: .month)

    /// 샘플 입력 - 최근 60일 (대사율 데이터 포함)
    static let sampleInputTwoMonths = Input(
        period: .twoMonths,
        includeMetabolismData: true
    )

    /// 샘플 출력 - 30일 데이터
    static func sampleOutput() -> Output {
        let now = Date()
        let dataPoints = [
            TrendDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -25, to: now)!,
                weight: Decimal(72.0),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(31.0),
                bmr: Decimal(1680),
                tdee: Decimal(2016)
            ),
            TrendDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: -15, to: now)!,
                weight: Decimal(71.2),
                bodyFatPercent: Decimal(19.3),
                muscleMass: Decimal(31.5),
                bmr: Decimal(1665),
                tdee: Decimal(2290)
            ),
            TrendDataPoint(
                id: UUID(),
                date: now,
                weight: Decimal(70.5),
                bodyFatPercent: Decimal(18.5),
                muscleMass: Decimal(32.0),
                bmr: Decimal(1650),
                tdee: Decimal(2280)
            )
        ]

        return Output(
            dataPoints: dataPoints,
            period: .month,
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: now)!,
            endDate: now
        )
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Query Use Case 이해
///
/// FetchBodyTrendsUseCase의 역할:
/// - Repository의 raw data를 차트에 최적화된 형태로 변환
/// - 날짜 범위 검증 및 데이터 정렬
/// - 선택적 데이터 로딩을 통한 성능 최적화
/// - 통계 정보 계산 (평균, 최소, 최대, 변화량 등)
///
/// 차트 최적화:
/// 1. 날짜 오름차순 정렬: Swift Charts 요구사항
/// 2. 불필요한 데이터 제거: 차트에 필요한 필드만 포함
/// 3. 조건부 데이터 로딩: includeMetabolismData 플래그
/// 4. 사전 계산된 통계: 평균, 최소, 최대 등
///
/// 지원하는 기간:
/// - 7일: 주간 트렌드 (빠른 변화 추적)
/// - 30일: 월간 트렌드 (중기 변화 추적)
/// - 90일: 분기 트렌드 (장기 변화 추적)
/// - 커스텀: execute(days:) 메서드로 임의 기간 조회
///
/// 성능 고려사항:
/// - Repository 쿼리는 0.3초 이내 목표
/// - 대사율 데이터는 필요한 경우에만 조회
/// - 데이터 변환 및 정렬은 메모리에서 수행 (빠름)
/// - 최대 90일 데이터 조회 권장 (성능 유지)
///
/// Clean Architecture에서의 위치:
/// - Domain Layer의 Use Case
/// - BodyRepositoryProtocol에 의존
/// - Presentation Layer (ViewModel)에서 호출됨
///
/// 💡 Java Spring과의 비교:
/// - Spring: @Service class with query method
/// - Swift: Struct with async/await
/// - Spring: Repository를 @Autowired로 주입
/// - Swift: 생성자로 의존성 주입
///
/// 사용 예시:
/// ```swift
/// let useCase = FetchBodyTrendsUseCase(bodyRepository: repository)
///
/// // 간단한 조회
/// let trends = try await useCase.execute(period: .month)
///
/// // 대사율 데이터 포함 조회
/// let input = FetchBodyTrendsUseCase.Input(
///     period: .month,
///     includeMetabolismData: true
/// )
/// let detailedTrends = try await useCase.execute(input: input)
///
/// // 차트에 표시
/// Chart(trends.dataPoints) { dataPoint in
///     LineMark(
///         x: .value("Date", dataPoint.date),
///         y: .value("Weight", dataPoint.weight)
///     )
/// }
///
/// // 요약 정보 표시
/// print(trends.summary())
/// ```
///

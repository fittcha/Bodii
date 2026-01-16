//
//  HealthKitReadService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Read Service
// HealthKit에서 데이터를 읽어오는 서비스
// 💡 Java 비교: Repository의 Read 메서드와 유사하지만 비동기 처리

import Foundation
import HealthKit

/// HealthKit read service
///
/// HealthKit에서 건강 데이터를 읽어오는 서비스
///
/// 📚 학습 포인트: Read Operations
/// - HKSampleQuery를 사용한 데이터 조회
/// - HKStatisticsQuery를 사용한 집계 데이터 조회
/// - 날짜 범위 기반 쿼리
/// 💡 Java 비교: DAO의 findBy* 메서드와 유사
///
/// ## 책임
/// - HealthKit에서 샘플 데이터 읽기
/// - 날짜 범위 기반 쿼리
/// - 통계 데이터 집계 (일일 합계)
/// - HKQuantitySample, HKCategorySample, HKWorkout 조회
///
/// ## 사용 시나리오
/// 1. **체중/체지방 조회**: 최근 측정값 또는 기간별 기록
/// 2. **활동 칼로리/걸음 수**: 일일 합계 집계
/// 3. **수면 데이터**: 수면 세그먼트 조회 및 총 수면 시간 계산
/// 4. **운동 데이터**: 운동 기록 조회
///
/// - Example:
/// ```swift
/// let service = HealthKitReadService(healthStore: authService.getHealthStore())
///
/// // 최근 체중 조회
/// let weight = try await service.fetchLatestWeight()
///
/// // 기간별 체중 기록 조회
/// let weights = try await service.fetchWeight(from: startDate, to: endDate)
///
/// // 일일 활동 칼로리 조회
/// let calories = try await service.fetchActiveCalories(for: date)
/// ```
final class HealthKitReadService {

    // MARK: - Properties

    /// HealthKit 데이터 저장소
    ///
    /// 📚 학습 포인트: HKHealthStore
    /// - HealthKit 데이터 읽기/쓰기를 위한 중앙 객체
    /// - 쿼리 실행 담당
    /// 💡 Java 비교: EntityManager와 유사한 역할
    ///
    /// - Note: HealthKitAuthorizationService에서 공유받아 사용
    private let healthStore: HKHealthStore

    // MARK: - Initialization

    /// HealthKitReadService 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - HKHealthStore를 외부에서 주입받아 테스트 가능하게 설계
    /// - AuthorizationService와 동일한 HKHealthStore 인스턴스 공유
    /// 💡 Java 비교: Constructor Injection
    ///
    /// - Parameter healthStore: HealthKit 데이터 저장소
    ///
    /// - Example:
    /// ```swift
    /// let authService = HealthKitAuthorizationService()
    /// let readService = HealthKitReadService(healthStore: authService.getHealthStore())
    /// ```
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Generic Query Methods

    /// HealthKit에서 샘플 데이터 조회 (제네릭 메서드)
    ///
    /// 📚 학습 포인트: Generic Method
    /// - HKSample의 모든 하위 타입(HKQuantitySample, HKCategorySample 등)에 사용 가능
    /// - 타입 안전성을 유지하면서 코드 재사용성 향상
    /// 💡 Java 비교: <T extends HKSample> 제네릭 메서드와 유사
    ///
    /// - Parameters:
    ///   - type: 조회할 HKSampleType (HKQuantityType, HKCategoryType, HKWorkoutType)
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    ///   - ascending: 정렬 순서 (true: 오래된 것부터, false: 최신 것부터)
    ///   - limit: 최대 결과 개수 (nil이면 전체 조회)
    ///
    /// - Returns: 조회된 샘플 배열 (타입별로 캐스팅됨)
    ///
    /// - Throws: HealthKitError
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///   - readFailed: 데이터 읽기 실패
    ///
    /// - Example:
    /// ```swift
    /// // 체중 데이터 조회
    /// let samples: [HKQuantitySample] = try await service.fetchSamples(
    ///     type: HealthKitDataTypes.QuantityType.weight.type!,
    ///     from: startDate,
    ///     to: endDate,
    ///     ascending: false,
    ///     limit: 10
    /// )
    ///
    /// // 수면 데이터 조회
    /// let sleepSamples: [HKCategorySample] = try await service.fetchSamples(
    ///     type: HealthKitDataTypes.CategoryType.sleepAnalysis.type!,
    ///     from: startDate,
    ///     to: endDate
    /// )
    /// ```
    func fetchSamples<T: HKSample>(
        type: HKSampleType,
        from startDate: Date,
        to endDate: Date,
        ascending: Bool = false,
        limit: Int? = nil
    ) async throws -> [T] {
        // 📚 학습 포인트: Date Range Validation
        // 시작 날짜가 종료 날짜보다 늦으면 에러
        guard startDate <= endDate else {
            throw HealthKitError.invalidDateRange(
                message: "시작 날짜(\(startDate))가 종료 날짜(\(endDate))보다 늦습니다"
            )
        }

        // 날짜 범위 predicate 생성
        let predicate = createDateRangePredicate(from: startDate, to: endDate)

        // 정렬 설정
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: ascending
        )

        // 📚 학습 포인트: HKSampleQuery
        // HealthKit에서 샘플 데이터를 조회하는 쿼리
        // 💡 Java 비교: JPA의 Query와 유사
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: limit ?? HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            // 쿼리 결과는 completion handler에서 처리됨
        }

        // 📚 학습 포인트: withCheckedThrowingContinuation
        // 콜백 기반 API를 async/await로 변환
        // 💡 Java 비교: CompletableFuture.supplyAsync()와 유사
        return try await withCheckedThrowingContinuation { continuation in
            // HKSampleQuery를 재생성 (클로저 캡처를 위해)
            let asyncQuery = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit ?? HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryExecutionFailed(
                        queryType: "HKSampleQuery",
                        error: error
                    ))
                    return
                }

                // 📚 학습 포인트: Type Casting
                // 제네릭 타입 T로 캐스팅 (실패 시 빈 배열 반환)
                // 💡 Java 비교: (List<T>) samples와 유사
                guard let typedSamples = samples as? [T] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: typedSamples)
            }

            // 쿼리 실행
            healthStore.execute(asyncQuery)
        }
    }

    // MARK: - Date Range Helpers

    /// 날짜 범위 predicate 생성
    ///
    /// 📚 학습 포인트: NSPredicate
    /// - HealthKit 쿼리에서 필터 조건을 표현
    /// - 시작일~종료일 범위의 샘플만 조회
    /// 💡 Java 비교: JPA의 Specification과 유사
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///
    /// - Returns: 날짜 범위를 나타내는 NSPredicate
    ///
    /// - Note: startDate 이상, endDate 이하의 샘플을 조회
    ///
    /// - Example:
    /// ```swift
    /// let predicate = createDateRangePredicate(
    ///     from: Date().addingTimeInterval(-7 * 24 * 3600),
    ///     to: Date()
    /// )
    /// // 최근 7일간의 데이터 조회 조건
    /// ```
    private func createDateRangePredicate(from startDate: Date, to endDate: Date) -> NSPredicate {
        return HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate, .strictEndDate]
        )
    }

    /// 특정 날짜의 시작/종료 시간 계산
    ///
    /// 📚 학습 포인트: Date Range Calculation
    /// - 특정 날짜의 00:00:00 ~ 23:59:59 범위 계산
    /// - 일일 데이터 조회에 사용
    /// 💡 Java 비교: LocalDate.atStartOfDay(), atTime(23, 59, 59)와 유사
    ///
    /// - Parameter date: 기준 날짜
    ///
    /// - Returns: (시작 시간, 종료 시간) 튜플
    ///
    /// - Example:
    /// ```swift
    /// let (start, end) = getDateBounds(for: Date())
    /// // start: 2026-01-16 00:00:00
    /// // end: 2026-01-16 23:59:59
    /// ```
    private func getDateBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        // 📚 학습 포인트: Calendar API
        // Swift의 Calendar는 날짜/시간 계산을 안전하게 처리
        // 💡 Java 비교: Calendar, LocalDate와 유사
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: startOfDay
        )?.addingTimeInterval(-1) ?? date

        return (startOfDay, endOfDay)
    }

    /// 특정 기간(일 수)의 시작/종료 날짜 계산
    ///
    /// 📚 학습 포인트: Date Calculation Helper
    /// - 현재 날짜로부터 N일 전까지의 범위 계산
    /// - 기본값으로 최근 7일 조회에 사용
    /// 💡 Java 비교: LocalDate.minusDays()와 유사
    ///
    /// - Parameters:
    ///   - days: 조회할 일 수 (기본값: 7일)
    ///   - endDate: 종료 날짜 (기본값: 현재 날짜)
    ///
    /// - Returns: (시작 날짜, 종료 날짜) 튜플
    ///
    /// - Example:
    /// ```swift
    /// let (start, end) = getDateRange(days: 30)
    /// // 최근 30일 범위
    ///
    /// let (start, end) = getDateRange(days: 7, endDate: specificDate)
    /// // specificDate로부터 7일 전 범위
    /// ```
    func getDateRange(days: Int = 7, endDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startDate = calendar.date(
            byAdding: .day,
            value: -days,
            to: endDate
        ) ?? endDate

        return (startDate, endDate)
    }

    // MARK: - Query Options

    /// 쿼리 정렬 옵션
    ///
    /// 📚 학습 포인트: Sort Order Enum
    /// - 쿼리 결과의 정렬 순서를 타입 안전하게 표현
    /// 💡 Java 비교: Sort.Direction enum과 유사
    enum SortOrder {
        /// 오래된 것부터 (과거 → 현재)
        case ascending
        /// 최신 것부터 (현재 → 과거)
        case descending

        /// Bool 값으로 변환
        ///
        /// - Returns: ascending이면 true, descending이면 false
        var boolValue: Bool {
            switch self {
            case .ascending:
                return true
            case .descending:
                return false
            }
        }
    }

    // MARK: - Statistics Query

    /// 통계 데이터 조회 (합계, 평균, 최소/최대)
    ///
    /// 📚 학습 포인트: HKStatisticsQuery
    /// - 수치 데이터의 집계 연산 (합계, 평균, 최소, 최대)
    /// - 일일 활동 칼로리, 걸음 수 등 집계에 사용
    /// 💡 Java 비교: SQL의 SUM(), AVG(), MIN(), MAX()와 유사
    ///
    /// - Parameters:
    ///   - quantityType: 집계할 HKQuantityType
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    ///   - options: 집계 옵션 (cumulativeSum, discreteAverage 등)
    ///
    /// - Returns: HKStatistics 객체 (합계, 평균 등 포함)
    ///
    /// - Throws: HealthKitError
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///   - statisticsUnavailable: 통계 데이터 없음
    ///
    /// - Example:
    /// ```swift
    /// // 일일 활동 칼로리 합계
    /// let stats = try await service.fetchStatistics(
    ///     quantityType: HealthKitDataTypes.QuantityType.activeEnergyBurned.type!,
    ///     from: startOfDay,
    ///     to: endOfDay,
    ///     options: .cumulativeSum
    /// )
    ///
    /// if let sum = stats.sumQuantity() {
    ///     let calories = sum.doubleValue(for: .kilocalorie())
    ///     print("활동 칼로리: \(calories) kcal")
    /// }
    /// ```
    func fetchStatistics(
        quantityType: HKQuantityType,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics {
        // 날짜 범위 검증
        guard startDate <= endDate else {
            throw HealthKitError.invalidDateRange(
                message: "시작 날짜가 종료 날짜보다 늦습니다"
            )
        }

        let predicate = createDateRangePredicate(from: startDate, to: endDate)

        // 📚 학습 포인트: HKStatisticsQuery
        // 수치 데이터의 집계 쿼리
        // 💡 Java 비교: Aggregation Query와 유사
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryExecutionFailed(
                        queryType: "HKStatisticsQuery",
                        error: error
                    ))
                    return
                }

                guard let statistics = statistics else {
                    continuation.resume(throwing: HealthKitError.statisticsUnavailable(
                        type: quantityType.identifier
                    ))
                    return
                }

                continuation.resume(returning: statistics)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Convenience Methods

extension HealthKitReadService {

    /// 최근 N개의 샘플 조회
    ///
    /// 📚 학습 포인트: Convenience Method
    /// - 자주 사용하는 패턴을 간편하게 호출
    /// - 기본적으로 최신 것부터 정렬
    /// 💡 Java 비교: findTop10ByOrderByDateDesc()와 유사
    ///
    /// - Parameters:
    ///   - type: 조회할 HKSampleType
    ///   - limit: 조회할 개수 (기본값: 10)
    ///
    /// - Returns: 최근 샘플 배열
    ///
    /// - Throws: HealthKitError
    ///
    /// - Example:
    /// ```swift
    /// // 최근 체중 10개 조회
    /// let recentWeights: [HKQuantitySample] = try await service.fetchRecentSamples(
    ///     type: HealthKitDataTypes.QuantityType.weight.type!,
    ///     limit: 10
    /// )
    /// ```
    func fetchRecentSamples<T: HKSample>(
        type: HKSampleType,
        limit: Int = 10
    ) async throws -> [T] {
        // 📚 학습 포인트: Distant Past/Future
        // Date.distantPast: 아주 오래된 날짜 (전체 조회용)
        // 💡 Java 비교: LocalDate.MIN과 유사
        return try await fetchSamples(
            type: type,
            from: Date.distantPast,
            to: Date(),
            ascending: false,
            limit: limit
        )
    }

    /// 특정 날짜의 샘플 조회
    ///
    /// 📚 학습 포인트: Daily Data Query
    /// - 특정 날짜(00:00:00 ~ 23:59:59)의 모든 샘플 조회
    /// 💡 Java 비교: findByDateBetween()와 유사
    ///
    /// - Parameters:
    ///   - type: 조회할 HKSampleType
    ///   - date: 조회할 날짜
    ///
    /// - Returns: 해당 날짜의 샘플 배열
    ///
    /// - Throws: HealthKitError
    ///
    /// - Example:
    /// ```swift
    /// // 특정 날짜의 운동 기록 조회
    /// let workouts: [HKWorkout] = try await service.fetchSamples(
    ///     type: HealthKitDataTypes.workoutType,
    ///     for: specificDate
    /// )
    /// ```
    func fetchSamples<T: HKSample>(
        type: HKSampleType,
        for date: Date
    ) async throws -> [T] {
        let (start, end) = getDateBounds(for: date)
        return try await fetchSamples(
            type: type,
            from: start,
            to: end,
            ascending: false
        )
    }
}

// MARK: - Weight & Body Fat Reading

extension HealthKitReadService {

    /// 체중 데이터 조회 (기간별)
    ///
    /// 📚 학습 포인트: Weight Data Reading
    /// - HealthKit의 HKQuantityType.bodyMass 사용
    /// - 여러 소스(앱, 스마트 저울 등)의 체중 기록 통합 조회
    /// 💡 Java 비교: findWeightByDateRange()와 유사
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///
    /// - Returns: 체중 샘플 배열 (최신 순)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 체중 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Example:
    /// ```swift
    /// // 최근 7일 체중 기록 조회
    /// let (start, end) = service.getDateRange(days: 7)
    /// let weights = try await service.fetchWeight(from: start, to: end)
    ///
    /// for sample in weights {
    ///     let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
    ///     print("체중: \(kg) kg, 날짜: \(sample.startDate)")
    /// }
    /// ```
    func fetchWeight(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        // 📚 학습 포인트: Type Safety with Optional Unwrapping
        // HealthKitDataTypes를 사용해 타입 안전하게 체중 타입 가져오기
        // 💡 Java 비교: Optional.orElseThrow()와 유사
        guard let weightType = HealthKitDataTypes.QuantityType.weight.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.QuantityType.weight.identifier.rawValue
            )
        }

        // 제네릭 fetchSamples 메서드 재사용
        return try await fetchSamples(
            type: weightType,
            from: startDate,
            to: endDate,
            ascending: false
        )
    }

    /// 체지방률 데이터 조회 (기간별)
    ///
    /// 📚 학습 포인트: Body Fat Percentage Reading
    /// - HealthKit의 HKQuantityType.bodyFatPercentage 사용
    /// - 스마트 저울이나 InBody 기기에서 기록한 체지방률 조회
    /// 💡 Java 비교: findBodyFatPercentageByDateRange()와 유사
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///
    /// - Returns: 체지방률 샘플 배열 (최신 순)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 체지방률 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Example:
    /// ```swift
    /// // 최근 30일 체지방률 기록 조회
    /// let (start, end) = service.getDateRange(days: 30)
    /// let bodyFats = try await service.fetchBodyFatPercentage(from: start, to: end)
    ///
    /// for sample in bodyFats {
    ///     let percent = sample.quantity.doubleValue(for: .percent())
    ///     print("체지방률: \(percent * 100)%, 날짜: \(sample.startDate)")
    /// }
    /// ```
    func fetchBodyFatPercentage(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        // 체지방률 타입 가져오기
        guard let bodyFatType = HealthKitDataTypes.QuantityType.bodyFatPercentage.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.QuantityType.bodyFatPercentage.identifier.rawValue
            )
        }

        // 제네릭 fetchSamples 메서드 재사용
        return try await fetchSamples(
            type: bodyFatType,
            from: startDate,
            to: endDate,
            ascending: false
        )
    }

    /// 최근 체중 조회 (1개)
    ///
    /// 📚 학습 포인트: Latest Record Query
    /// - 가장 최근에 기록된 체중 데이터 1개만 조회
    /// - 사용자의 현재 체중 표시에 사용
    /// 💡 Java 비교: findTopByOrderByDateDesc()와 유사
    ///
    /// - Returns: 최근 체중 샘플 (없으면 nil)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 체중 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Example:
    /// ```swift
    /// // 최근 체중 1개 조회
    /// if let latestWeight = try await service.fetchLatestWeight() {
    ///     let kg = latestWeight.quantity.doubleValue(for: .gramUnit(with: .kilo))
    ///     print("현재 체중: \(kg) kg")
    /// } else {
    ///     print("체중 기록이 없습니다")
    /// }
    /// ```
    func fetchLatestWeight() async throws -> HKQuantitySample? {
        // 체중 타입 가져오기
        guard let weightType = HealthKitDataTypes.QuantityType.weight.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.QuantityType.weight.identifier.rawValue
            )
        }

        // 📚 학습 포인트: fetchRecentSamples with limit 1
        // 최근 1개만 조회하여 성능 최적화
        // 💡 Java 비교: findFirstByOrderByDateDesc()와 유사
        let samples: [HKQuantitySample] = try await fetchRecentSamples(
            type: weightType,
            limit: 1
        )

        // 첫 번째 샘플 반환 (없으면 nil)
        return samples.first
    }

    /// 최근 체지방률 조회 (1개)
    ///
    /// 📚 학습 포인트: Latest Body Fat Query
    /// - 가장 최근에 기록된 체지방률 데이터 1개만 조회
    /// - 사용자의 현재 체지방률 표시에 사용
    /// 💡 Java 비교: findTopByOrderByDateDesc()와 유사
    ///
    /// - Returns: 최근 체지방률 샘플 (없으면 nil)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 체지방률 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Example:
    /// ```swift
    /// // 최근 체지방률 1개 조회
    /// if let latestBodyFat = try await service.fetchLatestBodyFatPercentage() {
    ///     let percent = latestBodyFat.quantity.doubleValue(for: .percent())
    ///     print("현재 체지방률: \(percent * 100)%")
    /// } else {
    ///     print("체지방률 기록이 없습니다")
    /// }
    /// ```
    func fetchLatestBodyFatPercentage() async throws -> HKQuantitySample? {
        // 체지방률 타입 가져오기
        guard let bodyFatType = HealthKitDataTypes.QuantityType.bodyFatPercentage.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.QuantityType.bodyFatPercentage.identifier.rawValue
            )
        }

        // 최근 1개만 조회
        let samples: [HKQuantitySample] = try await fetchRecentSamples(
            type: bodyFatType,
            limit: 1
        )

        // 첫 번째 샘플 반환 (없으면 nil)
        return samples.first
    }
}

// MARK: - HKQuantity Conversion Helpers

extension HealthKitReadService {

    /// HKQuantity를 Decimal로 변환 (체중용)
    ///
    /// 📚 학습 포인트: Unit Conversion
    /// - HealthKit의 HKQuantity를 앱의 Decimal 타입으로 변환
    /// - kg 단위로 통일
    /// 💡 Java 비교: BigDecimal 변환과 유사
    ///
    /// - Parameter quantity: 변환할 HKQuantity
    ///
    /// - Returns: kg 단위의 Decimal 값
    ///
    /// - Example:
    /// ```swift
    /// let sample = try await service.fetchLatestWeight()
    /// if let sample = sample {
    ///     let weight = service.convertWeightToDecimal(sample.quantity)
    ///     print("체중: \(weight) kg") // Decimal 타입
    /// }
    /// ```
    func convertWeightToDecimal(_ quantity: HKQuantity) -> Decimal {
        // 📚 학습 포인트: Double to Decimal Conversion
        // Double은 부동소수점 오차가 있으므로 금융/건강 데이터는 Decimal 사용
        // 💡 Java 비교: BigDecimal.valueOf(double)과 유사
        let kg = quantity.doubleValue(for: .gramUnit(with: .kilo))
        return Decimal(kg)
    }

    /// HKQuantity를 Decimal로 변환 (체지방률용)
    ///
    /// 📚 학습 포인트: Percentage Unit Conversion
    /// - HealthKit의 percent는 0.0~1.0 범위 (0.185 = 18.5%)
    /// - 앱에서는 0~100 범위로 변환하여 사용
    /// 💡 Java 비교: BigDecimal 변환과 유사
    ///
    /// - Parameter quantity: 변환할 HKQuantity
    ///
    /// - Returns: 퍼센트 값의 Decimal (0~100 범위)
    ///
    /// - Example:
    /// ```swift
    /// let sample = try await service.fetchLatestBodyFatPercentage()
    /// if let sample = sample {
    ///     let bodyFat = service.convertBodyFatPercentageToDecimal(sample.quantity)
    ///     print("체지방률: \(bodyFat)%") // 18.5% -> Decimal(18.5)
    /// }
    /// ```
    func convertBodyFatPercentageToDecimal(_ quantity: HKQuantity) -> Decimal {
        // 📚 학습 포인트: HealthKit Percent Unit
        // HealthKit percent(): 0.0 ~ 1.0 범위
        // 앱 표시: 0 ~ 100 범위
        // 💡 Java 비교: (double * 100)을 BigDecimal로 변환
        let percentValue = quantity.doubleValue(for: .percent())
        return Decimal(percentValue * 100)
    }
}

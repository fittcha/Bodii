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

// MARK: - Active Calories & Steps Reading

extension HealthKitReadService {

    /// 활동 칼로리 조회 (일일 합계)
    ///
    /// 📚 학습 포인트: Active Energy Burned
    /// - HKQuantityType.activeEnergyBurned 사용
    /// - HKStatisticsQuery로 하루 동안의 활동 칼로리 합계 계산
    /// - 여러 소스(Apple Watch, iPhone, 다른 앱)의 데이터 자동 집계
    /// 💡 Java 비교: SUM(calories) WHERE date = ?와 유사
    ///
    /// - Parameter date: 조회할 날짜
    ///
    /// - Returns: 해당 날짜의 활동 칼로리 합계 (kcal), 데이터 없으면 nil
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 활동 칼로리 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Note:
    ///   - activeEnergyBurned는 기초대사량을 제외한 활동으로 소모된 칼로리
    ///   - basalEnergyBurned(기초대사량)와는 별개
    ///   - 여러 소스의 중복 데이터는 HealthKit이 자동으로 처리
    ///
    /// - Example:
    /// ```swift
    /// // 오늘의 활동 칼로리 조회
    /// if let calories = try await service.fetchActiveCalories(for: Date()) {
    ///     print("오늘 활동 칼로리: \(calories) kcal")
    /// } else {
    ///     print("활동 칼로리 데이터가 없습니다")
    /// }
    ///
    /// // 특정 날짜의 활동 칼로리 조회
    /// let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    /// if let calories = try await service.fetchActiveCalories(for: yesterday) {
    ///     print("어제 활동 칼로리: \(calories) kcal")
    /// }
    /// ```
    func fetchActiveCalories(for date: Date) async throws -> Decimal? {
        // 📚 학습 포인트: Type Safety with Optional Unwrapping
        // HealthKitDataTypes를 사용해 타입 안전하게 활동 칼로리 타입 가져오기
        // 💡 Java 비교: Optional.orElseThrow()와 유사
        guard let caloriesType = HealthKitDataTypes.QuantityType.activeEnergyBurned.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.QuantityType.activeEnergyBurned.identifier.rawValue
            )
        }

        // 📚 학습 포인트: Date Range for Daily Data
        // 특정 날짜의 00:00:00 ~ 23:59:59 범위 계산
        let (startOfDay, endOfDay) = getDateBounds(for: date)

        // 📚 학습 포인트: HKStatisticsQuery with cumulativeSum
        // - cumulativeSum: 누적 합계 계산 (활동 칼로리, 걸음 수 등)
        // - 여러 소스의 데이터를 HealthKit이 자동으로 집계
        // - 중복 데이터는 HealthKit의 알고리즘이 제거
        // 💡 Java 비교: GROUP BY date와 SUM() 집계 함수
        let statistics = try await fetchStatistics(
            quantityType: caloriesType,
            from: startOfDay,
            to: endOfDay,
            options: .cumulativeSum
        )

        // 📚 학습 포인트: Optional Chaining
        // sumQuantity()가 nil이면 전체가 nil 반환
        // 💡 Java 비교: Optional.map()과 유사
        guard let sum = statistics.sumQuantity() else {
            return nil
        }

        // kcal 단위로 변환하여 Decimal로 반환
        let kcal = sum.doubleValue(for: .kilocalorie())
        return Decimal(kcal)
    }

    /// 걸음 수 조회 (일일 합계)
    ///
    /// 📚 학습 포인트: Step Count
    /// - HKQuantityType.stepCount 사용
    /// - HKStatisticsQuery로 하루 동안의 걸음 수 합계 계산
    /// - iPhone과 Apple Watch의 걸음 수 자동 통합
    /// 💡 Java 비교: SUM(steps) WHERE date = ?와 유사
    ///
    /// - Parameter date: 조회할 날짜
    ///
    /// - Returns: 해당 날짜의 걸음 수 합계, 데이터 없으면 nil
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 걸음 수 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Note:
    ///   - iPhone과 Apple Watch가 동시에 걸음을 측정하면 HealthKit이 중복 제거
    ///   - 일반적으로 Apple Watch 착용 시 Watch 데이터 우선
    ///   - 착용하지 않은 시간은 iPhone 데이터 사용
    ///
    /// - Example:
    /// ```swift
    /// // 오늘의 걸음 수 조회
    /// if let steps = try await service.fetchSteps(for: Date()) {
    ///     print("오늘 걸음 수: \(steps)걸음")
    /// } else {
    ///     print("걸음 수 데이터가 없습니다")
    /// }
    ///
    /// // 최근 7일 걸음 수 조회
    /// let calendar = Calendar.current
    /// for dayOffset in 0..<7 {
    ///     let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
    ///     if let steps = try await service.fetchSteps(for: date) {
    ///         print("\(date): \(steps)걸음")
    ///     }
    /// }
    /// ```
    func fetchSteps(for date: Date) async throws -> Decimal? {
        // 걸음 수 타입 가져오기
        guard let stepsType = HealthKitDataTypes.QuantityType.stepCount.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.QuantityType.stepCount.identifier.rawValue
            )
        }

        // 특정 날짜의 시작/종료 시간 계산
        let (startOfDay, endOfDay) = getDateBounds(for: date)

        // 📚 학습 포인트: cumulativeSum for Step Count
        // 걸음 수는 누적 합계로 집계
        // iPhone과 Apple Watch의 데이터를 HealthKit이 자동으로 통합
        // 💡 Java 비교: SUM(steps) GROUP BY date
        let statistics = try await fetchStatistics(
            quantityType: stepsType,
            from: startOfDay,
            to: endOfDay,
            options: .cumulativeSum
        )

        // 합계 값 추출
        guard let sum = statistics.sumQuantity() else {
            return nil
        }

        // 📚 학습 포인트: Count Unit
        // 걸음 수는 HKUnit.count() 단위 사용
        // 💡 Java 비교: Integer 타입이지만 Decimal로 변환
        let count = sum.doubleValue(for: .count())
        return Decimal(count)
    }
}

// MARK: - Sleep Data Reading

extension HealthKitReadService {

    /// 수면 데이터 구조체
    ///
    /// 📚 학습 포인트: Sleep Data Model
    /// - HealthKit에서 조회한 수면 데이터를 담는 구조체
    /// - 여러 수면 세그먼트의 정보를 통합하여 제공
    /// 💡 Java 비교: DTO(Data Transfer Object)와 유사
    ///
    /// - Note: HealthKit의 수면 데이터는 여러 세그먼트로 나뉠 수 있음
    ///         (예: 자다가 깨어났다가 다시 잠든 경우)
    ///
    /// - Example:
    /// ```swift
    /// let sleepData = SleepData(
    ///     totalDurationMinutes: 420,  // 7시간
    ///     segments: sleepSamples,
    ///     startDate: Date(),
    ///     endDate: Date().addingTimeInterval(7 * 3600)
    /// )
    /// ```
    struct SleepData {
        /// 총 수면 시간 (분 단위)
        ///
        /// 📚 학습 포인트: Sleep Duration Calculation
        /// - 여러 수면 세그먼트의 실제 수면 시간만 합산
        /// - inBed 상태는 제외하고 asleep 상태만 계산
        /// 💡 Java 비교: sum(durations)와 유사
        let totalDurationMinutes: Int

        /// 수면 세그먼트 배열
        ///
        /// 📚 학습 포인트: Sleep Segments
        /// - HealthKit은 수면을 여러 세그먼트로 기록
        /// - 각 세그먼트: inBed, asleep, awake, core, deep, REM 등
        /// 💡 Java 비교: List<HKCategorySample>과 유사
        let segments: [HKCategorySample]

        /// 첫 번째 수면 세그먼트 시작 시간
        ///
        /// - Note: nil이면 수면 데이터가 없음
        let startDate: Date?

        /// 마지막 수면 세그먼트 종료 시간
        ///
        /// - Note: nil이면 수면 데이터가 없음
        let endDate: Date?
    }

    /// 수면 데이터 조회 (특정 날짜)
    ///
    /// 📚 학습 포인트: Sleep Analysis
    /// - HKCategoryType.sleepAnalysis 사용
    /// - 수면 세그먼트를 조회하고 실제 수면 시간 계산
    /// - inBed(침대에 누워있음)는 제외하고 asleep(실제 수면) 상태만 집계
    /// 💡 Java 비교: findSleepRecordsByDate()와 유사
    ///
    /// - Parameter date: 조회할 날짜
    ///
    /// - Returns: SleepData 객체 (수면 데이터가 없으면 nil)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 수면 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Note: 수면 카테고리 종류
    ///   - **HKCategoryValueSleepAnalysis.inBed**: 침대에 누워있음 (수면 시간 미포함)
    ///   - **HKCategoryValueSleepAnalysis.asleep**: 수면 중 (구형, 수면 시간 포함)
    ///   - **HKCategoryValueSleepAnalysis.awake**: 깨어있음 (수면 시간 미포함)
    ///   - **HKCategoryValueSleepAnalysis.asleepCore**: 얕은 수면 (iOS 16+, 수면 시간 포함)
    ///   - **HKCategoryValueSleepAnalysis.asleepDeep**: 깊은 수면 (iOS 16+, 수면 시간 포함)
    ///   - **HKCategoryValueSleepAnalysis.asleepREM**: 렘수면 (iOS 16+, 수면 시간 포함)
    ///   - **HKCategoryValueSleepAnalysis.asleepUnspecified**: 미분류 수면 (iOS 16+, 수면 시간 포함)
    ///
    /// - Note: 수면 시간 계산 규칙
    ///   - asleep, asleepCore, asleepDeep, asleepREM, asleepUnspecified만 수면 시간으로 집계
    ///   - inBed, awake는 수면 시간에서 제외
    ///   - 여러 세그먼트의 총 시간을 합산
    ///
    /// - Example:
    /// ```swift
    /// // 오늘의 수면 데이터 조회
    /// if let sleepData = try await service.fetchSleepData(for: Date()) {
    ///     print("총 수면 시간: \(sleepData.totalDurationMinutes)분")
    ///     print("수면 세그먼트 수: \(sleepData.segments.count)개")
    ///
    ///     if let start = sleepData.startDate, let end = sleepData.endDate {
    ///         print("수면 시작: \(start)")
    ///         print("수면 종료: \(end)")
    ///     }
    /// } else {
    ///     print("수면 데이터가 없습니다")
    /// }
    ///
    /// // 어제의 수면 데이터 조회
    /// let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    /// if let sleepData = try await service.fetchSleepData(for: yesterday) {
    ///     print("어제 수면 시간: \(sleepData.totalDurationMinutes)분")
    /// }
    /// ```
    func fetchSleepData(for date: Date) async throws -> SleepData? {
        // 📚 학습 포인트: Type Safety with Optional Unwrapping
        // HealthKitDataTypes를 사용해 타입 안전하게 수면 타입 가져오기
        // 💡 Java 비교: Optional.orElseThrow()와 유사
        guard let sleepType = HealthKitDataTypes.CategoryType.sleepAnalysis.type else {
            throw HealthKitError.invalidSampleType(
                identifier: HealthKitDataTypes.CategoryType.sleepAnalysis.identifier.rawValue
            )
        }

        // 📚 학습 포인트: Extended Date Range for Sleep
        // 수면은 전날 밤부터 다음날 새벽까지 이어질 수 있으므로
        // 검색 범위를 전날 12시부터 다음날 12시까지로 확장
        // 💡 Java 비교: date.minusHours(12) ~ date.plusHours(36)과 유사
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // 전날 12:00부터 검색 (수면이 전날 밤부터 시작될 수 있음)
        let searchStart = calendar.date(
            byAdding: .hour,
            value: -12,
            to: startOfDay
        ) ?? startOfDay

        // 다음날 12:00까지 검색 (수면이 다음날 낮까지 이어질 수 있음)
        let searchEnd = calendar.date(
            byAdding: .hour,
            value: 36,
            to: startOfDay
        ) ?? startOfDay

        // 수면 샘플 조회
        let samples: [HKCategorySample] = try await fetchSamples(
            type: sleepType,
            from: searchStart,
            to: searchEnd,
            ascending: true
        )

        // 📚 학습 포인트: Early Return Pattern
        // 데이터가 없으면 nil 반환
        // 💡 Java 비교: Optional.empty()와 유사
        guard !samples.isEmpty else {
            return nil
        }

        // 실제 수면 샘플만 필터링 (asleep 상태만)
        let asleepSamples = filterAsleepSamples(samples)

        // 수면 샘플이 없으면 nil 반환
        guard !asleepSamples.isEmpty else {
            return nil
        }

        // 총 수면 시간 계산 (분 단위)
        let totalMinutes = calculateTotalSleepDuration(asleepSamples)

        // 시작/종료 시간 계산
        let startDate = asleepSamples.first?.startDate
        let endDate = asleepSamples.last?.endDate

        // SleepData 객체 생성
        return SleepData(
            totalDurationMinutes: totalMinutes,
            segments: asleepSamples,
            startDate: startDate,
            endDate: endDate
        )
    }

    /// 실제 수면 샘플만 필터링 (asleep 상태만)
    ///
    /// 📚 학습 포인트: Sleep State Filtering
    /// - inBed(침대에 누워있음)와 awake(깨어있음)는 제외
    /// - asleep 관련 상태만 실제 수면으로 간주
    /// 💡 Java 비교: stream().filter()와 유사
    ///
    /// - Parameter samples: 전체 수면 샘플 배열
    ///
    /// - Returns: 실제 수면 샘플만 포함된 배열
    ///
    /// - Note: 수면으로 간주하는 상태
    ///   - asleep (구형 기기)
    ///   - asleepUnspecified (iOS 16+)
    ///   - asleepCore (얕은 수면, iOS 16+)
    ///   - asleepDeep (깊은 수면, iOS 16+)
    ///   - asleepREM (렘수면, iOS 16+)
    ///
    /// - Example:
    /// ```swift
    /// let allSamples = [inBedSample, asleepSample, awakeSample]
    /// let asleepOnly = filterAsleepSamples(allSamples)
    /// // [asleepSample] 만 반환
    /// ```
    private func filterAsleepSamples(_ samples: [HKCategorySample]) -> [HKCategorySample] {
        return samples.filter { sample in
            // 📚 학습 포인트: HKCategoryValueSleepAnalysis
            // HealthKit의 수면 상태 enum
            // 💡 Java 비교: SleepState enum과 유사
            let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)

            switch value {
            case .asleep,           // 구형: 수면 중 (상세 단계 없음)
                 .asleepUnspecified,// iOS 16+: 미분류 수면
                 .asleepCore,       // iOS 16+: 얕은 수면 (코어 수면)
                 .asleepDeep,       // iOS 16+: 깊은 수면
                 .asleepREM:        // iOS 16+: 렘수면
                return true
            case .inBed,            // 침대에 누워있음 (수면 아님)
                 .awake:            // 깨어있음 (수면 아님)
                return false
            @unknown default:
                // 📚 학습 포인트: Future-Proofing
                // 미래에 추가될 수 있는 수면 상태 대비
                // 기본적으로 포함시키지 않음
                return false
            }
        }
    }

    /// 수면 세그먼트의 총 수면 시간 계산 (분 단위)
    ///
    /// 📚 학습 포인트: Duration Calculation
    /// - 각 수면 세그먼트의 시작/종료 시간 차이를 계산
    /// - 모든 세그먼트의 시간을 합산
    /// 💡 Java 비교: sum(endDate - startDate)와 유사
    ///
    /// - Parameter samples: 수면 샘플 배열
    ///
    /// - Returns: 총 수면 시간 (분 단위)
    ///
    /// - Note: TimeInterval은 초 단위이므로 60으로 나눠 분 단위로 변환
    ///
    /// - Example:
    /// ```swift
    /// // 3개의 수면 세그먼트: 2시간, 30분, 4시간 30분
    /// let samples = [sample1, sample2, sample3]
    /// let totalMinutes = calculateTotalSleepDuration(samples)
    /// // 420분 (7시간) 반환
    /// ```
    private func calculateTotalSleepDuration(_ samples: [HKCategorySample]) -> Int {
        // 📚 학습 포인트: reduce with Accumulator
        // 배열의 값을 누적하여 하나의 값으로 만들기
        // 💡 Java 비교: stream().reduce()와 유사
        let totalSeconds = samples.reduce(0.0) { total, sample in
            // 📚 학습 포인트: TimeInterval
            // Swift의 TimeInterval은 Double 타입으로 초 단위
            // 💡 Java 비교: Duration.between()과 유사
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            return total + duration
        }

        // 📚 학습 포인트: Unit Conversion
        // 초를 분으로 변환 (60으로 나눔)
        // 💡 Java 비교: totalSeconds / 60과 동일
        let totalMinutes = Int(totalSeconds / 60)

        return totalMinutes
    }
}

// MARK: - Workout Data Reading

extension HealthKitReadService {

    /// 운동 데이터 구조체
    ///
    /// 📚 학습 포인트: Workout Data Model
    /// - HealthKit에서 조회한 운동 데이터를 담는 구조체
    /// - HKWorkout을 앱의 ExerciseRecord로 변환할 때 사용
    /// 💡 Java 비교: DTO(Data Transfer Object)와 유사
    ///
    /// - Note: HKWorkout은 duration, calories, activityType 등의 정보 포함
    ///
    /// - Example:
    /// ```swift
    /// let workoutData = WorkoutData(
    ///     workout: hkWorkout,
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     caloriesBurned: 350
    /// )
    /// ```
    struct WorkoutData {
        /// HealthKit 원본 운동 객체
        ///
        /// 📚 학습 포인트: HKWorkout
        /// - HealthKit의 운동 기록 객체
        /// - UUID를 통해 중복 검사 가능
        /// 💡 Java 비교: Entity 객체와 유사
        let workout: HKWorkout

        /// 앱의 운동 종류 enum
        ///
        /// 📚 학습 포인트: HKWorkoutActivityType Mapping
        /// - HKWorkoutActivityType을 ExerciseType으로 변환
        /// - 앱에서 지원하는 운동 종류로 정규화
        /// 💡 Java 비교: Enum Mapping과 유사
        let exerciseType: ExerciseType

        /// 운동 시간 (분 단위)
        ///
        /// 📚 학습 포인트: Duration Conversion
        /// - HKWorkout.duration은 초 단위 (TimeInterval)
        /// - 앱에서는 분 단위로 저장
        /// 💡 Java 비교: Duration.toMinutes()와 유사
        let duration: Int32

        /// 소모 칼로리 (kcal)
        ///
        /// 📚 학습 포인트: Active Energy Burned
        /// - HKWorkout.totalEnergyBurned에서 추출
        /// - nil이면 0으로 처리 (일부 운동은 칼로리 데이터 없음)
        /// 💡 Java 비교: Optional.orElse(0)와 유사
        let caloriesBurned: Int32

        /// 운동 강도 (HealthKit에는 없으므로 기본값 중강도)
        ///
        /// 📚 학습 포인트: Default Intensity
        /// - HKWorkout에는 강도 정보가 없음
        /// - 기본값으로 중강도(medium) 사용
        /// - 추후 심박수 데이터로 추정 가능
        /// 💡 Java 비교: Default value 설정과 유사
        let intensity: Intensity

        /// HealthKit UUID (중복 검사용)
        ///
        /// 📚 학습 포인트: Duplicate Detection
        /// - HKWorkout의 UUID를 저장하여 중복 import 방지
        /// - 앱의 ExerciseRecord에 healthKitId로 저장
        /// 💡 Java 비교: External ID 참조와 유사
        var healthKitId: UUID {
            workout.uuid
        }

        /// 운동 시작 시간
        var startDate: Date {
            workout.startDate
        }

        /// 운동 종료 시간
        var endDate: Date {
            workout.endDate
        }
    }

    /// 운동 데이터 조회 (기간별)
    ///
    /// 📚 학습 포인트: Workout Data Reading
    /// - HKWorkoutType을 사용하여 운동 기록 조회
    /// - Apple Watch, iPhone, 다른 앱의 운동 기록 통합 조회
    /// 💡 Java 비교: findWorkoutsByDateRange()와 유사
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///
    /// - Returns: 운동 데이터 배열 (최신 순)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 운동 타입 생성 실패
    ///   - queryExecutionFailed: 쿼리 실행 실패
    ///
    /// - Note: HKWorkout 구조
    ///   - workoutActivityType: 운동 종류 (running, cycling 등)
    ///   - duration: 운동 시간 (초 단위)
    ///   - totalEnergyBurned: 소모 칼로리 (kcal)
    ///   - startDate, endDate: 운동 시작/종료 시간
    ///   - uuid: 중복 검사용 고유 ID
    ///
    /// - Example:
    /// ```swift
    /// // 최근 7일 운동 기록 조회
    /// let (start, end) = service.getDateRange(days: 7)
    /// let workouts = try await service.fetchWorkouts(from: start, to: end)
    ///
    /// for workout in workouts {
    ///     print("운동: \(workout.exerciseType.displayName)")
    ///     print("시간: \(workout.duration)분")
    ///     print("칼로리: \(workout.caloriesBurned) kcal")
    ///     print("날짜: \(workout.startDate)")
    /// }
    /// ```
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutData] {
        // 📚 학습 포인트: HKWorkoutType
        // HealthKit의 운동 타입 (HKQuantityType, HKCategoryType과 별개)
        // 💡 Java 비교: WorkoutEntity 타입과 유사
        let workoutType = HealthKitDataTypes.workoutType

        // 📚 학습 포인트: Generic fetchSamples with HKWorkout
        // HKWorkout도 HKSample의 하위 타입이므로 제네릭 메서드 사용 가능
        // 💡 Java 비교: Repository<T extends Entity>와 유사
        let workouts: [HKWorkout] = try await fetchSamples(
            type: workoutType,
            from: startDate,
            to: endDate,
            ascending: false
        )

        // 📚 학습 포인트: Mapping to Domain Model
        // HealthKit의 HKWorkout을 앱의 WorkoutData로 변환
        // 💡 Java 비교: Entity to DTO mapping과 유사
        return workouts.compactMap { workout in
            // HKWorkoutActivityType을 ExerciseType으로 변환
            guard let exerciseType = mapWorkoutActivityType(workout.workoutActivityType) else {
                // 매핑 실패 시 해당 운동 스킵 (지원하지 않는 운동 종류)
                return nil
            }

            // 운동 시간 (초 -> 분)
            let duration = Int32(workout.duration / 60)

            // 소모 칼로리 (nil이면 0)
            let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0
            let caloriesBurned = Int32(calories)

            // 기본 강도는 중강도 (HealthKit에는 강도 정보 없음)
            let intensity = Intensity.medium

            return WorkoutData(
                workout: workout,
                exerciseType: exerciseType,
                duration: duration,
                caloriesBurned: caloriesBurned,
                intensity: intensity
            )
        }
    }

    /// HKWorkoutActivityType을 ExerciseType으로 변환
    ///
    /// 📚 학습 포인트: Workout Type Mapping
    /// - HealthKit의 70+ 운동 종류를 앱의 8가지 운동 종류로 매핑
    /// - 유사한 운동들을 그룹화하여 단순화
    /// 💡 Java 비교: Enum Mapping Utility와 유사
    ///
    /// - Parameter activityType: HealthKit 운동 종류
    ///
    /// - Returns: 앱의 운동 종류 enum (매핑 실패 시 nil)
    ///
    /// - Note: 매핑 규칙
    ///   - walking 계열 -> .walking
    ///   - running/jogging 계열 -> .running
    ///   - cycling 계열 -> .cycling
    ///   - swimming 계열 -> .swimming
    ///   - strength training 계열 -> .weight
    ///   - cross training/HIIT 계열 -> .crossfit
    ///   - yoga/pilates 계열 -> .yoga
    ///   - 기타 모든 운동 -> .other
    ///
    /// - Example:
    /// ```swift
    /// let type1 = mapWorkoutActivityType(.running) // .running
    /// let type2 = mapWorkoutActivityType(.cycling) // .cycling
    /// let type3 = mapWorkoutActivityType(.tennis) // .other
    /// ```
    private func mapWorkoutActivityType(_ activityType: HKWorkoutActivityType) -> ExerciseType? {
        // 📚 학습 포인트: Comprehensive Activity Type Mapping
        // HealthKit의 다양한 운동 종류를 앱의 카테고리로 그룹화
        // 💡 Java 비교: switch-case with grouping과 유사
        switch activityType {
        // MARK: Walking
        case .walking,
             .hiking:
            return .walking

        // MARK: Running
        case .running:
            return .running

        // MARK: Cycling
        case .cycling,
             .wheelchairWalkPace,
             .wheelchairRunPace:
            return .cycling

        // MARK: Swimming
        case .swimming,
             .waterFitness,
             .waterPolo,
             .waterSports:
            return .swimming

        // MARK: Weight Training
        case .traditionalStrengthTraining,
             .functionalStrengthTraining,
             .coreTraining:
            return .weight

        // MARK: CrossFit / HIIT
        case .crossTraining,
             .highIntensityIntervalTraining,
             .mixedCardio:
            return .crossfit

        // MARK: Yoga
        case .yoga,
             .pilates,
             .flexibility,
             .mindAndBody,
             .barre,
             .cooldown:
            return .yoga

        // MARK: Other (모든 나머지 운동)
        // 📚 학습 포인트: Catch-All Case
        // HealthKit의 다양한 운동 종류를 .other로 분류
        // 테니스, 축구, 농구, 댄스 등 모든 기타 운동 포함
        // 💡 Java 비교: default case와 유사
        case .americanFootball,
             .archery,
             .australianFootball,
             .badminton,
             .baseball,
             .basketball,
             .bowling,
             .boxing,
             .climbing,
             .cricket,
             .curling,
             .dance,
             .danceInspiredTraining,
             .elliptical,
             .equestrianSports,
             .fencing,
             .fishing,
             .fitnessGaming,
             .golf,
             .gymnastics,
             .handball,
             .hockey,
             .hunting,
             .lacrosse,
             .martialArts,
             .paddleSports,
             .play,
             .preparationAndRecovery,
             .racquetball,
             .rowing,
             .rugby,
             .sailing,
             .skatingSports,
             .snowSports,
             .soccer,
             .softball,
             .squash,
             .stairClimbing,
             .surfingSports,
             .tableTennis,
             .tennis,
             .trackAndField,
             .volleyball,
             .wrestling,
             .other:
            return .other

        // MARK: Future-Proofing
        // 📚 학습 포인트: Unknown Default Case
        // 미래에 추가될 수 있는 새로운 운동 종류 대비
        // 💡 Java 비교: default with logging과 유사
        @unknown default:
            // 알 수 없는 운동 종류는 .other로 분류
            return .other
        }
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

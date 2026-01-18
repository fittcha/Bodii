//
//  HealthKitServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Service Protocols
// HealthKit 서비스의 인터페이스를 정의하여 테스트 가능성 향상
// 💡 Java 비교: Service Interface와 유사하지만 Protocol-Oriented Programming

import Foundation
import HealthKit

// MARK: - HealthKitAuthorizationServiceProtocol

/// HealthKit 권한 관리 서비스 인터페이스
///
/// 📚 학습 포인트: Authorization Service Protocol
/// - HealthKit 권한 요청 및 상태 확인 인터페이스
/// - 테스트 시 Mock으로 대체 가능
/// - Dependency Inversion Principle 구현
/// 💡 Java 비교: PermissionService Interface와 유사
///
/// ## 책임
/// - HealthKit 사용 가능 여부 확인
/// - 읽기/쓰기 권한 요청
/// - 권한 상태 조회
/// - 부분 권한 상태 추적
///
/// - Example:
/// ```swift
/// let service: HealthKitAuthorizationServiceProtocol = HealthKitAuthorizationService()
///
/// guard service.isHealthDataAvailable() else {
///     throw HealthKitError.healthKitNotAvailable
/// }
///
/// try await service.requestAuthorization()
/// if service.isFullyAuthorized {
///     print("All permissions granted")
/// }
/// ```
protocol HealthKitAuthorizationServiceProtocol {

    // MARK: - Availability Check

    /// HealthKit 사용 가능 여부 확인
    ///
    /// - Returns: HealthKit을 사용할 수 있으면 true (iPad는 false)
    func isHealthDataAvailable() -> Bool

    // MARK: - Authorization Request

    /// HealthKit 권한 요청
    ///
    /// 📚 학습 포인트: Permission Request
    /// - 읽기/쓰기 권한을 동시에 요청
    /// - iOS 시스템 다이얼로그 표시
    /// - 사용자가 개별 데이터 타입별로 허용/거부 선택
    ///
    /// - Throws: HealthKitError
    ///   - healthKitNotAvailable: 기기에서 HealthKit 사용 불가
    ///   - authorizationFailed: 권한 요청 과정에서 에러 발생
    func requestAuthorization() async throws

    // MARK: - Authorization Status Check

    /// 특정 데이터 타입에 대한 권한 상태 조회
    ///
    /// - Parameter type: 확인할 HKObjectType
    /// - Returns: HKAuthorizationStatus (notDetermined, sharingDenied, sharingAuthorized)
    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus

    /// 특정 데이터 타입에 대한 권한이 있는지 확인 (Boolean)
    ///
    /// - Parameter type: 확인할 HKObjectType
    /// - Returns: 권한이 허용되었으면 true
    func isAuthorized(for type: HKObjectType) -> Bool

    /// 특정 샘플 타입에 쓰기 권한이 있는지 확인
    ///
    /// - Parameter type: 확인할 HKSampleType
    /// - Returns: 쓰기 권한이 있으면 true
    func canWrite(to type: HKSampleType) -> Bool

    /// 모든 쓰기 타입에 대한 권한이 있는지 확인
    ///
    /// - Returns: 모든 쓰기 권한이 허용되었으면 true
    var isFullyAuthorized: Bool { get }

    // MARK: - Type-Safe Authorization Checks

    /// QuantityType에 대한 권한 확인 (타입 안전)
    ///
    /// - Parameter quantityType: 확인할 QuantityType
    /// - Returns: 권한이 허용되었으면 true
    func isAuthorized(for quantityType: HealthKitDataTypes.QuantityType) -> Bool

    /// CategoryType에 대한 권한 확인 (타입 안전)
    ///
    /// - Parameter categoryType: 확인할 CategoryType
    /// - Returns: 권한이 허용되었으면 true
    func isAuthorized(for categoryType: HealthKitDataTypes.CategoryType) -> Bool

    /// Workout 타입에 대한 권한 확인
    ///
    /// - Returns: 운동 데이터 권한이 허용되었으면 true
    var isAuthorizedForWorkouts: Bool { get }

    /// QuantityType에 대한 쓰기 권한 확인 (타입 안전)
    ///
    /// - Parameter quantityType: 확인할 QuantityType
    /// - Returns: 쓰기 권한이 있으면 true
    func canWrite(to quantityType: HealthKitDataTypes.QuantityType) -> Bool

    /// Workout 타입에 대한 쓰기 권한 확인
    ///
    /// - Returns: 운동 데이터 쓰기 권한이 있으면 true
    var canWriteWorkouts: Bool { get }

    // MARK: - Partial Authorization Handling

    /// 현재 권한 상태 요약 조회
    ///
    /// 📚 학습 포인트: Graceful Partial Authorization
    /// - 부분 권한 허용 상황을 우아하게 처리
    /// - 어떤 권한이 허용/거부되었는지 상세 정보 제공
    ///
    /// - Returns: 권한 상태 요약 정보
    func getAuthorizationSummary() -> HealthKitAuthorizationService.AuthorizationSummary

    // MARK: - HealthStore Access

    /// HKHealthStore 인스턴스 반환
    ///
    /// - Returns: HKHealthStore 인스턴스
    ///
    /// - Note: Read/Write 서비스가 동일한 HKHealthStore 공유
    func getHealthStore() -> HKHealthStore
}

// MARK: - HealthKitReadServiceProtocol

/// HealthKit 데이터 읽기 서비스 인터페이스
///
/// 📚 학습 포인트: Read Service Protocol
/// - HealthKit에서 건강 데이터를 읽어오는 서비스 인터페이스
/// - 테스트 시 Mock 데이터로 대체 가능
/// - Repository Pattern과 유사한 역할
/// 💡 Java 비교: Data Access Object (DAO) Interface와 유사
///
/// ## 책임
/// - HealthKit에서 샘플 데이터 읽기
/// - 날짜 범위 기반 쿼리
/// - 통계 데이터 집계 (일일 합계)
/// - HKQuantitySample, HKCategorySample, HKWorkout 조회
///
/// - Example:
/// ```swift
/// let service: HealthKitReadServiceProtocol = HealthKitReadService(healthStore: healthStore)
///
/// // 최근 체중 조회
/// let weight = try await service.fetchLatestWeight()
///
/// // 일일 활동 칼로리 조회
/// let calories = try await service.fetchActiveCalories(for: Date())
/// ```
protocol HealthKitReadServiceProtocol {

    // MARK: - Generic Query Methods

    /// HealthKit에서 샘플 데이터 조회 (제네릭 메서드)
    ///
    /// - Parameters:
    ///   - type: 조회할 HKSampleType
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - ascending: 정렬 순서 (true: 오래된 것부터, false: 최신 것부터)
    ///   - limit: 최대 결과 개수 (nil이면 전체 조회)
    /// - Returns: 조회된 샘플 배열
    /// - Throws: HealthKitError
    func fetchSamples<T: HKSample>(
        type: HKSampleType,
        from startDate: Date,
        to endDate: Date,
        ascending: Bool,
        limit: Int?
    ) async throws -> [T]

    // MARK: - Date Range Helpers

    /// 특정 기간(일 수)의 시작/종료 날짜 계산
    ///
    /// - Parameters:
    ///   - days: 조회할 일 수 (기본값: 7일)
    ///   - endDate: 종료 날짜 (기본값: 현재 날짜)
    /// - Returns: (시작 날짜, 종료 날짜) 튜플
    func getDateRange(days: Int, endDate: Date) -> (start: Date, end: Date)

    // MARK: - Statistics Query

    /// 통계 데이터 조회 (합계, 평균, 최소/최대)
    ///
    /// - Parameters:
    ///   - quantityType: 집계할 HKQuantityType
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - options: 집계 옵션 (cumulativeSum, discreteAverage 등)
    /// - Returns: HKStatistics 객체
    /// - Throws: HealthKitError
    func fetchStatistics(
        quantityType: HKQuantityType,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics

    // MARK: - Convenience Methods

    /// 최근 N개의 샘플 조회
    ///
    /// - Parameters:
    ///   - type: 조회할 HKSampleType
    ///   - limit: 조회할 개수 (기본값: 10)
    /// - Returns: 최근 샘플 배열
    /// - Throws: HealthKitError
    func fetchRecentSamples<T: HKSample>(
        type: HKSampleType,
        limit: Int
    ) async throws -> [T]

    /// 특정 날짜의 샘플 조회
    ///
    /// - Parameters:
    ///   - type: 조회할 HKSampleType
    ///   - date: 조회할 날짜
    /// - Returns: 해당 날짜의 샘플 배열
    /// - Throws: HealthKitError
    func fetchSamples<T: HKSample>(
        type: HKSampleType,
        for date: Date
    ) async throws -> [T]

    // MARK: - Weight & Body Fat Reading

    /// 체중 데이터 조회 (기간별)
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 체중 샘플 배열 (최신 순)
    /// - Throws: HealthKitError
    func fetchWeight(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample]

    /// 체지방률 데이터 조회 (기간별)
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 체지방률 샘플 배열 (최신 순)
    /// - Throws: HealthKitError
    func fetchBodyFatPercentage(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample]

    /// 최근 체중 조회 (1개)
    ///
    /// - Returns: 최근 체중 샘플 (없으면 nil)
    /// - Throws: HealthKitError
    func fetchLatestWeight() async throws -> HKQuantitySample?

    /// 최근 체지방률 조회 (1개)
    ///
    /// - Returns: 최근 체지방률 샘플 (없으면 nil)
    /// - Throws: HealthKitError
    func fetchLatestBodyFatPercentage() async throws -> HKQuantitySample?

    // MARK: - Active Calories & Steps Reading

    /// 활동 칼로리 조회 (일일 합계)
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 활동 칼로리 합계 (kcal), 데이터 없으면 nil
    /// - Throws: HealthKitError
    func fetchActiveCalories(for date: Date) async throws -> Decimal?

    /// 걸음 수 조회 (일일 합계)
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 걸음 수 합계, 데이터 없으면 nil
    /// - Throws: HealthKitError
    func fetchSteps(for date: Date) async throws -> Decimal?

    // MARK: - Sleep Data Reading

    /// 수면 데이터 조회 (특정 날짜)
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: SleepData 객체 (수면 데이터가 없으면 nil)
    /// - Throws: HealthKitError
    func fetchSleepData(for date: Date) async throws -> HealthKitReadService.SleepData?

    // MARK: - Workout Data Reading

    /// 운동 데이터 조회 (기간별)
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 운동 데이터 배열 (최신 순)
    /// - Throws: HealthKitError
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HealthKitReadService.WorkoutData]

    // MARK: - HKQuantity Conversion Helpers

    /// HKQuantity를 Decimal로 변환 (체중용)
    ///
    /// - Parameter quantity: 변환할 HKQuantity
    /// - Returns: kg 단위의 Decimal 값
    func convertWeightToDecimal(_ quantity: HKQuantity) -> Decimal

    /// HKQuantity를 Decimal로 변환 (체지방률용)
    ///
    /// - Parameter quantity: 변환할 HKQuantity
    /// - Returns: 퍼센트 값의 Decimal (0~100 범위)
    func convertBodyFatPercentageToDecimal(_ quantity: HKQuantity) -> Decimal
}

// MARK: - HealthKitWriteServiceProtocol

/// HealthKit 데이터 쓰기 서비스 인터페이스
///
/// 📚 학습 포인트: Write Service Protocol
/// - HealthKit에 건강 데이터를 저장하는 서비스 인터페이스
/// - 테스트 시 Mock으로 대체 가능
/// - Repository Pattern의 Save/Update/Delete와 유사
/// 💡 Java 비교: Data Access Object (DAO) Write Interface와 유사
///
/// ## 책임
/// - HealthKit에 샘플 데이터 저장
/// - 쓰기 권한 검증
/// - 배치 저장 지원
/// - HKQuantitySample, HKCategorySample, HKWorkout 저장
///
/// - Example:
/// ```swift
/// let service: HealthKitWriteServiceProtocol = HealthKitWriteService(healthStore: healthStore)
///
/// // 체중 저장
/// try await service.saveWeight(kg: 70.5, date: Date())
///
/// // 운동 저장
/// try await service.saveWorkout(
///     exerciseType: .running,
///     duration: 30,
///     caloriesBurned: 350,
///     intensity: .high,
///     startDate: Date()
/// )
/// ```
protocol HealthKitWriteServiceProtocol {

    // MARK: - Generic Save Methods

    /// HealthKit에 샘플 저장 (단일)
    ///
    /// - Parameter sample: 저장할 HKObject
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 데이터 저장 실패
    func save(sample: HKObject) async throws

    /// HealthKit에 샘플 배치 저장
    ///
    /// - Parameter samples: 저장할 HKObject 배열
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 데이터 저장 실패
    func save(samples: [HKObject]) async throws

    // MARK: - Delete Methods

    /// HealthKit에서 샘플 삭제 (단일)
    ///
    /// - Parameter sample: 삭제할 HKObject
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 삭제 권한이 없음
    ///   - writeFailed: 삭제 실패
    func delete(sample: HKObject) async throws

    /// HealthKit에서 샘플 배치 삭제
    ///
    /// - Parameter samples: 삭제할 HKObject 배열
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 삭제 권한이 없음
    ///   - writeFailed: 삭제 실패
    func delete(samples: [HKObject]) async throws

    // MARK: - Authorization Check Helpers

    /// 특정 샘플 타입에 쓰기 권한이 있는지 확인
    ///
    /// - Parameter sampleType: 확인할 HKSampleType
    /// - Returns: 쓰기 권한이 있으면 true
    func canWrite(to sampleType: HKSampleType) -> Bool

    /// QuantityType에 쓰기 권한이 있는지 확인 (타입 안전)
    ///
    /// - Parameter quantityType: 확인할 QuantityType
    /// - Returns: 쓰기 권한이 있으면 true
    func canWrite(to quantityType: HealthKitDataTypes.QuantityType) -> Bool

    /// Workout 타입에 쓰기 권한이 있는지 확인
    ///
    /// - Returns: 운동 데이터 쓰기 권한이 있으면 true
    var canWriteWorkouts: Bool { get }

    // MARK: - Body Composition Write Methods

    /// HealthKit에 체중 데이터 저장
    ///
    /// - Parameters:
    ///   - weight: 체중 (킬로그램 단위)
    ///   - date: 측정 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택)
    /// - Throws: HealthKitError
    func saveWeight(
        kg weight: Decimal,
        date: Date,
        metadata: [String: Any]?
    ) async throws

    /// HealthKit에 체지방률 데이터 저장
    ///
    /// - Parameters:
    ///   - percent: 체지방률 (0-100 범위의 퍼센트)
    ///   - date: 측정 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택)
    /// - Throws: HealthKitError
    func saveBodyFatPercentage(
        percent: Decimal,
        date: Date,
        metadata: [String: Any]?
    ) async throws

    /// HealthKit에 체중과 체지방률을 동시에 저장
    ///
    /// - Parameters:
    ///   - weight: 체중 (킬로그램 단위)
    ///   - bodyFatPercent: 체지방률 (0-100 범위의 퍼센트, 선택)
    ///   - date: 측정 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택)
    /// - Throws: HealthKitError
    func saveBodyComposition(
        kg weight: Decimal,
        percent bodyFatPercent: Decimal?,
        date: Date,
        metadata: [String: Any]?
    ) async throws

    // MARK: - Workout Write Methods

    /// HealthKit에 운동 데이터 저장
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류 (ExerciseType enum)
    ///   - duration: 운동 시간 (분 단위)
    ///   - caloriesBurned: 소모 칼로리 (kcal)
    ///   - intensity: 운동 강도 (저/중/고)
    ///   - startDate: 운동 시작 일시
    ///   - metadata: 추가 메타데이터 (선택)
    /// - Throws: HealthKitError
    func saveWorkout(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        intensity: Intensity,
        startDate: Date,
        metadata: [String: Any]?
    ) async throws

    // MARK: - Dietary Energy Write Methods

    /// HealthKit에 섭취 칼로리 데이터 저장
    ///
    /// - Parameters:
    ///   - calories: 섭취 칼로리 (kcal 단위)
    ///   - date: 식사 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택, 예: 식사 종류)
    /// - Throws: HealthKitError
    func saveDietaryEnergy(
        calories: Decimal,
        date: Date,
        metadata: [String: Any]?
    ) async throws

    /// HealthKit에 여러 식사의 섭취 칼로리를 배치 저장
    ///
    /// - Parameter meals: 식사 정보 배열 (칼로리, 시간, 메타데이터)
    /// - Throws: HealthKitError
    func saveDietaryEnergyBatch(
        meals: [(calories: Decimal, date: Date, metadata: [String: Any]?)]
    ) async throws

    // MARK: - Metadata Helper

    /// Bodii 앱에서 생성한 샘플임을 표시하는 메타데이터 생성
    ///
    /// - Parameters:
    ///   - source: 데이터 출처 (예: "manual_entry", "sync", "import")
    ///   - additionalMetadata: 추가 메타데이터 (선택)
    /// - Returns: 메타데이터 딕셔너리
    func createMetadata(
        source: String,
        additionalMetadata: [String: Any]?
    ) -> [String: Any]
}

// MARK: - HealthKitSyncServiceProtocol

/// HealthKit 동기화 서비스 인터페이스
///
/// 📚 학습 포인트: Sync Service Protocol
/// - HealthKit과 Bodii 데이터를 양방향 동기화하는 서비스 인터페이스
/// - 테스트 시 Mock으로 대체 가능
/// - Service Layer의 조정자 역할
/// 💡 Java 비교: SyncService Interface와 유사
///
/// ## 책임
/// - HealthKit → Bodii 동기화 (읽기)
/// - Bodii → HealthKit 동기화 (쓰기)
/// - 마지막 동기화 시각 추적
/// - 증분 동기화 (변경된 데이터만 동기화)
/// - 동기화 상태 관리
///
/// - Example:
/// ```swift
/// let service: HealthKitSyncServiceProtocol = HealthKitSyncService(
///     readService: readService,
///     writeService: writeService,
///     authService: authService
/// )
///
/// // 전체 동기화
/// try await service.sync(userId: userId)
///
/// // 증분 동기화
/// try await service.syncSince(date: lastSyncDate, userId: userId)
/// ```
protocol HealthKitSyncServiceProtocol {

    // MARK: - Public Sync Methods

    /// 전체 동기화 (기본 7일)
    ///
    /// 📚 학습 포인트: Full Sync
    /// - 기본적으로 최근 7일 데이터를 동기화
    /// - HealthKit → Bodii 읽기 동기화만 수행
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - days: 동기화할 일 수 (기본값: 7일)
    /// - Throws: HealthKitError
    func sync(userId: UUID, days: Int) async throws

    /// 증분 동기화 (특정 날짜 이후)
    ///
    /// 📚 학습 포인트: Incremental Sync
    /// - 특정 날짜 이후에 변경된 데이터만 동기화
    /// - 네트워크/배터리 효율적
    ///
    /// - Parameters:
    ///   - date: 시작 날짜 (이 날짜 이후 데이터만 동기화)
    ///   - userId: 사용자 ID
    /// - Throws: HealthKitError
    func syncSince(date: Date, userId: UUID) async throws

    // MARK: - Last Sync Date Management

    /// 마지막 동기화 시각 조회
    ///
    /// - Returns: 마지막 동기화 시각 (없으면 nil)
    func getLastSyncDate() -> Date?

    /// 마지막 동기화 시각 초기화
    func clearLastSyncDate()

    // MARK: - Public Export Methods (Bodii → HealthKit)

    /// 체중 데이터를 HealthKit에 저장
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%, Optional)
    ///   - date: 측정 날짜 (기본값: 현재 시각)
    /// - Throws: HealthKitError
    func exportBodyComposition(
        weight: Decimal,
        bodyFatPercent: Decimal?,
        date: Date
    ) async throws

    /// 운동 기록을 HealthKit에 저장
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - caloriesBurned: 소모 칼로리 (kcal)
    ///   - intensity: 운동 강도
    ///   - startDate: 운동 시작 시각 (기본값: 현재 시각)
    /// - Throws: HealthKitError
    func exportWorkout(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        intensity: Intensity,
        startDate: Date
    ) async throws

    /// 섭취 칼로리를 HealthKit에 저장
    ///
    /// - Parameters:
    ///   - calories: 섭취 칼로리 (kcal)
    ///   - date: 식사 시각 (기본값: 현재 시각)
    ///   - mealType: 식사 타입 (Optional)
    /// - Throws: HealthKitError
    func exportDietaryEnergy(
        calories: Decimal,
        date: Date,
        mealType: String?
    ) async throws
}

// MARK: - Documentation

/// 📚 학습 포인트: Protocol-Oriented Programming
///
/// ## HealthKit Service Protocols이란?
///
/// HealthKit 서비스의 인터페이스를 Protocol로 정의하여 테스트 가능성과 유연성을 향상시킵니다.
///
/// ### 장점
///
/// 1. **테스트 용이성**:
///    - Mock 구현체로 쉽게 테스트 가능
///    - 실제 HealthKit 없이 단위 테스트 가능
///    - 다양한 시나리오 테스트 (권한 거부, 데이터 없음 등)
///
/// 2. **의존성 역전**:
///    - ViewModel이 구체적인 구현에 의존하지 않음
///    - Protocol에만 의존하여 결합도 낮춤
///    - Dependency Inversion Principle 구현
///
/// 3. **유연성**:
///    - 구현체를 쉽게 교체 가능
///    - 여러 구현체 제공 가능 (Real, Mock, Fake)
///    - 플랫폼별 구현체 분리 가능
///
/// 4. **관심사 분리**:
///    - 인터페이스와 구현의 명확한 분리
///    - 각 서비스의 책임 명확화
///    - Clean Architecture 구현
///
/// ### 사용 예시
///
/// ```swift
/// // MARK: - Production Code
/// class HealthKitSettingsViewModel: ObservableObject {
///     private let authService: HealthKitAuthorizationServiceProtocol
///     private let syncService: HealthKitSyncServiceProtocol
///
///     init(
///         authService: HealthKitAuthorizationServiceProtocol,
///         syncService: HealthKitSyncServiceProtocol
///     ) {
///         self.authService = authService
///         self.syncService = syncService
///     }
///
///     func requestAuthorization() async {
///         do {
///             try await authService.requestAuthorization()
///             try await syncService.sync(userId: currentUserId)
///         } catch {
///             // Handle error
///         }
///     }
/// }
///
/// // MARK: - Test Code
/// class MockHealthKitAuthorizationService: HealthKitAuthorizationServiceProtocol {
///     var shouldGrantPermission = true
///     var requestAuthorizationCalled = false
///
///     func requestAuthorization() async throws {
///         requestAuthorizationCalled = true
///         if !shouldGrantPermission {
///             throw HealthKitError.authorizationDenied
///         }
///     }
///
///     // Implement other protocol methods...
/// }
///
/// class HealthKitSettingsViewModelTests: XCTestCase {
///     func testRequestAuthorization_Success() async {
///         // Given
///         let mockAuthService = MockHealthKitAuthorizationService()
///         let mockSyncService = MockHealthKitSyncService()
///         let viewModel = HealthKitSettingsViewModel(
///             authService: mockAuthService,
///             syncService: mockSyncService
///         )
///
///         // When
///         await viewModel.requestAuthorization()
///
///         // Then
///         XCTAssertTrue(mockAuthService.requestAuthorizationCalled)
///         XCTAssertTrue(mockSyncService.syncCalled)
///     }
/// }
/// ```
///
/// ### 💡 Java Spring과의 비교
///
/// - **Java Spring**: @Service 인터페이스 + 구현 클래스
///   ```java
///   public interface HealthKitSyncService {
///       void sync(UUID userId) throws HealthKitException;
///   }
///
///   @Service
///   public class HealthKitSyncServiceImpl implements HealthKitSyncService {
///       @Override
///       public void sync(UUID userId) {
///           // Implementation
///       }
///   }
///   ```
///
/// - **Swift Protocol**: Protocol + 구체 클래스
///   ```swift
///   protocol HealthKitSyncServiceProtocol {
///       func sync(userId: UUID) async throws
///   }
///
///   final class HealthKitSyncService: HealthKitSyncServiceProtocol {
///       func sync(userId: UUID) async throws {
///           // Implementation
///       }
///   }
///   ```
///
/// ### Clean Architecture에서의 위치
///
/// - **Protocols**: Domain Layer (Interfaces)
/// - **Implementations**: Infrastructure Layer (HealthKit)
/// - **Usage**: Presentation Layer (ViewModels)
///
/// ```
/// ┌─────────────────────────────────────────┐
/// │     Presentation Layer                  │
/// │  (ViewModels use Protocols)             │
/// └─────────────────────────────────────────┘
///          │ depends on
///          ▼
/// ┌─────────────────────────────────────────┐
/// │     Domain Layer                        │
/// │  (Protocols defined here)               │
/// └─────────────────────────────────────────┘
///          ▲ implemented by
///          │
/// ┌─────────────────────────────────────────┐
/// │     Infrastructure Layer                │
/// │  (Concrete implementations)             │
/// └─────────────────────────────────────────┘
/// ```

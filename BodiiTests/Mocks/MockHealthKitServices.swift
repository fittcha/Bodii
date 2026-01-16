//
//  MockHealthKitServices.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Mock HealthKit Services for Testing
// 실제 HealthKit 없이 테스트할 수 있는 Mock 서비스들
// 💡 Java 비교: Mockito의 @Mock과 유사하지만 Protocol 기반 구현

import Foundation
import HealthKit
@testable import Bodii

// MARK: - MockHealthKitAuthorizationService

/// 테스트용 Mock HealthKit Authorization Service
///
/// 📚 학습 포인트: Authorization Mock
/// - 실제 iOS 권한 다이얼로그 없이 권한 상태 시뮬레이션
/// - 다양한 권한 시나리오 테스트 (전체 허용, 부분 허용, 전체 거부)
/// - iPad 등 HealthKit 미지원 기기 시뮬레이션
/// 💡 Java 비교: Mockito.when(authService.requestAuthorization()).thenReturn()
///
/// **사용 예시:**
/// ```swift
/// let mockAuth = MockHealthKitAuthorizationService()
///
/// // Success 시나리오
/// mockAuth.isHealthKitAvailable = true
/// mockAuth.authorizationGranted = true
/// try await mockAuth.requestAuthorization()
///
/// // Failure 시나리오
/// mockAuth.authorizationGranted = false
/// mockAuth.shouldThrowError = HealthKitError.authorizationDenied
/// ```
final class MockHealthKitAuthorizationService: HealthKitAuthorizationServiceProtocol {

    // MARK: - Mock Configuration

    /// HealthKit 사용 가능 여부 (기본값: true)
    ///
    /// 📚 학습 포인트: Device Compatibility
    /// - iPhone: true
    /// - iPad: false
    var isHealthKitAvailable: Bool = true

    /// 권한 허용 여부 (기본값: true)
    ///
    /// requestAuthorization() 호출 시 권한이 허용되는지 여부
    var authorizationGranted: Bool = true

    /// 부분 권한 허용 설정
    ///
    /// 📚 학습 포인트: Partial Authorization
    /// - 특정 데이터 타입만 허용하고 나머지는 거부
    /// - 예: 체중은 허용하지만 수면 데이터는 거부
    var authorizedQuantityTypes: Set<HealthKitDataTypes.QuantityType> = []

    var authorizedCategoryTypes: Set<HealthKitDataTypes.CategoryType> = []

    var isWorkoutAuthorized: Bool = false

    /// 에러 시뮬레이션
    ///
    /// nil이 아닌 경우 항상 해당 에러를 throw
    var shouldThrowError: Error?

    // MARK: - Call Tracking

    /// 호출 횟수 추적: requestAuthorization()
    var requestAuthorizationCallCount = 0

    /// 호출 횟수 추적: getAuthorizationStatus()
    var getAuthorizationStatusCallCount = 0

    /// 호출 횟수 추적: isAuthorized()
    var isAuthorizedCallCount = 0

    /// 호출 횟수 추적: canWrite()
    var canWriteCallCount = 0

    // MARK: - Availability Check

    func isHealthDataAvailable() -> Bool {
        return isHealthKitAvailable
    }

    // MARK: - Authorization Request

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !isHealthKitAvailable {
            throw HealthKitError.healthKitNotAvailable
        }

        if !authorizationGranted {
            throw HealthKitError.authorizationDenied
        }

        // 권한 허용 시 기본적으로 모든 타입 허용
        if authorizationGranted && authorizedQuantityTypes.isEmpty {
            authorizedQuantityTypes = [.weight, .bodyFatPercentage, .activeEnergyBurned, .stepCount, .dietaryEnergyConsumed]
            authorizedCategoryTypes = [.sleepAnalysis]
            isWorkoutAuthorized = true
        }
    }

    // MARK: - Authorization Status Check

    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        getAuthorizationStatusCallCount += 1

        if !authorizationGranted {
            return .sharingDenied
        }

        return .sharingAuthorized
    }

    func isAuthorized(for type: HKObjectType) -> Bool {
        isAuthorizedCallCount += 1
        return getAuthorizationStatus(for: type) == .sharingAuthorized
    }

    func canWrite(to type: HKSampleType) -> Bool {
        canWriteCallCount += 1
        return authorizationGranted
    }

    var isFullyAuthorized: Bool {
        return authorizationGranted &&
               authorizedQuantityTypes.count == 5 &&
               authorizedCategoryTypes.count == 1 &&
               isWorkoutAuthorized
    }

    // MARK: - Type-Safe Authorization Checks

    func isAuthorized(for quantityType: HealthKitDataTypes.QuantityType) -> Bool {
        isAuthorizedCallCount += 1
        return authorizedQuantityTypes.contains(quantityType)
    }

    func isAuthorized(for categoryType: HealthKitDataTypes.CategoryType) -> Bool {
        isAuthorizedCallCount += 1
        return authorizedCategoryTypes.contains(categoryType)
    }

    var isAuthorizedForWorkouts: Bool {
        return isWorkoutAuthorized
    }

    func canWrite(to quantityType: HealthKitDataTypes.QuantityType) -> Bool {
        canWriteCallCount += 1
        return authorizedQuantityTypes.contains(quantityType)
    }

    var canWriteWorkouts: Bool {
        return isWorkoutAuthorized
    }

    // MARK: - Partial Authorization Handling

    func getAuthorizationSummary() -> HealthKitAuthorizationService.AuthorizationSummary {
        let totalRequested = 7 // 5 quantity + 1 category + 1 workout
        let authorized = authorizedQuantityTypes.count + authorizedCategoryTypes.count + (isWorkoutAuthorized ? 1 : 0)

        return HealthKitAuthorizationService.AuthorizationSummary(
            totalRequested: totalRequested,
            authorized: authorized,
            denied: totalRequested - authorized,
            notDetermined: 0,
            authorizedTypes: [],
            deniedTypes: []
        )
    }

    // MARK: - HealthStore Access

    func getHealthStore() -> HKHealthStore {
        return HKHealthStore()
    }

    // MARK: - Test Helpers

    /// Mock 상태 초기화
    ///
    /// 📚 학습 포인트: Test Setup/Teardown
    /// 각 테스트 전후에 호출하여 Mock 상태를 깨끗하게 유지
    func reset() {
        isHealthKitAvailable = true
        authorizationGranted = true
        authorizedQuantityTypes = []
        authorizedCategoryTypes = []
        isWorkoutAuthorized = false
        shouldThrowError = nil
        requestAuthorizationCallCount = 0
        getAuthorizationStatusCallCount = 0
        isAuthorizedCallCount = 0
        canWriteCallCount = 0
    }

    /// 전체 권한 허용 설정 (테스트 헬퍼)
    func grantAllPermissions() {
        authorizationGranted = true
        authorizedQuantityTypes = [.weight, .bodyFatPercentage, .activeEnergyBurned, .stepCount, .dietaryEnergyConsumed]
        authorizedCategoryTypes = [.sleepAnalysis]
        isWorkoutAuthorized = true
    }

    /// 전체 권한 거부 설정 (테스트 헬퍼)
    func denyAllPermissions() {
        authorizationGranted = false
        authorizedQuantityTypes = []
        authorizedCategoryTypes = []
        isWorkoutAuthorized = false
    }
}

// MARK: - MockHealthKitReadService

/// 테스트용 Mock HealthKit Read Service
///
/// 📚 학습 포인트: Read Service Mock
/// - 실제 HealthKit 데이터 없이 샘플 데이터 반환
/// - 다양한 데이터 시나리오 테스트 (데이터 있음, 없음, 에러)
/// - 날짜 범위 쿼리 검증
/// 💡 Java 비교: Repository Mock과 유사
///
/// **사용 예시:**
/// ```swift
/// let mockRead = MockHealthKitReadService()
///
/// // 샘플 체중 데이터 설정
/// mockRead.mockWeightSamples = [
///     MockHealthKitReadService.createWeightSample(kg: 70.5, date: Date())
/// ]
///
/// let weight = try await mockRead.fetchLatestWeight()
/// XCTAssertEqual(weight?.quantity.doubleValue(for: .kilogram()), 70.5)
/// ```
final class MockHealthKitReadService: HealthKitReadServiceProtocol {

    // MARK: - Mock Configuration

    /// Mock 체중 샘플 데이터
    var mockWeightSamples: [HKQuantitySample] = []

    /// Mock 체지방률 샘플 데이터
    var mockBodyFatSamples: [HKQuantitySample] = []

    /// Mock 활동 칼로리 (일일 합계)
    var mockActiveCalories: Decimal?

    /// Mock 걸음 수 (일일 합계)
    var mockSteps: Decimal?

    /// Mock 수면 데이터
    var mockSleepData: HealthKitReadService.SleepData?

    /// Mock 운동 데이터
    var mockWorkouts: [HealthKitReadService.WorkoutData] = []

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    // MARK: - Call Tracking

    var fetchSamplesCallCount = 0
    var fetchWeightCallCount = 0
    var fetchBodyFatCallCount = 0
    var fetchActiveCaloriesCallCount = 0
    var fetchStepsCallCount = 0
    var fetchSleepDataCallCount = 0
    var fetchWorkoutsCallCount = 0

    // MARK: - Generic Query Methods

    func fetchSamples<T: HKSample>(
        type: HKSampleType,
        from startDate: Date,
        to endDate: Date,
        ascending: Bool,
        limit: Int?
    ) async throws -> [T] {
        fetchSamplesCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        // 타입에 따라 적절한 mock 데이터 반환
        if type == HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            return mockWeightSamples as? [T] ?? []
        } else if type == HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            return mockBodyFatSamples as? [T] ?? []
        }

        return []
    }

    // MARK: - Date Range Helpers

    func getDateRange(days: Int, endDate: Date) -> (start: Date, end: Date) {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return (start, endDate)
    }

    // MARK: - Statistics Query

    func fetchStatistics(
        quantityType: HKQuantityType,
        from startDate: Date,
        to endDate: Date,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics {
        if let error = shouldThrowError {
            throw error
        }

        // HKStatistics는 생성 불가하므로 에러 던지기
        throw HealthKitError.statisticsUnavailable
    }

    // MARK: - Convenience Methods

    func fetchRecentSamples<T: HKSample>(
        type: HKSampleType,
        limit: Int
    ) async throws -> [T] {
        return try await fetchSamples(
            type: type,
            from: Date.distantPast,
            to: Date(),
            ascending: false,
            limit: limit
        )
    }

    func fetchSamples<T: HKSample>(
        type: HKSampleType,
        for date: Date
    ) async throws -> [T] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchSamples(
            type: type,
            from: startOfDay,
            to: endOfDay,
            ascending: false,
            limit: nil
        )
    }

    // MARK: - Weight & Body Fat Reading

    func fetchWeight(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        fetchWeightCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockWeightSamples
    }

    func fetchBodyFatPercentage(from startDate: Date, to endDate: Date) async throws -> [HKQuantitySample] {
        fetchBodyFatCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockBodyFatSamples
    }

    func fetchLatestWeight() async throws -> HKQuantitySample? {
        fetchWeightCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockWeightSamples.first
    }

    func fetchLatestBodyFatPercentage() async throws -> HKQuantitySample? {
        fetchBodyFatCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockBodyFatSamples.first
    }

    // MARK: - Active Calories & Steps Reading

    func fetchActiveCalories(for date: Date) async throws -> Decimal? {
        fetchActiveCaloriesCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockActiveCalories
    }

    func fetchSteps(for date: Date) async throws -> Decimal? {
        fetchStepsCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockSteps
    }

    // MARK: - Sleep Data Reading

    func fetchSleepData(for date: Date) async throws -> HealthKitReadService.SleepData? {
        fetchSleepDataCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockSleepData
    }

    // MARK: - Workout Data Reading

    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HealthKitReadService.WorkoutData] {
        fetchWorkoutsCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return mockWorkouts
    }

    // MARK: - HKQuantity Conversion Helpers

    func convertWeightToDecimal(_ quantity: HKQuantity) -> Decimal {
        return Decimal(quantity.doubleValue(for: .gramUnit(with: .kilo)))
    }

    func convertBodyFatPercentageToDecimal(_ quantity: HKQuantity) -> Decimal {
        return Decimal(quantity.doubleValue(for: .percent()) * 100.0)
    }

    // MARK: - Test Helpers

    /// Mock 상태 초기화
    func reset() {
        mockWeightSamples = []
        mockBodyFatSamples = []
        mockActiveCalories = nil
        mockSteps = nil
        mockSleepData = nil
        mockWorkouts = []
        shouldThrowError = nil
        fetchSamplesCallCount = 0
        fetchWeightCallCount = 0
        fetchBodyFatCallCount = 0
        fetchActiveCaloriesCallCount = 0
        fetchStepsCallCount = 0
        fetchSleepDataCallCount = 0
        fetchWorkoutsCallCount = 0
    }

    /// 샘플 체중 데이터 생성 (테스트 헬퍼)
    ///
    /// 📚 학습 포인트: Test Data Builder
    /// 테스트용 HKQuantitySample 생성
    static func createWeightSample(kg: Double, date: Date = Date()) -> HKQuantitySample {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)

        return HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: date,
            end: date
        )
    }

    /// 샘플 체지방률 데이터 생성 (테스트 헬퍼)
    static func createBodyFatSample(percent: Double, date: Date = Date()) -> HKQuantitySample {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let quantity = HKQuantity(unit: .percent(), doubleValue: percent / 100.0)

        return HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: date,
            end: date
        )
    }
}

// MARK: - MockHealthKitWriteService

/// 테스트용 Mock HealthKit Write Service
///
/// 📚 학습 포인트: Write Service Mock
/// - 실제 HealthKit 쓰기 없이 저장 동작 검증
/// - 저장된 데이터 추적 및 검증
/// - 권한 검증 시뮬레이션
/// 💡 Java 비교: Repository Save Mock과 유사
///
/// **사용 예시:**
/// ```swift
/// let mockWrite = MockHealthKitWriteService()
///
/// // 체중 저장
/// try await mockWrite.saveWeight(kg: 70.5, date: Date(), metadata: nil)
///
/// // 저장 검증
/// XCTAssertEqual(mockWrite.saveWeightCallCount, 1)
/// XCTAssertEqual(mockWrite.savedSamples.count, 1)
/// ```
final class MockHealthKitWriteService: HealthKitWriteServiceProtocol {

    // MARK: - Mock Configuration

    /// 저장된 샘플 추적
    ///
    /// 📚 학습 포인트: Save Tracking
    /// 테스트에서 어떤 데이터가 저장되었는지 검증
    var savedSamples: [HKObject] = []

    /// 삭제된 샘플 추적
    var deletedSamples: [HKObject] = []

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 권한 허용 여부
    var hasWritePermission: Bool = true

    // MARK: - Call Tracking

    var saveCallCount = 0
    var saveBatchCallCount = 0
    var deleteCallCount = 0
    var deleteBatchCallCount = 0
    var saveWeightCallCount = 0
    var saveBodyFatCallCount = 0
    var saveWorkoutCallCount = 0
    var saveDietaryEnergyCallCount = 0

    // MARK: - Generic Save Methods

    func save(sample: HKObject) async throws {
        saveCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "Sample")
        }

        savedSamples.append(sample)
    }

    func save(samples: [HKObject]) async throws {
        saveBatchCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "Samples")
        }

        savedSamples.append(contentsOf: samples)
    }

    // MARK: - Delete Methods

    func delete(sample: HKObject) async throws {
        deleteCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "Sample")
        }

        deletedSamples.append(sample)
    }

    func delete(samples: [HKObject]) async throws {
        deleteBatchCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "Samples")
        }

        deletedSamples.append(contentsOf: samples)
    }

    // MARK: - Authorization Check Helpers

    func canWrite(to sampleType: HKSampleType) -> Bool {
        return hasWritePermission
    }

    func canWrite(to quantityType: HealthKitDataTypes.QuantityType) -> Bool {
        return hasWritePermission
    }

    var canWriteWorkouts: Bool {
        return hasWritePermission
    }

    // MARK: - Body Composition Write Methods

    func saveWeight(
        kg weight: Decimal,
        date: Date,
        metadata: [String: Any]?
    ) async throws {
        saveWeightCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "Weight")
        }

        // 샘플 생성 (간단한 추적용)
        let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: Double(truncating: weight as NSNumber))
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date, metadata: metadata)

        savedSamples.append(sample)
    }

    func saveBodyFatPercentage(
        percent: Decimal,
        date: Date,
        metadata: [String: Any]?
    ) async throws {
        saveBodyFatCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "BodyFat")
        }

        let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let quantity = HKQuantity(unit: .percent(), doubleValue: Double(truncating: percent as NSNumber) / 100.0)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date, metadata: metadata)

        savedSamples.append(sample)
    }

    func saveBodyComposition(
        kg weight: Decimal,
        percent bodyFatPercent: Decimal?,
        date: Date,
        metadata: [String: Any]?
    ) async throws {
        try await saveWeight(kg: weight, date: date, metadata: metadata)

        if let bodyFat = bodyFatPercent {
            try await saveBodyFatPercentage(percent: bodyFat, date: date, metadata: metadata)
        }
    }

    // MARK: - Workout Write Methods

    func saveWorkout(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        intensity: Intensity,
        startDate: Date,
        metadata: [String: Any]?
    ) async throws {
        saveWorkoutCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "Workout")
        }

        // 간단한 추적용 (실제 HKWorkout 생성은 복잡하므로 생략)
        // 테스트에서는 saveWorkoutCallCount로 검증
    }

    // MARK: - Dietary Energy Write Methods

    func saveDietaryEnergy(
        calories: Decimal,
        date: Date,
        metadata: [String: Any]?
    ) async throws {
        saveDietaryEnergyCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        if !hasWritePermission {
            throw HealthKitError.dataTypeNotAuthorized(typeName: "DietaryEnergy")
        }

        let quantityType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(truncating: calories as NSNumber))
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date, metadata: metadata)

        savedSamples.append(sample)
    }

    func saveDietaryEnergyBatch(
        meals: [(calories: Decimal, date: Date, metadata: [String: Any]?)]
    ) async throws {
        for meal in meals {
            try await saveDietaryEnergy(calories: meal.calories, date: meal.date, metadata: meal.metadata)
        }
    }

    // MARK: - Metadata Helper

    func createMetadata(
        source: String,
        additionalMetadata: [String: Any]?
    ) -> [String: Any] {
        var metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: "com.bodii.app",
            HKMetadataKeySyncVersion: 1,
            "BodiiSource": source
        ]

        if let additional = additionalMetadata {
            metadata.merge(additional) { _, new in new }
        }

        return metadata
    }

    // MARK: - Test Helpers

    /// Mock 상태 초기화
    func reset() {
        savedSamples = []
        deletedSamples = []
        shouldThrowError = nil
        hasWritePermission = true
        saveCallCount = 0
        saveBatchCallCount = 0
        deleteCallCount = 0
        deleteBatchCallCount = 0
        saveWeightCallCount = 0
        saveBodyFatCallCount = 0
        saveWorkoutCallCount = 0
        saveDietaryEnergyCallCount = 0
    }
}

// MARK: - MockHealthKitSyncService

/// 테스트용 Mock HealthKit Sync Service
///
/// 📚 학습 포인트: Sync Service Mock
/// - 실제 동기화 없이 동기화 로직 검증
/// - 동기화 호출 추적
/// - 마지막 동기화 시각 관리
/// 💡 Java 비교: SyncService Mock과 유사
///
/// **사용 예시:**
/// ```swift
/// let mockSync = MockHealthKitSyncService()
///
/// // 동기화 실행
/// try await mockSync.sync(userId: userId)
///
/// // 동기화 검증
/// XCTAssertEqual(mockSync.syncCallCount, 1)
/// XCTAssertNotNil(mockSync.lastSyncDate)
/// ```
final class MockHealthKitSyncService: HealthKitSyncServiceProtocol {

    // MARK: - Mock Configuration

    /// 마지막 동기화 시각
    var lastSyncDate: Date?

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 동기화 성공 여부
    var syncSuccessful: Bool = true

    // MARK: - Call Tracking

    var syncCallCount = 0
    var syncSinceCallCount = 0
    var exportBodyCompositionCallCount = 0
    var exportWorkoutCallCount = 0
    var exportDietaryEnergyCallCount = 0

    /// 마지막 동기화에 사용된 userId
    var lastUserId: UUID?

    /// 마지막 동기화에 사용된 days
    var lastSyncDays: Int?

    /// 마지막 동기화 시작 날짜
    var lastSyncSinceDate: Date?

    // MARK: - Public Sync Methods

    func sync(userId: UUID, days: Int = 7) async throws {
        syncCallCount += 1
        lastUserId = userId
        lastSyncDays = days

        if let error = shouldThrowError {
            throw error
        }

        if syncSuccessful {
            lastSyncDate = Date()
        }
    }

    func syncSince(date: Date, userId: UUID) async throws {
        syncSinceCallCount += 1
        lastUserId = userId
        lastSyncSinceDate = date

        if let error = shouldThrowError {
            throw error
        }

        if syncSuccessful {
            lastSyncDate = Date()
        }
    }

    // MARK: - Last Sync Date Management

    func getLastSyncDate() -> Date? {
        return lastSyncDate
    }

    func clearLastSyncDate() {
        lastSyncDate = nil
    }

    // MARK: - Public Export Methods (Bodii → HealthKit)

    func exportBodyComposition(
        weight: Decimal,
        bodyFatPercent: Decimal?,
        date: Date
    ) async throws {
        exportBodyCompositionCallCount += 1

        if let error = shouldThrowError {
            throw error
        }
    }

    func exportWorkout(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        intensity: Intensity,
        startDate: Date
    ) async throws {
        exportWorkoutCallCount += 1

        if let error = shouldThrowError {
            throw error
        }
    }

    func exportDietaryEnergy(
        calories: Decimal,
        date: Date,
        mealType: String?
    ) async throws {
        exportDietaryEnergyCallCount += 1

        if let error = shouldThrowError {
            throw error
        }
    }

    // MARK: - Test Helpers

    /// Mock 상태 초기화
    func reset() {
        lastSyncDate = nil
        shouldThrowError = nil
        syncSuccessful = true
        syncCallCount = 0
        syncSinceCallCount = 0
        exportBodyCompositionCallCount = 0
        exportWorkoutCallCount = 0
        exportDietaryEnergyCallCount = 0
        lastUserId = nil
        lastSyncDays = nil
        lastSyncSinceDate = nil
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Mock Services for Unit Testing
///
/// ## Mock HealthKit Services란?
///
/// 실제 HealthKit 없이 단위 테스트를 실행할 수 있도록 하는 Mock 구현체들입니다.
///
/// ### 장점
///
/// 1. **테스트 속도**:
///    - 실제 HealthKit API 호출 없이 빠른 테스트
///    - CI/CD 파이프라인에서 실행 가능
///
/// 2. **테스트 가능성**:
///    - 다양한 시나리오 시뮬레이션 (성공, 실패, 권한 거부)
///    - 엣지 케이스 테스트 (데이터 없음, 부분 권한 등)
///
/// 3. **격리성**:
///    - iOS 시뮬레이터 HealthKit 데이터와 독립적
///    - 각 테스트가 서로 영향을 주지 않음
///
/// 4. **검증 가능성**:
///    - 메서드 호출 횟수 추적
///    - 전달된 파라미터 검증
///    - 저장된 데이터 검증
///
/// ### 사용 예시
///
/// ```swift
/// class HealthKitSyncTests: XCTestCase {
///     var mockAuth: MockHealthKitAuthorizationService!
///     var mockRead: MockHealthKitReadService!
///     var mockWrite: MockHealthKitWriteService!
///     var mockSync: MockHealthKitSyncService!
///
///     override func setUp() {
///         super.setUp()
///         mockAuth = MockHealthKitAuthorizationService()
///         mockRead = MockHealthKitReadService()
///         mockWrite = MockHealthKitWriteService()
///         mockSync = MockHealthKitSyncService()
///     }
///
///     override func tearDown() {
///         mockAuth.reset()
///         mockRead.reset()
///         mockWrite.reset()
///         mockSync.reset()
///         super.tearDown()
///     }
///
///     func testSync_Success() async throws {
///         // Given
///         mockAuth.grantAllPermissions()
///         mockRead.mockWeightSamples = [
///             MockHealthKitReadService.createWeightSample(kg: 70.5)
///         ]
///
///         // When
///         try await mockSync.sync(userId: UUID())
///
///         // Then
///         XCTAssertEqual(mockSync.syncCallCount, 1)
///         XCTAssertNotNil(mockSync.lastSyncDate)
///     }
///
///     func testSync_AuthorizationDenied() async {
///         // Given
///         mockAuth.denyAllPermissions()
///         mockSync.shouldThrowError = HealthKitError.authorizationDenied
///
///         // When/Then
///         do {
///             try await mockSync.sync(userId: UUID())
///             XCTFail("Expected error")
///         } catch let error as HealthKitError {
///             XCTAssertEqual(error, .authorizationDenied)
///         }
///     }
/// }
/// ```
///
/// ### 💡 Java Spring과의 비교
///
/// - **Java Spring**: Mockito의 @Mock 어노테이션
///   ```java
///   @Mock
///   private HealthKitSyncService syncService;
///
///   @Test
///   public void testSync_Success() throws Exception {
///       when(syncService.sync(any(UUID.class))).thenReturn(true);
///       // Test logic
///       verify(syncService, times(1)).sync(any(UUID.class));
///   }
///   ```
///
/// - **Swift Protocol**: Protocol 기반 Mock 구현
///   ```swift
///   let mockSync = MockHealthKitSyncService()
///   mockSync.syncSuccessful = true
///   try await mockSync.sync(userId: userId)
///   XCTAssertEqual(mockSync.syncCallCount, 1)
///   ```
///
/// ### 모범 사례
///
/// 1. **setUp/tearDown 사용**: 각 테스트 전후 Mock 초기화
/// 2. **Call Tracking**: 메서드 호출 횟수와 파라미터 검증
/// 3. **Error Simulation**: 다양한 에러 시나리오 테스트
/// 4. **Test Helpers**: 샘플 데이터 생성 헬퍼 메서드 제공
/// 5. **Configurable Mock**: 테스트마다 다른 동작 설정 가능
///

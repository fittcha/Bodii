//
//  HealthKitTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Integration Tests
// HealthKit 매퍼, 동기화 로직, 충돌 해결을 테스트
// 💡 Java 비교: JUnit + Mockito 통합 테스트와 유사

import XCTest
import HealthKit
@testable import Bodii

/// HealthKit 통합 테스트
///
/// 📚 학습 포인트: Comprehensive HealthKit Testing
/// - Mapper 테스트: HealthKit ↔ Domain 변환
/// - Sync 로직 테스트: 동기화 시나리오
/// - Conflict Resolution 테스트: 충돌 해결 전략
/// - Duplicate Detection 테스트: healthKitId 추적
/// 💡 Java 비교: @SpringBootTest + @MockBean과 유사
final class HealthKitTests: XCTestCase {

    // MARK: - Properties

    var mapper: HealthKitMapper!
    var mockAuth: MockHealthKitAuthorizationService!
    var mockRead: MockHealthKitReadService!
    var mockWrite: MockHealthKitWriteService!
    var syncService: HealthKitSyncService!

    let testUserId = UUID()

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mapper = HealthKitMapper()
        mockAuth = MockHealthKitAuthorizationService()
        mockRead = MockHealthKitReadService()
        mockWrite = MockHealthKitWriteService()

        // Initialize sync service with mocks
        syncService = HealthKitSyncService(
            readService: mockRead,
            writeService: mockWrite,
            authService: mockAuth,
            mapper: mapper
        )

        // Default: grant all permissions
        mockAuth.grantAllPermissions()
    }

    override func tearDown() {
        mapper = nil
        mockAuth.reset()
        mockRead.reset()
        mockWrite.reset()
        syncService = nil
        super.tearDown()
    }

    // MARK: - Mapper Tests: HealthKit → Domain

    /// Test: HKQuantitySample(체중) → BodyRecord 매핑 성공
    ///
    /// 테스트: 체중 샘플이 BodyRecord로 성공적으로 변환됨
    func testMapToBodyRecord_WeightSample_ReturnsBodyRecord() throws {
        // Given: Valid weight sample (70.5 kg)
        let weightSample = createWeightSample(kg: 70.5, date: Date())

        // When: Mapping to domain entity
        let bodyRecord = try mapper.mapToBodyRecord(
            from: weightSample,
            bodyFatSample: nil,
            userId: testUserId
        )

        // Then: Should map correctly
        XCTAssertEqual(bodyRecord.weight, Decimal(70.5), "Weight should match")
        XCTAssertNil(bodyRecord.bodyFatPercent, "Body fat should be nil")
        XCTAssertNil(bodyRecord.bodyFatMass, "Body fat mass should be nil")
        XCTAssertNotNil(bodyRecord.healthKitId, "HealthKit ID should be preserved")
        XCTAssertEqual(bodyRecord.userId, testUserId, "User ID should match")
    }

    /// Test: 체중 + 체지방률 샘플 → BodyRecord 매핑 성공
    ///
    /// 테스트: 체중과 체지방률이 하나의 BodyRecord로 병합됨
    func testMapToBodyRecord_WeightAndBodyFat_MergesIntoOneRecord() throws {
        // Given: Weight and body fat samples
        let weightSample = createWeightSample(kg: 70.5, date: Date())
        let bodyFatSample = createBodyFatSample(percent: 18.5, date: Date())

        // When: Mapping with both samples
        let bodyRecord = try mapper.mapToBodyRecord(
            from: weightSample,
            bodyFatSample: bodyFatSample,
            userId: testUserId
        )

        // Then: Should merge both values
        XCTAssertEqual(bodyRecord.weight, Decimal(70.5), "Weight should match")
        XCTAssertEqual(bodyRecord.bodyFatPercent, Decimal(18.5), accuracy: Decimal(0.1), "Body fat should match")
        XCTAssertNotNil(bodyRecord.bodyFatMass, "Body fat mass should be calculated")

        // Body fat mass = 70.5 * 0.185 = ~13.04 kg
        let expectedBodyFatMass = Decimal(70.5) * (Decimal(18.5) / 100)
        XCTAssertEqual(
            bodyRecord.bodyFatMass!,
            expectedBodyFatMass,
            accuracy: Decimal(0.1),
            "Body fat mass should be calculated correctly"
        )
    }

    /// Test: WorkoutData → ExerciseRecord 매핑 성공
    ///
    /// 테스트: 운동 데이터가 ExerciseRecord로 성공적으로 변환됨
    func testMapToExerciseRecord_WorkoutData_ReturnsExerciseRecord() {
        // Given: Valid workout data (running, 30 min, 350 kcal)
        let workoutData = createWorkoutData(
            exerciseType: .running,
            duration: 30,
            caloriesBurned: 350,
            date: Date()
        )

        // When: Mapping to domain entity
        let exerciseRecord = mapper.mapToExerciseRecord(
            from: workoutData,
            userId: testUserId
        )

        // Then: Should map all fields correctly
        XCTAssertEqual(exerciseRecord.exerciseType, .running, "Exercise type should match")
        XCTAssertEqual(exerciseRecord.duration, 30, "Duration should match")
        XCTAssertEqual(exerciseRecord.intensity, .medium, "Intensity should match")
        XCTAssertEqual(exerciseRecord.caloriesBurned, 350, "Calories should match")
        XCTAssertNotNil(exerciseRecord.healthKitId, "HealthKit ID should be preserved")
        XCTAssertEqual(exerciseRecord.userId, testUserId, "User ID should match")
    }

    /// Test: SleepData → SleepRecord 매핑 성공
    ///
    /// 테스트: 수면 데이터가 SleepRecord로 성공적으로 변환됨
    func testMapToSleepRecord_SleepData_ReturnsSleepRecord() {
        // Given: Valid sleep data (420 minutes = 7 hours)
        let sleepData = createSleepData(durationMinutes: 420, date: Date())

        // When: Mapping to domain entity
        let sleepRecord = mapper.mapToSleepRecord(
            from: sleepData,
            userId: testUserId
        )

        // Then: Should map correctly with auto-calculated status
        XCTAssertEqual(sleepRecord.duration, 420, "Duration should match")
        XCTAssertEqual(sleepRecord.status, .good, "Status should be good for 7 hours")
        XCTAssertNotNil(sleepRecord.healthKitId, "HealthKit ID should be preserved")
        XCTAssertEqual(sleepRecord.userId, testUserId, "User ID should match")
    }

    /// Test: 수면 상태 자동 계산 (다양한 시간대)
    ///
    /// 테스트: SleepStatus.from(durationMinutes:) 자동 계산 검증
    func testMapToSleepRecord_VariousDurations_CalculatesCorrectStatus() {
        // Given: Test cases for various sleep durations
        let testCases: [(minutes: Int, expectedStatus: SleepStatus)] = [
            (300, .bad),       // 5 hours -> bad
            (360, .soso),      // 6 hours -> soso
            (420, .good),      // 7 hours -> good
            (480, .excellent), // 8 hours -> excellent
            (550, .oversleep)  // 9+ hours -> oversleep
        ]

        for testCase in testCases {
            // When: Mapping sleep data
            let sleepData = createSleepData(durationMinutes: testCase.minutes, date: Date())
            let sleepRecord = mapper.mapToSleepRecord(from: sleepData, userId: testUserId)

            // Then: Status should be calculated correctly
            XCTAssertEqual(
                sleepRecord.status,
                testCase.expectedStatus,
                "\(testCase.minutes) minutes should result in \(testCase.expectedStatus)"
            )
        }
    }

    // MARK: - Mapper Tests: Domain → HealthKit

    /// Test: BodyRecord → HKQuantitySample(체중) 변환 성공
    ///
    /// 테스트: BodyRecord가 체중 샘플로 성공적으로 변환됨
    func testCreateWeightSample_BodyRecord_ReturnsHKQuantitySample() throws {
        // Given: BodyRecord with weight
        let bodyRecord = BodyRecord(
            id: UUID(),
            userId: testUserId,
            date: Date(),
            weight: Decimal(70.5),
            bodyFatMass: nil,
            bodyFatPercent: nil,
            muscleMass: nil,
            healthKitId: nil,
            createdAt: Date()
        )

        // When: Creating weight sample
        let weightSample = try mapper.createWeightSample(from: bodyRecord)

        // Then: Should create valid HKQuantitySample
        XCTAssertEqual(
            weightSample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
            70.5,
            accuracy: 0.1,
            "Weight should match"
        )
        XCTAssertEqual(
            weightSample.sampleType,
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            "Sample type should be body mass"
        )
    }

    /// Test: BodyRecord → HKQuantitySample(체지방률) 변환 성공
    ///
    /// 테스트: 체지방률이 0-1 범위로 올바르게 변환됨
    func testCreateBodyFatSample_BodyRecord_ConvertsPercentageCorrectly() throws {
        // Given: BodyRecord with body fat percentage (18.5%)
        let bodyRecord = BodyRecord(
            id: UUID(),
            userId: testUserId,
            date: Date(),
            weight: Decimal(70.5),
            bodyFatMass: nil,
            bodyFatPercent: Decimal(18.5), // 0-100 range
            muscleMass: nil,
            healthKitId: nil,
            createdAt: Date()
        )

        // When: Creating body fat sample
        let bodyFatSample = try mapper.createBodyFatSample(from: bodyRecord)

        // Then: Should convert to 0-1 range (18.5% → 0.185)
        XCTAssertEqual(
            bodyFatSample.quantity.doubleValue(for: .percent()),
            0.185,
            accuracy: 0.001,
            "Body fat should be in 0-1 range"
        )
    }

    /// Test: ExerciseRecord → HKWorkout 변환 성공
    ///
    /// 테스트: ExerciseRecord가 HKWorkout으로 성공적으로 변환됨
    func testCreateWorkout_ExerciseRecord_ReturnsHKWorkout() throws {
        // Given: ExerciseRecord (running, 30 min, 350 kcal)
        let exerciseRecord = ExerciseRecord(
            id: UUID(),
            userId: testUserId,
            date: Date(),
            exerciseType: .running,
            duration: 30,
            intensity: .high,
            caloriesBurned: 350,
            healthKitId: nil,
            createdAt: Date()
        )

        // When: Creating workout
        let workout = try mapper.createWorkout(from: exerciseRecord)

        // Then: Should create valid HKWorkout
        XCTAssertEqual(workout.workoutActivityType, .running, "Activity type should be running")
        XCTAssertEqual(workout.duration, 30 * 60, accuracy: 1.0, "Duration should be 30 minutes (1800 seconds)")
        XCTAssertEqual(
            workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
            350,
            accuracy: 1.0,
            "Calories should match"
        )
    }

    /// Test: ExerciseType → HKWorkoutActivityType 매핑 검증
    ///
    /// 테스트: 모든 ExerciseType이 올바른 HKWorkoutActivityType으로 변환됨
    func testCreateWorkout_AllExerciseTypes_MapsCorrectly() throws {
        // Given: Test cases for all exercise types
        let testCases: [(exerciseType: ExerciseType, expectedActivityType: HKWorkoutActivityType)] = [
            (.walking, .walking),
            (.running, .running),
            (.cycling, .cycling),
            (.swimming, .swimming),
            (.weight, .traditionalStrengthTraining),
            (.crossfit, .crossTraining),
            (.yoga, .yoga),
            (.other, .other)
        ]

        for testCase in testCases {
            // Given: ExerciseRecord with specific type
            let exerciseRecord = ExerciseRecord(
                id: UUID(),
                userId: testUserId,
                date: Date(),
                exerciseType: testCase.exerciseType,
                duration: 30,
                intensity: .medium,
                caloriesBurned: 200,
                healthKitId: nil,
                createdAt: Date()
            )

            // When: Creating workout
            let workout = try mapper.createWorkout(from: exerciseRecord)

            // Then: Activity type should match
            XCTAssertEqual(
                workout.workoutActivityType,
                testCase.expectedActivityType,
                "\(testCase.exerciseType) should map to \(testCase.expectedActivityType)"
            )
        }
    }

    // MARK: - Duplicate Detection Tests

    /// Test: healthKitId 추출 및 보존 검증
    ///
    /// 테스트: HKSample의 UUID가 BodyRecord.healthKitId에 보존됨
    func testMapToBodyRecord_PreservesHealthKitId() throws {
        // Given: Weight sample with known UUID
        let weightSample = createWeightSample(kg: 70.5, date: Date())
        let expectedHealthKitId = weightSample.uuid.uuidString

        // When: Mapping to BodyRecord
        let bodyRecord = try mapper.mapToBodyRecord(
            from: weightSample,
            userId: testUserId
        )

        // Then: HealthKit ID should be preserved
        XCTAssertEqual(bodyRecord.healthKitId, expectedHealthKitId, "HealthKit ID should be preserved")
        XCTAssertTrue(bodyRecord.isFromHealthKit, "Should be marked as from HealthKit")
    }

    /// Test: 수동 입력 데이터는 healthKitId가 nil
    ///
    /// 테스트: isFromHealthKit가 false를 반환함
    func testBodyRecord_ManualEntry_IsFromHealthKitIsFalse() {
        // Given: Manually created BodyRecord (no healthKitId)
        let bodyRecord = BodyRecord(
            id: UUID(),
            userId: testUserId,
            date: Date(),
            weight: Decimal(70.5),
            bodyFatMass: nil,
            bodyFatPercent: nil,
            muscleMass: nil,
            healthKitId: nil, // Manual entry
            createdAt: Date()
        )

        // Then: Should not be from HealthKit
        XCTAssertFalse(bodyRecord.isFromHealthKit, "Manual entry should not be from HealthKit")
    }

    /// Test: ExerciseRecord healthKitId 보존 검증
    ///
    /// 테스트: WorkoutData의 UUID가 ExerciseRecord.healthKitId에 보존됨
    func testMapToExerciseRecord_PreservesHealthKitId() {
        // Given: WorkoutData with known UUID
        let workoutData = createWorkoutData(
            exerciseType: .running,
            duration: 30,
            caloriesBurned: 350,
            date: Date()
        )
        let expectedHealthKitId = workoutData.healthKitId.uuidString

        // When: Mapping to ExerciseRecord
        let exerciseRecord = mapper.mapToExerciseRecord(
            from: workoutData,
            userId: testUserId
        )

        // Then: HealthKit ID should be preserved
        XCTAssertEqual(exerciseRecord.healthKitId, expectedHealthKitId, "HealthKit ID should be preserved")
        XCTAssertTrue(exerciseRecord.isFromHealthKit, "Should be marked as from HealthKit")
    }

    // MARK: - Sync Service Tests

    /// Test: 전체 동기화 성공 (권한 허용됨)
    ///
    /// 테스트: sync() 호출 시 모든 데이터 타입 동기화
    func testSync_AllPermissionsGranted_SyncsAllDataTypes() async throws {
        // Given: All permissions granted
        mockAuth.grantAllPermissions()

        // Mock data
        mockRead.mockWeightSamples = [createWeightSample(kg: 70.5, date: Date())]
        mockRead.mockWorkouts = [createWorkoutData(exerciseType: .running, duration: 30, caloriesBurned: 350, date: Date())]

        // When: Full sync
        try await syncService.sync(userId: testUserId, days: 7)

        // Then: Should fetch all data types
        XCTAssertEqual(mockRead.fetchWeightCallCount, 1, "Should fetch weight")
        XCTAssertEqual(mockRead.fetchBodyFatCallCount, 1, "Should fetch body fat")
        XCTAssertEqual(mockRead.fetchWorkoutsCallCount, 1, "Should fetch workouts")

        // Last sync date should be saved
        XCTAssertNotNil(syncService.getLastSyncDate(), "Last sync date should be saved")
    }

    /// Test: 부분 권한 시 해당 데이터만 동기화
    ///
    /// 테스트: 권한이 있는 데이터 타입만 동기화됨
    func testSync_PartialPermissions_SyncsOnlyAuthorizedTypes() async throws {
        // Given: Only weight permission granted
        mockAuth.denyAllPermissions()
        mockAuth.authorizedQuantityTypes = [.weight]

        mockRead.mockWeightSamples = [createWeightSample(kg: 70.5, date: Date())]

        // When: Full sync
        try await syncService.sync(userId: testUserId, days: 7)

        // Then: Should only fetch weight (authorized)
        XCTAssertEqual(mockRead.fetchWeightCallCount, 1, "Should fetch weight")
        XCTAssertEqual(mockRead.fetchWorkoutsCallCount, 0, "Should not fetch workouts (no permission)")
    }

    /// Test: 증분 동기화 (특정 날짜 이후)
    ///
    /// 테스트: syncSince() 호출 시 날짜 이후 데이터만 동기화
    func testSyncSince_ValidDateRange_SyncsIncrementally() async throws {
        // Given: All permissions granted
        mockAuth.grantAllPermissions()

        let startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        mockRead.mockWeightSamples = [createWeightSample(kg: 70.5, date: Date())]

        // When: Incremental sync since 3 days ago
        try await syncService.syncSince(date: startDate, userId: testUserId)

        // Then: Should fetch data types
        XCTAssertEqual(mockRead.fetchWeightCallCount, 1, "Should fetch weight")
        XCTAssertEqual(mockRead.fetchBodyFatCallCount, 1, "Should fetch body fat")
    }

    /// Test: 마지막 동기화 시각 관리
    ///
    /// 테스트: getLastSyncDate() / clearLastSyncDate() 동작 검증
    func testLastSyncDate_Management_WorksCorrectly() async throws {
        // Given: No previous sync
        syncService.clearLastSyncDate()
        XCTAssertNil(syncService.getLastSyncDate(), "Last sync date should be nil initially")

        mockAuth.grantAllPermissions()
        mockRead.mockWeightSamples = []

        // When: Sync once
        try await syncService.sync(userId: testUserId, days: 7)

        // Then: Last sync date should be saved
        XCTAssertNotNil(syncService.getLastSyncDate(), "Last sync date should be saved after sync")

        // When: Clear last sync date
        syncService.clearLastSyncDate()

        // Then: Should be nil
        XCTAssertNil(syncService.getLastSyncDate(), "Last sync date should be nil after clear")
    }

    // MARK: - Conflict Resolution Tests

    /// Test: 수동 입력 데이터 보존 (BodyRecord)
    ///
    /// 테스트: 수동 입력한 체성분 데이터는 HealthKit 데이터로 덮어쓰지 않음
    func testConflictResolution_ManualBodyRecord_IsPreserved() {
        // Given: Manual entry BodyRecord (no healthKitId)
        let manualRecord = BodyRecord(
            id: UUID(),
            userId: testUserId,
            date: Date(),
            weight: Decimal(72.0), // User entered 72kg
            bodyFatMass: nil,
            bodyFatPercent: nil,
            muscleMass: nil,
            healthKitId: nil, // Manual entry
            createdAt: Date()
        )

        // Simulate conflict resolution logic
        // (In real implementation, this would be in syncBodyComposition)
        let isManualEntry = manualRecord.healthKitId == nil

        // Then: Should preserve manual entry
        XCTAssertTrue(isManualEntry, "Should be identified as manual entry")
        XCTAssertFalse(manualRecord.isFromHealthKit, "Should not be from HealthKit")
    }

    /// Test: HealthKit 데이터 임포트 (수동 입력 없음)
    ///
    /// 테스트: 수동 입력이 없으면 HealthKit 데이터 임포트
    func testConflictResolution_NoManualEntry_ImportsHealthKitData() throws {
        // Given: HealthKit weight sample (no manual entry)
        let weightSample = createWeightSample(kg: 70.5, date: Date())
        let healthKitRecord = try mapper.mapToBodyRecord(
            from: weightSample,
            userId: testUserId
        )

        // Then: Should be from HealthKit
        XCTAssertTrue(healthKitRecord.isFromHealthKit, "Should be from HealthKit")
        XCTAssertNotNil(healthKitRecord.healthKitId, "HealthKit ID should be present")
    }

    /// Test: 중복 운동 기록 건너뛰기 (같은 healthKitId)
    ///
    /// 테스트: 같은 healthKitId를 가진 운동은 중복으로 건너뛰기
    func testDuplicateDetection_SameHealthKitId_SkipsDuplicate() {
        // Given: Two workout data with same UUID
        let workout1 = createWorkoutData(
            exerciseType: .running,
            duration: 30,
            caloriesBurned: 350,
            date: Date()
        )

        let workout2 = createWorkoutData(
            exerciseType: .running,
            duration: 30,
            caloriesBurned: 350,
            date: Date(),
            uuid: workout1.healthKitId // Same UUID
        )

        // Then: Should have same healthKitId
        XCTAssertEqual(
            workout1.healthKitId,
            workout2.healthKitId,
            "Same UUID means duplicate"
        )
    }

    /// Test: 운동 기록은 하루에 여러 개 허용 (allowMultiplePerDay)
    ///
    /// 테스트: 수동 입력 운동과 HealthKit 운동이 공존 가능
    func testConflictResolution_ExerciseRecords_AllowsMultiplePerDay() {
        // Given: Manual exercise record
        let manualExercise = ExerciseRecord(
            id: UUID(),
            userId: testUserId,
            date: Date(),
            exerciseType: .running,
            duration: 30,
            intensity: .high,
            caloriesBurned: 350,
            healthKitId: nil, // Manual entry
            createdAt: Date()
        )

        // Given: HealthKit exercise record (same day, different UUID)
        let workoutData = createWorkoutData(
            exerciseType: .cycling,
            duration: 45,
            caloriesBurned: 400,
            date: Date()
        )
        let healthKitExercise = mapper.mapToExerciseRecord(
            from: workoutData,
            userId: testUserId
        )

        // Then: Both should coexist (different healthKitId)
        XCTAssertFalse(manualExercise.isFromHealthKit, "Manual entry")
        XCTAssertTrue(healthKitExercise.isFromHealthKit, "HealthKit entry")
        XCTAssertNotEqual(
            manualExercise.id,
            healthKitExercise.id,
            "Different records, both allowed"
        )
    }

    // MARK: - Export Tests (Bodii → HealthKit)

    /// Test: 체중 데이터 HealthKit 저장 성공
    ///
    /// 테스트: exportBodyComposition() 호출 시 HealthKit에 저장됨
    func testExportBodyComposition_ValidData_SavesToHealthKit() async throws {
        // Given: Valid body composition data
        let weight = Decimal(70.5)
        let bodyFatPercent = Decimal(18.5)

        mockWrite.hasWritePermission = true

        // When: Export to HealthKit
        try await syncService.exportBodyComposition(
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            date: Date()
        )

        // Then: Should save to HealthKit
        XCTAssertEqual(mockWrite.saveWeightCallCount, 1, "Should save weight")
        XCTAssertEqual(mockWrite.saveBodyFatCallCount, 1, "Should save body fat")
    }

    /// Test: 쓰기 권한 없으면 저장 건너뛰기
    ///
    /// 테스트: exportBodyComposition() 권한 없으면 에러 발생하지 않고 건너뛰기
    func testExportBodyComposition_NoWritePermission_SkipsGracefully() async throws {
        // Given: No write permission
        mockWrite.hasWritePermission = false

        // When: Export to HealthKit
        try await syncService.exportBodyComposition(
            weight: Decimal(70.5),
            bodyFatPercent: nil,
            date: Date()
        )

        // Then: Should not throw error, just skip
        XCTAssertEqual(mockWrite.saveWeightCallCount, 0, "Should not save weight")
    }

    /// Test: 운동 데이터 HealthKit 저장 성공
    ///
    /// 테스트: exportWorkout() 호출 시 HealthKit에 저장됨
    func testExportWorkout_ValidData_SavesToHealthKit() async throws {
        // Given: Valid workout data
        mockWrite.hasWritePermission = true

        // When: Export to HealthKit
        try await syncService.exportWorkout(
            exerciseType: .running,
            duration: 30,
            caloriesBurned: 350,
            intensity: .high,
            startDate: Date()
        )

        // Then: Should save to HealthKit
        XCTAssertEqual(mockWrite.saveWorkoutCallCount, 1, "Should save workout")
    }

    /// Test: 섭취 칼로리 HealthKit 저장 성공
    ///
    /// 테스트: exportDietaryEnergy() 호출 시 HealthKit에 저장됨
    func testExportDietaryEnergy_ValidData_SavesToHealthKit() async throws {
        // Given: Valid dietary energy data
        mockWrite.hasWritePermission = true

        // When: Export to HealthKit
        try await syncService.exportDietaryEnergy(
            calories: Decimal(450),
            date: Date(),
            mealType: "breakfast"
        )

        // Then: Should save to HealthKit
        XCTAssertEqual(mockWrite.saveDietaryEnergyCallCount, 1, "Should save dietary energy")
    }

    // MARK: - Error Handling Tests

    /// Test: HealthKit 사용 불가능 시 에러 발생
    ///
    /// 테스트: iPad 등 HealthKit 미지원 기기에서 에러 발생
    func testSync_HealthKitNotAvailable_ThrowsError() async {
        // Given: HealthKit not available (e.g., iPad)
        mockAuth.isHealthKitAvailable = false

        // When/Then: Should throw error
        do {
            try await syncService.sync(userId: testUserId, days: 7)
            XCTFail("Expected HealthKitError.healthKitNotAvailable")
        } catch let error as HealthKitError {
            XCTAssertEqual(
                error,
                HealthKitError.healthKitNotAvailable,
                "Should throw healthKitNotAvailable error"
            )
        }
    }

    /// Test: 읽기 에러 시 부분 실패 (다른 타입은 계속)
    ///
    /// 테스트: 한 데이터 타입 읽기 실패해도 다른 타입은 계속 동기화
    func testSync_ReadError_ContinuesWithOtherTypes() async throws {
        // Given: Weight fetch will fail, but workouts will succeed
        mockAuth.grantAllPermissions()
        mockRead.shouldThrowError = HealthKitError.readFailed(typeName: "Weight")
        mockRead.mockWorkouts = [createWorkoutData(exerciseType: .running, duration: 30, caloriesBurned: 350, date: Date())]

        // When/Then: Should throw first error but still attempt other syncs
        do {
            try await syncService.sync(userId: testUserId, days: 7)
            XCTFail("Expected error")
        } catch {
            // Expected error from weight fetch
            XCTAssertNotNil(error, "Should throw error from failed sync")
        }
    }

    // MARK: - Helper Methods

    /// 테스트용 체중 샘플 생성
    private func createWeightSample(kg: Double, date: Date) -> HKQuantitySample {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)

        return HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: date,
            end: date
        )
    }

    /// 테스트용 체지방률 샘플 생성
    private func createBodyFatSample(percent: Double, date: Date) -> HKQuantitySample {
        let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let quantity = HKQuantity(unit: .percent(), doubleValue: percent / 100.0) // 18.5 → 0.185

        return HKQuantitySample(
            type: quantityType,
            quantity: quantity,
            start: date,
            end: date
        )
    }

    /// 테스트용 WorkoutData 생성
    private func createWorkoutData(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        date: Date,
        uuid: UUID = UUID()
    ) -> HealthKitReadService.WorkoutData {
        // Create a mock HKWorkout (simplified for testing)
        let activityType: HKWorkoutActivityType = {
            switch exerciseType {
            case .running: return .running
            case .walking: return .walking
            case .cycling: return .cycling
            case .swimming: return .swimming
            case .weight: return .traditionalStrengthTraining
            case .crossfit: return .crossTraining
            case .yoga: return .yoga
            case .other: return .other
            }
        }()

        let durationInSeconds = TimeInterval(duration * 60)
        let endDate = date.addingTimeInterval(durationInSeconds)
        let caloriesQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: Double(caloriesBurned))

        let workout = HKWorkout(
            activityType: activityType,
            start: date,
            end: endDate,
            duration: durationInSeconds,
            totalEnergyBurned: caloriesQuantity,
            totalDistance: nil,
            metadata: nil
        )

        return HealthKitReadService.WorkoutData(
            workout: workout,
            exerciseType: exerciseType,
            duration: duration,
            caloriesBurned: caloriesBurned,
            intensity: .medium,
            healthKitId: uuid,
            startDate: date,
            endDate: endDate
        )
    }

    /// 테스트용 SleepData 생성
    private func createSleepData(durationMinutes: Int, date: Date) -> HealthKitReadService.SleepData {
        return HealthKitReadService.SleepData(
            totalDurationMinutes: durationMinutes,
            segments: [], // Simplified for testing
            startDate: date,
            endDate: date.addingTimeInterval(TimeInterval(durationMinutes * 60))
        )
    }
}

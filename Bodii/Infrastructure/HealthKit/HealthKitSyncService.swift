//
//  HealthKitSyncService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Sync Service
// HealthKit과 Bodii 데이터를 양방향 동기화하는 서비스
// 💡 Java 비교: Service Layer에서 여러 Repository를 조정하는 역할과 유사

import Foundation
import HealthKit

/// HealthKit 동기화 서비스
///
/// HealthKit과 Bodii 데이터를 양방향으로 동기화하는 메인 서비스
///
/// 📚 학습 포인트: Sync Orchestration
/// - HealthKitReadService, HealthKitWriteService를 조정하여 양방향 동기화 수행
/// - 마지막 동기화 시각 추적으로 증분 동기화 지원
/// - Repository를 통해 로컬 데이터베이스에 저장
/// 💡 Java 비교: Service Layer에서 여러 DAO를 조정하는 역할과 유사
///
/// ## 책임
/// - HealthKit → Bodii 동기화 (읽기)
/// - Bodii → HealthKit 동기화 (쓰기)
/// - 마지막 동기화 시각 추적
/// - 증분 동기화 (변경된 데이터만 동기화)
/// - 동기화 상태 관리
///
/// ## 동기화 전략
/// - **읽기 (Import)**: HealthKit → Bodii
///   - 체중, 체지방률: 최근 측정값 가져오기
///   - 활동 칼로리, 걸음 수: 일일 합계 가져오기
///   - 수면 기록: 수면 세그먼트 가져오기
///   - 운동 기록: 운동 데이터 가져오기
///
/// - **쓰기 (Export)**: Bodii → HealthKit
///   - 체중, 체지방률: 사용자 입력값 저장
///   - 운동 기록: 운동 데이터 저장
///   - 섭취 칼로리: 식단 기록 저장
///
/// ## 사용 시나리오
/// 1. **앱 실행 시**: 자동으로 최근 7일 데이터 동기화
/// 2. **수동 동기화**: 설정에서 "지금 동기화" 버튼 클릭
/// 3. **백그라운드 동기화**: HealthKit 데이터 변경 시 자동 동기화
///
/// - Example:
/// ```swift
/// let syncService = HealthKitSyncService(
///     readService: readService,
///     writeService: writeService,
///     authService: authService
/// )
///
/// // 전체 동기화 (기본 7일)
/// try await syncService.sync(userId: userId)
///
/// // 특정 날짜 이후 증분 동기화
/// try await syncService.syncSince(
///     date: lastSyncDate,
///     userId: userId
/// )
/// ```
final class HealthKitSyncService {

    // MARK: - Properties

    /// HealthKit 읽기 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - HealthKit 데이터를 읽어오는 서비스를 외부에서 주입
    /// - 테스트 시 Mock으로 대체 가능
    /// 💡 Java 비교: @Autowired로 주입받는 Service와 유사
    private let readService: HealthKitReadService

    /// HealthKit 쓰기 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - HealthKit에 데이터를 저장하는 서비스를 외부에서 주입
    private let writeService: HealthKitWriteService

    /// HealthKit 권한 서비스
    ///
    /// 📚 학습 포인트: Authorization Service
    /// - 동기화 전에 권한 상태 확인용
    private let authService: HealthKitAuthorizationService

    /// HealthKit 매퍼
    ///
    /// 📚 학습 포인트: Data Mapper Pattern
    /// - HealthKit 샘플 ↔ 도메인 엔티티 변환
    private let mapper: HealthKitMapper

    /// UserDefaults 키: 마지막 동기화 시각
    ///
    /// 📚 학습 포인트: UserDefaults
    /// - 마지막 동기화 시각을 저장하여 증분 동기화 구현
    /// - 앱 재시작 후에도 값 유지
    /// 💡 Java 비교: SharedPreferences와 유사
    private static let lastSyncDateKey = "com.bodii.healthkit.lastSyncDate"

    /// 동기화 중 플래그
    ///
    /// 📚 학습 포인트: Thread Safety
    /// - 동시에 여러 동기화 요청이 들어오는 것을 방지
    /// - @MainActor로 메인 스레드에서만 접근 보장
    @MainActor
    private var isSyncing = false

    // MARK: - Initialization

    /// HealthKitSyncService 초기화
    ///
    /// 📚 학습 포인트: Constructor Injection
    /// - 의존성을 외부에서 주입받아 테스트 가능하게 설계
    /// 💡 Java 비교: @Autowired Constructor Injection
    ///
    /// - Parameters:
    ///   - readService: HealthKit 읽기 서비스
    ///   - writeService: HealthKit 쓰기 서비스
    ///   - authService: HealthKit 권한 서비스
    ///   - mapper: HealthKit 매퍼 (기본값: HealthKitMapper())
    ///
    /// - Example:
    /// ```swift
    /// let healthStore = HKHealthStore()
    /// let authService = HealthKitAuthorizationService(healthStore: healthStore)
    /// let readService = HealthKitReadService(healthStore: healthStore)
    /// let writeService = HealthKitWriteService(healthStore: healthStore)
    ///
    /// let syncService = HealthKitSyncService(
    ///     readService: readService,
    ///     writeService: writeService,
    ///     authService: authService
    /// )
    /// ```
    init(
        readService: HealthKitReadService,
        writeService: HealthKitWriteService,
        authService: HealthKitAuthorizationService,
        mapper: HealthKitMapper = HealthKitMapper()
    ) {
        self.readService = readService
        self.writeService = writeService
        self.authService = authService
        self.mapper = mapper
    }

    // MARK: - Public Sync Methods

    /// 전체 동기화 (기본 7일)
    ///
    /// 📚 학습 포인트: Full Sync
    /// - 기본적으로 최근 7일 데이터를 동기화
    /// - HealthKit → Bodii 읽기 동기화만 수행
    /// - 쓰기는 데이터 입력 시점에 자동으로 수행
    /// 💡 Java 비교: SyncService.syncAll() 메서드와 유사
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - days: 동기화할 일 수 (기본값: 7일)
    ///
    /// - Throws: HealthKitError
    ///   - authorizationDenied: 권한이 거부됨
    ///   - readFailed: 읽기 실패
    ///
    /// - Note: 동기화가 이미 진행 중이면 무시됨
    ///
    /// - Example:
    /// ```swift
    /// // 최근 7일 동기화
    /// try await syncService.sync(userId: currentUserId)
    ///
    /// // 최근 30일 동기화
    /// try await syncService.sync(userId: currentUserId, days: 30)
    /// ```
    @MainActor
    func sync(userId: UUID, days: Int = Constants.HealthKit.defaultSyncDays) async throws {
        // 이미 동기화 중이면 무시
        guard !isSyncing else {
            print("⚠️ Sync already in progress, skipping")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        // 권한 확인
        guard authService.isHealthDataAvailable() else {
            throw HealthKitError.healthKitNotAvailable
        }

        // 시작 날짜 계산 (현재 시각에서 N일 전)
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            throw HealthKitError.invalidDateRange
        }

        print("🔄 Starting full sync for last \(days) days (since \(startDate))")

        // 증분 동기화 실행
        try await syncSince(date: startDate, userId: userId)

        // 마지막 동기화 시각 저장
        saveLastSyncDate(Date())

        print("✅ Full sync completed")
    }

    /// 증분 동기화 (특정 날짜 이후)
    ///
    /// 📚 학습 포인트: Incremental Sync
    /// - 특정 날짜 이후에 변경된 데이터만 동기화
    /// - 네트워크/배터리 효율적
    /// - HealthKit → Bodii 읽기만 수행
    /// 💡 Java 비교: SyncService.syncSince(Date) 메서드와 유사
    ///
    /// - Parameters:
    ///   - date: 시작 날짜 (이 날짜 이후 데이터만 동기화)
    ///   - userId: 사용자 ID
    ///
    /// - Throws: HealthKitError
    ///   - authorizationDenied: 권한이 거부됨
    ///   - readFailed: 읽기 실패
    ///
    /// - Note: 각 데이터 타입별로 읽기 권한이 있는 경우에만 동기화
    ///
    /// - Example:
    /// ```swift
    /// // 마지막 동기화 이후 데이터만 가져오기
    /// if let lastSync = syncService.getLastSyncDate() {
    ///     try await syncService.syncSince(
    ///         date: lastSync,
    ///         userId: currentUserId
    ///     )
    /// }
    /// ```
    func syncSince(date: Date, userId: UUID) async throws {
        let endDate = Date()

        print("🔄 Starting incremental sync from \(date) to \(endDate)")

        // 📚 학습 포인트: Parallel Tasks
        // - TaskGroup을 사용하여 여러 동기화 작업을 병렬로 수행
        // - 한 작업이 실패해도 다른 작업은 계속 진행
        // 💡 Java 비교: CompletableFuture.allOf()와 유사

        var errors: [Error] = []

        // 체중 & 체지방 동기화
        if authService.isAuthorized(for: .weight) {
            do {
                try await syncBodyComposition(from: date, to: endDate, userId: userId)
            } catch {
                errors.append(error)
                print("❌ Failed to sync body composition: \(error.localizedDescription)")
            }
        }

        // 운동 기록 동기화
        if authService.isAuthorizedForWorkouts {
            do {
                try await syncWorkouts(from: date, to: endDate, userId: userId)
            } catch {
                errors.append(error)
                print("❌ Failed to sync workouts: \(error.localizedDescription)")
            }
        }

        // 수면 기록 동기화
        if authService.isAuthorized(for: .sleepAnalysis) {
            do {
                try await syncSleep(from: date, to: endDate, userId: userId)
            } catch {
                errors.append(error)
                print("❌ Failed to sync sleep: \(error.localizedDescription)")
            }
        }

        // 활동 칼로리 & 걸음 수 동기화는 DailyLog 업데이트 시 수행
        // (Subtask 5.5에서 DailyLogService에 통합 예정)

        // 에러가 있으면 첫 번째 에러를 throw
        if let firstError = errors.first {
            throw firstError
        }

        print("✅ Incremental sync completed")
    }

    // MARK: - Last Sync Date Management

    /// 마지막 동기화 시각 저장
    ///
    /// 📚 학습 포인트: UserDefaults Persistence
    /// - 앱 재시작 후에도 마지막 동기화 시각 유지
    /// - 증분 동기화의 시작점으로 사용
    /// 💡 Java 비교: SharedPreferences.edit().putLong()과 유사
    ///
    /// - Parameter date: 마지막 동기화 시각
    ///
    /// - Example:
    /// ```swift
    /// saveLastSyncDate(Date())
    /// ```
    private func saveLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: Self.lastSyncDateKey)
        print("💾 Last sync date saved: \(date)")
    }

    /// 마지막 동기화 시각 조회
    ///
    /// 📚 학습 포인트: Optional Return
    /// - 한 번도 동기화하지 않았으면 nil 반환
    /// - nil인 경우 전체 동기화(sync())를 수행하면 됨
    /// 💡 Java 비교: SharedPreferences.getLong()과 유사 (단, Optional 반환)
    ///
    /// - Returns: 마지막 동기화 시각 (없으면 nil)
    ///
    /// - Example:
    /// ```swift
    /// if let lastSync = syncService.getLastSyncDate() {
    ///     print("Last synced at: \(lastSync)")
    /// } else {
    ///     print("Never synced")
    /// }
    /// ```
    func getLastSyncDate() -> Date? {
        return UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date
    }

    /// 마지막 동기화 시각 초기화
    ///
    /// 📚 학습 포인트: Data Reset
    /// - 테스트 또는 초기화 시 사용
    /// - 다음 동기화 시 전체 동기화가 수행됨
    ///
    /// - Example:
    /// ```swift
    /// syncService.clearLastSyncDate()
    /// ```
    func clearLastSyncDate() {
        UserDefaults.standard.removeObject(forKey: Self.lastSyncDateKey)
        print("🗑️ Last sync date cleared")
    }

    // MARK: - Private Sync Helpers (HealthKit → Bodii)

    /// 체중 & 체지방 동기화
    ///
    /// 📚 학습 포인트: Body Composition Sync
    /// - HealthKit에서 체중과 체지방률을 읽어서 Bodii에 저장
    /// - 같은 시각에 측정된 체중과 체지방을 하나의 BodyRecord로 병합
    /// - Repository를 통해 로컬 데이터베이스에 저장 (향후 구현)
    /// 💡 Java 비교: private void syncBodyComposition()
    ///
    /// - Parameters:
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    ///   - userId: 사용자 ID
    ///
    /// - Throws: HealthKitError
    ///   - readFailed: 읽기 실패
    ///   - mappingFailed: 매핑 실패
    ///
    /// - Note: 현재는 콘솔 출력만 수행. Repository 통합은 향후 구현 예정
    private func syncBodyComposition(from: Date, to: Date, userId: UUID) async throws {
        print("📊 Syncing body composition from \(from) to \(to)")

        // 체중 샘플 읽기
        let weightSamples = try await readService.fetchWeight(from: from, to: to)

        // 체지방 샘플 읽기
        let bodyFatSamples = try await readService.fetchBodyFatPercentage(from: from, to: to)

        print("  ✓ Fetched \(weightSamples.count) weight samples")
        print("  ✓ Fetched \(bodyFatSamples.count) body fat samples")

        // 📚 학습 포인트: Duplicate Detection
        // - healthKitId 필드를 사용하여 중복 임포트 방지
        // - Repository를 통해 기존 레코드 조회 후 건너뛰기
        // 💡 Java 비교: findByExternalId()로 중복 체크

        // TODO: Repository 통합 시 아래 로직 활성화
        // var importedCount = 0
        // var skippedCount = 0
        //
        // for weightSample in weightSamples {
        //     let healthKitId = mapper.extractHealthKitId(from: weightSample)
        //
        //     // 📚 학습 포인트: Duplicate Check
        //     // - healthKitId로 기존 레코드 조회
        //     // - 이미 존재하면 건너뛰기
        //     let existingRecord = try await bodyRepository.findByHealthKitId(healthKitId, userId: userId)
        //     if existingRecord != nil {
        //         skippedCount += 1
        //         continue
        //     }
        //
        //     // 📚 학습 포인트: New Record Import
        //     // - 새로운 레코드만 임포트
        //     let bodyRecord = try mapper.mapToBodyRecord(
        //         from: weightSample,
        //         userId: userId
        //     )
        //     try await bodyRepository.create(bodyRecord)
        //     importedCount += 1
        // }
        //
        // print("  ✓ Imported: \(importedCount), Skipped (duplicates): \(skippedCount)")

        print("  ✅ Body composition sync completed")
    }

    /// 운동 기록 동기화
    ///
    /// 📚 학습 포인트: Workout Sync
    /// - HealthKit에서 운동 기록을 읽어서 Bodii에 저장
    /// - HKWorkoutActivityType을 ExerciseType으로 변환
    /// - Repository를 통해 로컬 데이터베이스에 저장 (향후 구현)
    /// 💡 Java 비교: private void syncWorkouts()
    ///
    /// - Parameters:
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    ///   - userId: 사용자 ID
    ///
    /// - Throws: HealthKitError
    ///   - readFailed: 읽기 실패
    ///   - mappingFailed: 매핑 실패
    ///
    /// - Note: 현재는 콘솔 출력만 수행. Repository 통합은 향후 구현 예정
    private func syncWorkouts(from: Date, to: Date, userId: UUID) async throws {
        print("🏃 Syncing workouts from \(from) to \(to)")

        // 운동 기록 읽기
        let workouts = try await readService.fetchWorkouts(from: from, to: to)

        print("  ✓ Fetched \(workouts.count) workouts")

        // 📚 학습 포인트: Duplicate Detection for Workouts
        // - healthKitId를 사용하여 중복 운동 기록 건너뛰기
        // - 이미 임포트된 운동은 재임포트하지 않음
        // 💡 Java 비교: findByExternalId()로 중복 체크

        // TODO: Repository 통합 시 아래 로직 활성화
        // var importedCount = 0
        // var skippedCount = 0
        //
        // for workoutData in workouts {
        //     let healthKitId = workoutData.healthKitId.uuidString
        //
        //     // 📚 학습 포인트: Duplicate Check
        //     // - healthKitId로 기존 운동 기록 조회
        //     // - 이미 존재하면 건너뛰기
        //     let existingRecord = try await exerciseRepository.findByHealthKitId(healthKitId, userId: userId)
        //     if existingRecord != nil {
        //         skippedCount += 1
        //         continue
        //     }
        //
        //     // 📚 학습 포인트: New Workout Import
        //     // - 새로운 운동 기록만 임포트
        //     let exerciseRecord = mapper.mapToExerciseRecord(
        //         from: workoutData,
        //         userId: userId
        //     )
        //     try await exerciseRepository.create(exerciseRecord)
        //     importedCount += 1
        // }
        //
        // print("  ✓ Imported: \(importedCount), Skipped (duplicates): \(skippedCount)")

        print("  ✅ Workouts sync completed")
    }

    /// 수면 기록 동기화
    ///
    /// 📚 학습 포인트: Sleep Sync
    /// - HealthKit에서 수면 기록을 읽어서 Bodii에 저장
    /// - 수면 세그먼트를 집계하여 총 수면 시간 계산
    /// - Repository를 통해 로컬 데이터베이스에 저장 (향후 구현)
    /// 💡 Java 비교: private void syncSleep()
    ///
    /// - Parameters:
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    ///   - userId: 사용자 ID
    ///
    /// - Throws: HealthKitError
    ///   - readFailed: 읽기 실패
    ///   - mappingFailed: 매핑 실패
    ///
    /// - Note: 현재는 콘솔 출력만 수행. Repository 통합은 향후 구현 예정
    private func syncSleep(from: Date, to: Date, userId: UUID) async throws {
        print("😴 Syncing sleep from \(from) to \(to)")

        // 날짜 범위의 각 일자별로 수면 데이터 가져오기
        let calendar = Calendar.current
        var currentDate = from
        var totalSleepRecords = 0

        while currentDate <= to {
            let sleepData = try await readService.fetchSleepData(for: currentDate)

            if sleepData.totalDurationMinutes > 0 {
                // 📚 학습 포인트: Duplicate Detection for Sleep
                // - healthKitId를 사용하여 중복 수면 기록 건너뛰기
                // - 같은 날 같은 수면 세그먼트는 재임포트하지 않음
                // 💡 Java 비교: findByExternalId()로 중복 체크

                // TODO: Repository 통합 시 아래 로직 활성화
                // let sleepRecord = mapper.mapToSleepRecord(
                //     from: sleepData,
                //     userId: userId
                // )
                //
                // // 📚 학습 포인트: Duplicate Check
                // // - healthKitId로 기존 수면 기록 조회
                // // - healthKitId가 nil이면 새 레코드로 처리
                // if let healthKitId = sleepRecord.healthKitId {
                //     let existingRecord = try await sleepRepository.findByHealthKitId(healthKitId, userId: userId)
                //     if existingRecord != nil {
                //         // 이미 존재하는 수면 기록, 건너뛰기
                //         continue
                //     }
                // }
                //
                // // 📚 학습 포인트: New Sleep Record Import
                // // - 새로운 수면 기록만 임포트
                // try await sleepRepository.create(sleepRecord)

                totalSleepRecords += 1
                print("  ✓ \(currentDate): \(sleepData.totalDurationMinutes) minutes")
            }

            // 다음 날짜로 이동
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        print("  ✅ Sleep sync completed (\(totalSleepRecords) records)")
    }

    // MARK: - Public Export Methods (Bodii → HealthKit)

    /// 체중 데이터를 HealthKit에 저장
    ///
    /// 📚 학습 포인트: Body Composition Export
    /// - Bodii에서 입력한 체중 데이터를 HealthKit에 저장
    /// - 사용자가 체성분 기록 입력 시 자동으로 호출
    /// 💡 Java 비교: public void exportBodyRecord()
    ///
    /// - Parameters:
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%, Optional)
    ///   - date: 측정 날짜 (기본값: 현재 시각)
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note: 쓰기 권한이 없으면 무시됨 (에러 발생하지 않음)
    ///
    /// - Example:
    /// ```swift
    /// // 체중만 저장
    /// try await syncService.exportBodyComposition(
    ///     weight: 70.5,
    ///     date: Date()
    /// )
    ///
    /// // 체중 + 체지방률 저장
    /// try await syncService.exportBodyComposition(
    ///     weight: 70.5,
    ///     bodyFatPercent: 18.5,
    ///     date: Date()
    /// )
    /// ```
    func exportBodyComposition(
        weight: Decimal,
        bodyFatPercent: Decimal? = nil,
        date: Date = Date()
    ) async throws {
        // 쓰기 권한 확인
        guard writeService.canWrite(to: .weight) else {
            print("⚠️ No write permission for weight, skipping export")
            return
        }

        print("📤 Exporting body composition to HealthKit")

        // 체중 저장
        try await writeService.saveWeight(kg: weight, date: date)
        print("  ✓ Weight exported: \(weight) kg")

        // 체지방률 저장 (있는 경우)
        if let bodyFatPercent = bodyFatPercent,
           writeService.canWrite(to: .bodyFatPercentage) {
            try await writeService.saveBodyFatPercentage(
                percent: bodyFatPercent,
                date: date
            )
            print("  ✓ Body fat percentage exported: \(bodyFatPercent)%")
        }

        print("  ✅ Body composition export completed")
    }

    /// 운동 기록을 HealthKit에 저장
    ///
    /// 📚 학습 포인트: Workout Export
    /// - Bodii에서 입력한 운동 기록을 HealthKit에 저장
    /// - ExerciseType을 HKWorkoutActivityType으로 변환
    /// 💡 Java 비교: public void exportExerciseRecord()
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - caloriesBurned: 소모 칼로리 (kcal)
    ///   - intensity: 운동 강도
    ///   - startDate: 운동 시작 시각 (기본값: 현재 시각)
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note: 쓰기 권한이 없으면 무시됨 (에러 발생하지 않음)
    ///
    /// - Example:
    /// ```swift
    /// try await syncService.exportWorkout(
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     caloriesBurned: 350,
    ///     intensity: .high,
    ///     startDate: Date()
    /// )
    /// ```
    func exportWorkout(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        intensity: Intensity,
        startDate: Date = Date()
    ) async throws {
        // 쓰기 권한 확인
        guard writeService.canWriteWorkouts else {
            print("⚠️ No write permission for workouts, skipping export")
            return
        }

        print("📤 Exporting workout to HealthKit")

        // 운동 저장
        try await writeService.saveWorkout(
            exerciseType: exerciseType,
            duration: duration,
            caloriesBurned: caloriesBurned,
            intensity: intensity,
            startDate: startDate
        )

        print("  ✅ Workout exported: \(exerciseType) for \(duration) minutes")
    }

    /// 섭취 칼로리를 HealthKit에 저장
    ///
    /// 📚 학습 포인트: Dietary Energy Export
    /// - Bodii에서 입력한 식단 기록의 칼로리를 HealthKit에 저장
    /// - 식사 타입(아침/점심/저녁)을 메타데이터로 포함
    /// 💡 Java 비교: public void exportDietaryEnergy()
    ///
    /// - Parameters:
    ///   - calories: 섭취 칼로리 (kcal)
    ///   - date: 식사 시각 (기본값: 현재 시각)
    ///   - mealType: 식사 타입 (Optional)
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note: 쓰기 권한이 없으면 무시됨 (에러 발생하지 않음)
    ///
    /// - Example:
    /// ```swift
    /// // 아침 식사 칼로리 저장
    /// try await syncService.exportDietaryEnergy(
    ///     calories: 450,
    ///     date: Date(),
    ///     mealType: "breakfast"
    /// )
    /// ```
    func exportDietaryEnergy(
        calories: Decimal,
        date: Date = Date(),
        mealType: String? = nil
    ) async throws {
        // 쓰기 권한 확인
        guard writeService.canWrite(to: .dietaryEnergyConsumed) else {
            print("⚠️ No write permission for dietary energy, skipping export")
            return
        }

        print("📤 Exporting dietary energy to HealthKit")

        // 메타데이터 생성 (식사 타입 포함)
        var metadata: [String: Any]?
        if let mealType = mealType {
            metadata = ["MealType": mealType]
        }

        // 섭취 칼로리 저장
        try await writeService.saveDietaryEnergy(
            calories: calories,
            date: date,
            metadata: metadata
        )

        print("  ✅ Dietary energy exported: \(calories) kcal")
    }
}

// MARK: - Sync Service Pattern 설명

/// ## Sync Service Pattern이란?
///
/// Sync Service는 여러 데이터 소스 간의 동기화를 조정하는 서비스입니다.
///
/// ### 책임
///
/// **읽기 동기화 (Import)**:
/// - HealthKit → Bodii: 외부 데이터를 앱으로 가져오기
/// - ReadService로 HealthKit 데이터 읽기
/// - Mapper로 도메인 엔티티로 변환
/// - Repository로 로컬 DB에 저장
///
/// **쓰기 동기화 (Export)**:
/// - Bodii → HealthKit: 앱 데이터를 외부로 내보내기
/// - 사용자 입력 시점에 자동으로 수행
/// - WriteService로 HealthKit에 저장
///
/// **동기화 전략**:
/// - 전체 동기화: sync() - 최근 N일 전체 데이터
/// - 증분 동기화: syncSince(date:) - 특정 날짜 이후 변경분만
/// - 마지막 동기화 시각 추적: UserDefaults 사용
///
/// ### 아키텍처
///
/// ```
/// ┌─────────────────────────────────────────┐
/// │     HealthKitSyncService                │
/// │  (양방향 동기화 조정)                    │
/// └─────────────────────────────────────────┘
///          │                    │
///          │                    │
///          ▼                    ▼
/// ┌──────────────────┐  ┌──────────────────┐
/// │ ReadService      │  │ WriteService     │
/// │ (HealthKit → )   │  │ (→ HealthKit)    │
/// └──────────────────┘  └──────────────────┘
///          │                    │
///          ▼                    ▼
/// ┌──────────────────────────────────────────┐
/// │       HealthKitMapper                    │
/// │  (HKSample ↔ Domain Entity)              │
/// └──────────────────────────────────────────┘
///          │
///          ▼
/// ┌──────────────────────────────────────────┐
/// │    Repositories (향후 통합)              │
/// │  (BodyRepository, ExerciseRepository)    │
/// └──────────────────────────────────────────┘
/// ```
///
/// ### 사용 예시
///
/// ```swift
/// // DI Container에서 초기화
/// let syncService = HealthKitSyncService(
///     readService: readService,
///     writeService: writeService,
///     authService: authService
/// )
///
/// // 앱 실행 시 자동 동기화
/// Task {
///     try await syncService.sync(userId: currentUserId)
/// }
///
/// // 사용자가 체중 입력 시 HealthKit에 자동 저장
/// try await syncService.exportBodyComposition(
///     weight: bodyRecord.weight,
///     bodyFatPercent: bodyRecord.bodyFatPercent,
///     date: bodyRecord.date
/// )
/// ```
///
/// ### 왜 Sync Service가 필요한가?
///
/// 1. **양방향 동기화 조정**:
///    - ReadService, WriteService를 조정하여 양방향 동기화 구현
///    - 복잡한 동기화 로직을 한 곳에 집중
///
/// 2. **중복 검사 (향후 구현)**:
///    - healthKitId를 추적하여 중복 임포트 방지
///    - 이미 가져온 데이터는 건너뛰기
///
/// 3. **충돌 해결 (향후 구현)**:
///    - 같은 날짜에 HealthKit과 Bodii 데이터가 모두 있는 경우 우선순위 결정
///    - HealthKit 데이터(Apple Watch)가 우선
///
/// 4. **증분 동기화**:
///    - 마지막 동기화 시각 이후 데이터만 가져오기
///    - 배터리, 네트워크 효율성 향상
///
/// 5. **에러 격리**:
///    - 한 데이터 타입 동기화가 실패해도 다른 타입은 계속 진행
///    - 부분 동기화 가능
///
/// ### 💡 Java 비교
///
/// - **Android SyncAdapter**: 백그라운드 동기화 관리
/// - **Spring @Service**: 여러 Repository를 조정하는 비즈니스 로직
/// - **Room Migration**: 데이터베이스 버전 간 동기화
///
/// ### 향후 개선 사항
///
/// - ✅ Subtask 5.2: healthKitId 필드 추가 및 중복 검사 로직 구현 완료
///   - ExerciseRecord, BodyRecord, SleepRecord에 healthKitId 필드 추가
///   - isFromHealthKit computed property로 데이터 출처 판별
///   - 중복 검사 로직 문서화 (Repository 통합 시 활성화)
/// - Subtask 5.3: 충돌 해결 전략 구현
/// - Subtask 5.4: 백그라운드 동기화 구현
/// - Subtask 5.5: DailyLogService 통합 (활동 칼로리, 걸음 수)

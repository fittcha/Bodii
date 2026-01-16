//
//  HealthKitBackgroundSync.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Background Delivery
// HKObserverQuery를 사용하여 앱이 종료된 상태에서도 HealthKit 데이터 변경 감지
// 💡 Java 비교: Background Service + BroadcastReceiver 조합과 유사

import Foundation
import HealthKit

/// HealthKit background sync coordinator
///
/// HKObserverQuery와 background delivery를 사용하여 앱이 종료된 상태에서도
/// HealthKit 데이터 변경을 감지하고 동기화하는 서비스
///
/// 📚 학습 포인트: Background Delivery
/// - enableBackgroundDelivery(): HealthKit이 앱을 깨워서 데이터 변경 알림
/// - HKObserverQuery: 특정 데이터 타입의 변경 감지
/// - Background Task: 백그라운드에서 동기화 작업 수행
/// 💡 Java 비교: WorkManager + ContentObserver 조합과 유사
///
/// ## 책임
/// - HealthKit 데이터 타입별 background delivery 활성화
/// - HKObserverQuery 등록 및 관리
/// - 데이터 변경 시 동기화 트리거
/// - 앱 종료 상태에서도 동기화 수행
///
/// ## 백그라운드 동작 방식
/// 1. **Background Delivery 활성화**
///    - enableBackgroundDelivery() 호출로 각 데이터 타입에 대해 백그라운드 알림 활성화
///    - iOS가 HealthKit 데이터 변경 시 앱을 백그라운드에서 깨움
///
/// 2. **Observer Query 등록**
///    - HKObserverQuery로 각 데이터 타입 변경 감지
///    - 변경 발생 시 completionHandler 호출
///
/// 3. **동기화 실행**
///    - HealthKitSyncService를 통해 변경된 데이터만 동기화
///    - Background task에서 안전하게 실행
///
/// ## 사용 시나리오
/// 1. **앱 시작 시**: setupBackgroundObservers() 호출하여 모든 observer 등록
/// 2. **HealthKit 데이터 변경**: iOS가 앱을 깨우고 observer 호출
/// 3. **동기화 실행**: 변경된 데이터만 자동으로 동기화
/// 4. **앱 종료 시**: stopBackgroundObservers() 호출하여 리소스 정리
///
/// - Example:
/// ```swift
/// let backgroundSync = HealthKitBackgroundSync(
///     syncService: syncService,
///     authService: authService
/// )
///
/// // 백그라운드 observer 시작
/// try await backgroundSync.setupBackgroundObservers(userId: userId)
///
/// // 백그라운드 observer 중지
/// backgroundSync.stopBackgroundObservers()
/// ```
@MainActor
final class HealthKitBackgroundSync {

    // MARK: - Properties

    /// HealthKit 데이터 저장소
    ///
    /// 📚 학습 포인트: HKHealthStore
    /// - background delivery 활성화 및 observer query 등록에 필요
    /// 💡 Java 비교: ContentResolver와 유사한 역할
    private let healthStore: HKHealthStore

    /// HealthKit 동기화 서비스
    ///
    /// 📚 학습 포인트: Service Delegation
    /// - 실제 동기화 작업은 HealthKitSyncService에 위임
    /// - 백그라운드 코디네이터는 트리거 역할만 담당
    /// 💡 Java 비교: Service Layer 위임 패턴
    private let syncService: HealthKitSyncService

    /// HealthKit 권한 서비스
    ///
    /// 📚 학습 포인트: Authorization Check
    /// - 백그라운드 동기화 전에 권한 확인
    private let authService: HealthKitAuthorizationService

    /// 등록된 observer query 목록
    ///
    /// 📚 학습 포인트: Query Management
    /// - 앱 종료 시 모든 query를 정리하기 위해 추적
    /// - HKQuery는 명시적으로 stopQuery() 호출 필요
    /// 💡 Java 비교: Disposable 리스트 관리와 유사
    private var observerQueries: [HKObserverQuery] = []

    /// 백그라운드 동기화 활성화 상태
    ///
    /// 📚 학습 포인트: State Management
    /// - 중복 활성화 방지
    /// - 동기화 상태 추적
    @Published private(set) var isBackgroundSyncEnabled = false

    // MARK: - Initialization

    /// HealthKitBackgroundSync 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - 필요한 서비스를 모두 외부에서 주입받아 테스트 가능하게 설계
    /// 💡 Java 비교: Constructor Injection
    ///
    /// - Parameters:
    ///   - healthStore: HealthKit 데이터 저장소 (기본값: 새 인스턴스)
    ///   - syncService: HealthKit 동기화 서비스
    ///   - authService: HealthKit 권한 서비스
    init(
        healthStore: HKHealthStore = HKHealthStore(),
        syncService: HealthKitSyncService,
        authService: HealthKitAuthorizationService
    ) {
        self.healthStore = healthStore
        self.syncService = syncService
        self.authService = authService
    }

    // MARK: - Background Delivery Setup

    /// 백그라운드 observer 설정 및 시작
    ///
    /// 📚 학습 포인트: Background Observer Setup
    /// 1. 모든 데이터 타입에 대해 background delivery 활성화
    /// 2. 각 데이터 타입에 대해 HKObserverQuery 등록
    /// 3. 데이터 변경 시 자동으로 동기화 트리거
    ///
    /// 💡 Java 비교: ContentObserver 등록과 유사
    ///
    /// ## 동작 방식
    /// - **Background Delivery**: iOS가 HealthKit 데이터 변경 시 앱을 깨움
    /// - **Observer Query**: 변경된 데이터 타입을 감지하고 completionHandler 호출
    /// - **자동 동기화**: 변경된 데이터만 동기화하여 효율성 향상
    ///
    /// - Parameter userId: 동기화할 사용자 ID
    /// - Throws: HealthKitError - background delivery 활성화 실패 시
    ///
    /// - Note: 이 메서드는 앱 시작 시 한 번만 호출해야 함
    ///
    /// - Example:
    /// ```swift
    /// try await backgroundSync.setupBackgroundObservers(userId: currentUserId)
    /// ```
    func setupBackgroundObservers(userId: String) async throws {
        // 이미 활성화된 경우 중복 방지
        guard !isBackgroundSyncEnabled else {
            print("⚠️ Background sync already enabled")
            return
        }

        // HealthKit 사용 가능 여부 확인
        guard authService.isHealthDataAvailable() else {
            throw HealthKitError.healthKitNotAvailable
        }

        print("🔄 Setting up HealthKit background observers...")

        // 1. Background delivery 활성화
        try await enableBackgroundDelivery()

        // 2. Observer query 등록
        await registerObserverQueries(userId: userId)

        isBackgroundSyncEnabled = true
        print("✅ HealthKit background sync enabled successfully")
    }

    /// 모든 데이터 타입에 대해 background delivery 활성화
    ///
    /// 📚 학습 포인트: enableBackgroundDelivery()
    /// - HealthKit이 데이터 변경 시 앱을 백그라운드에서 깨우도록 설정
    /// - 각 데이터 타입마다 개별적으로 활성화 필요
    /// - 빈도 설정: .immediate, .hourly, .daily, .weekly 중 선택 가능
    /// 💡 Java 비교: AlarmManager.setRepeating()과 유사하지만 데이터 변경 기반
    ///
    /// - Throws: HealthKitError - background delivery 활성화 실패 시
    ///
    /// - Example:
    /// ```swift
    /// // HealthKit이 체중 데이터 변경 시 즉시 앱을 깨움
    /// try await healthStore.enableBackgroundDelivery(
    ///     for: weightType,
    ///     frequency: .immediate
    /// )
    /// ```
    private func enableBackgroundDelivery() async throws {
        print("  📡 Enabling background delivery for all data types...")

        // Quantity types에 대해 background delivery 활성화
        for quantityType in HealthKitDataTypes.QuantityType.allCases {
            guard let hkType = quantityType.hkQuantityType else { continue }

            do {
                try await healthStore.enableBackgroundDelivery(
                    for: hkType,
                    frequency: .immediate
                )
                print("    ✅ Enabled for \(quantityType.displayName)")
            } catch {
                print("    ⚠️ Failed to enable for \(quantityType.displayName): \(error)")
                // 개별 타입 실패는 전체 실패로 간주하지 않음
                // 일부 타입만 권한이 있을 수 있음
            }
        }

        // Category types에 대해 background delivery 활성화
        for categoryType in HealthKitDataTypes.CategoryType.allCases {
            guard let hkType = categoryType.hkCategoryType else { continue }

            do {
                try await healthStore.enableBackgroundDelivery(
                    for: hkType,
                    frequency: .immediate
                )
                print("    ✅ Enabled for \(categoryType.displayName)")
            } catch {
                print("    ⚠️ Failed to enable for \(categoryType.displayName): \(error)")
            }
        }

        // Workout type에 대해 background delivery 활성화
        do {
            try await healthStore.enableBackgroundDelivery(
                for: HealthKitDataTypes.workoutType,
                frequency: .immediate
            )
            print("    ✅ Enabled for Workout")
        } catch {
            print("    ⚠️ Failed to enable for Workout: \(error)")
        }
    }

    /// 모든 데이터 타입에 대해 observer query 등록
    ///
    /// 📚 학습 포인트: HKObserverQuery
    /// - 특정 데이터 타입의 변경을 감지하는 쿼리
    /// - updateHandler: 데이터 변경 시 호출되는 클로저
    /// - Background에서도 실행 가능
    /// 💡 Java 비교: ContentObserver.onChange()와 유사
    ///
    /// ## Observer Query 동작 방식
    /// 1. **등록**: HKObserverQuery 생성 및 execute
    /// 2. **대기**: HealthKit이 데이터 변경 감지
    /// 3. **알림**: updateHandler 호출 (앱이 깨어있지 않으면 iOS가 깨움)
    /// 4. **동기화**: 변경된 데이터만 동기화
    /// 5. **완료**: completionHandler 호출로 iOS에 완료 알림
    ///
    /// - Parameter userId: 동기화할 사용자 ID
    ///
    /// - Example:
    /// ```swift
    /// let query = HKObserverQuery(sampleType: weightType) { query, handler, error in
    ///     // 체중 데이터 변경 시 호출됨
    ///     await self.handleDataUpdate(for: weightType, userId: userId)
    ///     handler() // iOS에 완료 알림
    /// }
    /// healthStore.execute(query)
    /// ```
    private func registerObserverQueries(userId: String) async {
        print("  👀 Registering observer queries...")

        // Quantity types에 대해 observer 등록
        for quantityType in HealthKitDataTypes.QuantityType.allCases {
            guard let hkType = quantityType.hkQuantityType else { continue }
            registerObserver(for: hkType, typeName: quantityType.displayName, userId: userId)
        }

        // Category types에 대해 observer 등록
        for categoryType in HealthKitDataTypes.CategoryType.allCases {
            guard let hkType = categoryType.hkCategoryType else { continue }
            registerObserver(for: hkType, typeName: categoryType.displayName, userId: userId)
        }

        // Workout type에 대해 observer 등록
        registerObserver(for: HealthKitDataTypes.workoutType, typeName: "Workout", userId: userId)

        print("  ✅ Registered \(observerQueries.count) observer queries")
    }

    /// 특정 데이터 타입에 대해 observer query 등록
    ///
    /// 📚 학습 포인트: Observer Pattern
    /// - 데이터 변경 시 자동으로 콜백 호출
    /// - Background에서도 실행됨
    /// 💡 Java 비교: Observer 패턴 + Callback
    ///
    /// - Parameters:
    ///   - sampleType: 관찰할 HealthKit 샘플 타입
    ///   - typeName: 로깅용 타입 이름
    ///   - userId: 동기화할 사용자 ID
    private func registerObserver(
        for sampleType: HKSampleType,
        typeName: String,
        userId: String
    ) {
        // HKObserverQuery 생성
        //
        // 📚 학습 포인트: HKObserverQuery 생성
        // - sampleType: 관찰할 데이터 타입
        // - predicate: 필터 조건 (nil = 모든 데이터)
        // - updateHandler: 데이터 변경 시 호출되는 클로저
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else {
                completionHandler()
                return
            }

            // 에러 처리
            if let error = error {
                print("    ⚠️ Observer error for \(typeName): \(error.localizedDescription)")
                completionHandler()
                return
            }

            print("  🔔 HealthKit data changed: \(typeName)")

            // 백그라운드에서 동기화 실행
            Task { @MainActor in
                await self.handleDataUpdate(for: sampleType, typeName: typeName, userId: userId)
                // iOS에 작업 완료 알림
                // 📚 학습 포인트: Completion Handler
                // - iOS에 백그라운드 작업이 완료되었음을 알림
                // - 호출하지 않으면 iOS가 앱을 종료하지 못함
                completionHandler()
            }
        }

        // Observer query 실행
        healthStore.execute(query)
        observerQueries.append(query)

        print("    👀 Observer registered for \(typeName)")
    }

    // MARK: - Data Update Handling

    /// 데이터 변경 시 동기화 처리
    ///
    /// 📚 학습 포인트: Background Sync Trigger
    /// - Observer가 감지한 데이터 변경에 대해 동기화 수행
    /// - 마지막 동기화 이후 데이터만 가져와서 효율성 향상
    /// - Background에서 안전하게 실행
    /// 💡 Java 비교: onReceive() + AsyncTask 조합과 유사
    ///
    /// - Parameters:
    ///   - sampleType: 변경된 데이터 타입
    ///   - typeName: 로깅용 타입 이름
    ///   - userId: 동기화할 사용자 ID
    private func handleDataUpdate(
        for sampleType: HKSampleType,
        typeName: String,
        userId: String
    ) async {
        print("  🔄 Syncing \(typeName) data...")

        do {
            // 📚 학습 포인트: Incremental Sync
            // - 마지막 동기화 시각 이후 데이터만 가져옴
            // - 전체 동기화보다 훨씬 효율적
            // - 배터리 및 네트워크 리소스 절약
            let lastSyncDate = syncService.getLastSyncDate() ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)

            try await syncService.syncSince(
                date: lastSyncDate,
                userId: userId
            )

            print("  ✅ Sync completed for \(typeName)")
        } catch {
            print("  ❌ Sync failed for \(typeName): \(error.localizedDescription)")
            // 백그라운드 동기화 실패는 치명적이지 않음
            // 다음 기회에 다시 시도
        }
    }

    // MARK: - Background Delivery Teardown

    /// 백그라운드 observer 중지 및 정리
    ///
    /// 📚 학습 포인트: Resource Cleanup
    /// - 앱 종료 시 또는 사용자가 HealthKit 동기화를 비활성화할 때 호출
    /// - 모든 observer query 중지
    /// - Background delivery 비활성화
    /// 💡 Java 비교: onDestroy() + unregisterReceiver()와 유사
    ///
    /// - Note: 이 메서드는 앱 종료 시 또는 설정에서 비활성화 시 호출
    ///
    /// - Example:
    /// ```swift
    /// // 설정에서 HealthKit 동기화 비활성화 시
    /// backgroundSync.stopBackgroundObservers()
    /// ```
    func stopBackgroundObservers() {
        guard isBackgroundSyncEnabled else {
            print("⚠️ Background sync already disabled")
            return
        }

        print("🛑 Stopping HealthKit background observers...")

        // 1. 모든 observer query 중지
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()

        // 2. Background delivery 비활성화
        Task {
            await disableBackgroundDelivery()
        }

        isBackgroundSyncEnabled = false
        print("✅ HealthKit background sync disabled successfully")
    }

    /// 모든 데이터 타입에 대해 background delivery 비활성화
    ///
    /// 📚 학습 포인트: disableBackgroundDelivery()
    /// - HealthKit이 더 이상 앱을 깨우지 않도록 설정
    /// - 배터리 절약 및 리소스 해제
    /// 💡 Java 비교: AlarmManager.cancel()과 유사
    private func disableBackgroundDelivery() async {
        print("  📡 Disabling background delivery for all data types...")

        // Quantity types에 대해 background delivery 비활성화
        for quantityType in HealthKitDataTypes.QuantityType.allCases {
            guard let hkType = quantityType.hkQuantityType else { continue }

            do {
                try await healthStore.disableBackgroundDelivery(for: hkType)
                print("    ✅ Disabled for \(quantityType.displayName)")
            } catch {
                print("    ⚠️ Failed to disable for \(quantityType.displayName): \(error)")
            }
        }

        // Category types에 대해 background delivery 비활성화
        for categoryType in HealthKitDataTypes.CategoryType.allCases {
            guard let hkType = categoryType.hkCategoryType else { continue }

            do {
                try await healthStore.disableBackgroundDelivery(for: hkType)
                print("    ✅ Disabled for \(categoryType.displayName)")
            } catch {
                print("    ⚠️ Failed to disable for \(categoryType.displayName): \(error)")
            }
        }

        // Workout type에 대해 background delivery 비활성화
        do {
            try await healthStore.disableBackgroundDelivery(for: HealthKitDataTypes.workoutType)
            print("    ✅ Disabled for Workout")
        } catch {
            print("    ⚠️ Failed to disable for Workout: \(error)")
        }
    }
}

// MARK: - HealthKitDataTypes Extension

extension HealthKitDataTypes.QuantityType: CaseIterable {
    /// 📚 학습 포인트: CaseIterable
    /// - enum의 모든 case를 순회할 수 있게 만듦
    /// - allCases 프로퍼티 자동 생성
    /// 💡 Java 비교: Enum.values()와 유사
    static var allCases: [HealthKitDataTypes.QuantityType] {
        return [.weight, .bodyFatPercentage, .activeEnergyBurned, .stepCount, .dietaryEnergyConsumed]
    }
}

extension HealthKitDataTypes.CategoryType: CaseIterable {
    static var allCases: [HealthKitDataTypes.CategoryType] {
        return [.sleepAnalysis]
    }
}

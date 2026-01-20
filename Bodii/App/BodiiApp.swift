//
//  BodiiApp.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: SwiftUI App Lifecycle
// iOS 14+에서는 App protocol 기반 진입점 사용
// 💡 Java 비교: main() 메서드 대신 App struct 사용

import SwiftUI
import HealthKit

// MARK: - App Entry Point

@main
struct BodiiApp: App {

    // MARK: - Properties

    // 📚 학습 포인트: @StateObject
    // App 생명주기 동안 유지되는 상태 객체
    // Core Data의 PersistenceController를 앱 전역에서 사용
    private let persistenceController = PersistenceController.shared

    // 📚 학습 포인트: @State for Background Sync
    // 백그라운드 동기화 상태 추적
    // 💡 Java 비교: Application 레벨 변수와 유사
    @State private var healthKitBackgroundSync: HealthKitBackgroundSync?

    // MARK: - Initialization

    init() {
        // 📚 학습 포인트: App Initialization
        // HealthKit 서비스 초기화는 앱 시작 시 한 번만 수행
        // 💡 Java 비교: Application.onCreate()와 유사
        // TODO: Phase 6 - DIContainer에 HealthKit 서비스 체인 구현 후 활성화
        // setupHealthKitBackgroundSync()
    }

    // MARK: - Body

    // 📚 학습 포인트: some Scene
    // WindowGroup은 플랫폼에 맞는 윈도우 관리 제공
    // iOS: 단일 윈도우, macOS: 다중 윈도우 지원
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 📚 학습 포인트: Environment
                // managedObjectContext를 View 계층 전체에 주입
                // 하위 뷰에서 @Environment(\.managedObjectContext)로 접근 가능
                .environment(\.managedObjectContext, persistenceController.viewContext)
                // 📚 학습 포인트: onAppear
                // View가 화면에 나타날 때 HealthKit 백그라운드 동기화 시작
                // 💡 Java 비교: Activity.onStart()와 유사
                // TODO: Phase 6 - DIContainer에 HealthKit 서비스 체인 구현 후 활성화
                // .onAppear {
                //     Task {
                //         await startHealthKitBackgroundSync()
                //     }
                // }
        }
    }

    // MARK: - HealthKit Background Sync

    /// HealthKit 백그라운드 동기화 초기화
    ///
    /// 📚 학습 포인트: Service Initialization via DIContainer
    /// - DIContainer를 통해 HealthKit 서비스 주입
    /// - lazy initialization으로 필요할 때만 생성
    /// - 단일 인스턴스 재사용으로 메모리 효율적
    /// 💡 Java 비교: @Autowired Service 초기화와 유사
    ///
    /// TODO: Phase 6에서 DIContainer에 HealthKit 서비스 체인 구현 후 활성화
    private func setupHealthKitBackgroundSync() {
        // HealthKit 사용 가능 여부 확인
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit is not available on this device")
            return
        }

        // TODO: Phase 6 - DIContainer에 healthKitBackgroundSync 프로퍼티 추가 후 활성화
        // 📚 학습 포인트: DIContainer Dependency Injection
        // DIContainer가 모든 의존성 체인을 관리
        // healthStore → authService → readService → writeService → syncService → backgroundSync
        // 💡 Java 비교: Spring @Autowired 의존성 체인과 유사
        // let container = DIContainer.shared
        // healthKitBackgroundSync = container.healthKitBackgroundSync

        print("⏸️ HealthKit background sync - pending DIContainer implementation (Phase 6)")
    }

    /// HealthKit 백그라운드 동기화 시작
    ///
    /// 📚 학습 포인트: Async Initialization
    /// - 앱 실행 시 백그라운드 observer 등록
    /// - 권한이 없으면 조용히 실패 (사용자가 설정에서 활성화할 때까지 대기)
    /// 💡 Java 비교: Background Service 시작과 유사
    ///
    /// - Note: 권한이 없어도 에러를 던지지 않음 (사용자가 나중에 활성화할 수 있음)
    @MainActor
    private func startHealthKitBackgroundSync() async {
        guard let backgroundSync = healthKitBackgroundSync else {
            print("⚠️ HealthKit background sync not initialized")
            return
        }

        // 📚 학습 포인트: Default User ID
        // 현재는 단일 사용자 앱이므로 "default" 사용
        // TODO: Phase 7에서 실제 사용자 인증 시스템 통합 시 userId 전달
        // 💡 Java 비교: SharedPreferences에서 userId 가져오기와 유사
        let userId = "default"

        do {
            // 📚 학습 포인트: Background Observer Setup
            // - HealthKit 데이터 변경 시 자동으로 앱을 깨워서 동기화
            // - 권한이 허용된 경우에만 작동
            // 💡 Java 비교: WorkManager 등록과 유사
            try await backgroundSync.setupBackgroundObservers(userId: userId)
            print("✅ HealthKit background observers started successfully")
        } catch HealthKitError.healthKitNotAvailable {
            print("⚠️ HealthKit not available on this device")
        } catch HealthKitError.authorizationDenied {
            print("ℹ️ HealthKit permission not granted yet (user will enable in settings)")
        } catch {
            print("⚠️ Failed to start HealthKit background sync: \(error.localizedDescription)")
            // 백그라운드 동기화 실패는 치명적이지 않음
            // 사용자가 설정에서 활성화할 때까지 대기
        }
    }
}

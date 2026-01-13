//
//  DIContainer.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Dependency Injection Container
// 앱 전체에서 사용되는 의존성들을 중앙에서 관리하는 컨테이너
// 💡 Java 비교: Dagger/Hilt의 Component와 유사한 역할

import Foundation

// MARK: - DI Container

/// 의존성 주입 컨테이너
/// 📚 학습 포인트: Singleton Pattern
/// 앱 전역에서 단일 인스턴스를 통해 의존성에 접근
/// 💡 Java 비교: static getInstance() 패턴과 유사하지만 더 간결
final class DIContainer {

    // MARK: - Singleton

    /// 공유 인스턴스
    /// 📚 학습 포인트: static let
    /// Swift에서 싱글톤은 static let으로 간단히 구현
    /// Thread-safe하게 한 번만 초기화됨 (Swift 런타임 보장)
    static let shared = DIContainer()

    // MARK: - Initialization

    /// private init으로 외부 인스턴스화 방지
    /// 📚 학습 포인트: Access Control
    /// private init은 외부에서 new를 막아 싱글톤 보장
    /// 💡 Java 비교: private constructor와 동일
    private init() {}

    // MARK: - Infrastructure

    // 📚 학습 포인트: lazy var
    // 처음 접근할 때만 초기화되는 프로퍼티
    // 무거운 객체의 지연 초기화에 유용
    // 💡 Java 비교: Lazy initialization pattern

    /// Persistence Controller (Core Data)
    /// ⚠️ 주의: PersistenceController는 별도로 shared 인스턴스 관리

    // MARK: - Data Sources

    // TODO: Phase 2에서 추가 예정
    // - NetworkManager
    // - HealthKitManager
    // - FoodAPIDataSource
    // - GeminiAPIDataSource

    // MARK: - Repositories

    /// 사용자 Repository
    /// 📚 학습 포인트: lazy var로 지연 초기화
    /// 처음 접근할 때만 생성되어 메모리 효율적
    lazy var userRepository: UserRepository = {
        let context = PersistenceController.shared.container.viewContext
        return UserRepository(context: context)
    }()

    /// 운동 기록 Repository
    lazy var exerciseRecordRepository: ExerciseRecordRepository = {
        let context = PersistenceController.shared.container.viewContext
        return ExerciseRecordRepository(context: context)
    }()

    /// 일일 집계 Repository
    lazy var dailyLogRepository: DailyLogRepository = {
        let context = PersistenceController.shared.container.viewContext
        return DailyLogRepository(context: context)
    }()

    // TODO: Phase 3에서 추가 예정
    // - BodyRepository
    // - FoodRepository
    // - SleepRepository
    // - GoalRepository

    // MARK: - Services

    /// 운동 칼로리 계산 서비스
    /// 📚 학습 포인트: Static Service
    /// ExerciseCalcService는 enum with static methods이므로
    /// 인스턴스화 불필요 (직접 ExerciseCalcService.calculateCaloriesBurned 호출)

    /// 운동 기록 서비스
    /// 📚 학습 포인트: Service with Dependencies
    /// 여러 Repository를 조합하여 비즈니스 로직 처리
    lazy var exerciseRecordService: ExerciseRecordService = {
        return ExerciseRecordService(
            exerciseRecordRepository: exerciseRecordRepository,
            dailyLogRepository: dailyLogRepository,
            userRepository: userRepository
        )
    }()

    // MARK: - Use Cases

    // TODO: Phase 4에서 추가 예정
    // - CalculateBMRUseCase
    // - CalculateTDEEUseCase
    // - RecordBodyUseCase
    // - SearchFoodUseCase
    // - etc.

    // MARK: - View Models

    // TODO: Phase 5에서 추가 예정
    // - OnboardingViewModel
    // - DashboardViewModel
    // - BodyViewModel
    // - etc.
}

// MARK: - Factory Methods

extension DIContainer {

    // 📚 학습 포인트: Factory Pattern
    // 의존성 생성 로직을 캡슐화
    // 테스트 시 Mock 객체로 교체 가능

    // MARK: - Exercise Feature

    /// 운동 목록 ViewModel 생성
    /// 📚 학습 포인트: Factory Method
    /// ViewModel 생성 시 필요한 의존성을 주입
    /// 테스트 시 Mock으로 교체 가능
    func makeExerciseViewModel() -> ExerciseViewModel {
        return ExerciseViewModel(exerciseRecordService: exerciseRecordService)
    }

    /// 운동 입력 ViewModel 생성
    /// 📚 학습 포인트: Factory Method with Parameters
    /// 기존 운동 레코드를 받아 편집 모드 지원
    ///
    /// - Parameter existingRecord: 편집할 기존 운동 레코드 (nil이면 생성 모드)
    /// - Returns: 생성된 ExerciseInputViewModel
    func makeExerciseInputViewModel(existingRecord: ExerciseRecord? = nil) -> ExerciseInputViewModel {
        return ExerciseInputViewModel(
            exerciseRecordService: exerciseRecordService,
            existingRecord: existingRecord
        )
    }

    // TODO: 각 Feature 구현 시 Factory 메서드 추가
    // func makeOnboardingViewModel() -> OnboardingViewModel
    // func makeDashboardViewModel() -> DashboardViewModel
    // func makeBodyViewModel() -> BodyViewModel
}

// MARK: - Testing Support

#if DEBUG
extension DIContainer {

    /// 테스트용 컨테이너 생성
    /// 📚 학습 포인트: #if DEBUG
    /// 디버그 빌드에서만 포함되는 코드
    /// 프로덕션 빌드 크기와 보안에 영향 없음
    /// 💡 Java 비교: BuildConfig.DEBUG 체크와 유사
    static func makeForTesting() -> DIContainer {
        return DIContainer()
    }
}
#endif

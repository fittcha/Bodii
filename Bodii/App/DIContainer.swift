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

    /// 운동 기록 로컬 데이터 소스
    /// 📚 학습 포인트: lazy var
    /// 처음 접근할 때만 초기화되며, 이후에는 캐시된 인스턴스 반환
    lazy var exerciseRecordLocalDataSource: ExerciseRecordLocalDataSource = {
        ExerciseRecordLocalDataSource(context: PersistenceController.shared.viewContext)
    }()

    /// 일일 기록 로컬 데이터 소스
    lazy var dailyLogLocalDataSource: DailyLogLocalDataSource = {
        DailyLogLocalDataSource(context: PersistenceController.shared.viewContext)
    }()

    // TODO: Phase 2에서 추가 예정
    // - NetworkManager
    // - HealthKitManager
    // - FoodAPIDataSource
    // - GeminiAPIDataSource

    // MARK: - Repositories

    /// 운동 기록 저장소
    /// 📚 학습 포인트: Protocol을 타입으로 사용
    /// 테스트 시 Mock으로 교체 가능하도록 프로토콜 타입 사용
    /// 💡 Java 비교: Interface 타입으로 필드 선언하는 것과 동일
    lazy var exerciseRecordRepository: ExerciseRecordRepository = {
        ExerciseRecordRepositoryImpl(localDataSource: exerciseRecordLocalDataSource)
    }()

    /// 일일 기록 저장소
    lazy var dailyLogRepository: DailyLogRepository = {
        DailyLogRepositoryImpl(localDataSource: dailyLogLocalDataSource)
    }()

    // TODO: Phase 3에서 추가 예정
    // - UserRepository
    // - BodyRepository
    // - FoodRepository
    // - SleepRepository
    // - GoalRepository

    // MARK: - Services

    /// 일일 기록 관리 서비스
    /// 📚 학습 포인트: Service Layer
    /// Repository를 조합하여 복잡한 비즈니스 로직 처리
    lazy var dailyLogService: DailyLogService = {
        DailyLogService(repository: dailyLogRepository)
    }()

    // 📚 학습 포인트: ExerciseCalcService는 enum이므로 등록 불필요
    // static 메서드만 있어서 인스턴스화할 필요 없음
    // 💡 Java 비교: Utility 클래스의 static 메서드와 유사

    // MARK: - Use Cases

    /// 운동 기록 추가 유스케이스
    /// 📚 학습 포인트: Use Case Pattern
    /// 단일 책임 원칙 - 하나의 Use Case는 하나의 비즈니스 액션만 담당
    lazy var addExerciseRecordUseCase: AddExerciseRecordUseCase = {
        AddExerciseRecordUseCase(
            exerciseRepository: exerciseRecordRepository,
            dailyLogService: dailyLogService
        )
    }()

    /// 운동 기록 수정 유스케이스
    lazy var updateExerciseRecordUseCase: UpdateExerciseRecordUseCase = {
        UpdateExerciseRecordUseCase(
            exerciseRepository: exerciseRecordRepository,
            dailyLogService: dailyLogService
        )
    }()

    /// 운동 기록 삭제 유스케이스
    lazy var deleteExerciseRecordUseCase: DeleteExerciseRecordUseCase = {
        DeleteExerciseRecordUseCase(
            exerciseRepository: exerciseRecordRepository,
            dailyLogService: dailyLogService
        )
    }()

    /// 운동 기록 조회 유스케이스
    lazy var getExerciseRecordsUseCase: GetExerciseRecordsUseCase = {
        GetExerciseRecordsUseCase(exerciseRepository: exerciseRecordRepository)
    }()

    // TODO: Phase 4에서 추가 예정
    // - CalculateBMRUseCase
    // - CalculateTDEEUseCase
    // - RecordBodyUseCase
    // - SearchFoodUseCase
    // - etc.
}

// MARK: - Factory Methods

extension DIContainer {

    // 📚 학습 포인트: Factory Pattern
    // 의존성 생성 로직을 캡슐화
    // 테스트 시 Mock 객체로 교체 가능

    // MARK: - Exercise ViewModels

    /// 운동 목록 ViewModel 생성
    ///
    /// 📚 학습 포인트: Factory Method Pattern
    /// ViewModel 생성 시 필요한 모든 의존성을 주입
    /// 테스트 시 이 메서드만 오버라이드하면 Mock ViewModel 제공 가능
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 의존성이 주입된 ExerciseListViewModel
    ///
    /// - Example:
    /// ```swift
    /// let viewModel = DIContainer.shared.makeExerciseListViewModel(userId: user.id)
    /// ExerciseListView(viewModel: viewModel)
    /// ```
    func makeExerciseListViewModel(userId: UUID) -> ExerciseListViewModel {
        ExerciseListViewModel(
            getExerciseRecordsUseCase: getExerciseRecordsUseCase,
            deleteExerciseRecordUseCase: deleteExerciseRecordUseCase,
            dailyLogRepository: dailyLogRepository,
            userId: userId
        )
    }

    /// 운동 입력 ViewModel 생성
    ///
    /// 📚 학습 포인트: 외부 파라미터가 많은 Factory Method
    /// ViewModel이 사용자별 데이터(체중, BMR, TDEE)를 필요로 할 때
    /// Factory Method로 깔끔하게 주입
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - userWeight: 사용자 체중 (kg) - 칼로리 계산에 필요
    ///   - userBMR: 사용자 기초대사량 (kcal)
    ///   - userTDEE: 사용자 활동대사량 (kcal)
    ///   - editingExercise: 편집할 운동 기록 (편집 모드일 때만 제공)
    /// - Returns: 의존성이 주입된 ExerciseInputViewModel
    ///
    /// - Example:
    /// ```swift
    /// // 추가 모드
    /// let viewModel = DIContainer.shared.makeExerciseInputViewModel(
    ///     userId: user.id,
    ///     userWeight: user.currentWeight ?? 70.0,
    ///     userBMR: user.currentBMR ?? 1650,
    ///     userTDEE: user.currentTDEE ?? 2310
    /// )
    ///
    /// // 편집 모드
    /// let viewModel = DIContainer.shared.makeExerciseInputViewModel(
    ///     userId: user.id,
    ///     userWeight: 70.0,
    ///     userBMR: 1650,
    ///     userTDEE: 2310,
    ///     editingExercise: exercise
    /// )
    /// ```
    func makeExerciseInputViewModel(
        userId: UUID,
        userWeight: Decimal,
        userBMR: Int32,
        userTDEE: Int32,
        editingExercise: ExerciseRecord? = nil
    ) -> ExerciseInputViewModel {
        ExerciseInputViewModel(
            addExerciseRecordUseCase: addExerciseRecordUseCase,
            updateExerciseRecordUseCase: editingExercise != nil ? updateExerciseRecordUseCase : nil,
            userId: userId,
            userWeight: userWeight,
            userBMR: userBMR,
            userTDEE: userTDEE,
            editingExercise: editingExercise
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

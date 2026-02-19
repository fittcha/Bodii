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
import HealthKit

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

    /// Body composition 로컬 데이터 소스
    /// 📚 학습 포인트: Lazy Initialization
    /// 첫 접근 시 한 번만 생성되어 재사용됨
    /// 💡 Java 비교: @Lazy + @Autowired와 유사
    lazy var bodyLocalDataSource: BodyLocalDataSource = {
        return BodyLocalDataSource(persistenceController: .shared)
    }()

    /// Sleep tracking 로컬 데이터 소스
    /// 📚 학습 포인트: Lazy Initialization
    /// 첫 접근 시 한 번만 생성되어 재사용됨
    /// 💡 Java 비교: @Lazy + @Autowired와 유사
    lazy var sleepLocalDataSource: SleepLocalDataSource = {
        return SleepLocalDataSource(persistenceController: .shared)
    }()

    /// Goal 로컬 데이터 소스
    /// 📚 학습 포인트: Lazy Initialization
    /// 첫 접근 시 한 번만 생성되어 재사용됨
    /// 💡 Java 비교: @Lazy + @Autowired와 유사
    lazy var goalLocalDataSource: GoalLocalDataSource = {
        return GoalLocalDataSource(persistenceController: .shared)
    }()

    // MARK: - HealthKit Infrastructure

    /// HealthKit 데이터 저장소
    /// 📚 학습 포인트: Lazy Initialization
    /// - HealthKit 사용 가능 여부와 무관하게 생성
    /// - 실제 사용 시 availabilty 체크 필요
    lazy var healthStore: HKHealthStore = {
        return HKHealthStore()
    }()

    /// HealthKit 권한 서비스
    /// 📚 학습 포인트: Authorization Service
    /// - HealthKit 권한 요청 및 상태 확인 담당
    lazy var healthKitAuthService: HealthKitAuthorizationService = {
        return HealthKitAuthorizationService(healthStore: healthStore)
    }()

    /// HealthKit 읽기 서비스
    /// 📚 학습 포인트: Read Service
    /// - HealthKit에서 데이터를 읽어오는 서비스
    lazy var healthKitReadService: HealthKitReadService = {
        return HealthKitReadService(healthStore: healthStore)
    }()

    /// HealthKit 쓰기 서비스
    /// 📚 학습 포인트: Write Service
    /// - HealthKit에 데이터를 저장하는 서비스
    lazy var healthKitWriteService: HealthKitWriteService = {
        return HealthKitWriteService(healthStore: healthStore)
    }()

    /// HealthKit 동기화 서비스
    /// 📚 학습 포인트: Sync Service
    /// - HealthKit과 Bodii 데이터 양방향 동기화
    lazy var healthKitSyncService: HealthKitSyncService = {
        return HealthKitSyncService(
            readService: healthKitReadService,
            writeService: healthKitWriteService,
            authService: healthKitAuthService
        )
    }()

    /// HealthKit 백그라운드 동기화 서비스
    /// 📚 학습 포인트: Background Sync
    /// - 앱이 종료된 상태에서도 HealthKit 데이터 변경 감지 및 동기화
    @MainActor
    lazy var healthKitBackgroundSync: HealthKitBackgroundSync = {
        return HealthKitBackgroundSync(
            healthStore: healthStore,
            syncService: healthKitSyncService,
            authService: healthKitAuthService
        )
    }()

    // MARK: - Repositories

    /// Body composition 리포지토리
    /// 📚 학습 포인트: Dependency Injection Chain
    /// bodyLocalDataSource를 주입받아 생성
    /// 💡 Java 비교: @Autowired Repository와 유사
    lazy var bodyRepository: BodyRepositoryProtocol = {
        return BodyRepository(localDataSource: bodyLocalDataSource)
    }()

    /// Sleep tracking 리포지토리
    /// 📚 학습 포인트: Dependency Injection Chain
    /// sleepLocalDataSource를 주입받아 생성
    /// 💡 Java 비교: @Autowired Repository와 유사
    lazy var sleepRepository: SleepRepositoryProtocol = {
        return SleepRepository(localDataSource: sleepLocalDataSource)
    }()

    /// Goal 리포지토리
    /// 📚 학습 포인트: Dependency Injection Chain
    /// goalLocalDataSource를 주입받아 생성
    /// 💡 Java 비교: @Autowired Repository와 유사
    lazy var goalRepository: GoalRepositoryProtocol = {
        return GoalRepository(localDataSource: goalLocalDataSource)
    }()

    // MARK: - Exercise Infrastructure

    /// Exercise 로컬 데이터 소스
    lazy var exerciseLocalDataSource: ExerciseRecordLocalDataSource = {
        return ExerciseRecordLocalDataSource(context: PersistenceController.shared.container.viewContext)
    }()

    /// DailyLog 로컬 데이터 소스
    lazy var dailyLogLocalDataSource: DailyLogLocalDataSource = {
        return DailyLogLocalDataSource(context: PersistenceController.shared.container.viewContext)
    }()

    /// Exercise 리포지토리
    lazy var exerciseRepository: ExerciseRecordRepository = {
        return ExerciseRecordRepositoryImpl(localDataSource: exerciseLocalDataSource)
    }()

    /// DailyLog 리포지토리
    lazy var dailyLogRepository: DailyLogRepository = {
        return DailyLogRepositoryImpl(localDataSource: dailyLogLocalDataSource)
    }()

    /// DailyLog 서비스
    lazy var dailyLogService: DailyLogService = {
        return DailyLogService(
            repository: dailyLogRepository,
            healthKitReadService: healthKitReadService
        )
    }()

    /// User 리포지토리
    /// 📚 학습 포인트: User Data Access
    /// - 현재 사용자 정보 조회
    /// - User → UserProfile 변환
    lazy var userRepository: UserRepository = {
        return UserRepository()
    }()

    /// Food 리포지토리 (음식 데이터 CRUD)
    lazy var foodRepository: FoodRepositoryProtocol = {
        return FoodRepository(context: PersistenceController.shared.container.viewContext)
    }()

    /// Food 로컬 캐시 데이터 소스
    lazy var foodLocalDataSource: FoodLocalDataSource = {
        return FoodLocalDataSourceImpl(persistenceController: .shared)
    }()

    /// 통합 식품 검색 API 서비스 (KFDA + USDA)
    lazy var unifiedFoodSearchService: UnifiedFoodSearchService = {
        return UnifiedFoodSearchService(context: PersistenceController.shared.container.viewContext)
    }()

    /// 하이브리드 음식 검색 서비스 (로컬 + API 병렬 검색)
    lazy var hybridFoodSearchService: HybridFoodSearchService = {
        let localService = LocalFoodSearchService(
            foodRepository: foodRepository,
            apiSearchService: unifiedFoodSearchService,
            cacheDataSource: foodLocalDataSource
        )
        return HybridFoodSearchService(
            localService: localService,
            apiService: unifiedFoodSearchService,
            foodRepository: foodRepository,
            context: PersistenceController.shared.container.viewContext
        )
    }()

    /// 음식 검색 서비스 (검색 버튼 탭 시 사용)
    lazy var foodSearchService: FoodSearchServiceProtocol = {
        return hybridFoodSearchService
    }()

    /// 최근/자주 사용 음식 서비스
    lazy var recentFoodsService: RecentFoodsServiceProtocol = {
        return RecentFoodsService(foodRepository: foodRepository)
    }()

    /// FoodRecord 리포지토리
    /// - 식단 기록 CRUD
    /// - 날짜별 식단 조회
    lazy var foodRecordRepository: FoodRecordRepositoryProtocol = {
        return FoodRecordRepository(context: PersistenceController.shared.container.viewContext)
    }()

    /// DietComment 캐시
    /// 📚 학습 포인트: In-Memory Cache
    /// - AI 식단 코멘트 캐싱
    /// - LRU 정책, 24시간 만료
    lazy var dietCommentCache: DietCommentCache = {
        return DietCommentCache()
    }()

    /// DietComment 리포지토리
    /// 📚 학습 포인트: AI Service Repository
    /// - AI 식단 코멘트 생성 및 캐싱
    /// - Gemini API 연동
    lazy var dietCommentRepository: DietCommentRepository = {
        return DietCommentRepositoryImpl(
            geminiService: geminiService,
            cache: dietCommentCache,
            foodRecordRepository: foodRecordRepository,
            dailyLogLocalDataSource: dailyLogLocalDataSource
        )
    }()

    /// Gemini AI 서비스
    /// 📚 학습 포인트: AI Service
    /// - AI 식단 코멘트 생성
    lazy var geminiService: GeminiServiceProtocol = {
        return GeminiService()
    }()

    // MARK: - Use Cases

    /// BMR 계산 Use Case
    /// 📚 학습 포인트: Stateless Use Case
    /// struct이므로 매번 새로 생성해도 무방하지만 lazy로 재사용
    /// 💡 Java 비교: @Service 싱글톤 빈과 유사
    lazy var calculateBMRUseCase = CalculateBMRUseCase()

    /// TDEE 계산 Use Case
    /// 📚 학습 포인트: Stateless Use Case
    /// struct이므로 매번 새로 생성해도 무방하지만 lazy로 재사용
    /// 💡 Java 비교: @Service 싱글톤 빈과 유사
    lazy var calculateTDEEUseCase = CalculateTDEEUseCase()

    /// Body composition 기록 Use Case
    /// 📚 학습 포인트: Orchestration Use Case with Dependencies
    /// 여러 Use Case와 Repository를 조합하여 복잡한 비즈니스 로직 구현
    /// - BMR/TDEE 자동 계산 (하이브리드 공식: 체지방률 유무에 따라 공식 선택)
    /// - User 엔티티의 currentWeight, currentBMR 등 자동 업데이트
    /// 💡 Java 비교: @Service with @Autowired dependencies
    lazy var recordBodyCompositionUseCase: RecordBodyCompositionUseCase = {
        return RecordBodyCompositionUseCase(
            calculateBMRUseCase: calculateBMRUseCase,
            calculateTDEEUseCase: calculateTDEEUseCase,
            bodyRepository: bodyRepository,
            userRepository: userRepository
        )
    }()

    /// Body trends 조회 Use Case
    /// 📚 학습 포인트: Query Use Case
    /// 차트 표시를 위한 데이터 조회 및 변환
    /// 💡 Java 비교: @Service with read-only operations
    lazy var fetchBodyTrendsUseCase: FetchBodyTrendsUseCase = {
        return FetchBodyTrendsUseCase(bodyRepository: bodyRepository)
    }()

    /// Sleep 기록 Use Case
    /// 📚 학습 포인트: Domain Use Case with Auto Status Calculation
    /// 수면 시간을 입력받아 상태를 자동 계산하고 저장
    /// 💡 Java 비교: @Service with business logic
    lazy var recordSleepUseCase: RecordSleepUseCase = {
        return RecordSleepUseCase(sleepRepository: sleepRepository)
    }()

    /// Sleep 히스토리 조회 Use Case
    /// 📚 학습 포인트: Query Use Case
    /// 리스트 표시를 위한 수면 기록 조회 및 통계 계산
    /// 💡 Java 비교: @Service with read-only operations
    lazy var fetchSleepHistoryUseCase: FetchSleepHistoryUseCase = {
        return FetchSleepHistoryUseCase(sleepRepository: sleepRepository)
    }()

    /// Sleep 통계 조회 Use Case
    /// 📚 학습 포인트: Statistics Use Case
    /// 차트 및 대시보드 표시를 위한 수면 통계 계산
    /// 💡 Java 비교: @Service with analytics logic
    lazy var fetchSleepStatsUseCase: FetchSleepStatsUseCase = {
        return FetchSleepStatsUseCase(sleepRepository: sleepRepository)
    }()

    // MARK: - Goal Use Cases

    /// Goal 설정 Use Case
    /// 📚 학습 포인트: Orchestration Use Case with Dependencies
    /// 여러 Repository를 조합하여 목표 설정 로직 구현
    /// 💡 Java 비교: @Service with @Autowired dependencies
    lazy var setGoalUseCase: SetGoalUseCase = {
        return SetGoalUseCase(
            bodyRepository: bodyRepository,
            goalRepository: goalRepository
        )
    }()

    /// Goal 진행상황 조회 Use Case
    /// 📚 학습 포인트: Query Use Case
    /// 목표 진행률, 마일스톤, 트렌드 분석 데이터 조회
    /// 💡 Java 비교: @Service with read-only operations
    lazy var getGoalProgressUseCase: GetGoalProgressUseCase = {
        return GetGoalProgressUseCase(
            goalRepository: goalRepository,
            bodyRepository: bodyRepository
        )
    }()

    /// Goal 업데이트 Use Case
    /// 📚 학습 포인트: Update Use Case
    /// 기존 목표 수정 (히스토리 보존)
    /// 💡 Java 비교: @Service with update operations
    lazy var updateGoalUseCase: UpdateGoalUseCase = {
        return UpdateGoalUseCase(goalRepository: goalRepository)
    }()

    // MARK: - Diet Use Cases

    /// AI 식단 코멘트 생성 Use Case
    lazy var generateDietCommentUseCase: GenerateDietCommentUseCase = {
        return GenerateDietCommentUseCase(
            dietCommentRepository: dietCommentRepository,
            geminiService: geminiService,
            foodRecordRepository: foodRecordRepository
        )
    }()

    // MARK: - Exercise Use Cases

    /// 운동 기록 추가 Use Case
    lazy var addExerciseRecordUseCase: AddExerciseRecordUseCase = {
        return AddExerciseRecordUseCase(
            exerciseRepository: exerciseRepository,
            dailyLogService: dailyLogService
        )
    }()

    /// 운동 기록 수정 Use Case
    lazy var updateExerciseRecordUseCase: UpdateExerciseRecordUseCase = {
        return UpdateExerciseRecordUseCase(
            exerciseRepository: exerciseRepository,
            dailyLogService: dailyLogService
        )
    }()

    /// 운동 기록 조회 Use Case
    lazy var getExerciseRecordsUseCase: GetExerciseRecordsUseCase = {
        return GetExerciseRecordsUseCase(exerciseRepository: exerciseRepository)
    }()

    /// 운동 기록 삭제 Use Case
    lazy var deleteExerciseRecordUseCase: DeleteExerciseRecordUseCase = {
        return DeleteExerciseRecordUseCase(
            exerciseRepository: exerciseRepository,
            dailyLogService: dailyLogService
        )
    }()

    // TODO: Phase 4에서 추가 예정
    // - SearchFoodUseCase
    // - etc.
}

// MARK: - Factory Methods

extension DIContainer {

    // 📚 학습 포인트: Factory Pattern
    // 의존성 생성 로직을 캡슐화
    // 테스트 시 Mock 객체로 교체 가능

    // MARK: - Body Composition ViewModels

    /// BodyCompositionViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - ViewModel 생성 로직을 중앙화
    /// - 의존성 주입을 한 곳에서 관리
    /// - 테스트 시 mock 주입이 쉬워짐
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameters:
    ///   - userProfile: 사용자 프로필 (BMR/TDEE 계산에 필요)
    /// - Returns: 새로운 BodyCompositionViewModel 인스턴스
    @MainActor
    func makeBodyCompositionViewModel(userProfile: UserProfile) -> BodyCompositionViewModel {
        return BodyCompositionViewModel(
            recordBodyCompositionUseCase: recordBodyCompositionUseCase,
            fetchBodyTrendsUseCase: fetchBodyTrendsUseCase,
            bodyRepository: bodyRepository,
            userProfile: userProfile
        )
    }

    /// BodyTrendsViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 차트 표시를 위한 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Returns: 새로운 BodyTrendsViewModel 인스턴스
    @MainActor
    func makeBodyTrendsViewModel() -> BodyTrendsViewModel {
        return BodyTrendsViewModel(
            fetchBodyTrendsUseCase: fetchBodyTrendsUseCase,
            bodyRepository: bodyRepository
        )
    }

    /// MetabolismViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 대시보드용 BMR/TDEE 표시 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Returns: 새로운 MetabolismViewModel 인스턴스
    @MainActor
    func makeMetabolismViewModel() -> MetabolismViewModel {
        return MetabolismViewModel(bodyRepository: bodyRepository)
    }

    // MARK: - Sleep ViewModels

    /// SleepInputViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 수면 입력을 위한 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// - 기본 수면 시간 설정 가능
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - defaultHours: 기본 수면 시간 (시간, 기본값: 7)
    ///   - defaultMinutes: 기본 수면 시간 (분, 기본값: 0)
    /// - Returns: 새로운 SleepInputViewModel 인스턴스
    @MainActor
    func makeSleepInputViewModel(
        userId: UUID,
        defaultHours: Int = 7,
        defaultMinutes: Int = 0
    ) -> SleepInputViewModel {
        return SleepInputViewModel(
            recordSleepUseCase: recordSleepUseCase,
            userId: userId,
            defaultHours: defaultHours,
            defaultMinutes: defaultMinutes
        )
    }

    /// 수면 기록 편집용 SleepInputViewModel 생성
    @MainActor
    func makeSleepInputViewModelForEditing(
        userId: UUID,
        record: SleepRecord
    ) -> SleepInputViewModel {
        let durationMinutes = Int(record.duration)
        return SleepInputViewModel(
            recordSleepUseCase: recordSleepUseCase,
            userId: userId,
            defaultHours: durationMinutes / 60,
            defaultMinutes: durationMinutes % 60,
            sleepRepository: sleepRepository,
            editingRecordId: record.id,
            editingDate: record.date
        )
    }

    /// SleepHistoryViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 수면 히스토리 리스트를 위한 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// - 기본 조회 모드 설정 가능 (최근 30일)
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameter defaultMode: 기본 조회 모드 (기본값: 최근 30일)
    /// - Returns: 새로운 SleepHistoryViewModel 인스턴스
    @MainActor
    func makeSleepHistoryViewModel(
        defaultMode: FetchSleepHistoryUseCase.QueryMode = .recent(days: 30)
    ) -> SleepHistoryViewModel {
        return SleepHistoryViewModel(
            fetchSleepHistoryUseCase: fetchSleepHistoryUseCase,
            sleepRepository: sleepRepository,
            defaultMode: defaultMode
        )
    }

    /// SleepTrendsViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 수면 트렌드 차트를 위한 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// - 차트 표시용 통계 데이터 제공
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Returns: 새로운 SleepTrendsViewModel 인스턴스
    @MainActor
    func makeSleepTrendsViewModel() -> SleepTrendsViewModel {
        return SleepTrendsViewModel(
            fetchSleepStatsUseCase: fetchSleepStatsUseCase,
            sleepRepository: sleepRepository
        )
    }

    // MARK: - Goal ViewModels

    /// GoalSettingViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 목표 설정 화면용 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameter userId: 사용자 ID (목표 소유자)
    /// - Returns: 새로운 GoalSettingViewModel 인스턴스
    @MainActor
    func makeGoalSettingViewModel(userId: UUID) -> GoalSettingViewModel {
        return GoalSettingViewModel(
            setGoalUseCase: setGoalUseCase,
            bodyRepository: bodyRepository,
            userId: userId
        )
    }

    /// GoalProgressViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 목표 진행상황 화면용 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Returns: 새로운 GoalProgressViewModel 인스턴스
    @MainActor
    func makeGoalProgressViewModel() -> GoalProgressViewModel {
        return GoalProgressViewModel(getGoalProgressUseCase: getGoalProgressUseCase)
    }

    /// GoalModeSettingsViewModel 공유 인스턴스
    /// 📚 학습 포인트: 목표 모드 상태는 앱 전역에서 동기화 필요
    /// ContentView와 SettingsView가 동일 인스턴스를 공유해야 토글 상태가 즉시 반영됨
    @MainActor
    private var _goalModeSettingsViewModel: GoalModeSettingsViewModel?

    @MainActor
    func makeGoalModeSettingsViewModel() -> GoalModeSettingsViewModel {
        if let existing = _goalModeSettingsViewModel {
            return existing
        }
        let vm = GoalModeSettingsViewModel(goalRepository: goalRepository)
        _goalModeSettingsViewModel = vm
        return vm
    }

    /// GoalExerciseStatsViewModel 생성
    @MainActor
    func makeGoalExerciseStatsViewModel() -> GoalExerciseStatsViewModel {
        return GoalExerciseStatsViewModel(exerciseRepository: exerciseRepository)
    }

    /// GoalDietStatsViewModel 생성
    @MainActor
    func makeGoalDietStatsViewModel() -> GoalDietStatsViewModel {
        return GoalDietStatsViewModel(dailyLogRepository: dailyLogRepository)
    }

    /// WeeklyReportViewModel 생성
    @MainActor
    func makeWeeklyReportViewModel() -> WeeklyReportViewModel {
        return WeeklyReportViewModel(
            exerciseRepository: exerciseRepository,
            dailyLogRepository: dailyLogRepository,
            bodyRepository: bodyRepository
        )
    }

    // MARK: - Managers

    /// SleepPromptManager 생성
    /// 📚 학습 포인트: Manager Factory Method
    /// - 아침 수면 기록 프롬프트 관리자 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// - UserDefaults는 기본값(.standard) 사용
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Returns: 새로운 SleepPromptManager 인스턴스
    @MainActor
    func makeSleepPromptManager() -> SleepPromptManager {
        return SleepPromptManager(
            sleepRepository: sleepRepository,
            userDefaults: .standard
        )
    }

    // MARK: - Exercise ViewModels

    /// ExerciseInputViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 운동 입력/편집 화면용 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - userWeight: 사용자 체중 (kg)
    ///   - userGender: 사용자 성별 (칼로리 보정에 사용)
    ///   - userBMR: 사용자 BMR
    ///   - userTDEE: 사용자 TDEE
    ///   - editingExercise: 편집할 운동 기록 (편집 모드일 때만 제공)
    /// - Returns: 새로운 ExerciseInputViewModel 인스턴스
    @MainActor
    func makeExerciseInputViewModel(
        userId: UUID,
        userWeight: Decimal,
        userGender: Gender,
        userBMR: Decimal,
        userTDEE: Decimal,
        editingExercise: ExerciseRecord? = nil,
        selectedDate: Date = Date()
    ) -> ExerciseInputViewModel {
        return ExerciseInputViewModel(
            addExerciseRecordUseCase: addExerciseRecordUseCase,
            updateExerciseRecordUseCase: editingExercise != nil ? updateExerciseRecordUseCase : nil,
            userId: userId,
            userWeight: userWeight,
            userGender: userGender,
            userBMR: userBMR,
            userTDEE: userTDEE,
            editingExercise: editingExercise,
            selectedDate: selectedDate
        )
    }

    /// ExerciseListViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 운동 기록 목록 화면용 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 새로운 ExerciseListViewModel 인스턴스
    @MainActor
    func makeExerciseListViewModel(userId: UUID) -> ExerciseListViewModel {
        return ExerciseListViewModel(
            getExerciseRecordsUseCase: getExerciseRecordsUseCase,
            deleteExerciseRecordUseCase: deleteExerciseRecordUseCase,
            dailyLogRepository: dailyLogRepository,
            exerciseRepository: exerciseRepository,
            healthKitReadService: healthKitReadService,
            healthKitAuthService: healthKitAuthService,
            userId: userId
        )
    }

    // MARK: - Diet ViewModels

    /// FoodSearchViewModel 생성
    @MainActor
    func makeFoodSearchViewModel() -> FoodSearchViewModel {
        return FoodSearchViewModel(
            foodSearchService: foodSearchService,
            recentFoodsService: recentFoodsService,
            hybridService: hybridFoodSearchService,
            foodRepository: foodRepository
        )
    }

    /// DietCommentViewModel 생성
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - goalType: 사용자 목표 (감량/유지/증량)
    ///   - tdee: 활동대사량 (kcal)
    ///   - targetCalories: 목표 섭취 칼로리 (kcal)
    /// - Returns: 새로운 DietCommentViewModel 인스턴스
    @MainActor
    func makeDietCommentViewModel(
        userId: UUID,
        goalType: GoalType,
        tdee: Int,
        targetCalories: Int
    ) -> DietCommentViewModel {
        return DietCommentViewModel(
            generateCommentUseCase: generateDietCommentUseCase,
            userId: userId,
            userGoalType: goalType,
            userTDEE: tdee,
            userTargetCalories: targetCalories
        )
    }
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
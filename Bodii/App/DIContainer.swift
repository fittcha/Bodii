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

    // MARK: - Infrastructure

    /// 네트워크 매니저
    /// 📚 학습 포인트: Network Layer
    /// 모든 HTTP 요청을 처리하는 중앙화된 네트워크 레이어
    /// 💡 Java 비교: Retrofit, OkHttp와 유사
    lazy var networkManager: NetworkManager = {
        return NetworkManager(timeout: 30, maxRetries: 2)
    }()

    /// API 설정
    /// 📚 학습 포인트: Configuration Singleton
    /// API 엔드포인트 및 인증 키 관리
    /// 💡 Java 비교: @Configuration 클래스와 유사
    var apiConfig: APIConfigProtocol {
        return APIConfig.shared
    }

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

    /// DailyLog 로컬 데이터 소스
    /// 📚 학습 포인트: Core Data Context Injection
    /// PersistenceController.shared.viewContext를 주입하여 Core Data 작업 수행
    /// 💡 Java 비교: @Lazy + @Autowired DAO와 유사
    lazy var dailyLogLocalDataSource: DailyLogLocalDataSource = {
        return DailyLogLocalDataSource(context: PersistenceController.shared.viewContext)
    }()

    /// 통합 음식 검색 서비스 (KFDA + USDA)
    /// 📚 학습 포인트: Unified Search Service
    /// 여러 데이터 소스를 통합하여 검색하는 서비스
    /// 💡 Java 비교: Facade pattern으로 여러 API를 통합
    lazy var unifiedFoodSearchService: UnifiedFoodSearchService = {
        return UnifiedFoodSearchService()
    }()

    /// Vision API 서비스
    /// 📚 학습 포인트: AI Service Integration
    /// Google Cloud Vision API를 사용하여 음식 사진 분석
    /// 💡 Java 비교: External API Client Service
    lazy var visionAPIService: VisionAPIServiceProtocol = {
        return VisionAPIService(
            networkManager: networkManager,
            apiConfig: apiConfig,
            usageTracker: VisionAPIUsageTracker.shared
        )
    }()

    // TODO: Phase 2에서 추가 예정
    // - HealthKitManager

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

    /// Food Repository
    /// 📚 학습 포인트: Protocol Type
    /// 프로토콜 타입으로 선언하여 구현 교체 가능 (테스트용 Mock 등)
    /// 💡 Java 비교: Interface 타입 필드와 동일
    lazy var foodRepository: FoodRepositoryProtocol = {
        FoodRepository(context: PersistenceController.shared.viewContext)
    }()

    /// FoodRecord Repository
    lazy var foodRecordRepository: FoodRecordRepositoryProtocol = {
        FoodRecordRepository(context: PersistenceController.shared.viewContext)
    }()

    /// DailyLog Repository (for unified dashboard)
    /// 📚 학습 포인트: Repository Pattern
    /// dailyLogLocalDataSource를 주입받아 일일 집계 데이터 관리
    /// DashboardViewModel에서 사용하여 사전 계산된 값 조회
    /// 💡 Java 비교: @Autowired Repository와 유사
    lazy var dailyLogRepository: DailyLogRepositoryProtocol = {
        DailyLogRepository(context: PersistenceController.shared.viewContext)
    }()

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

    // TODO: Phase 3에서 추가 예정
    // - GoalRepository

    // MARK: - Domain Services

    /// FoodRecord Service
    /// 📚 학습 포인트: Service Layer
    /// 여러 Repository를 조합하여 비즈니스 로직을 처리
    /// 💡 Java 비교: @Service 어노테이션이 붙은 서비스 클래스와 유사
    lazy var foodRecordService: FoodRecordServiceProtocol = {
        FoodRecordService(
            foodRecordRepository: foodRecordRepository,
            dailyLogRepository: dailyLogRepository,
            foodRepository: foodRepository
        )
    }()

    /// Food Search Service
    lazy var foodSearchService: FoodSearchServiceProtocol = {
        LocalFoodSearchService(foodRepository: foodRepository)
    }()

    /// Recent Foods Service
    lazy var recentFoodsService: RecentFoodsServiceProtocol = {
        RecentFoodsService(
            foodRepository: foodRepository,
            maxRecentFoods: 10,
            maxFrequentFoods: 10,
            maxQuickAddFoods: 15
        )
    }()

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
    /// 💡 Java 비교: @Service with @Autowired dependencies
    lazy var recordBodyCompositionUseCase: RecordBodyCompositionUseCase = {
        return RecordBodyCompositionUseCase(
            calculateBMRUseCase: calculateBMRUseCase,
            calculateTDEEUseCase: calculateTDEEUseCase,
            bodyRepository: bodyRepository
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

    // TODO: Phase 4에서 추가 예정
    // - LogExerciseUseCase
    // - etc.

    // MARK: - Domain Services

    /// 음식 라벨 매칭 서비스
    /// 📚 학습 포인트: AI Label Matching Service
    /// Vision API 라벨을 음식 데이터베이스와 매칭하는 서비스
    /// 💡 Java 비교: Business Logic Service with translation
    lazy var foodLabelMatcherService: FoodLabelMatcherServiceProtocol = {
        return FoodLabelMatcherService(
            unifiedSearchService: unifiedFoodSearchService,
            maxAlternatives: 3,
            minConfidence: 0.3
        )
    }()
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

    /// SleepHistoryViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 수면 히스토리 리스트를 위한 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// - 기본 조회 모드 설정 가능 (최근 30일)
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameter defaultMode: 기본 조회 모드 (기본값: 최근 30일)
    /// - Returns: 새로운 SleepHistoryViewModel 인스턴스
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
    func makeSleepTrendsViewModel() -> SleepTrendsViewModel {
        return SleepTrendsViewModel(
            fetchSleepStatsUseCase: fetchSleepStatsUseCase,
            sleepRepository: sleepRepository
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
    func makeSleepPromptManager() -> SleepPromptManager {
        return SleepPromptManager(
            sleepRepository: sleepRepository,
            userDefaults: .standard
        )
    }

    // MARK: - Diet/Food ViewModels

    /// DailyMealViewModel 생성
    /// - Returns: DailyMealViewModel 인스턴스
    func makeDailyMealViewModel() -> DailyMealViewModel {
        DailyMealViewModel(
            foodRecordService: foodRecordService,
            dailyLogRepository: dailyLogRepository
        )
    }

    /// FoodSearchViewModel 생성
    /// - Returns: FoodSearchViewModel 인스턴스
    func makeFoodSearchViewModel() -> FoodSearchViewModel {
        FoodSearchViewModel(
            foodSearchService: foodSearchService,
            recentFoodsService: recentFoodsService
        )
    }

    /// FoodDetailViewModel 생성
    /// - Parameters:
    ///   - foodId: 음식 ID
    ///   - selectedDate: 선택된 날짜
    ///   - selectedMealType: 선택된 식사 유형
    /// - Returns: FoodDetailViewModel 인스턴스
    func makeFoodDetailViewModel(
        foodId: UUID,
        selectedDate: Date,
        selectedMealType: MealType
    ) -> FoodDetailViewModel {
        FoodDetailViewModel(
            foodId: foodId,
            selectedDate: selectedDate,
            selectedMealType: selectedMealType,
            foodRepository: foodRepository,
            foodRecordService: foodRecordService
        )
    }

    /// ManualFoodEntryViewModel 생성
    /// - Parameters:
    ///   - selectedDate: 선택된 날짜
    ///   - selectedMealType: 선택된 식사 유형
    /// - Returns: ManualFoodEntryViewModel 인스턴스
    func makeManualFoodEntryViewModel(
        selectedDate: Date,
        selectedMealType: MealType
    ) -> ManualFoodEntryViewModel {
        ManualFoodEntryViewModel(
            selectedDate: selectedDate,
            selectedMealType: selectedMealType,
            foodRepository: foodRepository,
            foodRecordService: foodRecordService
        )
    }

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

    // MARK: - Dashboard ViewModels

    /// DashboardViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - 일일 대시보드 ViewModel 생성
    /// - DailyLogRepository 의존성 주입
    /// - 사용자별 일일 집계 데이터 조회
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 새로운 DashboardViewModel 인스턴스
    func makeDashboardViewModel(userId: UUID) -> DashboardViewModel {
        return DashboardViewModel(
            dailyLogRepository: dailyLogRepository,
            userId: userId
        )
    }

    // MARK: - Photo Recognition ViewModels

    /// PhotoRecognitionViewModel 생성
    /// 📚 학습 포인트: Complex ViewModel Factory
    /// - AI 사진 인식 워크플로우를 위한 ViewModel 생성
    /// - 여러 서비스의 의존성을 조합하여 주입
    /// - Vision API, 음식 매칭, 식단 기록 서비스 통합
    /// 💡 Java 비교: @Bean 메서드로 복잡한 의존성 그래프 관리
    ///
    /// - Parameters:
    ///   - foodRecordService: 식단 기록 서비스 (외부에서 주입, Core Data 컨텍스트 공유를 위해)
    /// - Returns: 새로운 PhotoRecognitionViewModel 인스턴스
    func makePhotoRecognitionViewModel(
        foodRecordService: FoodRecordServiceProtocol
    ) -> PhotoRecognitionViewModel {
        return PhotoRecognitionViewModel(
            visionAPIService: visionAPIService,
            foodLabelMatcher: foodLabelMatcherService,
            foodRecordService: foodRecordService,
            usageTracker: VisionAPIUsageTracker.shared
        )
    }

    // TODO: 각 Feature 구현 시 Factory 메서드 추가
    // func makeOnboardingViewModel() -> OnboardingViewModel
    // func makeFoodLogViewModel() -> FoodLogViewModel
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

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

    /// Body composition 로컬 데이터 소스
    /// 📚 학습 포인트: Lazy Initialization
    /// 첫 접근 시 한 번만 생성되어 재사용됨
    /// 💡 Java 비교: @Lazy + @Autowired와 유사
    lazy var bodyLocalDataSource: BodyLocalDataSource = {
        return BodyLocalDataSource(persistenceController: .shared)
    }()

    // TODO: Phase 2에서 추가 예정
    // - NetworkManager
    // - HealthKitManager
    // - FoodAPIDataSource
    // - GeminiAPIDataSource

    // MARK: - Repositories

    /// Body composition 리포지토리
    /// 📚 학습 포인트: Dependency Injection Chain
    /// bodyLocalDataSource를 주입받아 생성
    /// 💡 Java 비교: @Autowired Repository와 유사
    lazy var bodyRepository: BodyRepositoryProtocol = {
        return BodyRepository(localDataSource: bodyLocalDataSource)
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

    /// DailyLog Repository
    lazy var dailyLogRepository: DailyLogRepositoryProtocol = {
        DailyLogRepository(context: PersistenceController.shared.viewContext)
    }()

    // TODO: Phase 3에서 추가 예정
    // - UserRepository
    // - ExerciseRepository
    // - SleepRepository
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

    // TODO: Phase 4에서 추가 예정
    // - LogExerciseUseCase
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

    // TODO: 각 Feature 구현 시 Factory 메서드 추가
    // func makeOnboardingViewModel() -> OnboardingViewModel
    // func makeDashboardViewModel() -> DashboardViewModel
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

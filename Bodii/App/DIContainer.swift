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

    /// Gemini API 서비스
    /// 📚 학습 포인트: AI API Service with Rate Limiting
    /// Gemini AI API 호출을 담당하는 데이터 소스
    /// 💡 Java 비교: Retrofit Service Interface와 유사
    lazy var geminiAPIService: GeminiAPIService = {
        return GeminiAPIService()
    }()

    /// Diet comment 캐시
    /// 📚 학습 포인트: Actor-based In-Memory Cache
    /// AI 코멘트를 캐싱하여 중복 API 호출 방지
    /// 💡 Java 비교: Caffeine Cache와 유사
    lazy var dietCommentCache: DietCommentCache = {
        return DietCommentCache()
    }()

    // TODO: Phase 2에서 추가 예정
    // - NetworkManager
    // - HealthKitManager
    // - FoodAPIDataSource

    // MARK: - Services

    /// Gemini AI 서비스
    /// 📚 학습 포인트: Domain Service Layer
    /// AI 식단 코멘트 생성을 담당하는 도메인 서비스
    /// 💡 Java 비교: @Service 클래스와 유사
    lazy var geminiService: GeminiServiceProtocol = {
        return GeminiService(geminiAPIService: geminiAPIService)
    }()

    // MARK: - Repositories

    /// Body composition 리포지토리
    /// 📚 학습 포인트: Dependency Injection Chain
    /// bodyLocalDataSource를 주입받아 생성
    /// 💡 Java 비교: @Autowired Repository와 유사
    lazy var bodyRepository: BodyRepositoryProtocol = {
        return BodyRepository(localDataSource: bodyLocalDataSource)
    }()

    /// Food record 리포지토리
    /// 📚 학습 포인트: Core Data Repository
    /// 식단 기록 데이터의 CRUD 및 조회 기능 제공
    /// 💡 Java 비교: JPA Repository와 유사
    lazy var foodRecordRepository: FoodRecordRepositoryProtocol = {
        return FoodRecordRepository(context: PersistenceController.shared.viewContext)
    }()

    /// Diet comment 리포지토리
    /// 📚 학습 포인트: AI Service Repository
    /// AI 코멘트 생성 및 캐싱을 조정하는 리포지토리
    /// 💡 Java 비교: @Repository with @Service dependencies
    lazy var dietCommentRepository: DietCommentRepository = {
        return DietCommentRepositoryImpl(
            geminiService: geminiService,
            cache: dietCommentCache,
            foodRecordRepository: foodRecordRepository
        )
    }()

    // TODO: Phase 3에서 추가 예정
    // - UserRepository
    // - ExerciseRepository
    // - SleepRepository
    // - GoalRepository

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

    /// AI 식단 코멘트 생성 Use Case
    /// 📚 학습 포인트: Orchestration Use Case with AI Service
    /// AI 코멘트 생성, 캐싱, 에러 처리를 조정하는 유스케이스
    /// 💡 Java 비교: @Service with multiple repository dependencies
    lazy var generateDietCommentUseCase: GenerateDietCommentUseCase = {
        return GenerateDietCommentUseCase(
            dietCommentRepository: dietCommentRepository,
            geminiService: geminiService,
            foodRecordRepository: foodRecordRepository
        )
    }()

    // TODO: Phase 4에서 추가 예정
    // - SearchFoodUseCase
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

    // MARK: - Diet Comment ViewModels

    /// DietCommentViewModel 생성
    /// 📚 학습 포인트: Factory Method Pattern
    /// - AI 식단 코멘트 표시를 위한 ViewModel 생성
    /// - 의존성 주입을 한 곳에서 관리
    /// 💡 Java 비교: @Bean 메서드와 유사
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - goalType: 목표 타입 (감량/유지/증량)
    ///   - tdee: 총 일일 에너지 소비량
    /// - Returns: 새로운 DietCommentViewModel 인스턴스
    func makeDietCommentViewModel(
        userId: UUID,
        goalType: GoalType,
        tdee: Int
    ) -> DietCommentViewModel {
        return DietCommentViewModel(
            generateCommentUseCase: generateDietCommentUseCase,
            userId: userId,
            userGoalType: goalType,
            userTDEE: tdee
        )
    }

    // TODO: 각 Feature 구현 시 Factory 메서드 추가
    // func makeOnboardingViewModel() -> OnboardingViewModel
    // func makeDashboardViewModel() -> DashboardViewModel
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

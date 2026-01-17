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

    // TODO: Phase 3에서 추가 예정
    // - UserRepository
    // - FoodRepository
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

    // TODO: Phase 4에서 추가 예정
    // - SearchFoodUseCase
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

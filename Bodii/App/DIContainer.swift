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

    /// 네트워크 매니저 (싱글톤)
    /// 📚 학습 포인트: Singleton Dependency
    /// 모든 네트워크 요청에 공유되는 매니저
    /// 💡 Java 비교: OkHttpClient를 싱글톤으로 관리하는 패턴
    lazy var networkManager: NetworkManager = {
        NetworkManager()
    }()

    // MARK: - Data Sources

    /// 식약처 API 서비스
    /// 📚 학습 포인트: API Service
    /// 한국 식품 영양 데이터베이스 API 호출 서비스
    /// 💡 Java 비교: Retrofit Service 인스턴스
    lazy var kfdaFoodAPIService: KFDAFoodAPIService = {
        KFDAFoodAPIService(networkManager: self.networkManager)
    }()

    /// USDA API 서비스
    /// 📚 학습 포인트: API Service
    /// 미국 농무부 식품 데이터베이스 API 호출 서비스
    /// 💡 Java 비교: Retrofit Service 인스턴스
    lazy var usdaFoodAPIService: USDAFoodAPIService = {
        USDAFoodAPIService(networkManager: self.networkManager)
    }()

    /// 통합 식품 검색 서비스
    /// 📚 학습 포인트: Unified Service
    /// 여러 API를 통합하여 최적의 검색 결과 제공
    /// 한국 음식은 식약처 우선, 외국 음식은 USDA 우선
    /// 💡 Java 비교: Facade Pattern의 구현체
    lazy var unifiedFoodSearchService: UnifiedFoodSearchService = {
        UnifiedFoodSearchService(
            kfdaService: self.kfdaFoodAPIService,
            usdaService: self.usdaFoodAPIService
        )
    }()

    /// 식품 로컬 데이터 소스
    /// 📚 학습 포인트: Local Data Source
    /// Core Data를 사용한 식품 캐싱 및 오프라인 지원
    /// 💡 Java 비교: Room Database의 DAO와 유사
    lazy var foodLocalDataSource: FoodLocalDataSource = {
        FoodLocalDataSourceImpl()
    }()

    // TODO: Phase 2에서 추가 예정
    // - HealthKitManager
    // - GeminiAPIDataSource

    // MARK: - Repositories

    /// 식품 검색 저장소
    /// 📚 학습 포인트: Repository Pattern
    /// 다중 데이터 소스(API + 로컬)를 추상화한 단일 인터페이스
    /// 💡 Java 비교: Spring Data Repository
    lazy var foodSearchRepository: FoodSearchRepository = {
        FoodSearchRepositoryImpl(
            searchService: self.unifiedFoodSearchService,
            localDataSource: self.foodLocalDataSource
        )
    }()

    // TODO: Phase 3에서 추가 예정
    // - UserRepository
    // - BodyRepository
    // - ExerciseRepository
    // - SleepRepository
    // - GoalRepository

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
    // 💡 Java 비교: @Bean 메서드와 유사

    // MARK: - Food Search

    /// FoodSearchViewModel 생성
    /// 📚 학습 포인트: ViewModel Factory
    /// ViewModel 생성 시 필요한 모든 의존성을 주입
    /// 💡 Java 비교: ViewModelProvider.Factory
    ///
    /// - Returns: FoodSearchViewModel 인스턴스
    /// - Note: Phase 9에서 FoodSearchViewModel 구현 시 활성화
    // func makeFoodSearchViewModel() -> FoodSearchViewModel {
    //     FoodSearchViewModel(repository: foodSearchRepository)
    // }

    // TODO: 각 Feature 구현 시 Factory 메서드 추가
    // func makeOnboardingViewModel() -> OnboardingViewModel
    // func makeDashboardViewModel() -> DashboardViewModel
    // func makeBodyViewModel() -> BodyViewModel
    // func makeFoodRecordViewModel() -> FoodRecordViewModel
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

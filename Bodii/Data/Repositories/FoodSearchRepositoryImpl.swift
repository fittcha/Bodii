//
//  FoodSearchRepositoryImpl.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Repository Implementation
// Repository 패턴의 구현체로, 도메인 레이어의 인터페이스를 실제로 구현
// 💡 Java 비교: JpaRepository 구현체 (Spring Data)와 유사

import Foundation

/// 식품 검색 저장소 구현체
///
/// 📚 학습 포인트: Repository Pattern Implementation
/// FoodSearchRepository 프로토콜을 구현하여 데이터 소스 추상화
/// 여러 데이터 소스(식약처 API, USDA API, 로컬 캐시)를 통합하여 단일 인터페이스 제공
/// 💡 Java 비교: Repository 인터페이스의 구현체 (예: UserRepositoryImpl)
///
/// **아키텍처:**
/// ```
/// ViewModel/UseCase
///        ↓
/// FoodSearchRepository (Protocol) ← Domain Layer
///        ↓
/// FoodSearchRepositoryImpl (Implementation) ← Data Layer
///        ↓
/// UnifiedFoodSearchService → KFDA/USDA APIs
///        ↓
/// FoodLocalDataSource → Core Data
/// ```
///
/// **역할:**
/// - 프로토콜에 정의된 메서드를 실제로 구현
/// - UnifiedFoodSearchService를 사용하여 다중 API 검색
/// - 로컬 캐시 관리 (최근 검색, 접근 시간 업데이트, 캐시 정리)
/// - 비즈니스 로직과 데이터 소스 분리
///
/// **특징:**
/// - 의존성 주입을 통한 테스트 용이성
/// - Graceful degradation (한 API 실패 시 다른 API 활용)
/// - 오프라인 지원 (캐시 활용)
/// - 결과 중복 제거
///
/// **사용 예시:**
/// ```swift
/// // DIContainer에서 주입받음
/// let repository: FoodSearchRepository = FoodSearchRepositoryImpl(
///     searchService: UnifiedFoodSearchService(),
///     localDataSource: FoodLocalDataSource()
/// )
///
/// // 식품 검색
/// let foods = try await repository.searchFoods(query: "김치찌개", limit: 20)
///
/// // 최근 검색 식품
/// let recentFoods = try await repository.getRecentFoods(limit: 10)
/// ```
final class FoodSearchRepositoryImpl: FoodSearchRepository {

    // MARK: - Properties

    /// 통합 식품 검색 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: @Autowired field injection
    private let searchService: UnifiedFoodSearchService

    /// 로컬 데이터 소스 (캐시)
    ///
    /// 📚 학습 포인트: Optional Dependency
    /// 로컬 데이터 소스가 구현되기 전까지는 nil로 동작
    /// Phase 5에서 구현 후 주입받을 예정
    /// 💡 Java 비교: @Autowired(required = false)와 유사
    private let localDataSource: FoodLocalDataSource?

    // MARK: - Initialization

    /// FoodSearchRepositoryImpl 초기화
    ///
    /// 📚 학습 포인트: Constructor Injection
    /// 모든 의존성을 생성자를 통해 주입받아 테스트 용이성 향상
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - searchService: 통합 검색 서비스 (기본값: UnifiedFoodSearchService())
    ///   - localDataSource: 로컬 데이터 소스 (기본값: nil, Phase 5에서 구현 예정)
    init(
        searchService: UnifiedFoodSearchService = UnifiedFoodSearchService(),
        localDataSource: FoodLocalDataSource? = nil
    ) {
        self.searchService = searchService
        self.localDataSource = localDataSource
    }

    // MARK: - FoodSearchRepository Protocol Implementation

    /// 식품 검색
    ///
    /// 📚 학습 포인트: Multi-Source Search Strategy
    /// 1. 캐시 확인 (useCache=true인 경우)
    /// 2. UnifiedFoodSearchService를 통한 API 검색
    /// 3. 검색 결과를 캐시에 저장
    /// 💡 Java 비교: @Cacheable 어노테이션을 사용한 캐싱 로직과 유사
    ///
    /// - Parameters:
    ///   - query: 검색어 (식품명)
    ///   - limit: 최대 결과 개수
    ///   - offset: 페이징 오프셋 (현재 버전에서는 미지원)
    ///   - useCache: 캐시 사용 여부
    ///
    /// - Returns: 검색된 식품 배열
    ///
    /// - Throws:
    ///   - `FoodSearchError.invalidQuery`: 검색어가 비어있거나 유효하지 않음
    ///   - `FoodSearchError.networkFailure`: 네트워크 연결 실패
    ///   - `FoodSearchError.apiError`: API 요청 실패
    ///   - `FoodSearchError.noResults`: 검색 결과 없음
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int,
        useCache: Bool
    ) async throws -> [Food] {

        // 📚 학습 포인트: Input Validation
        // 검색어 유효성 검증을 도메인 레이어에서 수행
        // 💡 Java 비교: @Valid 어노테이션과 유사한 역할
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw FoodSearchError.invalidQuery("검색어를 입력해주세요.")
        }

        guard limit > 0 else {
            throw FoodSearchError.invalidQuery("limit은 1 이상이어야 합니다.")
        }

        // 📚 학습 포인트: Cache-First Strategy (Phase 5에서 구현 예정)
        // useCache가 true이고 캐시에 결과가 있으면 캐시 반환
        // 💡 Java 비교: Spring Cache의 @Cacheable과 유사
        if useCache, let localDataSource = localDataSource {
            do {
                // 캐시에서 검색 (정확한 매칭)
                let cachedFoods = try await localDataSource.searchFoods(
                    query: query,
                    limit: limit
                )

                // 캐시에 충분한 결과가 있으면 반환
                if !cachedFoods.isEmpty {
                    #if DEBUG
                    print("✅ Cache hit: \(cachedFoods.count) foods found for '\(query)'")
                    #endif
                    return cachedFoods
                }
            } catch {
                // 캐시 조회 실패는 무시하고 API 검색 진행
                #if DEBUG
                print("⚠️ Cache lookup failed: \(error.localizedDescription)")
                #endif
            }
        }

        // 📚 학습 포인트: API Search with Error Handling
        // UnifiedFoodSearchService를 통해 다중 API 검색
        // 💡 Java 비교: RestTemplate을 사용한 API 호출과 유사
        do {
            let foods = try await searchService.searchFoods(
                query: query,
                limit: limit,
                offset: offset
            )

            // 📚 학습 포인트: Async Cache Update (Phase 5에서 구현 예정)
            // 검색 결과를 백그라운드에서 캐시에 저장
            // 💡 Java 비교: @CachePut 어노테이션과 유사
            if let localDataSource = localDataSource {
                Task {
                    do {
                        try await localDataSource.saveFoods(foods)
                        #if DEBUG
                        print("✅ Cached \(foods.count) foods for query '\(query)'")
                        #endif
                    } catch {
                        // 캐시 저장 실패는 로깅만 하고 무시
                        #if DEBUG
                        print("⚠️ Failed to cache foods: \(error.localizedDescription)")
                        #endif
                    }
                }
            }

            // 결과가 없으면 noResults 에러 던지기 (선택적)
            // 현재는 빈 배열을 반환하는 것이 더 나은 UX
            if foods.isEmpty {
                #if DEBUG
                print("ℹ️ No results found for '\(query)'")
                #endif
            }

            return foods

        } catch {
            // 📚 학습 포인트: Error Mapping
            // 하위 레이어의 에러를 도메인 에러로 변환
            // 💡 Java 비교: Custom Exception Translator와 유사

            // 이미 FoodSearchError인 경우 그대로 전파
            if let foodSearchError = error as? FoodSearchError {
                throw foodSearchError
            }

            // 기타 에러는 unknown으로 래핑
            throw FoodSearchError.unknown(error)
        }
    }

    /// 최근 검색한 식품 목록 조회
    ///
    /// 📚 학습 포인트: Cache-Only Query
    /// 로컬 캐시에서만 데이터를 가져옴 (API 호출 없음)
    /// 💡 Java 비교: Cache에서만 조회하는 findAllFromCache()와 유사
    ///
    /// - Parameter limit: 최대 결과 개수
    ///
    /// - Returns: 최근 검색한 식품 목록 (lastAccessedAt 기준 정렬)
    ///
    /// - Throws: `FoodSearchError.cacheFailure`: 캐시 조회 실패
    func getRecentFoods(limit: Int) async throws -> [Food] {
        // 📚 학습 포인트: Optional Chaining with Throw
        // localDataSource가 nil이면 빈 배열 반환
        // 💡 Java 비교: Optional.orElse(Collections.emptyList())와 유사
        guard let localDataSource = localDataSource else {
            #if DEBUG
            print("ℹ️ Local data source not available, returning empty array")
            #endif
            return []
        }

        do {
            let recentFoods = try await localDataSource.getRecentFoods(limit: limit)

            #if DEBUG
            print("✅ Retrieved \(recentFoods.count) recent foods")
            #endif

            return recentFoods

        } catch {
            // 캐시 에러를 도메인 에러로 변환
            throw FoodSearchError.cacheFailure(error)
        }
    }

    /// 식품 접근 시간 업데이트
    ///
    /// 📚 학습 포인트: Activity Tracking
    /// 사용자가 식품을 선택할 때마다 접근 시간 업데이트
    /// LRU(Least Recently Used) 캐시 정책에 사용
    /// 💡 Java 비교: @CachePut with timestamp update
    ///
    /// - Parameter foodId: 식품 고유 ID
    ///
    /// - Throws: `FoodSearchError.cacheFailure`: 캐시 업데이트 실패
    func updateFoodAccessTime(foodId: UUID) async throws {
        // 📚 학습 포인트: Early Return Pattern
        // localDataSource가 없으면 조용히 리턴
        // 💡 Java 비교: Optional.ifPresent()와 유사
        guard let localDataSource = localDataSource else {
            #if DEBUG
            print("ℹ️ Local data source not available, skipping access time update")
            #endif
            return
        }

        do {
            try await localDataSource.updateAccessTime(foodId: foodId)

            #if DEBUG
            print("✅ Updated access time for food: \(foodId)")
            #endif

        } catch {
            // 접근 시간 업데이트 실패는 치명적이지 않으므로 로깅만
            #if DEBUG
            print("⚠️ Failed to update access time: \(error.localizedDescription)")
            #endif

            // 에러를 던지지 않고 무시 (UX에 영향 없음)
            // 필요하다면 여기서 throw 가능
        }
    }

    /// 캐시 정리 (LRU 정책)
    ///
    /// 📚 학습 포인트: Cache Eviction Policy
    /// 오래된 캐시 항목을 자동으로 정리하여 저장 공간 최적화
    /// 💡 Java 비교: @CacheEvict(allEntries=true)와 유사
    ///
    /// - Parameter maxCacheSize: 캐시 최대 크기
    ///
    /// - Throws: `FoodSearchError.cacheFailure`: 캐시 정리 실패
    func cleanupCache(maxCacheSize: Int) async throws {
        // 📚 학습 포인트: Early Return Pattern
        // localDataSource가 없으면 조용히 리턴
        guard let localDataSource = localDataSource else {
            #if DEBUG
            print("ℹ️ Local data source not available, skipping cache cleanup")
            #endif
            return
        }

        do {
            try await localDataSource.cleanupOldFoods(maxCount: maxCacheSize)

            #if DEBUG
            print("✅ Cache cleanup completed (max: \(maxCacheSize))")
            #endif

        } catch {
            // 캐시 정리 실패를 도메인 에러로 변환
            throw FoodSearchError.cacheFailure(error)
        }
    }
}

// MARK: - FoodLocalDataSource Protocol

/// 식품 로컬 데이터 소스 프로토콜
///
/// 📚 학습 포인트: Data Source Protocol
/// Core Data를 사용한 로컬 캐싱 인터페이스
/// 💡 Java 비교: DAO (Data Access Object) 인터페이스와 유사
///
/// - Note: 실제 구현은 FoodLocalDataSourceImpl (Phase 5.2)
protocol FoodLocalDataSource {
    /// 식품 검색 (로컬 캐시)
    func searchFoods(query: String, limit: Int) async throws -> [Food]

    /// 최근 검색한 식품 조회
    func getRecentFoods(limit: Int) async throws -> [Food]

    /// 식품 저장 (캐시)
    func saveFoods(_ foods: [Food]) async throws

    /// 접근 시간 업데이트
    func updateAccessTime(foodId: UUID) async throws

    /// 오래된 캐시 정리
    func cleanupOldFoods(maxCount: Int) async throws
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock FoodSearchRepository
///
/// 📚 학습 포인트: Mock Repository for Testing
/// 테스트에서 실제 API/DB 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock 또는 @InjectMocks와 유사
final class MockFoodSearchRepository: FoodSearchRepository {

    /// Mock 검색 결과
    var mockSearchResults: [Food] = []

    /// Mock 최근 식품
    var mockRecentFoods: [Food] = []

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 호출 추적
    var searchCallCount = 0
    var getRecentCallCount = 0
    var updateAccessTimeCallCount = 0
    var cleanupCacheCallCount = 0

    func searchFoods(
        query: String,
        limit: Int,
        offset: Int,
        useCache: Bool
    ) async throws -> [Food] {
        searchCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return Array(mockSearchResults.prefix(limit))
    }

    func getRecentFoods(limit: Int) async throws -> [Food] {
        getRecentCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        return Array(mockRecentFoods.prefix(limit))
    }

    func updateFoodAccessTime(foodId: UUID) async throws {
        updateAccessTimeCallCount += 1

        if let error = shouldThrowError {
            throw error
        }
    }

    func cleanupCache(maxCacheSize: Int) async throws {
        cleanupCacheCallCount += 1

        if let error = shouldThrowError {
            throw error
        }
    }
}
#endif

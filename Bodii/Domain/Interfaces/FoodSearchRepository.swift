//
//  FoodSearchRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Repository Pattern
// 데이터 소스를 추상화하여 도메인 레이어가 데이터 출처에 의존하지 않도록 함
// 💡 Java 비교: Spring Data Repository 인터페이스와 유사한 역할

import Foundation

/// 식품 검색 저장소 프로토콜
///
/// 📚 학습 포인트: Dependency Inversion Principle (SOLID)
/// 도메인 레이어가 데이터 레이어의 구체적인 구현에 의존하지 않도록
/// 프로토콜을 통해 추상화된 인터페이스 제공
/// 💡 Java 비교: Repository 인터페이스 (JpaRepository, CrudRepository 등)
///
/// **역할:**
/// - 식품 검색 기능의 추상화된 인터페이스 정의
/// - 도메인 레이어와 데이터 레이어 간의 경계 (Boundary)
/// - 구현체는 여러 데이터 소스를 조합하거나 선택할 수 있음
///
/// **구현 전략:**
/// - 식약처 API 우선 검색 (한국 음식)
/// - USDA API 폴백 (외국 음식)
/// - 로컬 캐시 활용 (오프라인 지원)
/// - 검색 결과 병합 및 중복 제거
///
/// **사용 예시:**
/// ```swift
/// // DIContainer에서 주입받음
/// let repository: FoodSearchRepository = container.resolve()
///
/// // 식품 검색
/// let foods = try await repository.searchFoods(
///     query: "김치찌개",
///     limit: 20,
///     useCache: true
/// )
///
/// foods.forEach { food in
///     print("\(food.name): \(food.calories)kcal (\(food.source.displayName))")
/// }
/// ```
protocol FoodSearchRepository {

    // MARK: - Search Methods

    /// 식품 검색
    ///
    /// 📚 학습 포인트: Protocol Method with Async/Throws
    /// 비동기 작업과 에러 처리를 프로토콜 레벨에서 명시
    /// 💡 Java 비교: CompletableFuture를 반환하는 메서드와 유사
    ///
    /// **검색 전략:**
    /// 1. 캐시 확인 (useCache=true인 경우)
    /// 2. 식약처 API 검색 (한국 음식 우선)
    /// 3. USDA API 검색 (폴백 또는 외국 음식)
    /// 4. 결과 병합 (한국 음식 먼저)
    /// 5. 중복 제거 (apiCode 기준)
    /// 6. 검색 결과 캐시에 저장
    ///
    /// **검색 로직:**
    /// - 한글이 포함된 검색어: 식약처 API 먼저 → USDA 폴백
    /// - 영문 검색어: USDA API 먼저 → 식약처 폴백
    /// - 빈 결과: 양쪽 API 모두 검색 → 캐시 검색
    ///
    /// - Parameters:
    ///   - query: 검색어 (식품명, 예: "김치찌개", "chicken breast")
    ///   - limit: 최대 결과 개수 (기본값: 20)
    ///   - offset: 페이징 오프셋 (기본값: 0)
    ///   - useCache: 캐시 사용 여부 (기본값: true)
    ///
    /// - Returns: 검색된 식품 도메인 엔티티 배열
    ///
    /// - Throws:
    ///   - `FoodSearchError.invalidQuery`: 검색어가 비어있거나 유효하지 않음
    ///   - `FoodSearchError.networkFailure`: 네트워크 연결 실패
    ///   - `FoodSearchError.apiError`: API 요청 실패
    ///   - `FoodSearchError.noResults`: 검색 결과 없음 (빈 배열 반환)
    ///
    /// - Note: 에러 발생 시 캐시된 결과를 반환할 수 있음 (graceful degradation)
    ///
    /// - Example:
    /// ```swift
    /// // 기본 검색
    /// let foods = try await searchFoods(query: "현미밥")
    ///
    /// // 페이징 검색
    /// let moreFoods = try await searchFoods(
    ///     query: "현미밥",
    ///     limit: 10,
    ///     offset: 10
    /// )
    ///
    /// // 캐시 없이 검색 (항상 최신 데이터)
    /// let freshFoods = try await searchFoods(
    ///     query: "현미밥",
    ///     useCache: false
    /// )
    /// ```
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int,
        useCache: Bool
    ) async throws -> [Food]

    // MARK: - Cache Methods

    /// 최근 검색한 식품 목록 조회
    ///
    /// 📚 학습 포인트: Cache-First Strategy
    /// 오프라인 지원과 빠른 응답을 위한 캐시 우선 전략
    /// 💡 Java 비교: @Cacheable 어노테이션과 유사
    ///
    /// - Parameter limit: 최대 결과 개수 (기본값: 20)
    ///
    /// - Returns: 최근 검색한 식품 목록 (lastAccessedAt 기준 정렬)
    ///
    /// - Note: 캐시에 저장된 식품만 반환 (API 호출 없음)
    ///
    /// - Example:
    /// ```swift
    /// let recentFoods = try await getRecentFoods(limit: 10)
    /// // 최근 10개 식품 반환
    /// ```
    func getRecentFoods(limit: Int) async throws -> [Food]

    /// 식품 접근 시간 업데이트
    ///
    /// 📚 학습 포인트: Activity Tracking
    /// 사용자가 식품을 선택할 때마다 접근 시간 업데이트
    /// LRU(Least Recently Used) 캐시 정책에 사용
    /// 💡 Java 비교: @CachePut과 유사
    ///
    /// - Parameter foodId: 식품 고유 ID
    ///
    /// - Note: 캐시에 없는 식품이면 무시
    ///
    /// - Example:
    /// ```swift
    /// // 사용자가 식품을 선택했을 때
    /// try await updateFoodAccessTime(foodId: food.id)
    /// ```
    func updateFoodAccessTime(foodId: UUID) async throws

    /// 캐시 정리 (LRU 정책)
    ///
    /// 📚 학습 포인트: Cache Eviction Policy
    /// 오래된 캐시 항목을 자동으로 정리하여 저장 공간 최적화
    /// 💡 Java 비교: @CacheEvict(allEntries=true)와 유사
    ///
    /// - Parameter maxCacheSize: 캐시 최대 크기 (기본값: 500)
    ///
    /// - Note: lastAccessedAt 기준으로 오래된 항목부터 삭제
    ///
    /// - Example:
    /// ```swift
    /// // 주기적으로 캐시 정리 (예: 앱 시작 시)
    /// try await cleanupCache(maxCacheSize: 500)
    /// ```
    func cleanupCache(maxCacheSize: Int) async throws
}

// MARK: - Default Parameter Values

extension FoodSearchRepository {

    /// 식품 검색 (기본 파라미터 적용)
    ///
    /// 📚 학습 포인트: Protocol Extension with Default Values
    /// 프로토콜 익스텐션을 통해 기본 파라미터 값 제공
    /// 호출 코드를 간결하게 만들고 유연성 향상
    /// 💡 Java 비교: 메서드 오버로딩과 유사한 효과
    ///
    /// - Parameter query: 검색어
    ///
    /// - Returns: 검색된 식품 배열 (최대 20개, 캐시 사용)
    func searchFoods(query: String) async throws -> [Food] {
        try await searchFoods(
            query: query,
            limit: 20,
            offset: 0,
            useCache: true
        )
    }

    /// 최근 검색한 식품 목록 조회 (기본 파라미터 적용)
    ///
    /// - Returns: 최근 20개 식품
    func getRecentFoods() async throws -> [Food] {
        try await getRecentFoods(limit: 20)
    }

    /// 캐시 정리 (기본 파라미터 적용)
    func cleanupCache() async throws {
        try await cleanupCache(maxCacheSize: 500)
    }
}

// MARK: - Search Error

/// 식품 검색 과정에서 발생할 수 있는 에러
///
/// 📚 학습 포인트: Domain-Level Error
/// 도메인 레이어에서 정의된 에러는 비즈니스 로직과 관련
/// 데이터 레이어의 기술적 에러를 도메인 에러로 변환
/// 💡 Java 비교: Custom Business Exception과 유사
enum FoodSearchError: Error {
    /// 유효하지 않은 검색어
    case invalidQuery(String)

    /// 네트워크 연결 실패
    case networkFailure(Error)

    /// API 요청 실패
    case apiError(String)

    /// 검색 결과 없음
    case noResults

    /// 캐시 작업 실패
    case cacheFailure(Error)

    /// 알 수 없는 에러
    case unknown(Error)

    /// 사용자 친화적 에러 메시지
    ///
    /// 📚 학습 포인트: LocalizedError Protocol
    /// UI에 표시할 수 있는 한글 에러 메시지 제공
    /// 💡 Java 비교: getMessage()와 유사
    var localizedDescription: String {
        switch self {
        case .invalidQuery(let message):
            return "유효하지 않은 검색어입니다: \(message)"
        case .networkFailure:
            return "네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요."
        case .apiError(let message):
            return "식품 정보를 불러오는데 실패했습니다: \(message)"
        case .noResults:
            return "검색 결과가 없습니다."
        case .cacheFailure:
            return "캐시 작업에 실패했습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }

    /// 복구 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Recoverable vs Non-Recoverable Errors
    /// 에러 유형에 따라 재시도 또는 폴백 전략 결정
    /// 💡 Java 비교: Checked vs Unchecked Exception과 유사한 개념
    var isRecoverable: Bool {
        switch self {
        case .invalidQuery:
            return false
        case .networkFailure, .apiError, .cacheFailure:
            return true
        case .noResults:
            return false
        case .unknown:
            return false
        }
    }
}

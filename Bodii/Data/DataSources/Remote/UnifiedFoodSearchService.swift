//
//  UnifiedFoodSearchService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Unified Search Service
// 여러 데이터 소스를 통합하여 단일 검색 인터페이스 제공
// 💡 Java 비교: Facade Pattern + Strategy Pattern의 조합

import Foundation

/// 통합 식품 검색 서비스
///
/// 📚 학습 포인트: Multi-Source Search Strategy
/// 식약처 API와 USDA API를 통합하여 최적의 검색 결과 제공
/// 한국 음식은 식약처 우선, 외국 음식은 USDA 우선 전략
/// 💡 Java 비교: Composite Pattern으로 여러 Repository를 조합하는 패턴과 유사
///
/// **검색 전략:**
/// 1. 검색어 분석 (한글/영문 판단)
/// 2. 한글 검색어: 식약처 먼저 → USDA 폴백
/// 3. 영문 검색어: 식약처 + USDA 병렬 검색 (USDA 우선)
/// 4. 결과 병합 (한국 음식이 항상 상위에 표시)
/// 5. 중복 제거 (apiCode 기준)
///
/// **에러 처리:**
/// - 한쪽 API 실패 시 다른 쪽 결과 반환
/// - 양쪽 API 모두 실패 시 빈 배열 반환 (에러 던지지 않음)
/// - 네트워크 에러는 로깅하고 graceful degradation
///
/// **사용 예시:**
/// ```swift
/// let service = UnifiedFoodSearchService()
///
/// // 한국 음식 검색 (식약처 우선)
/// let koreanFoods = try await service.searchFoods(query: "김치찌개", limit: 20)
///
/// // 외국 음식 검색 (USDA 포함)
/// let internationalFoods = try await service.searchFoods(query: "chicken breast", limit: 20)
/// ```
final class UnifiedFoodSearchService {

    // MARK: - Properties

    /// 식약처 API 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: @Autowired field injection
    private let kfdaService: KFDAFoodAPIService

    /// USDA API 서비스
    ///
    /// 외부에서 주입받아 테스트 시 Mock으로 교체 가능
    private let usdaService: USDAFoodAPIService

    /// 식약처 DTO to Domain 매퍼
    private let kfdaMapper: KFDAFoodMapper

    /// USDA DTO to Domain 매퍼
    private let usdaMapper: USDAFoodMapper

    // MARK: - Initialization

    /// UnifiedFoodSearchService 초기화
    ///
    /// 📚 학습 포인트: Constructor Injection
    /// 모든 의존성을 생성자를 통해 주입받아 테스트 용이성 향상
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - kfdaService: 식약처 API 서비스
    ///   - usdaService: USDA API 서비스
    ///   - kfdaMapper: 식약처 매퍼 (기본값: KFDAFoodMapper())
    ///   - usdaMapper: USDA 매퍼 (기본값: USDAFoodMapper())
    init(
        kfdaService: KFDAFoodAPIService = KFDAFoodAPIService(),
        usdaService: USDAFoodAPIService = USDAFoodAPIService(),
        kfdaMapper: KFDAFoodMapper = KFDAFoodMapper(),
        usdaMapper: USDAFoodMapper = USDAFoodMapper()
    ) {
        self.kfdaService = kfdaService
        self.usdaService = usdaService
        self.kfdaMapper = kfdaMapper
        self.usdaMapper = usdaMapper
    }

    // MARK: - Public Methods

    /// 통합 식품 검색
    ///
    /// 📚 학습 포인트: Intelligent Multi-Source Search
    /// 검색어를 분석하여 최적의 데이터 소스 선택 및 병합
    /// 💡 Java 비교: CompletableFuture를 활용한 병렬 처리와 유사
    ///
    /// **검색 로직:**
    /// 1. 검색어 분석 (한글 포함 여부 체크)
    /// 2. 한글 검색어:
    ///    - 식약처 API 먼저 검색
    ///    - 결과 부족 시(< 5개) USDA도 검색하여 추가
    /// 3. 영문 검색어:
    ///    - 식약처와 USDA 병렬 검색 (성능 최적화)
    ///    - USDA 결과를 상위에 배치
    /// 4. 중복 제거 (apiCode 기준)
    /// 5. limit 적용
    ///
    /// - Parameters:
    ///   - query: 검색어 (예: "김치찌개", "chicken")
    ///   - limit: 최대 결과 개수 (기본값: 20)
    ///   - offset: 오프셋 (현재 버전에서는 미지원, 추후 구현)
    ///
    /// - Returns: 통합 검색 결과 (Food 도메인 엔티티 배열)
    ///
    /// - Throws: 양쪽 API 모두 실패한 경우에만 에러 발생
    ///
    /// - Note: 한쪽 API 실패 시 다른 쪽 결과만 반환 (graceful degradation)
    ///
    /// - Example:
    /// ```swift
    /// // 한국 음식 검색
    /// let foods1 = try await service.searchFoods(query: "된장찌개")
    /// // → 식약처 우선, 결과 부족 시 USDA 추가
    ///
    /// // 외국 음식 검색
    /// let foods2 = try await service.searchFoods(query: "apple")
    /// // → 식약처 + USDA 병렬 검색, USDA 우선 정렬
    /// ```
    func searchFoods(
        query: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Food] {

        // 입력 검증
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw FoodSearchError.invalidQuery("검색어가 비어있습니다.")
        }

        // 검색어 분석: 한글이 포함되어 있는지 확인
        let containsKorean = containsKoreanCharacters(query)

        var allFoods: [Food] = []

        if containsKorean {
            // 📚 학습 포인트: Sequential Search with Fallback
            // 한글 검색어는 식약처 우선 → USDA 폴백 전략
            // 💡 Java 비교: try-catch with fallback pattern

            // 1단계: 식약처 검색
            let kfdaFoods = await searchKFDA(query: query, limit: limit)

            // 2단계: 식약처 결과가 충분하면 그대로 반환
            if kfdaFoods.count >= 5 {
                allFoods = kfdaFoods
            } else {
                // 3단계: 결과가 부족하면 USDA도 검색하여 추가
                let usdaFoods = await searchUSDA(query: query, limit: limit - kfdaFoods.count)

                // 4단계: 한국 음식 먼저, 외국 음식 나중에
                allFoods = kfdaFoods + usdaFoods
            }

        } else {
            // 📚 학습 포인트: Parallel Search for Performance
            // 영문 검색어는 양쪽 API를 병렬로 검색하여 성능 최적화
            // 💡 Java 비교: CompletableFuture.allOf()와 유사

            // 병렬 검색 (async let으로 동시 실행)
            async let kfdaFoodsTask = searchKFDA(query: query, limit: limit)
            async let usdaFoodsTask = searchUSDA(query: query, limit: limit)

            let (kfdaFoods, usdaFoods) = await (kfdaFoodsTask, usdaFoodsTask)

            // 📚 학습 포인트: Result Merging Strategy
            // 영문 검색어의 경우 USDA 결과가 더 정확할 가능성이 높음
            // 따라서 USDA 결과를 먼저 배치하되, 한국 음식도 포함
            // 💡 Java 비교: Stream.concat() + distinct()

            // USDA 먼저, 식약처 나중에 (외국 음식 우선)
            allFoods = usdaFoods + kfdaFoods
        }

        // 중복 제거 (apiCode 기준)
        let deduplicatedFoods = deduplicateFoods(allFoods)

        // limit 적용
        let limitedFoods = Array(deduplicatedFoods.prefix(limit))

        // 결과가 없으면 에러 던지기 (선택적)
        // 또는 빈 배열 반환 (graceful)
        // 현재는 빈 배열 반환으로 구현
        return limitedFoods
    }

    // MARK: - Private Methods

    /// 식약처 API 검색 (에러 처리 포함)
    ///
    /// 📚 학습 포인트: Error-Safe Search
    /// API 에러가 발생해도 앱이 중단되지 않도록 빈 배열 반환
    /// 💡 Java 비교: try-catch with empty list fallback
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - limit: 최대 결과 개수
    ///
    /// - Returns: 검색 결과 (에러 시 빈 배열)
    private func searchKFDA(query: String, limit: Int) async -> [Food] {
        do {
            // KFDA API는 인덱스 범위 사용 (1-based)
            let endIdx = limit
            let response = try await kfdaService.searchFoods(
                query: query,
                startIdx: 1,
                endIdx: endIdx
            )

            // DTO를 도메인 엔티티로 변환
            let foods = kfdaMapper.toDomainArray(from: response.foods)

            #if DEBUG
            print("✅ KFDA search success: \(foods.count) foods found for '\(query)'")
            #endif

            return foods

        } catch {
            // 에러 로깅 (디버그 모드)
            #if DEBUG
            print("⚠️ KFDA search failed for '\(query)': \(error.localizedDescription)")
            #endif

            // 에러 발생 시 빈 배열 반환 (graceful degradation)
            return []
        }
    }

    /// USDA API 검색 (에러 처리 포함)
    ///
    /// 📚 학습 포인트: Error-Safe Search
    /// API 에러가 발생해도 앱이 중단되지 않도록 빈 배열 반환
    /// 💡 Java 비교: try-catch with empty list fallback
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - limit: 최대 결과 개수
    ///
    /// - Returns: 검색 결과 (에러 시 빈 배열)
    private func searchUSDA(query: String, limit: Int) async -> [Food] {
        do {
            // USDA API는 페이지 번호 사용 (1-based)
            let response = try await usdaService.searchFoods(
                query: query,
                pageSize: limit,
                pageNumber: 1
            )

            // DTO를 도메인 엔티티로 변환
            let foods = usdaMapper.toDomainArray(from: response.foods ?? [])

            #if DEBUG
            print("✅ USDA search success: \(foods.count) foods found for '\(query)'")
            #endif

            return foods

        } catch {
            // 에러 로깅 (디버그 모드)
            #if DEBUG
            print("⚠️ USDA search failed for '\(query)': \(error.localizedDescription)")
            #endif

            // 에러 발생 시 빈 배열 반환 (graceful degradation)
            return []
        }
    }

    /// 검색어에 한글이 포함되어 있는지 확인
    ///
    /// 📚 학습 포인트: Unicode Range Check
    /// Swift의 유니코드 스칼라를 사용하여 한글 문자 범위 확인
    /// 💡 Java 비교: Character.UnicodeBlock.HANGUL_SYLLABLES와 유사
    ///
    /// - Parameter text: 검색어
    ///
    /// - Returns: 한글 포함 여부
    ///
    /// - Note: 한글 음절 범위: U+AC00 ~ U+D7A3 (가 ~ 힣)
    private func containsKoreanCharacters(_ text: String) -> Bool {
        // 📚 학습 포인트: Unicode Scalar Value Check
        // Swift String은 유니코드 스칼라로 구성되어 있음
        // 한글 음절 범위를 체크하여 한글 여부 판단
        // 💡 Java 비교: text.matches(".*[\\uAC00-\\uD7A3]+.*")와 유사

        for scalar in text.unicodeScalars {
            // 한글 음절 범위: U+AC00 (가) ~ U+D7A3 (힣)
            if (0xAC00...0xD7A3).contains(scalar.value) {
                return true
            }
        }

        return false
    }

    /// 중복된 식품 제거
    ///
    /// 📚 학습 포인트: Deduplication Strategy
    /// apiCode를 기준으로 중복 제거 (같은 식품이 여러 API에서 나올 수 있음)
    /// 💡 Java 비교: Stream.distinct() with custom comparator
    ///
    /// - Parameter foods: 식품 배열
    ///
    /// - Returns: 중복 제거된 식품 배열
    ///
    /// - Note: 첫 번째로 나온 식품을 유지 (순서 보존)
    ///         apiCode가 없는 식품은 name으로 중복 체크
    private func deduplicateFoods(_ foods: [Food]) -> [Food] {
        // 📚 학습 포인트: Dictionary-based Deduplication
        // 딕셔너리를 사용하여 O(n) 시간 복잡도로 중복 제거
        // 💡 Java 비교: Map을 사용한 중복 제거와 동일

        var seen = Set<String>()
        var result: [Food] = []

        for food in foods {
            // 중복 체크 키: apiCode 우선, 없으면 name 사용
            let key = food.apiCode ?? food.name

            // 이미 본 적이 있으면 스킵
            if seen.contains(key) {
                continue
            }

            // 새로운 식품이면 추가
            seen.insert(key)
            result.append(food)
        }

        return result
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Unified Search Service
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockUnifiedFoodSearchService {

    /// Mock 검색 결과
    var mockSearchResults: [Food] = []

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 검색 메서드 Mock
    func searchFoods(
        query: String,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Food] {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 결과 반환 (limit 적용)
        return Array(mockSearchResults.prefix(limit))
    }
}
#endif

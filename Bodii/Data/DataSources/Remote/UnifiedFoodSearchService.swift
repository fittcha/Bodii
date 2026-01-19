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
import CoreData

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
/// **에러 처리 및 재시도:**
/// - 각 API 호출은 최대 2회 재시도 (지수 백오프: 1초, 2초)
/// - 일시적 네트워크 에러(timeout, connection lost)는 자동 재시도
/// - 영구적 에러(401, 400, parsing error)는 즉시 폴백
/// - 한쪽 API 실패 시 다른 쪽 결과 반환
/// - 양쪽 API 모두 실패 시 빈 배열 반환 (graceful degradation)
/// - 모든 에러는 디버그 로그에 상세 기록
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

    /// Core Data context
    ///
    /// 📚 학습 포인트: Core Data Context Injection
    /// Food가 Core Data 엔티티이므로 context가 필요
    /// 💡 Java 비교: EntityManager 주입과 유사
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// UnifiedFoodSearchService 초기화
    ///
    /// 📚 학습 포인트: Constructor Injection
    /// 모든 의존성을 생성자를 통해 주입받아 테스트 용이성 향상
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - context: Core Data NSManagedObjectContext
    ///   - kfdaService: 식약처 API 서비스
    ///   - usdaService: USDA API 서비스
    ///   - kfdaMapper: 식약처 매퍼 (기본값: KFDAFoodMapper())
    ///   - usdaMapper: USDA 매퍼 (기본값: USDAFoodMapper())
    init(
        context: NSManagedObjectContext,
        kfdaService: KFDAFoodAPIService = KFDAFoodAPIService(),
        usdaService: USDAFoodAPIService = USDAFoodAPIService(),
        kfdaMapper: KFDAFoodMapper = KFDAFoodMapper(),
        usdaMapper: USDAFoodMapper = USDAFoodMapper()
    ) {
        self.context = context
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
    /// - Note: 각 API는 최대 2회 재시도하며, 한쪽 API 실패 시 다른 쪽 결과만 반환 (graceful degradation)
    ///         양쪽 API 모두 실패 시 빈 배열 반환 (에러를 던지지 않음)
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
            // 💡 Java 비교: Circuit Breaker + Fallback pattern

            // 1단계: 식약처 검색 (재시도 포함)
            let kfdaFoods = await searchKFDA(query: query, limit: limit)

            // 2단계: 식약처 결과가 충분하면 그대로 반환
            if kfdaFoods.count >= 5 {
                allFoods = kfdaFoods

                #if DEBUG
                print("✅ Korean query: Sufficient KFDA results (\(kfdaFoods.count) items)")
                #endif

            } else {
                // 3단계: 결과가 부족하면 USDA도 검색하여 추가
                #if DEBUG
                print("⚠️ Korean query: Insufficient KFDA results (\(kfdaFoods.count) items), searching USDA as fallback")
                #endif

                let usdaFoods = await searchUSDA(query: query, limit: limit - kfdaFoods.count)

                // 4단계: 한국 음식 먼저, 외국 음식 나중에
                allFoods = kfdaFoods + usdaFoods

                #if DEBUG
                if kfdaFoods.isEmpty && usdaFoods.isEmpty {
                    print("❌ Both KFDA and USDA search failed - returning empty results")
                } else {
                    print("✅ Fallback successful: \(kfdaFoods.count) KFDA + \(usdaFoods.count) USDA = \(allFoods.count) total")
                }
                #endif
            }

        } else {
            // 📚 학습 포인트: Parallel Search for Performance
            // 영문 검색어는 양쪽 API를 병렬로 검색하여 성능 최적화
            // 💡 Java 비교: CompletableFuture.allOf()와 유사

            #if DEBUG
            print("🔄 English query: Searching KFDA and USDA in parallel")
            #endif

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

            #if DEBUG
            if kfdaFoods.isEmpty && usdaFoods.isEmpty {
                print("❌ Both KFDA and USDA search failed for English query")
            } else {
                print("✅ Parallel search successful: \(usdaFoods.count) USDA + \(kfdaFoods.count) KFDA = \(allFoods.count) total")
            }
            #endif
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

    /// 식약처 API 검색 (에러 처리 및 재시도 포함)
    ///
    /// 📚 학습 포인트: Retry Logic with Exponential Backoff
    /// API 에러 발생 시 지수 백오프를 사용하여 자동 재시도
    /// 최대 2회 재시도 후에도 실패하면 에러를 상위로 전달
    /// 💡 Java 비교: Spring Retry의 @Retryable과 유사
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - limit: 최대 결과 개수
    ///   - retryCount: 현재 재시도 횟수 (내부용)
    ///
    /// - Returns: 검색 결과 (에러 시 빈 배열)
    ///
    /// - Throws: 재시도 후에도 실패 시 FoodSearchError
    private func searchKFDA(
        query: String,
        limit: Int,
        retryCount: Int = 0
    ) async -> [Food] {
        do {
            // KFDA API는 인덱스 범위 사용 (1-based)
            let endIdx = limit
            let response = try await kfdaService.searchFoods(
                query: query,
                startIdx: 1,
                endIdx: endIdx
            )

            // DTO를 도메인 엔티티로 변환
            let foods = kfdaMapper.toDomainArray(from: response.foods, context: context)

            #if DEBUG
            print("✅ KFDA search success: \(foods.count) foods found for '\(query)' (retry: \(retryCount))")
            #endif

            return foods

        } catch {
            // 에러 분석 및 로깅
            let errorType = classifyError(error)

            #if DEBUG
            print("⚠️ KFDA search failed for '\(query)': \(errorType) - \(error.localizedDescription)")
            #endif

            // 📚 학습 포인트: Retry Strategy
            // 일시적 네트워크 에러는 재시도, 영구적 에러는 즉시 반환
            // 💡 Java 비교: Resilience4j의 retry pattern과 유사

            let maxRetries = Constants.API.KFDA.maxRetries
            let shouldRetry = retryCount < maxRetries && isRetryableError(error)

            if shouldRetry {
                // 지수 백오프: 1초, 2초, 4초...
                let delay = pow(2.0, Double(retryCount))

                #if DEBUG
                print("🔄 Retrying KFDA search in \(delay)s... (attempt \(retryCount + 1)/\(maxRetries))")
                #endif

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // 재시도
                return await searchKFDA(query: query, limit: limit, retryCount: retryCount + 1)
            }

            // 재시도 불가능하거나 최대 재시도 횟수 초과
            #if DEBUG
            print("❌ KFDA search failed after \(retryCount) retries for '\(query)'")
            #endif

            // 에러 발생 시 빈 배열 반환 (graceful degradation)
            // 상위 레벨에서 USDA 폴백이 작동함
            return []
        }
    }

    /// USDA API 검색 (에러 처리 및 재시도 포함)
    ///
    /// 📚 학습 포인트: Retry Logic with Exponential Backoff
    /// API 에러 발생 시 지수 백오프를 사용하여 자동 재시도
    /// 최대 2회 재시도 후에도 실패하면 에러를 상위로 전달
    /// 💡 Java 비교: Spring Retry의 @Retryable과 유사
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - limit: 최대 결과 개수
    ///   - retryCount: 현재 재시도 횟수 (내부용)
    ///
    /// - Returns: 검색 결과 (에러 시 빈 배열)
    ///
    /// - Throws: 재시도 후에도 실패 시 FoodSearchError
    private func searchUSDA(
        query: String,
        limit: Int,
        retryCount: Int = 0
    ) async -> [Food] {
        do {
            // USDA API는 페이지 번호 사용 (1-based)
            let response = try await usdaService.searchFoods(
                query: query,
                pageSize: limit,
                pageNumber: 1
            )

            // DTO를 도메인 엔티티로 변환
            let foods = usdaMapper.toDomainArray(from: response.foods ?? [], context: context)

            #if DEBUG
            print("✅ USDA search success: \(foods.count) foods found for '\(query)' (retry: \(retryCount))")
            #endif

            return foods

        } catch {
            // 에러 분석 및 로깅
            let errorType = classifyError(error)

            #if DEBUG
            print("⚠️ USDA search failed for '\(query)': \(errorType) - \(error.localizedDescription)")
            #endif

            // 📚 학습 포인트: Retry Strategy
            // 일시적 네트워크 에러는 재시도, 영구적 에러는 즉시 반환
            // 💡 Java 비교: Resilience4j의 retry pattern과 유사

            let maxRetries = Constants.API.USDA.maxRetries
            let shouldRetry = retryCount < maxRetries && isRetryableError(error)

            if shouldRetry {
                // 지수 백오프: 1초, 2초, 4초...
                let delay = pow(2.0, Double(retryCount))

                #if DEBUG
                print("🔄 Retrying USDA search in \(delay)s... (attempt \(retryCount + 1)/\(maxRetries))")
                #endif

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // 재시도
                return await searchUSDA(query: query, limit: limit, retryCount: retryCount + 1)
            }

            // 재시도 불가능하거나 최대 재시도 횟수 초과
            #if DEBUG
            print("❌ USDA search failed after \(retryCount) retries for '\(query)'")
            #endif

            // 에러 발생 시 빈 배열 반환 (graceful degradation)
            return []
        }
    }

    /// 에러가 재시도 가능한지 판단
    ///
    /// 📚 학습 포인트: Retry Decision Logic
    /// 일시적 네트워크 문제는 재시도 가능, 영구적 에러는 불가능
    /// 💡 Java 비교: Spring Retry의 RetryPolicy와 유사
    ///
    /// - Parameter error: 발생한 에러
    ///
    /// - Returns: 재시도 가능 여부
    ///
    /// **재시도 가능한 에러:**
    /// - 네트워크 연결 실패 (일시적)
    /// - 타임아웃
    /// - 서버 에러 (5xx)
    /// - Rate limit (429)
    ///
    /// **재시도 불가능한 에러:**
    /// - 인증 실패 (401)
    /// - 잘못된 요청 (400)
    /// - 리소스 없음 (404)
    /// - JSON 파싱 에러
    private func isRetryableError(_ error: Error) -> Bool {
        // NetworkError 체크
        if let networkError = error as? NetworkError {
            switch networkError {
            case .timeout,
                 .networkUnavailable:
                return true // 재시도 가능

            case .httpError(let statusCode, _):
                // 5xx 서버 에러와 429 Rate Limit는 재시도 가능
                return statusCode >= 500 || statusCode == 429

            case .invalidURL,
                 .noData,
                 .decodingFailed,
                 .invalidResponse,
                 .unknown:
                return false // 재시도 불가능
            }
        }

        // 기타 에러는 재시도 가능하다고 가정 (보수적 접근)
        return true
    }

    /// 에러 타입 분류 (로깅용)
    ///
    /// 📚 학습 포인트: Error Classification
    /// 에러를 사람이 읽기 쉬운 형태로 분류하여 디버깅 향상
    /// 💡 Java 비교: Custom Exception 계층 구조와 유사
    ///
    /// - Parameter error: 발생한 에러
    ///
    /// - Returns: 에러 타입 문자열 (로깅용)
    private func classifyError(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .timeout:
                return "TIMEOUT"
            case .networkUnavailable:
                return "OFFLINE"
            case .httpError(let statusCode, _):
                if statusCode == 429 {
                    return "RATE_LIMIT"
                } else if statusCode >= 500 {
                    return "SERVER_ERROR"
                } else if statusCode == 401 || statusCode == 403 {
                    return "AUTH_ERROR"
                } else {
                    return "HTTP_ERROR_\(statusCode)"
                }
            case .decodingFailed:
                return "PARSING_ERROR"
            case .invalidURL:
                return "INVALID_URL"
            case .noData:
                return "NO_DATA"
            case .invalidResponse:
                return "INVALID_RESPONSE"
            case .unknown:
                return "UNKNOWN"
            }
        }

        // FoodSearchError 체크
        if let searchError = error as? FoodSearchError {
            switch searchError {
            case .invalidQuery:
                return "INVALID_QUERY"
            case .networkFailure:
                return "NETWORK_FAILURE"
            case .timeout:
                return "TIMEOUT"
            case .offline:
                return "OFFLINE"
            case .rateLimitExceeded:
                return "RATE_LIMIT"
            case .apiError:
                return "API_ERROR"
            case .kfdaApiError:
                return "KFDA_API_ERROR"
            case .usdaApiError:
                return "USDA_API_ERROR"
            case .authenticationFailed:
                return "AUTH_FAILED"
            case .parsingError:
                return "PARSING_ERROR"
            case .decodingFailed:
                return "DECODING_FAILED"
            case .cacheFailure:
                return "CACHE_ERROR"
            case .cacheUnavailable:
                return "CACHE_UNAVAILABLE"
            case .noResults:
                return "NO_RESULTS"
            case .insufficientData:
                return "INSUFFICIENT_DATA"
            case .unknown:
                return "UNKNOWN"
            }
        }

        // 기타 에러
        return "UNKNOWN_ERROR"
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
            let key = food.apiCode ?? food.name ?? UUID().uuidString

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

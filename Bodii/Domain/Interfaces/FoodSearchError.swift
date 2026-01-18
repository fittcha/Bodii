//
//  FoodSearchError.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Domain-Level Error Handling
// 식품 검색 도메인에서 발생할 수 있는 모든 에러를 체계적으로 정의
// 비즈니스 로직과 기술적 에러를 구분하여 관리
// 💡 Java 비교: Custom Business Exception 계층 구조와 유사

import Foundation

/// 식품 검색 과정에서 발생할 수 있는 에러
///
/// 📚 학습 포인트: Comprehensive Error Types
/// 도메인 레이어에서 정의된 에러는 비즈니스 로직과 관련된 에러를 표현합니다.
/// 데이터 레이어의 기술적 에러(NetworkError, CoreDataError 등)를
/// 도메인 레벨의 의미 있는 에러로 변환합니다.
/// 💡 Java 비교: Custom Business Exception (Service Layer)
///
/// **에러 카테고리:**
/// - **입력 검증**: invalidQuery
/// - **네트워크**: networkFailure, timeout, offline, rateLimitExceeded
/// - **API**: apiError, kfdaApiError, usdaApiError, authenticationFailed
/// - **파싱**: parsingError, decodingFailed
/// - **캐시**: cacheFailure, cacheUnavailable
/// - **데이터**: noResults, insufficientData
/// - **기타**: unknown
///
/// **에러 처리 전략:**
/// - **복구 가능(Recoverable)**: 재시도, 폴백, 캐시 사용 등으로 복구
///   * 예: networkFailure, timeout, apiError, cacheFailure
/// - **복구 불가(Non-recoverable)**: 사용자에게 에러 메시지 표시 후 중단
///   * 예: invalidQuery, authenticationFailed, parsingError
///
/// **사용 예시:**
/// ```swift
/// do {
///     let foods = try await repository.searchFoods(query: "김치찌개")
/// } catch FoodSearchError.offline {
///     // 캐시에서 검색
///     showOfflineMessage()
/// } catch FoodSearchError.noResults {
///     // 검색 결과 없음 메시지
///     showNoResultsView()
/// } catch let error as FoodSearchError {
///     if error.isRecoverable {
///         // 재시도 옵션 제공
///         showRetryButton()
///     } else {
///         // 에러 메시지 표시
///         showError(error.localizedDescription)
///     }
/// }
/// ```
public enum FoodSearchError: Error {

    // MARK: - Input Validation Errors

    /// 유효하지 않은 검색어
    ///
    /// 검색어가 비어있거나, 너무 짧거나, 유효하지 않은 문자가 포함된 경우
    ///
    /// - Parameter message: 구체적인 검증 실패 사유
    ///
    /// - Example:
    /// ```swift
    /// throw FoodSearchError.invalidQuery("검색어는 2글자 이상이어야 합니다")
    /// ```
    case invalidQuery(String)

    // MARK: - Network Errors

    /// 네트워크 연결 실패
    ///
    /// 일반적인 네트워크 에러 (서버 응답 없음, DNS 실패 등)
    ///
    /// - Parameter error: 원본 네트워크 에러
    ///
    /// - Note: 재시도 또는 캐시 폴백으로 복구 가능
    case networkFailure(Error)

    /// 요청 시간 초과
    ///
    /// API 요청이 설정된 제한 시간(30초) 내에 완료되지 않음
    ///
    /// - Note: 재시도로 복구 가능 (네트워크 상태 개선 시)
    case timeout

    /// 오프라인 상태 (인터넷 연결 없음)
    ///
    /// 📚 학습 포인트: Offline Detection
    /// 디바이스가 인터넷에 연결되어 있지 않은 상태
    /// 캐시 폴백 전략으로 graceful degradation 구현
    /// 💡 Java 비교: NetworkUnavailableException
    ///
    /// - Note: 캐시에서 검색 결과를 제공하여 복구 가능
    ///
    /// - Example:
    /// ```swift
    /// catch FoodSearchError.offline {
    ///     let cachedResults = try await repository.getRecentFoods()
    ///     return cachedResults
    /// }
    /// ```
    case offline

    /// API 요청 제한 초과 (Rate Limit)
    ///
    /// 📚 학습 포인트: Rate Limiting
    /// 짧은 시간 내에 너무 많은 요청을 보내 API 제한에 걸림
    /// 식약처 API: 하루 1000회 제한
    /// USDA API: 시간당 1000회 제한
    /// 💡 Java 비교: RateLimitExceededException
    ///
    /// - Parameter retryAfter: 재시도 가능한 시간 (초 단위)
    ///
    /// - Note: 일정 시간 대기 후 재시도 또는 캐시 사용
    ///
    /// - Example:
    /// ```swift
    /// catch FoodSearchError.rateLimitExceeded(let seconds) {
    ///     showMessage("잠시 후 (\(seconds)초) 다시 시도해주세요")
    /// }
    /// ```
    case rateLimitExceeded(retryAfter: Int?)

    // MARK: - API Errors

    /// API 요청 실패 (일반)
    ///
    /// HTTP 에러, 서버 에러 등 API 레벨의 에러
    ///
    /// - Parameter message: API 에러 메시지
    ///
    /// - Example:
    /// ```swift
    /// throw FoodSearchError.apiError("서버 점검 중입니다 (500)")
    /// ```
    case apiError(String)

    /// 식약처 API 에러
    ///
    /// 📚 학습 포인트: API-Specific Errors
    /// 각 API별로 구체적인 에러 정보를 제공하여 디버깅 용이
    /// 💡 Java 비교: API별 Custom Exception
    ///
    /// - Parameters:
    ///   - code: 식약처 API 결과 코드 (예: "01", "99")
    ///   - message: 식약처 API 에러 메시지
    ///
    /// - Note: USDA 폴백으로 복구 가능
    case kfdaApiError(code: String, message: String)

    /// USDA API 에러
    ///
    /// USDA FoodData Central API에서 반환한 에러
    ///
    /// - Parameters:
    ///   - statusCode: HTTP 상태 코드
    ///   - message: USDA API 에러 메시지
    ///
    /// - Note: 식약처 API 재시도 또는 캐시 폴백으로 복구 시도
    case usdaApiError(statusCode: Int, message: String)

    /// API 인증 실패
    ///
    /// 📚 학습 포인트: Authentication Error
    /// API 키가 유효하지 않거나 만료된 경우
    /// 💡 Java 비교: AuthenticationException
    ///
    /// - Parameter message: 인증 실패 사유
    ///
    /// - Note: 복구 불가 - 개발자가 API 키를 확인해야 함
    ///
    /// - Example:
    /// ```swift
    /// throw FoodSearchError.authenticationFailed("API 키가 유효하지 않습니다")
    /// ```
    case authenticationFailed(String)

    // MARK: - Parsing Errors

    /// 파싱 에러 (일반)
    ///
    /// API 응답을 파싱하는 과정에서 발생한 에러
    ///
    /// - Parameter message: 파싱 실패 사유
    ///
    /// - Note: API 응답 형식이 변경되었을 가능성 - 개발자 확인 필요
    case parsingError(String)

    /// JSON 디코딩 실패
    ///
    /// 📚 학습 포인트: Decoding Error
    /// Codable 프로토콜을 사용한 JSON 디코딩 실패
    /// 💡 Java 비교: JsonParseException, JsonMappingException
    ///
    /// - Parameters:
    ///   - type: 디코딩 시도한 타입 이름
    ///   - error: 원본 디코딩 에러
    ///
    /// - Note: API 응답 스키마 변경 가능성 - 개발자 확인 필요
    ///
    /// - Example:
    /// ```swift
    /// catch let error as DecodingError {
    ///     throw FoodSearchError.decodingFailed(
    ///         type: "KFDAFoodDTO",
    ///         error: error
    ///     )
    /// }
    /// ```
    case decodingFailed(type: String, error: Error)

    // MARK: - Cache Errors

    /// 캐시 작업 실패
    ///
    /// 로컬 캐시 읽기/쓰기 실패 (Core Data 에러 등)
    ///
    /// - Parameter error: 원본 캐시 에러
    ///
    /// - Note: 캐시 실패해도 API 검색은 계속 진행 가능 (graceful degradation)
    case cacheFailure(Error)

    /// 캐시 사용 불가
    ///
    /// 📚 학습 포인트: Cache Unavailability
    /// 캐시 시스템이 초기화되지 않았거나 사용할 수 없는 상태
    /// 💡 Java 비교: CacheNotAvailableException
    ///
    /// - Note: API 검색으로 복구 가능
    case cacheUnavailable

    // MARK: - Data Errors

    /// 검색 결과 없음
    ///
    /// 📚 학습 포인트: Empty Result vs Error
    /// 결과가 없는 것은 에러가 아니지만, 명시적 처리가 필요한 경우
    /// 빈 배열 반환 대신 에러로 처리하여 UI에서 "결과 없음" 메시지 표시
    /// 💡 Java 비교: NoResultException (Optional 사용 대신)
    ///
    /// - Note: 에러라기보다는 정상 상태의 하나 (빈 결과)
    ///
    /// - Example:
    /// ```swift
    /// catch FoodSearchError.noResults {
    ///     showEmptyStateView("검색 결과가 없습니다")
    /// }
    /// ```
    case noResults

    /// 불충분한 데이터
    ///
    /// API 응답은 성공했지만 필수 영양 정보가 누락됨
    ///
    /// - Parameter message: 누락된 데이터 설명
    ///
    /// - Note: 데이터 검증 단계에서 발생 - 다른 API로 재검색 시도
    ///
    /// - Example:
    /// ```swift
    /// if food.calories == nil || food.protein == nil {
    ///     throw FoodSearchError.insufficientData(
    ///         "필수 영양 정보(칼로리, 단백질)가 없습니다"
    ///     )
    /// }
    /// ```
    case insufficientData(String)

    // MARK: - Unknown Error

    /// 알 수 없는 에러
    ///
    /// 위의 카테고리에 해당하지 않는 예기치 않은 에러
    ///
    /// - Parameter error: 원본 에러
    ///
    /// - Note: 개발 중 발견되면 적절한 에러 타입으로 분류 필요
    case unknown(Error)
}

// MARK: - LocalizedError

/// 사용자 친화적인 에러 메시지 제공
///
/// 📚 학습 포인트: LocalizedError Protocol
/// 에러에 대한 지역화된(한국어) 메시지를 제공하여 UI에서 바로 사용 가능
/// 💡 Java 비교: getMessage()와 유사하지만 프로토콜 기반으로 더 체계적
extension FoodSearchError: LocalizedError {

    /// 사용자에게 표시할 에러 설명 (한국어)
    ///
    /// 📚 학습 포인트: User-Facing Error Messages
    /// 기술적 세부사항을 숨기고 사용자가 이해하기 쉬운 메시지 제공
    /// 💡 Java 비교: 국제화(i18n) 메시지와 유사
    ///
    /// - Returns: 한국어 에러 메시지
    public var errorDescription: String? {
        switch self {
        // Input Validation
        case .invalidQuery(let message):
            return "유효하지 않은 검색어입니다: \(message)"

        // Network Errors
        case .networkFailure:
            return "네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요."

        case .timeout:
            return "요청 시간이 초과되었습니다. 다시 시도해주세요."

        case .offline:
            return "인터넷에 연결되어 있지 않습니다. 연결 후 다시 시도해주세요."

        case .rateLimitExceeded(let seconds):
            if let seconds = seconds {
                return "요청 횟수 제한을 초과했습니다. \(seconds)초 후 다시 시도해주세요."
            } else {
                return "요청 횟수 제한을 초과했습니다. 잠시 후 다시 시도해주세요."
            }

        // API Errors
        case .apiError(let message):
            return "식품 정보를 불러오는데 실패했습니다: \(message)"

        case .kfdaApiError(let code, let message):
            return "식약처 API 에러 (코드 \(code)): \(message)"

        case .usdaApiError(let statusCode, let message):
            return "USDA API 에러 (상태 \(statusCode)): \(message)"

        case .authenticationFailed(let message):
            return "인증에 실패했습니다: \(message)"

        // Parsing Errors
        case .parsingError(let message):
            return "데이터 처리 중 오류가 발생했습니다: \(message)"

        case .decodingFailed(let type, _):
            return "데이터 형식이 올바르지 않습니다 (타입: \(type))"

        // Cache Errors
        case .cacheFailure:
            return "캐시 작업에 실패했습니다."

        case .cacheUnavailable:
            return "캐시를 사용할 수 없습니다."

        // Data Errors
        case .noResults:
            return "검색 결과가 없습니다."

        case .insufficientData(let message):
            return "불완전한 식품 정보입니다: \(message)"

        // Unknown
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

// MARK: - Recovery Strategy

extension FoodSearchError {

    /// 복구 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Recoverable vs Non-Recoverable Errors
    /// 에러 유형에 따라 재시도, 폴백 등의 복구 전략을 결정
    /// 💡 Java 비교: Checked vs Unchecked Exception과 유사한 개념
    ///
    /// **복구 전략:**
    /// - **복구 가능**: 재시도, 다른 API 사용, 캐시 사용 등
    ///   * networkFailure → 재시도 또는 캐시 폴백
    ///   * timeout → 재시도
    ///   * offline → 캐시 폴백
    ///   * apiError → 다른 API로 재시도 또는 캐시 폴백
    ///   * cacheFailure → API 검색 계속 진행
    ///
    /// - **복구 불가**: 사용자에게 에러 메시지 표시
    ///   * invalidQuery → 사용자가 검색어 수정 필요
    ///   * authenticationFailed → 개발자가 API 키 확인 필요
    ///   * parsingError → 개발자가 코드 수정 필요
    ///
    /// - Returns: 복구 가능하면 true, 불가능하면 false
    ///
    /// - Example:
    /// ```swift
    /// catch let error as FoodSearchError {
    ///     if error.isRecoverable {
    ///         // 재시도 또는 폴백 전략 실행
    ///         let cachedResults = try await searchFromCache()
    ///     } else {
    ///         // 사용자에게 에러 메시지 표시
    ///         showAlert(error.errorDescription)
    ///     }
    /// }
    /// ```
    public var isRecoverable: Bool {
        switch self {
        // Recoverable Errors (재시도 또는 폴백 가능)
        case .networkFailure,
             .timeout,
             .offline,
             .rateLimitExceeded,
             .apiError,
             .kfdaApiError,
             .usdaApiError,
             .cacheFailure,
             .cacheUnavailable:
            return true

        // Non-Recoverable Errors (사용자 또는 개발자 개입 필요)
        case .invalidQuery,
             .authenticationFailed,
             .parsingError,
             .decodingFailed,
             .noResults,
             .insufficientData,
             .unknown:
            return false
        }
    }

    /// 재시도 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Retry Strategy
    /// 일시적인 네트워크 문제 등은 재시도로 해결 가능
    /// 💡 Java 비교: @Retryable 어노테이션 조건
    ///
    /// **재시도 전략:**
    /// - 최대 2회 재시도 (NetworkManager에서 처리)
    /// - Exponential backoff 적용 (1초, 2초)
    /// - 재시도 불가능한 에러는 즉시 폴백
    ///
    /// - Returns: 재시도 가능하면 true
    ///
    /// - Example:
    /// ```swift
    /// var retryCount = 0
    /// while retryCount < maxRetries {
    ///     do {
    ///         return try await searchFoods()
    ///     } catch let error as FoodSearchError {
    ///         if error.canRetry {
    ///             retryCount += 1
    ///             await Task.sleep(retryCount * 1_000_000_000) // 1초씩 증가
    ///         } else {
    ///             throw error
    ///         }
    ///     }
    /// }
    /// ```
    public var canRetry: Bool {
        switch self {
        case .networkFailure,
             .timeout,
             .apiError,
             .kfdaApiError,
             .usdaApiError:
            return true

        default:
            return false
        }
    }

    /// 캐시 폴백 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Fallback Strategy
    /// API 실패 시 캐시에서 결과를 제공하여 graceful degradation
    /// 💡 Java 비교: Circuit Breaker 패턴의 폴백 메서드
    ///
    /// - Returns: 캐시 폴백 가능하면 true
    ///
    /// - Example:
    /// ```swift
    /// catch let error as FoodSearchError {
    ///     if error.shouldFallbackToCache {
    ///         return try await searchFromCache(query: query)
    ///     } else {
    ///         throw error
    ///     }
    /// }
    /// ```
    public var shouldFallbackToCache: Bool {
        switch self {
        case .networkFailure,
             .timeout,
             .offline,
             .rateLimitExceeded,
             .apiError,
             .kfdaApiError,
             .usdaApiError:
            return true

        default:
            return false
        }
    }
}

// MARK: - Error Mapping Helpers

extension FoodSearchError {

    /// NetworkError를 FoodSearchError로 변환
    ///
    /// 📚 학습 포인트: Error Mapping
    /// 하위 레벨(Infrastructure)의 에러를 상위 레벨(Domain)의 에러로 변환
    /// 도메인 레이어는 기술적 세부사항(NetworkError)에 의존하지 않음
    /// 💡 Java 비교: Exception Translation (Spring의 @Repository와 유사)
    ///
    /// - Parameter networkError: 네트워크 에러
    ///
    /// - Returns: 변환된 FoodSearchError
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let data = try await networkManager.request(...)
    /// } catch let error as NetworkError {
    ///     throw FoodSearchError.from(networkError: error)
    /// }
    /// ```
    static func from(networkError: NetworkError) -> FoodSearchError {
        switch networkError {
        case .invalidURL:
            return .parsingError("잘못된 URL입니다")

        case .noData:
            return .apiError("서버 응답에 데이터가 없습니다")

        case .decodingFailed(let error):
            return .decodingFailed(type: "Unknown", error: error)

        case .invalidResponse:
            return .apiError("서버 응답 형식이 올바르지 않습니다")

        case .httpError(let statusCode, let message):
            if statusCode == 401 || statusCode == 403 {
                return .authenticationFailed(message)
            } else if statusCode == 429 {
                return .rateLimitExceeded(retryAfter: nil)
            } else {
                return .apiError("HTTP \(statusCode): \(message)")
            }

        case .timeout:
            return .timeout

        case .networkUnavailable:
            return .offline

        case .unknown(let error):
            return .unknown(error)
        }
    }
}

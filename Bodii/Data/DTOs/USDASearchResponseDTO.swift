//
//  USDASearchResponseDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: USDA API Response Wrapper
// USDA API의 검색 응답 구조 (KFDA의 Header+Body와 다른 단순 구조)
// 💡 Java 비교: Page<T> wrapper - 페이징 정보가 포함된 응답 래퍼

import Foundation

/// USDA FoodData Central API 검색 응답 DTO
///
/// 📚 학습 포인트: Simple Response Structure
/// USDA API는 KFDA의 Header+Body 구조와 달리 단순한 응답 구조 사용
/// 에러는 HTTP 상태 코드로 처리
/// 💡 Java 비교: REST API의 표준 페이징 응답 형식
///
/// **API 응답 구조:**
/// ```json
/// {
///   "totalHits": 156,
///   "currentPage": 1,
///   "totalPages": 16,
///   "pageList": [1, 2, 3, 4, 5],
///   "foodSearchCriteria": {
///     "query": "apple",
///     "pageSize": 10,
///     "pageNumber": 1
///   },
///   "foods": [
///     { "fdcId": 123456, "description": "Apple, raw", ... },
///     ...
///   ]
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let response: USDASearchResponseDTO = try await networkManager.request(
///     url: usdaSearchURL,
///     method: .get
/// )
///
/// let foods = response.foods ?? []
/// print("Found \(response.totalHits) foods, showing page \(response.currentPage) of \(response.totalPages)")
///
/// if response.hasMorePages {
///     // 다음 페이지 로드
/// }
/// ```
///
/// **참고:**
/// - API 문서: https://fdc.nal.usda.gov/api-guide.html
/// - Search endpoint: GET /v1/foods/search
struct USDASearchResponseDTO: Codable {

    // MARK: - 검색 결과 정보

    /// 전체 검색 결과 수
    ///
    /// 검색 조건에 맞는 총 식품 개수
    /// 페이징 처리에 사용
    let totalHits: Int

    /// 현재 페이지 번호
    ///
    /// 1부터 시작하는 현재 페이지 번호
    let currentPage: Int

    /// 전체 페이지 수
    ///
    /// 전체 결과를 페이지로 나눈 총 페이지 수
    let totalPages: Int

    /// 페이지 번호 목록 (선택적)
    ///
    /// 사용 가능한 페이지 번호 목록
    /// UI에서 페이지네이션 버튼 표시에 사용
    let pageList: [Int]?

    // MARK: - 검색 조건

    /// 검색 조건 정보
    ///
    /// 📚 학습 포인트: Nested Object
    /// 요청 시 사용한 검색 조건을 응답에 포함
    /// 💡 Java 비교: Echo back pattern - 요청 파라미터 확인용
    let foodSearchCriteria: SearchCriteria?

    // MARK: - 검색 결과

    /// 식품 목록
    ///
    /// 현재 페이지의 식품 데이터 배열
    /// 검색 결과가 없으면 빈 배열 또는 nil
    let foods: [USDAFoodDTO]?

    // MARK: - Nested Types

    /// 📚 학습 포인트: Nested Struct for Related Data
    /// 검색 조건을 별도 구조체로 정의하여 응답 구조 명확화
    /// 💡 Java 비교: Inner Class와 유사
    ///
    /// **검색 조건 구조:**
    /// - query: 검색어
    /// - dataType: 식품 타입 필터 (선택적)
    /// - pageSize: 페이지 크기
    /// - pageNumber: 페이지 번호
    /// - sortBy: 정렬 기준 (선택적)
    /// - sortOrder: 정렬 순서 (선택적)
    struct SearchCriteria: Codable {
        /// 검색어
        let query: String?

        /// 식품 타입 필터
        ///
        /// 특정 타입으로 필터링 (예: ["Branded", "Foundation"])
        let dataType: [String]?

        /// 페이지 크기
        ///
        /// 한 페이지에 표시할 결과 수
        let pageSize: Int

        /// 페이지 번호
        ///
        /// 요청한 페이지 번호 (1부터 시작)
        let pageNumber: Int

        /// 정렬 기준 (선택적)
        ///
        /// 정렬 필드명 (예: "dataType.keyword", "lowercaseDescription.keyword")
        let sortBy: String?

        /// 정렬 순서 (선택적)
        ///
        /// "asc" 또는 "desc"
        let sortOrder: String?

        /// 브랜드 소유자 필터 (선택적)
        ///
        /// Branded 식품의 브랜드로 필터링
        let brandOwner: String?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case query = "query"
            case dataType = "dataType"
            case pageSize = "pageSize"
            case pageNumber = "pageNumber"
            case sortBy = "sortBy"
            case sortOrder = "sortOrder"
            case brandOwner = "brandOwner"
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case totalHits = "totalHits"
        case currentPage = "currentPage"
        case totalPages = "totalPages"
        case pageList = "pageList"
        case foodSearchCriteria = "foodSearchCriteria"
        case foods = "foods"
    }
}

// MARK: - Convenience Methods

extension USDASearchResponseDTO {

    /// 검색 결과가 있는지 확인
    ///
    /// 📚 학습 포인트: Computed Property
    /// 자주 사용하는 검증 로직을 프로퍼티로 제공
    /// 💡 Java 비교: getter 메서드와 동일하지만 더 간결
    ///
    /// - Returns: 식품이 하나라도 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// if response.hasResults {
    ///     displayFoods(response.foods ?? [])
    /// } else {
    ///     showNoResultsMessage()
    /// }
    /// ```
    var hasResults: Bool {
        return totalHits > 0 && !(foods?.isEmpty ?? true)
    }

    /// 다음 페이지가 있는지 확인
    ///
    /// 📚 학습 포인트: Pagination Logic
    /// 다음 페이지 요청 여부 결정
    /// 💡 Java 비교: Page.hasNext()와 유사
    ///
    /// - Returns: 다음 페이지가 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// if response.hasMorePages {
    ///     loadNextPage()
    /// }
    /// ```
    var hasMorePages: Bool {
        return currentPage < totalPages
    }

    /// 이전 페이지가 있는지 확인
    ///
    /// - Returns: 이전 페이지가 있으면 true
    var hasPreviousPages: Bool {
        return currentPage > 1
    }

    /// 다음 페이지 번호 반환
    ///
    /// - Returns: 다음 페이지 번호 (없으면 nil)
    var nextPage: Int? {
        return hasMorePages ? currentPage + 1 : nil
    }

    /// 이전 페이지 번호 반환
    ///
    /// - Returns: 이전 페이지 번호 (없으면 nil)
    var previousPage: Int? {
        return hasPreviousPages ? currentPage - 1 : nil
    }

    /// 현재 페이지의 식품 수
    ///
    /// - Returns: 현재 페이지에 있는 식품 개수
    var foodCount: Int {
        return foods?.count ?? 0
    }

    /// 검색 결과 요약 문자열
    ///
    /// UI에 표시할 검색 결과 요약
    ///
    /// - Returns: 검색 결과 요약 (예: "156개 결과 중 1-10")
    ///
    /// - Example:
    /// ```swift
    /// print(response.resultSummary) // "156개 결과 중 1-10"
    /// ```
    var resultSummary: String {
        guard hasResults else {
            return "검색 결과 없음"
        }

        let pageSize = foodSearchCriteria?.pageSize ?? 10
        let startIndex = (currentPage - 1) * pageSize + 1
        let endIndex = min(currentPage * pageSize, totalHits)

        return "\(totalHits)개 결과 중 \(startIndex)-\(endIndex)"
    }
}

// MARK: - Validation

extension USDASearchResponseDTO {

    /// 응답 데이터가 유효한지 검증
    ///
    /// 📚 학습 포인트: Response Validation
    /// API 응답의 일관성 검증
    /// 💡 Java 비교: Response validation pattern
    ///
    /// - Returns: 유효하면 true
    ///
    /// **검증 항목:**
    /// - 페이지 번호가 전체 페이지 범위 내에 있는지
    /// - totalHits와 실제 foods 배열이 일치하는지 (마지막 페이지는 예외)
    var isValid: Bool {
        // 페이지 번호 유효성 검증
        guard currentPage >= 1 && currentPage <= totalPages else {
            return false
        }

        // totalHits가 음수가 아닌지 확인
        guard totalHits >= 0 else {
            return false
        }

        // foods 배열이 nil이 아닌지 확인 (결과가 있는 경우)
        if totalHits > 0 {
            guard foods != nil else {
                return false
            }
        }

        return true
    }
}

// MARK: - Error Handling

/// USDA API 에러 타입
///
/// 📚 학습 포인트: Domain-Specific Error Types
/// USDA API는 HTTP 상태 코드로 에러를 전달하지만,
/// 비즈니스 로직에서는 의미 있는 에러 타입으로 변환
/// 💡 Java 비교: Custom Exception 계층 구조와 유사
///
/// - Note: USDA API는 KFDA처럼 응답 본문에 에러 코드를 포함하지 않음
///         HTTP 상태 코드와 메시지로 에러 판단
enum USDAAPIError: Error {
    /// 잘못된 요청 (400 Bad Request)
    case badRequest(String)

    /// 인증 실패 (401/403)
    case authenticationFailed(String)

    /// 리소스를 찾을 수 없음 (404)
    case notFound

    /// 요청 제한 초과 (429 Too Many Requests)
    case rateLimitExceeded

    /// 서버 에러 (500)
    case serverError(String)

    /// 데이터 없음
    case noData

    /// 파싱 에러
    case parsingError(String)

    /// 기타 에러
    case unknown(Int, String)

    /// 사용자 친화적 에러 메시지
    ///
    /// 📚 학습 포인트: Localized Error Message
    /// 사용자에게 표시할 한글 에러 메시지
    /// 💡 Java 비교: getMessage()와 유사
    var localizedDescription: String {
        switch self {
        case .badRequest(let message):
            return "잘못된 요청입니다: \(message)"
        case .authenticationFailed(let message):
            return "인증에 실패했습니다: \(message)"
        case .notFound:
            return "요청한 식품을 찾을 수 없습니다."
        case .rateLimitExceeded:
            return "요청 횟수 제한을 초과했습니다. 잠시 후 다시 시도해주세요."
        case .serverError(let message):
            return "서버 오류가 발생했습니다: \(message)"
        case .noData:
            return "검색 결과가 없습니다."
        case .parsingError(let message):
            return "데이터 처리 중 오류가 발생했습니다: \(message)"
        case .unknown(let code, let message):
            return "알 수 없는 오류가 발생했습니다 (코드: \(code)): \(message)"
        }
    }
}

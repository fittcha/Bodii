//
//  KFDASearchResponseDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: API Response Wrapper
// 한국 정부 API의 표준 응답 구조 (Header + Body)
// 💡 Java 비교: Spring Boot의 ResponseEntity와 유사한 구조

import Foundation

/// 식약처 API 검색 응답 전체 구조
///
/// 📚 학습 포인트: Nested DTO Structure
/// 한국 공공데이터 API의 표준 응답 형식을 반영
/// 💡 Java 비교: Wrapper DTO pattern
///
/// **API 응답 구조:**
/// ```json
/// {
///   "header": {
///     "resultCode": "00",
///     "resultMsg": "NORMAL SERVICE."
///   },
///   "body": {
///     "items": [...],
///     "numOfRows": 10,
///     "pageNo": 1,
///     "totalCount": 156
///   }
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let response: KFDASearchResponseDTO = try await networkManager.request(
///     url: kfdaSearchURL,
///     method: .get
/// )
///
/// if response.isSuccess {
///     let foods = response.body?.items ?? []
///     // foods 처리...
/// } else {
///     print("Error: \(response.header.resultMsg)")
/// }
/// ```
///
/// **참고:**
/// - 공공데이터포털 표준 응답 형식
/// - API 문서: https://www.data.go.kr/data/15127578/openapi.do
struct KFDASearchResponseDTO: Codable {

    // MARK: - Properties

    /// 응답 헤더 정보
    ///
    /// API 호출 성공/실패 여부와 메시지 포함
    let header: Header

    /// 응답 바디 정보
    ///
    /// 실제 식품 데이터와 페이징 정보 포함
    /// 에러 발생 시 nil일 수 있음
    let body: Body?

    // MARK: - Nested Types

    /// 📚 학습 포인트: Nested Struct
    /// 관련된 데이터 구조를 내부에 정의하여 네임스페이스 정리
    /// 💡 Java 비교: Inner Class와 유사
    ///
    /// **API Header 구조:**
    /// - resultCode: 결과 코드 ("00" = 정상, 기타 = 에러)
    /// - resultMsg: 결과 메시지
    struct Header: Codable {

        /// 결과 코드
        ///
        /// - "00": 정상 처리
        /// - "01": 어플리케이션 에러
        /// - "02": 데이터베이스 에러
        /// - "03": 데이터 없음
        /// - "04": HTTP 에러
        /// - "05": 서비스 연결 실패
        /// - "10": 잘못된 요청 파라미터
        /// - "11": 필수 요청 파라미터 누락
        /// - "12": 해당 오픈 API 서비스가 없거나 폐기
        /// - "20": 서비스 접근 거부
        /// - "21": 일시적으로 사용할 수 없는 서비스 키
        /// - "22": 서비스 요청 제한 횟수 초과
        /// - "30": 등록되지 않은 서비스 키
        /// - "31": 기한 만료된 서비스 키
        /// - "32": 등록되지 않은 IP
        /// - "99": 기타 에러
        let resultCode: String

        /// 결과 메시지
        ///
        /// 한글 또는 영문 메시지 (예: "NORMAL SERVICE.", "데이터 없음")
        let resultMsg: String

        /// CodingKeys for API field mapping
        ///
        /// API는 대문자 필드명 사용
        enum CodingKeys: String, CodingKey {
            case resultCode = "resultCode"
            case resultMsg = "resultMsg"
        }
    }

    /// 📚 학습 포인트: Response Body Structure
    /// 실제 데이터와 페이징 정보를 포함하는 바디 구조
    /// 💡 Java 비교: Page<T> 형식의 페이징 응답과 유사
    ///
    /// **API Body 구조:**
    /// - items: 식품 데이터 배열
    /// - numOfRows: 한 페이지의 결과 수
    /// - pageNo: 현재 페이지 번호
    /// - totalCount: 전체 결과 수
    struct Body: Codable {

        /// 식품 데이터 배열
        ///
        /// 검색 결과로 반환된 식품 목록
        /// 데이터가 없으면 빈 배열
        let items: [KFDAFoodDTO]?

        /// 한 페이지 결과 수
        ///
        /// 요청 시 지정한 페이지 당 결과 수 (endIdx - startIdx + 1)
        let numOfRows: Int?

        /// 현재 페이지 번호
        ///
        /// 요청 시 지정한 페이지 번호
        let pageNo: Int?

        /// 전체 결과 수
        ///
        /// 검색 조건에 맞는 전체 식품 수
        /// 페이징 처리에 사용
        let totalCount: Int?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case items = "items"
            case numOfRows = "numOfRows"
            case pageNo = "pageNo"
            case totalCount = "totalCount"
        }

        /// 📚 학습 포인트: Custom Decoding for Array
        /// API가 단일 item과 배열 items를 다르게 반환할 수 있어 커스텀 디코딩 처리
        /// 💡 Java 비교: Custom Deserializer와 유사
        ///
        /// **식약처 API 특이사항:**
        /// - 결과가 1개: `"item": { ... }` (단일 객체)
        /// - 결과가 여러개: `"item": [ ... ]` (배열)
        /// - 결과가 없음: `"item": ""` (빈 문자열) 또는 필드 없음
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // numOfRows, pageNo, totalCount 파싱
            numOfRows = try? container.decode(Int.self, forKey: .numOfRows)
            pageNo = try? container.decode(Int.self, forKey: .pageNo)
            totalCount = try? container.decode(Int.self, forKey: .totalCount)

            // items 파싱 - 배열 또는 단일 객체 처리
            if let itemsArray = try? container.decode([KFDAFoodDTO].self, forKey: .items) {
                // 배열인 경우
                items = itemsArray
            } else if let singleItem = try? container.decode(KFDAFoodDTO.self, forKey: .items) {
                // 단일 객체인 경우 - 배열로 래핑
                items = [singleItem]
            } else {
                // 데이터 없음 - 빈 배열
                items = []
            }
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case header = "header"
        case body = "body"
    }
}

// MARK: - Convenience Methods

extension KFDASearchResponseDTO {

    /// API 호출이 성공했는지 확인
    ///
    /// 📚 학습 포인트: Computed Property
    /// 자주 사용하는 검증 로직을 프로퍼티로 제공
    /// 💡 Java 비교: getter 메서드와 동일하지만 더 간결
    ///
    /// - Returns: resultCode가 "00"이면 true
    ///
    /// - Example:
    /// ```swift
    /// if response.isSuccess {
    ///     // 정상 처리
    /// } else {
    ///     print("Error: \(response.errorMessage)")
    /// }
    /// ```
    var isSuccess: Bool {
        return header.resultCode == "00"
    }

    /// 에러 메시지 반환
    ///
    /// 에러 발생 시 사용자에게 표시할 메시지
    ///
    /// - Returns: 에러 메시지 (성공 시 nil)
    var errorMessage: String? {
        return isSuccess ? nil : header.resultMsg
    }

    /// 검색 결과 식품 목록 반환
    ///
    /// 📚 학습 포인트: Safe Unwrapping
    /// Optional chaining과 nil coalescing으로 안전하게 배열 반환
    /// 💡 Java 비교: Optional.orElse()와 유사
    ///
    /// - Returns: 식품 목록 (결과 없으면 빈 배열)
    ///
    /// - Example:
    /// ```swift
    /// let foods = response.foods
    /// print("Found \(foods.count) foods")
    /// ```
    var foods: [KFDAFoodDTO] {
        return body?.items ?? []
    }

    /// 전체 결과 수 반환
    ///
    /// 페이징 처리에 사용
    ///
    /// - Returns: 전체 결과 수 (정보 없으면 0)
    var totalCount: Int {
        return body?.totalCount ?? 0
    }

    /// 현재 페이지에 더 많은 결과가 있는지 확인
    ///
    /// 📚 학습 포인트: Pagination Logic
    /// 다음 페이지 요청 여부 결정
    /// 💡 Java 비교: Page.hasNext()와 유사
    ///
    /// - Parameter currentItemCount: 현재까지 로드한 아이템 수
    ///
    /// - Returns: 더 많은 결과가 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// var allFoods: [KFDAFoodDTO] = []
    /// var currentIndex = 1
    ///
    /// repeat {
    ///     let response = try await searchFoods(startIdx: currentIndex)
    ///     allFoods.append(contentsOf: response.foods)
    ///     currentIndex += response.foods.count
    /// } while response.hasMoreResults(currentItemCount: allFoods.count)
    /// ```
    func hasMoreResults(currentItemCount: Int) -> Bool {
        return currentItemCount < totalCount
    }
}

// MARK: - Error Handling

extension KFDASearchResponseDTO {

    /// 결과 코드에 따른 상세 에러 타입 반환
    ///
    /// 📚 학습 포인트: Error Mapping
    /// API 에러 코드를 앱 내부 에러 타입으로 변환
    /// 💡 Java 비교: Exception mapping과 유사
    ///
    /// - Returns: 에러 타입 (성공 시 nil)
    var errorType: KFDAAPIError? {
        guard !isSuccess else { return nil }

        switch header.resultCode {
        case "03":
            return .noData
        case "10", "11":
            return .invalidRequest(header.resultMsg)
        case "12":
            return .serviceNotAvailable
        case "20", "21", "30", "31", "32":
            return .authenticationFailed(header.resultMsg)
        case "22":
            return .rateLimitExceeded
        default:
            return .unknown(header.resultCode, header.resultMsg)
        }
    }
}

// MARK: - KFDA API Error Types

/// 식약처 API 에러 타입
///
/// 📚 학습 포인트: Domain-Specific Error Types
/// API 에러를 명확한 타입으로 정의하여 에러 처리 개선
/// 💡 Java 비교: Custom Exception 계층 구조와 유사
enum KFDAAPIError: Error {
    /// 데이터 없음
    case noData

    /// 잘못된 요청
    case invalidRequest(String)

    /// 서비스 사용 불가
    case serviceNotAvailable

    /// 인증 실패 (API 키 문제)
    case authenticationFailed(String)

    /// 요청 제한 초과
    case rateLimitExceeded

    /// 기타 에러
    case unknown(String, String)

    /// 사용자 친화적 에러 메시지
    ///
    /// 📚 학습 포인트: Localized Error Message
    /// 사용자에게 표시할 한글 에러 메시지
    /// 💡 Java 비교: getMessage()와 유사
    var localizedDescription: String {
        switch self {
        case .noData:
            return "검색 결과가 없습니다."
        case .invalidRequest(let message):
            return "잘못된 요청입니다: \(message)"
        case .serviceNotAvailable:
            return "서비스를 사용할 수 없습니다. 잠시 후 다시 시도해주세요."
        case .authenticationFailed(let message):
            return "인증에 실패했습니다: \(message)"
        case .rateLimitExceeded:
            return "요청 횟수 제한을 초과했습니다. 잠시 후 다시 시도해주세요."
        case .unknown(let code, let message):
            return "알 수 없는 오류가 발생했습니다 (코드: \(code)): \(message)"
        }
    }
}

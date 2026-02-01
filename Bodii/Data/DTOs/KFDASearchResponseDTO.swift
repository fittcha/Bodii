//
//  KFDASearchResponseDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// 식약처 API 검색 응답 전체 구조 (FoodNtrCpntDbInfo02 API)
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
struct KFDASearchResponseDTO: Codable {

    let header: Header
    let body: Body?

    struct Header: Codable {
        /// 결과 코드 ("00" = 정상, "03" = 데이터없음 등)
        let resultCode: String
        /// 결과 메시지
        let resultMsg: String
    }

    struct Body: Codable {
        let items: [KFDAFoodDTO]?
        let numOfRows: Int?
        let pageNo: Int?
        let totalCount: Int?

        /// 커스텀 디코딩: items가 배열/단일 객체/없음 모두 처리
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            numOfRows = try? container.decode(Int.self, forKey: .numOfRows)
            pageNo = try? container.decode(Int.self, forKey: .pageNo)
            totalCount = try? container.decode(Int.self, forKey: .totalCount)

            if let itemsArray = try? container.decode([KFDAFoodDTO].self, forKey: .items) {
                items = itemsArray
            } else if let singleItem = try? container.decode(KFDAFoodDTO.self, forKey: .items) {
                items = [singleItem]
            } else {
                items = []
            }
        }

        enum CodingKeys: String, CodingKey {
            case items
            case numOfRows
            case pageNo
            case totalCount
        }
    }
}

// MARK: - Convenience Methods

extension KFDASearchResponseDTO {

    var isSuccess: Bool {
        return header.resultCode == "00"
    }

    var errorMessage: String? {
        return isSuccess ? nil : header.resultMsg
    }

    var foods: [KFDAFoodDTO] {
        return body?.items ?? []
    }

    var totalCount: Int {
        return body?.totalCount ?? 0
    }

    func hasMoreResults(currentItemCount: Int) -> Bool {
        return currentItemCount < totalCount
    }
}

// MARK: - Error Handling

extension KFDASearchResponseDTO {

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

enum KFDAAPIError: Error {
    case noData
    case invalidRequest(String)
    case serviceNotAvailable
    case authenticationFailed(String)
    case rateLimitExceeded
    case unknown(String, String)

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

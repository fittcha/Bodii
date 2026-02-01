//
//  KFDAFoodAPIService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// 식약처(KFDA) 식품 영양 정보 API 서비스 (FoodNtrCpntDbInfo02)
///
/// **API 정보:**
/// - Provider: 식품의약품안전처 (공공데이터포털)
/// - Endpoint: FoodNtrCpntDbInfo02/getFoodNtrCpntDbInq02
/// - Pagination: pageNo / numOfRows
final class KFDAFoodAPIService {

    private let networkManager: NetworkManager
    private let apiConfig: APIConfigProtocol

    init(
        networkManager: NetworkManager = NetworkManager(
            timeout: Constants.API.KFDA.timeout,
            maxRetries: Constants.API.KFDA.maxRetries
        ),
        apiConfig: APIConfigProtocol = APIConfig.shared
    ) {
        self.networkManager = networkManager
        self.apiConfig = apiConfig
    }

    // MARK: - Public Methods

    /// 식품명으로 검색
    ///
    /// - Parameters:
    ///   - query: 검색어 (식품명)
    ///   - pageNo: 페이지 번호 (1부터 시작, 기본값: 1)
    ///   - numOfRows: 한 페이지 결과 수 (기본값: defaultPageSize)
    ///
    /// - Returns: API 응답 (식품 목록과 페이징 정보 포함)
    func searchFoods(
        query: String,
        pageNo: Int = 1,
        numOfRows: Int? = nil
    ) async throws -> KFDASearchResponseDTO {

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw KFDAAPIError.invalidRequest("검색어가 비어있습니다.")
        }

        guard pageNo > 0 else {
            throw KFDAAPIError.invalidRequest("페이지 번호는 1 이상이어야 합니다.")
        }

        let rows = numOfRows ?? Constants.API.KFDA.defaultPageSize

        guard rows <= Constants.API.KFDA.maxPageSize else {
            throw KFDAAPIError.invalidRequest(
                "페이지 크기가 너무 큽니다. 최대 \(Constants.API.KFDA.maxPageSize)개까지 요청 가능합니다."
            )
        }

        let endpoint = APIConfig.KFDAEndpoint.search(
            query: query,
            pageNo: pageNo,
            numOfRows: rows
        )

        guard let url = apiConfig.buildKFDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("KFDA API URL 생성 실패")
        }

        do {
            let response: KFDASearchResponseDTO = try await networkManager.request(
                url: url.absoluteString,
                method: .get,
                timeout: Constants.API.KFDA.timeout
            )

            guard response.isSuccess else {
                if let error = response.errorType {
                    throw error
                } else {
                    throw KFDAAPIError.unknown(
                        response.header.resultCode,
                        response.header.resultMsg
                    )
                }
            }

            return response

        } catch let error as KFDAAPIError {
            throw error
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    /// 식품 코드로 상세 정보 조회
    func getFoodDetail(foodCode: String) async throws -> KFDAFoodDTO {

        guard !foodCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw KFDAAPIError.invalidRequest("식품 코드가 비어있습니다.")
        }

        let endpoint = APIConfig.KFDAEndpoint.detail(foodCode: foodCode)

        guard let url = apiConfig.buildKFDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("KFDA API URL 생성 실패")
        }

        do {
            let response: KFDASearchResponseDTO = try await networkManager.request(
                url: url.absoluteString,
                method: .get,
                timeout: Constants.API.KFDA.timeout
            )

            guard response.isSuccess else {
                if let error = response.errorType {
                    throw error
                } else {
                    throw KFDAAPIError.unknown(
                        response.header.resultCode,
                        response.header.resultMsg
                    )
                }
            }

            guard let food = response.foods.first else {
                throw KFDAAPIError.noData
            }

            guard food.isValid else {
                throw KFDAAPIError.invalidRequest("유효하지 않은 식품 데이터입니다.")
            }

            return food

        } catch let error as KFDAAPIError {
            throw error
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}

// MARK: - Validation Helper

extension KFDAFoodAPIService {

    /// 검색 결과 유효성 검증 (유효하지 않은 데이터 필터링)
    func validateFoods(_ foods: [KFDAFoodDTO]) -> [KFDAFoodDTO] {
        return foods.filter { food in
            let isValid = food.isValid
            if !isValid {
                #if DEBUG
                print("⚠️ Invalid KFDA food data: \(food.foodCd) - \(food.descKor)")
                #endif
            }
            return isValid
        }
    }
}

// MARK: - Testing Support

#if DEBUG
final class MockKFDAFoodAPIService {
    var mockSearchResponse: KFDASearchResponseDTO?
    var mockFoodDetail: KFDAFoodDTO?
    var shouldThrowError: Error?

    func searchFoods(
        query: String,
        pageNo: Int = 1,
        numOfRows: Int? = nil
    ) async throws -> KFDASearchResponseDTO {
        if let error = shouldThrowError { throw error }
        guard let response = mockSearchResponse else { throw KFDAAPIError.noData }
        return response
    }

    func getFoodDetail(foodCode: String) async throws -> KFDAFoodDTO {
        if let error = shouldThrowError { throw error }
        guard let detail = mockFoodDetail else { throw KFDAAPIError.noData }
        return detail
    }
}
#endif

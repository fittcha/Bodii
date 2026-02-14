//
//  OpenFoodFactsAPIService.swift
//  Bodii
//
//  Open Food Facts API 서비스 (무료, 키 불필요)

import Foundation

/// Open Food Facts API 서비스
///
/// 무료 오픈소스 식품 데이터베이스 API.
/// 바코드 기반 제품 조회 및 키워드 검색을 지원합니다.
/// 한국 제품 ~2,700개 + 글로벌 400만+ 제품.
final class OpenFoodFactsAPIService {

    // MARK: - Constants

    private let searchBaseURL = "https://kr.openfoodfacts.org/cgi/search.pl"
    private let productBaseURL = "https://world.openfoodfacts.org/api/v0/product"
    private let userAgent = "Bodii iOS App - https://github.com/fittcha/bodii"
    private let timeout: TimeInterval = Constants.API.OpenFoodFacts.timeout

    // MARK: - Private

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.API.OpenFoodFacts.timeout
        config.httpAdditionalHeaders = [
            "User-Agent": "Bodii iOS App - https://github.com/fittcha/bodii"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search

    /// 키워드로 제품을 검색합니다.
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - pageSize: 한 페이지 결과 수 (기본 50)
    ///   - page: 페이지 번호 (기본 1)
    /// - Returns: 검색 결과 DTO
    func searchProducts(
        query: String,
        pageSize: Int = 50,
        page: Int = 1
    ) async throws -> OFFSearchResponseDTO {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FoodSearchError.invalidQuery("검색어 인코딩 실패")
        }

        let urlString = "\(searchBaseURL)?search_terms=\(encodedQuery)&json=true&page_size=\(pageSize)&page=\(page)&search_simple=1&action=process"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: "OFF API error")
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(OFFSearchResponseDTO.self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ OFF decode error: \(error)")
            if let json = String(data: data.prefix(500), encoding: .utf8) {
                print("  Response preview: \(json)")
            }
            #endif
            throw NetworkError.decodingFailed(error)
        }
    }

    /// 바코드로 제품을 조회합니다.
    ///
    /// - Parameter barcode: 제품 바코드 (EAN-13, UPC-A 등)
    /// - Returns: 제품 DTO (없으면 nil)
    func getProduct(barcode: String) async throws -> OFFProductDTO? {
        let urlString = "\(productBaseURL)/\(barcode).json"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: "OFF API error")
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(OFFProductResponseDTO.self, from: data)

        guard result.status == 1 else {
            return nil // 제품 없음
        }

        return result.product
    }
}

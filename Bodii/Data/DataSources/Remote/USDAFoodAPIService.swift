//
//  USDAFoodAPIService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: API Service Layer
// 외부 API 호출을 캡슐화하는 서비스 클래스
// 💡 Java 비교: Retrofit의 Service Interface 구현체와 유사한 역할

import Foundation

/// USDA FoodData Central API 서비스
///
/// 📚 학습 포인트: Service Layer Pattern
/// 네트워크 요청 로직을 분리하여 재사용성과 테스트 용이성 향상
/// 💡 Java 비교: Repository 패턴의 Remote DataSource와 유사
///
/// **주요 기능:**
/// - 식품명으로 검색
/// - 페이징 지원 (page number 기반)
/// - 식품 상세 정보 조회 (FDC ID)
/// - API 응답 파싱 및 에러 처리
/// - Rate limit 준수
///
/// **API 정보:**
/// - Provider: USDA (미국 농무부)
/// - API 문서: https://fdc.nal.usda.gov/api-guide.html
/// - Rate Limit: DEMO_KEY - 30 requests/hour, 50 requests/day
/// - API 키 신청: https://fdc.nal.usda.gov/api-key-signup.html
///
/// **사용 예시:**
/// ```swift
/// let service = USDAFoodAPIService()
///
/// // 식품 검색
/// let result = try await service.searchFoods(query: "apple", pageSize: 10, pageNumber: 1)
/// print("Found \(result.totalHits) foods")
/// result.foods?.forEach { food in
///     let calories = food.getNutrientValue(USDANutrientID.energy)
///     print("\(food.description): \(calories ?? 0) kcal")
/// }
///
/// // 식품 상세 조회
/// let detail = try await service.getFoodDetail(fdcId: "123456")
/// ```
final class USDAFoodAPIService {

    // MARK: - Properties

    /// 네트워크 매니저
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// NetworkManager를 주입받아 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: Constructor Injection 패턴
    private let networkManager: NetworkManager

    /// API 설정
    ///
    /// API URL과 인증 키를 제공하는 설정 객체
    private let apiConfig: APIConfigProtocol

    // MARK: - Initialization

    /// USDAFoodAPIService 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 의존성을 주입받아 테스트와 유연성 향상
    /// 💡 Java 비교: @Inject 어노테이션과 유사한 패턴
    ///
    /// - Parameters:
    ///   - networkManager: 네트워크 요청을 처리할 매니저 (기본값: shared URLSession 사용)
    ///   - apiConfig: API 설정 (기본값: APIConfig.shared)
    init(
        networkManager: NetworkManager = NetworkManager(
            timeout: Constants.API.USDA.timeout,
            maxRetries: Constants.API.USDA.maxRetries
        ),
        apiConfig: APIConfigProtocol = APIConfig.shared
    ) {
        self.networkManager = networkManager
        self.apiConfig = apiConfig
    }

    // MARK: - Public Methods

    /// 식품명으로 검색
    ///
    /// 📚 학습 포인트: Async/Await Network Call
    /// 비동기 네트워크 요청을 동기 코드처럼 작성
    /// 💡 Java 비교: CompletableFuture와 유사하지만 더 간결
    ///
    /// 📚 학습 포인트: USDA Pagination
    /// USDA API는 페이지 번호(pageNumber)를 사용 (KFDA의 인덱스 범위와 다름)
    /// 💡 예: pageNumber=1, pageSize=10 → 1-10번 결과 (10개)
    ///       pageNumber=2, pageSize=10 → 11-20번 결과 (10개)
    ///
    /// - Parameters:
    ///   - query: 검색어 (식품명, 예: "apple", "milk")
    ///   - pageSize: 페이지 크기 (기본값: defaultPageSize - 25)
    ///   - pageNumber: 페이지 번호 (1부터 시작, 기본값: 1)
    ///   - dataType: 식품 타입 필터 (선택적, 예: ["Branded", "Foundation"])
    ///
    /// - Returns: API 응답 (식품 목록과 페이징 정보 포함)
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - USDAAPIError: API 에러 (인증 실패, rate limit 등)
    ///
    /// - Example:
    /// ```swift
    /// // 첫 페이지 검색
    /// let page1 = try await service.searchFoods(query: "apple")
    ///
    /// // 다음 페이지 검색
    /// let page2 = try await service.searchFoods(
    ///     query: "apple",
    ///     pageSize: 10,
    ///     pageNumber: 2
    /// )
    ///
    /// // Foundation 식품만 검색
    /// let foundations = try await service.searchFoods(
    ///     query: "apple",
    ///     dataType: ["Foundation"]
    /// )
    /// ```
    func searchFoods(
        query: String,
        pageSize: Int = Constants.API.USDA.defaultPageSize,
        pageNumber: Int = 1,
        dataType: [String]? = nil
    ) async throws -> USDASearchResponseDTO {

        // 입력 검증
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw USDAAPIError.badRequest("검색어가 비어있습니다.")
        }

        guard pageNumber > 0 else {
            throw USDAAPIError.badRequest("페이지 번호는 1 이상이어야 합니다.")
        }

        guard pageSize > 0 && pageSize <= Constants.API.USDA.maxPageSize else {
            throw USDAAPIError.badRequest(
                "페이지 크기는 1-\(Constants.API.USDA.maxPageSize) 범위여야 합니다."
            )
        }

        // URL 생성
        let endpoint = APIConfig.USDAEndpoint.search(
            query: query,
            pageSize: pageSize,
            pageNumber: pageNumber
        )

        guard let url = apiConfig.buildUSDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("USDA API URL 생성 실패")
        }

        // dataType 필터가 있으면 URL에 추가
        var finalURL = url
        if let dataTypes = dataType, !dataTypes.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var queryItems = components?.queryItems ?? []
            dataTypes.forEach { type in
                queryItems.append(URLQueryItem(name: "dataType", value: type))
            }
            components?.queryItems = queryItems
            finalURL = components?.url ?? url
        }

        // API 요청
        do {
            let response: USDASearchResponseDTO = try await networkManager.request(
                url: finalURL.absoluteString,
                method: .get,
                timeout: Constants.API.USDA.timeout
            )

            // API 응답 검증
            guard response.isValid else {
                throw USDAAPIError.parsingError("응답 데이터가 유효하지 않습니다.")
            }

            return response

        } catch let error as USDAAPIError {
            // USDA API 에러는 그대로 전달
            throw error

        } catch let error as NetworkError {
            // 네트워크 에러를 USDA 에러로 변환
            throw mapNetworkErrorToUSDAError(error)

        } catch {
            // 기타 에러
            throw NetworkError.unknown(error)
        }
    }

    /// FDC ID로 식품 상세 정보 조회
    ///
    /// 📚 학습 포인트: Single Item API Call
    /// 특정 식품의 상세 정보를 조회하는 메서드
    /// 💡 Java 비교: findById()와 유사한 패턴
    ///
    /// - Parameter fdcId: FDC ID (USDA 식품 고유 ID, 예: "123456")
    ///
    /// - Returns: 식품 상세 정보
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - USDAAPIError: API 에러 또는 식품을 찾을 수 없음
    ///
    /// - Example:
    /// ```swift
    /// let food = try await service.getFoodDetail(fdcId: "123456")
    /// let calories = food.getNutrientValue(USDANutrientID.energy)
    /// print("\(food.description): \(calories ?? 0) kcal")
    /// ```
    func getFoodDetail(fdcId: String) async throws -> USDAFoodDTO {

        // 입력 검증
        guard !fdcId.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw USDAAPIError.badRequest("FDC ID가 비어있습니다.")
        }

        // URL 생성
        let endpoint = APIConfig.USDAEndpoint.food(fdcId: fdcId)

        guard let url = apiConfig.buildUSDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("USDA API URL 생성 실패")
        }

        // API 요청
        do {
            let food: USDAFoodDTO = try await networkManager.request(
                url: url.absoluteString,
                method: .get,
                timeout: Constants.API.USDA.timeout
            )

            // 데이터 유효성 검증
            guard food.isValid else {
                throw USDAAPIError.parsingError("유효하지 않은 식품 데이터입니다.")
            }

            return food

        } catch let error as USDAAPIError {
            // USDA API 에러는 그대로 전달
            throw error

        } catch let error as NetworkError {
            // 네트워크 에러를 USDA 에러로 변환
            throw mapNetworkErrorToUSDAError(error)

        } catch {
            // 기타 에러
            throw NetworkError.unknown(error)
        }
    }

    /// 여러 FDC ID로 식품 정보 일괄 조회
    ///
    /// 📚 학습 포인트: Batch API Call
    /// 여러 식품을 한 번에 조회하여 네트워크 요청 최소화
    /// 💡 Java 비교: findAllById()와 유사한 패턴
    ///
    /// - Parameter fdcIds: FDC ID 배열
    ///
    /// - Returns: 식품 정보 배열
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - USDAAPIError: API 에러
    ///
    /// - Note: 최대 20개까지 한 번에 조회 가능 (USDA API 제한)
    ///
    /// - Example:
    /// ```swift
    /// let foods = try await service.getFoods(fdcIds: ["123456", "789012"])
    /// foods.forEach { food in
    ///     print(food.description)
    /// }
    /// ```
    func getFoods(fdcIds: [String]) async throws -> [USDAFoodDTO] {

        // 입력 검증
        guard !fdcIds.isEmpty else {
            throw USDAAPIError.badRequest("FDC ID 목록이 비어있습니다.")
        }

        guard fdcIds.count <= 20 else {
            throw USDAAPIError.badRequest("최대 20개까지 한 번에 조회 가능합니다.")
        }

        // URL 생성
        let endpoint = APIConfig.USDAEndpoint.foods(fdcIds: fdcIds)

        guard let url = apiConfig.buildUSDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("USDA API URL 생성 실패")
        }

        // API 요청
        do {
            let foods: [USDAFoodDTO] = try await networkManager.request(
                url: url.absoluteString,
                method: .get,
                timeout: Constants.API.USDA.timeout
            )

            // 유효한 식품만 필터링
            let validFoods = validateFoods(foods)

            return validFoods

        } catch let error as USDAAPIError {
            // USDA API 에러는 그대로 전달
            throw error

        } catch let error as NetworkError {
            // 네트워크 에러를 USDA 에러로 변환
            throw mapNetworkErrorToUSDAError(error)

        } catch {
            // 기타 에러
            throw NetworkError.unknown(error)
        }
    }

    // MARK: - Private Methods

    /// NetworkError를 USDAAPIError로 매핑
    ///
    /// 📚 학습 포인트: Error Mapping
    /// 네트워크 에러를 도메인별 에러로 변환하여 상위 레이어에서 처리 용이
    /// 💡 Java 비교: Exception mapping pattern
    ///
    /// - Parameter error: NetworkError
    ///
    /// - Returns: USDAAPIError
    private func mapNetworkErrorToUSDAError(_ error: NetworkError) -> USDAAPIError {
        switch error {
        case .httpError(let statusCode, let message):
            switch statusCode {
            case 400:
                return .badRequest(message)
            case 401, 403:
                return .authenticationFailed(message)
            case 404:
                return .notFound
            case 429:
                return .rateLimitExceeded
            case 500...599:
                return .serverError(message)
            default:
                return .unknown(statusCode, message)
            }

        case .networkUnavailable:
            return .serverError("네트워크 연결을 확인해주세요.")

        case .timeout:
            return .serverError("요청 시간이 초과되었습니다.")

        case .decodingFailed(let underlyingError):
            return .parsingError("데이터 파싱 실패: \(underlyingError.localizedDescription)")

        case .noData:
            return .noData

        case .invalidURL(let url):
            return .badRequest("잘못된 URL: \(url)")

        case .invalidResponse:
            return .parsingError("잘못된 응답 형식입니다.")

        case .unknown(let underlyingError):
            return .unknown(0, underlyingError.localizedDescription)
        }
    }
}

// MARK: - Pagination Helper

extension USDAFoodAPIService {

    /// 다음 페이지 번호 계산
    ///
    /// 📚 학습 포인트: Pagination Helper
    /// 페이징 로직을 캡슐화하여 호출 코드 단순화
    /// 💡 Java 비교: PageRequest.next()와 유사한 패턴
    ///
    /// - Parameter response: 현재 검색 응답
    ///
    /// - Returns: 다음 페이지 번호 (없으면 nil)
    ///
    /// - Example:
    /// ```swift
    /// var currentPage = 1
    /// var allFoods: [USDAFoodDTO] = []
    ///
    /// while true {
    ///     let result = try await service.searchFoods(
    ///         query: "apple",
    ///         pageNumber: currentPage
    ///     )
    ///
    ///     allFoods.append(contentsOf: result.foods ?? [])
    ///
    ///     guard let nextPage = service.nextPageNumber(from: result) else {
    ///         break
    ///     }
    ///     currentPage = nextPage
    /// }
    /// ```
    func nextPageNumber(from response: USDASearchResponseDTO) -> Int? {
        return response.nextPage
    }

    /// 이전 페이지 번호 계산
    ///
    /// - Parameter response: 현재 검색 응답
    ///
    /// - Returns: 이전 페이지 번호 (없으면 nil)
    func previousPageNumber(from response: USDASearchResponseDTO) -> Int? {
        return response.previousPage
    }

    /// 전체 페이지 수 계산
    ///
    /// - Parameter response: 검색 응답
    ///
    /// - Returns: 전체 페이지 수
    func totalPages(from response: USDASearchResponseDTO) -> Int {
        return response.totalPages
    }

    /// 현재 페이지가 마지막 페이지인지 확인
    ///
    /// - Parameter response: 검색 응답
    ///
    /// - Returns: 마지막 페이지면 true
    func isLastPage(response: USDASearchResponseDTO) -> Bool {
        return !response.hasMorePages
    }
}

// MARK: - Validation Helper

extension USDAFoodAPIService {

    /// 검색 결과 유효성 검증
    ///
    /// 📚 학습 포인트: Data Validation
    /// API 응답 데이터의 유효성을 검증하여 잘못된 데이터 필터링
    /// 💡 Java 비교: Bean Validation과 유사
    ///
    /// - Parameter foods: 검증할 식품 목록
    ///
    /// - Returns: 유효한 식품 목록 (필수 필드가 있는 항목만)
    ///
    /// - Note: 유효하지 않은 데이터는 제거되고 로그가 출력됨
    ///
    /// - Example:
    /// ```swift
    /// let response = try await service.searchFoods(query: "apple")
    /// let validFoods = service.validateFoods(response.foods ?? [])
    /// print("Valid foods: \(validFoods.count) / \(response.foods?.count ?? 0)")
    /// ```
    func validateFoods(_ foods: [USDAFoodDTO]) -> [USDAFoodDTO] {
        return foods.filter { food in
            let isValid = food.isValid

            if !isValid {
                // 유효하지 않은 데이터 로깅 (디버그 모드에서만)
                #if DEBUG
                print("⚠️ Invalid USDA food data: \(food.fdcId) - \(food.description)")
                #endif
            }

            return isValid
        }
    }

    /// 검색 응답이 비어있는지 확인
    ///
    /// - Parameter response: 검색 응답
    ///
    /// - Returns: 결과가 없으면 true
    func isEmpty(response: USDASearchResponseDTO) -> Bool {
        return !response.hasResults
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock USDA API 서비스
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockUSDAFoodAPIService {

    /// Mock 검색 응답 데이터
    var mockSearchResponse: USDASearchResponseDTO?

    /// Mock 상세 정보
    var mockFoodDetail: USDAFoodDTO?

    /// Mock 일괄 조회 응답
    var mockFoods: [USDAFoodDTO]?

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 검색 메서드 Mock
    func searchFoods(
        query: String,
        pageSize: Int = Constants.API.USDA.defaultPageSize,
        pageNumber: Int = 1,
        dataType: [String]? = nil
    ) async throws -> USDASearchResponseDTO {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 응답 반환
        guard let response = mockSearchResponse else {
            throw USDAAPIError.noData
        }

        return response
    }

    /// 상세 조회 메서드 Mock
    func getFoodDetail(fdcId: String) async throws -> USDAFoodDTO {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 데이터 반환
        guard let detail = mockFoodDetail else {
            throw USDAAPIError.notFound
        }

        return detail
    }

    /// 일괄 조회 메서드 Mock
    func getFoods(fdcIds: [String]) async throws -> [USDAFoodDTO] {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 데이터 반환
        guard let foods = mockFoods else {
            throw USDAAPIError.noData
        }

        return foods
    }
}
#endif

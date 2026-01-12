//
//  KFDAFoodAPIService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: API Service Layer
// 외부 API 호출을 캡슐화하는 서비스 클래스
// 💡 Java 비교: Retrofit의 Service Interface 구현체와 유사한 역할

import Foundation

/// 식약처(KFDA) 식품 영양 정보 API 서비스
///
/// 📚 학습 포인트: Service Layer Pattern
/// 네트워크 요청 로직을 분리하여 재사용성과 테스트 용이성 향상
/// 💡 Java 비교: Repository 패턴의 Remote DataSource와 유사
///
/// **주요 기능:**
/// - 식품명으로 검색
/// - 페이징 지원 (startIdx/endIdx)
/// - 식품 상세 정보 조회
/// - API 응답 파싱 및 에러 처리
/// - Rate limit 준수
///
/// **API 정보:**
/// - Provider: 식품의약품안전처 (공공데이터포털)
/// - API 문서: https://www.data.go.kr/data/15127578/openapi.do
/// - Rate Limit: API 키에 따라 상이 (일반적으로 1000 requests/day)
///
/// **사용 예시:**
/// ```swift
/// let service = KFDAFoodAPIService()
///
/// // 식품 검색
/// let result = try await service.searchFoods(query: "김치찌개", startIdx: 1, endIdx: 10)
/// print("Found \(result.totalCount) foods")
/// result.foods.forEach { food in
///     print("\(food.descKor): \(food.enercKcal ?? "N/A") kcal")
/// }
///
/// // 식품 상세 조회
/// let detail = try await service.getFoodDetail(foodCode: "D000001")
/// ```
final class KFDAFoodAPIService {

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

    /// KFDAFoodAPIService 초기화
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
    /// 📚 학습 포인트: Async/Await Network Call
    /// 비동기 네트워크 요청을 동기 코드처럼 작성
    /// 💡 Java 비교: CompletableFuture와 유사하지만 더 간결
    ///
    /// 📚 학습 포인트: KFDA Pagination
    /// KFDA API는 페이지 번호가 아닌 인덱스 범위(startIdx, endIdx)를 사용
    /// 💡 예: startIdx=1, endIdx=10 → 1-10번 결과 (10개)
    ///       startIdx=11, endIdx=20 → 11-20번 결과 (10개)
    ///
    /// - Parameters:
    ///   - query: 검색어 (식품명, 예: "김치찌개", "현미밥")
    ///   - startIdx: 시작 인덱스 (1부터 시작, 기본값: 1)
    ///   - endIdx: 종료 인덱스 (기본값: startIdx + defaultPageSize - 1)
    ///
    /// - Returns: API 응답 (식품 목록과 페이징 정보 포함)
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - KFDAAPIError: API 에러 (인증 실패, rate limit 등)
    ///
    /// - Example:
    /// ```swift
    /// // 첫 페이지 검색 (1-10)
    /// let page1 = try await service.searchFoods(query: "김치")
    ///
    /// // 다음 페이지 검색 (11-20)
    /// let page2 = try await service.searchFoods(
    ///     query: "김치",
    ///     startIdx: 11,
    ///     endIdx: 20
    /// )
    /// ```
    func searchFoods(
        query: String,
        startIdx: Int = 1,
        endIdx: Int? = nil
    ) async throws -> KFDASearchResponseDTO {

        // 입력 검증
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw KFDAAPIError.invalidRequest("검색어가 비어있습니다.")
        }

        guard startIdx > 0 else {
            throw KFDAAPIError.invalidRequest("시작 인덱스는 1 이상이어야 합니다.")
        }

        // endIdx 기본값 계산
        let calculatedEndIdx = endIdx ?? (startIdx + Constants.API.KFDA.defaultPageSize - 1)

        // 페이지 크기 검증
        let pageSize = calculatedEndIdx - startIdx + 1
        guard pageSize <= Constants.API.KFDA.maxPageSize else {
            throw KFDAAPIError.invalidRequest(
                "페이지 크기가 너무 큽니다. 최대 \(Constants.API.KFDA.maxPageSize)개까지 요청 가능합니다."
            )
        }

        // URL 생성
        let endpoint = APIConfig.KFDAEndpoint.search(
            query: query,
            startIdx: startIdx,
            endIdx: calculatedEndIdx
        )

        guard let url = apiConfig.buildKFDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("KFDA API URL 생성 실패")
        }

        // API 요청
        do {
            let response: KFDASearchResponseDTO = try await networkManager.request(
                url: url.absoluteString,
                method: .get,
                timeout: Constants.API.KFDA.timeout
            )

            // API 응답 검증
            guard response.isSuccess else {
                // API 에러 발생
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
            // KFDA API 에러는 그대로 전달
            throw error

        } catch let error as NetworkError {
            // 네트워크 에러 처리
            throw error

        } catch {
            // 기타 에러
            throw NetworkError.unknown(error)
        }
    }

    /// 식품 코드로 상세 정보 조회
    ///
    /// 📚 학습 포인트: Single Item API Call
    /// 특정 식품의 상세 정보를 조회하는 메서드
    /// 💡 Java 비교: findById()와 유사한 패턴
    ///
    /// - Parameter foodCode: 식품 코드 (예: "D000001")
    ///
    /// - Returns: 식품 상세 정보
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - KFDAAPIError: API 에러 또는 식품을 찾을 수 없음
    ///
    /// - Example:
    /// ```swift
    /// let food = try await service.getFoodDetail(foodCode: "D000001")
    /// print("\(food.descKor): \(food.enercKcal ?? "N/A") kcal")
    /// ```
    func getFoodDetail(foodCode: String) async throws -> KFDAFoodDTO {

        // 입력 검증
        guard !foodCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw KFDAAPIError.invalidRequest("식품 코드가 비어있습니다.")
        }

        // URL 생성
        let endpoint = APIConfig.KFDAEndpoint.detail(foodCode: foodCode)

        guard let url = apiConfig.buildKFDAURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("KFDA API URL 생성 실패")
        }

        // API 요청
        do {
            let response: KFDASearchResponseDTO = try await networkManager.request(
                url: url.absoluteString,
                method: .get,
                timeout: Constants.API.KFDA.timeout
            )

            // API 응답 검증
            guard response.isSuccess else {
                // API 에러 발생
                if let error = response.errorType {
                    throw error
                } else {
                    throw KFDAAPIError.unknown(
                        response.header.resultCode,
                        response.header.resultMsg
                    )
                }
            }

            // 식품 데이터 추출
            guard let food = response.foods.first else {
                throw KFDAAPIError.noData
            }

            // 데이터 유효성 검증
            guard food.isValid else {
                throw KFDAAPIError.invalidRequest("유효하지 않은 식품 데이터입니다.")
            }

            return food

        } catch let error as KFDAAPIError {
            // KFDA API 에러는 그대로 전달
            throw error

        } catch let error as NetworkError {
            // 네트워크 에러 처리
            throw error

        } catch {
            // 기타 에러
            throw NetworkError.unknown(error)
        }
    }
}

// MARK: - Pagination Helper

extension KFDAFoodAPIService {

    /// 다음 페이지 인덱스 범위 계산
    ///
    /// 📚 학습 포인트: Pagination Helper
    /// 페이징 로직을 캡슐화하여 호출 코드 단순화
    /// 💡 Java 비교: PageRequest.next()와 유사한 패턴
    ///
    /// - Parameters:
    ///   - currentStartIdx: 현재 페이지 시작 인덱스
    ///   - currentEndIdx: 현재 페이지 종료 인덱스
    ///
    /// - Returns: 다음 페이지의 (startIdx, endIdx) 튜플
    ///
    /// - Example:
    /// ```swift
    /// var (start, end) = (1, 10)
    ///
    /// while hasMoreResults {
    ///     let result = try await service.searchFoods(
    ///         query: "김치",
    ///         startIdx: start,
    ///         endIdx: end
    ///     )
    ///
    ///     // 결과 처리...
    ///
    ///     // 다음 페이지로
    ///     (start, end) = service.nextPageIndices(
    ///         currentStartIdx: start,
    ///         currentEndIdx: end
    ///     )
    ///     hasMoreResults = result.hasMoreResults(currentItemCount: allItems.count)
    /// }
    /// ```
    func nextPageIndices(
        currentStartIdx: Int,
        currentEndIdx: Int
    ) -> (startIdx: Int, endIdx: Int) {
        let pageSize = currentEndIdx - currentStartIdx + 1
        let nextStart = currentEndIdx + 1
        let nextEnd = nextStart + pageSize - 1

        return (nextStart, nextEnd)
    }

    /// 페이지 번호를 인덱스 범위로 변환
    ///
    /// 📚 학습 포인트: Page Number to Index Conversion
    /// 일반적인 페이지 번호(1, 2, 3...)를 KFDA API의 인덱스 범위로 변환
    /// 💡 Java 비교: PageRequest.of(page, size)와 유사한 패턴
    ///
    /// - Parameters:
    ///   - pageNumber: 페이지 번호 (1부터 시작)
    ///   - pageSize: 페이지 크기 (기본값: defaultPageSize)
    ///
    /// - Returns: (startIdx, endIdx) 튜플
    ///
    /// - Example:
    /// ```swift
    /// // 1페이지: startIdx=1, endIdx=10
    /// let (start1, end1) = service.pageToIndices(pageNumber: 1, pageSize: 10)
    ///
    /// // 2페이지: startIdx=11, endIdx=20
    /// let (start2, end2) = service.pageToIndices(pageNumber: 2, pageSize: 10)
    /// ```
    func pageToIndices(
        pageNumber: Int,
        pageSize: Int = Constants.API.KFDA.defaultPageSize
    ) -> (startIdx: Int, endIdx: Int) {
        let startIdx = (pageNumber - 1) * pageSize + 1
        let endIdx = startIdx + pageSize - 1

        return (startIdx, endIdx)
    }
}

// MARK: - Validation Helper

extension KFDAFoodAPIService {

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
    /// let response = try await service.searchFoods(query: "김치")
    /// let validFoods = service.validateFoods(response.foods)
    /// print("Valid foods: \(validFoods.count) / \(response.foods.count)")
    /// ```
    func validateFoods(_ foods: [KFDAFoodDTO]) -> [KFDAFoodDTO] {
        return foods.filter { food in
            let isValid = food.isValid

            if !isValid {
                // 유효하지 않은 데이터 로깅 (디버그 모드에서만)
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
/// 테스트용 Mock KFDA API 서비스
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockKFDAFoodAPIService {

    /// Mock 응답 데이터
    var mockSearchResponse: KFDASearchResponseDTO?

    /// Mock 상세 정보
    var mockFoodDetail: KFDAFoodDTO?

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 검색 메서드 Mock
    func searchFoods(
        query: String,
        startIdx: Int = 1,
        endIdx: Int? = nil
    ) async throws -> KFDASearchResponseDTO {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 응답 반환
        guard let response = mockSearchResponse else {
            throw KFDAAPIError.noData
        }

        return response
    }

    /// 상세 조회 메서드 Mock
    func getFoodDetail(foodCode: String) async throws -> KFDAFoodDTO {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 데이터 반환
        guard let detail = mockFoodDetail else {
            throw KFDAAPIError.noData
        }

        return detail
    }
}
#endif

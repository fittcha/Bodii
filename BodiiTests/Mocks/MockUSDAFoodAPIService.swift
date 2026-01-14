//
//  MockUSDAFoodAPIService.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Mock Objects for Unit Testing
// 테스트에서 실제 API 호출 없이 동작을 검증할 수 있는 Mock 객체
// 💡 Java 비교: Mockito의 @Mock 어노테이션과 유사한 역할

import Foundation
@testable import Bodii

/// 테스트용 Mock USDA API 서비스
///
/// 📚 학습 포인트: Configurable Mock Service
/// 실제 네트워크 호출 없이 다양한 시나리오를 테스트할 수 있습니다
/// - Success/Failure 시나리오
/// - Network delay 시뮬레이션
/// - 다양한 응답 데이터 설정
/// 💡 Java 비교: Mockito.when().thenReturn() 패턴
///
/// **주요 기능:**
/// - 설정 가능한 Mock 응답
/// - 에러 시나리오 시뮬레이션
/// - 네트워크 지연 시뮬레이션
/// - 호출 횟수 추적
///
/// **사용 예시:**
/// ```swift
/// let mockService = MockUSDAFoodAPIService()
///
/// // Success 시나리오
/// mockService.mockSearchResponse = USDASearchResponseDTO(...)
/// let result = try await mockService.searchFoods(query: "apple")
///
/// // Failure 시나리오
/// mockService.shouldThrowError = NetworkError.timeout
/// do {
///     _ = try await mockService.searchFoods(query: "apple")
/// } catch {
///     // 에러 처리 테스트
/// }
///
/// // Network delay 시뮬레이션
/// mockService.simulatedDelay = 2.0  // 2초 지연
/// let result = try await mockService.searchFoods(query: "apple")
/// ```
final class MockUSDAFoodAPIService {

    // MARK: - Mock Configuration

    /// Mock 검색 응답 데이터
    ///
    /// 📚 학습 포인트: Configurable Response
    /// 테스트마다 다른 응답 데이터를 설정할 수 있음
    var mockSearchResponse: USDASearchResponseDTO?

    /// Mock 상세 정보
    ///
    /// getFoodDetail() 호출 시 반환할 데이터
    var mockFoodDetail: USDAFoodDTO?

    /// Mock 일괄 조회 응답
    ///
    /// getFoods() 호출 시 반환할 데이터
    var mockFoods: [USDAFoodDTO]?

    /// 에러 시뮬레이션
    ///
    /// 📚 학습 포인트: Error Simulation
    /// nil이 아닌 경우 항상 해당 에러를 throw
    /// 💡 Java 비교: Mockito.when().thenThrow()
    var shouldThrowError: Error?

    /// 네트워크 지연 시뮬레이션 (초)
    ///
    /// 📚 학습 포인트: Network Delay Simulation
    /// 실제 네트워크 지연을 시뮬레이션하여 timeout, race condition 등 테스트
    /// 💡 0.0 = 지연 없음, 1.0 = 1초 지연
    var simulatedDelay: TimeInterval = 0.0

    // MARK: - Call Tracking

    /// 호출 횟수 추적: searchFoods()
    ///
    /// 📚 학습 포인트: Call Tracking
    /// 메서드가 몇 번 호출되었는지 추적하여 테스트 검증
    /// 💡 Java 비교: Mockito.verify(mock, times(n))
    var searchFoodsCallCount = 0

    /// 호출 횟수 추적: getFoodDetail()
    var getFoodDetailCallCount = 0

    /// 호출 횟수 추적: getFoods()
    var getFoodsCallCount = 0

    /// 마지막 검색 쿼리
    ///
    /// 📚 학습 포인트: Argument Capture
    /// 메서드 호출 시 전달된 인자를 캡처하여 검증
    /// 💡 Java 비교: ArgumentCaptor
    var lastSearchQuery: String?

    /// 마지막 검색 페이지 정보
    var lastPageSize: Int?
    var lastPageNumber: Int?
    var lastDataType: [String]?

    /// 마지막 조회한 FDC ID
    var lastFdcId: String?

    /// 마지막 일괄 조회한 FDC ID 목록
    var lastFdcIds: [String]?

    // MARK: - Mock Methods

    /// 식품명으로 검색 (Mock)
    ///
    /// 📚 학습 포인트: Mock Implementation
    /// 실제 API 호출 대신 미리 설정된 응답 반환
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - pageSize: 페이지 크기
    ///   - pageNumber: 페이지 번호
    ///   - dataType: 데이터 타입 필터
    ///
    /// - Returns: Mock 검색 응답
    ///
    /// - Throws:
    ///   - shouldThrowError가 설정된 경우 해당 에러
    ///   - mockSearchResponse가 nil인 경우 USDAAPIError.noData
    func searchFoods(
        query: String,
        pageSize: Int = Constants.API.USDA.defaultPageSize,
        pageNumber: Int = 1,
        dataType: [String]? = nil
    ) async throws -> USDASearchResponseDTO {

        // 호출 추적
        searchFoodsCallCount += 1
        lastSearchQuery = query
        lastPageSize = pageSize
        lastPageNumber = pageNumber
        lastDataType = dataType

        // 네트워크 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

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

    /// 식품 상세 조회 (Mock)
    ///
    /// - Parameter fdcId: FDC ID
    ///
    /// - Returns: Mock 식품 상세 정보
    ///
    /// - Throws:
    ///   - shouldThrowError가 설정된 경우 해당 에러
    ///   - mockFoodDetail이 nil인 경우 USDAAPIError.notFound
    func getFoodDetail(fdcId: String) async throws -> USDAFoodDTO {

        // 호출 추적
        getFoodDetailCallCount += 1
        lastFdcId = fdcId

        // 네트워크 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

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

    /// 식품 일괄 조회 (Mock)
    ///
    /// - Parameter fdcIds: FDC ID 목록
    ///
    /// - Returns: Mock 식품 목록
    ///
    /// - Throws:
    ///   - shouldThrowError가 설정된 경우 해당 에러
    ///   - mockFoods가 nil인 경우 USDAAPIError.noData
    func getFoods(fdcIds: [String]) async throws -> [USDAFoodDTO] {

        // 호출 추적
        getFoodsCallCount += 1
        lastFdcIds = fdcIds

        // 네트워크 지연 시뮬레이션
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }

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

    // MARK: - Test Helpers

    /// Mock 상태 초기화
    ///
    /// 📚 학습 포인트: Test Setup/Teardown
    /// 각 테스트 전후에 호출하여 Mock 상태를 깨끗하게 유지
    /// 💡 Java 비교: @Before, @After 어노테이션
    ///
    /// **사용 예시:**
    /// ```swift
    /// class MyTests: XCTestCase {
    ///     var mockService: MockUSDAFoodAPIService!
    ///
    ///     override func setUp() {
    ///         super.setUp()
    ///         mockService = MockUSDAFoodAPIService()
    ///     }
    ///
    ///     override func tearDown() {
    ///         mockService.reset()
    ///         super.tearDown()
    ///     }
    /// }
    /// ```
    func reset() {
        mockSearchResponse = nil
        mockFoodDetail = nil
        mockFoods = nil
        shouldThrowError = nil
        simulatedDelay = 0.0
        searchFoodsCallCount = 0
        getFoodDetailCallCount = 0
        getFoodsCallCount = 0
        lastSearchQuery = nil
        lastPageSize = nil
        lastPageNumber = nil
        lastDataType = nil
        lastFdcId = nil
        lastFdcIds = nil
    }

    /// Sample 검색 응답 생성 (테스트 헬퍼)
    ///
    /// 📚 학습 포인트: Test Data Builder
    /// 테스트용 샘플 데이터를 쉽게 생성
    /// 💡 Java 비교: Builder 패턴 또는 ObjectMother 패턴
    ///
    /// - Parameters:
    ///   - foods: 식품 목록
    ///   - totalHits: 전체 개수
    ///
    /// - Returns: 샘플 USDASearchResponseDTO
    static func createSampleSearchResponse(
        foods: [USDAFoodDTO],
        totalHits: Int? = nil
    ) -> USDASearchResponseDTO {
        let total = totalHits ?? foods.count

        return USDASearchResponseDTO(
            totalHits: total,
            currentPage: 1,
            totalPages: (total + 19) / 20,
            foods: foods
        )
    }

    /// Sample 식품 DTO 생성 (테스트 헬퍼)
    ///
    /// - Parameters:
    ///   - fdcId: FDC ID
    ///   - description: 식품명
    ///   - calories: 칼로리
    ///
    /// - Returns: 샘플 USDAFoodDTO
    static func createSampleFood(
        fdcId: Int = 123456,
        description: String = "Apple, raw",
        calories: Double = 52.0
    ) -> USDAFoodDTO {
        let nutrients: [USDANutrientDTO] = [
            // 칼로리 (Energy)
            USDANutrientDTO(
                nutrientId: USDANutrientID.energy,
                nutrientName: "Energy",
                nutrientNumber: "208",
                unitName: "kcal",
                value: calories
            ),
            // 단백질 (Protein)
            USDANutrientDTO(
                nutrientId: USDANutrientID.protein,
                nutrientName: "Protein",
                nutrientNumber: "203",
                unitName: "g",
                value: 0.3
            ),
            // 지방 (Fat)
            USDANutrientDTO(
                nutrientId: USDANutrientID.fat,
                nutrientName: "Total lipid (fat)",
                nutrientNumber: "204",
                unitName: "g",
                value: 0.2
            ),
            // 탄수화물 (Carbohydrate)
            USDANutrientDTO(
                nutrientId: USDANutrientID.carbohydrate,
                nutrientName: "Carbohydrate, by difference",
                nutrientNumber: "205",
                unitName: "g",
                value: 13.8
            ),
            // 나트륨 (Sodium)
            USDANutrientDTO(
                nutrientId: USDANutrientID.sodium,
                nutrientName: "Sodium, Na",
                nutrientNumber: "307",
                unitName: "mg",
                value: 1.0
            )
        ]

        return USDAFoodDTO(
            fdcId: fdcId,
            description: description,
            dataType: "Foundation",
            foodNutrients: nutrients,
            servingSize: 100.0,
            servingSizeUnit: "g"
        )
    }
}

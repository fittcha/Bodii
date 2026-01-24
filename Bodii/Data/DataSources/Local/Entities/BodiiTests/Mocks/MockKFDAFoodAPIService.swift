//
//  MockKFDAFoodAPIService.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Mock Objects for Unit Testing
// 테스트에서 실제 API 호출 없이 동작을 검증할 수 있는 Mock 객체
// 💡 Java 비교: Mockito의 @Mock 어노테이션과 유사한 역할

import Foundation
@testable import Bodii

/// 테스트용 Mock KFDA API 서비스
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
/// let mockService = MockKFDAFoodAPIService()
///
/// // Success 시나리오
/// mockService.mockSearchResponse = KFDASearchResponseDTO(...)
/// let result = try await mockService.searchFoods(query: "김치")
///
/// // Failure 시나리오
/// mockService.shouldThrowError = NetworkError.timeout
/// do {
///     _ = try await mockService.searchFoods(query: "김치")
/// } catch {
///     // 에러 처리 테스트
/// }
///
/// // Network delay 시뮬레이션
/// mockService.simulatedDelay = 2.0  // 2초 지연
/// let result = try await mockService.searchFoods(query: "김치")
/// ```
final class MockKFDAFoodAPIService {

    // MARK: - Mock Configuration

    /// Mock 검색 응답 데이터
    ///
    /// 📚 학습 포인트: Configurable Response
    /// 테스트마다 다른 응답 데이터를 설정할 수 있음
    var mockSearchResponse: KFDASearchResponseDTO?

    /// Mock 상세 정보
    ///
    /// getFoodDetail() 호출 시 반환할 데이터
    var mockFoodDetail: KFDAFoodDTO?

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

    /// 마지막 검색 쿼리
    ///
    /// 📚 학습 포인트: Argument Capture
    /// 메서드 호출 시 전달된 인자를 캡처하여 검증
    /// 💡 Java 비교: ArgumentCaptor
    var lastSearchQuery: String?

    /// 마지막 검색 인덱스 범위
    var lastSearchStartIdx: Int?
    var lastSearchEndIdx: Int?

    /// 마지막 조회한 식품 코드
    var lastFoodCode: String?

    // MARK: - Mock Methods

    /// 식품명으로 검색 (Mock)
    ///
    /// 📚 학습 포인트: Mock Implementation
    /// 실제 API 호출 대신 미리 설정된 응답 반환
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - startIdx: 시작 인덱스
    ///   - endIdx: 종료 인덱스
    ///
    /// - Returns: Mock 검색 응답
    ///
    /// - Throws:
    ///   - shouldThrowError가 설정된 경우 해당 에러
    ///   - mockSearchResponse가 nil인 경우 KFDAAPIError.noData
    func searchFoods(
        query: String,
        startIdx: Int = 1,
        endIdx: Int? = nil
    ) async throws -> KFDASearchResponseDTO {

        // 호출 추적
        searchFoodsCallCount += 1
        lastSearchQuery = query
        lastSearchStartIdx = startIdx
        lastSearchEndIdx = endIdx

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
            throw KFDAAPIError.noData
        }

        return response
    }

    /// 식품 상세 조회 (Mock)
    ///
    /// - Parameter foodCode: 식품 코드
    ///
    /// - Returns: Mock 식품 상세 정보
    ///
    /// - Throws:
    ///   - shouldThrowError가 설정된 경우 해당 에러
    ///   - mockFoodDetail이 nil인 경우 KFDAAPIError.noData
    func getFoodDetail(foodCode: String) async throws -> KFDAFoodDTO {

        // 호출 추적
        getFoodDetailCallCount += 1
        lastFoodCode = foodCode

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
            throw KFDAAPIError.noData
        }

        return detail
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
    ///     var mockService: MockKFDAFoodAPIService!
    ///
    ///     override func setUp() {
    ///         super.setUp()
    ///         mockService = MockKFDAFoodAPIService()
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
        shouldThrowError = nil
        simulatedDelay = 0.0
        searchFoodsCallCount = 0
        getFoodDetailCallCount = 0
        lastSearchQuery = nil
        lastSearchStartIdx = nil
        lastSearchEndIdx = nil
        lastFoodCode = nil
    }

    /// Sample 검색 응답 생성 (테스트 헬퍼)
    ///
    /// 📚 학습 포인트: Test Data Builder
    /// 테스트용 샘플 데이터를 쉽게 생성
    /// 💡 Java 비교: Builder 패턴 또는 ObjectMother 패턴
    ///
    /// - Parameters:
    ///   - foods: 식품 목록
    ///   - totalCount: 전체 개수
    ///
    /// - Returns: 샘플 KFDASearchResponseDTO
    static func createSampleSearchResponse(
        foods: [KFDAFoodDTO],
        totalCount: Int? = nil
    ) -> KFDASearchResponseDTO {
        let count = totalCount ?? foods.count

        return KFDASearchResponseDTO(
            header: KFDASearchResponseDTO.Header(
                resultCode: "00",
                resultMsg: "NORMAL SERVICE."
            ),
            body: KFDASearchResponseDTO.Body(
                pageNo: 1,
                totalCount: count,
                numOfRows: foods.count,
                items: foods
            )
        )
    }

    /// Sample 식품 DTO 생성 (테스트 헬퍼)
    ///
    /// - Parameters:
    ///   - foodCd: 식품 코드
    ///   - name: 식품명
    ///   - calories: 칼로리
    ///
    /// - Returns: 샘플 KFDAFoodDTO
    static func createSampleFood(
        foodCd: String = "D000001",
        name: String = "김치찌개",
        calories: String = "50"
    ) -> KFDAFoodDTO {
        return KFDAFoodDTO(
            foodCd: foodCd,
            descKor: name,
            servingWt: "210",
            enercKcal: calories,
            prot: "3.5",
            fatce: "1.2",
            chocdf: "7.8",
            nat: "450",
            fibtg: "1.5",
            sugar: "2.3"
        )
    }
}

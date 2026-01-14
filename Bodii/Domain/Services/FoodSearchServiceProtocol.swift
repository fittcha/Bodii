//
//  FoodSearchServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 음식 검색 비즈니스 로직을 처리하는 서비스 인터페이스
///
/// 로컬에 저장된 음식(사용자 정의 음식 및 캐시된 API 결과)을 검색하고,
/// 검색 결과를 관련성과 빈도에 따라 정렬하여 반환합니다.
///
/// - Note: 모든 메서드는 Swift Concurrency를 사용하여 비동기로 동작합니다.
/// - Note: 검색 결과는 한국 음식을 우선순위로 정렬합니다.
///
/// - Example:
/// ```swift
/// let service: FoodSearchServiceProtocol = LocalFoodSearchService(
///     foodRepository: foodRepository
/// )
/// let results = try await service.searchFoods(
///     query: "닭가슴살",
///     userId: userId
/// )
/// ```
protocol FoodSearchServiceProtocol {

    // MARK: - Search Operations

    /// 음식 이름으로 검색하고 관련성과 빈도에 따라 정렬합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. FoodRepository를 사용하여 이름으로 음식 검색 (부분 일치)
    /// 2. 사용자의 자주 사용하는 음식 목록 조회
    /// 3. 검색 결과를 우선순위에 따라 정렬:
    ///    - 1순위: 한국 음식 (governmentAPI) 중 자주 사용하는 음식
    ///    - 2순위: 한국 음식 (governmentAPI) 중 나머지
    ///    - 3순위: 기타 출처의 자주 사용하는 음식
    ///    - 4순위: 기타 출처의 나머지 음식
    ///
    /// - Parameters:
    ///   - query: 검색할 음식 이름 (빈 문자열인 경우 최근/자주 사용하는 음식 반환)
    ///   - userId: 사용자 ID (빈도 기반 정렬을 위해 필요)
    /// - Returns: 검색된 음식 목록 (정렬됨, 영양 정보 포함)
    /// - Throws: 조회 중 에러 발생 시
    ///
    /// - Note: 빈 검색어가 전달된 경우 빈 배열을 반환합니다.
    func searchFoods(query: String, userId: UUID) async throws -> [Food]

    /// 최근 사용한 음식을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 최근 30일 이내 사용한 음식 목록 (최대 10개)
    /// - Throws: 조회 중 에러 발생 시
    func getRecentFoods(userId: UUID) async throws -> [Food]

    /// 자주 사용하는 음식을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 자주 사용하는 음식 목록 (최대 10개)
    /// - Throws: 조회 중 에러 발생 시
    func getFrequentFoods(userId: UUID) async throws -> [Food]
}

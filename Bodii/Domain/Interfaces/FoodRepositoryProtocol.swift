//
//  FoodRepositoryProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// Food 엔티티에 대한 데이터 접근 인터페이스
///
/// Core Data를 사용하여 음식 정보를 관리하는 Repository 패턴입니다.
/// 프로토콜을 통해 데이터 소스를 추상화하여 테스트 가능성과 유지보수성을 높입니다.
///
/// - Note: 모든 메서드는 Swift Concurrency를 사용하여 비동기로 동작합니다.
///
/// - Example:
/// ```swift
/// let repository: FoodRepositoryProtocol = FoodRepository(context: persistenceController.viewContext)
/// let foods = try await repository.search(name: "닭가슴살")
/// ```
protocol FoodRepositoryProtocol {

    // MARK: - CRUD Operations

    /// 새로운 음식을 저장합니다.
    ///
    /// - Parameter food: 저장할 음식 엔티티
    /// - Returns: 저장된 음식 엔티티
    /// - Throws: Core Data 저장 중 발생한 에러
    func save(_ food: Food) async throws -> Food

    /// ID로 음식을 조회합니다.
    ///
    /// - Parameter id: 음식 ID
    /// - Returns: 조회된 음식 엔티티 (없으면 nil)
    /// - Throws: Core Data 조회 중 발생한 에러
    func findById(_ id: UUID) async throws -> Food?

    /// 모든 음식을 조회합니다.
    ///
    /// - Returns: 모든 음식 목록
    /// - Throws: Core Data 조회 중 발생한 에러
    func findAll() async throws -> [Food]

    /// 음식을 업데이트합니다.
    ///
    /// - Parameter food: 업데이트할 음식 엔티티
    /// - Returns: 업데이트된 음식 엔티티
    /// - Throws: Core Data 저장 중 발생한 에러
    func update(_ food: Food) async throws -> Food

    /// 음식을 삭제합니다.
    ///
    /// - Parameter id: 삭제할 음식 ID
    /// - Throws: Core Data 삭제 중 발생한 에러
    func delete(_ id: UUID) async throws

    // MARK: - Search Operations

    /// 음식 이름으로 검색합니다 (부분 일치).
    ///
    /// - Parameter name: 검색할 음식 이름
    /// - Returns: 이름에 검색어가 포함된 음식 목록
    /// - Throws: Core Data 조회 중 발생한 에러
    ///
    /// - Note: 검색은 대소문자를 구분하지 않으며 부분 일치를 지원합니다.
    func search(name: String) async throws -> [Food]

    // MARK: - Recent & Frequent Foods

    /// 최근 30일 내에 사용된 음식을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 최근 사용된 음식 목록 (사용 시간 역순)
    /// - Throws: Core Data 조회 중 발생한 에러
    ///
    /// - Note: FoodRecord를 기준으로 최근 30일 이내 기록이 있는 음식을 반환합니다.
    func getRecentFoods(userId: UUID) async throws -> [Food]

    /// 자주 사용된 음식을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 자주 사용된 음식 목록 (사용 횟수 내림차순, 최대 20개)
    /// - Throws: Core Data 조회 중 발생한 에러
    ///
    /// - Note: FoodRecord를 기준으로 사용 횟수가 많은 순으로 정렬하여 반환합니다.
    func getFrequentFoods(userId: UUID) async throws -> [Food]

    // MARK: - User-Defined Foods

    /// 특정 사용자가 생성한 음식을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 사용자가 생성한 음식 목록
    /// - Throws: Core Data 조회 중 발생한 에러
    func getUserDefinedFoods(userId: UUID) async throws -> [Food]

    /// 출처별 음식을 조회합니다.
    ///
    /// - Parameter source: 음식 출처 (정부 API, USDA, 사용자 정의)
    /// - Returns: 해당 출처의 음식 목록
    /// - Throws: Core Data 조회 중 발생한 에러
    func findBySource(_ source: FoodSource) async throws -> [Food]

    // MARK: - Search Ranking

    /// 음식의 검색 횟수를 증가시킵니다 (개인화 랭킹용).
    ///
    /// 사용자가 검색 결과에서 음식을 선택할 때 호출하여
    /// searchCount를 1 증가시킵니다. 높은 searchCount를 가진 음식은
    /// 검색 결과에서 더 높은 순위를 받습니다.
    ///
    /// - Parameter id: 검색 횟수를 증가시킬 음식 ID
    /// - Throws: Core Data 저장 중 발생한 에러
    func incrementSearchCount(_ id: UUID) async throws
}

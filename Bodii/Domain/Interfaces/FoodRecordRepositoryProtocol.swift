//
//  FoodRecordRepositoryProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// FoodRecord 엔티티에 대한 데이터 접근 인터페이스
///
/// Core Data를 사용하여 식단 기록 정보를 관리하는 Repository 패턴입니다.
/// 프로토콜을 통해 데이터 소스를 추상화하여 테스트 가능성과 유지보수성을 높입니다.
///
/// - Note: 모든 메서드는 Swift Concurrency를 사용하여 비동기로 동작합니다.
///
/// - Example:
/// ```swift
/// let repository: FoodRecordRepositoryProtocol = FoodRecordRepository(context: persistenceController.viewContext)
/// let records = try await repository.findByDate(date, userId: userId)
/// ```
protocol FoodRecordRepositoryProtocol {

    // MARK: - CRUD Operations

    /// 새로운 식단 기록을 저장합니다.
    ///
    /// - Parameter foodRecord: 저장할 식단 기록 엔티티
    /// - Returns: 저장된 식단 기록 엔티티
    /// - Throws: Core Data 저장 중 발생한 에러
    func save(_ foodRecord: FoodRecord) async throws -> FoodRecord

    /// ID로 식단 기록을 조회합니다.
    ///
    /// - Parameter id: 식단 기록 ID
    /// - Returns: 조회된 식단 기록 엔티티 (없으면 nil)
    /// - Throws: Core Data 조회 중 발생한 에러
    func findById(_ id: UUID) async throws -> FoodRecord?

    /// 식단 기록을 업데이트합니다.
    ///
    /// - Parameter foodRecord: 업데이트할 식단 기록 엔티티
    /// - Returns: 업데이트된 식단 기록 엔티티
    /// - Throws: Core Data 저장 중 발생한 에러
    func update(_ foodRecord: FoodRecord) async throws -> FoodRecord

    /// 식단 기록을 삭제합니다.
    ///
    /// - Parameter id: 삭제할 식단 기록 ID
    /// - Throws: Core Data 삭제 중 발생한 에러
    func delete(_ id: UUID) async throws

    // MARK: - Query Operations

    /// 특정 날짜의 모든 식단 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Returns: 해당 날짜의 식단 기록 목록 (생성시간 오름차순)
    /// - Throws: Core Data 조회 중 발생한 에러
    ///
    /// - Note: date는 날짜만 비교하며 시간은 무시됩니다.
    func findByDate(_ date: Date, userId: UUID) async throws -> [FoodRecord]

    /// 특정 날짜와 끼니의 식단 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - mealType: 끼니 종류 (아침, 점심, 저녁, 간식)
    ///   - userId: 사용자 ID
    /// - Returns: 해당 날짜와 끼니의 식단 기록 목록 (생성시간 오름차순)
    /// - Throws: Core Data 조회 중 발생한 에러
    ///
    /// - Note: date는 날짜만 비교하며 시간은 무시됩니다.
    func findByDateAndMealType(_ date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord]
}

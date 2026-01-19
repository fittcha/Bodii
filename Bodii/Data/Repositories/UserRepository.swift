//
//  UserRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// 사용자 Repository
///
/// User 엔티티에 대한 조회 작업을 처리합니다.
///
/// **주요 기능**:
/// - 현재 사용자 조회 (fetchCurrentUser)
/// - 현재 체중 조회 (getCurrentWeight)
///
/// - Example:
/// ```swift
/// let repository = UserRepository(context: persistenceController.viewContext)
///
/// // 현재 사용자 조회
/// if let user = try repository.fetchCurrentUser() {
///     print("User: \(user.name ?? "Unknown")")
/// }
///
/// // 현재 체중 조회
/// if let weight = try repository.getCurrentWeight() {
///     print("Current weight: \(weight) kg")
/// }
/// ```
final class UserRepository {

    // MARK: - Properties

    /// Core Data NSManagedObjectContext
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// Repository 초기화
    ///
    /// - Parameter context: Core Data NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Fetch Operations

    /// 현재 사용자 조회
    ///
    /// 앱에는 단일 사용자만 존재하므로, 첫 번째 User 레코드를 반환합니다.
    ///
    /// - Returns: 현재 사용자, 없으면 nil
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// if let user = try repository.fetchCurrentUser() {
    ///     print("User: \(user.name ?? "Unknown")")
    /// }
    /// ```
    func fetchCurrentUser() throws -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1

        return try context.fetch(fetchRequest).first
    }

    /// 현재 체중 조회
    ///
    /// 현재 사용자의 currentWeight를 반환합니다.
    ///
    /// - Returns: 현재 체중 (kg), 사용자가 없거나 체중이 설정되지 않았으면 nil
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// if let weight = try repository.getCurrentWeight() {
    ///     print("Current weight: \(weight) kg")
    /// }
    /// ```
    func getCurrentWeight() throws -> Decimal? {
        guard let user = try fetchCurrentUser() else {
            return nil
        }

        return user.currentWeight?.decimalValue
    }
}

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
/// 도메인 엔티티와 Core Data Managed Object 간의 변환을 담당합니다.
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
///     print("User: \(user.name)")
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
    ///     print("User: \(user.name)")
    /// }
    /// ```
    func fetchCurrentUser() throws -> User? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "User")
        fetchRequest.fetchLimit = 1

        guard let managedObject = try context.fetch(fetchRequest).first else {
            return nil
        }

        return try convertToDomain(managedObject)
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

        return user.currentWeight
    }

    // MARK: - Private Helpers

    /// Core Data Managed Object를 도메인 엔티티로 변환
    ///
    /// - Parameter managedObject: Core Data User Managed Object
    /// - Returns: User 도메인 엔티티
    /// - Throws: 필수 필드가 없거나 타입 변환 실패 시 에러
    private func convertToDomain(_ managedObject: NSManagedObject) throws -> User {
        guard let id = managedObject.value(forKey: "id") as? UUID else {
            throw RepositoryError.invalidData("User.id is missing")
        }

        guard let name = managedObject.value(forKey: "name") as? String else {
            throw RepositoryError.invalidData("User.name is missing")
        }

        guard let genderRaw = managedObject.value(forKey: "gender") as? Int16,
              let gender = Gender(rawValue: genderRaw) else {
            throw RepositoryError.invalidData("User.gender is invalid")
        }

        guard let birthDate = managedObject.value(forKey: "birthDate") as? Date else {
            throw RepositoryError.invalidData("User.birthDate is missing")
        }

        guard let height = managedObject.value(forKey: "height") as? Decimal else {
            throw RepositoryError.invalidData("User.height is missing")
        }

        guard let activityLevelRaw = managedObject.value(forKey: "activityLevel") as? Int16,
              let activityLevel = ActivityLevel(rawValue: activityLevelRaw) else {
            throw RepositoryError.invalidData("User.activityLevel is invalid")
        }

        let currentWeight = managedObject.value(forKey: "currentWeight") as? Decimal
        let currentBodyFatPct = managedObject.value(forKey: "currentBodyFatPct") as? Decimal
        let currentMuscleMass = managedObject.value(forKey: "currentMuscleMass") as? Decimal
        let currentBMR = managedObject.value(forKey: "currentBMR") as? Decimal
        let currentTDEE = managedObject.value(forKey: "currentTDEE") as? Decimal
        let metabolismUpdatedAt = managedObject.value(forKey: "metabolismUpdatedAt") as? Date

        guard let createdAt = managedObject.value(forKey: "createdAt") as? Date else {
            throw RepositoryError.invalidData("User.createdAt is missing")
        }

        guard let updatedAt = managedObject.value(forKey: "updatedAt") as? Date else {
            throw RepositoryError.invalidData("User.updatedAt is missing")
        }

        return User(
            id: id,
            name: name,
            gender: gender,
            birthDate: birthDate,
            height: height,
            activityLevel: activityLevel,
            currentWeight: currentWeight,
            currentBodyFatPct: currentBodyFatPct,
            currentMuscleMass: currentMuscleMass,
            currentBMR: currentBMR,
            currentTDEE: currentTDEE,
            metabolismUpdatedAt: metabolismUpdatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

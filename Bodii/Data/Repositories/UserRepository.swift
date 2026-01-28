//
//  UserRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

// MARK: - UserRepositoryError

/// UserRepository 에러 타입
enum UserRepositoryError: Error, LocalizedError {
    /// 사용자를 찾을 수 없음
    case userNotFound
    /// 저장 실패
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        case .saveFailed(let error):
            return "저장 실패: \(error.localizedDescription)"
        }
    }
}

/// 사용자 Repository
///
/// User 엔티티에 대한 조회 및 업데이트 작업을 처리합니다.
///
/// **주요 기능**:
/// - 현재 사용자 조회 (fetchCurrentUser)
/// - 현재 사용자 프로필 조회 (fetchCurrentUserProfile)
/// - 현재 체중 조회 (getCurrentWeight)
/// - 현재 체성분/대사량 업데이트 (updateCurrentValues)
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
/// // 현재 사용자 프로필 조회
/// if let profile = try repository.fetchCurrentUserProfile() {
///     print("Height: \(profile.height) cm")
/// }
///
/// // 현재 체중 조회
/// if let weight = try repository.getCurrentWeight() {
///     print("Current weight: \(weight) kg")
/// }
///
/// // 체성분 및 대사량 업데이트 (체성분 입력 시)
/// try await repository.updateCurrentValues(
///     weight: 70.5,
///     bodyFatPercent: 18.5,  // 인바디 측정 시
///     muscleMass: 32.0,      // 인바디 측정 시
///     bmr: 1650,
///     tdee: 2310
/// )
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

    /// 기본 context로 초기화
    convenience init() {
        self.init(context: PersistenceController.shared.viewContext)
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

    /// 현재 사용자의 UserProfile 조회
    ///
    /// Core Data User 엔티티를 도메인 UserProfile로 변환하여 반환합니다.
    /// 사용자가 없으면 nil을 반환합니다.
    ///
    /// - Returns: 현재 사용자 프로필, 없으면 nil
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// if let profile = try repository.fetchCurrentUserProfile() {
    ///     print("Height: \(profile.height) cm, Age: \(profile.age)")
    /// }
    /// ```
    func fetchCurrentUserProfile() throws -> UserProfile? {
        guard let user = try fetchCurrentUser() else {
            return nil
        }

        return mapToUserProfile(from: user)
    }

    /// 현재 사용자의 ID 조회
    ///
    /// - Returns: 현재 사용자 UUID, 없으면 nil
    /// - Throws: Core Data fetch 실패 시 에러
    func fetchCurrentUserId() throws -> UUID? {
        return try fetchCurrentUser()?.id
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

    // MARK: - Update Operations

    /// 현재 체성분 및 대사량 업데이트
    ///
    /// 체성분을 입력할 때마다 User 엔티티의 현재 값들을 업데이트합니다.
    /// 이 값들은 다른 계산(운동 칼로리 계산 등)에서 기본값으로 사용됩니다.
    ///
    /// **업데이트 시나리오**:
    /// 1. **매일 몸무게만 입력**: weight만 업데이트, bodyFatPercent/muscleMass는 nil 전달
    /// 2. **인바디 측정 시**: weight, bodyFatPercent, muscleMass 모두 업데이트
    ///
    /// - Parameters:
    ///   - weight: 현재 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%, 인바디 측정 시에만 - nil이면 기존 값 유지)
    ///   - muscleMass: 근육량 (kg, 인바디 측정 시에만 - nil이면 기존 값 유지)
    ///   - bmr: 기초대사량 (kcal/day)
    ///   - tdee: 활동대사량 (kcal/day)
    ///
    /// - Throws: 사용자가 없거나 저장 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// // 매일 몸무게만 입력하는 경우
    /// try await repository.updateCurrentValues(
    ///     weight: 70.5,
    ///     bodyFatPercent: nil,  // 기존 값 유지
    ///     muscleMass: nil,      // 기존 값 유지
    ///     bmr: 1650,
    ///     tdee: 2310
    /// )
    ///
    /// // 인바디 측정 시 (전체 체성분 입력)
    /// try await repository.updateCurrentValues(
    ///     weight: 70.5,
    ///     bodyFatPercent: 18.5,
    ///     muscleMass: 32.0,
    ///     bmr: 1620,  // Katch-McArdle 공식으로 재계산됨
    ///     tdee: 2268
    /// )
    /// ```
    func updateCurrentValues(
        weight: Decimal,
        bodyFatPercent: Decimal?,
        muscleMass: Decimal?,
        bmr: Decimal,
        tdee: Decimal
    ) async throws {
        guard let user = try fetchCurrentUser() else {
            throw UserRepositoryError.userNotFound
        }

        // 체중은 항상 업데이트
        user.currentWeight = NSDecimalNumber(decimal: weight)

        // 체지방률: nil이면 기존 값 유지, 값이 있으면 업데이트
        if let bodyFatPercent = bodyFatPercent {
            user.currentBodyFatPct = NSDecimalNumber(decimal: bodyFatPercent)
        }

        // 근육량: nil이면 기존 값 유지, 값이 있으면 업데이트
        if let muscleMass = muscleMass {
            user.currentMuscleMass = NSDecimalNumber(decimal: muscleMass)
        }

        // BMR/TDEE는 항상 업데이트 (체중 변경 시 재계산되므로)
        user.currentBMR = NSDecimalNumber(decimal: bmr)
        user.currentTDEE = NSDecimalNumber(decimal: tdee)

        // 대사량 업데이트 시간 기록
        user.metabolismUpdatedAt = Date()

        // 저장
        try context.save()
    }

    /// 현재 체중만 업데이트 (간편 입력용)
    ///
    /// 매일 몸무게만 빠르게 입력할 때 사용합니다.
    /// 체지방률과 근육량은 기존 값을 유지합니다.
    ///
    /// - Parameters:
    ///   - weight: 현재 체중 (kg)
    ///   - bmr: 기초대사량 (kcal/day)
    ///   - tdee: 활동대사량 (kcal/day)
    ///
    /// - Throws: 사용자가 없거나 저장 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// try await repository.updateCurrentWeight(
    ///     weight: 70.5,
    ///     bmr: 1650,
    ///     tdee: 2310
    /// )
    /// ```
    func updateCurrentWeight(
        weight: Decimal,
        bmr: Decimal,
        tdee: Decimal
    ) async throws {
        try await updateCurrentValues(
            weight: weight,
            bodyFatPercent: nil,
            muscleMass: nil,
            bmr: bmr,
            tdee: tdee
        )
    }

    // MARK: - Mapping

    /// Core Data User 엔티티를 도메인 UserProfile로 변환
    ///
    /// - Parameter user: Core Data User 엔티티
    /// - Returns: 도메인 UserProfile
    private func mapToUserProfile(from user: User) -> UserProfile {
        let height = user.height?.decimalValue ?? Decimal(170)
        let birthDate = user.birthDate ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        let gender = Gender(rawValue: user.gender) ?? .male
        let activityLevel = ActivityLevel(rawValue: user.activityLevel) ?? .moderatelyActive

        return UserProfile(
            id: user.id ?? UUID(),
            height: height,
            birthDate: birthDate,
            gender: gender,
            activityLevel: activityLevel
        )
    }
}

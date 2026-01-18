//
//  ExerciseRecordRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// 운동 기록 Repository
///
/// ExerciseRecord 엔티티에 대한 CRUD 작업을 처리합니다.
/// 도메인 엔티티와 Core Data Managed Object 간의 변환을 담당합니다.
///
/// **주요 기능**:
/// - 운동 기록 생성/수정 (save)
/// - ID로 단일 운동 기록 조회 (fetch by id)
/// - 특정 날짜의 운동 기록 목록 조회 (fetchAll for date)
/// - 사용자의 모든 운동 기록 조회 (fetchAll for user)
/// - 운동 기록 삭제 (delete)
///
/// - Example:
/// ```swift
/// let repository = ExerciseRecordRepository(context: persistenceController.viewContext)
///
/// // 운동 기록 저장
/// let exerciseRecord = ExerciseRecord(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     exerciseType: .running,
///     duration: 30,
///     intensity: .high,
///     caloriesBurned: 280,
///     createdAt: Date()
/// )
/// try repository.save(exerciseRecord)
///
/// // 특정 날짜의 운동 기록 조회
/// let todayRecords = try repository.fetchAll(for: user.id, on: Date())
/// ```
final class ExerciseRecordRepository {

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

    // MARK: - CRUD Operations

    /// 운동 기록 저장 (생성 또는 수정)
    ///
    /// ID가 존재하지 않으면 새로운 레코드를 생성하고,
    /// 존재하면 기존 레코드를 업데이트합니다.
    ///
    /// - Parameter exerciseRecord: 저장할 운동 기록 도메인 엔티티
    /// - Throws: Core Data 저장 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// let record = ExerciseRecord(
    ///     id: UUID(),
    ///     userId: userId,
    ///     date: Date(),
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .high,
    ///     caloriesBurned: 280,
    ///     createdAt: Date()
    /// )
    /// try repository.save(record)
    /// ```
    func save(_ exerciseRecord: ExerciseRecord) throws {
        // 기존 레코드가 있는지 확인
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ExerciseRecord")
        fetchRequest.predicate = NSPredicate(format: "id == %@", exerciseRecord.id as CVarArg)

        let managedObject: NSManagedObject

        if let existingObject = try context.fetch(fetchRequest).first {
            // 기존 레코드 업데이트
            managedObject = existingObject
        } else {
            // 새 레코드 생성
            guard let entity = NSEntityDescription.entity(forEntityName: "ExerciseRecord", in: context) else {
                throw RepositoryError.entityNotFound("ExerciseRecord")
            }
            managedObject = NSManagedObject(entity: entity, insertInto: context)

            // ID와 createdAt는 생성 시에만 설정
            managedObject.setValue(exerciseRecord.id, forKey: "id")
            managedObject.setValue(exerciseRecord.createdAt, forKey: "createdAt")
        }

        // 공통 속성 설정
        managedObject.setValue(exerciseRecord.date, forKey: "date")
        managedObject.setValue(exerciseRecord.exerciseType.rawValue, forKey: "exerciseType")
        managedObject.setValue(exerciseRecord.duration, forKey: "duration")
        managedObject.setValue(exerciseRecord.intensity.rawValue, forKey: "intensity")
        managedObject.setValue(exerciseRecord.caloriesBurned, forKey: "caloriesBurned")

        // HealthKit 관련 필드는 기본값 설정
        if managedObject.value(forKey: "fromHealthKit") == nil {
            managedObject.setValue(false, forKey: "fromHealthKit")
        }

        // User 관계 설정
        try setUserRelationship(for: managedObject, userId: exerciseRecord.userId)

        // 컨텍스트 저장
        try context.save()
    }

    /// ID로 운동 기록 조회
    ///
    /// - Parameter id: 조회할 운동 기록의 ID
    /// - Returns: 조회된 운동 기록, 없으면 nil
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// if let record = try repository.fetch(by: recordId) {
    ///     print("Found exercise: \(record.exerciseType.displayName)")
    /// }
    /// ```
    func fetch(by id: UUID) throws -> ExerciseRecord? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ExerciseRecord")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let managedObject = try context.fetch(fetchRequest).first else {
            return nil
        }

        return try convertToDomain(managedObject)
    }

    /// 특정 날짜의 운동 기록 목록 조회
    ///
    /// 같은 날짜(캘린더 기준)의 모든 운동 기록을 조회합니다.
    /// 시간 부분은 무시하고 날짜만 비교합니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 조회할 날짜
    /// - Returns: 해당 날짜의 운동 기록 목록 (생성일시 오름차순)
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// let todayRecords = try repository.fetchAll(for: userId, on: Date())
    /// print("Today's exercises: \(todayRecords.count)")
    /// ```
    func fetchAll(for userId: UUID, on date: Date) throws -> [ExerciseRecord] {
        // 날짜의 시작과 끝 계산 (시간 무시)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ExerciseRecord")
        fetchRequest.predicate = NSPredicate(
            format: "user.id == %@ AND date >= %@ AND date < %@",
            userId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        let managedObjects = try context.fetch(fetchRequest)
        return try managedObjects.map { try convertToDomain($0) }
    }

    /// 사용자의 모든 운동 기록 조회
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 사용자의 모든 운동 기록 목록 (날짜 내림차순)
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// let allRecords = try repository.fetchAll(for: userId)
    /// print("Total exercises: \(allRecords.count)")
    /// ```
    func fetchAll(for userId: UUID) throws -> [ExerciseRecord] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ExerciseRecord")
        fetchRequest.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let managedObjects = try context.fetch(fetchRequest)
        return try managedObjects.map { try convertToDomain($0) }
    }

    /// ID로 운동 기록 삭제
    ///
    /// - Parameter id: 삭제할 운동 기록의 ID
    /// - Throws: Core Data 삭제 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// try repository.delete(by: recordId)
    /// ```
    func delete(by id: UUID) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ExerciseRecord")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let managedObject = try context.fetch(fetchRequest).first else {
            // 삭제할 레코드가 없으면 조용히 반환 (이미 삭제됨)
            return
        }

        context.delete(managedObject)
        try context.save()
    }

    // MARK: - Private Helpers

    /// Core Data Managed Object를 도메인 엔티티로 변환
    ///
    /// - Parameter managedObject: Core Data ExerciseRecord Managed Object
    /// - Returns: ExerciseRecord 도메인 엔티티
    /// - Throws: 필수 필드가 없거나 타입 변환 실패 시 에러
    private func convertToDomain(_ managedObject: NSManagedObject) throws -> ExerciseRecord {
        guard let id = managedObject.value(forKey: "id") as? UUID else {
            throw RepositoryError.invalidData("ExerciseRecord.id is missing")
        }

        guard let userObject = managedObject.value(forKey: "user") as? NSManagedObject,
              let userId = userObject.value(forKey: "id") as? UUID else {
            throw RepositoryError.invalidData("ExerciseRecord.userId is missing")
        }

        guard let date = managedObject.value(forKey: "date") as? Date else {
            throw RepositoryError.invalidData("ExerciseRecord.date is missing")
        }

        guard let exerciseTypeRaw = managedObject.value(forKey: "exerciseType") as? Int16,
              let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) else {
            throw RepositoryError.invalidData("ExerciseRecord.exerciseType is invalid")
        }

        guard let duration = managedObject.value(forKey: "duration") as? Int32 else {
            throw RepositoryError.invalidData("ExerciseRecord.duration is missing")
        }

        guard let intensityRaw = managedObject.value(forKey: "intensity") as? Int16,
              let intensity = Intensity(rawValue: intensityRaw) else {
            throw RepositoryError.invalidData("ExerciseRecord.intensity is invalid")
        }

        guard let caloriesBurned = managedObject.value(forKey: "caloriesBurned") as? Int32 else {
            throw RepositoryError.invalidData("ExerciseRecord.caloriesBurned is missing")
        }

        guard let createdAt = managedObject.value(forKey: "createdAt") as? Date else {
            throw RepositoryError.invalidData("ExerciseRecord.createdAt is missing")
        }

        return ExerciseRecord(
            id: id,
            userId: userId,
            date: date,
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            caloriesBurned: caloriesBurned,
            createdAt: createdAt
        )
    }

    /// User 관계 설정
    ///
    /// ExerciseRecord의 user 관계를 설정합니다.
    ///
    /// - Parameters:
    ///   - managedObject: ExerciseRecord Managed Object
    ///   - userId: User ID
    /// - Throws: User를 찾을 수 없거나 관계 설정 실패 시 에러
    private func setUserRelationship(for managedObject: NSManagedObject, userId: UUID) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let userObject = try context.fetch(fetchRequest).first else {
            throw RepositoryError.relatedEntityNotFound("User with id \(userId)")
        }

        managedObject.setValue(userObject, forKey: "user")
    }
}

// MARK: - Repository Errors

/// Repository 레이어에서 발생하는 에러
enum RepositoryError: Error, LocalizedError {
    /// 엔티티를 찾을 수 없음
    case entityNotFound(String)

    /// 잘못된 데이터 (필수 필드 누락, 타입 불일치 등)
    case invalidData(String)

    /// 관련 엔티티를 찾을 수 없음 (Foreign Key 제약)
    case relatedEntityNotFound(String)

    var errorDescription: String? {
        switch self {
        case .entityNotFound(let entity):
            return "Entity not found: \(entity)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .relatedEntityNotFound(let entity):
            return "Related entity not found: \(entity)"
        }
    }
}

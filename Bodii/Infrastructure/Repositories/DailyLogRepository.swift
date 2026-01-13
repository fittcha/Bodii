//
//  DailyLogRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import CoreData

/// 일일 집계 Repository
///
/// DailyLog 엔티티에 대한 CRUD 작업을 처리합니다.
/// 도메인 엔티티와 Core Data Managed Object 간의 변환을 담당합니다.
///
/// **주요 기능**:
/// - 일일 집계 조회 또는 생성 (getOrCreate - 자동 DailyLog 생성)
/// - 특정 날짜의 일일 집계 조회 (fetch by date)
/// - 일일 집계 수정 (update)
///
/// - Example:
/// ```swift
/// let repository = DailyLogRepository(context: persistenceController.viewContext)
///
/// // 일일 집계 조회 또는 생성 (없으면 자동 생성)
/// let dailyLog = try repository.getOrCreate(
///     userId: user.id,
///     date: Date(),
///     defaultBMR: 1650,
///     defaultTDEE: 2310
/// )
///
/// // 일일 집계 업데이트
/// var updatedLog = dailyLog
/// updatedLog.totalCaloriesOut += 280
/// updatedLog.exerciseMinutes += 30
/// updatedLog.exerciseCount += 1
/// try repository.update(updatedLog)
/// ```
final class DailyLogRepository {

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

    /// 일일 집계 조회 또는 생성
    ///
    /// 지정된 날짜의 DailyLog가 존재하면 반환하고, 없으면 새로 생성합니다.
    /// DailyLog는 사용자별/날짜별로 고유하므로, getOrCreate 패턴이 자주 사용됩니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 조회/생성할 날짜
    ///   - defaultBMR: 새 DailyLog 생성 시 사용할 기본 BMR
    ///   - defaultTDEE: 새 DailyLog 생성 시 사용할 기본 TDEE
    /// - Returns: 기존 또는 새로 생성된 DailyLog
    /// - Throws: Core Data 작업 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// let dailyLog = try repository.getOrCreate(
    ///     userId: user.id,
    ///     date: Date(),
    ///     defaultBMR: 1650,
    ///     defaultTDEE: 2310
    /// )
    /// ```
    func getOrCreate(userId: UUID, date: Date, defaultBMR: Int32, defaultTDEE: Int32) throws -> DailyLog {
        // 기존 DailyLog가 있는지 확인
        if let existingLog = try fetch(by: userId, date: date) {
            return existingLog
        }

        // 새 DailyLog 생성
        guard let entity = NSEntityDescription.entity(forEntityName: "DailyLog", in: context) else {
            throw RepositoryError.entityNotFound("DailyLog")
        }

        let managedObject = NSManagedObject(entity: entity, insertInto: context)
        let now = Date()
        let id = UUID()

        // 필수 속성 설정
        managedObject.setValue(id, forKey: "id")
        managedObject.setValue(date, forKey: "date")
        managedObject.setValue(now, forKey: "createdAt")
        managedObject.setValue(now, forKey: "updatedAt")

        // 대사량 스냅샷
        managedObject.setValue(defaultBMR, forKey: "bmr")
        managedObject.setValue(defaultTDEE, forKey: "tdee")

        // 초기값 설정 (모두 0 또는 nil)
        managedObject.setValue(Int32(0), forKey: "totalCaloriesIn")
        managedObject.setValue(Decimal(0), forKey: "totalCarbs")
        managedObject.setValue(Decimal(0), forKey: "totalProtein")
        managedObject.setValue(Decimal(0), forKey: "totalFat")
        managedObject.setValue(nil, forKey: "carbsRatio")
        managedObject.setValue(nil, forKey: "proteinRatio")
        managedObject.setValue(nil, forKey: "fatRatio")
        managedObject.setValue(Int32(0), forKey: "totalCaloriesOut")
        managedObject.setValue(Int32(0), forKey: "exerciseMinutes")
        managedObject.setValue(Int16(0), forKey: "exerciseCount")
        managedObject.setValue(nil, forKey: "steps")
        managedObject.setValue(nil, forKey: "weight")
        managedObject.setValue(nil, forKey: "bodyFatPct")
        managedObject.setValue(nil, forKey: "sleepDuration")
        managedObject.setValue(nil, forKey: "sleepStatus")

        // netCalories 계산: totalCaloriesIn - tdee
        let netCalories = Int32(0) - defaultTDEE
        managedObject.setValue(netCalories, forKey: "netCalories")

        // User 관계 설정
        try setUserRelationship(for: managedObject, userId: userId)

        // 컨텍스트 저장
        try context.save()

        return try convertToDomain(managedObject)
    }

    /// 특정 날짜의 일일 집계 조회
    ///
    /// 같은 날짜(캘린더 기준)의 DailyLog를 조회합니다.
    /// 시간 부분은 무시하고 날짜만 비교합니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 조회할 날짜
    /// - Returns: 해당 날짜의 DailyLog, 없으면 nil
    /// - Throws: Core Data fetch 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// if let dailyLog = try repository.fetch(by: userId, date: Date()) {
    ///     print("Total calories in: \(dailyLog.totalCaloriesIn)")
    /// }
    /// ```
    func fetch(by userId: UUID, date: Date) throws -> DailyLog? {
        // 날짜의 시작과 끝 계산 (시간 무시)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DailyLog")
        fetchRequest.predicate = NSPredicate(
            format: "user.id == %@ AND date >= %@ AND date < %@",
            userId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.fetchLimit = 1

        guard let managedObject = try context.fetch(fetchRequest).first else {
            return nil
        }

        return try convertToDomain(managedObject)
    }

    /// 일일 집계 수정
    ///
    /// 기존 DailyLog의 값을 업데이트합니다.
    /// ID로 기존 레코드를 찾아 변경사항을 저장합니다.
    ///
    /// - Parameter dailyLog: 수정할 일일 집계 도메인 엔티티
    /// - Throws: Core Data 저장 실패 시 에러
    ///
    /// - Example:
    /// ```swift
    /// var dailyLog = try repository.fetch(by: userId, date: Date())!
    /// dailyLog.totalCaloriesOut += 280
    /// dailyLog.exerciseMinutes += 30
    /// dailyLog.exerciseCount += 1
    /// try repository.update(dailyLog)
    /// ```
    func update(_ dailyLog: DailyLog) throws {
        // 기존 레코드 조회
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "DailyLog")
        fetchRequest.predicate = NSPredicate(format: "id == %@", dailyLog.id as CVarArg)
        fetchRequest.fetchLimit = 1

        guard let managedObject = try context.fetch(fetchRequest).first else {
            throw RepositoryError.entityNotFound("DailyLog with id \(dailyLog.id)")
        }

        // 모든 속성 업데이트
        managedObject.setValue(dailyLog.date, forKey: "date")
        managedObject.setValue(Date(), forKey: "updatedAt")

        // 섭취 데이터
        managedObject.setValue(dailyLog.totalCaloriesIn, forKey: "totalCaloriesIn")
        managedObject.setValue(dailyLog.totalCarbs, forKey: "totalCarbs")
        managedObject.setValue(dailyLog.totalProtein, forKey: "totalProtein")
        managedObject.setValue(dailyLog.totalFat, forKey: "totalFat")
        managedObject.setValue(dailyLog.carbsRatio, forKey: "carbsRatio")
        managedObject.setValue(dailyLog.proteinRatio, forKey: "proteinRatio")
        managedObject.setValue(dailyLog.fatRatio, forKey: "fatRatio")

        // 대사량 스냅샷
        managedObject.setValue(dailyLog.bmr, forKey: "bmr")
        managedObject.setValue(dailyLog.tdee, forKey: "tdee")
        managedObject.setValue(dailyLog.netCalories, forKey: "netCalories")

        // 운동 데이터
        managedObject.setValue(dailyLog.totalCaloriesOut, forKey: "totalCaloriesOut")
        managedObject.setValue(dailyLog.exerciseMinutes, forKey: "exerciseMinutes")
        managedObject.setValue(dailyLog.exerciseCount, forKey: "exerciseCount")
        managedObject.setValue(dailyLog.steps, forKey: "steps")

        // 체성분 스냅샷
        managedObject.setValue(dailyLog.weight, forKey: "weight")
        managedObject.setValue(dailyLog.bodyFatPct, forKey: "bodyFatPct")

        // 수면 데이터
        managedObject.setValue(dailyLog.sleepDuration, forKey: "sleepDuration")
        managedObject.setValue(dailyLog.sleepStatus?.rawValue, forKey: "sleepStatus")

        // 컨텍스트 저장
        try context.save()
    }

    // MARK: - Private Helpers

    /// Core Data Managed Object를 도메인 엔티티로 변환
    ///
    /// - Parameter managedObject: Core Data DailyLog Managed Object
    /// - Returns: DailyLog 도메인 엔티티
    /// - Throws: 필수 필드가 없거나 타입 변환 실패 시 에러
    private func convertToDomain(_ managedObject: NSManagedObject) throws -> DailyLog {
        guard let id = managedObject.value(forKey: "id") as? UUID else {
            throw RepositoryError.invalidData("DailyLog.id is missing")
        }

        guard let userObject = managedObject.value(forKey: "user") as? NSManagedObject,
              let userId = userObject.value(forKey: "id") as? UUID else {
            throw RepositoryError.invalidData("DailyLog.userId is missing")
        }

        guard let date = managedObject.value(forKey: "date") as? Date else {
            throw RepositoryError.invalidData("DailyLog.date is missing")
        }

        guard let totalCaloriesIn = managedObject.value(forKey: "totalCaloriesIn") as? Int32 else {
            throw RepositoryError.invalidData("DailyLog.totalCaloriesIn is missing")
        }

        guard let totalCarbs = managedObject.value(forKey: "totalCarbs") as? Decimal else {
            throw RepositoryError.invalidData("DailyLog.totalCarbs is missing")
        }

        guard let totalProtein = managedObject.value(forKey: "totalProtein") as? Decimal else {
            throw RepositoryError.invalidData("DailyLog.totalProtein is missing")
        }

        guard let totalFat = managedObject.value(forKey: "totalFat") as? Decimal else {
            throw RepositoryError.invalidData("DailyLog.totalFat is missing")
        }

        let carbsRatio = managedObject.value(forKey: "carbsRatio") as? Decimal
        let proteinRatio = managedObject.value(forKey: "proteinRatio") as? Decimal
        let fatRatio = managedObject.value(forKey: "fatRatio") as? Decimal

        guard let bmr = managedObject.value(forKey: "bmr") as? Int32 else {
            throw RepositoryError.invalidData("DailyLog.bmr is missing")
        }

        guard let tdee = managedObject.value(forKey: "tdee") as? Int32 else {
            throw RepositoryError.invalidData("DailyLog.tdee is missing")
        }

        guard let netCalories = managedObject.value(forKey: "netCalories") as? Int32 else {
            throw RepositoryError.invalidData("DailyLog.netCalories is missing")
        }

        guard let totalCaloriesOut = managedObject.value(forKey: "totalCaloriesOut") as? Int32 else {
            throw RepositoryError.invalidData("DailyLog.totalCaloriesOut is missing")
        }

        guard let exerciseMinutes = managedObject.value(forKey: "exerciseMinutes") as? Int32 else {
            throw RepositoryError.invalidData("DailyLog.exerciseMinutes is missing")
        }

        guard let exerciseCount = managedObject.value(forKey: "exerciseCount") as? Int16 else {
            throw RepositoryError.invalidData("DailyLog.exerciseCount is missing")
        }

        let steps = managedObject.value(forKey: "steps") as? Int32
        let weight = managedObject.value(forKey: "weight") as? Decimal
        let bodyFatPct = managedObject.value(forKey: "bodyFatPct") as? Decimal
        let sleepDuration = managedObject.value(forKey: "sleepDuration") as? Int32

        let sleepStatus: SleepStatus?
        if let sleepStatusRaw = managedObject.value(forKey: "sleepStatus") as? Int16 {
            sleepStatus = SleepStatus(rawValue: sleepStatusRaw)
        } else {
            sleepStatus = nil
        }

        guard let createdAt = managedObject.value(forKey: "createdAt") as? Date else {
            throw RepositoryError.invalidData("DailyLog.createdAt is missing")
        }

        guard let updatedAt = managedObject.value(forKey: "updatedAt") as? Date else {
            throw RepositoryError.invalidData("DailyLog.updatedAt is missing")
        }

        return DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            carbsRatio: carbsRatio,
            proteinRatio: proteinRatio,
            fatRatio: fatRatio,
            bmr: bmr,
            tdee: tdee,
            netCalories: netCalories,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// User 관계 설정
    ///
    /// DailyLog의 user 관계를 설정합니다.
    ///
    /// - Parameters:
    ///   - managedObject: DailyLog Managed Object
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

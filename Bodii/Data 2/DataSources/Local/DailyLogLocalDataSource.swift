//
//  DailyLogLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Core Data CRUD 작업
// LocalDataSource는 Core Data와 직접 상호작용하는 계층
// 💡 Java 비교: DAO(Data Access Object) 패턴과 유사

import Foundation
import CoreData

// MARK: - DailyLogLocalDataSource

/// DailyLog의 Core Data 작업을 담당하는 로컬 데이터 소스
///
/// ## 책임
/// - Core Data의 DailyLog 엔티티 CRUD 작업
/// - NSManagedObject ↔ Domain Entity 매핑
/// - 날짜 기반 조회
/// - 운동 데이터 증감 처리
///
/// ## 의존성
/// - NSManagedObjectContext: Core Data 컨텍스트
///
/// - Example:
/// ```swift
/// let context = PersistenceController.shared.viewContext
/// let dataSource = DailyLogLocalDataSource(context: context)
///
/// // DailyLog 조회 또는 생성
/// let dailyLog = try await dataSource.getOrCreate(
///     for: Date(),
///     userId: userId,
///     bmr: 1650,
///     tdee: 2310
/// )
/// ```
final class DailyLogLocalDataSource {

    // MARK: - Properties

    // 📚 학습 포인트: NSManagedObjectContext
    // Core Data의 작업 공간 - 엔티티의 CRUD 작업을 추적하고 관리
    // 💡 Java 비교: JPA의 EntityManager와 유사한 역할
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    /// LocalDataSource 초기화
    /// - Parameter context: Core Data 컨텍스트
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Get or Create

    /// 특정 날짜의 DailyLog를 조회하거나 없으면 생성합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    ///   - bmr: 기초대사량 (kcal), DailyLog 생성 시 사용
    ///   - tdee: 활동대사량 (kcal), DailyLog 생성 시 사용
    /// - Throws: Core Data 작업 실패 시 에러
    /// - Returns: 조회되거나 생성된 DailyLog
    func getOrCreate(
        for date: Date,
        userId: UUID,
        bmr: Int32,
        tdee: Int32
    ) async throws -> Domain.DailyLog {
        // 📚 학습 포인트: async/await with Core Data
        // context.perform을 사용하여 Core Data의 스레드 안전성 보장
        // 💡 Java 비교: @Transactional 어노테이션과 유사한 역할

        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 해당 날짜의 DailyLog가 이미 존재하는지 확인
            if let existing = try self.fetchDailyLog(for: date, userId: userId) {
                return existing
            }

            // 없으면 새로 생성
            return try self.createDailyLog(date: date, userId: userId, bmr: bmr, tdee: tdee)
        }
    }

    /// 특정 날짜의 DailyLog를 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 조회된 DailyLog, 없으면 nil
    func fetch(for date: Date, userId: UUID) async throws -> Domain.DailyLog? {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            return try self.fetchDailyLog(for: date, userId: userId)
        }
    }

    /// 오늘 날짜의 DailyLog를 조회합니다.
    ///
    /// 대시보드에서 사용하는 단일 진입점으로, 오늘 날짜의 DailyLog를 반환합니다.
    /// DailyLog에는 모든 사전 계산된 값(칼로리, 매크로, 운동, 수면 등)이 포함되어 있습니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 조회된 DailyLog, 없으면 nil
    func fetchCurrentDay(userId: UUID) async throws -> Domain.DailyLog? {
        // 📚 학습 포인트: 현재 날짜 가져오기
        // Date()는 현재 시각을 반환하며, fetchDailyLog에서 startOfDay로 정규화됨
        let today = Date()
        return try await fetch(for: today, userId: userId)
    }

    // MARK: - Update

    /// DailyLog를 업데이트합니다.
    ///
    /// - Parameter dailyLog: 업데이트할 DailyLog
    /// - Throws: 업데이트 실패 시 에러
    /// - Returns: 업데이트된 DailyLog
    func update(_ dailyLog: Domain.DailyLog) async throws -> Domain.DailyLog {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 기존 레코드 조회
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(
                format: "id == %@ AND user.id == %@",
                dailyLog.id as CVarArg,
                dailyLog.userId as CVarArg
            )
            request.fetchLimit = 1

            guard let managedObject = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            // 도메인 엔티티 → Core Data 엔티티 매핑
            self.mapToManagedObject(from: dailyLog, to: managedObject)

            try self.context.save()

            return self.mapToDomainEntity(from: managedObject)
        }
    }

    // MARK: - Exercise Updates

    /// 운동 추가 시 DailyLog를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - calories: 소모 칼로리 (kcal)
    ///   - duration: 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    func addExercise(
        date: Date,
        userId: UUID,
        calories: Int32,
        duration: Int32
    ) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 📚 학습 포인트: 날짜 범위 계산
            // 해당 날짜의 00:00:00 ~ 23:59:59 범위 계산
            let calendar = Calendar.current
            guard let startOfDay = calendar.startOfDay(for: date) as Date? else {
                throw DataSourceError.invalidDate
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(
                format: "date == %@ AND user.id == %@",
                startOfDay as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            guard let managedObject = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            // 📚 학습 포인트: 값 증가
            // 기존 값에 새로운 값을 더함
            let currentCaloriesOut = managedObject.value(forKey: "totalCaloriesOut") as! Int32
            let currentMinutes = managedObject.value(forKey: "exerciseMinutes") as! Int32
            let currentCount = managedObject.value(forKey: "exerciseCount") as! Int16

            managedObject.setValue(currentCaloriesOut + calories, forKey: "totalCaloriesOut")
            managedObject.setValue(currentMinutes + duration, forKey: "exerciseMinutes")
            managedObject.setValue(currentCount + 1, forKey: "exerciseCount")

            // updatedAt 갱신
            managedObject.setValue(Date(), forKey: "updatedAt")

            try self.context.save()
        }
    }

    /// 운동 삭제 시 DailyLog를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - calories: 소모 칼로리 (kcal)
    ///   - duration: 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    func removeExercise(
        date: Date,
        userId: UUID,
        calories: Int32,
        duration: Int32
    ) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            guard let startOfDay = calendar.startOfDay(for: date) as Date? else {
                throw DataSourceError.invalidDate
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(
                format: "date == %@ AND user.id == %@",
                startOfDay as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            guard let managedObject = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            // 📚 학습 포인트: 값 감소
            // 기존 값에서 값을 뺌 (음수가 되지 않도록 max(0, ...) 사용)
            let currentCaloriesOut = managedObject.value(forKey: "totalCaloriesOut") as! Int32
            let currentMinutes = managedObject.value(forKey: "exerciseMinutes") as! Int32
            let currentCount = managedObject.value(forKey: "exerciseCount") as! Int16

            managedObject.setValue(max(0, currentCaloriesOut - calories), forKey: "totalCaloriesOut")
            managedObject.setValue(max(0, currentMinutes - duration), forKey: "exerciseMinutes")
            managedObject.setValue(max(0, currentCount - 1), forKey: "exerciseCount")

            // updatedAt 갱신
            managedObject.setValue(Date(), forKey: "updatedAt")

            try self.context.save()
        }
    }

    /// 운동 수정 시 DailyLog를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - date: 운동 날짜
    ///   - userId: 사용자 ID
    ///   - oldCalories: 이전 소모 칼로리 (kcal)
    ///   - newCalories: 새로운 소모 칼로리 (kcal)
    ///   - oldDuration: 이전 운동 시간 (분)
    ///   - newDuration: 새로운 운동 시간 (분)
    /// - Throws: 업데이트 실패 시 에러
    func updateExercise(
        date: Date,
        userId: UUID,
        oldCalories: Int32,
        newCalories: Int32,
        oldDuration: Int32,
        newDuration: Int32
    ) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            guard let startOfDay = calendar.startOfDay(for: date) as Date? else {
                throw DataSourceError.invalidDate
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
            request.predicate = NSPredicate(
                format: "date == %@ AND user.id == %@",
                startOfDay as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            guard let managedObject = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            // 📚 학습 포인트: 차이값 적용
            // 이전 값을 빼고 새 값을 더함
            let currentCaloriesOut = managedObject.value(forKey: "totalCaloriesOut") as! Int32
            let currentMinutes = managedObject.value(forKey: "exerciseMinutes") as! Int32

            let caloriesDiff = newCalories - oldCalories
            let durationDiff = newDuration - oldDuration

            managedObject.setValue(currentCaloriesOut + caloriesDiff, forKey: "totalCaloriesOut")
            managedObject.setValue(currentMinutes + durationDiff, forKey: "exerciseMinutes")

            // updatedAt 갱신
            managedObject.setValue(Date(), forKey: "updatedAt")

            try self.context.save()
        }
    }
}

// MARK: - Private Helpers

extension DailyLogLocalDataSource {

    /// 특정 날짜의 DailyLog를 조회합니다 (내부용)
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 조회된 DailyLog, 없으면 nil
    private func fetchDailyLog(for date: Date, userId: UUID) throws -> Domain.DailyLog? {
        // 📚 학습 포인트: 날짜 정규화
        // DailyLog는 날짜의 00:00:00으로 저장되므로 startOfDay로 정규화
        let calendar = Calendar.current
        guard let startOfDay = calendar.startOfDay(for: date) as Date? else {
            throw DataSourceError.invalidDate
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyLog")
        request.predicate = NSPredicate(
            format: "date == %@ AND user.id == %@",
            startOfDay as CVarArg,
            userId as CVarArg
        )
        request.fetchLimit = 1

        let results = try context.fetch(request)
        return results.first.map { mapToDomainEntity(from: $0) }
    }

    /// 새로운 DailyLog를 생성합니다 (내부용)
    ///
    /// - Parameters:
    ///   - date: 날짜
    ///   - userId: 사용자 ID
    ///   - bmr: 기초대사량 (kcal)
    ///   - tdee: 활동대사량 (kcal)
    /// - Throws: Core Data 생성 실패 시 에러
    /// - Returns: 생성된 DailyLog
    private func createDailyLog(
        date: Date,
        userId: UUID,
        bmr: Int32,
        tdee: Int32
    ) throws -> Domain.DailyLog {
        // 📚 학습 포인트: NSEntityDescription으로 엔티티 생성
        // Core Data 엔티티의 인스턴스를 생성
        guard let entity = NSEntityDescription.entity(
            forEntityName: "DailyLog",
            in: context
        ) else {
            throw DataSourceError.entityNotFound("DailyLog")
        }

        let managedObject = NSManagedObject(entity: entity, insertInto: context)

        // 날짜 정규화 (00:00:00으로)
        let calendar = Calendar.current
        guard let startOfDay = calendar.startOfDay(for: date) as Date? else {
            throw DataSourceError.invalidDate
        }

        // 기본 값 설정
        let now = Date()
        managedObject.setValue(UUID(), forKey: "id")
        managedObject.setValue(startOfDay, forKey: "date")
        managedObject.setValue(bmr, forKey: "bmr")
        managedObject.setValue(tdee, forKey: "tdee")
        managedObject.setValue(0, forKey: "totalCaloriesIn")
        managedObject.setValue(0, forKey: "totalCaloriesOut")
        managedObject.setValue(0, forKey: "exerciseMinutes")
        managedObject.setValue(Int16(0), forKey: "exerciseCount")
        managedObject.setValue(Decimal(0), forKey: "totalCarbs")
        managedObject.setValue(Decimal(0), forKey: "totalProtein")
        managedObject.setValue(Decimal(0), forKey: "totalFat")
        managedObject.setValue(-tdee, forKey: "netCalories") // 초기값: 0(섭취) - tdee
        managedObject.setValue(now, forKey: "createdAt")
        managedObject.setValue(now, forKey: "updatedAt")

        // 📚 학습 포인트: Relationship 설정
        // User와의 관계 설정 (user.id로 User 엔티티 조회 후 연결)
        let userRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        userRequest.fetchLimit = 1

        if let user = try? context.fetch(userRequest).first {
            managedObject.setValue(user, forKey: "user")
        }

        // 📚 학습 포인트: Core Data 저장
        // context.save()를 호출하여 변경사항을 영구 저장소에 커밋
        // ⚠️ 주의: save() 호출 전에는 메모리에만 존재
        try context.save()

        return mapToDomainEntity(from: managedObject)
    }

    /// 도메인 엔티티 → Core Data 엔티티 매핑
    ///
    /// - Parameters:
    ///   - domain: 도메인 DailyLog
    ///   - managedObject: Core Data NSManagedObject
    private func mapToManagedObject(from domain: Domain.DailyLog, to managedObject: NSManagedObject) {
        // 📚 학습 포인트: setValue를 사용한 동적 속성 설정
        // Core Data는 런타임에 속성을 설정하므로 setValue 사용
        // ⚠️ 주의: 속성 이름이 정확해야 함 (오타 시 런타임 에러)

        managedObject.setValue(domain.id, forKey: "id")
        managedObject.setValue(domain.date, forKey: "date")
        managedObject.setValue(domain.totalCaloriesIn, forKey: "totalCaloriesIn")
        managedObject.setValue(domain.totalCarbs, forKey: "totalCarbs")
        managedObject.setValue(domain.totalProtein, forKey: "totalProtein")
        managedObject.setValue(domain.totalFat, forKey: "totalFat")
        managedObject.setValue(domain.carbsRatio, forKey: "carbsRatio")
        managedObject.setValue(domain.proteinRatio, forKey: "proteinRatio")
        managedObject.setValue(domain.fatRatio, forKey: "fatRatio")
        managedObject.setValue(domain.bmr, forKey: "bmr")
        managedObject.setValue(domain.tdee, forKey: "tdee")
        managedObject.setValue(domain.netCalories, forKey: "netCalories")
        managedObject.setValue(domain.totalCaloriesOut, forKey: "totalCaloriesOut")
        managedObject.setValue(domain.exerciseMinutes, forKey: "exerciseMinutes")
        managedObject.setValue(domain.exerciseCount, forKey: "exerciseCount")
        managedObject.setValue(domain.steps, forKey: "steps")
        managedObject.setValue(domain.weight, forKey: "weight")
        managedObject.setValue(domain.bodyFatPct, forKey: "bodyFatPct")
        managedObject.setValue(domain.sleepDuration, forKey: "sleepDuration")
        managedObject.setValue(domain.sleepStatus?.rawValue, forKey: "sleepStatus")
        managedObject.setValue(domain.createdAt, forKey: "createdAt")
        managedObject.setValue(domain.updatedAt, forKey: "updatedAt")

        // Relationship 설정
        let userRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        userRequest.predicate = NSPredicate(format: "id == %@", domain.userId as CVarArg)
        userRequest.fetchLimit = 1

        if let user = try? context.fetch(userRequest).first {
            managedObject.setValue(user, forKey: "user")
        }
    }

    /// Core Data 엔티티 → 도메인 엔티티 매핑
    ///
    /// - Parameter managedObject: Core Data NSManagedObject
    /// - Returns: 도메인 DailyLog
    private func mapToDomainEntity(from managedObject: NSManagedObject) -> Domain.DailyLog {
        // 📚 학습 포인트: value(forKey:)로 속성 읽기
        // Core Data에서 값을 읽을 때 타입 캐스팅 필요
        // ⚠️ 주의: 강제 언래핑(!) 사용 시 nil이면 크래시

        let id = managedObject.value(forKey: "id") as! UUID
        let date = managedObject.value(forKey: "date") as! Date
        let totalCaloriesIn = managedObject.value(forKey: "totalCaloriesIn") as! Int32
        let totalCarbs = managedObject.value(forKey: "totalCarbs") as! Decimal
        let totalProtein = managedObject.value(forKey: "totalProtein") as! Decimal
        let totalFat = managedObject.value(forKey: "totalFat") as! Decimal
        let carbsRatio = managedObject.value(forKey: "carbsRatio") as? Decimal
        let proteinRatio = managedObject.value(forKey: "proteinRatio") as? Decimal
        let fatRatio = managedObject.value(forKey: "fatRatio") as? Decimal
        let bmr = managedObject.value(forKey: "bmr") as! Int32
        let tdee = managedObject.value(forKey: "tdee") as! Int32
        let netCalories = managedObject.value(forKey: "netCalories") as! Int32
        let totalCaloriesOut = managedObject.value(forKey: "totalCaloriesOut") as! Int32
        let exerciseMinutes = managedObject.value(forKey: "exerciseMinutes") as! Int32
        let exerciseCount = managedObject.value(forKey: "exerciseCount") as! Int16
        let steps = managedObject.value(forKey: "steps") as? Int32
        let weight = managedObject.value(forKey: "weight") as? Decimal
        let bodyFatPct = managedObject.value(forKey: "bodyFatPct") as? Decimal
        let sleepDuration = managedObject.value(forKey: "sleepDuration") as? Int32
        let sleepStatusRaw = managedObject.value(forKey: "sleepStatus") as? Int16
        let createdAt = managedObject.value(forKey: "createdAt") as! Date
        let updatedAt = managedObject.value(forKey: "updatedAt") as! Date

        // Relationship에서 userId 추출
        let user = managedObject.value(forKey: "user") as! NSManagedObject
        let userId = user.value(forKey: "id") as! UUID

        // 📚 학습 포인트: rawValue를 사용한 Enum 변환
        // Int16을 Enum으로 변환
        let sleepStatus = sleepStatusRaw.flatMap { SleepStatus(rawValue: $0) }

        return Domain.DailyLog(
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
}

// MARK: - Domain Namespace

// 📚 학습 포인트: Namespace를 사용한 이름 충돌 방지
// Core Data의 DailyLog(NSManagedObject)와 Domain의 DailyLog 구분
// 💡 Java 비교: package를 사용한 네임스페이스와 유사한 역할
enum Domain {
    typealias DailyLog = Bodii.DailyLog
}

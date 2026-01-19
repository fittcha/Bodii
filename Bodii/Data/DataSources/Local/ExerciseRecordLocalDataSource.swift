//
//  ExerciseRecordLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Core Data CRUD 작업
// LocalDataSource는 Core Data와 직접 상호작용하는 계층
// 💡 Java 비교: DAO(Data Access Object) 패턴과 유사

import Foundation
import CoreData

// MARK: - ExerciseRecordLocalDataSource

/// ExerciseRecord의 Core Data 작업을 담당하는 로컬 데이터 소스
///
/// ## 책임
/// - Core Data의 ExerciseRecord 엔티티 CRUD 작업
/// - 날짜 기반 조회 및 필터링
///
/// ## 의존성
/// - NSManagedObjectContext: Core Data 컨텍스트
///
/// - Example:
/// ```swift
/// let context = PersistenceController.shared.viewContext
/// let dataSource = ExerciseRecordLocalDataSource(context: context)
///
/// // 운동 기록 생성
/// let record = ExerciseRecord(context: context)
/// // ... 속성 설정 ...
/// try await dataSource.save(record)
///
/// // 오늘 운동 조회
/// let records = try await dataSource.fetchByDate(Date(), userId: userId)
/// ```
final class ExerciseRecordLocalDataSource {

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

    // MARK: - Create / Save

    /// 운동 기록을 저장합니다 (새로 생성하거나 업데이트).
    ///
    /// - Parameter record: 저장할 운동 기록
    /// - Throws: Core Data 저장 실패 시 에러
    /// - Returns: 저장된 운동 기록
    func save(_ record: ExerciseRecord) async throws -> ExerciseRecord {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 같은 context에 있으면 바로 저장
            if record.managedObjectContext == self.context {
                try self.context.save()
                return record
            }

            // 다른 context에서 온 경우, 새 엔티티 생성 후 복사
            let newRecord = ExerciseRecord(context: self.context)
            newRecord.id = record.id ?? UUID()
            newRecord.date = record.date
            newRecord.exerciseType = record.exerciseType
            newRecord.duration = record.duration
            newRecord.intensity = record.intensity
            newRecord.caloriesBurned = record.caloriesBurned
            newRecord.createdAt = record.createdAt ?? Date()
            newRecord.note = record.note
            newRecord.fromHealthKit = record.fromHealthKit
            newRecord.healthKitId = record.healthKitId
            newRecord.user = record.user

            try self.context.save()
            return newRecord
        }
    }

    // MARK: - Read

    /// ID로 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - id: 운동 기록 고유 식별자
    ///   - userId: 사용자 ID (권한 확인용)
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 조회된 운동 기록, 없으면 nil
    func fetchById(_ id: UUID, userId: UUID) async throws -> ExerciseRecord? {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "id == %@ AND user.id == %@",
                id as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            return try self.context.fetch(request).first
        }
    }

    /// 특정 날짜의 모든 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchByDate(_ date: Date, userId: UUID) async throws -> [ExerciseRecord] {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 📚 학습 포인트: Calendar를 사용한 날짜 범위 생성
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw DataSourceError.invalidDate
            }

            let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@ AND user.id == %@",
                startOfDay as CVarArg,
                endOfDay as CVarArg,
                userId as CVarArg
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            return try self.context.fetch(request)
        }
    }

    /// 날짜 범위 내 모든 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchByDateRange(
        startDate: Date,
        endDate: Date,
        userId: UUID
    ) async throws -> [ExerciseRecord] {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@ AND user.id == %@",
                startDate as CVarArg,
                endDate as CVarArg,
                userId as CVarArg
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: true),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            return try self.context.fetch(request)
        }
    }

    /// 모든 운동 기록을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchAll(userId: UUID) async throws -> [ExerciseRecord] {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
            request.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            return try self.context.fetch(request)
        }
    }

    // MARK: - Update

    /// 기존 운동 기록을 수정합니다.
    ///
    /// - Parameter record: 수정할 운동 기록 (ID 필수)
    /// - Throws: 업데이트 실패 또는 권한 없음 시 에러
    /// - Returns: 수정된 운동 기록
    func update(_ record: ExerciseRecord) async throws -> ExerciseRecord {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            try self.context.save()
            return record
        }
    }

    // MARK: - Delete

    /// 운동 기록을 삭제합니다.
    ///
    /// - Parameters:
    ///   - id: 삭제할 운동 기록 ID
    ///   - userId: 사용자 ID (권한 확인용)
    /// - Throws: 삭제 실패 또는 권한 없음 시 에러
    func delete(id: UUID, userId: UUID) async throws {
        try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "id == %@ AND user.id == %@",
                id as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            guard let record = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            self.context.delete(record)
            try self.context.save()
        }
    }

    // MARK: - Utility

    /// 특정 날짜의 운동 기록 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 개수
    func count(forDate date: Date, userId: UUID) async throws -> Int {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw DataSourceError.invalidDate
            }

            let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@ AND user.id == %@",
                startOfDay as CVarArg,
                endOfDay as CVarArg,
                userId as CVarArg
            )

            return try self.context.count(for: request)
        }
    }

    /// 특정 날짜의 총 운동 시간(분)을 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 총 운동 시간 (분)
    func totalDuration(forDate date: Date, userId: UUID) async throws -> Int32 {
        let records = try await fetchByDate(date, userId: userId)
        return records.reduce(0) { $0 + $1.duration }
    }

    /// 특정 날짜의 총 소모 칼로리를 반환합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 총 소모 칼로리 (kcal)
    func totalCaloriesBurned(forDate date: Date, userId: UUID) async throws -> Int32 {
        let records = try await fetchByDate(date, userId: userId)
        return records.reduce(0) { $0 + $1.caloriesBurned }
    }
}

// MARK: - DataSourceError

/// LocalDataSource에서 발생하는 에러
enum DataSourceError: LocalizedError {
    case contextDeallocated
    case entityNotFound(String)
    case recordNotFound
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .contextDeallocated:
            return "Core Data context가 해제되었습니다."
        case .entityNotFound(let entityName):
            return "엔티티를 찾을 수 없습니다: \(entityName)"
        case .recordNotFound:
            return "레코드를 찾을 수 없습니다."
        case .invalidDate:
            return "유효하지 않은 날짜입니다."
        }
    }
}

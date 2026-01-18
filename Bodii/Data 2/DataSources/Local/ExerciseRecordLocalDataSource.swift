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
/// - NSManagedObject ↔ Domain Entity 매핑
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
/// let record = ExerciseRecord(...)
/// try await dataSource.create(record)
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

    // MARK: - Create

    /// 새로운 운동 기록을 생성합니다.
    ///
    /// - Parameter record: 생성할 운동 기록
    /// - Throws: Core Data 저장 실패 시 에러
    /// - Returns: 생성된 운동 기록
    func create(_ record: Domain.ExerciseRecord) async throws -> Domain.ExerciseRecord {
        // 📚 학습 포인트: async/await with Core Data
        // context.perform을 사용하여 Core Data의 스레드 안전성 보장
        // 💡 Java 비교: @Transactional 어노테이션과 유사한 역할

        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 📚 학습 포인트: NSEntityDescription으로 엔티티 생성
            // Core Data 엔티티의 인스턴스를 생성
            guard let entity = NSEntityDescription.entity(
                forEntityName: "ExerciseRecord",
                in: self.context
            ) else {
                throw DataSourceError.entityNotFound("ExerciseRecord")
            }

            let managedObject = NSManagedObject(entity: entity, insertInto: self.context)

            // 도메인 엔티티 → Core Data 엔티티 매핑
            self.mapToManagedObject(from: record, to: managedObject)

            // 📚 학습 포인트: Core Data 저장
            // context.save()를 호출하여 변경사항을 영구 저장소에 커밋
            // ⚠️ 주의: save() 호출 전에는 메모리에만 존재
            try self.context.save()

            // Core Data 엔티티 → 도메인 엔티티로 변환하여 반환
            return self.mapToDomainEntity(from: managedObject)
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
    func fetchById(_ id: UUID, userId: UUID) async throws -> Domain.ExerciseRecord? {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 📚 학습 포인트: NSFetchRequest 생성
            // Core Data에서 데이터를 조회하기 위한 쿼리 객체
            // 💡 Java 비교: JPA의 CriteriaQuery와 유사
            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")

            // 📚 학습 포인트: NSPredicate로 필터링
            // SQL의 WHERE 절과 유사한 역할
            // ⚠️ 주의: user는 relationship이므로 user.id로 접근
            request.predicate = NSPredicate(
                format: "id == %@ AND user.id == %@",
                id as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            let results = try self.context.fetch(request)

            // 📚 학습 포인트: Optional Chaining
            // results.first는 Optional이므로 map으로 변환
            return results.first.map { self.mapToDomainEntity(from: $0) }
        }
    }

    /// 특정 날짜의 모든 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchByDate(_ date: Date, userId: UUID) async throws -> [Domain.ExerciseRecord] {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 📚 학습 포인트: Calendar를 사용한 날짜 범위 생성
            // 해당 날짜의 00:00:00 ~ 23:59:59 범위 계산
            let calendar = Calendar.current
            guard let startOfDay = calendar.startOfDay(for: date) as Date?,
                  let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw DataSourceError.invalidDate
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")

            // 날짜 범위와 사용자 ID로 필터링
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@ AND user.id == %@",
                startOfDay as CVarArg,
                endOfDay as CVarArg,
                userId as CVarArg
            )

            // 📚 학습 포인트: NSSortDescriptor로 정렬
            // SQL의 ORDER BY와 유사한 역할
            // ascending: false로 최신순 정렬
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            let results = try self.context.fetch(request)

            // 📚 학습 포인트: map을 사용한 컬렉션 변환
            // 각 NSManagedObject를 Domain Entity로 변환
            // 💡 Java 비교: Stream API의 map()과 동일
            return results.map { self.mapToDomainEntity(from: $0) }
        }
    }

    /// 날짜 범위 내 모든 운동 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - startDate: 시작 날짜 (포함)
    ///   - endDate: 종료 날짜 (포함)
    ///   - userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchByDateRange(
        startDate: Date,
        endDate: Date,
        userId: UUID
    ) async throws -> [Domain.ExerciseRecord] {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let calendar = Calendar.current
            guard let rangeStart = calendar.startOfDay(for: startDate) as Date?,
                  let rangeEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
                throw DataSourceError.invalidDate
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@ AND user.id == %@",
                rangeStart as CVarArg,
                rangeEnd as CVarArg,
                userId as CVarArg
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            let results = try self.context.fetch(request)
            return results.map { self.mapToDomainEntity(from: $0) }
        }
    }

    /// 사용자의 모든 운동 기록을 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: Core Data 조회 실패 시 에러
    /// - Returns: 운동 기록 배열 (없으면 빈 배열)
    func fetchAll(userId: UUID) async throws -> [Domain.ExerciseRecord] {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")
            request.predicate = NSPredicate(format: "user.id == %@", userId as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            let results = try self.context.fetch(request)
            return results.map { self.mapToDomainEntity(from: $0) }
        }
    }

    // MARK: - Update

    /// 기존 운동 기록을 수정합니다.
    ///
    /// - Parameter record: 수정할 운동 기록 (ID 필수)
    /// - Throws: 업데이트 실패 또는 권한 없음 시 에러
    /// - Returns: 수정된 운동 기록
    func update(_ record: Domain.ExerciseRecord) async throws -> Domain.ExerciseRecord {
        return try await context.perform { [weak self] in
            guard let self = self else {
                throw DataSourceError.contextDeallocated
            }

            // 기존 레코드 조회
            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")
            request.predicate = NSPredicate(
                format: "id == %@ AND user.id == %@",
                record.id as CVarArg,
                record.userId as CVarArg
            )
            request.fetchLimit = 1

            guard let managedObject = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            // 도메인 엔티티 → Core Data 엔티티 매핑
            self.mapToManagedObject(from: record, to: managedObject)

            try self.context.save()

            return self.mapToDomainEntity(from: managedObject)
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

            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")
            request.predicate = NSPredicate(
                format: "id == %@ AND user.id == %@",
                id as CVarArg,
                userId as CVarArg
            )
            request.fetchLimit = 1

            guard let managedObject = try self.context.fetch(request).first else {
                throw DataSourceError.recordNotFound
            }

            // 📚 학습 포인트: Core Data 삭제
            // context.delete()로 객체를 삭제 표시하고 save()로 커밋
            self.context.delete(managedObject)
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
            guard let startOfDay = calendar.startOfDay(for: date) as Date?,
                  let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw DataSourceError.invalidDate
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "ExerciseRecord")
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@ AND user.id == %@",
                startOfDay as CVarArg,
                endOfDay as CVarArg,
                userId as CVarArg
            )

            // 📚 학습 포인트: count() 메서드
            // 실제 데이터를 가져오지 않고 개수만 반환 (성능 최적화)
            // 💡 Java 비교: JPA의 COUNT 쿼리와 동일
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

        // 📚 학습 포인트: reduce를 사용한 집계
        // 배열의 모든 요소를 하나의 값으로 축약
        // 💡 Java 비교: Stream API의 reduce()와 동일
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

// MARK: - Private Helpers (Mapping)

extension ExerciseRecordLocalDataSource {

    /// 도메인 엔티티 → Core Data 엔티티 매핑
    ///
    /// - Parameters:
    ///   - domain: 도메인 ExerciseRecord
    ///   - managedObject: Core Data NSManagedObject
    private func mapToManagedObject(from domain: Domain.ExerciseRecord, to managedObject: NSManagedObject) {
        // 📚 학습 포인트: setValue를 사용한 동적 속성 설정
        // Core Data는 런타임에 속성을 설정하므로 setValue 사용
        // ⚠️ 주의: 속성 이름이 정확해야 함 (오타 시 런타임 에러)

        managedObject.setValue(domain.id, forKey: "id")
        managedObject.setValue(domain.date, forKey: "date")
        managedObject.setValue(domain.exerciseType.rawValue, forKey: "exerciseType")
        managedObject.setValue(domain.duration, forKey: "duration")
        managedObject.setValue(domain.intensity.rawValue, forKey: "intensity")
        managedObject.setValue(domain.caloriesBurned, forKey: "caloriesBurned")
        managedObject.setValue(domain.createdAt, forKey: "createdAt")

        // 📚 학습 포인트: Relationship 설정
        // User와의 관계 설정 (user.id로 User 엔티티 조회 후 연결)
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
    /// - Returns: 도메인 ExerciseRecord
    private func mapToDomainEntity(from managedObject: NSManagedObject) -> Domain.ExerciseRecord {
        // 📚 학습 포인트: value(forKey:)로 속성 읽기
        // Core Data에서 값을 읽을 때 타입 캐스팅 필요
        // ⚠️ 주의: 강제 언래핑(!) 사용 시 nil이면 크래시

        let id = managedObject.value(forKey: "id") as! UUID
        let date = managedObject.value(forKey: "date") as! Date
        let exerciseTypeRaw = managedObject.value(forKey: "exerciseType") as! Int16
        let duration = managedObject.value(forKey: "duration") as! Int32
        let intensityRaw = managedObject.value(forKey: "intensity") as! Int16
        let caloriesBurned = managedObject.value(forKey: "caloriesBurned") as! Int32
        let createdAt = managedObject.value(forKey: "createdAt") as! Date

        // Relationship에서 userId 추출
        let user = managedObject.value(forKey: "user") as! NSManagedObject
        let userId = user.value(forKey: "id") as! UUID

        // 📚 학습 포인트: rawValue를 사용한 Enum 변환
        // Int16을 Enum으로 변환 (실패 시 기본값 사용)
        let exerciseType = ExerciseType(rawValue: exerciseTypeRaw) ?? .other
        let intensity = Intensity(rawValue: intensityRaw) ?? .medium

        return Domain.ExerciseRecord(
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
}

// MARK: - Domain Namespace

// 📚 학습 포인트: Namespace를 사용한 이름 충돌 방지
// Core Data의 ExerciseRecord(NSManagedObject)와 Domain의 ExerciseRecord 구분
// 💡 Java 비교: package를 사용한 네임스페이스와 유사한 역할
enum Domain {
    typealias ExerciseRecord = Bodii.ExerciseRecord
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

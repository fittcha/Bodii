//
//  SleepRecordMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Mapper Pattern for Sleep Data
// Core Data 엔티티와 Domain 엔티티 간의 변환을 담당하는 매퍼
// 💡 Java 비교: ModelMapper 또는 MapStruct와 유사한 역할

import Foundation
import CoreData

// MARK: - SleepRecordMapper

/// SleepRecord (Core Data) ↔ SleepRecord (Domain) 매퍼
/// 데이터 레이어와 도메인 레이어 간의 경계를 명확히 구분합니다.
/// 📚 학습 포인트: Clean Architecture - Data Layer
/// - Core Data의 NSManagedObject를 도메인 엔티티로 변환
/// - 도메인 레이어가 Core Data 의존성을 갖지 않도록 격리
/// - SleepStatus enum 변환 처리 (Int16 ↔ SleepStatus)
/// - 양방향 변환 지원 (toDomain, toEntity)
/// 💡 Java 비교: DTO ↔ Entity 변환 매퍼와 유사
struct SleepRecordMapper {

    // MARK: - Types

    /// 매핑 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum MappingError: Error, LocalizedError {
        /// 필수 필드 누락
        case missingRequiredField(String)

        /// 잘못된 데이터 타입
        case invalidDataType(String)

        /// 잘못된 enum 값
        case invalidEnumValue(String)

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .missingRequiredField(let field):
                return "필수 필드가 누락되었습니다: \(field)"
            case .invalidDataType(let field):
                return "잘못된 데이터 타입입니다: \(field)"
            case .invalidEnumValue(let field):
                return "잘못된 enum 값입니다: \(field)"
            }
        }
    }

    // MARK: - Initialization

    /// Mapper 초기화
    /// 📚 학습 포인트: Stateless Mapper
    /// 이 Mapper는 상태를 갖지 않으므로 별도 초기화 불필요
    /// 그러나 명시적으로 init을 제공하여 일관성 유지
    init() {}

    // MARK: - Core Data → Domain

    /// SleepRecord (Core Data)를 SleepRecord (Domain)로 변환
    /// 📚 학습 포인트: Optional Handling & Enum Conversion
    /// Core Data의 optional 필드를 안전하게 처리하고 Int16을 SleepStatus로 변환
    /// 💡 Java 비교: Optional.ofNullable()과 유사한 패턴
    ///
    /// - Parameter entity: Core Data SleepRecord 엔티티
    /// - Returns: Domain SleepRecord
    /// - Throws: MappingError - 필수 필드 누락 또는 enum 변환 실패 시
    func toDomain(_ entity: SleepRecord) throws -> Bodii.SleepRecord {
        // 📚 학습 포인트: Guard Let Pattern
        // optional을 unwrap하고 실패 시 에러를 throw
        // 💡 Java 비교: Objects.requireNonNull()과 유사

        guard let id = entity.id else {
            throw MappingError.missingRequiredField("id")
        }

        guard let userId = entity.userId else {
            throw MappingError.missingRequiredField("userId")
        }

        guard let date = entity.date else {
            throw MappingError.missingRequiredField("date")
        }

        guard let createdAt = entity.createdAt else {
            throw MappingError.missingRequiredField("createdAt")
        }

        guard let updatedAt = entity.updatedAt else {
            throw MappingError.missingRequiredField("updatedAt")
        }

        // 📚 학습 포인트: Int16 → Enum Conversion
        // Core Data의 Int16 값을 SleepStatus enum으로 변환
        // 💡 Java 비교: Enum.valueOf()와 유사하지만 optional 처리
        guard let status = SleepStatus(rawValue: entity.status) else {
            throw MappingError.invalidEnumValue("status: \(entity.status)")
        }

        return Bodii.SleepRecord(
            id: id,
            userId: userId,
            date: date,
            duration: entity.duration,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// 여러 SleepRecord를 한 번에 변환
    /// 📚 학습 포인트: Collection Transformation
    /// Swift의 map을 활용한 컬렉션 변환
    /// 💡 Java 비교: Stream.map()과 유사
    ///
    /// - Parameter entities: Core Data SleepRecord 배열
    /// - Returns: Domain SleepRecord 배열
    /// - Throws: MappingError - 변환 중 에러 발생 시
    func toDomain(_ entities: [SleepRecord]) throws -> [Bodii.SleepRecord] {
        return try entities.map { try toDomain($0) }
    }

    // MARK: - Domain → Core Data

    /// SleepRecord (Domain)를 SleepRecord (Core Data)로 변환
    /// 📚 학습 포인트: NSManagedObject Creation
    /// Core Data 엔티티를 생성하려면 NSManagedObjectContext가 필요
    /// 💡 Java 비교: EntityManager를 사용한 엔티티 생성과 유사
    ///
    /// - Parameters:
    ///   - domainEntity: Domain SleepRecord
    ///   - context: Core Data NSManagedObjectContext
    /// - Returns: Core Data SleepRecord
    func toEntity(_ domainEntity: Bodii.SleepRecord, context: NSManagedObjectContext) -> SleepRecord {
        // 📚 학습 포인트: NSManagedObject Initialization
        // Core Data 엔티티는 context와 함께 생성되어야 함
        // entity는 context가 관리하는 객체 설명 정보
        let entity = SleepRecord(context: context)

        // 📚 학습 포인트: Value Assignment
        // Domain entity의 값을 Core Data entity로 복사
        entity.id = domainEntity.id
        entity.userId = domainEntity.userId
        entity.date = domainEntity.date
        entity.duration = domainEntity.duration

        // 📚 학습 포인트: Enum → Int16 Conversion
        // SleepStatus enum을 Core Data의 Int16 값으로 변환
        // 💡 Java 비교: enum.ordinal()과 유사하지만 rawValue 사용
        entity.status = domainEntity.status.rawValue

        // 📚 학습 포인트: Timestamp Management
        // createdAt과 updatedAt을 Domain 값 그대로 사용
        entity.createdAt = domainEntity.createdAt
        entity.updatedAt = domainEntity.updatedAt

        // 📚 학습 포인트: Return Unsaved Entity
        // 여기서는 context.save()를 호출하지 않음
        // 저장은 Repository 레이어에서 담당 (단일 책임 원칙)
        return entity
    }

    /// 기존 SleepRecord 업데이트
    /// 📚 학습 포인트: Update vs Create
    /// 새로운 엔티티를 생성하지 않고 기존 엔티티를 업데이트
    /// 💡 Java 비교: JPA의 merge() 메서드와 유사
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data SleepRecord
    ///   - domainEntity: 새로운 값을 가진 Domain SleepRecord
    func updateEntity(_ entity: SleepRecord, from domainEntity: Bodii.SleepRecord) {
        // 📚 학습 포인트: Partial Update
        // ID와 userId, createdAt은 변경하지 않고 나머지 필드만 업데이트
        // 불변(immutable) 필드와 가변(mutable) 필드 구분

        entity.date = domainEntity.date
        entity.duration = domainEntity.duration
        entity.status = domainEntity.status.rawValue
        entity.updatedAt = domainEntity.updatedAt

        // 📚 학습 포인트: Audit Trail
        // updatedAt은 Domain 엔티티의 값을 사용
        // 또는 여기서 Date()로 갱신할 수도 있음
    }
}

// MARK: - Convenience Extensions

extension SleepRecordMapper {
    /// 📚 학습 포인트: Convenience Methods
    /// 자주 사용되는 패턴을 간편하게 호출할 수 있는 헬퍼 메서드

    /// Domain 엔티티로 새 Core Data 엔티티 생성 및 즉시 저장
    /// 📚 학습 포인트: Combined Operation
    /// 생성과 저장을 한 번에 처리하는 편의 메서드
    /// 💡 주의: 에러 처리를 위해 throws 사용
    ///
    /// - Parameters:
    ///   - domainEntity: Domain SleepRecord
    ///   - context: Core Data NSManagedObjectContext
    /// - Returns: 저장된 Core Data SleepRecord
    /// - Throws: Core Data 저장 에러
    func createAndSave(_ domainEntity: Bodii.SleepRecord, context: NSManagedObjectContext) throws -> SleepRecord {
        let entity = toEntity(domainEntity, context: context)

        // 📚 학습 포인트: Try Expression
        // context.save()가 throw할 수 있으므로 try 키워드 필요
        // 💡 Java 비교: checked exception 처리와 유사
        try context.save()

        return entity
    }

    /// Domain 엔티티로 기존 Core Data 엔티티 업데이트 및 즉시 저장
    /// 📚 학습 포인트: Update and Persist
    /// 업데이트와 저장을 한 번에 처리
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data SleepRecord
    ///   - domainEntity: 새로운 값을 가진 Domain SleepRecord
    ///   - context: Core Data NSManagedObjectContext
    /// - Throws: Core Data 저장 에러
    func updateAndSave(_ entity: SleepRecord, from domainEntity: Bodii.SleepRecord, context: NSManagedObjectContext) throws {
        updateEntity(entity, from: domainEntity)
        try context.save()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepRecordMapper의 특징
///
/// BodyRecordMapper와의 유사점 및 차이점:
/// 1. Enum 변환 처리
///    - SleepStatus enum을 Int16로 변환
///    - 잘못된 enum 값에 대한 에러 처리 필요
///    - MetabolismSnapshotMapper의 ActivityLevel 변환과 유사한 패턴
///
/// 2. 02:00 경계 로직
///    - date 필드는 02:00 기준으로 하루를 구분
///    - 변환 로직이 아닌 Use Case 레이어에서 처리
///    - Mapper는 단순히 값을 복사만 함
///
/// 3. updatedAt 필드 관리
///    - SleepRecord는 수정 가능한 엔티티
///    - updatedAt을 통해 수정 이력 추적
///    - BodyRecord는 createdAt만 있지만 SleepRecord는 둘 다 있음
///
/// 왜 별도의 Mapper가 필요한가?
/// - SleepRecord와 BodyRecord는 서로 다른 엔티티
/// - 각각 독립적인 라이프사이클을 가짐
/// - SleepRecord는 02:00 기준 날짜 로직으로 DailyLog와 연동
/// - 수면 추이 분석을 위해 별도로 fetch 가능
///
/// 사용 예시:
/// ```swift
/// // Core Data → Domain
/// let mapper = SleepRecordMapper()
/// let sleepRecord = try mapper.toDomain(entity)
///
/// // Domain → Core Data
/// let entity = mapper.toEntity(sleepRecord, context: context)
/// try context.save()
/// ```
///
/// 💡 실무 팁:
/// - Enum 변환 시 항상 실패 가능성을 고려
/// - 수면 시간은 Int32(분 단위)로 저장하여 정밀도 유지
/// - 변환 로직은 최대한 단순하게 유지 (복잡한 로직은 Use Case로)
/// - 날짜 경계 로직은 DateUtils와 Use Case에서 처리
///

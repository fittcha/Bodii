//
//  MetabolismSnapshotMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Mapper Pattern for Metabolism Data
// Core Data 엔티티와 Domain 엔티티 간의 변환을 담당하는 매퍼
// 💡 Java 비교: ModelMapper 또는 MapStruct와 유사한 역할

import Foundation
import CoreData

// MARK: - MetabolismSnapshotMapper

/// MetabolismSnapshot (Core Data) ↔ MetabolismData (Domain) 매퍼
/// 데이터 레이어와 도메인 레이어 간의 경계를 명확히 구분합니다.
/// 📚 학습 포인트: Clean Architecture - Data Layer
/// - Core Data의 NSManagedObject를 도메인 엔티티로 변환
/// - 도메인 레이어가 Core Data 의존성을 갖지 않도록 격리
/// - ActivityLevel enum 변환 처리 (Int16 ↔ ActivityLevel)
/// - 양방향 변환 지원 (toDomain, toEntity)
/// 💡 Java 비교: DTO ↔ Entity 변환 매퍼와 유사
struct MetabolismSnapshotMapper {

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

    /// MetabolismSnapshot (Core Data)를 MetabolismData (Domain)로 변환
    /// 📚 학습 포인트: Optional Handling & Enum Conversion
    /// Core Data의 optional 필드를 안전하게 처리하고 Int16을 ActivityLevel로 변환
    /// 💡 Java 비교: Optional.ofNullable()과 유사한 패턴
    ///
    /// - Parameter entity: Core Data MetabolismSnapshot 엔티티
    /// - Returns: Domain MetabolismData
    /// - Throws: MappingError - 필수 필드 누락 또는 enum 변환 실패 시
    func toDomain(_ entity: MetabolismSnapshot) throws -> MetabolismData {
        // 📚 학습 포인트: Guard Let Pattern
        // optional을 unwrap하고 실패 시 에러를 throw
        // 💡 Java 비교: Objects.requireNonNull()과 유사

        guard let id = entity.id else {
            throw MappingError.missingRequiredField("id")
        }

        guard let date = entity.date else {
            throw MappingError.missingRequiredField("date")
        }

        // 📚 학습 포인트: NSDecimalNumber → Decimal Conversion
        // Core Data의 NSDecimalNumber를 Swift의 Decimal로 변환
        let bmr = entity.bmr ?? Decimal(0)
        let tdee = entity.tdee ?? Decimal(0)
        let weight = entity.weight ?? Decimal(0)

        // 📚 학습 포인트: Field Name Mapping
        // Core Data에서는 bodyFatPct, Domain에서는 bodyFatPercent
        // 데이터베이스 네이밍과 도메인 네이밍을 분리할 수 있음
        let bodyFatPercent = entity.bodyFatPct ?? Decimal(0)

        // 📚 학습 포인트: Int16 → Enum Conversion
        // Core Data의 Int16 값을 ActivityLevel enum으로 변환
        // 💡 Java 비교: Enum.valueOf()와 유사하지만 optional 처리
        guard let activityLevel = ActivityLevel(rawValue: entity.activityLevel) else {
            throw MappingError.invalidEnumValue("activityLevel: \(entity.activityLevel)")
        }

        return MetabolismData(
            id: id,
            date: date,
            bmr: bmr,
            tdee: tdee,
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            activityLevel: activityLevel
        )
    }

    /// 여러 MetabolismSnapshot을 한 번에 변환
    /// 📚 학습 포인트: Collection Transformation
    /// Swift의 map을 활용한 컬렉션 변환
    /// 💡 Java 비교: Stream.map()과 유사
    ///
    /// - Parameter entities: Core Data MetabolismSnapshot 배열
    /// - Returns: Domain MetabolismData 배열
    /// - Throws: MappingError - 변환 중 에러 발생 시
    func toDomain(_ entities: [MetabolismSnapshot]) throws -> [MetabolismData] {
        return try entities.map { try toDomain($0) }
    }

    // MARK: - Domain → Core Data

    /// MetabolismData (Domain)를 MetabolismSnapshot (Core Data)로 변환
    /// 📚 학습 포인트: NSManagedObject Creation
    /// Core Data 엔티티를 생성하려면 NSManagedObjectContext가 필요
    /// 💡 Java 비교: EntityManager를 사용한 엔티티 생성과 유사
    ///
    /// - Parameters:
    ///   - domainEntity: Domain MetabolismData
    ///   - context: Core Data NSManagedObjectContext
    /// - Returns: Core Data MetabolismSnapshot
    func toEntity(_ domainEntity: MetabolismData, context: NSManagedObjectContext) -> MetabolismSnapshot {
        // 📚 학습 포인트: NSManagedObject Initialization
        // Core Data 엔티티는 context와 함께 생성되어야 함
        // entity는 context가 관리하는 객체 설명 정보
        let entity = MetabolismSnapshot(context: context)

        // 📚 학습 포인트: Value Assignment
        // Domain entity의 값을 Core Data entity로 복사
        entity.id = domainEntity.id
        entity.date = domainEntity.date
        entity.bmr = domainEntity.bmr
        entity.tdee = domainEntity.tdee
        entity.weight = domainEntity.weight

        // 📚 학습 포인트: Field Name Mapping
        // Domain의 bodyFatPercent를 Core Data의 bodyFatPct로 매핑
        entity.bodyFatPct = domainEntity.bodyFatPercent

        // 📚 학습 포인트: Enum → Int16 Conversion
        // ActivityLevel enum을 Core Data의 Int16 값으로 변환
        // 💡 Java 비교: enum.ordinal()과 유사하지만 rawValue 사용
        entity.activityLevel = domainEntity.activityLevel.rawValue

        // 📚 학습 포인트: Timestamp Management
        // createdAt은 생성 시점을 기록하는 감사(audit) 필드
        // Core Data에서만 사용되고 Domain에는 노출되지 않음
        entity.createdAt = Date()

        // 📚 학습 포인트: Return Unsaved Entity
        // 여기서는 context.save()를 호출하지 않음
        // 저장은 Repository 레이어에서 담당 (단일 책임 원칙)
        return entity
    }

    /// 기존 MetabolismSnapshot 업데이트
    /// 📚 학습 포인트: Update vs Create
    /// 새로운 엔티티를 생성하지 않고 기존 엔티티를 업데이트
    /// 💡 Java 비교: JPA의 merge() 메서드와 유사
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data MetabolismSnapshot
    ///   - domainEntity: 새로운 값을 가진 Domain MetabolismData
    func updateEntity(_ entity: MetabolismSnapshot, from domainEntity: MetabolismData) {
        // 📚 학습 포인트: Partial Update
        // ID와 createdAt은 변경하지 않고 나머지 필드만 업데이트
        // 불변(immutable) 필드와 가변(mutable) 필드 구분

        entity.date = domainEntity.date
        entity.bmr = domainEntity.bmr
        entity.tdee = domainEntity.tdee
        entity.weight = domainEntity.weight
        entity.bodyFatPct = domainEntity.bodyFatPercent
        entity.activityLevel = domainEntity.activityLevel.rawValue

        // 📚 학습 포인트: Audit Trail
        // updatedAt 같은 필드가 있다면 여기서 갱신
        // 현재 MetabolismSnapshot 모델에는 updatedAt이 없지만 향후 추가 가능
    }
}

// MARK: - Convenience Extensions

extension MetabolismSnapshotMapper {
    /// 📚 학습 포인트: Convenience Methods
    /// 자주 사용되는 패턴을 간편하게 호출할 수 있는 헬퍼 메서드

    /// Domain 엔티티로 새 Core Data 엔티티 생성 및 즉시 저장
    /// 📚 학습 포인트: Combined Operation
    /// 생성과 저장을 한 번에 처리하는 편의 메서드
    /// 💡 주의: 에러 처리를 위해 throws 사용
    ///
    /// - Parameters:
    ///   - domainEntity: Domain MetabolismData
    ///   - context: Core Data NSManagedObjectContext
    /// - Returns: 저장된 Core Data MetabolismSnapshot
    /// - Throws: Core Data 저장 에러
    func createAndSave(_ domainEntity: MetabolismData, context: NSManagedObjectContext) throws -> MetabolismSnapshot {
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
    ///   - entity: 업데이트할 Core Data MetabolismSnapshot
    ///   - domainEntity: 새로운 값을 가진 Domain MetabolismData
    ///   - context: Core Data NSManagedObjectContext
    /// - Throws: Core Data 저장 에러
    func updateAndSave(_ entity: MetabolismSnapshot, from domainEntity: MetabolismData, context: NSManagedObjectContext) throws {
        updateEntity(entity, from: domainEntity)
        try context.save()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: MetabolismSnapshotMapper의 특징
///
/// BodyRecordMapper와의 차이점:
/// 1. Enum 변환 처리
///    - ActivityLevel enum을 Int16로 변환
///    - 잘못된 enum 값에 대한 에러 처리 필요
///
/// 2. 필드 이름 매핑
///    - Core Data: bodyFatPct
///    - Domain: bodyFatPercent
///    - 데이터베이스와 도메인의 네이밍 컨벤션을 분리
///
/// 3. 정밀도 보존
///    - BMR과 TDEE는 Decimal 타입으로 정확한 계산 보장
///    - Double을 사용하면 부동소수점 오차 발생 가능
///
/// 왜 별도의 Mapper가 필요한가?
/// - MetabolismSnapshot과 BodyRecord는 서로 다른 엔티티
/// - 각각 독립적인 라이프사이클을 가짐
/// - MetabolismSnapshot은 BodyRecord와 함께 생성되지만 독립적으로 조회 가능
/// - 시계열 대사율 분석을 위해 별도로 fetch 가능
///
/// 사용 예시:
/// ```swift
/// // Core Data → Domain
/// let mapper = MetabolismSnapshotMapper()
/// let metabolismData = try mapper.toDomain(snapshot)
///
/// // Domain → Core Data
/// let snapshot = mapper.toEntity(metabolismData, context: context)
/// try context.save()
/// ```
///
/// 💡 실무 팁:
/// - Enum 변환 시 항상 실패 가능성을 고려
/// - 필드 이름이 다를 때 주석으로 매핑 관계 명시
/// - 정밀도가 중요한 계산에는 Decimal 사용
/// - 변환 로직은 최대한 단순하게 유지 (복잡한 로직은 Use Case로)
///

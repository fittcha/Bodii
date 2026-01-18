//
//  GoalMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Mapper Pattern
// Core Data 엔티티와 Domain 엔티티 간의 변환을 담당하는 매퍼
// 💡 Java 비교: ModelMapper 또는 MapStruct와 유사한 역할

import Foundation
import CoreData

// MARK: - GoalMapper

/// Goal (Core Data) ↔ Goal (Domain) 매퍼
/// 데이터 레이어와 도메인 레이어 간의 경계를 명확히 구분합니다.
/// 📚 학습 포인트: Clean Architecture - Data Layer
/// - Core Data의 NSManagedObject를 도메인 엔티티로 변환
/// - 도메인 레이어가 Core Data 의존성을 갖지 않도록 격리
/// - 양방향 변환 지원 (toDomain, toEntity)
/// 💡 Java 비교: DTO ↔ Entity 변환 매퍼와 유사
struct GoalMapper {

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

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .missingRequiredField(let field):
                return "필수 필드가 누락되었습니다: \(field)"
            case .invalidDataType(let field):
                return "잘못된 데이터 타입입니다: \(field)"
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

    /// Goal (Core Data)를 Goal (Domain)로 변환
    /// 📚 학습 포인트: Optional Handling
    /// Core Data의 optional 필드를 안전하게 처리
    /// 💡 Java 비교: Optional.ofNullable()과 유사한 패턴
    ///
    /// - Parameter entity: Core Data Goal 엔티티
    /// - Returns: Domain Goal
    /// - Throws: MappingError - 필수 필드 누락 시
    func toDomain(_ entity: NSManagedObject) throws -> Bodii.Goal {
        // 📚 학습 포인트: Guard Let Pattern
        // optional을 unwrap하고 실패 시 에러를 throw
        // 💡 Java 비교: Objects.requireNonNull()과 유사

        guard let id = entity.value(forKey: "id") as? UUID else {
            throw MappingError.missingRequiredField("id")
        }

        // 📚 학습 포인트: User Relationship Handling
        // User 관계에서 userId 추출
        guard let user = entity.value(forKey: "user") as? NSManagedObject,
              let userId = user.value(forKey: "id") as? UUID else {
            throw MappingError.missingRequiredField("userId")
        }

        guard let createdAt = entity.value(forKey: "createdAt") as? Date else {
            throw MappingError.missingRequiredField("createdAt")
        }

        guard let updatedAt = entity.value(forKey: "updatedAt") as? Date else {
            throw MappingError.missingRequiredField("updatedAt")
        }

        // 📚 학습 포인트: Enum Conversion
        // Core Data의 Int16을 GoalType enum으로 변환
        let goalTypeValue = entity.value(forKey: "goalType") as? Int16 ?? 0
        let goalType = GoalType(rawValue: goalTypeValue) ?? .lose

        // 📚 학습 포인트: Optional Decimal Fields
        // Core Data의 NSDecimalNumber를 Swift의 Decimal로 변환
        let targetWeight = entity.value(forKey: "targetWeight") as? Decimal
        let targetBodyFatPct = entity.value(forKey: "targetBodyFatPct") as? Decimal
        let targetMuscleMass = entity.value(forKey: "targetMuscleMass") as? Decimal

        let weeklyWeightRate = entity.value(forKey: "weeklyWeightRate") as? Decimal
        let weeklyFatPctRate = entity.value(forKey: "weeklyFatPctRate") as? Decimal
        let weeklyMuscleRate = entity.value(forKey: "weeklyMuscleRate") as? Decimal

        let startWeight = entity.value(forKey: "startWeight") as? Decimal
        let startBodyFatPct = entity.value(forKey: "startBodyFatPct") as? Decimal
        let startMuscleMass = entity.value(forKey: "startMuscleMass") as? Decimal
        let startBMR = entity.value(forKey: "startBMR") as? Decimal
        let startTDEE = entity.value(forKey: "startTDEE") as? Decimal

        // 📚 학습 포인트: Optional Int32 Handling
        // dailyCalorieTarget이 0이면 nil로 처리
        let dailyCalorieTargetValue = entity.value(forKey: "dailyCalorieTarget") as? Int32 ?? 0
        let dailyCalorieTarget = dailyCalorieTargetValue == 0 ? nil : dailyCalorieTargetValue

        // 📚 학습 포인트: Boolean with Default
        // isActive는 non-optional이므로 기본값 제공
        let isActive = entity.value(forKey: "isActive") as? Bool ?? true

        return Bodii.Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: targetWeight,
            targetBodyFatPct: targetBodyFatPct,
            targetMuscleMass: targetMuscleMass,
            weeklyWeightRate: weeklyWeightRate,
            weeklyFatPctRate: weeklyFatPctRate,
            weeklyMuscleRate: weeklyMuscleRate,
            startWeight: startWeight,
            startBodyFatPct: startBodyFatPct,
            startMuscleMass: startMuscleMass,
            startBMR: startBMR,
            startTDEE: startTDEE,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// 여러 Goal을 한 번에 변환
    /// 📚 학습 포인트: Collection Transformation
    /// Swift의 map을 활용한 컬렉션 변환
    /// 💡 Java 비교: Stream.map()과 유사
    ///
    /// - Parameter entities: Core Data Goal 배열
    /// - Returns: Domain Goal 배열
    /// - Throws: MappingError - 변환 중 에러 발생 시
    func toDomain(_ entities: [NSManagedObject]) throws -> [Bodii.Goal] {
        return try entities.map { try toDomain($0) }
    }

    // MARK: - Domain → Core Data

    /// Goal (Domain)를 Goal (Core Data)로 변환
    /// 📚 학습 포인트: NSManagedObject Creation
    /// Core Data 엔티티를 생성하려면 NSManagedObjectContext가 필요
    /// 💡 Java 비교: EntityManager를 사용한 엔티티 생성과 유사
    ///
    /// - Parameters:
    ///   - domainEntity: Domain Goal
    ///   - context: Core Data NSManagedObjectContext
    /// - Returns: Core Data Goal
    func toEntity(_ domainEntity: Bodii.Goal, context: NSManagedObjectContext) -> NSManagedObject {
        // 📚 학습 포인트: NSManagedObject Initialization
        // Core Data 엔티티는 context와 함께 생성되어야 함
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Goal", into: context)

        // 📚 학습 포인트: Value Assignment
        // Domain entity의 값을 Core Data entity로 복사
        entity.setValue(domainEntity.id, forKey: "id")
        entity.setValue(domainEntity.goalType.rawValue, forKey: "goalType")
        entity.setValue(domainEntity.targetWeight as NSDecimalNumber?, forKey: "targetWeight")
        entity.setValue(domainEntity.targetBodyFatPct as NSDecimalNumber?, forKey: "targetBodyFatPct")
        entity.setValue(domainEntity.targetMuscleMass as NSDecimalNumber?, forKey: "targetMuscleMass")
        entity.setValue(domainEntity.weeklyWeightRate as NSDecimalNumber?, forKey: "weeklyWeightRate")
        entity.setValue(domainEntity.weeklyFatPctRate as NSDecimalNumber?, forKey: "weeklyFatPctRate")
        entity.setValue(domainEntity.weeklyMuscleRate as NSDecimalNumber?, forKey: "weeklyMuscleRate")
        entity.setValue(domainEntity.startWeight as NSDecimalNumber?, forKey: "startWeight")
        entity.setValue(domainEntity.startBodyFatPct as NSDecimalNumber?, forKey: "startBodyFatPct")
        entity.setValue(domainEntity.startMuscleMass as NSDecimalNumber?, forKey: "startMuscleMass")
        entity.setValue(domainEntity.startBMR as NSDecimalNumber?, forKey: "startBMR")
        entity.setValue(domainEntity.startTDEE as NSDecimalNumber?, forKey: "startTDEE")
        entity.setValue(domainEntity.dailyCalorieTarget ?? 0, forKey: "dailyCalorieTarget")
        entity.setValue(domainEntity.isActive, forKey: "isActive")
        entity.setValue(domainEntity.createdAt, forKey: "createdAt")
        entity.setValue(domainEntity.updatedAt, forKey: "updatedAt")

        // 📚 학습 포인트: User Relationship
        // userId로 User 엔티티를 조회하여 관계 설정
        // Note: 실제 구현에서는 외부에서 User 관계를 설정하는 것이 일반적
        // 여기서는 toEntity가 순수하게 변환만 담당하므로 User 조회는 하지 않음

        // 📚 학습 포인트: Return Unsaved Entity
        // 여기서는 context.save()를 호출하지 않음
        // 저장은 Repository 레이어에서 담당 (단일 책임 원칙)
        return entity
    }

    /// 기존 Goal 업데이트
    /// 📚 학습 포인트: Update vs Create
    /// 새로운 엔티티를 생성하지 않고 기존 엔티티를 업데이트
    /// 💡 Java 비교: JPA의 merge() 메서드와 유사
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data Goal
    ///   - domainEntity: 새로운 값을 가진 Domain Goal
    func updateEntity(_ entity: NSManagedObject, from domainEntity: Bodii.Goal) {
        // 📚 학습 포인트: Partial Update
        // ID와 createdAt은 변경하지 않고 나머지 필드만 업데이트
        // 불변(immutable) 필드와 가변(mutable) 필드 구분

        entity.setValue(domainEntity.goalType.rawValue, forKey: "goalType")
        entity.setValue(domainEntity.targetWeight as NSDecimalNumber?, forKey: "targetWeight")
        entity.setValue(domainEntity.targetBodyFatPct as NSDecimalNumber?, forKey: "targetBodyFatPct")
        entity.setValue(domainEntity.targetMuscleMass as NSDecimalNumber?, forKey: "targetMuscleMass")
        entity.setValue(domainEntity.weeklyWeightRate as NSDecimalNumber?, forKey: "weeklyWeightRate")
        entity.setValue(domainEntity.weeklyFatPctRate as NSDecimalNumber?, forKey: "weeklyFatPctRate")
        entity.setValue(domainEntity.weeklyMuscleRate as NSDecimalNumber?, forKey: "weeklyMuscleRate")
        entity.setValue(domainEntity.startWeight as NSDecimalNumber?, forKey: "startWeight")
        entity.setValue(domainEntity.startBodyFatPct as NSDecimalNumber?, forKey: "startBodyFatPct")
        entity.setValue(domainEntity.startMuscleMass as NSDecimalNumber?, forKey: "startMuscleMass")
        entity.setValue(domainEntity.startBMR as NSDecimalNumber?, forKey: "startBMR")
        entity.setValue(domainEntity.startTDEE as NSDecimalNumber?, forKey: "startTDEE")
        entity.setValue(domainEntity.dailyCalorieTarget ?? 0, forKey: "dailyCalorieTarget")
        entity.setValue(domainEntity.isActive, forKey: "isActive")
        entity.setValue(domainEntity.updatedAt, forKey: "updatedAt")

        // 📚 학습 포인트: Audit Trail
        // updatedAt 필드는 이미 domainEntity에서 설정되어 있음
        // 현재 Goal 엔티티는 updatedAt을 가지고 있음
    }
}

// MARK: - Convenience Extensions

extension GoalMapper {
    /// 📚 학습 포인트: Convenience Methods
    /// 자주 사용되는 패턴을 간편하게 호출할 수 있는 헬퍼 메서드

    /// Domain 엔티티로 새 Core Data 엔티티 생성 및 즉시 저장
    /// 📚 학습 포인트: Combined Operation
    /// 생성과 저장을 한 번에 처리하는 편의 메서드
    /// 💡 주의: 에러 처리를 위해 throws 사용
    ///
    /// - Parameters:
    ///   - domainEntity: Domain Goal
    ///   - context: Core Data NSManagedObjectContext
    /// - Returns: 저장된 Core Data Goal
    /// - Throws: Core Data 저장 에러
    func createAndSave(_ domainEntity: Bodii.Goal, context: NSManagedObjectContext) throws -> NSManagedObject {
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
    ///   - entity: 업데이트할 Core Data Goal
    ///   - domainEntity: 새로운 값을 가진 Domain Goal
    ///   - context: Core Data NSManagedObjectContext
    /// - Throws: Core Data 저장 에러
    func updateAndSave(_ entity: NSManagedObject, from domainEntity: Bodii.Goal, context: NSManagedObjectContext) throws {
        updateEntity(entity, from: domainEntity)
        try context.save()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Mapper Pattern 이해
///
/// Mapper의 역할:
/// - 데이터 레이어(Core Data)와 도메인 레이어(Business Logic)의 경계 정의
/// - 각 레이어가 서로의 구현 세부사항을 알지 못하도록 격리
/// - 테스트 가능성 향상 (도메인 로직을 Core Data 없이 테스트 가능)
///
/// 왜 Mapper가 필요한가?
/// 1. 관심사의 분리 (Separation of Concerns)
///    - Domain은 비즈니스 로직에만 집중
///    - Data Layer는 영속성(persistence)에만 집중
///
/// 2. 독립성 (Independence)
///    - Core Data를 다른 DB로 변경해도 Domain은 영향 없음
///    - Domain 엔티티 변경 시 Core Data 모델은 영향 최소화
///
/// 3. 테스트 용이성 (Testability)
///    - Domain 로직을 테스트할 때 Core Data mock 불필요
///    - 순수한 Swift 객체로 테스트 가능
///
/// 4. 타입 안전성 (Type Safety)
///    - Core Data의 optional/non-optional 불일치 해결
///    - NSDecimalNumber ↔ Decimal 변환 일관성
///
/// Clean Architecture의 레이어:
/// ```
/// Presentation Layer (UI)
///        ↓
/// Domain Layer (Business Logic) ← Goal (Domain)
///        ↓
/// Data Layer (Persistence) ← Goal (Core Data)
///        ↓
/// Mapper: 이 레이어 간의 번역기 역할
/// ```
///
/// 💡 실무 팁:
/// - Mapper는 stateless해야 함 (상태를 갖지 않음)
/// - 단방향보다는 양방향 변환 지원이 유용
/// - 복잡한 로직은 Mapper가 아닌 Use Case에 위치
/// - 변환 실패 시 명확한 에러 메시지 제공
/// - User 관계 처리는 DataSource에서 수행 (Mapper는 순수하게 변환만 담당)
///

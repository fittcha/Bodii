//
//  FoodEntityMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Bidirectional Data Mapper Pattern
// Domain Entity와 Core Data Entity 간의 양방향 변환을 담당하는 매퍼
// 💡 Java 비교: JPA Entity ↔ Domain Model 변환 매퍼와 유사

import Foundation
import CoreData

/// Food 도메인 엔티티와 FoodEntity Core Data 객체 간의 양방향 매퍼
///
/// 📚 학습 포인트: Clean Architecture Layer Separation
/// - Domain Layer: Food (도메인 엔티티, 비즈니스 로직)
/// - Infrastructure Layer: FoodEntity (Core Data, 영속성)
/// - 각 레이어는 자신의 모델을 가지며, 매퍼가 변환을 담당
/// 💡 Java 비교: Domain Model과 JPA Entity를 분리하는 패턴
///
/// **변환 방향:**
/// - toDomain: FoodEntity (Core Data) → Food (Domain)
/// - toEntity: Food (Domain) → FoodEntity (Core Data)
///
/// **사용 예시:**
/// ```swift
/// let mapper = FoodEntityMapper()
///
/// // Core Data → Domain 변환 (캐시에서 읽어올 때)
/// let cachedFood = try mapper.toDomain(from: foodEntity)
///
/// // Domain → Core Data 변환 (캐시에 저장할 때)
/// let entityToCache = try mapper.toEntity(from: food, context: context)
/// ```
struct FoodEntityMapper {

    // MARK: - Core Data to Domain Mapping

    /// FoodEntity Core Data 객체를 Food 도메인 엔티티로 변환
    ///
    /// 📚 학습 포인트: Infrastructure → Domain 변환
    /// 영속성 계층의 데이터를 도메인 계층의 모델로 변환
    /// 💡 Java 비교: JPA Entity → Domain Model 변환
    ///
    /// - Parameter entity: Core Data FoodEntity 객체
    ///
    /// - Returns: Food 도메인 엔티티
    ///
    /// - Throws: `FoodEntityError` - 필수 필드 누락 또는 변환 실패
    ///
    /// - Example:
    /// ```swift
    /// let fetchRequest = Food.fetchRecentFoods(limit: 20)
    /// let foodEntities = try context.fetch(fetchRequest)
    ///
    /// let mapper = FoodEntityMapper()
    /// let foods = try foodEntities.map { try mapper.toDomain(from: $0) }
    /// ```
    func toDomain(from entity: Food) throws -> Bodii.Food {
        // 📚 학습 포인트: Delegation to Extension Method
        // 실제 변환 로직은 FoodEntity+CoreData.swift의 toDomainEntity()에 위임
        // 매퍼는 일관된 인터페이스만 제공
        // 💡 Java 비교: Adapter Pattern - 기존 메서드를 표준 인터페이스로 감싸기
        return try entity.toDomainEntity()
    }

    // MARK: - Domain to Core Data Mapping

    /// Food 도메인 엔티티를 FoodEntity Core Data 객체로 변환
    ///
    /// 📚 학습 포인트: Domain → Infrastructure 변환
    /// 도메인 계층의 모델을 영속성 계층의 데이터로 변환
    /// 💡 Java 비교: Domain Model → JPA Entity 변환
    ///
    /// - Parameters:
    ///   - domainFood: Food 도메인 엔티티
    ///   - context: NSManagedObjectContext (Core Data context)
    ///
    /// - Returns: 생성된 FoodEntity Core Data 객체
    ///
    /// - Example:
    /// ```swift
    /// let food = Food(id: UUID(), name: "김치찌개", ...)
    /// let mapper = FoodEntityMapper()
    ///
    /// // 도메인 엔티티를 Core Data로 변환하여 캐시에 저장
    /// let entity = try mapper.toEntity(from: food, context: context)
    /// try context.save()
    /// ```
    @discardableResult
    func toEntity(from domainFood: Bodii.Food, context: NSManagedObjectContext) -> Food {
        // 📚 학습 포인트: Factory Method Delegation
        // FoodEntity+CoreData.swift의 from() 팩토리 메서드에 위임
        // 💡 Java 비교: EntityManager.merge()와 유사한 팩토리 패턴
        return Food.from(domainFood: domainFood, context: context)
    }

    /// Food 도메인 엔티티로 기존 FoodEntity를 업데이트
    ///
    /// 📚 학습 포인트: Update vs Create
    /// 새로 생성하지 않고 기존 엔티티의 값만 업데이트
    /// Core Data의 변경 추적 기능을 활용하여 효율적인 업데이트
    /// 💡 Java 비교: JPA의 merge() 또는 setter 호출과 유사
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 FoodEntity Core Data 객체
    ///   - domainFood: 새로운 값을 가진 Food 도메인 엔티티
    ///
    /// - Example:
    /// ```swift
    /// let existingEntity = // ... fetch from Core Data
    /// let updatedFood = Food(id: existingEntity.id, name: "Updated Name", ...)
    ///
    /// let mapper = FoodEntityMapper()
    /// mapper.update(entity: existingEntity, from: updatedFood)
    /// try context.save()
    /// ```
    func update(entity: Food, from domainFood: Bodii.Food) {
        // 📚 학습 포인트: Update Method Delegation
        // FoodEntity+CoreData.swift의 update() 메서드에 위임
        // 💡 Java 비교: Entity의 setter 메서드 호출과 유사
        entity.update(from: domainFood)
    }

    // MARK: - Batch Mapping Operations

    /// 여러 FoodEntity Core Data 객체를 도메인 엔티티 배열로 변환
    ///
    /// 📚 학습 포인트: Batch Processing with Error Handling
    /// 대량 데이터 변환 시 일부 변환 실패해도 성공한 항목들은 반환
    /// 💡 Java 비교: Stream.map().filter() 패턴과 유사
    ///
    /// - Parameter entities: FoodEntity Core Data 객체 배열
    ///
    /// - Returns: 성공적으로 변환된 Food 도메인 엔티티 배열
    ///
    /// - Note: 변환 실패한 항목은 자동으로 제외됨 (try? 사용)
    ///
    /// - Example:
    /// ```swift
    /// let fetchRequest = Food.fetchRecentFoods(limit: 50)
    /// let foodEntities = try context.fetch(fetchRequest)
    ///
    /// let mapper = FoodEntityMapper()
    /// let foods = mapper.toDomainArray(from: foodEntities)
    /// // 일부 엔티티가 잘못되어도 유효한 Food만 반환됨
    /// ```
    func toDomainArray(from entities: [Food]) -> [Bodii.Food] {
        // 📚 학습 포인트: compactMap for Error Handling
        // try?와 compactMap을 사용하여 변환 실패 항목 자동 제거
        // 💡 Java 비교: stream().map().filter(Objects::nonNull) 패턴
        return entities.compactMap { entity in
            try? toDomain(from: entity)
        }
    }

    /// 여러 Food 도메인 엔티티를 FoodEntity Core Data 객체 배열로 변환
    ///
    /// 📚 학습 포인트: Batch Insert Pattern
    /// 대량 데이터 저장 시 성능 최적화를 위한 일괄 변환
    /// 💡 Java 비교: JPA의 batch insert와 유사
    ///
    /// - Parameters:
    ///   - domainFoods: Food 도메인 엔티티 배열
    ///   - context: NSManagedObjectContext
    ///
    /// - Returns: 생성된 FoodEntity Core Data 객체 배열
    ///
    /// - Example:
    /// ```swift
    /// let apiResults: [Food] = // ... API 검색 결과
    ///
    /// let mapper = FoodEntityMapper()
    /// let entities = mapper.toEntityArray(from: apiResults, context: context)
    /// try context.save() // 일괄 저장
    /// ```
    func toEntityArray(from domainFoods: [Bodii.Food], context: NSManagedObjectContext) -> [Food] {
        // 📚 학습 포인트: Batch Creation with Factory Method
        // FoodEntity+CoreData.swift의 batchCreate() 메서드에 위임
        // 💡 Java 비교: EntityManager.persist()를 반복 호출하는 것과 유사
        return Food.batchCreate(from: domainFoods, context: context)
    }

    // MARK: - Upsert Operations

    /// 중복 제거 후 일괄 저장 (Upsert)
    ///
    /// 📚 학습 포인트: Upsert (Update or Insert) Pattern
    /// API 코드를 기준으로 중복을 확인하고, 기존 데이터는 업데이트, 새 데이터는 삽입
    /// 캐시 중복을 방지하여 데이터 일관성 유지
    /// 💡 Java 비교: JPA의 merge() 또는 ON DUPLICATE KEY UPDATE와 유사
    ///
    /// - Parameters:
    ///   - domainFoods: Food 도메인 엔티티 배열
    ///   - context: NSManagedObjectContext
    ///
    /// - Returns: 새로 삽입된 음식 개수 (업데이트된 것은 제외)
    ///
    /// - Throws: Core Data 저장 실패 시 오류 발생
    ///
    /// - Example:
    /// ```swift
    /// let searchResults: [Food] = // ... API 검색 결과 (일부는 이미 캐시됨)
    ///
    /// let mapper = FoodEntityMapper()
    /// let insertedCount = try mapper.saveUnique(from: searchResults, context: context)
    /// print("새로 저장된 음식: \(insertedCount)개")
    /// ```
    func saveUnique(from domainFoods: [Bodii.Food], context: NSManagedObjectContext) throws -> Int {
        // 📚 학습 포인트: Deduplication Strategy
        // apiCode를 기준으로 중복 체크하여 캐시 중복 방지
        // FoodEntity+CoreData.swift의 saveUnique() 메서드에 위임
        // 💡 Java 비교: JPA의 findByApiCode() + merge() 패턴
        return try Food.saveUnique(from: domainFoods, context: context)
    }
}

// MARK: - Convenience Methods

extension FoodEntityMapper {

    /// 단일 도메인 엔티티를 Core Data로 저장 (Upsert)
    ///
    /// 📚 학습 포인트: Single Item Upsert Convenience
    /// 배열이 아닌 단일 항목 저장을 위한 편의 메서드
    /// 💡 Java 비교: Repository의 save() 메서드와 유사
    ///
    /// - Parameters:
    ///   - domainFood: Food 도메인 엔티티
    ///   - context: NSManagedObjectContext
    ///
    /// - Returns: 새로 삽입되었으면 true, 업데이트되었으면 false
    ///
    /// - Throws: Core Data 저장 실패 시 오류 발생
    ///
    /// - Example:
    /// ```swift
    /// let food = Food(id: UUID(), name: "김치찌개", ...)
    /// let mapper = FoodEntityMapper()
    ///
    /// let wasInserted = try mapper.saveUnique(domainFood: food, context: context)
    /// if wasInserted {
    ///     print("새로운 음식이 캐시에 추가되었습니다")
    /// } else {
    ///     print("기존 음식이 업데이트되었습니다")
    /// }
    /// ```
    @discardableResult
    func saveUnique(domainFood: Bodii.Food, context: NSManagedObjectContext) throws -> Bool {
        let insertedCount = try saveUnique(from: [domainFood], context: context)
        return insertedCount > 0
    }

    /// 도메인 엔티티를 Core Data로 저장하고 context를 자동으로 저장
    ///
    /// 📚 학습 포인트: Auto-save Convenience
    /// toEntity() + context.save()를 한 번에 수행하는 편의 메서드
    /// 💡 Java 비교: @Transactional 메서드와 유사한 효과
    ///
    /// - Parameters:
    ///   - domainFood: Food 도메인 엔티티
    ///   - context: NSManagedObjectContext
    ///
    /// - Returns: 저장된 FoodEntity Core Data 객체
    ///
    /// - Throws: Core Data 저장 실패 시 오류 발생
    ///
    /// - Example:
    /// ```swift
    /// let food = Food(id: UUID(), name: "김치찌개", ...)
    /// let mapper = FoodEntityMapper()
    ///
    /// // toEntity() + context.save()를 한 번에 수행
    /// let savedEntity = try mapper.toEntityAndSave(from: food, context: context)
    /// ```
    @discardableResult
    func toEntityAndSave(from domainFood: Bodii.Food, context: NSManagedObjectContext) throws -> Food {
        let entity = toEntity(from: domainFood, context: context)
        try context.save()
        return entity
    }
}

// MARK: - Usage Documentation

/// 📚 학습 포인트: FoodEntityMapper 사용 가이드
///
/// **사용 시나리오:**
///
/// 1. **캐시에서 읽어오기 (Core Data → Domain):**
///    ```swift
///    let mapper = FoodEntityMapper()
///    let fetchRequest = Food.fetchRecentFoods(limit: 20)
///    let foodEntities = try context.fetch(fetchRequest)
///    let foods = mapper.toDomainArray(from: foodEntities)
///    ```
///
/// 2. **API 결과를 캐시에 저장하기 (Domain → Core Data):**
///    ```swift
///    let apiResults: [Food] = // ... from API
///    let mapper = FoodEntityMapper()
///
///    // 중복 제거하며 저장 (upsert)
///    let insertedCount = try mapper.saveUnique(from: apiResults, context: context)
///    try context.save()
///    ```
///
/// 3. **단일 음식 저장:**
///    ```swift
///    let food = Food(id: UUID(), name: "김치찌개", ...)
///    let mapper = FoodEntityMapper()
///
///    // 저장 + context.save() 자동 수행
///    let entity = try mapper.toEntityAndSave(from: food, context: context)
///    ```
///
/// 4. **기존 엔티티 업데이트:**
///    ```swift
///    let existingEntity = // ... fetch from Core Data
///    let updatedFood = Food(id: existingEntity.id, name: "New Name", ...)
///
///    let mapper = FoodEntityMapper()
///    mapper.update(entity: existingEntity, from: updatedFood)
///    try context.save()
///    ```
///
/// **아키텍처 원칙:**
/// - Repository 계층에서만 이 매퍼를 사용
/// - ViewModel이나 View에서는 직접 사용하지 않음
/// - Domain 엔티티(Food)만 상위 계층으로 노출
/// - Core Data 엔티티(FoodEntity)는 Data 계층 내부에 숨김
///
/// 💡 Java 비교:
/// - Repository에서 JPA Entity를 Domain Model로 변환하는 것과 동일한 패턴
/// - Service 계층 이상에서는 Domain Model만 사용

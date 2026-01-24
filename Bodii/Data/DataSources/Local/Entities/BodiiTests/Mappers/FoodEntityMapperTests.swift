//
//  FoodEntityMapperTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
import CoreData
@testable import Bodii

/// Unit tests for FoodEntityMapper bidirectional mapping
///
/// FoodEntityMapper의 양방향 매핑 단위 테스트 (Food ↔ FoodEntity)
final class FoodEntityMapperTests: XCTestCase {

    // MARK: - Properties

    var mapper: FoodEntityMapper!
    var context: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mapper = FoodEntityMapper()

        // Create in-memory Core Data context for testing
        let persistenceController = PersistenceController.preview
        context = persistenceController.container.viewContext
    }

    override func tearDown() {
        mapper = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Domain to Core Data Mapping Tests

    /// Test: Food domain entity maps to FoodEntity Core Data object successfully
    ///
    /// 테스트: Food 도메인 엔티티가 FoodEntity Core Data 객체로 성공적으로 변환됨
    func testToEntity_ValidFood_ReturnsFoodEntity() {
        // Given: Valid Food domain entity
        let food = Bodii.Food(
            id: UUID(),
            name: "현미밥",
            calories: 330,
            carbohydrates: Decimal(73.4),
            protein: Decimal(6.8),
            fat: Decimal(2.5),
            sodium: Decimal(5),
            fiber: Decimal(3.0),
            sugar: Decimal(0.5),
            servingSize: Decimal(210),
            servingUnit: "1공기",
            source: .governmentAPI,
            apiCode: "D000001",
            createdByUserId: nil,
            createdAt: Date()
        )

        // When: Mapping to Core Data entity
        let entity = mapper.toEntity(from: food, context: context)

        // Then: Should map all fields correctly
        XCTAssertEqual(entity.id, food.id, "ID should match")
        XCTAssertEqual(entity.name, "현미밥", "Name should match")
        XCTAssertEqual(entity.calories, 330, "Calories should match")
        XCTAssertEqual(entity.source, Int16(FoodSource.governmentAPI.rawValue), "Source should be governmentAPI")
        XCTAssertEqual(entity.apiCode, "D000001", "API code should match")
    }

    /// Test: Batch mapping with valid domain foods
    ///
    /// 테스트: 유효한 도메인 엔티티의 배치 매핑
    func testToEntityArray_ValidFoods_ReturnsAllEntities() {
        // Given: Array of valid Food domain entities
        let foods = [
            createSampleFood(apiCode: "D000001", name: "현미밥", calories: 330),
            createSampleFood(apiCode: "D000002", name: "김치찌개", calories: 150),
            createSampleFood(apiCode: "D000003", name: "된장찌개", calories: 120)
        ]

        // When: Batch mapping to Core Data entities
        let entities = mapper.toEntityArray(from: foods, context: context)

        // Then: All foods should be mapped
        XCTAssertEqual(entities.count, 3, "Should map all 3 foods")
        XCTAssertEqual(entities[0].name, "현미밥", "First entity name should match")
        XCTAssertEqual(entities[1].name, "김치찌개", "Second entity name should match")
        XCTAssertEqual(entities[2].name, "된장찌개", "Third entity name should match")
    }

    // MARK: - Upsert Tests

    /// Test: saveUnique with new foods (inserts all)
    ///
    /// 테스트: 새로운 음식들의 saveUnique (모두 삽입됨)
    func testSaveUnique_AllNewFoods_InsertsAll() throws {
        // Given: Array of new foods
        let foods = [
            createSampleFood(apiCode: "D0001", name: "Food 1"),
            createSampleFood(apiCode: "D0002", name: "Food 2"),
            createSampleFood(apiCode: "D0003", name: "Food 3")
        ]

        // When: Saving unique foods
        let insertedCount = try mapper.saveUnique(from: foods, context: context)

        // Then: All should be inserted
        XCTAssertEqual(insertedCount, 3, "Should insert all 3 new foods")
    }

    /// Test: Saving duplicate foods (upserts instead of duplicating)
    ///
    /// 테스트: 중복 음식 저장 (중복 대신 업데이트)
    func testSaveUnique_DuplicateFoods_UpdatesInsteadOfDuplicating() throws {
        // Given: Initial food saved to Core Data
        let originalFood = createSampleFood(apiCode: "D0001", name: "Original Name")
        _ = try mapper.saveUnique(from: [originalFood], context: context)

        // When: Saving updated food with same apiCode
        let updatedFood = createSampleFood(apiCode: "D0001", name: "Updated Name")
        let insertedCount = try mapper.saveUnique(from: [updatedFood], context: context)

        // Then: Should update instead of insert (insertedCount = 0)
        XCTAssertEqual(insertedCount, 0, "Should update existing food, not insert new")

        // Verify updated name
        let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "apiCode == %@", "D0001")
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1, "Should have exactly 1 food with apiCode D0001")
        XCTAssertEqual(results.first?.name, "Updated Name", "Name should be updated")
    }

    /// Test: Saving mix of new and duplicate foods
    ///
    /// 테스트: 새 음식과 중복 음식 혼합 저장
    func testSaveUnique_MixOfNewAndDuplicate_HandlesCorrectly() throws {
        // Given: Initial foods saved to Core Data
        let existingFoods = [
            createSampleFood(apiCode: "D0001", name: "Food 1"),
            createSampleFood(apiCode: "D0002", name: "Food 2")
        ]
        _ = try mapper.saveUnique(from: existingFoods, context: context)

        // When: Saving mix of new and duplicate foods
        let mixedFoods = [
            createSampleFood(apiCode: "D0001", name: "Food 1 Updated"), // Duplicate
            createSampleFood(apiCode: "D0003", name: "Food 3"),         // New
            createSampleFood(apiCode: "D0004", name: "Food 4")          // New
        ]
        let insertedCount = try mapper.saveUnique(from: mixedFoods, context: context)

        // Then: Should insert only new foods
        XCTAssertEqual(insertedCount, 2, "Should insert only 2 new foods")

        // Verify total count
        let fetchRequest: NSFetchRequest<Food> = Food.fetchRequest()
        let allFoods = try context.fetch(fetchRequest)
        XCTAssertEqual(allFoods.count, 4, "Should have 4 total foods (2 original + 2 new)")
    }

    // MARK: - Helper Methods

    /// Create a sample Food entity for testing
    private func createSampleFood(
        apiCode: String,
        name: String,
        calories: Int32 = 100,
        carbs: Decimal = 20,
        protein: Decimal = 5,
        fat: Decimal = 3
    ) -> Bodii.Food {
        return Bodii.Food(
            id: UUID(),
            name: name,
            calories: calories,
            carbohydrates: carbs,
            protein: protein,
            fat: fat,
            sodium: nil,
            fiber: nil,
            sugar: nil,
            servingSize: 100,
            servingUnit: nil,
            source: .governmentAPI,
            apiCode: apiCode,
            createdByUserId: nil,
            createdAt: Date()
        )
    }
}

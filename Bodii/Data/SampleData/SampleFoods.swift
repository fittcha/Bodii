//
//  SampleFoods.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-13.
//

import Foundation
import CoreData

/// 샘플 음식 데이터 제공
///
/// 테스트 및 초기 앱 사용을 위한 샘플 한국 음식 데이터를 제공합니다.
/// Core Data 컨텍스트가 필요합니다.
///
/// - Note: Food는 Core Data 엔티티이므로 context가 필요합니다.
enum SampleFoods {

    // MARK: - Create Sample Foods

    /// 샘플 음식들을 Core Data context에 생성합니다.
    /// - Parameter context: NSManagedObjectContext
    /// - Returns: 생성된 Food 배열
    @MainActor
    static func createAllFoods(in context: NSManagedObjectContext) -> [Food] {
        var foods: [Food] = []

        // 백미밥
        let whiteRice = Food(context: context)
        whiteRice.id = UUID()
        whiteRice.name = "백미밥"
        whiteRice.calories = 300
        whiteRice.carbohydrates = Decimal(65.8) as NSDecimalNumber
        whiteRice.protein = Decimal(5.4) as NSDecimalNumber
        whiteRice.fat = Decimal(0.5) as NSDecimalNumber
        whiteRice.sodium = Decimal(2.0) as NSDecimalNumber
        whiteRice.fiber = Decimal(0.8) as NSDecimalNumber
        whiteRice.sugar = Decimal(0.1) as NSDecimalNumber
        whiteRice.servingSize = Decimal(210.0) as NSDecimalNumber
        whiteRice.servingUnit = "1공기"
        whiteRice.source = 0 // governmentAPI
        whiteRice.apiCode = "KR001"
        whiteRice.createdAt = Date()
        foods.append(whiteRice)

        // 현미밥
        let brownRice = Food(context: context)
        brownRice.id = UUID()
        brownRice.name = "현미밥"
        brownRice.calories = 330
        brownRice.carbohydrates = Decimal(73.4) as NSDecimalNumber
        brownRice.protein = Decimal(6.8) as NSDecimalNumber
        brownRice.fat = Decimal(2.5) as NSDecimalNumber
        brownRice.sodium = Decimal(3.0) as NSDecimalNumber
        brownRice.fiber = Decimal(4.2) as NSDecimalNumber
        brownRice.sugar = Decimal(0.3) as NSDecimalNumber
        brownRice.servingSize = Decimal(210.0) as NSDecimalNumber
        brownRice.servingUnit = "1공기"
        brownRice.source = 0
        brownRice.apiCode = "KR002"
        brownRice.createdAt = Date()
        foods.append(brownRice)

        // 닭가슴살
        let chickenBreast = Food(context: context)
        chickenBreast.id = UUID()
        chickenBreast.name = "닭가슴살"
        chickenBreast.calories = 165
        chickenBreast.carbohydrates = Decimal(0) as NSDecimalNumber
        chickenBreast.protein = Decimal(31.0) as NSDecimalNumber
        chickenBreast.fat = Decimal(3.6) as NSDecimalNumber
        chickenBreast.sodium = Decimal(74) as NSDecimalNumber
        chickenBreast.fiber = nil
        chickenBreast.sugar = nil
        chickenBreast.servingSize = Decimal(100) as NSDecimalNumber
        chickenBreast.servingUnit = "100g"
        chickenBreast.source = 0
        chickenBreast.apiCode = "KR003"
        chickenBreast.createdAt = Date()
        foods.append(chickenBreast)

        // 계란
        let egg = Food(context: context)
        egg.id = UUID()
        egg.name = "계란"
        egg.calories = 155
        egg.carbohydrates = Decimal(1.1) as NSDecimalNumber
        egg.protein = Decimal(12.6) as NSDecimalNumber
        egg.fat = Decimal(10.6) as NSDecimalNumber
        egg.sodium = Decimal(124) as NSDecimalNumber
        egg.fiber = nil
        egg.sugar = Decimal(1.1) as NSDecimalNumber
        egg.servingSize = Decimal(100) as NSDecimalNumber
        egg.servingUnit = "2개"
        egg.source = 0
        egg.apiCode = "KR004"
        egg.createdAt = Date()
        foods.append(egg)

        // 김치
        let kimchi = Food(context: context)
        kimchi.id = UUID()
        kimchi.name = "배추김치"
        kimchi.calories = 18
        kimchi.carbohydrates = Decimal(2.4) as NSDecimalNumber
        kimchi.protein = Decimal(2.0) as NSDecimalNumber
        kimchi.fat = Decimal(0.5) as NSDecimalNumber
        kimchi.sodium = Decimal(747) as NSDecimalNumber
        kimchi.fiber = Decimal(2.1) as NSDecimalNumber
        kimchi.sugar = Decimal(1.1) as NSDecimalNumber
        kimchi.servingSize = Decimal(100) as NSDecimalNumber
        kimchi.servingUnit = "1접시"
        kimchi.source = 0
        kimchi.apiCode = "KR005"
        kimchi.createdAt = Date()
        foods.append(kimchi)

        return foods
    }
}

//
//  SampleFoods.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-13.
//

import Foundation

/// 샘플 음식 데이터 제공
///
/// 테스트 및 초기 앱 사용을 위한 샘플 한국 음식 데이터를 제공합니다.
/// 실제 식약처 영양 데이터베이스를 기반으로 한 정확한 영양 정보를 포함합니다.
///
/// - Note: 모든 샘플 음식은 FoodSource.governmentAPI를 사용합니다.
///
/// - Example:
/// ```swift
/// let foods = SampleFoods.allFoods
/// for food in foods {
///     try await foodRepository.save(food)
/// }
/// ```
enum SampleFoods {

    // MARK: - All Sample Foods

    /// 모든 샘플 음식 목록
    static var allFoods: [Food] {
        [
            // 밥류 (Rice & Grains)
            whiteRice,
            brownRice,

            // 국/찌개류 (Soups & Stews)
            kimchiStew,
            soybeansStew,
            seaweedSoup,
            beanSproutSoup,
            softTofuStew,
            ginsengChickenSoup,

            // 메인 요리 (Main Dishes)
            bulgogi,
            bibimbap,
            kimbap,
            tteokbokki,
            ramyeon,
            friedChicken,

            // 단백질 (Protein)
            chickenBreast,
            egg,
            tofu,

            // 채소/김치 (Vegetables)
            kimchi,

            // 간식/과일 (Snacks & Fruits)
            sweetPotato,
            banana,
            apple,
            avocado
        ]
    }

    // MARK: - Rice & Grains (밥류)

    /// 백미밥 (210g, 1공기)
    ///
    /// 기본적인 한국식 백미밥입니다.
    /// 탄수화물이 주 영양소이며, 단백질과 지방은 소량 포함됩니다.
    static let whiteRice = Food(
        id: UUID(),
        name: "백미밥",
        calories: 300,
        carbohydrates: Decimal(65.8),
        protein: Decimal(5.4),
        fat: Decimal(0.5),
        sodium: Decimal(2.0),
        fiber: Decimal(0.8),
        sugar: Decimal(0.1),
        servingSize: Decimal(210.0),
        servingUnit: "1공기",
        source: .governmentAPI,
        apiCode: "KR001",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 현미밥 (210g, 1공기)
    ///
    /// 백미밥 대비 식이섬유가 많고 영양소가 풍부합니다.
    /// 다이어트와 건강식을 선호하는 사용자에게 적합합니다.
    static let brownRice = Food(
        id: UUID(),
        name: "현미밥",
        calories: 330,
        carbohydrates: Decimal(73.4),
        protein: Decimal(6.8),
        fat: Decimal(2.5),
        sodium: Decimal(5.0),
        fiber: Decimal(3.0),
        sugar: Decimal(0.5),
        servingSize: Decimal(210.0),
        servingUnit: "1공기",
        source: .governmentAPI,
        apiCode: "KR002",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Soups & Stews (국/찌개류)

    /// 김치찌개 (350g, 1인분)
    ///
    /// 대표적인 한국 찌개 요리입니다.
    /// 김치와 돼지고기로 만들어 단백질과 나트륨이 풍부합니다.
    static let kimchiStew = Food(
        id: UUID(),
        name: "김치찌개",
        calories: 180,
        carbohydrates: Decimal(12.5),
        protein: Decimal(15.0),
        fat: Decimal(8.5),
        sodium: Decimal(1200.0),
        fiber: Decimal(3.5),
        sugar: Decimal(4.0),
        servingSize: Decimal(350.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR003",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 된장찌개 (350g, 1인분)
    ///
    /// 된장을 베이스로 한 전통 한국 찌개입니다.
    /// 단백질이 풍부하며 발효 식품의 장점이 있습니다.
    static let soybeansStew = Food(
        id: UUID(),
        name: "된장찌개",
        calories: 150,
        carbohydrates: Decimal(10.0),
        protein: Decimal(12.0),
        fat: Decimal(7.0),
        sodium: Decimal(1100.0),
        fiber: Decimal(3.0),
        sugar: Decimal(3.5),
        servingSize: Decimal(350.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR004",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 미역국 (350g, 1인분)
    ///
    /// 한국의 전통 국 요리로 미역이 주재료입니다.
    /// 저칼로리이며 요오드와 식이섬유가 풍부합니다.
    static let seaweedSoup = Food(
        id: UUID(),
        name: "미역국",
        calories: 80,
        carbohydrates: Decimal(5.0),
        protein: Decimal(8.0),
        fat: Decimal(3.0),
        sodium: Decimal(800.0),
        fiber: Decimal(2.0),
        sugar: Decimal(1.0),
        servingSize: Decimal(350.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR005",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 콩나물국 (350g, 1인분)
    ///
    /// 콩나물을 주재료로 한 저칼로리 국입니다.
    /// 해장 요리로도 인기가 많습니다.
    static let beanSproutSoup = Food(
        id: UUID(),
        name: "콩나물국",
        calories: 60,
        carbohydrates: Decimal(6.0),
        protein: Decimal(5.0),
        fat: Decimal(2.0),
        sodium: Decimal(900.0),
        fiber: Decimal(2.5),
        sugar: Decimal(1.5),
        servingSize: Decimal(350.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR006",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 순두부찌개 (400g, 1인분)
    ///
    /// 순두부를 주재료로 한 부드러운 찌개입니다.
    /// 단백질이 풍부하고 소화가 잘 됩니다.
    static let softTofuStew = Food(
        id: UUID(),
        name: "순두부찌개",
        calories: 200,
        carbohydrates: Decimal(10.0),
        protein: Decimal(18.0),
        fat: Decimal(10.0),
        sodium: Decimal(1300.0),
        fiber: Decimal(2.0),
        sugar: Decimal(2.5),
        servingSize: Decimal(400.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR007",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 삼계탕 (800g, 1인분)
    ///
    /// 닭고기와 인삼을 넣어 끓인 보양식입니다.
    /// 단백질이 매우 풍부하며 여름철 보양식으로 유명합니다.
    static let ginsengChickenSoup = Food(
        id: UUID(),
        name: "삼계탕",
        calories: 900,
        carbohydrates: Decimal(50.0),
        protein: Decimal(70.0),
        fat: Decimal(35.0),
        sodium: Decimal(1500.0),
        fiber: Decimal(3.0),
        sugar: Decimal(5.0),
        servingSize: Decimal(800.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR008",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Main Dishes (메인 요리)

    /// 불고기 (150g, 1인분)
    ///
    /// 양념한 소고기를 구운 한국의 대표 요리입니다.
    /// 단백질과 지방이 풍부합니다.
    static let bulgogi = Food(
        id: UUID(),
        name: "불고기",
        calories: 280,
        carbohydrates: Decimal(15.0),
        protein: Decimal(25.0),
        fat: Decimal(12.0),
        sodium: Decimal(800.0),
        fiber: Decimal(1.0),
        sugar: Decimal(8.0),
        servingSize: Decimal(150.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR009",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 비빔밥 (450g, 1인분)
    ///
    /// 밥 위에 나물과 고기, 계란을 올린 한국의 대표 요리입니다.
    /// 균형잡힌 영양소 구성이 특징입니다.
    static let bibimbap = Food(
        id: UUID(),
        name: "비빔밥",
        calories: 550,
        carbohydrates: Decimal(85.0),
        protein: Decimal(20.0),
        fat: Decimal(12.0),
        sodium: Decimal(1000.0),
        fiber: Decimal(6.0),
        sugar: Decimal(8.0),
        servingSize: Decimal(450.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR010",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 김밥 (200g, 1줄)
    ///
    /// 밥과 야채, 단무지 등을 김으로 말아 만든 간편식입니다.
    /// 휴대가 간편하여 도시락으로 인기가 많습니다.
    static let kimbap = Food(
        id: UUID(),
        name: "김밥",
        calories: 420,
        carbohydrates: Decimal(70.0),
        protein: Decimal(12.0),
        fat: Decimal(10.0),
        sodium: Decimal(600.0),
        fiber: Decimal(3.5),
        sugar: Decimal(5.0),
        servingSize: Decimal(200.0),
        servingUnit: "1줄",
        source: .governmentAPI,
        apiCode: "KR011",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 떡볶이 (300g, 1인분)
    ///
    /// 가래떡을 고추장 양념에 볶은 인기 간식입니다.
    /// 탄수화물이 주 영양소이며 매콤한 맛이 특징입니다.
    static let tteokbokki = Food(
        id: UUID(),
        name: "떡볶이",
        calories: 380,
        carbohydrates: Decimal(75.0),
        protein: Decimal(8.0),
        fat: Decimal(5.0),
        sodium: Decimal(1200.0),
        fiber: Decimal(2.0),
        sugar: Decimal(15.0),
        servingSize: Decimal(300.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR012",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 라면 (120g, 1봉지)
    ///
    /// 한국의 대표적인 인스턴트 식품입니다.
    /// 나트륨 함량이 높으니 섭취 시 주의가 필요합니다.
    static let ramyeon = Food(
        id: UUID(),
        name: "라면",
        calories: 510,
        carbohydrates: Decimal(80.0),
        protein: Decimal(10.0),
        fat: Decimal(16.0),
        sodium: Decimal(1900.0),
        fiber: Decimal(3.0),
        sugar: Decimal(5.0),
        servingSize: Decimal(120.0),
        servingUnit: "1봉지",
        source: .governmentAPI,
        apiCode: "KR013",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 치킨 (200g, 1인분)
    ///
    /// 튀긴 닭고기로 한국에서 매우 인기있는 야식입니다.
    /// 단백질과 지방이 높은 고칼로리 음식입니다.
    static let friedChicken = Food(
        id: UUID(),
        name: "치킨",
        calories: 520,
        carbohydrates: Decimal(20.0),
        protein: Decimal(45.0),
        fat: Decimal(30.0),
        sodium: Decimal(1100.0),
        fiber: Decimal(0.5),
        sugar: Decimal(3.0),
        servingSize: Decimal(200.0),
        servingUnit: "1인분",
        source: .governmentAPI,
        apiCode: "KR014",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Protein (단백질 식품)

    /// 닭가슴살 (100g)
    ///
    /// 저지방 고단백 식품의 대표입니다.
    /// 다이어트와 근육 증가에 이상적인 식품입니다.
    static let chickenBreast = Food(
        id: UUID(),
        name: "닭가슴살",
        calories: 165,
        carbohydrates: Decimal(0.0),
        protein: Decimal(31.0),
        fat: Decimal(3.6),
        sodium: Decimal(74.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        source: .governmentAPI,
        apiCode: "KR015",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 계란 (50g, 1개)
    ///
    /// 완전 단백질 식품으로 영양가가 매우 높습니다.
    /// 아침 식사로 인기가 많습니다.
    static let egg = Food(
        id: UUID(),
        name: "계란",
        calories: 72,
        carbohydrates: Decimal(0.6),
        protein: Decimal(6.3),
        fat: Decimal(4.8),
        sodium: Decimal(71.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.6),
        servingSize: Decimal(50.0),
        servingUnit: "1개",
        source: .governmentAPI,
        apiCode: "KR016",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 두부 (150g, 1/2모)
    ///
    /// 식물성 단백질이 풍부한 콩 제품입니다.
    /// 저칼로리 고단백으로 다이어트에 적합합니다.
    static let tofu = Food(
        id: UUID(),
        name: "두부",
        calories: 110,
        carbohydrates: Decimal(3.0),
        protein: Decimal(12.0),
        fat: Decimal(6.0),
        sodium: Decimal(7.0),
        fiber: Decimal(1.5),
        sugar: Decimal(1.0),
        servingSize: Decimal(150.0),
        servingUnit: "1/2모",
        source: .governmentAPI,
        apiCode: "KR017",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Vegetables (채소/김치)

    /// 김치 (40g, 1접시)
    ///
    /// 한국의 전통 발효 식품입니다.
    /// 유산균과 식이섬유가 풍부하며 나트륨 함량이 높습니다.
    static let kimchi = Food(
        id: UUID(),
        name: "김치",
        calories: 18,
        carbohydrates: Decimal(2.4),
        protein: Decimal(1.3),
        fat: Decimal(0.6),
        sodium: Decimal(498.0),
        fiber: Decimal(1.6),
        sugar: Decimal(1.2),
        servingSize: Decimal(40.0),
        servingUnit: "1접시",
        source: .governmentAPI,
        apiCode: "KR018",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Snacks & Fruits (간식/과일)

    /// 고구마 (130g, 1개)
    ///
    /// 식이섬유가 풍부한 건강한 탄수화물 간식입니다.
    /// 포만감이 높아 다이어트 간식으로 인기가 많습니다.
    static let sweetPotato = Food(
        id: UUID(),
        name: "고구마",
        calories: 115,
        carbohydrates: Decimal(27.0),
        protein: Decimal(1.6),
        fat: Decimal(0.1),
        sodium: Decimal(7.0),
        fiber: Decimal(3.8),
        sugar: Decimal(6.5),
        servingSize: Decimal(130.0),
        servingUnit: "1개",
        source: .governmentAPI,
        apiCode: "KR019",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 바나나 (120g, 1개)
    ///
    /// 칼륨이 풍부한 과일입니다.
    /// 운동 전후 간식으로 인기가 많습니다.
    static let banana = Food(
        id: UUID(),
        name: "바나나",
        calories: 108,
        carbohydrates: Decimal(27.5),
        protein: Decimal(1.3),
        fat: Decimal(0.4),
        sodium: Decimal(1.0),
        fiber: Decimal(3.1),
        sugar: Decimal(14.4),
        servingSize: Decimal(120.0),
        servingUnit: "1개",
        source: .governmentAPI,
        apiCode: "KR020",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 사과 (200g, 1개)
    ///
    /// 식이섬유가 풍부한 대표적인 과일입니다.
    /// 저칼로리로 간식으로 적합합니다.
    static let apple = Food(
        id: UUID(),
        name: "사과",
        calories: 104,
        carbohydrates: Decimal(27.6),
        protein: Decimal(0.5),
        fat: Decimal(0.3),
        sodium: Decimal(2.0),
        fiber: Decimal(4.8),
        sugar: Decimal(20.8),
        servingSize: Decimal(200.0),
        servingUnit: "1개",
        source: .governmentAPI,
        apiCode: "KR021",
        createdByUserId: nil,
        createdAt: Date()
    )

    /// 아보카도 (150g, 1개)
    ///
    /// 건강한 지방이 풍부한 과일입니다.
    /// 불포화지방산이 많아 건강식으로 인기가 많습니다.
    static let avocado = Food(
        id: UUID(),
        name: "아보카도",
        calories: 240,
        carbohydrates: Decimal(12.8),
        protein: Decimal(3.0),
        fat: Decimal(22.0),
        sodium: Decimal(11.0),
        fiber: Decimal(10.0),
        sugar: Decimal(1.0),
        servingSize: Decimal(150.0),
        servingUnit: "1개",
        source: .governmentAPI,
        apiCode: "KR022",
        createdByUserId: nil,
        createdAt: Date()
    )

    // MARK: - Helper Methods

    /// 카테고리별 음식 목록을 반환합니다.
    ///
    /// - Parameter category: 음식 카테고리
    /// - Returns: 해당 카테고리의 음식 배열
    ///
    /// - Example:
    /// ```swift
    /// let riceFoods = SampleFoods.foods(in: .rice)
    /// ```
    static func foods(in category: FoodCategory) -> [Food] {
        switch category {
        case .rice:
            return [whiteRice, brownRice]
        case .soup:
            return [kimchiStew, soybeansStew, seaweedSoup, beanSproutSoup, softTofuStew, ginsengChickenSoup]
        case .mainDish:
            return [bulgogi, bibimbap, kimbap, tteokbokki, ramyeon, friedChicken]
        case .protein:
            return [chickenBreast, egg, tofu]
        case .vegetable:
            return [kimchi]
        case .snack:
            return [sweetPotato, banana, apple, avocado]
        }
    }
}

// MARK: - Food Category

/// 음식 카테고리 열거형
///
/// 샘플 음식을 카테고리별로 분류합니다.
enum FoodCategory {
    case rice        // 밥류
    case soup        // 국/찌개류
    case mainDish    // 메인 요리
    case protein     // 단백질 식품
    case vegetable   // 채소/김치
    case snack       // 간식/과일

    var displayName: String {
        switch self {
        case .rice: return "밥류"
        case .soup: return "국/찌개류"
        case .mainDish: return "메인 요리"
        case .protein: return "단백질 식품"
        case .vegetable: return "채소/김치"
        case .snack: return "간식/과일"
        }
    }
}

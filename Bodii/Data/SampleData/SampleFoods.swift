//
//  SampleFoods.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-13.
//

import Foundation
import CoreData

// 📚 학습 포인트: Core Data Sample Data Pattern
// Food는 Core Data 엔티티(NSManagedObject)이므로 context 없이 인스턴스화 불가
// 런타임에 context를 제공받아 샘플 데이터를 생성하는 방식 사용
// 💡 Java 비교: EntityManager를 통한 persist와 유사

/// 샘플 음식 데이터 제공
///
/// 테스트 및 초기 앱 사용을 위한 샘플 한국 음식 데이터를 제공합니다.
/// Core Data 컨텍스트가 필요합니다.
///
/// - Note: 모든 샘플 음식은 FoodSource.governmentAPI를 사용합니다.
/// - Note: Food는 Core Data 엔티티이므로 반드시 context를 제공해야 합니다.
///
/// - Example:
/// ```swift
/// let context = PersistenceController.shared.container.viewContext
/// let foods = SampleFoods.createAllFoods(in: context)
/// try context.save()
/// ```
enum SampleFoods {

    // MARK: - Sample Food Data Definitions

    /// 샘플 음식 데이터 정의 (Core Data 생성에 필요한 데이터)
    struct FoodData {
        let name: String
        let calories: Int32
        let carbohydrates: Decimal
        let protein: Decimal
        let fat: Decimal
        let sodium: Decimal?
        let fiber: Decimal?
        let sugar: Decimal?
        let servingSize: Decimal
        let servingUnit: String
        let apiCode: String
    }

    // MARK: - All Sample Food Data

    /// 모든 샘플 음식 데이터
    static let allFoodData: [FoodData] = [
        // 밥류 (Rice & Grains)
        whiteRiceData,
        brownRiceData,

        // 국/찌개류 (Soups & Stews)
        kimchiStewData,
        soybeansStewData,
        seaweedSoupData,
        beanSproutSoupData,
        softTofuStewData,
        ginsengChickenSoupData,

        // 메인 요리 (Main Dishes)
        bulgogiData,
        bibimbapData,
        kimbapData,
        tteokbokkiData,
        ramyeonData,
        friedChickenData,

        // 단백질 (Protein)
        chickenBreastData,
        eggData,
        tofuData,

        // 채소/김치 (Vegetables)
        kimchiData,

        // 간식/과일 (Snacks & Fruits)
        sweetPotatoData,
        bananaData,
        appleData,
        avocadoData,

        // 유제품 (Dairy)
        milkData,
        yogurtData,
        cheeseData,

        // 원재료 (Raw Ingredients)
        honeyData,
        butterData,
        oliveOilData,
        sugarData,
        saltData,
        flourData,

        // 빵/디저트 (Bread & Desserts)
        breadData,
        donutData,

        // 음료 (Beverages)
        orangeJuiceData,
        coffeeLatteData,

        // 추가 단백질 (More Protein)
        porkBellyData,
        beefData,
        salmonData,
        shrimpData,

        // 추가 채소/과일 (More Vegetables & Fruits)
        tomatoData,
        cucumberData,
        carrotData,
        spinachData,
        grapesData,
        watermelonData
    ]

    // MARK: - Rice & Grains (밥류)

    /// 백미밥 (210g, 1공기)
    static let whiteRiceData = FoodData(
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
        apiCode: "KR001"
    )

    /// 현미밥 (210g, 1공기)
    static let brownRiceData = FoodData(
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
        apiCode: "KR002"
    )

    // MARK: - Soups & Stews (국/찌개류)

    /// 김치찌개 (350g, 1인분)
    static let kimchiStewData = FoodData(
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
        apiCode: "KR003"
    )

    /// 된장찌개 (350g, 1인분)
    static let soybeansStewData = FoodData(
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
        apiCode: "KR004"
    )

    /// 미역국 (300g, 1인분)
    static let seaweedSoupData = FoodData(
        name: "미역국",
        calories: 70,
        carbohydrates: Decimal(5.0),
        protein: Decimal(7.0),
        fat: Decimal(3.0),
        sodium: Decimal(800.0),
        fiber: Decimal(2.0),
        sugar: Decimal(1.0),
        servingSize: Decimal(300.0),
        servingUnit: "1인분",
        apiCode: "KR005"
    )

    /// 콩나물국 (300g, 1인분)
    static let beanSproutSoupData = FoodData(
        name: "콩나물국",
        calories: 60,
        carbohydrates: Decimal(6.0),
        protein: Decimal(5.0),
        fat: Decimal(2.0),
        sodium: Decimal(700.0),
        fiber: Decimal(2.5),
        sugar: Decimal(2.0),
        servingSize: Decimal(300.0),
        servingUnit: "1인분",
        apiCode: "KR006"
    )

    /// 순두부찌개 (350g, 1인분)
    static let softTofuStewData = FoodData(
        name: "순두부찌개",
        calories: 200,
        carbohydrates: Decimal(8.0),
        protein: Decimal(18.0),
        fat: Decimal(11.0),
        sodium: Decimal(1000.0),
        fiber: Decimal(2.0),
        sugar: Decimal(3.0),
        servingSize: Decimal(350.0),
        servingUnit: "1인분",
        apiCode: "KR007"
    )

    /// 삼계탕 (800g, 1인분)
    static let ginsengChickenSoupData = FoodData(
        name: "삼계탕",
        calories: 550,
        carbohydrates: Decimal(35.0),
        protein: Decimal(45.0),
        fat: Decimal(25.0),
        sodium: Decimal(900.0),
        fiber: Decimal(2.0),
        sugar: Decimal(3.0),
        servingSize: Decimal(800.0),
        servingUnit: "1인분",
        apiCode: "KR008"
    )

    // MARK: - Main Dishes (메인 요리)

    /// 불고기 (150g, 1인분)
    static let bulgogiData = FoodData(
        name: "불고기",
        calories: 280,
        carbohydrates: Decimal(12.0),
        protein: Decimal(25.0),
        fat: Decimal(15.0),
        sodium: Decimal(600.0),
        fiber: Decimal(1.0),
        sugar: Decimal(8.0),
        servingSize: Decimal(150.0),
        servingUnit: "1인분",
        apiCode: "KR009"
    )

    /// 비빔밥 (400g, 1인분)
    static let bibimbapData = FoodData(
        name: "비빔밥",
        calories: 550,
        carbohydrates: Decimal(78.0),
        protein: Decimal(18.0),
        fat: Decimal(18.0),
        sodium: Decimal(800.0),
        fiber: Decimal(5.0),
        sugar: Decimal(6.0),
        servingSize: Decimal(400.0),
        servingUnit: "1인분",
        apiCode: "KR010"
    )

    /// 김밥 (300g, 1줄)
    static let kimbapData = FoodData(
        name: "김밥",
        calories: 450,
        carbohydrates: Decimal(65.0),
        protein: Decimal(12.0),
        fat: Decimal(15.0),
        sodium: Decimal(900.0),
        fiber: Decimal(3.0),
        sugar: Decimal(5.0),
        servingSize: Decimal(300.0),
        servingUnit: "1줄",
        apiCode: "KR011"
    )

    /// 떡볶이 (250g, 1인분)
    static let tteokbokkiData = FoodData(
        name: "떡볶이",
        calories: 400,
        carbohydrates: Decimal(75.0),
        protein: Decimal(8.0),
        fat: Decimal(8.0),
        sodium: Decimal(1200.0),
        fiber: Decimal(2.0),
        sugar: Decimal(15.0),
        servingSize: Decimal(250.0),
        servingUnit: "1인분",
        apiCode: "KR012"
    )

    /// 라면 (550g, 1인분)
    static let ramyeonData = FoodData(
        name: "라면",
        calories: 500,
        carbohydrates: Decimal(70.0),
        protein: Decimal(10.0),
        fat: Decimal(18.0),
        sodium: Decimal(1800.0),
        fiber: Decimal(2.0),
        sugar: Decimal(4.0),
        servingSize: Decimal(550.0),
        servingUnit: "1인분",
        apiCode: "KR013"
    )

    /// 치킨 (200g, 2조각)
    static let friedChickenData = FoodData(
        name: "치킨",
        calories: 450,
        carbohydrates: Decimal(15.0),
        protein: Decimal(30.0),
        fat: Decimal(30.0),
        sodium: Decimal(800.0),
        fiber: Decimal(1.0),
        sugar: Decimal(2.0),
        servingSize: Decimal(200.0),
        servingUnit: "2조각",
        apiCode: "KR014"
    )

    // MARK: - Protein (단백질 식품)

    /// 닭가슴살 (100g, 1개)
    static let chickenBreastData = FoodData(
        name: "닭가슴살",
        calories: 165,
        carbohydrates: Decimal(0.0),
        protein: Decimal(31.0),
        fat: Decimal(3.6),
        sodium: Decimal(74.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "1개",
        apiCode: "KR015"
    )

    /// 계란 (50g, 1개)
    static let eggData = FoodData(
        name: "계란",
        calories: 78,
        carbohydrates: Decimal(0.6),
        protein: Decimal(6.3),
        fat: Decimal(5.3),
        sodium: Decimal(62.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.6),
        servingSize: Decimal(50.0),
        servingUnit: "1개",
        apiCode: "KR016"
    )

    /// 두부 (100g, 1/4모)
    static let tofuData = FoodData(
        name: "두부",
        calories: 80,
        carbohydrates: Decimal(2.0),
        protein: Decimal(8.0),
        fat: Decimal(4.5),
        sodium: Decimal(7.0),
        fiber: Decimal(0.5),
        sugar: Decimal(0.5),
        servingSize: Decimal(100.0),
        servingUnit: "1/4모",
        apiCode: "KR017"
    )

    // MARK: - Vegetables (채소/김치)

    /// 김치 (50g, 1회분량)
    static let kimchiData = FoodData(
        name: "김치",
        calories: 20,
        carbohydrates: Decimal(3.0),
        protein: Decimal(1.5),
        fat: Decimal(0.3),
        sodium: Decimal(400.0),
        fiber: Decimal(2.0),
        sugar: Decimal(2.0),
        servingSize: Decimal(50.0),
        servingUnit: "1회분량",
        apiCode: "KR018"
    )

    // MARK: - Snacks & Fruits (간식/과일)

    /// 고구마 (150g, 1개)
    static let sweetPotatoData = FoodData(
        name: "고구마",
        calories: 130,
        carbohydrates: Decimal(30.0),
        protein: Decimal(2.0),
        fat: Decimal(0.1),
        sodium: Decimal(10.0),
        fiber: Decimal(3.0),
        sugar: Decimal(12.0),
        servingSize: Decimal(150.0),
        servingUnit: "1개",
        apiCode: "KR019"
    )

    /// 바나나 (120g, 1개)
    static let bananaData = FoodData(
        name: "바나나",
        calories: 105,
        carbohydrates: Decimal(27.0),
        protein: Decimal(1.3),
        fat: Decimal(0.4),
        sodium: Decimal(1.0),
        fiber: Decimal(3.0),
        sugar: Decimal(14.0),
        servingSize: Decimal(120.0),
        servingUnit: "1개",
        apiCode: "KR020"
    )

    /// 사과 (200g, 1개)
    static let appleData = FoodData(
        name: "사과",
        calories: 95,
        carbohydrates: Decimal(25.0),
        protein: Decimal(0.5),
        fat: Decimal(0.3),
        sodium: Decimal(2.0),
        fiber: Decimal(4.0),
        sugar: Decimal(19.0),
        servingSize: Decimal(200.0),
        servingUnit: "1개",
        apiCode: "KR021"
    )

    /// 아보카도 (150g, 1개)
    static let avocadoData = FoodData(
        name: "아보카도",
        calories: 240,
        carbohydrates: Decimal(13.0),
        protein: Decimal(3.0),
        fat: Decimal(22.0),
        sodium: Decimal(11.0),
        fiber: Decimal(10.0),
        sugar: Decimal(1.0),
        servingSize: Decimal(150.0),
        servingUnit: "1개",
        apiCode: "KR022"
    )

    // MARK: - Dairy (유제품)

    /// 우유 (200ml, 1컵)
    static let milkData = FoodData(
        name: "우유",
        calories: 130,
        carbohydrates: Decimal(10.0),
        protein: Decimal(6.4),
        fat: Decimal(7.4),
        sodium: Decimal(100.0),
        fiber: Decimal(0.0),
        sugar: Decimal(10.0),
        servingSize: Decimal(200.0),
        servingUnit: "1컵",
        apiCode: "KR023"
    )

    /// 요거트 (100g, 1개)
    static let yogurtData = FoodData(
        name: "요거트",
        calories: 60,
        carbohydrates: Decimal(7.0),
        protein: Decimal(3.5),
        fat: Decimal(1.5),
        sodium: Decimal(46.0),
        fiber: Decimal(0.0),
        sugar: Decimal(7.0),
        servingSize: Decimal(100.0),
        servingUnit: "1개",
        apiCode: "KR024"
    )

    /// 치즈 (20g, 1장)
    static let cheeseData = FoodData(
        name: "치즈",
        calories: 68,
        carbohydrates: Decimal(0.4),
        protein: Decimal(4.2),
        fat: Decimal(5.5),
        sodium: Decimal(174.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.1),
        servingSize: Decimal(20.0),
        servingUnit: "1장",
        apiCode: "KR025"
    )

    // MARK: - Raw Ingredients (원재료)

    /// 꿀 (15g, 1큰술)
    static let honeyData = FoodData(
        name: "꿀",
        calories: 46,
        carbohydrates: Decimal(12.4),
        protein: Decimal(0.0),
        fat: Decimal(0.0),
        sodium: Decimal(1.0),
        fiber: Decimal(0.0),
        sugar: Decimal(12.3),
        servingSize: Decimal(15.0),
        servingUnit: "1큰술",
        apiCode: "KR026"
    )

    /// 버터 (10g, 1큰술)
    static let butterData = FoodData(
        name: "버터",
        calories: 72,
        carbohydrates: Decimal(0.0),
        protein: Decimal(0.1),
        fat: Decimal(8.1),
        sodium: Decimal(82.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(10.0),
        servingUnit: "1큰술",
        apiCode: "KR027"
    )

    /// 올리브오일 (14g, 1큰술)
    static let oliveOilData = FoodData(
        name: "올리브오일",
        calories: 119,
        carbohydrates: Decimal(0.0),
        protein: Decimal(0.0),
        fat: Decimal(14.0),
        sodium: Decimal(0.3),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(14.0),
        servingUnit: "1큰술",
        apiCode: "KR028"
    )

    /// 설탕 (10g, 1큰술)
    static let sugarData = FoodData(
        name: "설탕",
        calories: 39,
        carbohydrates: Decimal(10.0),
        protein: Decimal(0.0),
        fat: Decimal(0.0),
        sodium: Decimal(0.0),
        fiber: Decimal(0.0),
        sugar: Decimal(10.0),
        servingSize: Decimal(10.0),
        servingUnit: "1큰술",
        apiCode: "KR029"
    )

    /// 소금 (5g, 1작은술)
    static let saltData = FoodData(
        name: "소금",
        calories: 0,
        carbohydrates: Decimal(0.0),
        protein: Decimal(0.0),
        fat: Decimal(0.0),
        sodium: Decimal(1938.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(5.0),
        servingUnit: "1작은술",
        apiCode: "KR030"
    )

    /// 밀가루 (100g)
    static let flourData = FoodData(
        name: "밀가루",
        calories: 364,
        carbohydrates: Decimal(76.0),
        protein: Decimal(10.3),
        fat: Decimal(1.0),
        sodium: Decimal(2.0),
        fiber: Decimal(2.7),
        sugar: Decimal(0.3),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR031"
    )

    // MARK: - Bread & Desserts (빵/디저트)

    /// 식빵 (30g, 1장)
    static let breadData = FoodData(
        name: "식빵",
        calories: 80,
        carbohydrates: Decimal(14.0),
        protein: Decimal(3.0),
        fat: Decimal(1.3),
        sodium: Decimal(130.0),
        fiber: Decimal(0.7),
        sugar: Decimal(2.0),
        servingSize: Decimal(30.0),
        servingUnit: "1장",
        apiCode: "KR032"
    )

    /// 도넛 (50g, 1개)
    static let donutData = FoodData(
        name: "도넛",
        calories: 195,
        carbohydrates: Decimal(23.0),
        protein: Decimal(2.3),
        fat: Decimal(10.5),
        sodium: Decimal(180.0),
        fiber: Decimal(0.5),
        sugar: Decimal(10.0),
        servingSize: Decimal(50.0),
        servingUnit: "1개",
        apiCode: "KR033"
    )

    // MARK: - Beverages (음료)

    /// 오렌지주스 (200ml, 1컵)
    static let orangeJuiceData = FoodData(
        name: "오렌지주스",
        calories: 89,
        carbohydrates: Decimal(20.8),
        protein: Decimal(1.4),
        fat: Decimal(0.4),
        sodium: Decimal(2.0),
        fiber: Decimal(0.4),
        sugar: Decimal(17.0),
        servingSize: Decimal(200.0),
        servingUnit: "1컵",
        apiCode: "KR034"
    )

    /// 카페라떼 (350ml, 1잔)
    static let coffeeLatteData = FoodData(
        name: "카페라떼",
        calories: 150,
        carbohydrates: Decimal(12.0),
        protein: Decimal(8.0),
        fat: Decimal(8.0),
        sodium: Decimal(100.0),
        fiber: Decimal(0.0),
        sugar: Decimal(12.0),
        servingSize: Decimal(350.0),
        servingUnit: "1잔",
        apiCode: "KR035"
    )

    // MARK: - More Protein (추가 단백질)

    /// 삼겹살 (100g)
    static let porkBellyData = FoodData(
        name: "삼겹살",
        calories: 331,
        carbohydrates: Decimal(0.0),
        protein: Decimal(17.0),
        fat: Decimal(29.0),
        sodium: Decimal(50.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR036"
    )

    /// 소고기 (100g)
    static let beefData = FoodData(
        name: "소고기",
        calories: 250,
        carbohydrates: Decimal(0.0),
        protein: Decimal(26.0),
        fat: Decimal(15.0),
        sodium: Decimal(72.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR037"
    )

    /// 연어 (100g)
    static let salmonData = FoodData(
        name: "연어",
        calories: 208,
        carbohydrates: Decimal(0.0),
        protein: Decimal(20.0),
        fat: Decimal(13.0),
        sodium: Decimal(59.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR038"
    )

    /// 새우 (100g)
    static let shrimpData = FoodData(
        name: "새우",
        calories: 85,
        carbohydrates: Decimal(0.2),
        protein: Decimal(20.0),
        fat: Decimal(0.5),
        sodium: Decimal(566.0),
        fiber: Decimal(0.0),
        sugar: Decimal(0.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR039"
    )

    // MARK: - More Vegetables & Fruits (추가 채소/과일)

    /// 토마토 (150g, 1개)
    static let tomatoData = FoodData(
        name: "토마토",
        calories: 27,
        carbohydrates: Decimal(5.8),
        protein: Decimal(1.3),
        fat: Decimal(0.3),
        sodium: Decimal(8.0),
        fiber: Decimal(1.8),
        sugar: Decimal(3.9),
        servingSize: Decimal(150.0),
        servingUnit: "1개",
        apiCode: "KR040"
    )

    /// 오이 (100g)
    static let cucumberData = FoodData(
        name: "오이",
        calories: 12,
        carbohydrates: Decimal(2.2),
        protein: Decimal(0.6),
        fat: Decimal(0.1),
        sodium: Decimal(3.0),
        fiber: Decimal(0.7),
        sugar: Decimal(1.4),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR041"
    )

    /// 당근 (100g)
    static let carrotData = FoodData(
        name: "당근",
        calories: 36,
        carbohydrates: Decimal(8.2),
        protein: Decimal(0.7),
        fat: Decimal(0.2),
        sodium: Decimal(58.0),
        fiber: Decimal(2.4),
        sugar: Decimal(4.5),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR042"
    )

    /// 시금치 (100g)
    static let spinachData = FoodData(
        name: "시금치",
        calories: 23,
        carbohydrates: Decimal(3.6),
        protein: Decimal(2.9),
        fat: Decimal(0.4),
        sodium: Decimal(79.0),
        fiber: Decimal(2.2),
        sugar: Decimal(0.4),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR043"
    )

    /// 포도 (100g)
    static let grapesData = FoodData(
        name: "포도",
        calories: 67,
        carbohydrates: Decimal(17.2),
        protein: Decimal(0.6),
        fat: Decimal(0.4),
        sodium: Decimal(2.0),
        fiber: Decimal(0.9),
        sugar: Decimal(16.0),
        servingSize: Decimal(100.0),
        servingUnit: "100g",
        apiCode: "KR044"
    )

    /// 수박 (200g, 1조각)
    static let watermelonData = FoodData(
        name: "수박",
        calories: 60,
        carbohydrates: Decimal(15.2),
        protein: Decimal(1.2),
        fat: Decimal(0.3),
        sodium: Decimal(2.0),
        fiber: Decimal(0.8),
        sugar: Decimal(12.4),
        servingSize: Decimal(200.0),
        servingUnit: "1조각",
        apiCode: "KR045"
    )

    // MARK: - Core Data Creation Methods

    /// 모든 샘플 음식을 Core Data context에 생성합니다.
    ///
    /// - Parameter context: NSManagedObjectContext
    /// - Returns: 생성된 Food 엔티티 배열
    ///
    /// - Example:
    /// ```swift
    /// let context = PersistenceController.shared.container.viewContext
    /// let foods = SampleFoods.createAllFoods(in: context)
    /// try context.save()
    /// ```
    @discardableResult
    static func createAllFoods(in context: NSManagedObjectContext) -> [Food] {
        return allFoodData.map { data in
            createFood(from: data, in: context)
        }
    }

    /// FoodData로부터 Core Data Food 엔티티를 생성합니다.
    ///
    /// - Parameters:
    ///   - data: FoodData 구조체
    ///   - context: NSManagedObjectContext
    /// - Returns: 생성된 Food 엔티티
    static func createFood(from data: FoodData, in context: NSManagedObjectContext) -> Food {
        let food = Food(context: context)
        food.id = UUID()
        food.name = data.name
        food.calories = data.calories
        food.carbohydrates = data.carbohydrates as NSDecimalNumber
        food.protein = data.protein as NSDecimalNumber
        food.fat = data.fat as NSDecimalNumber
        food.sodium = data.sodium.map { $0 as NSDecimalNumber }
        food.fiber = data.fiber.map { $0 as NSDecimalNumber }
        food.sugar = data.sugar.map { $0 as NSDecimalNumber }
        food.servingSize = data.servingSize as NSDecimalNumber
        food.servingUnit = data.servingUnit
        food.source = FoodSource.governmentAPI.rawValue
        food.apiCode = data.apiCode
        food.createdByUser = nil
        food.createdAt = Date()
        return food
    }

    /// 카테고리별 샘플 음식 데이터를 반환합니다.
    ///
    /// - Parameter category: 음식 카테고리
    /// - Returns: 해당 카테고리의 FoodData 배열
    static func foodData(in category: FoodCategory) -> [FoodData] {
        switch category {
        case .rice:
            return [whiteRiceData, brownRiceData]
        case .soup:
            return [kimchiStewData, soybeansStewData, seaweedSoupData, beanSproutSoupData, softTofuStewData, ginsengChickenSoupData]
        case .mainDish:
            return [bulgogiData, bibimbapData, kimbapData, tteokbokkiData, ramyeonData, friedChickenData]
        case .protein:
            return [chickenBreastData, eggData, tofuData, porkBellyData, beefData, salmonData, shrimpData]
        case .vegetable:
            return [kimchiData, tomatoData, cucumberData, carrotData, spinachData]
        case .snack:
            return [sweetPotatoData, bananaData, appleData, avocadoData, grapesData, watermelonData]
        case .dairy:
            return [milkData, yogurtData, cheeseData]
        case .ingredient:
            return [honeyData, butterData, oliveOilData, sugarData, saltData, flourData]
        case .bread:
            return [breadData, donutData]
        case .beverage:
            return [orangeJuiceData, coffeeLatteData]
        }
    }

    /// 카테고리별 샘플 음식을 Core Data context에 생성합니다.
    ///
    /// - Parameters:
    ///   - category: 음식 카테고리
    ///   - context: NSManagedObjectContext
    /// - Returns: 생성된 Food 엔티티 배열
    @discardableResult
    static func createFoods(in category: FoodCategory, context: NSManagedObjectContext) -> [Food] {
        return foodData(in: category).map { data in
            createFood(from: data, in: context)
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
    case dairy       // 유제품
    case ingredient  // 원재료
    case bread       // 빵/디저트
    case beverage    // 음료

    var displayName: String {
        switch self {
        case .rice: return "밥류"
        case .soup: return "국/찌개류"
        case .mainDish: return "메인 요리"
        case .protein: return "단백질 식품"
        case .vegetable: return "채소/김치"
        case .snack: return "간식/과일"
        case .dairy: return "유제품"
        case .ingredient: return "원재료"
        case .bread: return "빵/디저트"
        case .beverage: return "음료"
        }
    }
}

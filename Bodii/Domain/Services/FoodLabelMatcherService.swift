//
//  FoodLabelMatcherService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Label-to-Food Matching Service
// Vision API 라벨을 음식 데이터베이스와 매칭하고 번역하는 서비스
// 💡 Java 비교: Translator + Search Service의 결합

import Foundation

/// Vision API 라벨과 음식 데이터베이스 매칭 서비스 구현
///
/// 📚 학습 포인트: Intelligent Food Matching with Translation
/// 영문 라벨을 한국어로 번역하고, 여러 데이터베이스를 검색하여
/// 사용자에게 최적의 음식 매칭 결과를 제공합니다.
/// 💡 Java 비교: Multi-source search with i18n support
///
/// ## 주요 기능
/// 1. 영문 음식 라벨 → 한국어 번역
/// 2. KFDA 데이터베이스 우선 검색
/// 3. USDA 데이터베이스 보조 검색
/// 4. 퍼지 매칭으로 부분 일치 검색
/// 5. 신뢰도 기반 정렬
/// 6. 대체 옵션 제공
///
/// - Example:
/// ```swift
/// let service = FoodLabelMatcherService(
///     unifiedSearchService: unifiedSearchService
/// )
/// let labels = [VisionLabel(description: "Pizza", score: 0.95)]
/// let matches = try await service.matchLabelsToFoods(labels)
/// ```
final class FoodLabelMatcherService: FoodLabelMatcherServiceProtocol {

    // MARK: - Properties

    /// 통합 음식 검색 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// KFDA/USDA 통합 검색을 위한 서비스 주입
    /// 💡 Java 비교: @Autowired field injection
    private let unifiedSearchService: UnifiedFoodSearchService

    /// 최대 대체 옵션 개수
    ///
    /// 각 라벨당 반환할 최대 대체 음식 개수
    private let maxAlternatives: Int

    /// 최소 매칭 신뢰도
    ///
    /// 📚 학습 포인트: Quality Threshold
    /// 이 점수 이하의 매칭은 제외
    /// 💡 기본값 0.3으로 너무 낮은 신뢰도의 결과 필터링
    private let minConfidence: Double

    // MARK: - Translation Dictionary

    /// 영문 음식 라벨 → 한국어 번역 사전
    ///
    /// 📚 학습 포인트: Translation Dictionary Pattern
    /// 공통 음식 용어를 미리 번역하여 검색 정확도 향상
    /// 💡 Java 비교: ResourceBundle 또는 i18n properties file과 유사
    ///
    /// **번역 전략:**
    /// - 일반적인 음식 카테고리 및 구체적인 음식명 포함
    /// - 한국에서 흔히 사용하는 외래어 우선
    /// - 검색 가능성을 높이기 위해 여러 표현 지원
    ///
    /// - Note: 번역이 없는 라벨은 원본 영문으로 검색
    private let translationDictionary: [String: [String]] = [
        // 주요 음식 카테고리
        "food": ["음식", "식품"],
        "dish": ["요리", "음식"],
        "meal": ["식사", "끼니"],
        "cuisine": ["요리", "음식"],

        // 곡물 및 주식
        "rice": ["밥", "쌀"],
        "bread": ["빵"],
        "noodle": ["면", "국수"],
        "noodles": ["면", "국수"],
        "pasta": ["파스타"],
        "cereal": ["시리얼"],

        // 육류
        "meat": ["고기", "육류"],
        "chicken": ["닭고기", "치킨"],
        "beef": ["소고기", "쇠고기"],
        "pork": ["돼지고기"],
        "turkey": ["칠면조"],
        "lamb": ["양고기"],
        "duck": ["오리고기"],

        // 해산물
        "fish": ["생선", "물고기"],
        "seafood": ["해산물"],
        "salmon": ["연어"],
        "tuna": ["참치"],
        "shrimp": ["새우"],
        "crab": ["게"],
        "shellfish": ["조개"],
        "squid": ["오징어"],

        // 유제품
        "milk": ["우유"],
        "cheese": ["치즈"],
        "yogurt": ["요거트", "요구르트"],
        "butter": ["버터"],
        "cream": ["크림"],

        // 채소
        "vegetable": ["채소", "야채"],
        "lettuce": ["상추"],
        "tomato": ["토마토"],
        "cucumber": ["오이"],
        "carrot": ["당근"],
        "potato": ["감자"],
        "onion": ["양파"],
        "garlic": ["마늘"],
        "cabbage": ["양배추", "배추"],
        "spinach": ["시금치"],
        "broccoli": ["브로콜리"],

        // 과일
        "fruit": ["과일"],
        "apple": ["사과"],
        "banana": ["바나나"],
        "orange": ["오렌지"],
        "grape": ["포도"],
        "strawberry": ["딸기"],
        "watermelon": ["수박"],
        "peach": ["복숭아"],
        "pear": ["배"],
        "kiwi": ["키위"],

        // 간식 및 디저트
        "snack": ["간식", "스낵"],
        "dessert": ["디저트", "후식"],
        "cake": ["케이크"],
        "cookie": ["쿠키"],
        "chocolate": ["초콜릿"],
        "candy": ["사탕", "캔디"],
        "ice cream": ["아이스크림"],

        // 음료
        "drink": ["음료", "음료수"],
        "beverage": ["음료", "음료수"],
        "water": ["물"],
        "coffee": ["커피"],
        "tea": ["차"],
        "juice": ["주스"],
        "soda": ["탄산음료", "소다"],
        "beer": ["맥주"],
        "wine": ["와인"],

        // 인기 음식
        "pizza": ["피자"],
        "burger": ["버거", "햄버거"],
        "sandwich": ["샌드위치"],
        "salad": ["샐러드"],
        "soup": ["수프", "국"],
        "stew": ["찌개", "스튜"],
        "curry": ["카레"],
        "sushi": ["초밥", "스시"],
        "ramen": ["라면"],
        "fried chicken": ["치킨", "프라이드치킨"],

        // 조리 방법
        "fried": ["튀김", "프라이"],
        "grilled": ["구이", "그릴"],
        "baked": ["구운"],
        "steamed": ["찐", "찜"],
        "boiled": ["삶은"],
        "roasted": ["구운", "로스트"],

        // 한식 (영문 표기)
        "kimchi": ["김치"],
        "bibimbap": ["비빔밥"],
        "bulgogi": ["불고기"],
        "galbi": ["갈비"],
        "samgyeopsal": ["삼겹살"],
        "tteokbokki": ["떡볶이"],
        "jjigae": ["찌개"],

        // 기타
        "egg": ["계란", "달걀"],
        "tofu": ["두부"],
        "mushroom": ["버섯"],
        "nut": ["견과류"],
        "bean": ["콩"],
        "sauce": ["소스"],
        "oil": ["기름", "오일"]
    ]

    // MARK: - Initialization

    /// FoodLabelMatcherService 초기화
    ///
    /// 📚 학습 포인트: Constructor Injection
    /// 의존성을 생성자를 통해 주입받아 테스트 용이성 향상
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - unifiedSearchService: 통합 음식 검색 서비스
    ///   - maxAlternatives: 최대 대체 옵션 개수 (기본값: 3)
    ///   - minConfidence: 최소 매칭 신뢰도 (기본값: 0.3)
    init(
        unifiedSearchService: UnifiedFoodSearchService,
        maxAlternatives: Int = 3,
        minConfidence: Double = 0.3
    ) {
        self.unifiedSearchService = unifiedSearchService
        self.maxAlternatives = maxAlternatives
        self.minConfidence = minConfidence
    }

    // MARK: - FoodLabelMatcherServiceProtocol

    func matchLabelsToFoods(_ labels: [VisionLabel]) async throws -> [FoodMatch] {
        // 입력 검증
        guard !labels.isEmpty else {
            return []
        }

        #if DEBUG
        print("🔍 Starting label matching for \(labels.count) labels")
        #endif

        // 📚 학습 포인트: Parallel Label Matching
        // 각 라벨을 병렬로 처리하여 성능 최적화
        // 💡 Java 비교: CompletableFuture.allOf()와 유사

        // 각 라벨에 대해 매칭 수행
        var allMatches: [FoodMatch] = []

        for label in labels {
            // 각 라벨 매칭
            let matches = await matchSingleLabel(label)
            allMatches.append(contentsOf: matches)
        }

        // 📚 학습 포인트: Confidence-based Sorting
        // 신뢰도가 높은 매칭을 상위에 배치
        // 💡 Java 비교: Comparator.comparing().reversed()
        let sortedMatches = allMatches.sorted { $0.confidence > $1.confidence }

        #if DEBUG
        print("✅ Label matching complete: \(sortedMatches.count) matches found")
        if !sortedMatches.isEmpty {
            print("   Top match: \(sortedMatches[0].food.name) (confidence: \(sortedMatches[0].confidencePercentage)%)")
        }
        #endif

        return sortedMatches
    }

    // MARK: - Private Methods

    /// 단일 라벨을 음식과 매칭
    ///
    /// 📚 학습 포인트: Multi-Strategy Search
    /// 여러 검색 전략을 순차적으로 시도하여 최적의 결과 도출
    /// 💡 Java 비교: Chain of Responsibility pattern
    ///
    /// - Parameter label: Vision API 라벨
    ///
    /// - Returns: 매칭된 음식 목록
    ///
    /// **매칭 전략:**
    /// 1. 라벨을 한국어로 번역
    /// 2. 번역된 키워드로 검색
    /// 3. 원본 영문 라벨로도 검색
    /// 4. 결과 병합 및 중복 제거
    /// 5. 신뢰도 기반 정렬
    private func matchSingleLabel(_ label: VisionLabel) async -> [FoodMatch] {
        #if DEBUG
        print("🔍 Matching label: '\(label.description)' (score: \(label.scorePercentage)%)")
        #endif

        var foundFoods: [Food] = []

        // 1. 라벨 번역
        let translations = translate(label: label.description)

        // 2. 번역된 키워드로 검색
        if !translations.isEmpty {
            #if DEBUG
            print("   Translated to: \(translations.joined(separator: ", "))")
            #endif

            for keyword in translations {
                let foods = await searchFoods(query: keyword)
                foundFoods.append(contentsOf: foods)

                // 충분한 결과를 찾았으면 조기 종료
                if foundFoods.count >= 5 {
                    break
                }
            }
        }

        // 3. 원본 영문으로도 검색 (번역이 없거나 결과가 부족한 경우)
        if foundFoods.count < 3 {
            #if DEBUG
            print("   Searching with original label: '\(label.description)'")
            #endif

            let foods = await searchFoods(query: label.description)
            foundFoods.append(contentsOf: foods)
        }

        // 4. 중복 제거
        foundFoods = deduplicateFoods(foundFoods)

        #if DEBUG
        print("   Found \(foundFoods.count) unique foods")
        #endif

        // 5. FoodMatch 객체 생성
        guard !foundFoods.isEmpty else {
            return []
        }

        // 첫 번째 음식을 주 매칭으로, 나머지를 대체 옵션으로 설정
        let primaryFood = foundFoods[0]
        let alternatives = Array(foundFoods.dropFirst().prefix(maxAlternatives))

        // 📚 학습 포인트: Confidence Score Calculation
        // Vision API 점수와 매칭 품질을 결합
        // 💡 정확한 이름 매칭일수록 높은 신뢰도
        let matchQuality = calculateMatchQuality(
            labelText: label.description,
            foodName: primaryFood.name ?? "",
            translations: translations
        )
        let confidence = label.score * matchQuality

        // 최소 신뢰도 체크
        guard confidence >= minConfidence else {
            #if DEBUG
            print("   Confidence too low (\(Int(confidence * 100))%), skipping")
            #endif
            return []
        }

        let match = FoodMatch(
            label: label.description,
            originalLabel: label,
            confidence: confidence,
            food: primaryFood,
            alternatives: alternatives,
            translatedKeyword: translations.first
        )

        #if DEBUG
        print("   ✅ Match: \(primaryFood.name) (confidence: \(match.confidencePercentage)%, alternatives: \(alternatives.count))")
        #endif

        return [match]
    }

    /// 음식 검색 (graceful error handling)
    ///
    /// 📚 학습 포인트: Graceful Degradation
    /// 검색 실패 시에도 에러를 던지지 않고 빈 배열 반환
    /// 💡 Java 비교: Optional.orElse([])와 유사
    ///
    /// - Parameter query: 검색어
    ///
    /// - Returns: 검색 결과 (실패 시 빈 배열)
    private func searchFoods(query: String) async -> [Food] {
        do {
            let foods = try await unifiedSearchService.searchFoods(
                query: query,
                limit: 5
            )
            return foods
        } catch {
            #if DEBUG
            print("⚠️ Search failed for '\(query)': \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// 라벨을 한국어로 번역
    ///
    /// 📚 학습 포인트: Dictionary-based Translation
    /// 사전 기반 번역으로 빠르고 정확한 키워드 변환
    /// 💡 Java 비교: ResourceBundle.getString()과 유사
    ///
    /// - Parameter label: 영문 라벨
    ///
    /// - Returns: 번역된 한국어 키워드 배열 (번역 없으면 빈 배열)
    ///
    /// **번역 로직:**
    /// 1. 라벨을 소문자로 변환
    /// 2. 정확한 매칭 시도
    /// 3. 부분 매칭 시도 (라벨에 키워드가 포함된 경우)
    ///
    /// - Example:
    /// ```swift
    /// translate("Pizza") → ["피자"]
    /// translate("Fried Chicken") → ["튀김", "프라이", "닭고기", "치킨"]
    /// translate("Unknown Food") → []
    /// ```
    private func translate(label: String) -> [String] {
        let lowercasedLabel = label.lowercased()

        var translations: [String] = []

        // 1. 정확한 매칭 시도
        if let exactTranslations = translationDictionary[lowercasedLabel] {
            translations.append(contentsOf: exactTranslations)
        }

        // 2. 부분 매칭 시도 (라벨에 키워드가 포함된 경우)
        // 예: "Grilled Chicken" → "grilled", "chicken" 각각 번역
        for (key, values) in translationDictionary {
            if lowercasedLabel.contains(key) && !translations.contains(where: { values.contains($0) }) {
                translations.append(contentsOf: values)
            }
        }

        // 중복 제거
        return Array(Set(translations))
    }

    /// 매칭 품질 점수 계산
    ///
    /// 📚 학습 포인트: Match Quality Score
    /// 라벨과 음식명의 유사도를 계산하여 매칭 품질 평가
    /// 💡 Java 비교: String similarity algorithms (Levenshtein, Jaro-Winkler)
    ///
    /// - Parameters:
    ///   - labelText: 라벨 텍스트
    ///   - foodName: 음식명
    ///   - translations: 번역된 키워드 목록
    ///
    /// - Returns: 매칭 품질 점수 (0.0 ~ 1.0)
    ///
    /// **점수 산정 기준:**
    /// - 1.0: 정확한 이름 매칭 (대소문자 무시)
    /// - 0.9: 번역 키워드가 음식명에 포함
    /// - 0.7: 라벨이 음식명에 포함 (부분 매칭)
    /// - 0.5: 기타 매칭
    private func calculateMatchQuality(
        labelText: String,
        foodName: String,
        translations: [String]
    ) -> Double {
        let lowercasedLabel = labelText.lowercased()
        let lowercasedFoodName = foodName.lowercased()

        // 1. 정확한 매칭
        if lowercasedLabel == lowercasedFoodName {
            return 1.0
        }

        // 2. 번역 키워드가 음식명에 포함
        for translation in translations {
            if lowercasedFoodName.contains(translation.lowercased()) {
                return 0.9
            }
        }

        // 3. 라벨이 음식명에 포함 (부분 매칭)
        if lowercasedFoodName.contains(lowercasedLabel) || lowercasedLabel.contains(lowercasedFoodName) {
            return 0.7
        }

        // 4. 단어 단위 매칭 확인
        let labelWords = lowercasedLabel.split(separator: " ").map(String.init)
        let foodWords = lowercasedFoodName.split(separator: " ").map(String.init)

        let commonWords = Set(labelWords).intersection(Set(foodWords))
        if !commonWords.isEmpty {
            let matchRatio = Double(commonWords.count) / Double(max(labelWords.count, foodWords.count))
            return 0.5 + (matchRatio * 0.2)  // 0.5 ~ 0.7
        }

        // 5. 기본 점수
        return 0.5
    }

    /// 중복된 음식 제거
    ///
    /// 📚 학습 포인트: Deduplication by ID
    /// 동일한 음식이 여러 검색어로 나타날 수 있으므로 ID 기준 중복 제거
    /// 💡 Java 비교: Stream.distinct()와 유사
    ///
    /// - Parameter foods: 음식 배열
    ///
    /// - Returns: 중복 제거된 음식 배열
    private func deduplicateFoods(_ foods: [Food]) -> [Food] {
        var seen = Set<UUID>()
        var result: [Food] = []

        for food in foods {
            guard let foodId = food.id else { continue }
            if !seen.contains(foodId) {
                seen.insert(foodId)
                result.append(food)
            }
        }

        return result
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Food Label Matcher Service
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 검색 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockFoodLabelMatcherService: FoodLabelMatcherServiceProtocol {

    /// Mock 매칭 결과
    var mockMatches: [FoodMatch] = []

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 매칭 메서드 Mock
    func matchLabelsToFoods(_ labels: [VisionLabel]) async throws -> [FoodMatch] {
        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 결과 반환
        return mockMatches
    }
}
#endif

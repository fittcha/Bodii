//
//  FoodLabelMatcherServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Label Matching Service Protocol
// Vision API 라벨을 음식 데이터베이스 항목과 매칭하는 서비스 인터페이스
// 💡 Java 비교: Service Interface pattern

import Foundation

/// Vision API 라벨과 음식 데이터베이스 매칭을 처리하는 서비스 인터페이스
///
/// 📚 학습 포인트: Multi-Database Search Strategy
/// Vision API가 반환한 라벨을 한국어로 번역하고,
/// KFDA 및 USDA 데이터베이스에서 매칭되는 음식을 검색합니다.
/// 💡 Java 비교: Search + Translation Service의 조합
///
/// ## 매칭 전략
/// 1. 영문 라벨을 한국어로 번역 (공통 음식 사전 활용)
/// 2. KFDA 데이터베이스 우선 검색
/// 3. USDA 데이터베이스 보조 검색
/// 4. 신뢰도 점수 기반 정렬
/// 5. 대체 매칭 옵션 제공
///
/// - Example:
/// ```swift
/// let service: FoodLabelMatcherServiceProtocol = FoodLabelMatcherService(...)
/// let labels = [VisionLabel(description: "Pizza", score: 0.95, ...)]
/// let matches = try await service.matchLabelsToFoods(labels)
/// // → [FoodMatch(label: "Pizza", confidence: 0.95, food: <피자 음식 객체>, ...)]
/// ```
protocol FoodLabelMatcherServiceProtocol {

    // MARK: - Matching Operations

    /// Vision API 라벨을 음식 데이터베이스 항목과 매칭합니다.
    ///
    /// 📚 학습 포인트: Intelligent Label Matching
    /// 각 라벨을 한국어로 번역하고, 여러 데이터베이스를 검색하여
    /// 가장 적합한 음식을 찾습니다.
    /// 💡 Java 비교: Multi-step search with translation
    ///
    /// ## 매칭 로직
    /// 1. 라벨을 한국어로 번역 (번역 사전 활용)
    /// 2. 번역된 키워드로 KFDA 검색
    /// 3. 결과 부족 시 USDA 검색
    /// 4. 원본 영문 라벨로도 검색
    /// 5. 신뢰도 점수로 정렬
    /// 6. 대체 매칭 옵션 추가
    ///
    /// - Parameter labels: Vision API가 인식한 라벨 목록
    ///
    /// - Returns: 매칭된 음식 목록 (신뢰도 순으로 정렬)
    ///
    /// - Throws: 검색 중 에러 발생 시
    ///
    /// - Note: 라벨이 음식과 관련 없거나 매칭 실패 시 빈 배열 반환
    ///
    /// - Example:
    /// ```swift
    /// let labels = [
    ///     VisionLabel(description: "Pizza", score: 0.95),
    ///     VisionLabel(description: "Cheese", score: 0.87)
    /// ]
    /// let matches = try await service.matchLabelsToFoods(labels)
    /// // → 피자 관련 음식들이 신뢰도 순으로 반환됨
    /// ```
    func matchLabelsToFoods(_ labels: [VisionLabel]) async throws -> [FoodMatch]
}

// MARK: - FoodMatch Model

/// Vision API 라벨과 매칭된 음식 정보
///
/// 📚 학습 포인트: Rich Match Result Model
/// 단순 검색 결과가 아닌, 라벨 정보, 신뢰도, 대체 옵션을 포함한 풍부한 정보 제공
/// 💡 Java 비교: DTO with confidence scores and alternatives
///
/// - Example:
/// ```swift
/// let match = FoodMatch(
///     label: "Pizza",
///     originalLabel: VisionLabel(...),
///     confidence: 0.95,
///     food: pizzaFood,
///     alternatives: [otherPizzaOptions],
///     translatedKeyword: "피자"
/// )
/// ```
struct FoodMatch: Identifiable {

    // MARK: - Properties

    /// 고유 ID (SwiftUI List용)
    let id: UUID

    /// 인식된 라벨 텍스트 (영문)
    ///
    /// 📚 학습 포인트: Original Label Tracking
    /// Vision API가 반환한 원본 라벨 텍스트
    /// 💡 예: "Pizza", "Chicken breast", "Rice"
    let label: String

    /// 원본 Vision 라벨 객체
    ///
    /// 📚 학습 포인트: Complete Label Information
    /// 점수, topicality 등 추가 정보를 포함한 전체 라벨 객체
    let originalLabel: VisionLabel

    /// 매칭 신뢰도 (0.0 ~ 1.0)
    ///
    /// 📚 학습 포인트: Combined Confidence Score
    /// Vision API 점수와 매칭 품질을 결합한 종합 신뢰도
    /// 💡 계산식: visionScore * matchQuality
    let confidence: Double

    /// 매칭된 음식 (최상위 매칭)
    ///
    /// 가장 적합하다고 판단된 음식 객체
    let food: Food

    /// 대체 매칭 옵션
    ///
    /// 📚 학습 포인트: Alternative Suggestions
    /// 사용자가 선택할 수 있는 다른 매칭 옵션들
    /// 💡 예: "Pizza" → [치즈 피자, 페퍼로니 피자, 야채 피자]
    let alternatives: [Food]

    /// 번역된 검색 키워드 (한국어)
    ///
    /// 📚 학습 포인트: Translation Tracking
    /// 영문 라벨을 한국어로 번역한 키워드
    /// 💡 예: "Pizza" → "피자"
    let translatedKeyword: String?

    // MARK: - Initialization

    /// FoodMatch 초기화
    ///
    /// - Parameters:
    ///   - id: 고유 ID (기본값: UUID())
    ///   - label: 인식된 라벨 텍스트
    ///   - originalLabel: 원본 Vision 라벨
    ///   - confidence: 매칭 신뢰도
    ///   - food: 매칭된 음식
    ///   - alternatives: 대체 매칭 옵션 (기본값: [])
    ///   - translatedKeyword: 번역된 한국어 키워드 (선택적)
    init(
        id: UUID = UUID(),
        label: String,
        originalLabel: VisionLabel,
        confidence: Double,
        food: Food,
        alternatives: [Food] = [],
        translatedKeyword: String? = nil
    ) {
        self.id = id
        self.label = label
        self.originalLabel = originalLabel
        self.confidence = confidence
        self.food = food
        self.alternatives = alternatives
        self.translatedKeyword = translatedKeyword
    }

    // MARK: - Computed Properties

    /// 신뢰도 백분율 (0 ~ 100)
    ///
    /// - Returns: 백분율로 변환된 신뢰도
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }

    /// 높은 신뢰도를 가진 매칭인지 확인
    ///
    /// 📚 학습 포인트: Threshold-based Validation
    /// 신뢰도 70% 이상을 높은 신뢰도로 판단
    /// 💡 사용자에게 자동으로 추천할 수 있는 수준
    ///
    /// - Returns: 신뢰도가 0.7 이상이면 true
    var isHighConfidence: Bool {
        return confidence >= 0.7
    }

    /// 대체 옵션 개수
    ///
    /// - Returns: alternatives 배열의 크기
    var alternativeCount: Int {
        return alternatives.count
    }
}

// MARK: - Equatable

extension FoodMatch: Equatable {
    static func == (lhs: FoodMatch, rhs: FoodMatch) -> Bool {
        return lhs.id == rhs.id
    }
}

//
//  DietComment.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation
import SwiftUI

/// AI가 생성한 식단 코멘트 도메인 엔티티
///
/// Gemini API를 통해 생성된 AI 피드백을 저장합니다.
/// 사용자의 식단에 대한 좋은 점, 개선점, 요약, 점수를 포함합니다.
///
/// - Note: 점수는 0-10 범위로 제한되며, DietScore로 분류됩니다.
///         8-10: Great (우수)
///         5-7: Good (좋음)
///         0-4: NeedsWork (개선 필요)
///
/// - Note: 한국 음식 맥락을 이해하고 사용자의 목표(감량/유지/증량)를 고려한 피드백을 제공합니다.
///
/// - Example:
/// ```swift
/// let comment = DietComment(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     mealType: .lunch,
///     goodPoints: ["단백질 섭취가 충분합니다", "채소 섭취가 균형있습니다"],
///     improvements: ["나트륨 섭취가 다소 높습니다", "과일 섭취를 늘려보세요"],
///     summary: "전반적으로 균형잡힌 식단이나 나트륨 조절이 필요합니다.",
///     score: 7,
///     generatedAt: Date()
/// )
/// print(comment.dietScore) // .good
/// print(comment.dietScore.color) // .yellow
/// ```
struct DietComment {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Key

    /// User 참조
    let userId: UUID

    // MARK: - Context

    /// 평가 대상 날짜
    ///
    /// 식단 코멘트가 생성된 날짜입니다.
    let date: Date

    /// 끼니 종류 (0: 아침, 1: 점심, 2: 저녁, 3: 간식)
    ///
    /// 어떤 끼니에 대한 코멘트인지 나타냅니다.
    /// nil인 경우 일일 전체 식단에 대한 코멘트입니다.
    let mealType: MealType?

    // MARK: - AI Feedback

    /// 좋은 점 목록
    ///
    /// AI가 평가한 식단의 긍정적인 측면들입니다.
    /// 예: "단백질 섭취가 충분합니다", "채소 섭취가 균형있습니다"
    var goodPoints: [String]

    /// 개선점 목록
    ///
    /// AI가 제안하는 식단 개선 사항들입니다.
    /// 예: "나트륨 섭취를 줄여보세요", "과일 섭취를 늘려보세요"
    var improvements: [String]

    /// 요약
    ///
    /// 전체 식단에 대한 AI의 종합 평가입니다.
    /// 예: "전반적으로 균형잡힌 식단이나 나트륨 조절이 필요합니다."
    var summary: String

    /// 점수 (0-10)
    ///
    /// AI가 평가한 식단의 전체 점수입니다.
    /// 8-10: 우수 (Great)
    /// 5-7: 좋음 (Good)
    /// 0-4: 개선 필요 (NeedsWork)
    var score: Int {
        didSet {
            // 점수 범위 검증 (0-10)
            if score < 0 {
                score = 0
            } else if score > 10 {
                score = 10
            }
        }
    }

    // MARK: - Metadata

    /// AI 코멘트 생성 일시
    let generatedAt: Date

    // MARK: - Computed Properties

    /// 점수에 따른 식단 평가 등급
    var dietScore: DietScore {
        DietScore.from(score: score)
    }

    // MARK: - Initialization

    /// DietComment 초기화
    ///
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - userId: 사용자 ID
    ///   - date: 평가 대상 날짜
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///   - goodPoints: 좋은 점 목록
    ///   - improvements: 개선점 목록
    ///   - summary: 요약
    ///   - score: 점수 (0-10, 범위 초과 시 자동으로 0 또는 10으로 조정됨)
    ///   - generatedAt: 생성 일시
    init(
        id: UUID,
        userId: UUID,
        date: Date,
        mealType: MealType? = nil,
        goodPoints: [String],
        improvements: [String],
        summary: String,
        score: Int,
        generatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.mealType = mealType
        self.goodPoints = goodPoints
        self.improvements = improvements
        self.summary = summary
        // 점수 범위 검증
        self.score = min(max(score, 0), 10)
        self.generatedAt = generatedAt
    }
}

// MARK: - DietScore Enum

/// 식단 평가 점수 등급
///
/// AI 코멘트의 점수(0-10)를 기반으로 한 식단 품질 등급입니다.
/// 각 등급은 시각적 피드백을 위한 색상 매핑을 제공합니다.
///
/// - Cases:
///   - excellent: 최고 (9-10점) - 파란색
///   - great: 좋음 (7-8점) - 초록색
///   - good: 보통 (4-6점) - 노란색
///   - needsWork: 개선 필요 (0-3점) - 빨간색
///
/// - Example:
/// ```swift
/// let score = DietScore.from(score: 9)
/// print(score.displayName) // "최고"
/// print(score.color) // Color.blue
/// ```
enum DietScore: String, CaseIterable, Codable {
    case excellent = "excellent"
    case great = "great"
    case good = "good"
    case needsWork = "needsWork"

    /// 사용자에게 표시할 등급 이름
    var displayName: String {
        switch self {
        case .excellent: return "최고"
        case .great: return "좋음"
        case .good: return "보통"
        case .needsWork: return "개선 필요"
        }
    }

    /// 등급별 색상
    ///
    /// - excellent: 파란색 (최고의 식단)
    /// - great: 초록색 (건강하고 균형잡힌 식단)
    /// - good: 노란색 (양호하나 개선 여지 있음)
    /// - needsWork: 빨간색 (개선이 필요한 식단)
    var color: Color {
        switch self {
        case .excellent: return .blue
        case .great: return .green
        case .good: return .yellow
        case .needsWork: return .red
        }
    }

    /// 점수로부터 식단 평가 등급을 결정하는 팩토리 메서드
    ///
    /// - Parameter score: 식단 점수 (0-10)
    /// - Returns: 점수에 해당하는 식단 평가 등급
    ///
    /// 등급 기준:
    /// - excellent: 9-10점 (최고)
    /// - great: 7-8점 (좋음)
    /// - good: 4-6점 (보통)
    /// - needsWork: 0-3점 (개선 필요)
    static func from(score: Int) -> DietScore {
        switch score {
        case 9...10:
            return .excellent
        case 7...8:
            return .great
        case 4...6:
            return .good
        default:
            return .needsWork
        }
    }
}

// MARK: - DietScore + Identifiable

extension DietScore: Identifiable {
    var id: String { rawValue }
}

// MARK: - DietComment + Identifiable

extension DietComment: Identifiable {}

// MARK: - DietComment + Equatable

extension DietComment: Equatable {
    static func == (lhs: DietComment, rhs: DietComment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DietComment + Hashable

extension DietComment: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

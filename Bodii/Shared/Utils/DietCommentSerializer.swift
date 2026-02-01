//
//  DietCommentSerializer.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-31.
//

import Foundation

/// DietComment ↔ DailyLog Core Data 필드 간 변환 유틸리티
///
/// DailyLog에 저장된 AI 코멘트 필드(String, Int32, JSON)를
/// DietComment 도메인 모델로 변환하거나 그 반대로 변환합니다.
enum DietCommentSerializer {

    // MARK: - JSON Encoding/Decoding

    /// String 배열을 JSON String으로 인코딩
    ///
    /// - Parameter array: 인코딩할 String 배열
    /// - Returns: JSON 문자열 (실패 시 nil)
    static func encode(_ array: [String]) -> String? {
        guard let data = try? JSONEncoder().encode(array) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// JSON String을 String 배열로 디코딩
    ///
    /// - Parameter jsonString: 디코딩할 JSON 문자열
    /// - Returns: String 배열 (실패 시 빈 배열)
    static func decode(_ jsonString: String?) -> [String] {
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }

    // MARK: - DailyLog → DietComment

    /// DailyLog의 AI 코멘트 필드에서 DietComment 도메인 모델을 생성
    ///
    /// - Parameters:
    ///   - dailyLog: AI 코멘트가 저장된 DailyLog
    ///   - userId: 사용자 ID
    /// - Returns: DietComment (저장된 코멘트가 없으면 nil)
    static func toDietComment(from dailyLog: DailyLog, userId: UUID) -> DietComment? {
        // aiCommentSummary가 없으면 저장된 코멘트 없음
        guard let summary = dailyLog.aiCommentSummary,
              !summary.isEmpty,
              let generatedAt = dailyLog.aiCommentGeneratedAt else {
            return nil
        }

        return DietComment(
            id: UUID(), // 영구 ID 불필요 (DailyLog 기반 재생성)
            userId: userId,
            date: dailyLog.date ?? Date(),
            mealType: nil, // DailyLog는 일일 전체 코멘트만 저장
            goodPoints: decode(dailyLog.aiCommentGoodPointsJSON),
            improvements: decode(dailyLog.aiCommentImprovementsJSON),
            summary: summary,
            score: Int(dailyLog.aiCommentScore),
            generatedAt: generatedAt
        )
    }

    // MARK: - DietComment → DailyLog

    /// DietComment를 DailyLog의 AI 코멘트 필드에 저장
    ///
    /// - Parameters:
    ///   - comment: 저장할 DietComment
    ///   - dailyLog: 저장 대상 DailyLog
    static func saveToDailyLog(_ comment: DietComment, dailyLog: DailyLog) {
        dailyLog.aiCommentSummary = comment.summary
        dailyLog.aiCommentScore = Int32(comment.score)
        dailyLog.aiCommentGoodPointsJSON = encode(comment.goodPoints)
        dailyLog.aiCommentImprovementsJSON = encode(comment.improvements)
        dailyLog.aiCommentGeneratedAt = comment.generatedAt
    }
}

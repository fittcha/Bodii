//
//  GeminiServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: AI Service Protocol for Diet Analysis
// AI 식단 코멘트 생성 서비스의 추상화된 인터페이스
// 💡 Java 비교: Service Interface 패턴과 유사

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Gemini AI 서비스 프로토콜
///
/// 📚 학습 포인트: Domain Service Protocol
/// 도메인 서비스 레이어의 AI 코멘트 생성 인터페이스
/// 💡 Java 비교: Spring Service 인터페이스와 유사
///
/// **역할:**
/// - AI 식단 코멘트 생성 비즈니스 로직 추상화
/// - 프롬프트 엔지니어링 및 응답 파싱 캡슐화
/// - 한국 음식 맥락 이해 및 TDEE/목표 기반 분석
///
/// **핵심 기능:**
/// - 식단 데이터 → AI 프롬프트 변환
/// - Gemini API 호출 및 JSON 응답 파싱
/// - DietComment 도메인 엔티티로 변환
///
/// **사용 예시:**
/// ```swift
/// // DIContainer에서 주입받음
/// let geminiService: GeminiServiceProtocol = container.resolve()
///
/// // 식단 코멘트 생성
/// let comment = try await geminiService.generateDietComment(
///     foodRecords: records,
///     mealType: .lunch,
///     userId: userId,
///     date: Date(),
///     goalType: .weightLoss,
///     tdee: 2100
/// )
/// ```
protocol GeminiServiceProtocol {

    // MARK: - Diet Comment Generation

    /// AI 식단 코멘트 생성
    ///
    /// 📚 학습 포인트: AI-Powered Diet Analysis
    /// 식단 데이터를 분석하여 AI 코멘트 생성
    /// 💡 Java 비교: @Service 클래스의 비즈니스 메서드와 유사
    ///
    /// **동작 방식:**
    /// 1. 식단 데이터를 구조화된 프롬프트로 변환
    /// 2. 한국 음식 맥락 및 영양학 지식 포함
    /// 3. 사용자 목표(감량/유지/증량) 반영
    /// 4. TDEE 대비 섭취량 분석
    /// 5. Gemini API 호출하여 AI 응답 생성
    /// 6. JSON 응답 파싱 → DietComment 엔티티 변환
    ///
    /// **프롬프트 엔지니어링 원칙:**
    /// - 역할 설정: "당신은 영양 전문가입니다"
    /// - 컨텍스트 제공: 한국 음식 맥락, 사용자 목표, TDEE
    /// - 구조화된 출력: JSON 형식 요청
    /// - 구체적 지시: goodPoints, improvements, summary, score
    /// - 제약 조건: 점수 범위(0-10), 한국어 응답
    ///
    /// **AI 응답 형식 (JSON):**
    /// ```json
    /// {
    ///   "goodPoints": [
    ///     "단백질 섭취가 충분합니다",
    ///     "채소 섭취가 균형있습니다"
    ///   ],
    ///   "improvements": [
    ///     "나트륨 섭취를 줄여보세요",
    ///     "과일 섭취를 늘려보세요"
    ///   ],
    ///   "summary": "전반적으로 균형잡힌 식단이나 나트륨 조절이 필요합니다.",
    ///   "score": 7
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - foodRecords: 분석할 식단 기록 배열
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///   - userId: 사용자 ID
    ///   - date: 식단 날짜
    ///   - goalType: 사용자 목표 (감량/유지/증량)
    ///   - tdee: 활동대사량 (kcal)
    ///
    /// - Returns: 생성된 DietComment 엔티티
    ///
    /// - Throws:
    ///   - `GeminiServiceError.emptyFoodRecords`: 식단 기록이 비어있음
    ///   - `GeminiServiceError.invalidResponse`: AI 응답 파싱 실패
    ///   - `GeminiServiceError.apiError`: Gemini API 호출 실패
    ///
    /// - Note: Rate limiting은 GeminiAPIService에서 처리됨
    ///
    /// - Example:
    /// ```swift
    /// // 점심 식단 분석
    /// let comment = try await generateDietComment(
    ///     foodRecords: lunchRecords,
    ///     mealType: .lunch,
    ///     userId: currentUser.id,
    ///     date: Date(),
    ///     goalType: .lose,
    ///     tdee: 2100
    /// )
    /// print("점수: \(comment.score)/10")
    /// print("요약: \(comment.summary)")
    /// ```
    func generateDietComment(
        foodRecords: [FoodRecord],
        mealType: MealType?,
        userId: UUID,
        date: Date,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment

    // MARK: - Food Image Analysis

    /// 음식 사진을 Gemini Multimodal API로 분석하여 영양 정보를 반환합니다.
    ///
    /// - Parameter image: 분석할 음식 사진
    /// - Returns: 인식된 음식 목록
    /// - Throws: `GeminiServiceError`
    func analyzeFoodImage(_ image: UIImage) async throws -> [GeminiFoodAnalysis]
}

// MARK: - GeminiServiceError

/// Gemini 서비스 에러
///
/// 📚 학습 포인트: Service-Level Error Types
/// 서비스 레이어에서 발생할 수 있는 에러를 명확하게 정의
/// 💡 Java 비교: Custom Service Exception과 유사
enum GeminiServiceError: LocalizedError {
    case emptyFoodRecords
    case invalidResponse(String)
    case apiError(Error)
    case jsonParsingFailed
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyFoodRecords:
            return "분석할 식단 기록이 없습니다. 식사를 먼저 기록해주세요."
        case .invalidResponse(let message):
            return "AI 응답 처리 실패: \(message)"
        case .apiError(let error):
            return "AI API 호출 실패: \(error.localizedDescription)"
        case .jsonParsingFailed:
            return "AI 응답 형식이 올바르지 않습니다. 다시 시도해주세요."
        case .imageEncodingFailed:
            return "이미지를 처리할 수 없습니다. 다른 사진을 시도해주세요."
        }
    }
}

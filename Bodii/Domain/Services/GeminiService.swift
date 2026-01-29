//
//  GeminiService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: AI Service Implementation with Prompt Engineering
// AI 식단 코멘트 생성 서비스 구현 with 한국 음식 맥락 이해
// 💡 Java 비교: @Service 클래스 구현과 유사

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Gemini AI 서비스 구현
///
/// 📚 학습 포인트: Domain Service Implementation
/// GeminiServiceProtocol을 구현하여 AI 식단 코멘트 생성
/// 💡 Java 비교: Spring @Service 구현 클래스와 유사
///
/// **주요 기능:**
/// - 식단 데이터 → AI 프롬프트 변환 (한국 음식 맥락)
/// - TDEE 대비 섭취량 분석
/// - 목표(감량/유지/증량) 기반 추천
/// - 구조화된 JSON 응답 파싱
/// - DietComment 엔티티 생성
///
/// **프롬프트 엔지니어링 전략:**
/// 1. 역할 설정: "당신은 한국 음식 전문 영양사입니다"
/// 2. 컨텍스트: 식단 데이터, TDEE, 목표
/// 3. 출력 형식: JSON (goodPoints, improvements, summary, score)
/// 4. 제약 조건: 한국어, 구체적, 실행 가능한 조언
///
/// **사용 예시:**
/// ```swift
/// let service = GeminiService(geminiAPIService: apiService)
///
/// let comment = try await service.generateDietComment(
///     foodRecords: records,
///     mealType: .lunch,
///     userId: userId,
///     date: Date(),
///     goalType: .lose,
///     tdee: 2100
/// )
/// ```
final class GeminiService: GeminiServiceProtocol {

    // MARK: - Properties

    /// Gemini API 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// GeminiAPIService를 주입받아 테스트 가능성 향상
    /// 💡 Java 비교: @Autowired와 유사
    private let geminiAPIService: GeminiAPIService

    // MARK: - Initialization

    /// GeminiService 초기화
    ///
    /// 📚 학습 포인트: Constructor Injection
    /// 외부에서 의존성을 주입받아 테스트와 유연성 향상
    /// 💡 Java 비교: Constructor-based DI와 유사
    ///
    /// - Parameter geminiAPIService: Gemini API 서비스 (기본값: 새 인스턴스)
    init(geminiAPIService: GeminiAPIService = GeminiAPIService()) {
        self.geminiAPIService = geminiAPIService
    }

    // MARK: - Public Methods

    func generateDietComment(
        foodRecords: [FoodRecord],
        mealType: MealType?,
        userId: UUID,
        date: Date,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment {

        // 1. 입력 검증
        guard !foodRecords.isEmpty else {
            throw GeminiServiceError.emptyFoodRecords
        }

        // 2. 프롬프트 생성 (한국 음식 맥락 포함)
        let prompt = buildPrompt(
            foodRecords: foodRecords,
            mealType: mealType,
            goalType: goalType,
            tdee: tdee
        )

        // 3. Gemini API 호출
        do {
            let responseText = try await geminiAPIService.generateText(
                prompt: prompt,
                temperature: 0.7,
                maxOutputTokens: 1024
            )

            guard let text = responseText else {
                throw GeminiServiceError.invalidResponse("AI 응답이 비어있습니다.")
            }

            // 4. JSON 응답 파싱
            let parsedResponse = try parseResponse(text)

            // 5. DietComment 엔티티 생성
            let comment = DietComment(
                id: UUID(),
                userId: userId,
                date: date,
                mealType: mealType,
                goodPoints: parsedResponse.goodPoints,
                improvements: parsedResponse.improvements,
                summary: parsedResponse.summary,
                score: parsedResponse.score,
                generatedAt: Date()
            )

            return comment

        } catch let error as GeminiServiceError {
            // 서비스 에러는 그대로 전달
            throw error
        } catch {
            // 기타 에러는 apiError로 래핑
            throw GeminiServiceError.apiError(error)
        }
    }

    // MARK: - Food Image Analysis

    func analyzeFoodImage(_ image: UIImage) async throws -> [GeminiFoodAnalysis] {
        // 1. 이미지를 Base64로 인코딩
        guard let base64String = image.toBase64String() else {
            throw GeminiServiceError.imageEncodingFailed
        }

        // 2. Multimodal 요청 생성
        let prompt = buildFoodImagePrompt()
        let request = GeminiRequestDTO(
            imageBase64: base64String,
            mimeType: "image/jpeg",
            prompt: prompt,
            temperature: 0.3,
            maxOutputTokens: 2048
        )

        // 3. Gemini API 호출
        do {
            let response = try await geminiAPIService.generateContent(request: request)

            guard let text = response.generatedText else {
                throw GeminiServiceError.invalidResponse("AI 응답이 비어있습니다.")
            }

            // 4. JSON 파싱
            return try parseFoodImageResponse(text)

        } catch let error as GeminiServiceError {
            throw error
        } catch {
            throw GeminiServiceError.apiError(error)
        }
    }

    // MARK: - Private Helpers

    /// 음식 사진 분석용 프롬프트 생성
    private func buildFoodImagePrompt() -> String {
        return """
        당신은 한국 음식에 정통한 전문 영양사입니다. 이 사진에 있는 음식을 분석해주세요.

        **분석 지침:**
        1. 사진에 보이는 모든 음식을 개별적으로 식별하세요
        2. 각 음식의 양(g)을 그릇/접시 크기를 참고하여 추정하세요
        3. 추정된 양을 기반으로 칼로리와 영양소를 계산하세요
        4. 한국 음식의 경우 일반적인 1인분 기준을 참고하세요

        **한국 음식 기준 참고:**
        - 공기밥: 약 210g (약 300kcal)
        - 김치찌개 1인분: 약 300g (약 150kcal)
        - 된장찌개 1인분: 약 300g (약 120kcal)
        - 김치 반찬: 약 50g (약 20kcal)
        - 불고기 1인분: 약 150g (약 280kcal)

        **출력 형식:**
        다음 JSON 형식으로만 응답해주세요. 다른 설명이나 텍스트는 포함하지 마세요.

        {
          "foods": [
            {
              "name": "음식 이름 (한국어)",
              "estimatedGrams": 210,
              "calories": 300,
              "carbohydrates": 65.0,
              "protein": 5.0,
              "fat": 1.0
            }
          ],
          "confidence": 0.85
        }

        **제약 조건:**
        - 모든 음식 이름은 한국어로 작성
        - 음식이 보이지 않으면 foods를 빈 배열로 반환
        - confidence는 0.0-1.0 범위 (인식 확실도)
        - 영양소 값은 소수점 1자리까지
        """
    }

    /// 음식 이미지 분석 응답 파싱
    private func parseFoodImageResponse(_ responseText: String) throws -> [GeminiFoodAnalysis] {
        let jsonText = extractJSON(from: responseText)

        guard let jsonData = jsonText.data(using: .utf8) else {
            throw GeminiServiceError.jsonParsingFailed
        }

        do {
            let response = try JSONDecoder().decode(GeminiFoodImageResponse.self, from: jsonData)
            return response.toDomainModels()
        } catch {
            throw GeminiServiceError.jsonParsingFailed
        }
    }

    /// AI 프롬프트 생성
    ///
    /// 📚 학습 포인트: Prompt Engineering for Korean Food Context
    /// 한국 음식 전문 영양사 역할로 구조화된 프롬프트 생성
    /// 💡 Java 비교: Template Method 패턴과 유사
    ///
    /// **프롬프트 구조:**
    /// 1. 역할 설정 (한국 음식 전문 영양사)
    /// 2. 컨텍스트 (식단 데이터, TDEE, 목표)
    /// 3. 분석 지침 (영양소 균형, TDEE 대비)
    /// 4. 출력 형식 (JSON)
    /// 5. 제약 조건 (한국어, 구체적 조언)
    ///
    /// - Parameters:
    ///   - foodRecords: 식단 기록 배열
    ///   - mealType: 끼니 종류
    ///   - goalType: 사용자 목표
    ///   - tdee: 활동대사량
    ///
    /// - Returns: 구조화된 AI 프롬프트
    private func buildPrompt(
        foodRecords: [FoodRecord],
        mealType: MealType?,
        goalType: GoalType,
        tdee: Int
    ) -> String {

        // 총 영양소 계산
        let totalCalories = foodRecords.reduce(0) { $0 + Int($1.calculatedCalories) }
        let totalCarbs = foodRecords.reduce(Decimal(0)) { $0 + ($1.calculatedCarbs?.decimalValue ?? 0) }
        let totalProtein = foodRecords.reduce(Decimal(0)) { $0 + ($1.calculatedProtein?.decimalValue ?? 0) }
        let totalFat = foodRecords.reduce(Decimal(0)) { $0 + ($1.calculatedFat?.decimalValue ?? 0) }

        // 끼니 이름
        let mealName = mealType?.displayName ?? "전체 식단"

        // 목표 설명
        let goalDescription = buildGoalDescription(goalType: goalType)

        // 목표 칼로리 계산
        let targetCalories = calculateTargetCalories(tdee: tdee, goalType: goalType)

        // 프롬프트 생성
        let prompt = """
        당신은 한국 음식에 정통한 전문 영양사입니다. 사용자의 식단을 분석하고 개선점을 제안해주세요.

        **사용자 정보:**
        - 목표: \(goalDescription)
        - 활동대사량(TDEE): \(tdee) kcal
        - 권장 섭취량: \(targetCalories) kcal

        **\(mealName) 섭취 내역:**
        - 총 칼로리: \(totalCalories) kcal
        - 탄수화물: \(totalCarbs)g
        - 단백질: \(totalProtein)g
        - 지방: \(totalFat)g

        **분석 지침:**
        1. 한국 음식의 특성(나트륨, 발효식품, 찬반 구성 등)을 고려하세요
        2. 사용자의 목표(\(goalType.displayName))에 맞는 조언을 제공하세요
        3. TDEE 대비 섭취량을 분석하세요
        4. 매크로 영양소 균형을 평가하세요
        5. 구체적이고 실행 가능한 개선점을 제안하세요

        **출력 형식:**
        다음 JSON 형식으로만 응답해주세요. 다른 설명이나 텍스트는 포함하지 마세요.

        {
          "goodPoints": ["좋은 점 1", "좋은 점 2", "좋은 점 3"],
          "improvements": ["개선점 1", "개선점 2", "개선점 3"],
          "summary": "전체 식단에 대한 한 줄 요약",
          "score": 7
        }

        **점수 기준:**
        - 8-10점: 우수 (목표에 맞고 영양 균형이 훌륭함)
        - 5-7점: 좋음 (적절하나 개선 여지 있음)
        - 0-4점: 개선 필요 (목표와 맞지 않거나 영양 불균형)

        **제약 조건:**
        - goodPoints, improvements는 각각 2-4개 항목
        - 모든 텍스트는 한국어로 작성
        - 구체적이고 실행 가능한 조언 제공
        - 긍정적이고 격려하는 톤 유지
        """

        return prompt
    }

    /// 목표 설명 생성
    ///
    /// - Parameter goalType: 사용자 목표 유형
    /// - Returns: 목표에 대한 설명
    private func buildGoalDescription(goalType: GoalType) -> String {
        switch goalType {
        case .lose:
            return "체중 감량 (칼로리 적자 필요)"
        case .maintain:
            return "체중 유지 (칼로리 균형 유지)"
        case .gain:
            return "체중 증량 (칼로리 잉여 필요)"
        }
    }

    /// 목표 칼로리 계산
    ///
    /// 📚 학습 포인트: Goal-Based Calorie Calculation
    /// 목표에 따라 권장 칼로리 섭취량 계산
    /// 💡 Java 비교: Strategy 패턴과 유사
    ///
    /// **칼로리 조정:**
    /// - 감량: TDEE - 500 kcal (주당 0.5kg 감량)
    /// - 유지: TDEE
    /// - 증량: TDEE + 300 kcal (주당 0.3kg 증량)
    ///
    /// - Parameters:
    ///   - tdee: 활동대사량
    ///   - goalType: 목표 유형
    ///
    /// - Returns: 목표 칼로리
    private func calculateTargetCalories(tdee: Int, goalType: GoalType) -> Int {
        switch goalType {
        case .lose:
            return tdee - 500  // 주당 약 0.5kg 감량
        case .maintain:
            return tdee
        case .gain:
            return tdee + 300  // 주당 약 0.3kg 증량
        }
    }

    /// AI 응답 파싱
    ///
    /// 📚 학습 포인트: JSON Response Parsing with Error Handling
    /// AI 응답에서 JSON 추출 및 구조화된 데이터로 변환
    /// 💡 Java 비교: Jackson ObjectMapper와 유사
    ///
    /// **파싱 전략:**
    /// 1. JSON 블록 추출 (```json ... ``` 또는 { ... })
    /// 2. JSONDecoder로 파싱
    /// 3. 데이터 유효성 검증
    /// 4. Fallback 처리 (파싱 실패 시)
    ///
    /// - Parameter responseText: AI 응답 텍스트
    ///
    /// - Returns: 파싱된 AI 응답 데이터
    ///
    /// - Throws: GeminiServiceError.jsonParsingFailed
    private func parseResponse(_ responseText: String) throws -> AIResponse {

        // JSON 블록 추출
        let jsonText = extractJSON(from: responseText)

        // JSON 파싱
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw GeminiServiceError.jsonParsingFailed
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(AIResponse.self, from: jsonData)

            // 데이터 유효성 검증
            guard response.isValid else {
                throw GeminiServiceError.invalidResponse("응답 데이터가 유효하지 않습니다.")
            }

            return response

        } catch {
            // 파싱 실패 시 fallback
            throw GeminiServiceError.jsonParsingFailed
        }
    }

    /// 응답 텍스트에서 JSON 블록 추출
    ///
    /// 📚 학습 포인트: Text Extraction with Pattern Matching
    /// AI 응답에서 JSON 형식의 텍스트만 추출
    /// 💡 Java 비교: 정규표현식 또는 String manipulation과 유사
    ///
    /// **추출 전략:**
    /// 1. ```json ... ``` 코드 블록 찾기
    /// 2. 없으면 { ... } JSON 객체 찾기
    /// 3. 없으면 전체 텍스트 반환
    ///
    /// - Parameter text: AI 응답 전체 텍스트
    ///
    /// - Returns: JSON 텍스트
    private func extractJSON(from text: String) -> String {

        // ```json ... ``` 형식 찾기
        if let jsonBlockRange = text.range(of: "```json", options: .caseInsensitive) {
            let startIndex = text.index(jsonBlockRange.upperBound, offsetBy: 0)
            if let endRange = text.range(of: "```", range: startIndex..<text.endIndex) {
                return String(text[startIndex..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // { ... } 형식 찾기
        if let openBrace = text.firstIndex(of: "{"),
           let closeBrace = text.lastIndex(of: "}") {
            return String(text[openBrace...closeBrace])
        }

        // 전체 텍스트 반환
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - AIResponse Model

/// AI 응답 구조
///
/// 📚 학습 포인트: Response DTO for JSON Parsing
/// Gemini API의 JSON 응답을 파싱하기 위한 구조체
/// 💡 Java 비교: Response DTO 클래스와 유사
private struct AIResponse: Codable {
    let goodPoints: [String]
    let improvements: [String]
    let summary: String
    let score: Int

    /// 응답 데이터 유효성 검증
    ///
    /// - Returns: 유효하면 true
    var isValid: Bool {
        // goodPoints와 improvements가 각각 1개 이상
        guard !goodPoints.isEmpty, !improvements.isEmpty else {
            return false
        }

        // summary가 비어있지 않음
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // score가 0-10 범위
        guard score >= 0 && score <= 10 else {
            return false
        }

        return true
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock GeminiService
///
/// 📚 학습 포인트: Mock Service for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockGeminiService: GeminiServiceProtocol {

    /// Mock 응답 데이터
    var mockComment: DietComment?

    /// Mock 음식 분석 결과
    var mockFoodAnalysis: [GeminiFoodAnalysis] = []

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    func generateDietComment(
        foodRecords: [FoodRecord],
        mealType: MealType?,
        userId: UUID,
        date: Date,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment {

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 응답 반환
        guard let comment = mockComment else {
            throw GeminiServiceError.emptyFoodRecords
        }

        return comment
    }

    func analyzeFoodImage(_ image: UIImage) async throws -> [GeminiFoodAnalysis] {
        if let error = shouldThrowError {
            throw error
        }
        return mockFoodAnalysis
    }
}
#endif

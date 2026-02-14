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
        tdee: Int,
        targetCalories: Int
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
            tdee: tdee,
            targetCalories: targetCalories
        )

        // 3. Gemini API 호출
        do {
            let responseText = try await geminiAPIService.generateText(
                prompt: prompt,
                temperature: 0.7,
                maxOutputTokens: 2048
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

    // MARK: - Home Coaching

    func generateHomeCoaching(context: HomeCoachingContext) async throws -> String {
        let prompt = buildHomeCoachingPrompt(context: context)

        do {
            let responseText = try await geminiAPIService.generateText(
                prompt: prompt,
                temperature: 0.7,
                maxOutputTokens: 256
            )

            guard let text = responseText else {
                throw GeminiServiceError.invalidResponse("AI 응답이 비어있습니다.")
            }

            // JSON에서 coaching 필드 추출
            let jsonText = extractJSON(from: text)
            if let jsonData = jsonText.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let coaching = json["coaching"] as? String,
               !coaching.isEmpty {
                return coaching
            }

            // JSON 파싱 실패 시 원문 텍스트에서 추출 시도
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty && cleaned.count < 200 {
                return cleaned
            }

            throw GeminiServiceError.jsonParsingFailed
        } catch let error as GeminiServiceError {
            throw error
        } catch {
            throw GeminiServiceError.apiError(error)
        }
    }

    /// 홈 코칭 프롬프트 생성
    private func buildHomeCoachingPrompt(context: HomeCoachingContext) -> String {
        // 시간대 설명
        let timeOfDay: String
        switch context.currentHour {
        case 8..<12: timeOfDay = "오전"
        case 12..<14: timeOfDay = "점심"
        case 14..<18: timeOfDay = "오후"
        case 18..<22: timeOfDay = "저녁"
        default: timeOfDay = "밤"
        }

        // 수면 정보
        var sleepSection = "수면 기록 없음"
        if let duration = context.sleepDurationMinutes {
            let hours = duration / 60
            let mins = duration % 60
            let statusText = context.sleepStatus?.displayName ?? "알 수 없음"
            sleepSection = "\(hours)시간 \(mins)분 (\(statusText))"
        }

        // 식단 정보
        let dietSection: String
        if context.mealCount > 0 {
            dietSection = "\(context.intakeCalories)kcal (끼니 \(context.mealCount)회, 탄 \(Int(context.totalCarbs))g / 단 \(Int(context.totalProtein))g / 지 \(Int(context.totalFat))g)"
        } else {
            dietSection = "기록 없음"
        }

        // 운동 정보
        let exerciseSection: String
        if context.exerciseCount > 0 {
            let names = context.exerciseNames.prefix(3).joined(separator: ", ")
            exerciseSection = "\(context.exerciseCalories)kcal 소모 (\(names))"
        } else {
            exerciseSection = "기록 없음"
        }

        // 체성분 트렌드
        var bodySection = "체성분 기록 없음"
        if let weight = context.currentWeight {
            var parts = [String(format: "현재 체중 %.1fkg", weight)]
            if let change = context.weightChange30d {
                let sign = change >= 0 ? "+" : ""
                parts.append(String(format: "30일 변화 %@%.1fkg", sign, change))
            }
            if let fat = context.currentBodyFat, fat > 0 {
                parts.append(String(format: "체지방률 %.1f%%", fat))
                if let fatChange = context.bodyFatChange30d {
                    let sign = fatChange >= 0 ? "+" : ""
                    parts.append(String(format: "30일 변화 %@%.1f%%p", sign, fatChange))
                }
            }
            bodySection = parts.joined(separator: ", ")
        }

        // 최근 7일 체성분 개별 데이터
        var recentBodySection = ""
        if !context.recentBodyEntries.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d"
            let lines = context.recentBodyEntries.map { entry -> String in
                let dateStr = dateFormatter.string(from: entry.date)
                if let fat = entry.bodyFat {
                    return String(format: "  %@: %.1fkg, 체지방 %.1f%%", dateStr, entry.weight, fat)
                } else {
                    return String(format: "  %@: %.1fkg", dateStr, entry.weight)
                }
            }
            recentBodySection = "\n**최근 7일 체성분 기록:**\n" + lines.joined(separator: "\n")
        }

        // 목표 설명
        let goalDesc = buildGoalDescription(goalType: context.goalType)

        // 목표 모드 컨텍스트
        var goalModeSection = ""
        var goalModeToneGuide = ""
        if context.isGoalModeActive {
            var goalModeParts: [String] = []
            if let dDay = context.dDay {
                goalModeParts.append("D-Day: D-\(dDay)")
            }
            if let urgency = context.goalUrgency {
                goalModeParts.append("긴박도: \(urgency.displayName)")
            }
            if let progress = context.periodProgressPercent {
                goalModeParts.append(String(format: "기간 진행률: %.0f%%", progress))
            }
            var targetParts: [String] = []
            if let tw = context.targetWeight { targetParts.append(String(format: "체중 %.1fkg", tw)) }
            if let tf = context.targetBodyFat { targetParts.append(String(format: "체지방 %.1f%%", tf)) }
            if let tm = context.targetMuscle { targetParts.append(String(format: "근육량 %.1fkg", tm)) }
            if !targetParts.isEmpty {
                goalModeParts.append("목표값: \(targetParts.joined(separator: ", "))")
            }
            goalModeSection = "\n**[목표 모드 활성]** \(goalModeParts.joined(separator: " | "))"

            // 긴박도별 톤 가이드
            switch context.goalUrgency {
            case .relaxed:
                goalModeToneGuide = "\n- 톤: 격려하고 장기 관점에서 조언. 차분하고 안정적인 어조."
            case .steady:
                goalModeToneGuide = "\n- 톤: 집중하되 부담 없이. 구체적 실천 제안."
            case .intense:
                goalModeToneGuide = "\n- 톤: 적극적 동기 부여. 구체적 행동 제안과 D-Day 언급."
            case .critical:
                goalModeToneGuide = "\n- 톤: 긴급하지만 긍정적. 마지막 스퍼트 독려. D-Day 강조."
            case .none:
                break
            }
        }

        return """
        당신은 전문 건강 코치입니다. 사용자의 오늘 건강 데이터를 보고 시간대에 맞는 한마디 코칭을 해주세요.

        **현재 시간대:** \(timeOfDay) (\(context.currentHour)시)
        **목표:** \(goalDesc)
        **TDEE:** \(context.tdee)kcal / 목표 섭취: \(context.targetCalories)kcal
        \(goalModeSection)
        **체성분 트렌드:** \(bodySection)\(recentBodySection)
        **오늘의 수면:** \(sleepSection)
        **오늘의 식단:** \(dietSection)
        **오늘의 운동:** \(exerciseSection)

        **코칭 지침:**
        - 시간대에 맞는 실용적 조언 1-2문장 (예: 아침이면 오늘 계획, 저녁이면 하루 총평)
        - 기록된 데이터 기반으로 구체적으로 언급 (체성분 변화 추세도 반영)
        - 데이터가 없는 항목은 기록을 독려\(goalModeToneGuide)
        - 격려하는 톤, 한국어, 반말 금지
        - 이모지 1개만 앞에 사용

        **출력 형식 (JSON만 응답):**
        {"coaching": "이모지 + 코칭 메시지"}
        """
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
        tdee: Int,
        targetCalories: Int
    ) -> String {

        // 현재 날짜/시간
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 d일 (E) HH:mm"
        let nowString = dateFormatter.string(from: Date())

        // 목표 설명
        let goalDescription = buildGoalDescription(goalType: goalType)

        // 끼니별 음식 목록 구성
        let mealSection = buildMealSection(foodRecords: foodRecords, mealType: mealType)

        // 총 영양소 계산 (매크로 + 미량 영양소)
        let totalCalories = foodRecords.reduce(0) { $0 + Int($1.calculatedCalories) }
        let totalCarbs = foodRecords.reduce(Decimal(0)) { $0 + ($1.calculatedCarbs?.decimalValue ?? 0) }
        let totalProtein = foodRecords.reduce(Decimal(0)) { $0 + ($1.calculatedProtein?.decimalValue ?? 0) }
        let totalFat = foodRecords.reduce(Decimal(0)) { $0 + ($1.calculatedFat?.decimalValue ?? 0) }

        // 미량 영양소
        let totalSodium = foodRecords.reduce(Decimal(0)) { $0 + ($1.food?.sodium?.decimalValue ?? 0) }
        let totalFiber = foodRecords.reduce(Decimal(0)) { $0 + ($1.food?.fiber?.decimalValue ?? 0) }
        let totalSugar = foodRecords.reduce(Decimal(0)) { $0 + ($1.food?.sugar?.decimalValue ?? 0) }

        // 끼니별 칼로리 분배 계산
        let allMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        var mealCalorieBreakdown: [String] = []
        for meal in allMealTypes {
            let mealCals = foodRecords
                .filter { $0.mealType == Int16(meal.rawValue) }
                .reduce(0) { $0 + Int($1.calculatedCalories) }
            if mealCals > 0 {
                let percentage = totalCalories > 0 ? Int(Double(mealCals) / Double(totalCalories) * 100) : 0
                mealCalorieBreakdown.append("- \(meal.displayName): \(mealCals) kcal (\(percentage)%)")
            }
        }
        let mealBreakdownText = mealCalorieBreakdown.isEmpty ? "없음" : mealCalorieBreakdown.joined(separator: "\n")

        // 현재 시간 컴포넌트 (시간대별 평가용)
        let currentHour = Calendar.current.component(.hour, from: Date())

        // 시간대별 평가 지침
        let timeBasedGuideline: String
        if currentHour < 10 {
            timeBasedGuideline = """
            현재 아침 시간입니다. 아직 하루가 시작되었으므로 기록된 식사만으로 판단하되, \
            아침 식사의 영양 균형을 중점 평가하세요. 아직 기록되지 않은 끼니는 이후에 먹을 수 있으므로 \
            총 칼로리 부족에 대해 감점하지 마세요.
            """
        } else if currentHour < 14 {
            timeBasedGuideline = """
            현재 점심 시간대입니다. 아침과 점심 기록을 중심으로 평가하세요. \
            아직 저녁 식사를 하지 않았을 수 있으므로 총 칼로리 부족에 대해 크게 감점하지 마세요. \
            다만 아침을 거른 경우 개선점으로 언급해도 좋습니다.
            """
        } else if currentHour < 18 {
            timeBasedGuideline = """
            현재 오후 시간입니다. 아침과 점심 기록을 중심으로 평가하되, \
            저녁 식사를 아직 하지 않았을 수 있습니다. \
            현재까지 섭취량이 권장량의 50% 미만이면 개선점으로 언급하세요.
            """
        } else if currentHour < 21 {
            timeBasedGuideline = """
            현재 저녁 시간입니다. 하루 대부분의 식사가 완료되었을 것으로 판단합니다. \
            총 칼로리가 권장량에 크게 부족하거나 초과하면 엄격하게 평가하세요. \
            끼니를 거른 경우 감점 요소입니다.
            """
        } else {
            timeBasedGuideline = """
            현재 밤 시간입니다. 하루 식사가 거의 완료되었으므로 엄격하게 평가하세요. \
            총 칼로리와 영양소 균형을 종합적으로 판단하세요. \
            야식이 포함된 경우 체중 관리 관점에서 개선점을 제안하세요.
            """
        }

        // 프롬프트 생성
        let prompt = """
        당신은 한국 음식 및 세계 음식에 정통한 전문 영양사입니다. 사용자의 식단을 분석하고 개선점을 제안해주세요.

        **현재 시간:** \(nowString)
        \(timeBasedGuideline)

        **사용자 정보:**
        - 목표: \(goalDescription)
        - 활동대사량(TDEE): \(tdee) kcal
        - 하루 권장 섭취량: \(targetCalories) kcal

        **섭취 내역:**
        \(mealSection)

        **매크로 합계:** \(totalCalories) kcal (탄수화물 \(totalCarbs)g / 단백질 \(totalProtein)g / 지방 \(totalFat)g)

        **미량 영양소 합계:**
        - 나트륨: \(totalSodium)mg (권장 2000mg 이하)
        - 식이섬유: \(totalFiber)g (권장 25-30g)
        - 당류: \(totalSugar)g (권장 50g 이하)

        **끼니별 칼로리 분배:**
        \(mealBreakdownText)
        이상적 분배: 아침 20-25% / 점심 35-40% / 저녁 30-35% / 간식 5-10%

        **분석 지침:**
        1. 음식의 특성(나트륨, 발효식품, 영양 구성 등)을 고려하세요
        2. 사용자의 목표(\(goalType.displayName))에 맞는 조언을 제공하세요
        3. 하루 권장 섭취량(\(targetCalories) kcal) 대비 현재 섭취량을 분석하세요
        4. 매크로 영양소(탄수화물/단백질/지방) 균형을 평가하세요
        5. 끼니별 칼로리 분배가 적절한지 평가하세요 (한 끼에 몰아먹기 주의)
        6. 나트륨, 식이섬유, 당류 섭취량을 평가하세요
        7. 구체적인 음식명을 언급하며 실행 가능한 개선점을 제안하세요

        **출력 형식:**
        다음 JSON 형식으로만 응답해주세요. 다른 설명이나 텍스트는 포함하지 마세요.

        {
          "goodPoints": ["좋은 점 1", "좋은 점 2"],
          "improvements": ["개선점 1", "개선점 2"],
          "summary": "전체 식단에 대한 2-3줄 총평",
          "score": 7
        }

        **점수 기준 (매우 까다롭게 적용 — 9점 이상은 정말 뛰어난 식단에만 부여):**
        - 9-10점: 매우 좋음 — 권장 칼로리 ±5% 이내, 3대 영양소 균형 완벽, 나트륨/식이섬유/당류 모두 적정, 끼니 분배 균등
        - 8점: 좋음 — 권장 칼로리 ±10% 이내, 영양소 대체로 균형, 사소한 개선점 1-2개
        - 6-7점: 보통 — 칼로리 ±20% 이내이나 일부 영양소 불균형, 또는 끼니 분배 치우침
        - 4-5점: 미흡 — 칼로리 ±30% 이상 편차, 또는 2개 이상 영양소 심각한 불균형
        - 0-3점: 매우 부족 — 끼니 대부분 누락, 극단적 칼로리 과잉/부족, 또는 영양소 극도 편향

        **제약 조건:**
        - goodPoints, improvements는 각각 2-4개 항목
        - 모든 텍스트는 한국어로 작성
        - 구체적이고 실행 가능한 조언 제공
        - 긍정적이고 격려하는 톤 유지하되, 점수는 엄격하게
        """

        return prompt
    }

    /// 끼니별 음식 목록 구성
    private func buildMealSection(foodRecords: [FoodRecord], mealType: MealType?) -> String {
        if let mealType = mealType {
            // 특정 끼니만 요청된 경우
            let foods = foodRecords.map { formatFoodRecord($0) }.joined(separator: "\n")
            return "**\(mealType.displayName):**\n\(foods)"
        } else {
            // 하루 전체 — 끼니별로 그룹핑
            var sections: [String] = []
            let allMealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]

            for meal in allMealTypes {
                let records = foodRecords.filter { $0.mealType == Int16(meal.rawValue) }
                guard !records.isEmpty else { continue }
                let foods = records.map { formatFoodRecord($0) }.joined(separator: "\n")
                sections.append("**\(meal.displayName):**\n\(foods)")
            }

            return sections.joined(separator: "\n\n")
        }
    }

    /// 개별 음식 기록 포맷
    private func formatFoodRecord(_ record: FoodRecord) -> String {
        let name = record.food?.name ?? "알 수 없는 음식"
        let cal = record.calculatedCalories
        return "- \(name) \(cal)kcal"
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
        tdee: Int,
        targetCalories: Int
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

    /// Mock 홈 코칭 메시지
    var mockHomeCoaching: String = "🌟 오늘도 건강한 하루 보내세요!"

    func generateHomeCoaching(context: HomeCoachingContext) async throws -> String {
        if let error = shouldThrowError {
            throw error
        }
        return mockHomeCoaching
    }

    func analyzeFoodImage(_ image: UIImage) async throws -> [GeminiFoodAnalysis] {
        if let error = shouldThrowError {
            throw error
        }
        return mockFoodAnalysis
    }
}
#endif

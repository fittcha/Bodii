//
//  GeminiFoodAnalysis.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-29.
//

import Foundation

/// Gemini AI가 사진에서 인식한 개별 음식 정보
///
/// Gemini Multimodal API의 이미지 분석 결과로 반환되는 음식 데이터입니다.
/// 음식명, 추정 중량(g), 칼로리, 3대 영양소 정보를 포함합니다.
struct GeminiFoodAnalysis: Identifiable, Equatable, Hashable {

    /// 고유 ID
    let id: UUID

    /// 음식 이름 (한국어)
    let name: String

    /// 추정 중량 (g)
    let estimatedGrams: Double

    /// 추정 칼로리 (kcal)
    let calories: Double

    /// 탄수화물 (g)
    let carbohydrates: Double

    /// 단백질 (g)
    let protein: Double

    /// 지방 (g)
    let fat: Double
}

/// Gemini 음식 이미지 분석 API 응답
///
/// Gemini API의 JSON 응답을 파싱하기 위한 구조체입니다.
struct GeminiFoodImageResponse: Codable {

    /// 인식된 음식 목록
    let foods: [FoodItem]

    /// AI 분석 신뢰도 (0.0-1.0)
    let confidence: Double

    /// JSON 파싱용 개별 음식 항목
    struct FoodItem: Codable {
        let name: String
        let estimatedGrams: Double
        let calories: Double
        let carbohydrates: Double
        let protein: Double
        let fat: Double
    }

    /// GeminiFoodAnalysis 도메인 모델로 변환
    func toDomainModels() -> [GeminiFoodAnalysis] {
        return foods.map { item in
            GeminiFoodAnalysis(
                id: UUID(),
                name: item.name,
                estimatedGrams: item.estimatedGrams,
                calories: item.calories,
                carbohydrates: item.carbohydrates,
                protein: item.protein,
                fat: item.fat
            )
        }
    }
}

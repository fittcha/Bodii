//
//  NutritionSummaryCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Nutrition Summary Card Component
// 일일 영양 요약 카드 컴포넌트
// 💡 칼로리, 매크로 영양소, 비율을 시각적으로 표시

import SwiftUI

/// 일일 영양 요약 카드
///
/// 총 섭취 칼로리, 남은 칼로리, 매크로 영양소 비율을 표시합니다.
///
/// - Note: DailyLog의 데이터를 기반으로 렌더링됩니다.
/// - Note: 매크로 비율을 원형 차트로 시각화합니다.
///
/// - Example:
/// ```swift
/// NutritionSummaryCard(
///     dailyLog: dailyLog,
///     remainingCalories: 810,
///     calorieIntakePercentage: 65.0
/// )
/// ```
struct NutritionSummaryCard: View {

    // MARK: - Properties

    /// 일일 기록
    let dailyLog: DailyLog

    /// 목표 칼로리 (목표 섭취량 또는 TDEE)
    let targetCalories: Int32

    /// 남은 칼로리 (kcal)
    let remainingCalories: Int32

    /// 칼로리 섭취 비율 (%)
    let calorieIntakePercentage: Double

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 칼로리 섹션
            caloriesSection

            Divider()

            // 매크로 영양소 섹션
            macrosSection
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// 칼로리 섹션
    ///
    /// 총 섭취 칼로리, TDEE, 진행률, 남은 칼로리를 표시합니다.
    private var caloriesSection: some View {
        VStack(spacing: 12) {
            // 제목
            Text("일일 칼로리")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 칼로리 표시
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(dailyLog.totalCaloriesIn)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)

                Text("/ \(targetCalories) kcal")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // 진행 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)

                    // 진행률
                    Rectangle()
                        .fill(calorieColor)
                        .frame(
                            width: min(
                                geometry.size.width * CGFloat(calorieIntakePercentage / 100),
                                geometry.size.width
                            ),
                            height: 8
                        )
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            // 남은 칼로리
            HStack {
                Text("남은 칼로리")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(remainingCalories) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(remainingCalories >= 0 ? .green : .red)
            }
        }
    }

    /// 매크로 영양소 섹션
    ///
    /// 탄수화물, 단백질, 지방의 섭취량과 비율을 표시합니다.
    /// 원형 차트로 비율을 시각화합니다.
    private var macrosSection: some View {
        VStack(spacing: 12) {
            // 제목
            Text("매크로 영양소")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                // 매크로 차트
                MacroRatioChart(
                    carbsRatio: dailyLog.carbsRatio as Decimal?,
                    proteinRatio: dailyLog.proteinRatio as Decimal?,
                    fatRatio: dailyLog.fatRatio as Decimal?,
                    size: 100
                )

                // 영양소 목록
                VStack(spacing: 8) {
                    macroItem(
                        name: "탄수화물",
                        amount: (dailyLog.totalCarbs as? Decimal) ?? Decimal.zero,
                        ratio: dailyLog.carbsRatio as Decimal?,
                        color: .blue
                    )

                    macroItem(
                        name: "단백질",
                        amount: (dailyLog.totalProtein as? Decimal) ?? Decimal.zero,
                        ratio: dailyLog.proteinRatio as Decimal?,
                        color: .orange
                    )

                    macroItem(
                        name: "지방",
                        amount: (dailyLog.totalFat as? Decimal) ?? Decimal.zero,
                        ratio: dailyLog.fatRatio as Decimal?,
                        color: .purple
                    )
                }
            }
        }
    }

    /// 매크로 영양소 아이템
    ///
    /// 개별 매크로 영양소의 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - name: 영양소 이름
    ///   - amount: 섭취량 (g)
    ///   - ratio: 비율 (%)
    ///   - color: 색상
    /// - Returns: 매크로 아이템 뷰
    private func macroItem(name: String, amount: Decimal, ratio: Decimal?, color: Color) -> some View {
        HStack(spacing: 8) {
            // 색상 인디케이터
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            // 영양소 이름
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            // 섭취량
            Text("\(formattedDecimal(amount))g")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 45, alignment: .trailing)

            // 비율 (있는 경우)
            if let ratio = ratio {
                Text("\(formattedDecimal(ratio))%")
                    .font(.caption)
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .cornerRadius(4)
                    .frame(width: 50, alignment: .center)
            } else {
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .center)
            }
        }
    }

    // MARK: - Helpers

    /// 칼로리 진행률에 따른 색상
    ///
    /// 섭취 비율에 따라 적절한 색상을 반환합니다.
    /// - < 50%: 파란색 (부족)
    /// - 50-90%: 초록색 (양호)
    /// - 90-110%: 주황색 (적정)
    /// - > 110%: 빨간색 (초과)
    ///
    /// - Returns: 진행률 색상
    private var calorieColor: Color {
        if calorieIntakePercentage < 50 {
            return .blue
        } else if calorieIntakePercentage < 90 {
            return .green
        } else if calorieIntakePercentage <= 110 {
            return .orange
        } else {
            return .red
        }
    }

    /// Decimal 값을 포맷팅
    ///
    /// Decimal 값을 소수점 첫째 자리까지 표시하는 문자열로 변환합니다.
    ///
    /// - Parameter value: 포맷팅할 Decimal 값
    /// - Returns: 포맷팅된 문자열
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: nsDecimal) ?? "0"
    }
}

// MARK: - Preview
// Preview는 Core Data 엔티티 초기화 문제로 인해 임시 비활성화
// TODO: PreviewHelpers를 사용한 Preview 구현 필요

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// DailyLog는 Core Data 엔티티이므로 struct처럼 초기화 불가
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("NutritionSummaryCard Preview")
        .font(.headline)
        .padding()
        .background(Color(.systemGroupedBackground))
}

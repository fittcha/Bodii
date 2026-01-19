//
//  FoodMatchCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Food Match Card Component
// AI 인식 결과의 각 음식 매칭을 표시하는 카드 컴포넌트
// 💡 신뢰도, 음식 정보, 선택 상태를 포함한 인터랙티브 카드

import SwiftUI

/// 음식 매칭 카드 뷰
///
/// AI가 인식한 음식 매칭 결과를 카드 형태로 표시합니다.
///
/// **주요 기능:**
/// - 신뢰도 점수 표시 (백분율)
/// - 음식 정보 (이름, 칼로리, 매크로)
/// - 체크박스로 포함/제외 선택
/// - 스와이프하여 삭제
///
/// - Note: FoodMatch 모델을 기반으로 UI를 구성합니다.
/// - Note: 신뢰도가 70% 이상이면 하이라이트 표시합니다.
///
/// - Example:
/// ```swift
/// FoodMatchCard(
///     match: foodMatch,
///     isSelected: true,
///     onToggleSelection: { isSelected in
///         // 선택 상태 변경 처리
///     },
///     onTap: {
///         // 카드 탭 처리 (상세 편집)
///     }
/// )
/// ```
struct FoodMatchCard: View {

    // MARK: - Properties

    /// 음식 매칭 정보
    let match: FoodMatch

    /// 선택 여부
    let isSelected: Bool

    /// 선택 토글 콜백
    let onToggleSelection: (Bool) -> Void

    /// 카드 탭 콜백 (상세 편집으로 이동)
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 선택 체크박스
                Button(action: {
                    onToggleSelection(!isSelected)
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())

                // 음식 정보
                VStack(alignment: .leading, spacing: 6) {
                    // 음식 이름과 신뢰도
                    HStack(spacing: 8) {
                        Text(match.food.name ?? "알 수 없는 음식")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Spacer()

                        // 신뢰도 배지
                        confidenceBadge
                    }

                    // 인식된 라벨 (Vision API 결과)
                    if !match.label.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.viewfinder")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("인식: \(match.label)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // 1회 제공량 정보
                    Text(servingSizeText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 칼로리와 매크로 미리보기
                    HStack(spacing: 12) {
                        // 칼로리
                        HStack(spacing: 4) {
                            Text("\(match.food.calories)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("kcal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // 매크로 미리보기 (P/C/F)
                        HStack(spacing: 6) {
                            macroPreview("P", value: match.food.protein?.decimalValue ?? Decimal(0), color: .orange)
                            macroPreview("C", value: match.food.carbohydrates?.decimalValue ?? Decimal(0), color: .blue)
                            macroPreview("F", value: match.food.fat?.decimalValue ?? Decimal(0), color: .purple)
                        }
                    }
                }

                // 네비게이션 아이콘
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? Color.blue.opacity(0.5)
                            : (match.isHighConfidence ? Color.green.opacity(0.3) : Color.clear),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Subviews

    /// 신뢰도 배지
    ///
    /// 신뢰도 점수를 백분율로 표시하는 배지입니다.
    ///
    /// 📚 학습 포인트: Confidence-based Color Coding
    /// - 70% 이상: 녹색 (높은 신뢰도)
    /// - 50-69%: 주황색 (중간 신뢰도)
    /// - 50% 미만: 회색 (낮은 신뢰도)
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption2)

            Text("\(match.confidencePercentage)%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(confidenceColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.15))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    /// 신뢰도에 따른 색상
    private var confidenceColor: Color {
        if match.confidence >= 0.7 {
            return .green
        } else if match.confidence >= 0.5 {
            return .orange
        } else {
            return .gray
        }
    }

    /// 신뢰도에 따른 아이콘
    private var confidenceIcon: String {
        if match.confidence >= 0.7 {
            return "checkmark.circle.fill"
        } else if match.confidence >= 0.5 {
            return "exclamationmark.circle.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }

    /// 1회 제공량 텍스트
    private var servingSizeText: String {
        let size = match.food.servingSize?.decimalValue ?? Decimal(100)
        let sizeString = formattedDecimal(size)

        if let unit = match.food.servingUnit {
            return "\(unit) (\(sizeString)g)"
        } else {
            return "\(sizeString)g"
        }
    }

    // MARK: - Helpers

    /// 매크로 영양소 미리보기
    ///
    /// 매크로 영양소의 짧은 정보를 표시합니다.
    ///
    /// - Parameters:
    ///   - label: 영양소 레이블 (P/C/F)
    ///   - value: 영양소 값 (g)
    ///   - color: 표시 색상
    /// - Returns: 매크로 미리보기 뷰
    private func macroPreview(_ label: String, value: Decimal, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(formattedDecimal(value))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
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

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// FoodMatch는 Core Data Food 엔티티를 참조하므로 직접 초기화 불가
// VisionLabel도 mid 파라미터가 필요하며 구조가 복잡함
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("FoodMatchCard Preview")
        .font(.headline)
        .padding()
        .background(Color(.systemGroupedBackground))
}

//
//  WeeklyRatePicker.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Weekly Rate Picker Component
// 주간 변화율 선택 컴포넌트 - 프리셋 버튼과 커스텀 입력
// 💡 빠른 선택을 위한 프리셋 버튼과 정확한 입력을 위한 커스텀 필드 제공

import SwiftUI

// MARK: - Weekly Rate Picker

/// 주간 변화율 선택 컴포넌트
///
/// 프리셋 변화율 버튼과 커스텀 입력 필드를 제공하는 재사용 가능한 컴포넌트입니다.
///
/// **주요 기능:**
/// - 프리셋 변화율 버튼 (빠른 선택)
/// - 커스텀 입력 필드 (정확한 값 입력)
/// - 목표 유형에 따른 권장 변화율 표시
/// - 인라인 검증 에러 표시
///
/// **프리셋 값 예시:**
/// - 체중: [-1.0, -0.5, 0.0, +0.5, +1.0] kg/week
/// - 체지방률: [-1.0, -0.5, 0.0] %/week
/// - 근육량: [0.0, +0.2, +0.5] kg/week
///
/// - Example:
/// ```swift
/// WeeklyRatePicker(
///     selectedRate: $viewModel.weeklyWeightRateInput,
///     unit: "kg/주",
///     presetRates: [-1.0, -0.5, 0.0, 0.5, 1.0],
///     recommendedRange: "±2kg/week 이내",
///     error: viewModel.validationErrors.weeklyWeightRate,
///     onSelectRate: { rate in
///         viewModel.selectWeeklyRate(rate)
///     }
/// )
/// ```
struct WeeklyRatePicker: View {

    // MARK: - Properties

    // 📚 학습 포인트: @Binding for Two-Way Data Flow
    // 부모 View와 양방향 데이터 동기화

    /// 선택된 변화율 (String - 사용자 입력 그대로)
    @Binding var selectedRate: String

    /// 변화율 단위 (예: "kg/주", "%/주")
    let unit: String

    /// 프리셋 변화율 목록
    let presetRates: [Decimal]

    /// 권장 범위 힌트 (예: "±2kg/week 이내")
    let recommendedRange: String

    /// 검증 에러 메시지
    let error: String?

    /// 프리셋 변화율 선택 시 호출되는 콜백
    let onSelectRate: ((Decimal) -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 프리셋 버튼 섹션
            presetButtonsSection

            Divider()

            // 커스텀 입력 섹션
            customInputSection

            // 권장 범위 힌트
            recommendedRangeHint
        }
    }

    // MARK: - View Components

    /// 프리셋 변화율 버튼 섹션
    ///
    /// 빠른 선택을 위한 프리셋 변화율 버튼들을 표시합니다.
    @ViewBuilder
    private var presetButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("빠른 선택")
                .font(.caption)
                .foregroundStyle(.secondary)

            // 📚 학습 포인트: ScrollView for Many Buttons
            // 버튼이 많을 경우 가로 스크롤 가능하도록
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presetRates, id: \.self) { rate in
                        presetButton(rate: rate)
                    }
                }
            }
        }
    }

    /// 커스텀 입력 섹션
    ///
    /// 직접 입력을 위한 텍스트 필드를 표시합니다.
    @ViewBuilder
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("직접 입력")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                // 변화율 입력 필드
                TextField("예: -0.5", text: $selectedRate)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )

                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)
            }

            // 검증 에러 메시지
            if let error = error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)

                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            }
        }
    }

    /// 권장 범위 힌트
    @ViewBuilder
    private var recommendedRangeHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(recommendedRange)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 프리셋 변화율 버튼
    ///
    /// 빠른 선택을 위한 프리셋 변화율 버튼입니다.
    ///
    /// - Parameter rate: 변화율 값
    /// - Returns: 프리셋 버튼 뷰
    @ViewBuilder
    private func presetButton(rate: Decimal) -> some View {
        let isSelected = selectedRate == formatRate(rate)

        Button(action: {
            handleRateSelection(rate)
        }) {
            VStack(spacing: 4) {
                // 변화율 값
                Text(formatRateWithSign(rate))
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)

                // 단위
                Text(unit)
                    .font(.caption2)
            }
            .foregroundStyle(
                isSelected ? .white : rateColor(rate)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? rateColor(rate)
                            : Color(.systemGray5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    /// 변화율 선택 처리
    ///
    /// - Parameter rate: 선택된 변화율
    private func handleRateSelection(_ rate: Decimal) {
        // 📚 학습 포인트: Haptic Feedback
        // 사용자 인터랙션에 촉각 피드백 제공
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // 선택된 변화율 업데이트
        selectedRate = formatRate(rate)

        // 콜백 실행 (있는 경우)
        onSelectRate?(rate)
    }

    // MARK: - Helpers

    /// 변화율 값을 부호와 함께 포맷팅
    ///
    /// - Parameter rate: 변화율 값
    /// - Returns: 부호가 포함된 문자열 (예: "+0.5", "-0.5", "0.0")
    private func formatRateWithSign(_ rate: Decimal) -> String {
        let formatted = formatRate(rate)
        if rate > 0 {
            return "+\(formatted)"
        } else {
            return formatted
        }
    }

    /// 변화율 값을 포맷팅
    ///
    /// - Parameter rate: 변화율 값
    /// - Returns: 포맷팅된 문자열
    private func formatRate(_ rate: Decimal) -> String {
        let nsDecimal = rate as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsDecimal) ?? "0.0"
    }

    /// 변화율에 따른 색상
    ///
    /// - Parameter rate: 변화율 값
    /// - Returns: 변화율의 의미에 맞는 색상
    ///   - 감소 (음수): 파란색
    ///   - 유지 (0): 녹색
    ///   - 증가 (양수): 주황색
    private func rateColor(_ rate: Decimal) -> Color {
        if rate < 0 {
            return .blue  // 감소 (체중/체지방 감량)
        } else if rate > 0 {
            return .orange  // 증가 (체중/근육 증가)
        } else {
            return .green  // 유지
        }
    }
}

// MARK: - Preview

#Preview("Weekly Rate Picker - Weight Loss") {
    struct PreviewWrapper: View {
        @State private var selectedRate = "-0.5"

        var body: some View {
            VStack(spacing: 20) {
                Text("체중 변화율 선택")
                    .font(.headline)

                WeeklyRatePicker(
                    selectedRate: $selectedRate,
                    unit: "kg/주",
                    presetRates: [-1.0, -0.5, 0.0, 0.5, 1.0],
                    recommendedRange: "권장: ±2kg/week 이내",
                    error: nil,
                    onSelectRate: { rate in
                        print("Selected rate: \(rate)")
                    }
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .padding()

                Text("선택된 변화율: \(selectedRate) kg/주")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Weekly Rate Picker - Body Fat") {
    struct PreviewWrapper: View {
        @State private var selectedRate = "-0.5"

        var body: some View {
            VStack(spacing: 20) {
                Text("체지방률 변화율 선택")
                    .font(.headline)

                WeeklyRatePicker(
                    selectedRate: $selectedRate,
                    unit: "%/주",
                    presetRates: [-1.0, -0.5, 0.0],
                    recommendedRange: "권장: ±3%/week 이내",
                    error: nil,
                    onSelectRate: { rate in
                        print("Selected rate: \(rate)")
                    }
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .padding()

                Text("선택된 변화율: \(selectedRate) %/주")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Weekly Rate Picker - Muscle Gain") {
    struct PreviewWrapper: View {
        @State private var selectedRate = "0.2"

        var body: some View {
            VStack(spacing: 20) {
                Text("근육량 변화율 선택")
                    .font(.headline)

                WeeklyRatePicker(
                    selectedRate: $selectedRate,
                    unit: "kg/주",
                    presetRates: [0.0, 0.2, 0.5],
                    recommendedRange: "권장: ±1kg/week 이내",
                    error: nil,
                    onSelectRate: { rate in
                        print("Selected rate: \(rate)")
                    }
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .padding()

                Text("선택된 변화율: \(selectedRate) kg/주")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Weekly Rate Picker - With Error") {
    struct PreviewWrapper: View {
        @State private var selectedRate = "-5.0"

        var body: some View {
            VStack(spacing: 20) {
                Text("체중 변화율 선택 (에러)")
                    .font(.headline)

                WeeklyRatePicker(
                    selectedRate: $selectedRate,
                    unit: "kg/주",
                    presetRates: [-1.0, -0.5, 0.0, 0.5, 1.0],
                    recommendedRange: "권장: ±2kg/week 이내",
                    error: "주간 변화율은 ±2kg/week 이내여야 합니다",
                    onSelectRate: { rate in
                        print("Selected rate: \(rate)")
                    }
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .padding()

                Text("선택된 변화율: \(selectedRate) kg/주")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Weekly Rate Picker - All Types") {
    ScrollView {
        VStack(spacing: 32) {
            // 체중 변화율
            VStack(alignment: .leading, spacing: 12) {
                Text("체중 변화율")
                    .font(.title3)
                    .fontWeight(.bold)

                WeeklyRatePicker(
                    selectedRate: .constant("-0.5"),
                    unit: "kg/주",
                    presetRates: [-1.0, -0.5, 0.0, 0.5, 1.0],
                    recommendedRange: "권장: ±2kg/week 이내",
                    error: nil,
                    onSelectRate: nil
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }

            // 체지방률 변화율
            VStack(alignment: .leading, spacing: 12) {
                Text("체지방률 변화율")
                    .font(.title3)
                    .fontWeight(.bold)

                WeeklyRatePicker(
                    selectedRate: .constant("-0.5"),
                    unit: "%/주",
                    presetRates: [-1.0, -0.5, 0.0],
                    recommendedRange: "권장: ±3%/week 이내",
                    error: nil,
                    onSelectRate: nil
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }

            // 근육량 변화율
            VStack(alignment: .leading, spacing: 12) {
                Text("근육량 변화율")
                    .font(.title3)
                    .fontWeight(.bold)

                WeeklyRatePicker(
                    selectedRate: .constant("0.2"),
                    unit: "kg/주",
                    presetRates: [0.0, 0.2, 0.5],
                    recommendedRange: "권장: ±1kg/week 이내",
                    error: nil,
                    onSelectRate: nil
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Weekly Rate Picker Pattern
///
/// 주간 변화율 선택을 위한 재사용 가능한 컴포넌트 패턴입니다.
///
/// ### 주요 특징
///
/// 1. **Preset Buttons for Quick Selection**:
///    - 자주 사용하는 변화율을 버튼으로 제공
///    - 한 번의 탭으로 빠르게 선택 가능
///
/// 2. **Custom Input for Precision**:
///    - 정확한 값이 필요할 때 직접 입력 가능
///    - 프리셋에 없는 값도 입력 가능
///
/// 3. **Color-coded Rates**:
///    - 감소 (음수): 파란색
///    - 유지 (0): 녹색
///    - 증가 (양수): 주황색
///
/// 4. **Inline Validation**:
///    - 검증 에러를 입력 필드 바로 아래 표시
///    - 권장 범위 힌트 제공
///
/// ### Color Coding Strategy
///
/// **의미 있는 색상 사용**:
/// ```swift
/// private func rateColor(_ rate: Decimal) -> Color {
///     if rate < 0 {
///         return .blue  // 감소 (체중/체지방 감량)
///     } else if rate > 0 {
///         return .orange  // 증가 (체중/근육 증가)
///     } else {
///         return .green  // 유지
///     }
/// }
/// ```
///
/// 이 색상 체계는:
/// - 직관적: 파란색(하락), 녹색(안정), 주황색(상승)
/// - 일관성: 앱 전체에서 동일한 의미
/// - 접근성: 색상만 의존하지 않고 부호(+/-)도 함께 표시
///
/// ### Preset Configuration by Goal Type
///
/// **체중 목표**:
/// ```swift
/// presetRates: [-1.0, -0.5, 0.0, 0.5, 1.0]
/// ```
/// - 감량과 증량 모두 지원
/// - 일반적인 변화율 범위
///
/// **체지방률 목표**:
/// ```swift
/// presetRates: [-1.0, -0.5, 0.0]
/// ```
/// - 주로 감량 목표
/// - 체지방 증가는 일반적이지 않음
///
/// **근육량 목표**:
/// ```swift
/// presetRates: [0.0, 0.2, 0.5]
/// ```
/// - 주로 증량 또는 유지
/// - 근육 감소는 목표가 아님
///
/// ### Horizontal Scroll Pattern
///
/// **많은 버튼 처리**:
/// ```swift
/// ScrollView(.horizontal, showsIndicators: false) {
///     HStack(spacing: 8) {
///         ForEach(presetRates, id: \.self) { rate in
///             presetButton(rate: rate)
///         }
///     }
/// }
/// ```
///
/// - `showsIndicators: false`: 스크롤바 숨김
/// - 버튼이 많을 경우 가로 스크롤 가능
/// - 작은 화면에서도 모든 옵션 접근 가능
///
/// ### Number Formatting
///
/// **부호 포함 포맷팅**:
/// ```swift
/// private func formatRateWithSign(_ rate: Decimal) -> String {
///     let formatted = formatRate(rate)
///     if rate > 0 {
///         return "+\(formatted)"  // +0.5
///     } else {
///         return formatted        // -0.5 or 0.0
///     }
/// }
/// ```
///
/// - 양수: 명시적으로 "+" 부호 추가
/// - 음수: 자동으로 "-" 부호 포함
/// - 0: 부호 없음
///
/// ### Integration with ViewModel
///
/// ```swift
/// WeeklyRatePicker(
///     selectedRate: $viewModel.weeklyWeightRateInput,
///     unit: "kg/주",
///     presetRates: [-1.0, -0.5, 0.0, 0.5, 1.0],
///     recommendedRange: "권장: ±2kg/week 이내",
///     error: viewModel.validationErrors.weeklyWeightRate,
///     onSelectRate: { rate in
///         // 선택 시 추가 로직 (옵셔널)
///         viewModel.recalculateEstimatedDate()
///     }
/// )
/// ```
///
/// ### Haptic Feedback
///
/// ```swift
/// private func handleRateSelection(_ rate: Decimal) {
///     let generator = UIImpactFeedbackGenerator(style: .light)
///     generator.impactOccurred()
///
///     selectedRate = formatRate(rate)
///     onSelectRate?(rate)
/// }
/// ```
///
/// - 프리셋 버튼 선택 시 가벼운 햅틱 피드백
/// - 물리적 버튼을 누르는 느낌
/// - 사용자 경험 향상
///
/// ### Best Practices
///
/// 1. **Visual Clarity**:
///    - 선택된 버튼이 명확히 구분되도록 배경색 변경
///    - 색상과 부호(+/-)를 함께 사용하여 의미 전달
///
/// 2. **Flexibility**:
///    - 프리셋 + 커스텀 입력 조합
///    - 빠른 선택과 정확한 입력 모두 지원
///
/// 3. **Context-Specific Presets**:
///    - 목표 유형에 맞는 프리셋 제공
///    - 체중, 체지방률, 근육량마다 다른 범위
///
/// 4. **Consistent Feedback**:
///    - 검증 에러 표시 (주황색 + 아이콘)
///    - 권장 범위 힌트 (회색 + 정보 아이콘)
///
/// 5. **Accessibility**:
///    - 버튼 크기 충분 (최소 44x44pt)
///    - 색상만 의존하지 않고 텍스트도 함께 표시
///    - VoiceOver 지원 (부호 포함 읽기)
///

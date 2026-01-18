//
//  GoalTargetInputCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Reusable Goal Target Input Card
// 목표 입력을 위한 재사용 가능한 카드 컴포넌트 (토글 + 입력 필드 + 검증)
// 💡 Java 비교: Android의 Material Card with Expansion과 유사

import SwiftUI

// MARK: - Goal Target Input Card

/// 목표 타겟 입력 카드 컴포넌트
///
/// 체중, 체지방률, 근육량 등의 목표를 설정하기 위한 재사용 가능한 입력 카드입니다.
///
/// **주요 기능:**
/// - 목표 활성화/비활성화 토글
/// - 목표값 입력 필드
/// - 주간 변화율 입력 필드
/// - 인라인 검증 에러 표시
/// - 활성/비활성 상태에 따른 시각적 피드백
///
/// **애니메이션:**
/// - 토글 시 입력 필드가 부드럽게 나타나고 사라짐
/// - easeInOut 애니메이션 (0.2초)
///
/// - Example:
/// ```swift
/// GoalTargetInputCard(
///     title: "체중 목표",
///     icon: "scalemass",
///     isEnabled: $viewModel.isWeightEnabled,
///     targetValue: $viewModel.targetWeightInput,
///     targetPlaceholder: "예: 65.0",
///     targetUnit: "kg",
///     targetLabel: "목표 체중 (kg)",
///     weeklyRate: $viewModel.weeklyWeightRateInput,
///     rateUnit: "kg/주",
///     rateLabel: "주간 변화율 (kg/week)",
///     rateHint: "권장: ±2kg/week 이내",
///     targetError: viewModel.validationErrors.targetWeight,
///     rateError: viewModel.validationErrors.weeklyWeightRate
/// )
/// ```
struct GoalTargetInputCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Card Metadata
    // 카드의 제목, 아이콘 등 메타데이터

    /// 카드 제목 (예: "체중 목표")
    let title: String

    /// SF Symbol 아이콘 이름
    let icon: String

    // 📚 학습 포인트: @Binding for Two-Way Data Flow
    // 부모 View와 양방향 데이터 동기화

    /// 목표 활성화 여부
    @Binding var isEnabled: Bool

    /// 목표값 입력 (String - 사용자 입력 그대로)
    @Binding var targetValue: String

    /// 주간 변화율 입력 (String - 사용자 입력 그대로)
    @Binding var weeklyRate: String

    // 📚 학습 포인트: Field Configuration
    // 각 입력 필드의 설정 정보

    /// 목표값 플레이스홀더 (예: "예: 65.0")
    let targetPlaceholder: String

    /// 목표값 단위 (예: "kg")
    let targetUnit: String

    /// 목표값 레이블 (예: "목표 체중 (kg)")
    let targetLabel: String

    /// 주간 변화율 단위 (예: "kg/주")
    let rateUnit: String

    /// 주간 변화율 레이블 (예: "주간 변화율 (kg/week)")
    let rateLabel: String

    /// 주간 변화율 힌트 (예: "권장: ±2kg/week 이내")
    let rateHint: String

    // 📚 학습 포인트: Validation Errors
    // 각 필드의 검증 에러 메시지

    /// 목표값 검증 에러 메시지
    let targetError: String?

    /// 주간 변화율 검증 에러 메시지
    let rateError: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 토글 헤더
            toggleHeader

            // 입력 필드 (활성화된 경우에만 표시)
            if isEnabled {
                VStack(spacing: 16) {
                    // 목표값 입력
                    targetInputSection

                    // 주간 변화율 입력
                    weeklyRateInputSection
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(cardBackground)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    // MARK: - View Components

    /// 토글 헤더
    ///
    /// 목표 제목과 활성화 토글을 포함하는 헤더입니다.
    @ViewBuilder
    private var toggleHeader: some View {
        HStack {
            // 제목과 아이콘
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.headline)
            }

            Spacer()

            // 활성화 토글
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(.blue)
        }
    }

    /// 목표값 입력 섹션
    ///
    /// 목표값을 입력하는 필드와 검증 에러를 표시합니다.
    @ViewBuilder
    private var targetInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(targetLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(targetPlaceholder, text: $targetValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )

                Text(targetUnit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
            }

            // 검증 에러 표시
            if let error = targetError {
                validationErrorLabel(error)
            }
        }
    }

    /// 주간 변화율 입력 섹션
    ///
    /// 주간 변화율을 입력하는 필드와 검증 에러, 힌트를 표시합니다.
    @ViewBuilder
    private var weeklyRateInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(rateLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("예: -0.5", text: $weeklyRate)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )

                Text(rateUnit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
            }

            // 검증 에러 표시
            if let error = rateError {
                validationErrorLabel(error)
            }

            // 권장 범위 힌트
            Text(rateHint)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 카드 배경
    ///
    /// 라이트/다크 모드에 자동 대응하는 카드 배경입니다.
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(
                color: isEnabled ? Color.blue.opacity(0.1) : Color.black.opacity(0.05),
                radius: isEnabled ? 8 : 4,
                x: 0,
                y: 2
            )
    }

    /// 검증 에러 레이블
    ///
    /// - Parameter message: 에러 메시지
    /// - Returns: 에러 레이블 뷰
    @ViewBuilder
    private func validationErrorLabel(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)

            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.orange)
    }
}

// MARK: - Preview

#Preview("Goal Target Input Card - Weight") {
    // 📚 학습 포인트: Preview with State
    // Preview에서 상태 관리를 위한 PreviewWrapper 사용
    struct PreviewWrapper: View {
        @State private var isEnabled = true
        @State private var targetValue = "65.0"
        @State private var weeklyRate = "-0.5"

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    GoalTargetInputCard(
                        title: "체중 목표",
                        icon: "scalemass",
                        isEnabled: $isEnabled,
                        targetValue: $targetValue,
                        targetPlaceholder: "예: 65.0",
                        targetUnit: "kg",
                        targetLabel: "목표 체중 (kg)",
                        weeklyRate: $weeklyRate,
                        rateUnit: "kg/주",
                        rateLabel: "주간 변화율 (kg/week)",
                        rateHint: "권장: ±2kg/week 이내",
                        targetError: nil,
                        rateError: nil
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Goal Target Input Card - Body Fat") {
    struct PreviewWrapper: View {
        @State private var isEnabled = true
        @State private var targetValue = "18.0"
        @State private var weeklyRate = "-0.5"

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    GoalTargetInputCard(
                        title: "체지방률 목표",
                        icon: "percent",
                        isEnabled: $isEnabled,
                        targetValue: $targetValue,
                        targetPlaceholder: "예: 18.0",
                        targetUnit: "%",
                        targetLabel: "목표 체지방률 (%)",
                        weeklyRate: $weeklyRate,
                        rateUnit: "%/주",
                        rateLabel: "주간 변화율 (%/week)",
                        rateHint: "권장: ±3%/week 이내",
                        targetError: nil,
                        rateError: nil
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Goal Target Input Card - Disabled") {
    struct PreviewWrapper: View {
        @State private var isEnabled = false
        @State private var targetValue = ""
        @State private var weeklyRate = ""

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    GoalTargetInputCard(
                        title: "근육량 목표",
                        icon: "figure.strengthtraining.traditional",
                        isEnabled: $isEnabled,
                        targetValue: $targetValue,
                        targetPlaceholder: "예: 32.0",
                        targetUnit: "kg",
                        targetLabel: "목표 근육량 (kg)",
                        weeklyRate: $weeklyRate,
                        rateUnit: "kg/주",
                        rateLabel: "주간 변화율 (kg/week)",
                        rateHint: "권장: ±1kg/week 이내",
                        targetError: nil,
                        rateError: nil
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Goal Target Input Card - With Errors") {
    struct PreviewWrapper: View {
        @State private var isEnabled = true
        @State private var targetValue = "1000"
        @State private var weeklyRate = "-10"

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    GoalTargetInputCard(
                        title: "체중 목표",
                        icon: "scalemass",
                        isEnabled: $isEnabled,
                        targetValue: $targetValue,
                        targetPlaceholder: "예: 65.0",
                        targetUnit: "kg",
                        targetLabel: "목표 체중 (kg)",
                        weeklyRate: $weeklyRate,
                        rateUnit: "kg/주",
                        rateLabel: "주간 변화율 (kg/week)",
                        rateHint: "권장: ±2kg/week 이내",
                        targetError: "목표 체중은 500kg 이하여야 합니다",
                        rateError: "주간 변화율은 ±2kg/week 이내여야 합니다"
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Goal Target Input Card - Multiple Cards") {
    struct PreviewWrapper: View {
        @State private var isWeightEnabled = true
        @State private var targetWeight = "65.0"
        @State private var weeklyWeightRate = "-0.5"

        @State private var isBodyFatEnabled = true
        @State private var targetBodyFat = "18.0"
        @State private var weeklyBodyFatRate = "-0.5"

        @State private var isMuscleEnabled = false
        @State private var targetMuscle = ""
        @State private var weeklyMuscleRate = ""

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // 체중 목표
                    GoalTargetInputCard(
                        title: "체중 목표",
                        icon: "scalemass",
                        isEnabled: $isWeightEnabled,
                        targetValue: $targetWeight,
                        targetPlaceholder: "예: 65.0",
                        targetUnit: "kg",
                        targetLabel: "목표 체중 (kg)",
                        weeklyRate: $weeklyWeightRate,
                        rateUnit: "kg/주",
                        rateLabel: "주간 변화율 (kg/week)",
                        rateHint: "권장: ±2kg/week 이내",
                        targetError: nil,
                        rateError: nil
                    )

                    // 체지방률 목표
                    GoalTargetInputCard(
                        title: "체지방률 목표",
                        icon: "percent",
                        isEnabled: $isBodyFatEnabled,
                        targetValue: $targetBodyFat,
                        targetPlaceholder: "예: 18.0",
                        targetUnit: "%",
                        targetLabel: "목표 체지방률 (%)",
                        weeklyRate: $weeklyBodyFatRate,
                        rateUnit: "%/주",
                        rateLabel: "주간 변화율 (%/week)",
                        rateHint: "권장: ±3%/week 이내",
                        targetError: nil,
                        rateError: nil
                    )

                    // 근육량 목표
                    GoalTargetInputCard(
                        title: "근육량 목표",
                        icon: "figure.strengthtraining.traditional",
                        isEnabled: $isMuscleEnabled,
                        targetValue: $targetMuscle,
                        targetPlaceholder: "예: 32.0",
                        targetUnit: "kg",
                        targetLabel: "목표 근육량 (kg)",
                        weeklyRate: $weeklyMuscleRate,
                        rateUnit: "kg/주",
                        rateLabel: "주간 변화율 (kg/week)",
                        rateHint: "권장: ±1kg/week 이내",
                        targetError: nil,
                        rateError: nil
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

// MARK: - Learning Notes

/// ## Goal Target Input Card Pattern
///
/// 목표 입력을 위한 재사용 가능한 카드 컴포넌트 패턴입니다.
///
/// ### 주요 특징
///
/// 1. **Toggle-based Activation**:
///    - 목표를 활성화/비활성화할 수 있는 토글
///    - 토글 상태에 따라 입력 필드 표시/숨김
///
/// 2. **Two Input Fields**:
///    - 목표값 입력 (target value)
///    - 주간 변화율 입력 (weekly rate)
///
/// 3. **Inline Validation**:
///    - 각 필드별 검증 에러 메시지 표시
///    - 시각적으로 명확한 에러 표시 (주황색, 경고 아이콘)
///
/// 4. **Visual Feedback**:
///    - 활성화 상태에 따른 그림자 효과 변경
///    - 토글 시 부드러운 애니메이션
///
/// ### Toggle-based Conditional UI Pattern
///
/// **Toggle Header**:
/// ```swift
/// HStack {
///     HStack(spacing: 8) {
///         Image(systemName: icon)
///         Text(title)
///     }
///     Spacer()
///     Toggle("", isOn: $isEnabled)
///         .labelsHidden()
/// }
/// ```
///
/// **Conditional Content with Animation**:
/// ```swift
/// if isEnabled {
///     VStack(spacing: 16) {
///         // 입력 필드들
///     }
///     .transition(.opacity.combined(with: .move(edge: .top)))
/// }
/// .animation(.easeInOut(duration: 0.2), value: isEnabled)
/// ```
///
/// ### Reusability Benefits
///
/// 이 컴포넌트를 사용하면:
/// - 체중, 체지방률, 근육량 목표 입력이 동일한 UI/UX로 일관성 유지
/// - 중복 코드 제거 (GoalSettingView가 훨씬 간결해짐)
/// - 수정 시 한 곳만 변경하면 모든 목표 입력에 반영
///
/// **Before (Repetitive Code)**:
/// ```swift
/// // weightTargetSection - 100+ lines
/// // bodyFatTargetSection - 100+ lines
/// // muscleTargetSection - 100+ lines
/// ```
///
/// **After (Using Component)**:
/// ```swift
/// GoalTargetInputCard(
///     title: "체중 목표",
///     icon: "scalemass",
///     isEnabled: $viewModel.isWeightEnabled,
///     targetValue: $viewModel.targetWeightInput,
///     // ... 간단한 파라미터들
/// )
/// ```
///
/// ### Animation Strategy
///
/// **Combined Transition**:
/// ```swift
/// .transition(.opacity.combined(with: .move(edge: .top)))
/// ```
///
/// - `opacity`: 페이드 인/아웃 효과
/// - `move(edge: .top)`: 위에서 아래로 슬라이드
/// - 두 효과를 결합하여 자연스러운 애니메이션
///
/// **Value-based Animation**:
/// ```swift
/// .animation(.easeInOut(duration: 0.2), value: isEnabled)
/// ```
///
/// - `isEnabled` 값이 변경될 때만 애니메이션 실행
/// - 다른 상태 변경 시에는 애니메이션 없음
/// - 성능 최적화
///
/// ### Visual Feedback Pattern
///
/// **Active State Shadow**:
/// ```swift
/// .shadow(
///     color: isEnabled ? Color.blue.opacity(0.1) : Color.black.opacity(0.05),
///     radius: isEnabled ? 8 : 4,
///     x: 0,
///     y: 2
/// )
/// ```
///
/// - 활성화 시: 파란색 그림자, 더 큰 반경 (8pt)
/// - 비활성화 시: 검은색 그림자, 작은 반경 (4pt)
/// - 사용자가 활성 상태를 시각적으로 쉽게 인식
///
/// ### Best Practices
///
/// 1. **Consistent Styling**:
///    - 모든 목표 입력이 동일한 디자인
///    - 아이콘, 색상, 간격 일관성
///
/// 2. **Clear Visual Hierarchy**:
///    - 제목 → 목표값 → 주간 변화율 순서
///    - 레이블 → 입력 필드 → 에러/힌트 순서
///
/// 3. **Accessibility**:
///    - Toggle labels hidden but accessible
///    - Error messages with icons for visibility
///
/// 4. **Keyboard Type Optimization**:
///    - 목표값: `.decimalPad` (양수만)
///    - 주간 변화율: `.numbersAndPunctuation` (음수 허용)
///
/// 5. **Error Display**:
///    - Inline error messages (필드 바로 아래)
///    - 주황색 + 경고 아이콘 조합
///    - 힌트 메시지와 구분 (힌트는 회색)
///

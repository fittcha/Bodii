//
//  DashboardEmptyStates.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Empty State Components
// 대시보드 카드에 데이터가 없을 때 표시되는 Empty State 컴포넌트들
// 💡 사용자에게 유용한 메시지와 함께 액션 버튼을 제공하여 UX 개선

import SwiftUI

// MARK: - Generic Empty State View

/// 재사용 가능한 Empty State 뷰
///
/// 데이터가 없을 때 표시되는 공통 Empty State 컴포넌트입니다.
/// 아이콘, 메시지, 액션 버튼을 조합하여 사용자에게 명확한 안내를 제공합니다.
///
/// **표시 내용:**
/// - SF Symbol 아이콘
/// - 주 메시지 (예: "오늘 음식 기록 없음")
/// - 부 메시지 (예: "첫 식사를 기록해 보세요")
/// - 액션 버튼 (선택 사항)
///
/// - Note: 재사용 가능한 컴포넌트로 설계되어 다양한 Empty State에서 활용 가능합니다.
///
/// - Example:
/// ```swift
/// DashboardEmptyState(
///     icon: "fork.knife",
///     iconColor: .orange,
///     title: "오늘 음식 기록 없음",
///     message: "첫 식사를 기록해 보세요",
///     actionTitle: "음식 추가",
///     actionColor: .orange,
///     action: { /* 음식 추가 화면으로 이동 */ }
/// )
/// ```
struct DashboardEmptyState: View {

    // MARK: - Properties

    // 📚 학습 포인트: Flexible Empty State Design
    // 아이콘, 메시지, 액션을 외부에서 주입받아 다양한 상황에 대응
    // 💡 Java 비교: Builder 패턴과 유사한 유연한 설계

    /// SF Symbol 아이콘 이름
    let icon: String

    /// 아이콘 색상
    let iconColor: Color

    /// 주 메시지 (제목)
    let title: String

    /// 부 메시지 (설명)
    let message: String

    /// 액션 버튼 제목 (nil이면 버튼 표시 안 함)
    let actionTitle: String?

    /// 액션 버튼 색상
    let actionColor: Color

    /// 액션 버튼 클릭 콜백 (nil이면 버튼 표시 안 함)
    let action: (() -> Void)?

    // MARK: - Initialization

    /// DashboardEmptyState 초기화
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘 이름
    ///   - iconColor: 아이콘 색상
    ///   - title: 주 메시지
    ///   - message: 부 메시지
    ///   - actionTitle: 액션 버튼 제목 (기본값: nil)
    ///   - actionColor: 액션 버튼 색상 (기본값: .blue)
    ///   - action: 액션 버튼 클릭 콜백 (기본값: nil)
    init(
        icon: String,
        iconColor: Color,
        title: String,
        message: String,
        actionTitle: String? = nil,
        actionColor: Color = .blue,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionColor = actionColor
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 아이콘
            // 📚 학습 포인트: Large Icon for Empty State
            // 큰 아이콘으로 시각적 주목도를 높임
            // 💡 Java 비교: Empty View with large icon과 유사
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(iconColor.opacity(0.5))
                .padding(.top, 8)

            // 메시지 섹션
            VStack(spacing: 4) {
                // 주 메시지
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // 부 메시지
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 액션 버튼 (있을 경우)
            // 📚 학습 포인트: Optional Action Button
            // actionTitle과 action이 모두 있을 때만 버튼 표시
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)

                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(actionColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Specific Empty States

/// 음식 기록 없음 Empty State
///
/// 칼로리 밸런스 카드와 매크로 분석 카드에서 사용됩니다.
/// 사용자가 음식을 기록하지 않았을 때 표시됩니다.
///
/// - Parameter onAddFood: 음식 추가 버튼 클릭 콜백
struct FoodEmptyState: View {

    /// 음식 추가 버튼 클릭 콜백
    let onAddFood: (() -> Void)?

    var body: some View {
        DashboardEmptyState(
            icon: "fork.knife",
            iconColor: .orange,
            title: "오늘 음식 기록 없음",
            message: "첫 식사를 기록해 보세요",
            actionTitle: onAddFood != nil ? "음식 추가" : nil,
            actionColor: .orange,
            action: onAddFood
        )
    }
}

/// 운동 기록 없음 Empty State
///
/// 운동 요약 카드에서 사용됩니다.
/// 사용자가 운동을 기록하지 않았을 때 표시됩니다.
///
/// - Parameter onAddExercise: 운동 추가 버튼 클릭 콜백
struct ExerciseEmptyState: View {

    /// 운동 추가 버튼 클릭 콜백
    let onAddExercise: (() -> Void)?

    var body: some View {
        DashboardEmptyState(
            icon: "figure.run",
            iconColor: .green,
            title: "오늘 운동 기록 없음",
            message: "첫 운동을 기록해 보세요",
            actionTitle: onAddExercise != nil ? "운동 추가" : nil,
            actionColor: .green,
            action: onAddExercise
        )
    }
}

/// 수면 기록 없음 Empty State
///
/// 수면 품질 카드에서 사용됩니다.
/// 사용자가 수면 시간을 기록하지 않았을 때 표시됩니다.
///
/// - Note: 수면 기록은 별도 화면이 없으므로 액션 버튼이 없습니다.
struct SleepEmptyState: View {

    var body: some View {
        DashboardEmptyState(
            icon: "moon.zzz.fill",
            iconColor: .purple,
            title: "어젯밤 수면 기록 없음",
            message: "수면 시간을 기록하면 품질을 분석해 드려요",
            actionTitle: nil,
            actionColor: .purple,
            action: nil
        )
    }
}

/// 체성분 기록 없음 Empty State
///
/// 체성분 카드에서 사용됩니다.
/// 사용자가 체중과 체지방률을 기록하지 않았을 때 표시됩니다.
///
/// - Parameter onAddBodyComposition: 체성분 추가 버튼 클릭 콜백
struct BodyCompositionEmptyState: View {

    /// 체성분 추가 버튼 클릭 콜백
    let onAddBodyComposition: (() -> Void)?

    var body: some View {
        DashboardEmptyState(
            icon: "scalemass",
            iconColor: .blue,
            title: "오늘 체성분 기록 없음",
            message: "체중과 체지방률을 기록해 보세요",
            actionTitle: onAddBodyComposition != nil ? "체성분 기록" : nil,
            actionColor: .blue,
            action: onAddBodyComposition
        )
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 Empty State를 미리 보며 개발
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Generic Empty State") {
    VStack(spacing: 20) {
        // 액션 버튼 있는 경우
        DashboardEmptyState(
            icon: "fork.knife",
            iconColor: .orange,
            title: "데이터 없음",
            message: "새로운 데이터를 추가해 보세요",
            actionTitle: "추가하기",
            actionColor: .orange,
            action: { print("Action clicked") }
        )
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 16)

        // 액션 버튼 없는 경우
        DashboardEmptyState(
            icon: "moon.zzz.fill",
            iconColor: .purple,
            title: "데이터 없음",
            message: "데이터가 없습니다",
            actionTitle: nil,
            actionColor: .purple,
            action: nil
        )
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Food Empty State") {
    VStack(spacing: 20) {
        // 액션 버튼 있는 경우
        FoodEmptyState(onAddFood: { print("Add Food") })
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 16)

        // 액션 버튼 없는 경우
        FoodEmptyState(onAddFood: nil)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Exercise Empty State") {
    VStack(spacing: 20) {
        ExerciseEmptyState(onAddExercise: { print("Add Exercise") })
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Sleep Empty State") {
    VStack(spacing: 20) {
        SleepEmptyState()
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Body Composition Empty State") {
    VStack(spacing: 20) {
        BodyCompositionEmptyState(onAddBodyComposition: { print("Add Body Composition") })
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Empty States") {
    ScrollView {
        VStack(spacing: 20) {
            // 음식 기록 없음
            VStack(spacing: 16) {
                Text("음식 Empty State")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FoodEmptyState(onAddFood: { print("Add Food") })
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
            }

            // 운동 기록 없음
            VStack(spacing: 16) {
                Text("운동 Empty State")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ExerciseEmptyState(onAddExercise: { print("Add Exercise") })
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
            }

            // 수면 기록 없음
            VStack(spacing: 16) {
                Text("수면 Empty State")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SleepEmptyState()
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
            }

            // 체성분 기록 없음
            VStack(spacing: 16) {
                Text("체성분 Empty State")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                BodyCompositionEmptyState(onAddBodyComposition: { print("Add Body Composition") })
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    )
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: 20) {
            FoodEmptyState(onAddFood: { print("Add Food") })
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                )
                .padding(.horizontal, 16)

            ExerciseEmptyState(onAddExercise: { print("Add Exercise") })
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

// MARK: - Learning Notes

/// ## Empty State 컴포넌트 구현
///
/// ### 주요 개념
///
/// 1. **재사용 가능한 Generic 컴포넌트**
///    - DashboardEmptyState: 기본 Empty State 컴포넌트
///    - 아이콘, 메시지, 액션을 외부에서 주입받아 다양한 상황에 대응
///    - Specific Empty State: 각 카드별 특화된 Empty State 컴포넌트
///
/// 2. **Optional Action Button**
///    - actionTitle과 action이 모두 있을 때만 버튼 표시
///    - 수면 기록처럼 별도 입력 화면이 없는 경우 버튼 없이 메시지만 표시
///    - 유연한 설계로 다양한 요구사항 대응
///
/// 3. **일관된 디자인 언어**
///    - 큰 아이콘 (60pt)으로 시각적 주목도 향상
///    - 주 메시지 (headline) + 부 메시지 (subheadline)
///    - 액션 버튼은 QuickAddButtons와 유사한 스타일
///    - 색상은 각 기능별로 일관되게 적용
///
/// 4. **색상 규칙**
///    - 음식: 주황색 (orange) - 따뜻하고 식욕을 자극하는 색
///    - 운동: 초록색 (green) - 건강과 활력을 상징하는 색
///    - 수면: 보라색 (purple) - 편안함과 휴식을 나타내는 색
///    - 체성분: 파란색 (blue) - 신뢰와 안정을 나타내는 색
///
/// 5. **사용자 경험 (UX) 고려**
///    - 빈 화면을 보여주지 않고 명확한 안내 메시지 제공
///    - 다음 행동을 유도하는 액션 버튼 제공
///    - 친근하고 긍정적인 메시지 ("~해 보세요")
///
/// ### Empty State 사용 위치
///
/// | 카드 | Empty State | 액션 버튼 |
/// |------|-------------|----------|
/// | CalorieBalanceCard | FoodEmptyState | 있음 |
/// | MacroBreakdownCard | FoodEmptyState | 있음 |
/// | ExerciseSummaryCard | ExerciseEmptyState | 있음 |
/// | SleepQualityCard | SleepEmptyState | 없음 |
/// | BodyCompositionCard | BodyCompositionEmptyState | 있음 |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | DashboardEmptyState | EmptyStateView component |
/// | Optional action | Nullable callback |
/// | VStack(spacing:) | Column(verticalArrangement) |
/// | Image(systemName:) | Icon(imageVector) |
/// | Button with RoundedRectangle | Button with RoundedCornerShape |
///
/// ### 모범 사례
///
/// 1. **재사용성**: Generic 컴포넌트로 설계하여 중복 코드 최소화
/// 2. **유연성**: Optional 파라미터로 다양한 케이스 대응
/// 3. **일관성**: 모든 Empty State가 동일한 구조와 스타일 유지
/// 4. **접근성**: 명확한 메시지와 터치하기 쉬운 버튼 크기
/// 5. **긍정적 메시지**: 사용자를 격려하고 다음 행동 유도
///
/// ### 사용 예시
///
/// ```swift
/// // CalorieBalanceCard에서 사용
/// if isEmpty {
///     FoodEmptyState(onAddFood: {
///         // 음식 추가 화면으로 이동
///         onNavigateToDiet?()
///     })
/// } else {
///     // 실제 칼로리 데이터 표시
///     calorieBalanceContent
/// }
/// ```
///
/// ### 향후 확장 가능성
///
/// 필요에 따라 더 많은 Empty State를 추가할 수 있습니다:
/// - WaterEmptyState: 수분 섭취 기록 없음
/// - MoodEmptyState: 기분 기록 없음
/// - NoteEmptyState: 메모 없음
///
/// DashboardEmptyState를 사용하여 쉽게 추가 가능합니다.
///
/// ### UX 디자인 원칙
///
/// Empty State는 단순히 "데이터 없음"을 알리는 것이 아니라:
/// - **교육적**: 이 기능이 무엇인지 설명
/// - **유도적**: 다음 행동을 명확히 제시
/// - **긍정적**: 사용자를 격려하는 메시지
/// - **시각적**: 아이콘과 색상으로 직관적 이해
///
/// 좋은 Empty State는 사용자 온보딩의 일부이며,
/// 사용자가 앱의 기능을 발견하고 활용하도록 돕습니다.
///

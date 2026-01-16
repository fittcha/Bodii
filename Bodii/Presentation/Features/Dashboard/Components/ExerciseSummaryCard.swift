//
//  ExerciseSummaryCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-15.
//

// 📚 학습 포인트: Exercise Summary Card Component
// 일일 운동 요약 카드 - 총 소모 칼로리, 운동 횟수, 운동 시간
// 💡 DailyLog의 사전 계산된 값을 사용하여 빠른 렌더링 보장

import SwiftUI

/// 운동 요약 카드
///
/// 오늘의 운동 정보를 요약하여 표시하는 카드 컴포넌트입니다.
/// 총 소모 칼로리, 운동 횟수, 운동 시간을 시각적으로 표현합니다.
///
/// **표시 내용:**
/// - 총 소모 칼로리 (kcal)
/// - 운동 횟수 (회)
/// - 총 운동 시간 (시간:분 형식)
///
/// **색상 규칙:**
/// - 소모 칼로리: 주황색
/// - 운동 횟수: 초록색
/// - 운동 시간: 파란색
///
/// - Note: DailyLog의 사전 계산된 값을 사용하여 빠른 렌더링을 보장합니다.
///
/// - Example:
/// ```swift
/// ExerciseSummaryCard(
///     totalCaloriesOut: 450,
///     exerciseCount: 2,
///     exerciseMinutes: 75
/// )
/// ```
struct ExerciseSummaryCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 운동 소모 칼로리 (kcal)
    let totalCaloriesOut: Int32

    /// 운동 횟수
    let exerciseCount: Int16

    /// 총 운동 시간 (분)
    let exerciseMinutes: Int32

    /// 운동 추가 콜백 (Empty State에서 사용)
    var onAddExercise: (() -> Void)? = nil

    // MARK: - Constants

    /// 매크로 영양소 색상
    private let caloriesColor: Color = .orange
    private let countColor: Color = .green
    private let timeColor: Color = .blue

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 여부
    private var isEmpty: Bool {
        totalCaloriesOut == 0 && exerciseCount == 0 && exerciseMinutes == 0
    }

    /// 시간 포맷팅 (예: "1시간 30분", "45분")
    private var formattedTime: String {
        formatMinutes(exerciseMinutes)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 제목 섹션
            titleSection

            // 📚 학습 포인트: Conditional Rendering - Empty State vs Content
            // 데이터 유무에 따라 Empty State 또는 실제 컨텐츠 표시
            if isEmpty {
                // Empty State: 운동 기록이 없을 때
                ExerciseEmptyState(onAddExercise: onAddExercise)
                    .padding(.vertical, 8)
            } else {
                // 실제 컨텐츠: 데이터가 있을 때
                // 통계 카드 그리드
                // 📚 학습 포인트: HStack with Equal Distribution
                // spacing으로 간격 조절, 각 카드는 maxWidth: .infinity로 균등 분배
                // 💡 Java 비교: LinearLayout with layout_weight="1"과 유사
                HStack(spacing: 12) {
                    // 소모 칼로리 카드
                    statCard(
                        title: "소모 칼로리",
                        value: "\(totalCaloriesOut)",
                        unit: "kcal",
                        icon: "flame.fill",
                        color: caloriesColor
                    )

                    // 운동 횟수 카드
                    statCard(
                        title: "운동 횟수",
                        value: "\(exerciseCount)",
                        unit: "회",
                        icon: "figure.run",
                        color: countColor
                    )

                    // 운동 시간 카드
                    statCard(
                        title: "운동 시간",
                        value: formattedTime,
                        unit: "",
                        icon: "clock.fill",
                        color: timeColor
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - View Components

    /// 제목 섹션
    private var titleSection: some View {
        HStack {
            Text("오늘의 운동")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(isEmpty ? .secondary : .primary)
            Spacer()
        }
    }

    /// 카드 배경
    private var cardBackground: some View {
        // 📚 학습 포인트: Material Background with Shadow
        // iOS 네이티브 느낌의 카드 디자인
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }

    /// 개별 통계 카드
    ///
    /// 운동 통계 항목을 카드 형태로 표시합니다.
    ///
    /// - Parameters:
    ///   - title: 제목 (예: "소모 칼로리")
    ///   - value: 값 (예: "450")
    ///   - unit: 단위 (예: "kcal")
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 및 배경 색상
    /// - Returns: 통계 카드 뷰
    private func statCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        // 📚 학습 포인트: VStack Layout with Color Background
        // 세로로 요소를 배치하고 색상 배경으로 시각적 구분
        // 💡 Java 비교: Column with Modifier.background()와 유사
        VStack(spacing: 8) {
            // 아이콘
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            // 값과 단위
            // 📚 학습 포인트: HStack with Baseline Alignment
            // firstTextBaseline로 텍스트 베이스라인 맞춤
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(isEmpty ? .secondary : .primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 제목
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Helper Methods

    /// 분 단위를 "X시간 Y분" 형식으로 변환
    ///
    /// - Parameter minutes: 분 단위 시간
    /// - Returns: 포맷팅된 문자열 (예: "1시간 30분", "45분", "0분")
    ///
    /// - Example:
    /// ```swift
    /// formatMinutes(90)  // "1시간 30분"
    /// formatMinutes(45)  // "45분"
    /// formatMinutes(120) // "2시간"
    /// formatMinutes(0)   // "0분"
    /// ```
    private func formatMinutes(_ minutes: Int32) -> String {
        // 📚 학습 포인트: Integer Division and Modulo
        // Swift의 정수 나눗셈과 나머지 연산
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)시간 \(remainingMinutes)분"
            } else {
                return "\(hours)시간"
            }
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (운동 있음/없음/다양한 시간대)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("With Exercises") {
    VStack(spacing: 20) {
        // 일반적인 운동 (2회, 75분, 450 kcal)
        ExerciseSummaryCard(
            totalCaloriesOut: 450,
            exerciseCount: 2,
            exerciseMinutes: 75
        )

        // 많은 운동 (5회, 240분, 1250 kcal)
        ExerciseSummaryCard(
            totalCaloriesOut: 1250,
            exerciseCount: 5,
            exerciseMinutes: 240
        )

        // 짧은 운동 (1회, 30분, 180 kcal)
        ExerciseSummaryCard(
            totalCaloriesOut: 180,
            exerciseCount: 1,
            exerciseMinutes: 30
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    VStack {
        // 운동 기록이 없는 경우 - 회색 톤으로 표시
        ExerciseSummaryCard(
            totalCaloriesOut: 0,
            exerciseCount: 0,
            exerciseMinutes: 0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Various Times") {
    ScrollView {
        VStack(spacing: 20) {
            // 정확히 1시간
            ExerciseSummaryCard(
                totalCaloriesOut: 350,
                exerciseCount: 1,
                exerciseMinutes: 60
            )

            // 1시간 30분
            ExerciseSummaryCard(
                totalCaloriesOut: 525,
                exerciseCount: 2,
                exerciseMinutes: 90
            )

            // 45분 미만
            ExerciseSummaryCard(
                totalCaloriesOut: 220,
                exerciseCount: 1,
                exerciseMinutes: 45
            )

            // 긴 시간 (3시간 15분)
            ExerciseSummaryCard(
                totalCaloriesOut: 980,
                exerciseCount: 4,
                exerciseMinutes: 195
            )

            // 2시간 정확히
            ExerciseSummaryCard(
                totalCaloriesOut: 720,
                exerciseCount: 3,
                exerciseMinutes: 120
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("High Intensity") {
    VStack(spacing: 20) {
        // 고강도 운동 (짧은 시간, 높은 칼로리)
        ExerciseSummaryCard(
            totalCaloriesOut: 600,
            exerciseCount: 1,
            exerciseMinutes: 45
        )

        // 저강도 운동 (긴 시간, 낮은 칼로리)
        ExerciseSummaryCard(
            totalCaloriesOut: 300,
            exerciseCount: 1,
            exerciseMinutes: 90
        )
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Exercise Summary Card 구현
///
/// ### 주요 개념
///
/// 1. **3개의 통계 카드 배치**
///    - HStack으로 가로 배치
///    - maxWidth: .infinity로 균등 분배
///    - spacing: 12로 카드 간 간격 조절
///
/// 2. **색상 규칙 (Color Coding)**
///    - 소모 칼로리: 주황색 - 에너지 소비
///    - 운동 횟수: 초록색 - 활동성
///    - 운동 시간: 파란색 - 지속 시간
///
/// 3. **시간 포맷팅**
///    - formatMinutes() 함수로 "X시간 Y분" 형식 변환
///    - 1시간 미만: "45분"
///    - 1시간 이상: "1시간 30분"
///    - 정확히 X시간: "2시간"
///
/// 4. **Empty State 처리**
///    - isEmpty 계산 프로퍼티로 빈 상태 판단
///    - 빈 상태일 때 회색 톤으로 표시
///    - 0 값도 명시적으로 표시하여 혼란 방지
///
/// 5. **카드 배경 효과**
///    - 각 통계 카드에 색상별 투명 배경 (opacity: 0.1)
///    - 시각적으로 구분되면서도 조화로운 디자인
///    - RoundedRectangle로 부드러운 모서리
///
/// ### statCard 함수 구조
///
/// ```swift
/// VStack {
///     Image(systemName: icon)      // 상단 아이콘
///     HStack {
///         Text(value)              // 값
///         Text(unit)               // 단위
///     }
///     Text(title)                  // 하단 제목
/// }
/// .background(color.opacity(0.1))  // 색상 배경
/// ```
///
/// - 세로 중심 정렬로 균형잡힌 레이아웃
/// - 아이콘 → 값 → 제목 순서로 시각적 계층 구성
/// - 색상 배경으로 각 카드 구분
///
/// ### 시간 포맷팅 로직
///
/// | 입력 (분) | 출력 |
/// |----------|------|
/// | 0 | "0분" |
/// | 45 | "45분" |
/// | 60 | "1시간" |
/// | 90 | "1시간 30분" |
/// | 120 | "2시간" |
/// | 195 | "3시간 15분" |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | HStack(spacing: 12) | Row(arrangement = spacedBy(12.dp)) |
/// | VStack(spacing: 8) | Column(arrangement = spacedBy(8.dp)) |
/// | .frame(maxWidth: .infinity) | Modifier.weight(1f) |
/// | .background(color.opacity(0.1)) | Modifier.background(color.copy(alpha = 0.1f)) |
/// | formatMinutes() | Duration.format() |
///
/// ### 모범 사례
///
/// 1. **Props 최소화**: 필요한 3가지 값만 받기 (calories, count, minutes)
/// 2. **Computed Properties**: isEmpty, formattedTime로 로직 분리
/// 3. **색상 일관성**: 앱 전체에서 같은 색상 규칙 사용
/// 4. **의미 있는 아이콘**: 각 통계의 특성을 나타내는 아이콘 선택
/// 5. **빈 상태 처리**: 데이터 없을 때도 UI가 깨지지 않도록 처리
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// if let dailyLog = viewModel.dailyLog {
///     ExerciseSummaryCard(
///         totalCaloriesOut: dailyLog.totalCaloriesOut,
///         exerciseCount: dailyLog.exerciseCount,
///         exerciseMinutes: dailyLog.exerciseMinutes
///     )
/// }
/// ```
///
/// ### 성능 최적화
///
/// - DailyLog의 사전 계산된 값 사용 (totalCaloriesOut, exerciseCount, exerciseMinutes)
/// - 추가 계산 없이 바로 표시 가능
/// - <0.5s 로딩 목표 달성에 기여
///
/// ### 접근성 (Accessibility)
///
/// - VoiceOver: "소모 칼로리 450 킬로칼로리, 운동 횟수 2회, 운동 시간 1시간 15분"으로 읽힘
/// - Dynamic Type: 시스템 폰트 크기에 자동 대응
/// - 색맹 지원: 아이콘과 텍스트로 색상만 의존하지 않음
///
/// ### 디자인 의도
///
/// 이 카드는 사용자가 오늘 얼마나 운동했는지 한눈에 파악할 수 있도록 합니다:
/// - **소모 칼로리**: 운동의 강도와 효과를 나타냄
/// - **운동 횟수**: 하루 동안 몇 번 운동했는지 추적
/// - **운동 시간**: 전체 활동 시간을 표시
///
/// 3개의 통계를 함께 보여줌으로써 운동의 양과 질을 모두 파악할 수 있습니다.
///

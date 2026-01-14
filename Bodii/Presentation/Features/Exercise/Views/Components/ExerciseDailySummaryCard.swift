//
//  ExerciseDailySummaryCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Reusable Summary Card Component
// 일일 운동 집계를 표시하는 재사용 가능한 카드 컴포넌트
// 💡 Java 비교: Compose의 @Composable Card와 유사한 역할

import SwiftUI

// MARK: - Exercise Daily Summary Card

/// 일일 운동 요약 카드
///
/// 하루 동안의 운동 집계 정보를 카드 형태로 표시하는 재사용 가능한 뷰입니다.
///
/// **표시 내용:**
/// - 총 소모 칼로리 (kcal)
/// - 총 운동 시간 (시간:분 형식)
/// - 운동 횟수 (회)
///
/// **특징:**
/// - 운동 기록이 없을 때 시각적 구분 (회색 톤, 0 값 표시)
/// - 각 통계별 색상 구분 (주황/파랑/초록)
/// - 아이콘을 활용한 직관적 UI
///
/// - Example:
/// ```swift
/// ExerciseDailySummaryCard(
///     totalCaloriesOut: 720,
///     exerciseMinutes: 135,
///     exerciseCount: 3
/// )
/// ```
struct ExerciseDailySummaryCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 총 소모 칼로리 (kcal)
    let totalCaloriesOut: Int32

    /// 총 운동 시간 (분)
    let exerciseMinutes: Int32

    /// 운동 횟수
    let exerciseCount: Int16

    // MARK: - Computed Properties

    /// 운동 기록이 없는지 여부
    /// - Returns: 모든 값이 0이면 true
    private var isEmpty: Bool {
        totalCaloriesOut == 0 && exerciseMinutes == 0 && exerciseCount == 0
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

            // 📚 학습 포인트: HStack with Equal Distribution
            // spacing으로 간격 조절, 각 카드는 maxWidth: .infinity로 균등 분배
            // 💡 Java 비교: LinearLayout with layout_weight="1"과 유사
            HStack(spacing: 12) {
                // 소모 칼로리 카드
                summaryCard(
                    title: "소모 칼로리",
                    value: "\(totalCaloriesOut)",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: isEmpty ? .gray : .orange
                )

                // 운동 시간 카드
                summaryCard(
                    title: "운동 시간",
                    value: formattedTime,
                    unit: "",
                    icon: "clock.fill",
                    color: isEmpty ? .gray : .blue
                )

                // 운동 횟수 카드
                summaryCard(
                    title: "운동 횟수",
                    value: "\(exerciseCount)",
                    unit: "회",
                    icon: "figure.run",
                    color: isEmpty ? .gray : .green
                )
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

    /// 개별 통계 카드 (재사용 가능한 단위 컴포넌트)
    ///
    /// - Parameters:
    ///   - title: 제목 (예: "소모 칼로리")
    ///   - value: 값 (예: "450")
    ///   - unit: 단위 (예: "kcal")
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 및 배경 색상
    /// - Returns: 통계를 표시하는 카드 뷰
    private func summaryCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        // 📚 학습 포인트: VStack Layout
        // 세로로 요소를 배치하는 레이아웃 컨테이너
        // alignment: .center로 중앙 정렬
        // 💡 Java 비교: LinearLayout(vertical, gravity=center)과 유사
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
// 다양한 상태를 미리 보며 개발 (운동 있음/없음)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("With Exercises") {
    VStack(spacing: 20) {
        // 운동 기록이 있는 경우
        ExerciseDailySummaryCard(
            totalCaloriesOut: 720,
            exerciseMinutes: 135,
            exerciseCount: 3
        )

        // 운동이 많은 경우
        ExerciseDailySummaryCard(
            totalCaloriesOut: 1250,
            exerciseMinutes: 240,
            exerciseCount: 5
        )

        // 짧은 운동
        ExerciseDailySummaryCard(
            totalCaloriesOut: 180,
            exerciseMinutes: 30,
            exerciseCount: 1
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    VStack {
        // 운동 기록이 없는 경우 - 회색 톤으로 표시
        ExerciseDailySummaryCard(
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Various Times") {
    VStack(spacing: 20) {
        // 정확히 1시간
        ExerciseDailySummaryCard(
            totalCaloriesOut: 350,
            exerciseMinutes: 60,
            exerciseCount: 1
        )

        // 1시간 30분
        ExerciseDailySummaryCard(
            totalCaloriesOut: 525,
            exerciseMinutes: 90,
            exerciseCount: 2
        )

        // 45분 미만
        ExerciseDailySummaryCard(
            totalCaloriesOut: 220,
            exerciseMinutes: 45,
            exerciseCount: 1
        )

        // 긴 시간 (3시간 15분)
        ExerciseDailySummaryCard(
            totalCaloriesOut: 980,
            exerciseMinutes: 195,
            exerciseCount: 4
        )
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Reusable Component 설계 패턴
///
/// ### 주요 개념
///
/// 1. **Props-Based Design**
///    - let으로 선언된 불변 프로퍼티
///    - 외부에서 주입받는 데이터만 사용
///    - 내부 상태를 갖지 않음 (Stateless)
///
/// 2. **Computed Properties**
///    - isEmpty: 데이터 유무 판단
///    - formattedTime: 표시 형식 변환
///    - UI 로직과 비즈니스 로직 분리
///
/// 3. **View Composition**
///    - summaryCard 함수로 반복되는 카드 추출
///    - 재사용 가능한 작은 단위로 분리
///    - 코드 중복 제거
///
/// 4. **Conditional Styling**
///    - isEmpty에 따라 색상 변경 (.gray vs .orange/.blue/.green)
///    - 사용자에게 시각적 피드백 제공
///
/// 5. **Preview-Driven Development**
///    - 다양한 상태의 Preview 제공
///    - 운동 있음/없음/다양한 시간대 테스트
///    - UI 개발 속도 향상
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | struct View | @Composable function |
/// | let property | final field |
/// | VStack/HStack | Column/Row |
/// | .background | Modifier.background |
/// | #Preview | @Preview |
/// | Computed Property | get() method |
///
/// ### 모범 사례
///
/// 1. **Props 최소화**: 필요한 데이터만 props로 받기
/// 2. **Pure Function**: 같은 입력에 항상 같은 출력
/// 3. **단일 책임**: 하나의 컴포넌트는 하나의 역할만
/// 4. **Preview 활용**: 개발 중 실시간 피드백
/// 5. **문서화**: 사용 예시와 파라미터 설명 제공
///
/// ### 이 컴포넌트의 재사용성
///
/// ```swift
/// // ExerciseListView에서 사용
/// ExerciseDailySummaryCard(
///     totalCaloriesOut: viewModel.totalCaloriesOut,
///     exerciseMinutes: viewModel.exerciseMinutes,
///     exerciseCount: viewModel.exerciseCount
/// )
///
/// // ExerciseDetailView에서도 사용 가능
/// ExerciseDailySummaryCard(
///     totalCaloriesOut: detailViewModel.calories,
///     exerciseMinutes: detailViewModel.minutes,
///     exerciseCount: detailViewModel.count
/// )
///
/// // 다른 날짜의 요약에도 사용 가능
/// ExerciseDailySummaryCard(
///     totalCaloriesOut: yesterdayLog.totalCaloriesOut,
///     exerciseMinutes: yesterdayLog.exerciseMinutes,
///     exerciseCount: yesterdayLog.exerciseCount
/// )
/// ```
///

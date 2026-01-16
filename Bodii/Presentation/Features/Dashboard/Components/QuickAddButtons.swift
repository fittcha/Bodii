//
//  QuickAddButtons.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Quick Add Buttons Component
// 빠른 추가 버튼 - 음식, 운동, 체성분 데이터를 빠르게 기록할 수 있는 가로 스크롤 버튼들
// 💡 각 버튼은 해당 입력 화면으로 네비게이션

import SwiftUI

/// 빠른 추가 버튼
///
/// 대시보드에서 음식, 운동, 체성분 데이터를 빠르게 추가할 수 있는 가로 스크롤 버튼 컴포넌트입니다.
///
/// **주요 기능:**
/// - 음식 추가: 식단 기록 화면으로 이동
/// - 운동 추가: 운동 기록 화면으로 이동
/// - 체성분 기록: 체성분 입력 화면으로 이동
///
/// **UI 특징:**
/// - 가로 스크롤 가능한 버튼 목록
/// - SF Symbols 아이콘 사용
/// - 각 버튼은 고유 색상으로 구분
///
/// - Note: 부모 View에서 네비게이션 콜백을 제공해야 합니다.
///
/// - Example:
/// ```swift
/// QuickAddButtons(
///     onAddFood: { /* 식단 탭으로 이동 */ },
///     onAddExercise: { /* 운동 탭으로 이동 */ },
///     onAddBodyComposition: { /* 체성분 탭으로 이동 */ }
/// )
/// ```
struct QuickAddButtons: View {

    // MARK: - Properties

    // 📚 학습 포인트: Callback-based Navigation
    // 각 버튼의 액션을 외부에서 주입받아 처리
    // 💡 Java 비교: OnClickListener 인터페이스와 유사

    /// 음식 추가 버튼 클릭 콜백
    let onAddFood: () -> Void

    /// 운동 추가 버튼 클릭 콜백
    let onAddExercise: () -> Void

    /// 체성분 기록 버튼 클릭 콜백
    let onAddBodyComposition: () -> Void

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: ScrollView with HStack
        // 가로 스크롤 가능한 버튼 목록
        // 💡 Java 비교: HorizontalScrollView + LinearLayout과 유사
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 음식 추가 버튼
                quickAddButton(
                    title: "음식 추가",
                    icon: "fork.knife",
                    color: .orange,
                    action: onAddFood
                )

                // 운동 추가 버튼
                quickAddButton(
                    title: "운동 추가",
                    icon: "figure.run",
                    color: .green,
                    action: onAddExercise
                )

                // 체성분 기록 버튼
                quickAddButton(
                    title: "체성분 기록",
                    icon: "scalemass.fill",
                    color: .blue,
                    action: onAddBodyComposition
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - View Components

    /// 빠른 추가 버튼
    ///
    /// 개별 빠른 추가 버튼을 생성합니다.
    /// 아이콘, 제목, 색상을 받아 일관된 스타일의 버튼을 만듭니다.
    ///
    /// - Parameters:
    ///   - title: 버튼 제목 (예: "음식 추가")
    ///   - icon: SF Symbol 아이콘 이름 (예: "fork.knife")
    ///   - color: 버튼 강조 색상
    ///   - action: 버튼 클릭 시 실행할 액션
    /// - Returns: 빠른 추가 버튼 뷰
    private func quickAddButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // 아이콘
                ZStack {
                    // 배경 원
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    // SF Symbol 아이콘
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }

                // 제목
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .background(buttonBackground)
        }
        .buttonStyle(PlainButtonStyle()) // 기본 버튼 스타일 제거
        .accessibilityLabel(title)
        .accessibilityHint("\(title) 화면으로 이동합니다")
    }

    /// 버튼 배경
    ///
    /// 버튼의 배경 스타일을 정의합니다.
    private var buttonBackground: some View {
        // 📚 학습 포인트: Material Background with Shadow
        // iOS 네이티브 느낌의 카드 디자인
        // 💡 Java 비교: Material CardView와 유사
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (라이트/다크 모드)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Light Mode") {
    VStack(spacing: 20) {
        QuickAddButtons(
            onAddFood: { print("Add Food") },
            onAddExercise: { print("Add Exercise") },
            onAddBodyComposition: { print("Add Body Composition") }
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        QuickAddButtons(
            onAddFood: { print("Add Food") },
            onAddExercise: { print("Add Exercise") },
            onAddBodyComposition: { print("Add Body Composition") }
        )
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("In Context") {
    ScrollView {
        VStack(spacing: 20) {
            // 날짜 헤더 (예시)
            Text("오늘")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            // 빠른 추가 버튼
            QuickAddButtons(
                onAddFood: { print("Add Food") },
                onAddExercise: { print("Add Exercise") },
                onAddBodyComposition: { print("Add Body Composition") }
            )

            // 다른 카드들 (예시)
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .frame(height: 200)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 16)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .frame(height: 200)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Quick Add Buttons 구현
///
/// ### 주요 개념
///
/// 1. **가로 스크롤 버튼 목록**
///    - ScrollView(.horizontal)로 가로 스크롤 구현
///    - HStack으로 버튼들을 나란히 배치
///    - showsIndicators: false로 스크롤 인디케이터 숨김
///
/// 2. **일관된 버튼 디자인**
///    - 모든 버튼이 동일한 크기와 스타일
///    - 색상만 다르게 하여 기능 구분
///    - SF Symbols 아이콘으로 직관적인 표현
///
/// 3. **콜백 패턴**
///    - onAddFood: 음식 추가 화면으로 이동
///    - onAddExercise: 운동 추가 화면으로 이동
///    - onAddBodyComposition: 체성분 기록 화면으로 이동
///    - 부모 View에서 실제 네비게이션 처리
///
/// 4. **색상 의미**
///    - 주황색 (orange): 음식 - 따뜻하고 식욕을 자극하는 색
///    - 초록색 (green): 운동 - 건강과 활력을 상징하는 색
///    - 파란색 (blue): 체성분 - 신뢰와 안정을 나타내는 색
///
/// 5. **접근성 (Accessibility)**
///    - accessibilityLabel: 각 버튼의 목적 명시
///    - accessibilityHint: 버튼 클릭 시 동작 설명
///    - VoiceOver 사용자를 위한 명확한 설명
///
/// ### 버튼 레이아웃 구조
///
/// ```swift
/// ScrollView(.horizontal) {
///     HStack {
///         Button {
///             VStack {
///                 ZStack {
///                     Circle()              // 배경 원
///                     Image(systemName:)    // 아이콘
///                 }
///                 Text(title)              // 제목
///             }
///         }
///     }
/// }
/// ```
///
/// ### 버튼 스타일
///
/// | 요소 | 스타일 | 설명 |
/// |------|--------|------|
/// | 아이콘 배경 | Circle, color.opacity(0.15) | 60x60pt 원형 배경 |
/// | 아이콘 | SF Symbol, size: 28 | 각 기능별 고유 아이콘 |
/// | 버튼 배경 | RoundedRectangle, systemBackground | 카드 스타일 배경 |
/// | 버튼 크기 | 120pt width | 일관된 버튼 크기 |
///
/// ### SF Symbols 선택
///
/// | 기능 | 아이콘 | 의미 |
/// |------|--------|------|
/// | 음식 추가 | fork.knife | 식사 도구 |
/// | 운동 추가 | figure.run | 달리기 동작 |
/// | 체성분 기록 | scalemass.fill | 체중계 |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | ScrollView(.horizontal) | HorizontalScrollView |
/// | HStack(spacing:) | LinearLayout(horizontal) |
/// | Button(action:) { ... } | Button.setOnClickListener { ... } |
/// | Circle().fill() | CircleShape with Modifier.background() |
/// | PlainButtonStyle() | Removes default ripple effect |
///
/// ### 모범 사례
///
/// 1. **재사용 가능한 버튼 컴포넌트**: quickAddButton() 함수로 중복 제거
/// 2. **명확한 콜백 이름**: onAddFood, onAddExercise 등 직관적인 이름
/// 3. **일관된 디자인**: 모든 버튼이 동일한 크기와 스타일
/// 4. **접근성 지원**: 모든 버튼에 명확한 라벨과 힌트
/// 5. **가로 스크롤**: 더 많은 버튼 추가 시에도 UI가 깨지지 않음
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// QuickAddButtons(
///     onAddFood: {
///         // 식단 탭으로 이동 또는 식단 추가 화면 표시
///         selectedTab = .diet
///     },
///     onAddExercise: {
///         // 운동 탭으로 이동 또는 운동 추가 화면 표시
///         selectedTab = .exercise
///     },
///     onAddBodyComposition: {
///         // 체성분 탭으로 이동 또는 체성분 입력 화면 표시
///         selectedTab = .body
///     }
/// )
/// ```
///
/// ### 향후 확장 가능성
///
/// 필요에 따라 더 많은 빠른 추가 버튼을 추가할 수 있습니다:
/// - 수면 기록 (moon.zzz.fill, 보라색)
/// - 수분 섭취 (drop.fill, 파란색)
/// - 기분 기록 (face.smiling.fill, 노란색)
/// - 메모 작성 (note.text, 회색)
///
/// 가로 스크롤 UI이므로 버튼을 추가해도 레이아웃이 깨지지 않습니다.
///
/// ### 디자인 의도
///
/// 이 컴포넌트는 사용자가 대시보드에서 빠르게 데이터를 기록할 수 있도록 합니다:
/// - **빠른 접근**: 한 번의 탭으로 원하는 기록 화면으로 이동
/// - **시각적 명확성**: 각 버튼의 색상과 아이콘으로 기능을 직관적으로 파악
/// - **일관된 UX**: 모든 버튼이 동일한 스타일로 사용자 혼란 최소화
/// - **확장 가능**: 새로운 빠른 추가 기능을 쉽게 추가 가능
///
/// 대시보드의 핵심 목표는 "한 곳에서 모든 것을 빠르게 관리"하는 것이므로,
/// 빠른 추가 버튼은 사용자 경험의 핵심 요소입니다.
///

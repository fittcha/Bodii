//
//  DateNavigationHeader.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Date Navigation Header Component
// 날짜 네비게이션 헤더 - 좌우 화살표로 날짜 이동, 중앙에 날짜 표시, 오늘로 돌아가기 버튼
// 💡 DashboardViewModel의 날짜 네비게이션 메서드와 연동하여 날짜별 데이터 조회

import SwiftUI

/// 날짜 네비게이션 헤더
///
/// 날짜를 전환하고 표시하는 헤더 컴포넌트입니다.
/// 좌우 화살표로 날짜를 이동하고, 중앙에 현재 선택된 날짜를 표시합니다.
///
/// **주요 기능:**
/// - 이전/다음 날짜로 이동 (좌우 화살표)
/// - 날짜 표시 (오늘, 어제, 또는 yyyy년 M월 d일 (요일) 형식)
/// - 오늘로 돌아가기 버튼
///
/// **날짜 표시 규칙:**
/// - 오늘: "오늘"
/// - 어제: "어제"
/// - 그 외: "2026년 1월 15일 (수)" 형식
///
/// - Note: DashboardViewModel과 연동하여 날짜별 DailyLog를 조회합니다.
///
/// - Example:
/// ```swift
/// DateNavigationHeader(
///     selectedDate: viewModel.selectedDate,
///     isToday: viewModel.isToday,
///     onPreviousDay: viewModel.goToPreviousDay,
///     onNextDay: viewModel.goToNextDay,
///     onToday: viewModel.goToToday
/// )
/// ```
struct DateNavigationHeader: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 현재 선택된 날짜
    let selectedDate: Date

    /// 오늘 날짜인지 여부
    let isToday: Bool

    /// 이전 날짜로 이동 콜백
    let onPreviousDay: () -> Void

    /// 다음 날짜로 이동 콜백
    let onNextDay: () -> Void

    /// 오늘로 돌아가기 콜백
    let onToday: () -> Void

    // MARK: - Computed Properties

    /// 선택된 날짜를 표시용 문자열로 변환
    ///
    /// - Returns: "오늘", "어제", 또는 "2026년 1월 15일 (수)" 형식의 문자열
    private var formattedDate: String {
        // 📚 학습 포인트: Date Comparison
        // Calendar를 사용하여 날짜 비교 및 포맷팅

        let calendar = Calendar.current

        if calendar.isDateInToday(selectedDate) {
            return "오늘"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "어제"
        } else {
            // 📚 학습 포인트: DateFormatter
            // 날짜를 사용자 친화적인 문자열로 변환
            // 로케일(locale)에 따라 자동으로 형식 조정
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 M월 d일 (E)"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: HStack with Spacing
        // 좌우 버튼과 중앙 날짜 표시를 수평으로 배치
        // 💡 Java 비교: Row(horizontalArrangement = SpaceBetween)과 유사
        HStack(spacing: 16) {
            // 이전 날짜 버튼
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
            }
            .accessibilityLabel("이전 날짜")
            .accessibilityHint("하루 전으로 이동합니다")

            Spacer()

            // 중앙 날짜 표시 및 오늘로 돌아가기 버튼
            Button(action: onToday) {
                HStack(spacing: 8) {
                    // 날짜 텍스트
                    Text(formattedDate)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    // 오늘이 아닐 때만 오늘로 돌아가기 아이콘 표시
                    if !isToday {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isToday ? Color(.systemGray6) : Color.blue.opacity(0.1))
                )
            }
            .disabled(isToday)
            .accessibilityLabel(isToday ? "오늘" : "오늘로 돌아가기")
            .accessibilityHint(isToday ? "현재 날짜입니다" : "오늘 날짜로 이동합니다")

            Spacer()

            // 다음 날짜 버튼
            Button(action: onNextDay) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
            }
            .accessibilityLabel("다음 날짜")
            .accessibilityHint("하루 후로 이동합니다")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (오늘/어제/다른 날짜)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Today") {
    VStack(spacing: 20) {
        // 오늘 날짜
        DateNavigationHeader(
            selectedDate: Date(),
            isToday: true,
            onPreviousDay: { print("Previous") },
            onNextDay: { print("Next") },
            onToday: { print("Today") }
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Yesterday") {
    VStack(spacing: 20) {
        // 어제 날짜
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        DateNavigationHeader(
            selectedDate: yesterday,
            isToday: false,
            onPreviousDay: { print("Previous") },
            onNextDay: { print("Next") },
            onToday: { print("Today") }
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Other Date") {
    VStack(spacing: 20) {
        // 다른 날짜 (3일 전)
        let otherDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        DateNavigationHeader(
            selectedDate: otherDate,
            isToday: false,
            onPreviousDay: { print("Previous") },
            onNextDay: { print("Next") },
            onToday: { print("Today") }
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Various Dates") {
    ScrollView {
        VStack(spacing: 20) {
            // 오늘
            DateNavigationHeader(
                selectedDate: Date(),
                isToday: true,
                onPreviousDay: { },
                onNextDay: { },
                onToday: { }
            )

            // 어제
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            DateNavigationHeader(
                selectedDate: yesterday,
                isToday: false,
                onPreviousDay: { },
                onNextDay: { },
                onToday: { }
            )

            // 3일 전
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            DateNavigationHeader(
                selectedDate: threeDaysAgo,
                isToday: false,
                onPreviousDay: { },
                onNextDay: { },
                onToday: { }
            )

            // 1주일 전
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            DateNavigationHeader(
                selectedDate: oneWeekAgo,
                isToday: false,
                onPreviousDay: { },
                onNextDay: { },
                onToday: { }
            )

            // 1개월 전
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            DateNavigationHeader(
                selectedDate: oneMonthAgo,
                isToday: false,
                onPreviousDay: { },
                onNextDay: { },
                onToday: { }
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Date Navigation Header 구현
///
/// ### 주요 개념
///
/// 1. **날짜 네비게이션 UI**
///    - 좌우 화살표 버튼으로 날짜 이동
///    - 중앙에 현재 선택된 날짜 표시
///    - 오늘로 돌아가기 버튼 (오늘이 아닐 때만 활성화)
///
/// 2. **날짜 표시 규칙**
///    - 오늘: "오늘" (간단 표시)
///    - 어제: "어제" (간단 표시)
///    - 그 외: "2026년 1월 15일 (수)" (전체 포맷)
///
/// 3. **콜백 패턴**
///    - onPreviousDay: 이전 날짜로 이동
///    - onNextDay: 다음 날짜로 이동
///    - onToday: 오늘로 돌아가기
///    - ViewModel의 메서드와 1:1 대응
///
/// 4. **조건부 UI**
///    - isToday가 true일 때: 오늘로 돌아가기 버튼 비활성화
///    - isToday가 false일 때: 파란색 아이콘 표시
///
/// 5. **접근성 (Accessibility)**
///    - 각 버튼에 accessibilityLabel 및 accessibilityHint 제공
///    - VoiceOver 사용자를 위한 명확한 설명
///
/// ### 레이아웃 구조
///
/// ```swift
/// HStack {
///     Button(chevron.left)      // 이전 날짜
///     Spacer()
///     Button(date + icon)        // 날짜 표시 / 오늘로 돌아가기
///     Spacer()
///     Button(chevron.right)      // 다음 날짜
/// }
/// ```
///
/// ### 날짜 포맷팅 로직
///
/// | 조건 | 표시 | 예시 |
/// |------|------|------|
/// | calendar.isDateInToday | "오늘" | "오늘" |
/// | calendar.isDateInYesterday | "어제" | "어제" |
/// | 그 외 | "yyyy년 M월 d일 (E)" | "2026년 1월 15일 (수)" |
///
/// ### 버튼 스타일
///
/// | 요소 | 스타일 | 설명 |
/// |------|--------|------|
/// | 좌우 화살표 | Circle, systemGray6 | 44x44pt 원형 버튼 |
/// | 날짜 표시 (오늘) | RoundedRectangle, systemGray6 | 회색 배경 |
/// | 날짜 표시 (다른 날) | RoundedRectangle, blue.opacity(0.1) | 파란색 배경 + 아이콘 |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | HStack(spacing: 16) | Row(horizontalArrangement = spacedBy(16.dp)) |
/// | Button(action:) { ... } | Button(onClick = { ... }) { ... } |
/// | Circle().fill() | CircleShape with Modifier.background() |
/// | Calendar.current | Calendar.getInstance() |
/// | DateFormatter | SimpleDateFormat |
///
/// ### 모범 사례
///
/// 1. **Props 명확화**: 날짜, 상태(isToday), 콜백 3가지로 단순화
/// 2. **Computed Properties**: formattedDate로 날짜 포맷팅 로직 분리
/// 3. **조건부 렌더링**: isToday에 따라 버튼 스타일 및 활성화 상태 변경
/// 4. **접근성 지원**: 모든 버튼에 명확한 라벨과 힌트 제공
/// 5. **일관된 스타일**: 앱 전체 디자인 시스템과 일치 (systemGray6, 원형 버튼)
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// DateNavigationHeader(
///     selectedDate: viewModel.selectedDate,
///     isToday: viewModel.isToday,
///     onPreviousDay: viewModel.goToPreviousDay,
///     onNextDay: viewModel.goToNextDay,
///     onToday: viewModel.goToToday
/// )
/// ```
///
/// ### ViewModel 연동
///
/// DashboardViewModel의 메서드와 1:1 대응:
/// - onPreviousDay → viewModel.goToPreviousDay()
/// - onNextDay → viewModel.goToNextDay()
/// - onToday → viewModel.goToToday()
///
/// ViewModel이 날짜를 변경하면 자동으로 DailyLog를 다시 로드합니다.
///
/// ### 디자인 의도
///
/// 이 헤더는 사용자가 날짜별 건강 데이터를 쉽게 탐색할 수 있도록 합니다:
/// - **직관적인 화살표**: 좌우로 날짜 이동
/// - **명확한 날짜 표시**: 오늘/어제/전체 날짜 자동 선택
/// - **빠른 복귀**: 오늘로 돌아가기 버튼으로 쉽게 현재 날짜로 복귀
/// - **시각적 피드백**: 오늘일 때와 다른 날일 때 다른 스타일 적용
///
/// 날짜 네비게이션은 데이터 탐색의 핵심 기능이므로,
/// 사용자가 직관적으로 이해하고 빠르게 조작할 수 있도록 설계했습니다.
///

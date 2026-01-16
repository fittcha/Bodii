//
//  DashboardSkeletonView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Skeleton Loading Views with Shimmer Effect
// 데이터 로딩 중 스켈레톤 뷰를 표시하여 더 나은 UX 제공
// 💡 Java 비교: Android의 Shimmer 라이브러리 또는 Placeholder API와 유사

import SwiftUI

// MARK: - Shimmer Effect Modifier

/// 스켈레톤 뷰에 적용할 Shimmer 효과
///
/// 반짝이는 애니메이션 효과를 제공하여 콘텐츠가 로딩 중임을 시각적으로 표현합니다.
///
/// ## 작동 원리
/// - LinearGradient로 그라데이션 효과 생성
/// - @State로 애니메이션 상태 관리
/// - onAppear에서 반복 애니메이션 시작
///
/// ## 사용 예시
/// ```swift
/// Rectangle()
///     .fill(Color(.systemGray5))
///     .frame(height: 20)
///     .shimmer()
/// ```
struct ShimmerModifier: ViewModifier {

    // MARK: - Properties

    /// 애니메이션 진행 상태 (0.0 ~ 1.0)
    /// 📚 학습 포인트: @State for Animation
    /// - 시간에 따라 변경되는 애니메이션 값 관리
    /// - 값 변경 시 자동으로 뷰 리렌더링
    /// 💡 Java 비교: Animated.Value in React Native와 유사
    @State private var phase: CGFloat = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(
                // 📚 학습 포인트: LinearGradient Shimmer
                // 반투명 그라데이션을 왼쪽에서 오른쪽으로 이동시켜 shimmer 효과 생성
                // 💡 Java 비교: Canvas의 LinearGradient + ObjectAnimator와 유사
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: -200 + phase * 400) // -200에서 +200까지 이동
                .mask(content) // content 모양대로만 표시
            )
            .onAppear {
                // 📚 학습 포인트: Repeating Animation
                // withAnimation을 사용하여 무한 반복 애니메이션 실행
                // 💡 Java 비교: ValueAnimator.setRepeatCount(INFINITE)와 유사
                withAnimation(
                    .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Shimmer 효과 적용
    ///
    /// 스켈레톤 뷰에 반짝이는 로딩 효과를 추가합니다.
    ///
    /// - Returns: Shimmer 효과가 적용된 뷰
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card Components

/// 칼로리 밸런스 카드 스켈레톤
///
/// CalorieBalanceCard의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct CalorieBalanceCardSkeleton: View {

    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                skeletonRectangle(width: 120, height: 24)
                Spacer()
            }

            // 원형 진행 표시기
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 200, height: 200)
                .shimmer()
                .padding(.vertical, 8)

            // 통계 섹션
            HStack(spacing: 16) {
                statItemSkeleton()
                Divider().frame(height: 40)
                statItemSkeleton()
                Divider().frame(height: 40)
                statItemSkeleton()
            }
            .padding(.horizontal, 8)

            // 상태 배지
            skeletonRectangle(width: 100, height: 32, cornerRadius: 20)
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// 통계 아이템 스켈레톤
    private func statItemSkeleton() -> some View {
        VStack(spacing: 4) {
            skeletonRectangle(width: 40, height: 12)
            skeletonRectangle(width: 60, height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 매크로 분석 카드 스켈레톤
///
/// MacroBreakdownCard의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct MacroBreakdownCardSkeleton: View {

    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                skeletonRectangle(width: 120, height: 24)
                Spacer()
            }

            // 매크로 진행 바 3개
            VStack(spacing: 16) {
                macroProgressBarSkeleton()
                macroProgressBarSkeleton()
                macroProgressBarSkeleton()
            }
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// 매크로 진행 바 스켈레톤
    private func macroProgressBarSkeleton() -> some View {
        VStack(spacing: 8) {
            // 헤더
            HStack {
                skeletonRectangle(width: 80, height: 16)
                Spacer()
                skeletonRectangle(width: 60, height: 16)
            }

            // 진행 바
            skeletonRectangle(height: 8, cornerRadius: 4)
        }
    }
}

/// 운동 요약 카드 스켈레톤
///
/// ExerciseSummaryCard의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct ExerciseSummaryCardSkeleton: View {

    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                skeletonRectangle(width: 100, height: 24)
                Spacer()
            }

            // 통계 3개
            HStack(spacing: 12) {
                exerciseStatSkeleton()
                exerciseStatSkeleton()
                exerciseStatSkeleton()
            }
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// 운동 통계 아이템 스켈레톤
    private func exerciseStatSkeleton() -> some View {
        VStack(spacing: 12) {
            // 아이콘
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)
                .shimmer()

            // 값
            skeletonRectangle(width: 60, height: 20)

            // 라벨
            skeletonRectangle(width: 50, height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

/// 수면 품질 카드 스켈레톤
///
/// SleepQualityCard의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct SleepQualityCardSkeleton: View {

    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                skeletonRectangle(width: 100, height: 24)
                Spacer()
            }

            // 수면 정보
            HStack(spacing: 20) {
                // 이모지 인디케이터
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .shimmer()

                VStack(alignment: .leading, spacing: 8) {
                    // 수면 시간
                    skeletonRectangle(width: 100, height: 28)

                    // 수면 품질
                    skeletonRectangle(width: 80, height: 16)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// 체성분 카드 스켈레톤
///
/// BodyCompositionCard의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct BodyCompositionCardSkeleton: View {

    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                skeletonRectangle(width: 100, height: 24)
                Spacer()
            }

            // 체성분 정보
            HStack(spacing: 16) {
                // 체중
                bodyStatSkeleton()

                Divider().frame(height: 60)

                // 체지방률
                bodyStatSkeleton()
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// 체성분 통계 아이템 스켈레톤
    private func bodyStatSkeleton() -> some View {
        VStack(spacing: 8) {
            // 라벨
            skeletonRectangle(width: 50, height: 12)

            // 값
            skeletonRectangle(width: 70, height: 32)

            // 변화량
            skeletonRectangle(width: 60, height: 16)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 날짜 네비게이션 헤더 스켈레톤
///
/// DateNavigationHeader의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct DateNavigationHeaderSkeleton: View {

    var body: some View {
        HStack {
            // 이전 버튼
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 40, height: 40)
                .shimmer()

            Spacer()

            // 날짜 표시
            skeletonRectangle(width: 120, height: 24, cornerRadius: 12)

            Spacer()

            // 다음 버튼
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 40, height: 40)
                .shimmer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// 빠른 추가 버튼 스켈레톤
///
/// QuickAddButtons의 로딩 상태를 표현하는 스켈레톤 뷰입니다.
struct QuickAddButtonsSkeleton: View {

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 120, height: 80)
                        .shimmer()
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Helper Functions

/// 스켈레톤 사각형
///
/// Shimmer 효과가 적용된 사각형을 생성합니다.
///
/// - Parameters:
///   - width: 너비 (nil이면 maxWidth 사용)
///   - height: 높이
///   - cornerRadius: 모서리 둥글기 (기본값: 8)
/// - Returns: Shimmer 효과가 적용된 사각형 뷰
private func skeletonRectangle(
    width: CGFloat? = nil,
    height: CGFloat,
    cornerRadius: CGFloat = 8
) -> some View {
    Group {
        if let width = width {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemGray5))
                .frame(width: width, height: height)
                .shimmer()
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemGray5))
                .frame(height: height)
                .shimmer()
        }
    }
}

/// 카드 배경 (모든 스켈레톤 카드에서 공통으로 사용)
private var cardBackground: some View {
    RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
}

// MARK: - Full Dashboard Skeleton

/// 전체 대시보드 스켈레톤 뷰
///
/// 대시보드의 모든 컴포넌트를 스켈레톤 형태로 표시합니다.
/// 데이터 로딩 중일 때 사용합니다.
///
/// ## 사용 예시
/// ```swift
/// if viewModel.isLoading {
///     DashboardSkeletonView()
/// } else {
///     // 실제 대시보드 컨텐츠
/// }
/// ```
struct DashboardSkeletonView: View {

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 날짜 네비게이션 헤더
                DateNavigationHeaderSkeleton()

                // 빠른 추가 버튼
                QuickAddButtonsSkeleton()

                // 칼로리 밸런스 카드
                CalorieBalanceCardSkeleton()

                // 매크로 분석 카드
                MacroBreakdownCardSkeleton()

                // 운동 요약 카드
                ExerciseSummaryCardSkeleton()

                // 수면 품질 카드
                SleepQualityCardSkeleton()

                // 체성분 카드
                BodyCompositionCardSkeleton()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Preview

#Preview("전체 대시보드 스켈레톤") {
    NavigationStack {
        DashboardSkeletonView()
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("개별 카드 스켈레톤") {
    ScrollView {
        VStack(spacing: 20) {
            Text("칼로리 밸런스").font(.headline)
            CalorieBalanceCardSkeleton()

            Text("매크로 분석").font(.headline)
            MacroBreakdownCardSkeleton()

            Text("운동 요약").font(.headline)
            ExerciseSummaryCardSkeleton()

            Text("수면 품질").font(.headline)
            SleepQualityCardSkeleton()

            Text("체성분").font(.headline)
            BodyCompositionCardSkeleton()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("날짜 헤더 & 빠른 추가") {
    VStack(spacing: 20) {
        DateNavigationHeaderSkeleton()
        QuickAddButtonsSkeleton()
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Shimmer Effect 구현
///
/// ### 주요 개념
///
/// 1. **LinearGradient 애니메이션**
///    - 투명 → 반투명 흰색 → 투명 그라데이션 생성
///    - offset을 애니메이션하여 왼쪽에서 오른쪽으로 이동
///    - mask()로 콘텐츠 모양대로만 표시
///
/// 2. **ViewModifier 패턴**
///    - 재사용 가능한 modifier 생성 (ShimmerModifier)
///    - View extension으로 .shimmer() 메서드 제공
///    - 모든 뷰에 적용 가능
///
/// 3. **@State 애니메이션**
///    - phase 값을 0에서 1로 애니메이션
///    - repeatForever로 무한 반복
///    - linear duration 1.5초로 부드러운 효과
///
/// 4. **스켈레톤 컴포넌트 구조**
///    - 각 카드별 전용 스켈레톤 뷰 생성
///    - 실제 카드의 레이아웃을 최대한 유사하게 구현
///    - 일관된 회색 톤(systemGray5) 사용
///
/// 5. **Helper 함수 활용**
///    - skeletonRectangle(): 재사용 가능한 스켈레톤 사각형
///    - cardBackground: 모든 카드에서 공통으로 사용하는 배경
///    - 코드 중복 최소화
///
/// ### Shimmer 애니메이션 상세
///
/// ```swift
/// // 1. 그라데이션 생성
/// LinearGradient(
///     gradient: Gradient(colors: [.clear, .white.opacity(0.4), .clear]),
///     startPoint: .leading,
///     endPoint: .trailing
/// )
///
/// // 2. offset으로 위치 이동
/// .offset(x: -200 + phase * 400)  // -200 → +200
///
/// // 3. mask로 모양 제한
/// .mask(content)
///
/// // 4. 애니메이션 시작
/// withAnimation(.linear(duration: 1.5).repeatForever()) {
///     phase = 1
/// }
/// ```
///
/// ### 모범 사례
///
/// 1. **일관된 색상 사용**: systemGray5로 통일
/// 2. **실제 레이아웃 모방**: 사용자가 무엇을 기다리는지 알 수 있도록
/// 3. **부드러운 애니메이션**: 1.5초 duration으로 너무 빠르지 않게
/// 4. **재사용 가능한 컴포넌트**: 각 카드별 스켈레톤 분리
/// 5. **Preview 제공**: 개발 시 쉽게 확인 가능
///
/// ### Swift vs Java/Android
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | ViewModifier | Custom View class |
/// | .shimmer() | view.setShimmer() |
/// | withAnimation | ValueAnimator |
/// | LinearGradient | LinearGradient shader |
/// | @State | mutable state |
///
/// ### 사용 시나리오
///
/// 1. **초기 로딩**: 앱 시작 시 데이터 로딩 중
/// 2. **페이지 전환**: 새 화면으로 이동 시
/// 3. **새로고침**: Pull-to-refresh 동작 시
/// 4. **네트워크 요청**: API 호출 중
///
/// ### 성능 최적화
///
/// - LinearGradient 대신 Shape.trim()도 가능하지만 시각적 효과가 덜 함
/// - 애니메이션 duration을 너무 짧게 하면 산만함
/// - 너무 많은 스켈레톤 뷰는 성능 저하 가능 (현재 구현은 적절)
///
/// ### UX 고려사항
///
/// 1. **예측 가능성**: 실제 콘텐츠와 유사한 형태
/// 2. **진행 표시**: 무언가 일어나고 있음을 알림
/// 3. **로딩 시간 체감 감소**: 빈 화면보다 덜 답답함
/// 4. **전문적인 느낌**: 최신 앱의 표준 UX 패턴
///

//
//  MacroBreakdownCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-15.
//

// 📚 학습 포인트: Macro Breakdown Card Component
// 일일 매크로 영양소(탄수화물/단백질/지방) 분석 카드
// 💡 가로 진행 바(horizontal progress bars)로 비율과 실제 섭취량을 시각화

import SwiftUI

/// 매크로 영양소 분석 카드
///
/// 탄수화물, 단백질, 지방의 섭취량과 비율을 가로 진행 바로 시각화합니다.
/// 각 영양소의 실제 그램 수와 전체 칼로리 대비 비율을 함께 표시합니다.
///
/// **색상 규칙:**
/// - 탄수화물: 파란색
/// - 단백질: 주황색
/// - 지방: 보라색
///
/// - Note: DailyLog의 사전 계산된 값을 사용하여 빠른 렌더링을 보장합니다.
///
/// - Example:
/// ```swift
/// MacroBreakdownCard(
///     totalCarbs: 187.5,
///     totalProtein: 93.75,
///     totalFat: 41.67,
///     carbsRatio: 50.0,
///     proteinRatio: 25.0,
///     fatRatio: 25.0
/// )
/// ```
struct MacroBreakdownCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 총 탄수화물 (g)
    let totalCarbs: Decimal

    /// 총 단백질 (g)
    let totalProtein: Decimal

    /// 총 지방 (g)
    let totalFat: Decimal

    /// 탄수화물 비율 (%)
    let carbsRatio: Decimal?

    /// 단백질 비율 (%)
    let proteinRatio: Decimal?

    /// 지방 비율 (%)
    let fatRatio: Decimal?

    /// 음식 추가 콜백 (Empty State에서 사용)
    var onAddFood: (() -> Void)? = nil

    // MARK: - Constants

    /// 진행 바 높이
    private let barHeight: CGFloat = 12

    /// 매크로 영양소 색상
    private let carbsColor: Color = .blue
    private let proteinColor: Color = .orange
    private let fatColor: Color = .purple

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 여부
    private var isEmpty: Bool {
        totalCarbs == 0 && totalProtein == 0 && totalFat == 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 제목 섹션
            titleSection

            // 📚 학습 포인트: Conditional Rendering - Empty State vs Content
            // 데이터 유무에 따라 Empty State 또는 실제 컨텐츠 표시
            if isEmpty {
                // Empty State: 음식 기록이 없을 때
                FoodEmptyState(onAddFood: onAddFood)
                    .padding(.vertical, 8)
            } else {
                // 실제 컨텐츠: 데이터가 있을 때
                // 매크로 영양소 목록
                VStack(spacing: 16) {
                    // 탄수화물
                    macroProgressBar(
                        name: "탄수화물",
                        amount: totalCarbs,
                        ratio: carbsRatio,
                        color: carbsColor,
                        icon: "cube.fill"
                    )

                    // 단백질
                    macroProgressBar(
                        name: "단백질",
                        amount: totalProtein,
                        ratio: proteinRatio,
                        color: proteinColor,
                        icon: "flame.fill"
                    )

                    // 지방
                    macroProgressBar(
                        name: "지방",
                        amount: totalFat,
                        ratio: fatRatio,
                        color: fatColor,
                        icon: "drop.fill"
                    )
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("매크로 영양소 카드")
    }

    // MARK: - View Components

    /// 제목 섹션
    private var titleSection: some View {
        HStack {
            Text("매크로 영양소")
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

    /// 매크로 영양소 진행 바
    ///
    /// 개별 매크로 영양소의 섭취량과 비율을 가로 진행 바로 표시합니다.
    ///
    /// - Parameters:
    ///   - name: 영양소 이름 (예: "탄수화물")
    ///   - amount: 섭취량 (g)
    ///   - ratio: 비율 (%, 없으면 nil)
    ///   - color: 진행 바 색상
    ///   - icon: SF Symbol 아이콘 이름
    /// - Returns: 진행 바 뷰
    private func macroProgressBar(
        name: String,
        amount: Decimal,
        ratio: Decimal?,
        color: Color,
        icon: String
    ) -> some View {
        VStack(spacing: 8) {
            // 📚 학습 포인트: 헤더 레이아웃 (아이콘, 이름, 수치)
            // HStack으로 좌우 정렬, Spacer()로 양끝 배치
            HStack {
                // 아이콘과 이름
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(isEmpty ? .secondary : color)

                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(isEmpty ? .secondary : .primary)
                }

                Spacer()

                // 수치 (그램과 비율)
                HStack(spacing: 8) {
                    // 섭취량
                    Text("\(formattedDecimal(amount))g")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isEmpty ? .secondary : .primary)

                    // 비율 배지
                    if let ratio = ratio {
                        Text("\(formattedDecimal(ratio))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(color.opacity(0.15))
                            )
                    } else {
                        Text("-%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray5))
                            )
                    }
                }
            }

            // 📚 학습 포인트: Horizontal Progress Bar
            // GeometryReader로 부모 너비를 받아 비율만큼 채우기
            // 💡 Java 비교: LinearLayout with weight 또는 Box with fillMaxWidth()와 유사
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 (회색)
                    RoundedRectangle(cornerRadius: barHeight / 2)
                        .fill(Color(.systemGray5))
                        .frame(height: barHeight)

                    // 진행 (색상)
                    if let ratio = ratio {
                        RoundedRectangle(cornerRadius: barHeight / 2)
                            .fill(isEmpty ? Color(.systemGray4) : color)
                            .frame(
                                width: min(
                                    geometry.size.width * CGFloat(truncating: ratio as NSNumber) / 100,
                                    geometry.size.width
                                ),
                                height: barHeight
                            )
                            .animation(.easeInOut(duration: 0.3), value: ratio)
                    }
                }
            }
            .frame(height: barHeight)
        }
        // 📚 학습 포인트: Accessibility for Progress Bar
        // 진행 바의 정보를 VoiceOver로 읽을 수 있도록 함
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue("\(formattedDecimal(amount)) 그램, \(ratio != nil ? formattedDecimal(ratio!) + " 퍼센트" : "비율 없음")")
    }

    // MARK: - Helpers

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
        formatter.minimumFractionDigits = 0
        return formatter.string(from: nsDecimal) ?? "0"
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (균형 잡힌/고탄수/고단백/빈 상태)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Balanced Macros") {
    VStack(spacing: 20) {
        // 균형 잡힌 매크로 (50/25/25)
        MacroBreakdownCard(
            totalCarbs: 187.5,
            totalProtein: 93.75,
            totalFat: 41.67,
            carbsRatio: 50.0,
            proteinRatio: 25.0,
            fatRatio: 25.0
        )

        // 균형 잡힌 매크로 (40/30/30)
        MacroBreakdownCard(
            totalCarbs: 150.0,
            totalProtein: 112.5,
            totalFat: 50.0,
            carbsRatio: 40.0,
            proteinRatio: 30.0,
            fatRatio: 30.0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("High Carb Diet") {
    VStack(spacing: 20) {
        // 고탄수 식단 (70/15/15)
        MacroBreakdownCard(
            totalCarbs: 367.5,
            totalProtein: 78.75,
            totalFat: 35.0,
            carbsRatio: 70.0,
            proteinRatio: 15.0,
            fatRatio: 15.0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("High Protein Diet") {
    VStack(spacing: 20) {
        // 고단백 식단 (30/40/30)
        MacroBreakdownCard(
            totalCarbs: 112.5,
            totalProtein: 150.0,
            totalFat: 50.0,
            carbsRatio: 30.0,
            proteinRatio: 40.0,
            fatRatio: 30.0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Keto Diet") {
    VStack(spacing: 20) {
        // 케토 식단 (10/20/70)
        MacroBreakdownCard(
            totalCarbs: 37.5,
            totalProtein: 75.0,
            totalFat: 116.67,
            carbsRatio: 10.0,
            proteinRatio: 20.0,
            fatRatio: 70.0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    VStack {
        // 데이터 없음 - 회색 톤으로 표시
        MacroBreakdownCard(
            totalCarbs: 0,
            totalProtein: 0,
            totalFat: 0,
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Partial Data") {
    ScrollView {
        VStack(spacing: 20) {
            // 아침 식사만 입력 (작은 수치)
            MacroBreakdownCard(
                totalCarbs: 45.0,
                totalProtein: 12.0,
                totalFat: 8.0,
                carbsRatio: 65.0,
                proteinRatio: 20.0,
                fatRatio: 15.0
            )

            // 점심까지 입력 (중간 수치)
            MacroBreakdownCard(
                totalCarbs: 120.0,
                totalProtein: 60.0,
                totalFat: 30.0,
                carbsRatio: 55.0,
                proteinRatio: 25.0,
                fatRatio: 20.0
            )

            // 하루 종일 입력 (큰 수치)
            MacroBreakdownCard(
                totalCarbs: 280.0,
                totalProtein: 140.0,
                totalFat: 70.0,
                carbsRatio: 52.0,
                proteinRatio: 28.0,
                fatRatio: 20.0
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Horizontal Progress Bar 구현
///
/// ### 주요 개념
///
/// 1. **GeometryReader를 사용한 동적 너비 계산**
///    - 부모 컨테이너의 너비를 받아 비율만큼 채우기
///    - `geometry.size.width * (ratio / 100)` 형태로 계산
///    - min()으로 최대 너비 제한 (100% 초과 방지)
///
/// 2. **ZStack 레이어링**
///    - 배경 바 (회색, 100% 너비)
///    - 진행 바 (색상, 비율만큼만 너비)
///    - `alignment: .leading`으로 왼쪽 정렬
///
/// 3. **RoundedRectangle로 둥근 모서리**
///    - `cornerRadius: barHeight / 2`로 완전히 둥근 끝 처리
///    - 양쪽 끝이 캡슐 모양으로 표현됨
///
/// 4. **애니메이션 적용**
///    - `.animation(.easeInOut(duration: 0.3), value: ratio)`
///    - 비율 변경 시 부드럽게 전환
///    - 사용자 경험 향상
///
/// 5. **색상 규칙 (Color Coding)**
///    - 탄수화물: 파란색 - 에너지원
///    - 단백질: 주황색 - 근육 성장
///    - 지방: 보라색 - 호르몬 조절
///
/// ### GeometryReader 사용법
///
/// ```swift
/// GeometryReader { geometry in
///     // geometry.size.width: 부모의 너비
///     // geometry.size.height: 부모의 높이
///     Rectangle()
///         .frame(width: geometry.size.width * 0.5) // 50% 너비
/// }
/// ```
///
/// - GeometryReader는 부모가 제공하는 공간을 측정
/// - 클로저 내부에서 geometry.size로 접근 가능
/// - 반응형 레이아웃 구현에 필수
///
/// ### Optional 비율 처리
///
/// ```swift
/// if let ratio = ratio {
///     // 비율이 있을 때만 진행 바 표시
///     Rectangle()
///         .frame(width: width * ratio / 100)
/// }
/// ```
///
/// - carbsRatio/proteinRatio/fatRatio는 Optional (Decimal?)
/// - 음식 기록이 없으면 nil
/// - nil일 때는 진행 바를 표시하지 않음
///
/// ### 수치 표시 레이아웃
///
/// ```swift
/// HStack {
///     // 왼쪽: 아이콘 + 이름
///     HStack(spacing: 6) {
///         Image(systemName: "cube.fill")
///         Text("탄수화물")
///     }
///
///     Spacer() // 중앙 공간
///
///     // 오른쪽: 그램 + 비율 배지
///     HStack(spacing: 8) {
///         Text("187.5g")
///         Text("50%")
///             .padding(...)
///             .background(...)
///     }
/// }
/// ```
///
/// - Spacer()로 좌우 양끝 정렬
/// - 비율 배지는 색상별로 구분하여 직관성 향상
///
/// ### 매크로 영양소별 아이콘
///
/// | 영양소 | 아이콘 | 의미 |
/// |--------|--------|------|
/// | 탄수화물 | cube.fill | 블록/큐브 - 에너지 단위 |
/// | 단백질 | flame.fill | 불꽃 - 연소/대사 |
/// | 지방 | drop.fill | 물방울 - 액체 형태 |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | GeometryReader | onSizeChanged() modifier |
/// | ZStack(alignment: .leading) | Box(contentAlignment = Start) |
/// | RoundedRectangle | RoundedCornerShape |
/// | .animation() | animateFloatAsState() |
/// | Decimal | BigDecimal |
///
/// ### 모범 사례
///
/// 1. **Props 최소화**: 필요한 6가지 값만 받기 (carbs, protein, fat + 각 ratio)
/// 2. **nil 처리**: 비율이 없을 때도 UI가 깨지지 않도록 처리
/// 3. **색상 일관성**: 앱 전체에서 같은 색상 규칙 사용
/// 4. **애니메이션**: 데이터 변경 시 부드러운 전환 효과
/// 5. **의미 있는 아이콘**: 각 영양소의 특성을 나타내는 아이콘 선택
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// if let dailyLog = viewModel.dailyLog {
///     MacroBreakdownCard(
///         totalCarbs: dailyLog.totalCarbs,
///         totalProtein: dailyLog.totalProtein,
///         totalFat: dailyLog.totalFat,
///         carbsRatio: dailyLog.carbsRatio,
///         proteinRatio: dailyLog.proteinRatio,
///         fatRatio: dailyLog.fatRatio
///     )
/// }
/// ```
///
/// ### 성능 최적화
///
/// - DailyLog의 사전 계산된 값 사용
/// - 추가 계산 없이 바로 표시 가능
/// - <0.5s 로딩 목표 달성에 기여
///
/// ### 접근성 (Accessibility)
///
/// - VoiceOver: "탄수화물 187.5그램, 50퍼센트"로 읽힘
/// - Dynamic Type: 시스템 폰트 크기에 자동 대응
/// - 색맹 지원: 아이콘과 텍스트로 색상만 의존하지 않음
///

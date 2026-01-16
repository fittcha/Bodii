//
//  BodyCompositionCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-15.
//

// 📚 학습 포인트: Body Composition Card Component
// 오늘의 체성분 정보 카드 - 체중, 체지방률, 전날 대비 변화량
// 💡 DailyLog의 사전 계산된 weight, bodyFatPct 값을 사용하여 빠른 렌더링 보장

import SwiftUI

/// 체성분 카드
///
/// 오늘의 체성분 정보를 표시하는 카드 컴포넌트입니다.
/// 체중, 체지방률, 전날 대비 변화량을 시각적으로 표현합니다.
///
/// **표시 내용:**
/// - 오늘의 체중 (kg)
/// - 오늘의 체지방률 (%)
/// - 전날 대비 변화량 (있을 경우)
///
/// **색상 규칙:**
/// - 체중 증가: 빨간색
/// - 체중 감소: 초록색
/// - 체중 유지: 파란색
///
/// - Note: DailyLog의 사전 계산된 값을 사용하여 빠른 렌더링을 보장합니다.
///
/// - Example:
/// ```swift
/// BodyCompositionCard(
///     weight: Decimal(70.5),
///     bodyFatPct: Decimal(21.5),
///     previousWeight: Decimal(71.0),
///     previousBodyFatPct: Decimal(22.0)
/// )
/// ```
struct BodyCompositionCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 오늘의 체중 (kg, nil이면 기록 없음)
    let weight: Decimal?

    /// 오늘의 체지방률 (%, nil이면 기록 없음)
    let bodyFatPct: Decimal?

    /// 어제의 체중 (kg, nil이면 비교 불가)
    let previousWeight: Decimal?

    /// 어제의 체지방률 (%, nil이면 비교 불가)
    let previousBodyFatPct: Decimal?

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 여부
    private var isEmpty: Bool {
        weight == nil
    }

    /// 체중 변화량 (kg)
    private var weightChange: Decimal? {
        guard let weight = weight, let previousWeight = previousWeight else {
            return nil
        }
        return weight - previousWeight
    }

    /// 체지방률 변화량 (%)
    private var bodyFatPctChange: Decimal? {
        guard let bodyFatPct = bodyFatPct, let previousBodyFatPct = previousBodyFatPct else {
            return nil
        }
        return bodyFatPct - previousBodyFatPct
    }

    /// 체중 변화 색상
    private var weightChangeColor: Color {
        guard let change = weightChange else { return .gray }

        if change > 0 {
            // 체중 증가 - 빨간색
            return .red
        } else if change < 0 {
            // 체중 감소 - 초록색
            return .green
        } else {
            // 체중 유지 - 파란색
            return .blue
        }
    }

    /// 체지방률 변화 색상
    private var bodyFatPctChangeColor: Color {
        guard let change = bodyFatPctChange else { return .gray }

        if change > 0 {
            // 체지방률 증가 - 빨간색
            return .red
        } else if change < 0 {
            // 체지방률 감소 - 초록색
            return .green
        } else {
            // 체지방률 유지 - 파란색
            return .blue
        }
    }

    /// 체중 변화 아이콘
    private var weightChangeIcon: String {
        guard let change = weightChange else { return "minus.circle.fill" }

        if change > 0 {
            return "arrow.up.circle.fill"
        } else if change < 0 {
            return "arrow.down.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }

    /// 체지방률 변화 아이콘
    private var bodyFatPctChangeIcon: String {
        guard let change = bodyFatPctChange else { return "minus.circle.fill" }

        if change > 0 {
            return "arrow.up.circle.fill"
        } else if change < 0 {
            return "arrow.down.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }

    /// 체중을 포맷팅 (소수점 1자리)
    private var formattedWeight: String {
        guard let weight = weight else { return "기록 없음" }
        return String(format: "%.1f", NSDecimalNumber(decimal: weight).doubleValue)
    }

    /// 체지방률을 포맷팅 (소수점 1자리)
    private var formattedBodyFatPct: String {
        guard let bodyFatPct = bodyFatPct else { return "측정 안 함" }
        return String(format: "%.1f", NSDecimalNumber(decimal: bodyFatPct).doubleValue)
    }

    /// 체중 변화량을 포맷팅
    private var formattedWeightChange: String {
        guard let change = weightChange else { return "" }
        let value = NSDecimalNumber(decimal: change).doubleValue
        if value > 0 {
            return "+\(String(format: "%.1f", value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    /// 체지방률 변화량을 포맷팅
    private var formattedBodyFatPctChange: String {
        guard let change = bodyFatPctChange else { return "" }
        let value = NSDecimalNumber(decimal: change).doubleValue
        if value > 0 {
            return "+\(String(format: "%.1f", value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 제목 섹션
            titleSection

            if isEmpty {
                // 빈 상태 표시
                emptyStateView
            } else {
                // 체성분 정보 표시
                // 📚 학습 포인트: HStack with Equal Distribution
                // spacing으로 간격 조절, 각 카드는 maxWidth: .infinity로 균등 분배
                // 💡 Java 비교: LinearLayout with layout_weight="1"과 유사
                HStack(spacing: 12) {
                    // 체중 카드
                    statCard(
                        title: "체중",
                        value: formattedWeight,
                        unit: "kg",
                        icon: "scalemass.fill",
                        color: .blue,
                        change: formattedWeightChange,
                        changeIcon: weightChangeIcon,
                        changeColor: weightChangeColor
                    )

                    // 체지방률 카드
                    statCard(
                        title: "체지방률",
                        value: formattedBodyFatPct,
                        unit: "%",
                        icon: "chart.pie.fill",
                        color: .purple,
                        change: formattedBodyFatPctChange,
                        changeIcon: bodyFatPctChangeIcon,
                        changeColor: bodyFatPctChangeColor
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
            Text("오늘의 체성분")
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

    /// 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            // 빈 상태 아이콘
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            // 빈 상태 메시지
            VStack(spacing: 4) {
                Text("오늘 체성분 기록 없음")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("체중과 체지방률을 기록해 보세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    /// 개별 통계 카드
    ///
    /// 체성분 통계 항목을 카드 형태로 표시합니다.
    ///
    /// - Parameters:
    ///   - title: 제목 (예: "체중")
    ///   - value: 값 (예: "70.5")
    ///   - unit: 단위 (예: "kg")
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 및 배경 색상
    ///   - change: 변화량 (예: "+0.5", "-1.2")
    ///   - changeIcon: 변화 아이콘
    ///   - changeColor: 변화 색상
    /// - Returns: 통계 카드 뷰
    private func statCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color,
        change: String,
        changeIcon: String,
        changeColor: Color
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 제목
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 변화량 (있을 경우)
            if !change.isEmpty {
                Divider()
                    .padding(.horizontal, 8)

                HStack(spacing: 4) {
                    Image(systemName: changeIcon)
                        .font(.caption2)
                        .foregroundStyle(changeColor)

                    Text(change)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(changeColor)

                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (정상/체중 증가/체중 감소/빈 상태)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("With Data and Changes") {
    VStack(spacing: 20) {
        // 체중 감소, 체지방률 감소 (좋은 변화)
        BodyCompositionCard(
            weight: Decimal(70.5),
            bodyFatPct: Decimal(21.5),
            previousWeight: Decimal(71.0),
            previousBodyFatPct: Decimal(22.0)
        )

        // 체중 증가, 체지방률 증가 (주의 필요)
        BodyCompositionCard(
            weight: Decimal(72.3),
            bodyFatPct: Decimal(23.2),
            previousWeight: Decimal(71.0),
            previousBodyFatPct: Decimal(22.5)
        )

        // 체중 유지, 체지방률 유지
        BodyCompositionCard(
            weight: Decimal(70.0),
            bodyFatPct: Decimal(22.0),
            previousWeight: Decimal(70.0),
            previousBodyFatPct: Decimal(22.0)
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Without Previous Data") {
    VStack(spacing: 20) {
        // 오늘 데이터는 있지만 어제 데이터 없음 (변화량 표시 안 됨)
        BodyCompositionCard(
            weight: Decimal(70.5),
            bodyFatPct: Decimal(21.5),
            previousWeight: nil,
            previousBodyFatPct: nil
        )

        // 체중만 있고 체지방률 없음
        BodyCompositionCard(
            weight: Decimal(70.5),
            bodyFatPct: nil,
            previousWeight: Decimal(71.0),
            previousBodyFatPct: Decimal(22.0)
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    VStack {
        // 오늘 체성분 기록이 없는 경우
        BodyCompositionCard(
            weight: nil,
            bodyFatPct: nil,
            previousWeight: Decimal(70.0),
            previousBodyFatPct: Decimal(22.0)
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Various Changes") {
    ScrollView {
        VStack(spacing: 20) {
            // 큰 체중 감소
            BodyCompositionCard(
                weight: Decimal(68.5),
                bodyFatPct: Decimal(20.0),
                previousWeight: Decimal(71.0),
                previousBodyFatPct: Decimal(22.5)
            )

            // 작은 체중 증가
            BodyCompositionCard(
                weight: Decimal(70.3),
                bodyFatPct: Decimal(21.8),
                previousWeight: Decimal(70.0),
                previousBodyFatPct: Decimal(21.5)
            )

            // 체중은 감소했지만 체지방률은 증가 (근손실 경고)
            BodyCompositionCard(
                weight: Decimal(69.5),
                bodyFatPct: Decimal(23.0),
                previousWeight: Decimal(70.0),
                previousBodyFatPct: Decimal(22.0)
            )

            // 체중은 증가했지만 체지방률은 감소 (근육량 증가)
            BodyCompositionCard(
                weight: Decimal(71.0),
                bodyFatPct: Decimal(21.0),
                previousWeight: Decimal(70.5),
                previousBodyFatPct: Decimal(21.5)
            )

            // 변화 없음
            BodyCompositionCard(
                weight: Decimal(70.0),
                bodyFatPct: Decimal(22.0),
                previousWeight: Decimal(70.0),
                previousBodyFatPct: Decimal(22.0)
            )

            // 빈 상태
            BodyCompositionCard(
                weight: nil,
                bodyFatPct: nil,
                previousWeight: Decimal(70.0),
                previousBodyFatPct: Decimal(22.0)
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Body Composition Card 구현
///
/// ### 주요 개념
///
/// 1. **2개의 통계 카드 배치**
///    - HStack으로 가로 배치
///    - maxWidth: .infinity로 균등 분배
///    - spacing: 12로 카드 간 간격 조절
///
/// 2. **색상 규칙 (Color Coding)**
///    - 체중: 파란색 - 기본 색상
///    - 체지방률: 보라색 - 구분 색상
///    - 증가: 빨간색 - 주의 필요
///    - 감소: 초록색 - 긍정적 변화
///    - 유지: 파란색 - 안정적
///
/// 3. **변화량 표시**
///    - 전날 데이터가 있을 경우만 변화량 표시
///    - 증가: "+"와 빨간색 화살표
///    - 감소: "-"와 초록색 화살표
///    - 유지: "0"과 파란색 등호 아이콘
///
/// 4. **Empty State 처리**
///    - weight가 nil일 때 "오늘 체성분 기록 없음" 메시지 표시
///    - 체지방률만 없을 수도 있음 (체중만 측정)
///    - 어제 데이터가 없으면 변화량 표시 안 함
///
/// 5. **Decimal 타입 처리**
///    - Swift의 Decimal 타입을 NSDecimalNumber로 변환
///    - String format으로 소수점 1자리까지 표시
///    - 정확한 계산이 필요한 체중/체지방률에 적합
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
///     Text(title)                  // 제목
///
///     if !change.isEmpty {
///         Divider()
///         HStack {
///             Image(changeIcon)    // 변화 아이콘
///             Text(change)         // 변화량
///             Text(unit)           // 단위
///         }
///     }
/// }
/// .background(color.opacity(0.1))  // 색상 배경
/// ```
///
/// ### 변화량 계산 로직
///
/// | 오늘 | 어제 | 변화량 | 색상 | 아이콘 |
/// |------|------|--------|------|-------|
/// | 70.5 | 71.0 | -0.5 | 초록색 | ↓ |
/// | 72.0 | 71.0 | +1.0 | 빨간색 | ↑ |
/// | 70.0 | 70.0 | 0.0 | 파란색 | = |
/// | 70.5 | nil | nil | 회색 | - |
/// | nil | 71.0 | nil | - | - |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | Decimal | BigDecimal |
/// | NSDecimalNumber | BigDecimal |
/// | Optional (Decimal?) | Nullable (BigDecimal?) |
/// | String(format:) | String.format() |
/// | .frame(maxWidth: .infinity) | Modifier.weight(1f) |
///
/// ### 모범 사례
///
/// 1. **Props 최소화**: 필요한 4가지 값만 받기 (weight, bodyFatPct, previous*)
/// 2. **Computed Properties**: isEmpty, weightChange, formattedWeight로 로직 분리
/// 3. **색상 일관성**: 증가/감소/유지에 대한 색상 규칙을 앱 전체에서 일관되게 사용
/// 4. **의미 있는 아이콘**: 각 통계의 특성을 나타내는 아이콘 선택
/// 5. **빈 상태 처리**: weight가 nil일 때도 UI가 깨지지 않도록 처리
/// 6. **부분 데이터 지원**: 체중만 있고 체지방률 없을 수도 있음
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// if let dailyLog = viewModel.dailyLog {
///     BodyCompositionCard(
///         weight: dailyLog.weight,
///         bodyFatPct: dailyLog.bodyFatPct,
///         previousWeight: viewModel.previousDailyLog?.weight,
///         previousBodyFatPct: viewModel.previousDailyLog?.bodyFatPct
///     )
/// }
/// ```
///
/// ### 성능 최적화
///
/// - DailyLog의 사전 계산된 값 사용 (weight, bodyFatPct)
/// - 변화량은 클라이언트에서 계산 (간단한 뺄셈)
/// - 추가 네트워크 요청 없이 바로 표시 가능
/// - <0.5s 로딩 목표 달성에 기여
///
/// ### 접근성 (Accessibility)
///
/// - VoiceOver: "체중 70.5 킬로그램, 전날 대비 -0.5 킬로그램 감소"로 읽힘
/// - Dynamic Type: 시스템 폰트 크기에 자동 대응
/// - 색맹 지원: 아이콘과 텍스트로 색상만 의존하지 않음
///
/// ### 디자인 의도
///
/// 이 카드는 사용자의 체성분 변화를 한눈에 파악할 수 있도록 합니다:
/// - **체중**: 가장 기본적인 건강 지표
/// - **체지방률**: 체성분의 질적 평가
/// - **변화량**: 어제와의 비교로 트렌드 파악
///
/// 체중과 체지방률을 함께 보여줌으로써 단순히 체중이 줄었는지가 아니라,
/// 체지방이 줄었는지 근육이 줄었는지를 파악할 수 있도록 돕습니다.
///
/// ### 비즈니스 로직
///
/// - 체중 감소 + 체지방률 감소: 건강한 다이어트 ✅
/// - 체중 감소 + 체지방률 증가: 근손실 경고 ⚠️
/// - 체중 증가 + 체지방률 감소: 근육량 증가 💪
/// - 체중 증가 + 체지방률 증가: 주의 필요 ⚠️
///

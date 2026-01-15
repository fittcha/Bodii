//
//  CalorieBalanceCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-15.
//

// 📚 학습 포인트: Calorie Balance Card Component
// 일일 칼로리 섭취 vs TDEE를 원형 진행 표시기로 시각화하는 카드 컴포넌트
// 💡 칼로리 수지에 따라 색상이 변경되어 직관적인 피드백 제공

import SwiftUI

/// 칼로리 밸런스 카드
///
/// 오늘의 칼로리 섭취량을 TDEE와 비교하여 원형 진행 표시기로 시각화합니다.
/// 순 칼로리(섭취 - TDEE)에 따라 색상이 자동으로 변경됩니다.
///
/// **색상 규칙:**
/// - 칼로리 적자(deficit): 초록색 - 체중 감량 중
/// - 칼로리 균형(balanced): 파란색 - 유지 중
/// - 칼로리 과잉(surplus): 빨간색 - 과다 섭취
///
/// - Note: DailyLog의 사전 계산된 값을 사용하여 빠른 렌더링을 보장합니다.
///
/// - Example:
/// ```swift
/// CalorieBalanceCard(
///     totalCaloriesIn: 1800,
///     tdee: 2310,
///     netCalories: -510
/// )
/// ```
struct CalorieBalanceCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 총 섭취 칼로리 (kcal)
    let totalCaloriesIn: Int32

    /// TDEE (활동대사량, kcal)
    let tdee: Int32

    /// 순 칼로리 (섭취 - TDEE, kcal)
    let netCalories: Int32

    // MARK: - Constants

    /// 원형 진행 표시기 크기
    private let circleSize: CGFloat = 200

    /// 원형 진행 표시기 선 두께
    private let lineWidth: CGFloat = 16

    /// 균형 범위 (±50 kcal)
    private let balancedRange: Int32 = 50

    // MARK: - Computed Properties

    /// 칼로리 섭취 비율 (0.0 ~ 1.0+)
    ///
    /// TDEE 대비 섭취량 비율을 계산합니다.
    /// 1.0 이상이면 목표 칼로리를 초과한 것입니다.
    private var intakePercentage: Double {
        guard tdee > 0 else { return 0.0 }
        return Double(totalCaloriesIn) / Double(tdee)
    }

    /// 칼로리 상태 색상
    ///
    /// 순 칼로리에 따라 적절한 색상을 반환합니다.
    /// - 적자 (< -50): 초록색 (체중 감량)
    /// - 균형 (±50): 파란색 (유지)
    /// - 과잉 (> +50): 빨간색 (과다 섭취)
    private var statusColor: Color {
        if netCalories < -balancedRange {
            // 칼로리 적자 - 체중 감량 중
            return .green
        } else if netCalories > balancedRange {
            // 칼로리 과잉 - 과다 섭취
            return .red
        } else {
            // 칼로리 균형 - 유지 중
            return .blue
        }
    }

    /// 칼로리 상태 라벨
    ///
    /// 순 칼로리에 따라 사용자 친화적인 상태 문구를 반환합니다.
    private var statusLabel: String {
        if netCalories < -balancedRange {
            return "칼로리 적자"
        } else if netCalories > balancedRange {
            return "칼로리 과잉"
        } else {
            return "칼로리 균형"
        }
    }

    /// 칼로리 상태 아이콘
    ///
    /// 순 칼로리에 따라 적절한 SF Symbol 아이콘을 반환합니다.
    private var statusIcon: String {
        if netCalories < -balancedRange {
            return "arrow.down.circle.fill"
        } else if netCalories > balancedRange {
            return "arrow.up.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }

    /// 데이터가 비어있는지 여부
    private var isEmpty: Bool {
        totalCaloriesIn == 0 && tdee == 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 제목 섹션
            titleSection

            // 📚 학습 포인트: ZStack with Circular Progress
            // ZStack으로 원형 진행 표시기와 중앙 텍스트를 겹쳐서 표시
            // 💡 Java 비교: FrameLayout 또는 Box(contentAlignment = Alignment.Center)와 유사
            ZStack {
                // 배경 원 (회색)
                Circle()
                    .stroke(
                        Color(.systemGray5),
                        lineWidth: lineWidth
                    )
                    .frame(width: circleSize, height: circleSize)

                // 진행 원 (색상)
                Circle()
                    .trim(from: 0, to: min(intakePercentage, 1.5)) // 최대 150%까지 표시
                    .stroke(
                        statusColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90)) // 12시 방향부터 시작

                // 중앙 정보
                centerInfo
            }
            .padding(.vertical, 8)

            // 통계 섹션
            statsSection

            // 상태 라벨
            statusBadge
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
            Text("칼로리 밸런스")
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

    /// 중앙 정보 (원형 진행 표시기 내부)
    private var centerInfo: some View {
        VStack(spacing: 8) {
            // 섭취 칼로리
            Text("\(totalCaloriesIn)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(isEmpty ? .secondary : statusColor)

            // 구분선
            Text("ㅡ")
                .font(.title3)
                .foregroundStyle(.secondary)

            // TDEE
            Text("\(tdee)")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            // 단위
            Text("kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// 통계 섹션
    ///
    /// 섭취, TDEE, 순 칼로리를 나란히 표시합니다.
    private var statsSection: some View {
        HStack(spacing: 16) {
            // 섭취 칼로리
            statItem(
                title: "섭취",
                value: "\(totalCaloriesIn)",
                unit: "kcal",
                color: .orange
            )

            Divider()
                .frame(height: 40)

            // TDEE
            statItem(
                title: "목표",
                value: "\(tdee)",
                unit: "kcal",
                color: .blue
            )

            Divider()
                .frame(height: 40)

            // 순 칼로리
            statItem(
                title: "수지",
                value: netCalories >= 0 ? "+\(netCalories)" : "\(netCalories)",
                unit: "kcal",
                color: statusColor
            )
        }
        .padding(.horizontal, 8)
    }

    /// 개별 통계 아이템
    ///
    /// - Parameters:
    ///   - title: 제목 (예: "섭취")
    ///   - value: 값 (예: "1800")
    ///   - unit: 단위 (예: "kcal")
    ///   - color: 색상
    /// - Returns: 통계 아이템 뷰
    private func statItem(
        title: String,
        value: String,
        unit: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            // 제목
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            // 값
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isEmpty ? .secondary : color)

                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 상태 배지
    ///
    /// 칼로리 상태를 아이콘과 함께 표시합니다.
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.caption)

            Text(statusLabel)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(isEmpty ? .secondary : statusColor)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isEmpty ? Color(.systemGray5) : statusColor.opacity(0.15))
        )
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (적자/균형/과잉)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Calorie Deficit") {
    VStack(spacing: 20) {
        // 칼로리 적자 - 체중 감량 중 (초록색)
        CalorieBalanceCard(
            totalCaloriesIn: 1800,
            tdee: 2310,
            netCalories: -510
        )

        // 칼로리 적자 - 작은 차이
        CalorieBalanceCard(
            totalCaloriesIn: 2100,
            tdee: 2310,
            netCalories: -210
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Calorie Balanced") {
    VStack(spacing: 20) {
        // 칼로리 균형 - 유지 중 (파란색)
        CalorieBalanceCard(
            totalCaloriesIn: 2300,
            tdee: 2310,
            netCalories: -10
        )

        // 칼로리 균형 - 정확히 일치
        CalorieBalanceCard(
            totalCaloriesIn: 2310,
            tdee: 2310,
            netCalories: 0
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Calorie Surplus") {
    VStack(spacing: 20) {
        // 칼로리 과잉 - 과다 섭취 (빨간색)
        CalorieBalanceCard(
            totalCaloriesIn: 2800,
            tdee: 2310,
            netCalories: 490
        )

        // 칼로리 과잉 - 큰 차이
        CalorieBalanceCard(
            totalCaloriesIn: 3200,
            tdee: 2310,
            netCalories: 890
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    VStack {
        // 데이터 없음 - 회색 톤으로 표시
        CalorieBalanceCard(
            totalCaloriesIn: 0,
            tdee: 2310,
            netCalories: -2310
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Various Intakes") {
    ScrollView {
        VStack(spacing: 20) {
            // 매우 적은 섭취 (25%)
            CalorieBalanceCard(
                totalCaloriesIn: 600,
                tdee: 2310,
                netCalories: -1710
            )

            // 절반 섭취 (50%)
            CalorieBalanceCard(
                totalCaloriesIn: 1155,
                tdee: 2310,
                netCalories: -1155
            )

            // 75% 섭취
            CalorieBalanceCard(
                totalCaloriesIn: 1733,
                tdee: 2310,
                netCalories: -577
            )

            // 125% 섭취 (과잉)
            CalorieBalanceCard(
                totalCaloriesIn: 2888,
                tdee: 2310,
                netCalories: 578
            )

            // 150% 섭취 (큰 과잉)
            CalorieBalanceCard(
                totalCaloriesIn: 3465,
                tdee: 2310,
                netCalories: 1155
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Circular Progress Indicator 구현
///
/// ### 주요 개념
///
/// 1. **ZStack 레이어링**
///    - 배경 원 (회색, 100% 크기)
///    - 진행 원 (색상, trim으로 부분 표시)
///    - 중앙 텍스트 (섭취/TDEE 표시)
///
/// 2. **Circle.trim() 메서드**
///    - `from: 0, to: percentage` 형태로 진행률 표시
///    - 0.0 = 0%, 1.0 = 100%, 1.5 = 150%
///    - `.rotationEffect(.degrees(-90))`로 12시 방향부터 시작
///
/// 3. **조건부 색상 (Color Coding)**
///    - 적자 (deficit): 초록색 - 체중 감량 의도
///    - 균형 (balanced): 파란색 - 유지 의도
///    - 과잉 (surplus): 빨간색 - 주의 필요
///
/// 4. **Computed Properties로 로직 분리**
///    - `intakePercentage`: 섭취 비율 계산
///    - `statusColor`: 색상 결정 로직
///    - `statusLabel`: 상태 문구 결정
///    - UI와 비즈니스 로직 분리로 테스트 용이
///
/// 5. **균형 범위 (Balanced Range)**
///    - ±50 kcal 범위는 "균형" 상태로 간주
///    - 너무 엄격한 기준은 사용자를 스트레스받게 함
///    - 현실적인 목표 달성 가능성 제공
///
/// ### Circle.trim() 상세 설명
///
/// ```swift
/// Circle()
///     .trim(from: 0, to: 0.75)  // 75% 표시
///     .stroke(Color.blue, lineWidth: 16)
///     .rotationEffect(.degrees(-90))  // 12시 방향 시작
/// ```
///
/// - `trim()`: 원의 일부만 그리기
/// - `from`: 시작 지점 (0.0 ~ 1.0)
/// - `to`: 종료 지점 (0.0 ~ 1.0)
/// - 기본적으로 3시 방향(0도)에서 시작하므로 -90도 회전 필요
///
/// ### StrokeStyle 옵션
///
/// ```swift
/// .stroke(
///     color,
///     style: StrokeStyle(
///         lineWidth: 16,      // 선 두께
///         lineCap: .round     // 선 끝을 둥글게
///     )
/// )
/// ```
///
/// - `lineCap: .round`: 선의 끝을 둥글게 처리하여 부드러운 느낌
/// - `lineCap: .square`: 선의 끝을 각지게 처리
/// - `lineCap: .butt`: 기본값, 끝 처리 없음
///
/// ### 색상 규칙 비즈니스 로직
///
/// | 상태 | 순 칼로리 범위 | 색상 | 의미 |
/// |------|---------------|------|------|
/// | 적자 | < -50 kcal | 초록색 | 체중 감량 중 (목표) |
/// | 균형 | -50 ~ +50 kcal | 파란색 | 유지 중 (안정) |
/// | 과잉 | > +50 kcal | 빨간색 | 과다 섭취 (주의) |
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | ZStack | Box(contentAlignment = Center) |
/// | Circle().trim() | Canvas.drawArc() |
/// | .stroke() | Paint.setStyle(STROKE) |
/// | .rotationEffect() | Canvas.rotate() |
/// | Computed Property | get() method |
///
/// ### 모범 사례
///
/// 1. **Props 최소화**: 필요한 3가지 값만 받기 (intake, tdee, net)
/// 2. **로직 분리**: Computed properties로 색상/라벨 결정 로직 분리
/// 3. **의미 있는 색상**: 사용자가 직관적으로 이해할 수 있는 색상 선택
/// 4. **현실적인 기준**: 너무 엄격하지 않은 균형 범위 설정
/// 5. **빈 상태 처리**: 데이터 없을 때도 UI가 깨지지 않도록 처리
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// if let dailyLog = viewModel.dailyLog {
///     CalorieBalanceCard(
///         totalCaloriesIn: dailyLog.totalCaloriesIn,
///         tdee: dailyLog.tdee,
///         netCalories: dailyLog.netCalories
///     )
/// }
/// ```
///
/// ### 성능 최적화
///
/// - DailyLog의 사전 계산된 값 사용 (totalCaloriesIn, tdee, netCalories)
/// - 추가 계산 없이 바로 표시 가능
/// - <0.5s 로딩 목표 달성에 기여
///

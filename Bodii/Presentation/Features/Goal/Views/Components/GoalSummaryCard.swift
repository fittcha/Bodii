//
//  GoalSummaryCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Goal Summary Card Component
// 목표의 시작/현재/목표 값을 프로그레스 바와 함께 표시하는 재사용 가능한 카드 컴포넌트
// 💡 Java 비교: Android의 Material Card with Progress Indicator와 유사

import SwiftUI

// MARK: - Goal Summary Card

/// 목표 요약 카드 컴포넌트
///
/// 목표의 시작값, 현재값, 목표값을 프로그레스 바와 함께 시각적으로 표시합니다.
///
/// **주요 기능:**
/// - 목표 제목과 아이콘 표시
/// - 진행률 배지 표시
/// - 프로그레스 바 (색상 커스터마이징 가능)
/// - 시작/현재/목표 값 표시
/// - 남은 값 표시 (깃발 아이콘)
///
/// **애니메이션:**
/// - 진행률 변경 시 프로그레스 바 애니메이션
/// - easeInOut 애니메이션
///
/// - Example:
/// ```swift
/// GoalSummaryCard(
///     title: "체중 목표",
///     icon: "scalemass",
///     progress: 60.0,
///     start: 70.0,
///     current: 67.0,
///     target: 65.0,
///     unit: "kg",
///     color: .blue
/// )
/// ```
struct GoalSummaryCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Card Metadata
    // 카드의 제목, 아이콘, 색상 등 메타데이터

    /// 카드 제목 (예: "체중 목표")
    let title: String

    /// SF Symbol 아이콘 이름
    let icon: String

    /// 진행률 (0.0 ~ 150.0)
    /// 📚 학습 포인트: Progress Percentage
    /// ProgressResult의 percentage를 그대로 전달
    let progress: Decimal

    // 📚 학습 포인트: Goal Values
    // 시작, 현재, 목표 값

    /// 시작 값 (목표 설정 시점의 값)
    let start: Decimal

    /// 현재 값 (최신 측정 값)
    let current: Decimal

    /// 목표 값 (달성하려는 값)
    let target: Decimal

    // 📚 학습 포인트: Display Configuration
    // 표시 형식 설정

    /// 단위 (예: "kg", "%")
    let unit: String

    /// 테마 색상 (예: .blue, .orange, .green)
    let color: Color

    /// 남은 값 (옵션, 계산되지 않은 경우 자동 계산)
    /// 📚 학습 포인트: Optional Remaining Value
    /// ProgressResult.remaining을 전달하거나, nil이면 자동 계산
    var remaining: Decimal?

    // MARK: - Computed Properties

    /// 남은 값 (계산)
    ///
    /// remaining이 제공되지 않으면 자동으로 계산합니다.
    private var calculatedRemaining: Decimal {
        remaining ?? abs(target - current)
    }

    /// 프로그레스 바 너비 비율 (0.0 ~ 1.0)
    ///
    /// 100%를 초과하는 경우에도 1.0으로 제한됩니다.
    private var progressRatio: Double {
        min(Double(truncating: progress as NSNumber) / 100.0, 1.0)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // 헤더 (제목, 아이콘, 진행률 배지)
            header

            // 프로그레스 바
            progressBar

            // 시작, 현재, 목표 값 표시
            valuesDisplay

            // 남은 값 표시
            remainingDisplay
        }
        .padding()
        .background(cardBackground)
    }

    // MARK: - View Components

    /// 헤더
    ///
    /// 제목, 아이콘, 진행률 배지를 표시합니다.
    @ViewBuilder
    private var header: some View {
        HStack {
            // 아이콘
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            // 제목
            Text(title)
                .font(.headline)

            Spacer()

            // 진행률 배지
            progressBadge
        }
    }

    /// 진행률 배지
    @ViewBuilder
    private var progressBadge: some View {
        Text(formatProgress(progress))
            .font(.headline)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
            )
    }

    /// 프로그레스 바
    ///
    /// GeometryReader를 사용하여 진행률에 따라 너비를 조정합니다.
    @ViewBuilder
    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 바
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    // 진행률 바
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * CGFloat(progressRatio),
                            height: 12
                        )
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 12)
        }
    }

    /// 시작, 현재, 목표 값 표시
    ///
    /// 3개의 컬럼으로 구성된 값 표시 섹션입니다.
    @ViewBuilder
    private var valuesDisplay: some View {
        HStack(spacing: 0) {
            // 시작
            valueColumn(
                label: "시작",
                value: start,
                font: .subheadline,
                fontWeight: .medium,
                color: .primary
            )
            .frame(maxWidth: .infinity)

            // 현재 (강조)
            valueColumn(
                label: "현재",
                value: current,
                font: .title3,
                fontWeight: .bold,
                color: color
            )
            .frame(maxWidth: .infinity)

            // 목표
            valueColumn(
                label: "목표",
                value: target,
                font: .subheadline,
                fontWeight: .medium,
                color: .primary
            )
            .frame(maxWidth: .infinity)
        }
    }

    /// 개별 값 컬럼
    ///
    /// - Parameters:
    ///   - label: 레이블 (예: "시작", "현재", "목표")
    ///   - value: 값
    ///   - font: 폰트 크기
    ///   - fontWeight: 폰트 굵기
    ///   - color: 텍스트 색상
    @ViewBuilder
    private func valueColumn(
        label: String,
        value: Decimal,
        font: Font,
        fontWeight: Font.Weight,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formatValue(value))
                .font(font)
                .fontWeight(fontWeight)
                .foregroundStyle(color)
        }
    }

    /// 남은 값 표시
    ///
    /// 깃발 아이콘과 함께 목표까지 남은 값을 표시합니다.
    @ViewBuilder
    private var remainingDisplay: some View {
        HStack {
            Image(systemName: "flag.checkered")
                .foregroundStyle(.secondary)

            Text("남은 \(cleanTitle): ")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(formatValue(calculatedRemaining))
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()
        }
    }

    /// 카드 배경
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    /// 제목에서 " 목표" 제거
    ///
    /// "체중 목표" → "체중"
    private var cleanTitle: String {
        title.replacingOccurrences(of: " 목표", with: "")
    }

    /// 진행률 포맷팅
    ///
    /// - Parameter value: 진행률 (0.0 ~ 150.0)
    /// - Returns: 포맷된 문자열 (예: "60%")
    private func formatProgress(_ value: Decimal) -> String {
        let rounded = NSDecimalNumber(decimal: value).rounding(
            accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 0,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            )
        )
        return "\(rounded)%"
    }

    /// 값 포맷팅
    ///
    /// - Parameter value: 값 (Decimal)
    /// - Returns: 포맷된 문자열 (예: "70.0 kg", "18.5%")
    private func formatValue(_ value: Decimal) -> String {
        let rounded = NSDecimalNumber(decimal: value).rounding(
            accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 1,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            )
        )
        return "\(rounded) \(unit)"
    }
}

// MARK: - Preview

#Preview("체중 목표 - 중간 진행") {
    VStack(spacing: 20) {
        GoalSummaryCard(
            title: "체중 목표",
            icon: "scalemass",
            progress: 60.0,
            start: 70.0,
            current: 67.0,
            target: 65.0,
            unit: "kg",
            color: .blue
        )

        Text("60% 진행 - 시작 70kg → 현재 67kg → 목표 65kg")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("체지방률 목표 - 초반") {
    VStack(spacing: 20) {
        GoalSummaryCard(
            title: "체지방률 목표",
            icon: "percent",
            progress: 25.0,
            start: 25.0,
            current: 23.5,
            target: 19.0,
            unit: "%",
            color: .orange
        )

        Text("25% 진행 - 시작 25% → 현재 23.5% → 목표 19%")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("근육량 목표 - 거의 완료") {
    VStack(spacing: 20) {
        GoalSummaryCard(
            title: "근육량 목표",
            icon: "figure.strengthtraining.traditional",
            progress: 85.0,
            start: 30.0,
            current: 34.25,
            target: 35.0,
            unit: "kg",
            color: .green,
            remaining: 0.75
        )

        Text("85% 진행 - 시작 30kg → 현재 34.25kg → 목표 35kg")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("목표 달성") {
    VStack(spacing: 20) {
        GoalSummaryCard(
            title: "체중 목표",
            icon: "scalemass",
            progress: 100.0,
            start: 70.0,
            current: 65.0,
            target: 65.0,
            unit: "kg",
            color: .green,
            remaining: 0.0
        )

        Text("100% 진행 - 목표 달성!")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("초과 달성") {
    VStack(spacing: 20) {
        GoalSummaryCard(
            title: "체중 목표",
            icon: "scalemass",
            progress: 120.0,
            start: 70.0,
            current: 64.0,
            target: 65.0,
            unit: "kg",
            color: .green,
            remaining: 0.0
        )

        Text("120% 진행 - 초과 달성 (목표보다 1kg 더 감량)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("다크 모드") {
    VStack(spacing: 20) {
        GoalSummaryCard(
            title: "체중 목표",
            icon: "scalemass",
            progress: 60.0,
            start: 70.0,
            current: 67.0,
            target: 65.0,
            unit: "kg",
            color: .blue
        )

        Text("다크 모드에서의 목표 요약 카드")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("모든 목표 유형") {
    ScrollView {
        VStack(spacing: 20) {
            // 체중
            GoalSummaryCard(
                title: "체중 목표",
                icon: "scalemass",
                progress: 60.0,
                start: 70.0,
                current: 67.0,
                target: 65.0,
                unit: "kg",
                color: .blue
            )

            // 체지방률
            GoalSummaryCard(
                title: "체지방률 목표",
                icon: "percent",
                progress: 50.0,
                start: 25.0,
                current: 22.0,
                target: 19.0,
                unit: "%",
                color: .orange
            )

            // 근육량
            GoalSummaryCard(
                title: "근육량 목표",
                icon: "figure.strengthtraining.traditional",
                progress: 40.0,
                start: 30.0,
                current: 32.0,
                target: 35.0,
                unit: "kg",
                color: .green
            )

            Text("3가지 목표 유형 모두 표시")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

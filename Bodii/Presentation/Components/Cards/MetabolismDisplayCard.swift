//
//  MetabolismDisplayCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Reusable Dashboard Card Component
// SwiftUI의 재사용 가능한 대시보드 카드 컴포넌트
// 💡 Java 비교: Android의 Custom View/Compose Component와 유사

import SwiftUI

// MARK: - MetabolismDisplayCard

/// BMR/TDEE 및 칼로리 균형을 표시하는 대시보드 카드 컴포넌트
/// 📚 학습 포인트: Dashboard Display Component
/// - 읽기 전용 정보 표시 (입력 없음)
/// - BMR/TDEE 값과 칼로리 균형 상태를 시각적으로 표현
/// - 컴팩트한 디자인으로 대시보드에 적합
/// 💡 Java 비교: React Component, Android Compose Component와 유사
struct MetabolismDisplayCard: View {

    // MARK: - Properties

    /// 기초대사량 (BMR) (kcal/day)
    /// 📚 학습 포인트: Optional Value
    /// - nil이면 데이터 없음 상태 표시
    let bmr: Decimal?

    /// 총 일일 에너지 소비량 (TDEE) (kcal/day)
    let tdee: Decimal?

    /// 활동 수준
    let activityLevel: ActivityLevel?

    /// 칼로리 균형 (섭취 - 소비)
    /// 📚 학습 포인트: Calorie Balance
    /// - 양수: 잉여 (체중 증가 경향)
    /// - 음수: 결핍 (체중 감소 경향)
    /// - 0 근처: 유지 상태
    let calorieBalance: Decimal?

    /// 칼로리 균형 상태 텍스트 ("잉여", "결핍", "유지")
    let balanceStatusText: String

    /// 칼로리 균형 상태 색상
    let balanceStatusColor: Color

    /// 칼로리 균형 상태 아이콘
    let balanceStatusIcon: String

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 데이터 로드 중 로딩 인디케이터 표시
    let isLoading: Bool

    /// 탭 액션 콜백
    /// 📚 학습 포인트: Callback Pattern
    /// - 카드 탭 시 신체 탭으로 이동 등의 액션
    /// 💡 Java 비교: OnClickListener와 유사
    let onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // 카드 헤더
                cardHeader

                if isLoading {
                    // 로딩 상태
                    loadingView
                } else if let bmr = bmr, let tdee = tdee {
                    // 데이터가 있는 경우
                    VStack(alignment: .leading, spacing: 12) {
                        // BMR/TDEE 섹션
                        metabolismValuesSection(bmr: bmr, tdee: tdee)

                        Divider()

                        // 활동 수준 섹션
                        if let activityLevel = activityLevel {
                            activityLevelSection(activityLevel: activityLevel)
                        }

                        // 칼로리 균형 섹션 (있는 경우)
                        if calorieBalance != nil {
                            Divider()
                            calorieBalanceSection
                        }
                    }
                } else {
                    // 데이터가 없는 경우
                    emptyStateView
                }
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Subviews

    /// 카드 헤더
    private var cardHeader: some View {
        HStack {
            // 📚 학습 포인트: SF Symbols
            // Apple이 제공하는 시스템 아이콘
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            Text("대사율")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            // 화살표 아이콘 (탭 가능 표시)
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// BMR/TDEE 값 섹션
    /// 📚 학습 포인트: Extracted View Function
    /// - 반복되는 UI 패턴을 함수로 추출
    ///
    /// - Parameters:
    ///   - bmr: 기초대사량
    ///   - tdee: 총 일일 에너지 소비량
    /// - Returns: BMR/TDEE 표시 뷰
    private func metabolismValuesSection(bmr: Decimal, tdee: Decimal) -> some View {
        HStack(spacing: 20) {
            // BMR
            metabolismValueItem(
                title: "BMR",
                value: formatCalories(bmr),
                icon: "bed.double.fill",
                color: .blue
            )

            Divider()
                .frame(height: 50)

            // TDEE
            metabolismValueItem(
                title: "TDEE",
                value: formatCalories(tdee),
                icon: "figure.walk",
                color: .green
            )
        }
    }

    /// 개별 대사량 값 아이템
    /// 📚 학습 포인트: Reusable Component Function
    /// - 반복되는 UI 패턴을 재사용 가능한 함수로 추출
    ///
    /// - Parameters:
    ///   - title: 제목 (BMR, TDEE 등)
    ///   - value: 칼로리 값
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 색상
    /// - Returns: 값 표시 뷰
    private func metabolismValueItem(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 레이블
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // 값
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // 단위
            Text("kcal/일")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 활동 수준 섹션
    /// 📚 학습 포인트: Activity Level Display
    /// - 사용자의 활동 수준과 설명 표시
    ///
    /// - Parameter activityLevel: 활동 수준
    /// - Returns: 활동 수준 표시 뷰
    private func activityLevelSection(activityLevel: ActivityLevel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: activityLevelIcon(for: activityLevel))
                .font(.caption)
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("활동 수준")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(activityLevel.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // 활동 계수 표시
            Text("\(String(format: "%.2f", activityLevel.multiplier))x")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(6)
        }
    }

    /// 칼로리 균형 섹션
    /// 📚 학습 포인트: Visual Feedback
    /// - 칼로리 균형 상태를 색상과 아이콘으로 시각화
    private var calorieBalanceSection: some View {
        HStack(spacing: 8) {
            // 상태 아이콘
            Image(systemName: balanceStatusIcon)
                .font(.title3)
                .foregroundStyle(balanceStatusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("칼로리 균형")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(balanceStatusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(balanceStatusColor)

                    if let balance = calorieBalance {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(formatCalorieBalance(balance))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }

            Spacer()
        }
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("대사율 데이터 로드 중...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)

                Text("신체 기록이 없습니다")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("신체 구성 데이터를 입력하면\nBMR과 TDEE가 자동으로 계산됩니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    /// 카드 배경
    /// 📚 학습 포인트: Adaptive Colors
    /// - 라이트/다크 모드에 자동 대응하는 색상
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
    }

    // MARK: - Helper Methods

    /// 칼로리 값 포맷팅
    /// 📚 학습 포인트: Number Formatting
    /// - Decimal을 읽기 쉬운 문자열로 변환
    ///
    /// - Parameter calories: 칼로리 값
    /// - Returns: 포맷된 문자열 (예: "1,650")
    private func formatCalories(_ calories: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let number = NSDecimalNumber(decimal: calories)
        return formatter.string(from: number) ?? "\(calories)"
    }

    /// 칼로리 균형 포맷팅
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter balance: 칼로리 균형
    /// - Returns: 포맷된 문자열 (예: "+300 kcal", "-150 kcal")
    private func formatCalorieBalance(_ balance: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: balance)
        return (formatter.string(from: number) ?? "\(balance)") + " kcal"
    }

    /// 활동 수준에 따른 아이콘 반환
    /// 📚 학습 포인트: Icon Mapping
    /// - 활동 수준에 맞는 SF Symbol 선택
    ///
    /// - Parameter activityLevel: 활동 수준
    /// - Returns: SF Symbol 이름
    private func activityLevelIcon(for activityLevel: ActivityLevel) -> String {
        switch activityLevel {
        case .sedentary:
            return "figure.seated.side"
        case .lightlyActive:
            return "figure.walk"
        case .moderatelyActive:
            return "figure.run"
        case .veryActive:
            return "figure.strengthtraining.traditional"
        case .extraActive:
            return "figure.climbing"
        }
    }
}

// MARK: - Convenience Initializers

extension MetabolismDisplayCard {
    /// 📚 학습 포인트: Convenience Initializer with ViewModel
    /// - MetabolismViewModel에서 직접 값을 가져오는 편의 생성자
    /// - View에서 쉽게 사용 가능
    ///
    /// - Parameters:
    ///   - viewModel: MetabolismViewModel 인스턴스
    ///   - onTap: 탭 액션 콜백
    init(viewModel: MetabolismViewModel, onTap: (() -> Void)? = nil) {
        self.bmr = viewModel.bmr
        self.tdee = viewModel.tdee
        self.activityLevel = viewModel.activityLevel
        self.calorieBalance = viewModel.calorieBalance
        self.balanceStatusText = viewModel.calorieBalanceStatusText()
        self.balanceStatusColor = viewModel.calorieBalanceStatusColor()
        self.balanceStatusIcon = viewModel.calorieBalanceStatusIcon()
        self.isLoading = viewModel.isLoading
        self.onTap = onTap
    }

    /// 📚 학습 포인트: Convenience Initializer for Manual Values
    /// - 개별 값을 직접 전달하는 생성자
    /// - Preview나 테스트에서 유용
    ///
    /// - Parameters:
    ///   - bmr: 기초대사량
    ///   - tdee: 총 일일 에너지 소비량
    ///   - activityLevel: 활동 수준
    ///   - calorieBalance: 칼로리 균형
    ///   - balanceStatus: 균형 상태 ("잉여", "결핍", "유지")
    ///   - balanceColor: 균형 상태 색상
    ///   - balanceIcon: 균형 상태 아이콘
    ///   - onTap: 탭 액션 콜백
    init(
        bmr: Decimal?,
        tdee: Decimal?,
        activityLevel: ActivityLevel?,
        calorieBalance: Decimal? = nil,
        balanceStatus: String = "데이터 없음",
        balanceColor: Color = .gray,
        balanceIcon: String = "questionmark.circle",
        isLoading: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.bmr = bmr
        self.tdee = tdee
        self.activityLevel = activityLevel
        self.calorieBalance = calorieBalance
        self.balanceStatusText = balanceStatus
        self.balanceStatusColor = balanceColor
        self.balanceStatusIcon = balanceIcon
        self.isLoading = isLoading
        self.onTap = onTap
    }
}

// MARK: - Preview

#Preview("데이터 있음 - 유지 상태") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: Decimal(1650),
            tdee: Decimal(2280),
            activityLevel: .moderatelyActive,
            calorieBalance: Decimal(50),
            balanceStatus: "유지",
            balanceColor: .green,
            balanceIcon: "equal.circle.fill",
            onTap: {
                print("Card tapped")
            }
        )
        .padding()
    }
}

#Preview("데이터 있음 - 잉여 상태") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: Decimal(1650),
            tdee: Decimal(2280),
            activityLevel: .moderatelyActive,
            calorieBalance: Decimal(300),
            balanceStatus: "잉여",
            balanceColor: .orange,
            balanceIcon: "arrow.up.circle.fill"
        )
        .padding()
    }
}

#Preview("데이터 있음 - 결핍 상태") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: Decimal(1680),
            tdee: Decimal(2016),
            activityLevel: .sedentary,
            calorieBalance: Decimal(-400),
            balanceStatus: "결핍",
            balanceColor: .blue,
            balanceIcon: "arrow.down.circle.fill"
        )
        .padding()
    }
}

#Preview("칼로리 균형 없음") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: Decimal(1650),
            tdee: Decimal(2280),
            activityLevel: .lightlyActive
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: nil,
            tdee: nil,
            activityLevel: nil
        )
        .padding()
    }
}

#Preview("로딩 상태") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: nil,
            tdee: nil,
            activityLevel: nil,
            isLoading: true
        )
        .padding()
    }
}

#Preview("다크 모드 - 데이터 있음") {
    ScrollView {
        MetabolismDisplayCard(
            bmr: Decimal(1650),
            tdee: Decimal(2280),
            activityLevel: .veryActive,
            calorieBalance: Decimal(-250),
            balanceStatus: "결핍",
            balanceColor: .blue,
            balanceIcon: "arrow.down.circle.fill"
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("다양한 활동 수준") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach([ActivityLevel.sedentary, .lightlyActive, .moderatelyActive, .veryActive, .extraActive]) { level in
                MetabolismDisplayCard(
                    bmr: Decimal(1650),
                    tdee: Decimal(1650) * Decimal(level.multiplier),
                    activityLevel: level
                )
            }
        }
        .padding()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: MetabolismDisplayCard 사용법
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct DashboardView: View {
///     @StateObject private var metabolismViewModel: MetabolismViewModel
///
///     var body: some View {
///         MetabolismDisplayCard(
///             viewModel: metabolismViewModel,
///             onTap: {
///                 // 신체 탭으로 이동
///                 selectedTab = .body
///             }
///         )
///     }
/// }
/// ```
///
/// 개별 값으로 사용:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         MetabolismDisplayCard(
///             bmr: Decimal(1650),
///             tdee: Decimal(2280),
///             activityLevel: .moderatelyActive,
///             calorieBalance: Decimal(300),
///             balanceStatus: "잉여",
///             balanceColor: .orange,
///             balanceIcon: "arrow.up.circle.fill"
///         )
///     }
/// }
/// ```
///
/// 빈 상태 표시:
/// ```swift
/// MetabolismDisplayCard(
///     bmr: nil,
///     tdee: nil,
///     activityLevel: nil
/// )
/// ```
///
/// 주요 기능:
/// - BMR/TDEE 값을 명확하게 표시
/// - 활동 수준과 활동 계수 표시
/// - 칼로리 균형을 색상과 아이콘으로 시각화
/// - 빈 상태와 로딩 상태 지원
/// - 탭 가능하여 상세 페이지로 이동 가능
/// - 라이트/다크 모드 자동 대응
/// - 컴팩트한 디자인으로 대시보드에 적합
///
/// 💡 Android 비교:
/// - Android: CardView + Data Binding
/// - SwiftUI: Card component with @Binding
/// - Android: LiveData 관찰
/// - SwiftUI: @Published + ObservableObject
///

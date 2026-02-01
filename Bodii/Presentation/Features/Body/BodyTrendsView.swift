//
//  BodyTrendsView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Chart Display View Pattern
// 차트 중심의 트렌드 분석 화면
// 💡 Java 비교: Android의 Chart Fragment와 유사하지만 더 선언적

import SwiftUI
import Charts

// MARK: - BodyTrendsView

/// 신체 구성 트렌드 차트 화면
/// 📚 학습 포인트: Chart-Focused View
/// - 체중 및 체지방률 트렌드 차트 표시
/// - 기간 선택 기능 (7/30/90일)
/// - 통계 요약 정보 표시
/// - 빈 상태 처리
/// 💡 Java 비교: Android의 Analytics Fragment와 유사
struct BodyTrendsView: View {

    // MARK: - Properties

    /// ViewModel - 트렌드 데이터 관리
    /// 📚 학습 포인트: @StateObject
    /// - View의 생명주기와 연결된 ObservableObject
    /// - View가 사라져도 상태 유지
    /// 💡 Java 비교: Android ViewModel과 유사
    @StateObject private var viewModel: BodyTrendsViewModel

    /// 사용자 성별 (건강 구간 표시용)
    /// 📚 학습 포인트: Optional Gender for Health Zones
    /// - 체지방률 건강 구간 판별에 사용
    /// - nil이면 일반적인 색상 사용
    let userGender: Gender?

    /// 목표 체중
    /// 📚 학습 포인트: Optional Goal Line
    /// - 차트에 목표선 표시
    let goalWeight: Decimal?

    /// 목표 체지방률
    let goalBodyFat: Decimal?

    /// 화면 닫기 액션
    /// 📚 학습 포인트: Environment Dismiss
    /// - Sheet나 NavigationStack에서 화면을 닫을 때 사용
    /// 💡 Java 비교: finish() 또는 popBackStack()과 유사
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// BodyTrendsView 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel을 외부에서 주입받음
    /// - 테스트 시 Mock ViewModel 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameters:
    ///   - viewModel: 트렌드 ViewModel
    ///   - userGender: 사용자 성별 (기본값: nil)
    ///   - goalWeight: 목표 체중 (기본값: nil)
    ///   - goalBodyFat: 목표 체지방률 (기본값: nil)
    init(
        viewModel: BodyTrendsViewModel,
        userGender: Gender? = nil,
        goalWeight: Decimal? = nil,
        goalBodyFat: Decimal? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.userGender = userGender
        self.goalWeight = goalWeight
        self.goalBodyFat = goalBodyFat
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack
        // iOS 16+의 새로운 네비게이션 시스템
        // 💡 Java 비교: Navigation Component와 유사
        NavigationStack {
            // 📚 학습 포인트: ScrollView with LazyVStack
            // 성능 최적화를 위해 보이는 부분만 렌더링
            ScrollView {
                VStack(spacing: 20) {
                    // 기간 선택기
                    periodSelectorSection

                    // 차트 섹션
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        // 통계 요약
                        statisticsSection

                        // 체중 트렌드 차트
                        weightChartSection

                        // 체지방률 트렌드 차트
                        bodyFatChartSection

                        // 근육량 트렌드 차트
                        muscleMassChartSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("트렌드 분석")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            // 📚 학습 포인트: refreshable modifier
            // Pull-to-refresh 구현
            .refreshable {
                await viewModel.refresh()
            }
            // 📚 학습 포인트: Alert for Errors
            // 에러 발생 시 알림 표시
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 기간 선택기 섹션
    /// 📚 학습 포인트: Period Selector Section
    /// - TrendPeriodPicker를 카드 안에 배치
    private var periodSelectorSection: some View {
        VStack(spacing: 0) {
            TrendPeriodPicker(fullWidth: $viewModel.selectedPeriod)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 통계 요약 섹션
    /// 📚 학습 포인트: Statistics Summary
    /// - 평균, 최소, 최대, 변화량 표시
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "통계 요약",
                icon: "chart.bar.fill"
            )

            if let output = viewModel.trendsOutput {
                statisticsCard(output: output)
            }
        }
    }

    /// 통계 카드
    /// - 체중 변화와 체지방 변화만 표시 (핵심 트렌드 정보)
    private func statisticsCard(output: FetchBodyTrendsUseCase.Output) -> some View {
        VStack(spacing: 16) {
            // 데이터 기간
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("기간: \(formatDate(output.startDate, style: .short)) - \(formatDate(output.endDate, style: .short))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(output.count)개 기록")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }

            Divider()

            // 변화량만 표시 (평균값은 트렌드에서 실용성 낮음)
            HStack(spacing: 16) {
                // 체중 변화
                if let weightChange = output.weightChange {
                    statisticItem(
                        title: "체중 변화",
                        value: formatWeightChange(weightChange),
                        icon: weightChange >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: weightChange >= 0 ? .orange : .blue
                    )
                }

                // 체지방률 변화
                if let bodyFatChange = output.bodyFatPercentChange {
                    statisticItem(
                        title: "체지방 변화",
                        value: formatBodyFatChange(bodyFatChange),
                        icon: bodyFatChange >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: bodyFatChange >= 0 ? .orange : .blue
                    )
                }

                // 근육량 변화
                if let muscleMassChange = output.muscleMassChange {
                    statisticItem(
                        title: "근육량 변화",
                        value: formatMuscleMassChange(muscleMassChange),
                        icon: muscleMassChange >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: muscleMassChange >= 0 ? .green : .orange
                    )
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 개별 통계 아이템
    /// 📚 학습 포인트: Reusable Statistic Item
    /// - 통계 지표를 일관된 형식으로 표시
    ///
    /// - Parameters:
    ///   - title: 통계 제목
    ///   - value: 통계 값
    ///   - icon: SF Symbol 아이콘
    ///   - color: 강조 색상
    /// - Returns: 통계 아이템 뷰
    private func statisticItem(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 아이콘과 제목
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 값
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }

    /// 체중 차트 섹션
    /// 📚 학습 포인트: Chart Section
    /// - 차트를 카드 안에 배치
    private var weightChartSection: some View {
        VStack(spacing: 0) {
            WeightTrendChart(
                viewModel: viewModel,
                goalWeight: goalWeight,
                isInteractive: true,
                height: 280,
                gender: userGender
            )
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 체지방률 차트 섹션
    /// 📚 학습 포인트: Chart Section with Health Zones
    /// - 건강 구간과 함께 차트 표시
    private var bodyFatChartSection: some View {
        VStack(spacing: 0) {
            BodyFatTrendChart(
                viewModel: viewModel,
                goalBodyFat: goalBodyFat,
                isInteractive: true,
                height: 280,
                gender: userGender,
                showHealthZones: true
            )
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 근육량 차트 섹션
    private var muscleMassChartSection: some View {
        VStack(spacing: 0) {
            MuscleMassTrendChart(
                viewModel: viewModel,
                isInteractive: true,
                height: 280,
                gender: userGender
            )
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 닫기 버튼
    /// 📚 학습 포인트: Toolbar Item
    /// - 네비게이션 바에 닫기 버튼 추가
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                Text("닫기")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
        }
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("트렌드 데이터를 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 70))
                .foregroundStyle(.gray.opacity(0.3))

            VStack(spacing: 8) {
                Text("트렌드 데이터가 없습니다")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("선택한 기간 동안의 신체 구성 기록이 없습니다.\n체성분 탭에서 데이터를 입력하면\n트렌드를 확인할 수 있습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 다른 기간 선택 안내
            VStack(spacing: 12) {
                Text("다른 기간을 선택해보세요:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                TrendPeriodPicker(compactStyle: $viewModel.selectedPeriod)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .padding(.horizontal, 32)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 섹션 헤더
    /// 📚 학습 포인트: Section Header Component
    ///
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - icon: SF Symbol 아이콘
    /// - Returns: 섹션 헤더 뷰
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
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

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    ///
    /// - Parameters:
    ///   - date: 날짜
    ///   - style: 날짜 스타일 (기본값: .medium)
    /// - Returns: 포맷된 문자열
    private func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 체중 포맷팅
    /// 📚 학습 포인트: Weight Formatting
    /// - 소수점 1자리 + "kg" 단위
    ///
    /// - Parameter weight: 체중
    /// - Returns: 포맷된 문자열 (예: "70.5 kg")
    private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: weight)
        return (formatter.string(from: number) ?? "\(weight)") + " kg"
    }

    /// 체중 변화량 포맷팅
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+1.5 kg", "-0.8 kg")
    private func formatWeightChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + " kg"
    }

    /// 체지방률 포맷팅
    /// 📚 학습 포인트: Percentage Formatting
    /// - 소수점 1자리 + "%" 기호
    ///
    /// - Parameter bodyFat: 체지방률
    /// - Returns: 포맷된 문자열 (예: "18.5%")
    private func formatBodyFat(_ bodyFat: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: bodyFat)
        return (formatter.string(from: number) ?? "\(bodyFat)") + "%"
    }

    /// 근육량 변화량 포맷팅
    private func formatMuscleMassChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + " kg"
    }

    /// 체지방률 변화량 포맷팅
    /// 📚 학습 포인트: Percentage Change Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+1.5%", "-0.8%")
    private func formatBodyFatChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + "%"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("기본 상태") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    // BodyTrendsView(viewModel: .makePreview())
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("데이터 있음") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("빈 상태") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("다크 모드") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
        .preferredColorScheme(.dark)
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: BodyTrendsView 사용법
///
/// 기본 사용 (DIContainer에서 생성):
/// ```swift
/// struct ContentView: View {
///     let container: DIContainer
///
///     var body: some View {
///         BodyTrendsView(
///             viewModel: container.makeBodyTrendsViewModel(),
///             userGender: .male,
///             goalWeight: Decimal(70.0),
///             goalBodyFat: Decimal(15.0)
///         )
///     }
/// }
/// ```
///
/// Sheet로 표시 (권장):
/// ```swift
/// struct BodyCompositionView: View {
///     @State private var showTrendsView = false
///
///     var body: some View {
///         VStack {
///             Button("트렌드 보기") {
///                 showTrendsView = true
///             }
///         }
///         .sheet(isPresented: $showTrendsView) {
///             BodyTrendsView(
///                 viewModel: trendsViewModel,
///                 userGender: userProfile.gender,
///                 goalWeight: userProfile.goalWeight,
///                 goalBodyFat: userProfile.goalBodyFat
///             )
///         }
///     }
/// }
/// ```
///
/// NavigationLink로 표시:
/// ```swift
/// NavigationLink("트렌드 분석") {
///     BodyTrendsView(
///         viewModel: trendsViewModel,
///         userGender: .female
///     )
/// }
/// ```
///
/// 주요 기능:
/// - 기간 선택 (7/30/90일)
/// - 체중 트렌드 차트
/// - 체지방률 트렌드 차트 (건강 구간 표시)
/// - 통계 요약 (평균, 최소, 최대, 변화량)
/// - 목표선 표시
/// - 인터랙티브 차트 (탭하여 상세 정보)
/// - Pull-to-refresh 새로고침
/// - 빈 상태 처리
/// - 로딩 및 에러 상태 표시
///
/// 화면 구성:
/// 1. 기간 선택기: TrendPeriodPicker
/// 2. 통계 요약: 평균, 변화량 등
/// 3. 체중 차트: WeightTrendChart
/// 4. 체지방률 차트: BodyFatTrendChart (건강 구간 포함)
///
/// 네비게이션:
/// - NavigationStack 사용
/// - 닫기 버튼으로 dismiss
/// - Environment dismiss 사용
///
/// 상태 관리:
/// - ViewModel의 @Published 프로퍼티 관찰
/// - @StateObject로 ViewModel 생명주기 관리
/// - @Environment(\.dismiss)로 화면 닫기
///
/// 에러 처리:
/// - Alert로 에러 메시지 표시
/// - ViewModel에서 에러 상태 관리
/// - 사용자 친화적인 한글 메시지
///
/// 💡 Android 비교:
/// - Android: Fragment + Multiple Charts + Statistics
/// - SwiftUI: View + ScrollView + Charts + Statistics
/// - Android: RecyclerView with different view types
/// - SwiftUI: VStack with different sections
/// - Android: SwipeRefreshLayout
/// - SwiftUI: .refreshable modifier
///
/// 접근성:
/// - VoiceOver 지원
/// - Dynamic Type 지원
/// - 충분한 터치 영역
/// - 명확한 레이블과 힌트
///
/// 성능 최적화:
/// - ScrollView로 스크롤 가능
/// - 차트는 선택적 상호작용 (isInteractive)
/// - ViewModel에서 데이터 캐싱
/// - 기간 변경 시 debounce로 중복 호출 방지
///

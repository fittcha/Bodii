//
//  SleepTrendsView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Chart Display View Pattern for Sleep Trends
// 차트 중심의 수면 트렌드 분석 화면
// 💡 Java 비교: Android의 Chart Fragment와 유사하지만 더 선언적

import SwiftUI
import Charts

// MARK: - SleepTrendsView

/// 수면 트렌드 차트 화면
/// 📚 학습 포인트: Chart-Focused View for Sleep Analytics
/// - 수면 시간 및 품질 트렌드 차트 표시
/// - 기간 선택 기능 (7/30/90일)
/// - 통계 요약 정보 표시
/// - 상태별 분포 표시
/// - 빈 상태 처리
/// 💡 Java 비교: Android의 Analytics Fragment와 유사
struct SleepTrendsView: View {

    // MARK: - Properties

    /// ViewModel - 트렌드 데이터 관리
    /// 📚 학습 포인트: @StateObject
    /// - View의 생명주기와 연결된 ObservableObject
    /// - View가 사라져도 상태 유지
    /// 💡 Java 비교: Android ViewModel과 유사
    @StateObject private var viewModel: SleepTrendsViewModel

    /// 화면 닫기 액션
    /// 📚 학습 포인트: Environment Dismiss
    /// - Sheet나 NavigationStack에서 화면을 닫을 때 사용
    /// 💡 Java 비교: finish() 또는 popBackStack()과 유사
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// SleepTrendsView 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel을 외부에서 주입받음
    /// - 테스트 시 Mock ViewModel 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameter viewModel: 트렌드 ViewModel
    init(viewModel: SleepTrendsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack
        // iOS 16+의 새로운 네비게이션 시스템
        // 💡 Java 비교: Navigation Component와 유사
        NavigationStack {
            // 📚 학습 포인트: ScrollView for Scrollable Content
            // 여러 섹션을 스크롤 가능하게 표시
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

                        // 수면 트렌드 차트
                        sleepChartSection

                        // 상태 분포
                        statusDistributionSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("수면 트렌드 분석")
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
                    viewModel.clearError()
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
    /// - Picker를 카드 안에 배치
    private var periodSelectorSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.purple)

                Text("분석 기간")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // 📚 학습 포인트: Segmented Picker
            // iOS 스타일 세그먼트 컨트롤
            Picker("기간", selection: $viewModel.selectedPeriod) {
                Text("7일").tag(FetchSleepStatsUseCase.StatsPeriod.week)
                Text("30일").tag(FetchSleepStatsUseCase.StatsPeriod.month)
                Text("90일").tag(FetchSleepStatsUseCase.StatsPeriod.quarter)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 통계 요약 섹션
    /// 📚 학습 포인트: Statistics Summary for Sleep
    /// - 평균 수면 시간, 일관성, 품질 지표 표시
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "통계 요약",
                icon: "chart.bar.fill"
            )

            if let output = viewModel.statsOutput {
                statisticsCard(output: output)
            }
        }
    }

    /// 통계 카드
    /// 📚 학습 포인트: Statistics Display Card for Sleep
    /// - 여러 통계 지표를 그리드로 표시
    ///
    /// - Parameter output: 수면 통계 데이터 출력
    /// - Returns: 통계 카드 뷰
    private func statisticsCard(output: FetchSleepStatsUseCase.Output) -> some View {
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
                    .foregroundStyle(.purple)
            }

            Divider()

            // 통계 그리드
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // 평균 수면 시간
                statisticItem(
                    title: "평균 수면",
                    value: viewModel.averageDurationString,
                    icon: "moon.fill",
                    color: .purple
                )

                // 가장 많은 수면 상태
                statisticItem(
                    title: "가장 많은 상태",
                    value: viewModel.mostCommonStatusString,
                    icon: output.mostCommonStatus?.iconName ?? "moon.stars",
                    color: output.mostCommonStatus?.color ?? .blue
                )

                // 좋은 수면 비율
                statisticItem(
                    title: "좋은 수면 비율",
                    value: viewModel.goodSleepPercentageString,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                // 일관성 점수
                statisticItem(
                    title: "일관성 점수",
                    value: viewModel.consistencyScoreString,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            }

            // 추세 정보 (있는 경우)
            if let trend = viewModel.trendInfo {
                Divider()

                HStack(spacing: 8) {
                    Image(systemName: trend.change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(trend.change >= 0 ? .green : .orange)

                    Text("최근 추세: \(viewModel.trendString)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
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

    /// 수면 차트 섹션
    /// 📚 학습 포인트: Chart Section
    /// - SleepBarChart를 카드 안에 배치
    private var sleepChartSection: some View {
        VStack(spacing: 0) {
            SleepBarChart(
                viewModel: viewModel,
                isInteractive: true,
                height: 300,
                showStatusLegend: true
            )
            .padding(16)
        }
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 상태 분포 섹션
    /// 📚 학습 포인트: Status Distribution Display
    /// - 수면 상태별 빈도를 시각적으로 표시
    private var statusDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "수면 상태 분포",
                icon: "chart.pie.fill"
            )

            if let output = viewModel.statsOutput {
                statusDistributionCard(statusStats: output.statusStats)
            }
        }
    }

    /// 상태 분포 카드
    /// 📚 학습 포인트: Status Distribution Card
    /// - 각 수면 상태의 횟수와 비율을 표시
    ///
    /// - Parameter statusStats: 상태별 통계
    /// - Returns: 상태 분포 카드 뷰
    private func statusDistributionCard(statusStats: [FetchSleepStatsUseCase.StatusStats]) -> some View {
        VStack(spacing: 12) {
            // 상태별 표시 (매우좋음 → 좋음 → 보통 → 나쁨 → 과다수면 순)
            ForEach(statusStats.sorted { lhs, rhs in
                let order: [SleepStatus] = [.excellent, .good, .soso, .bad, .oversleep]
                let lhsIndex = order.firstIndex(of: lhs.status) ?? order.count
                let rhsIndex = order.firstIndex(of: rhs.status) ?? order.count
                return lhsIndex < rhsIndex
            }) { stat in
                statusDistributionRow(stat: stat)
            }

            // 빈 상태 (데이터가 없는 경우)
            if statusStats.isEmpty {
                Text("상태별 데이터가 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 상태 분포 행
    /// 📚 학습 포인트: Status Distribution Row
    /// - 하나의 수면 상태에 대한 정보 표시
    ///
    /// - Parameter stat: 상태 통계
    /// - Returns: 상태 분포 행 뷰
    private func statusDistributionRow(stat: FetchSleepStatsUseCase.StatusStats) -> some View {
        VStack(spacing: 8) {
            // 상태 정보
            HStack {
                // 아이콘과 이름
                HStack(spacing: 8) {
                    Image(systemName: stat.status.iconName)
                        .font(.body)
                        .foregroundStyle(stat.status.color)
                        .frame(width: 24)

                    Text(stat.status.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // 횟수와 비율
                HStack(spacing: 12) {
                    Text("\(stat.count)회")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.0f%%", stat.percentage * 100))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(stat.status.color)
                }
            }

            // 진행 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 바
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // 채워진 바
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stat.status.color)
                        .frame(width: geometry.size.width * CGFloat(stat.percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
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
            .foregroundStyle(.purple)
        }
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("수면 트렌드 데이터를 불러오는 중...")
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
            Image(systemName: "moon.zzz")
                .font(.system(size: 70))
                .foregroundStyle(.purple.opacity(0.3))

            VStack(spacing: 8) {
                Text("수면 트렌드 데이터가 없습니다")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("선택한 기간 동안의 수면 기록이 없습니다.\n수면 기록을 입력하면\n트렌드를 확인할 수 있습니다.")
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

                // 📚 학습 포인트: Inline Period Picker
                // 빈 상태에서도 기간을 쉽게 변경할 수 있도록
                Picker("기간", selection: $viewModel.selectedPeriod) {
                    Text("7일").tag(FetchSleepStatsUseCase.StatsPeriod.week)
                    Text("30일").tag(FetchSleepStatsUseCase.StatsPeriod.month)
                    Text("90일").tag(FetchSleepStatsUseCase.StatsPeriod.quarter)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)
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
                .foregroundStyle(.purple)

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
}

// MARK: - Preview

#if DEBUG
#Preview("기본 상태") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    // SleepTrendsView(viewModel: .makePreview())
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

/// 📚 학습 포인트: SleepTrendsView 사용법
///
/// 기본 사용 (DIContainer에서 생성):
/// ```swift
/// struct ContentView: View {
///     let container: DIContainer
///
///     var body: some View {
///         SleepTrendsView(
///             viewModel: container.makeSleepTrendsViewModel()
///         )
///     }
/// }
/// ```
///
/// Sheet로 표시 (권장):
/// ```swift
/// struct SleepTabView: View {
///     @State private var showTrendsView = false
///
///     var body: some View {
///         VStack {
///             Button("트렌드 보기") {
///                 showTrendsView = true
///             }
///         }
///         .sheet(isPresented: $showTrendsView) {
///             SleepTrendsView(
///                 viewModel: trendsViewModel
///             )
///         }
///     }
/// }
/// ```
///
/// NavigationLink로 표시:
/// ```swift
/// NavigationLink("트렌드 분석") {
///     SleepTrendsView(
///         viewModel: trendsViewModel
///     )
/// }
/// ```
///
/// 주요 기능:
/// - 기간 선택 (7/30/90일)
/// - 수면 시간 트렌드 차트 (상태별 색상 구분)
/// - 통계 요약 (평균, 일관성, 좋은 수면 비율, 추세)
/// - 상태별 분포 (횟수와 비율)
/// - 인터랙티브 차트 (탭하여 상세 정보)
/// - Pull-to-refresh 새로고침
/// - 빈 상태 처리
/// - 로딩 및 에러 상태 표시
///
/// 화면 구성:
/// 1. 기간 선택기: 7/30/90일 세그먼트 컨트롤
/// 2. 통계 요약: 평균 수면, 일관성, 좋은 수면 비율, 추세
/// 3. 수면 차트: SleepBarChart (상태별 색상)
/// 4. 상태 분포: 각 상태의 횟수와 비율
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
/// - Android: Fragment + Chart + Statistics + Distribution
/// - SwiftUI: View + ScrollView + Chart + Stats + Distribution
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
/// SleepHistoryView와의 차이:
/// - SleepHistoryView: 리스트 표시 및 편집/삭제
/// - SleepTrendsView: 차트 및 통계 분석 표시
/// - SleepHistoryView: CRUD 작업 중심
/// - SleepTrendsView: 데이터 분석 및 시각화 중심
///
/// BodyTrendsView와의 유사점:
/// - 동일한 구조 패턴 (기간 선택 + 통계 + 차트)
/// - 동일한 네비게이션 패턴
/// - 동일한 상태 관리 방식
/// - 차이점: 수면 데이터는 상태별 색상 구분, 상태 분포 섹션 추가
///

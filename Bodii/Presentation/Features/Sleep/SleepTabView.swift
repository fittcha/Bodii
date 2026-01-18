//
//  SleepTabView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Container View with Segmented Control
// 수면 기능 컨테이너 뷰 - History와 Trends 전환
// 💡 Java 비교: Android의 ViewPager + TabLayout과 유사

import SwiftUI

// MARK: - SleepTabView

/// 수면 기능 메인 컨테이너 뷰
/// 📚 학습 포인트: Container View Pattern
/// - Segmented control로 History/Trends 전환
/// - 각 탭에 해당하는 View 표시
/// - 수면 기록 추가 기능
/// 💡 Java 비교: Android의 Fragment Container + TabLayout과 유사
struct SleepTabView: View {

    // MARK: - Tab Selection

    /// 탭 선택 상태
    /// 📚 학습 포인트: Enum for Tab State
    /// - 타입 안전한 탭 구분
    enum Tab: String, CaseIterable {
        case history = "기록"
        case trends = "트렌드"
    }

    // MARK: - Properties

    /// DIContainer for dependency injection
    /// 📚 학습 포인트: Dependency Injection
    /// - ViewModel 생성을 위한 팩토리
    /// 💡 Java 비교: Dagger/Hilt의 Component와 유사
    let container: DIContainer

    /// 현재 선택된 탭
    /// 📚 학습 포인트: @State for Tab Selection
    /// - 탭 전환 상태 관리
    @State private var selectedTab: Tab = .history

    /// 수면 입력 시트 표시 여부
    /// 📚 학습 포인트: Sheet Presentation State
    /// - true일 때 SleepInputSheet 표시
    @State private var showInputSheet = false

    // Lazy ViewModels for each tab
    // 📚 학습 포인트: Lazy Initialization
    // - 각 탭의 ViewModel을 필요할 때만 생성
    @State private var historyViewModel: SleepHistoryViewModel?
    @State private var trendsViewModel: SleepTrendsViewModel?

    // MARK: - Initialization

    /// SleepTabView 초기화
    /// 📚 학습 포인트: Default Parameter
    /// - DIContainer 기본값 제공으로 편리한 사용
    /// 💡 Java 비교: 오버로딩된 생성자와 유사
    ///
    /// - Parameter container: DIContainer (기본값: .shared)
    init(container: DIContainer = .shared) {
        self.container = container
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack
        // iOS 16+의 새로운 네비게이션 시스템
        // 💡 Java 비교: Navigation Component와 유사
        NavigationStack {
            VStack(spacing: 0) {
                // 📚 학습 포인트: Segmented Picker
                // iOS 스타일 세그먼트 컨트롤로 탭 전환
                Picker("보기 모드", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // 구분선
                Divider()

                // 선택된 탭의 콘텐츠 표시
                // 📚 학습 포인트: Dynamic Content Switching
                // selectedTab에 따라 다른 뷰 표시
                selectedView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("수면")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            // 📚 학습 포인트: Sheet for Input
            // 수면 기록 추가 시트
            .sheet(isPresented: $showInputSheet) {
                SleepInputSheet(
                    viewModel: container.makeSleepInputViewModel(),
                    canSkip: true,
                    onSkip: nil
                )
            }
            .onAppear {
                // 📚 학습 포인트: Lazy ViewModel Initialization
                // 첫 등장 시 ViewModel 생성
                initializeViewModelsIfNeeded()
            }
        }
    }

    // MARK: - Subviews

    /// 선택된 탭에 따라 표시할 뷰
    /// 📚 학습 포인트: @ViewBuilder
    /// - 조건에 따라 다른 View 반환
    /// - switch/if 문 사용 가능
    /// 💡 Java 비교: Factory pattern과 유사
    @ViewBuilder
    private var selectedView: some View {
        switch selectedTab {
        case .history:
            // 📚 학습 포인트: History Content View
            // SleepHistoryView의 콘텐츠를 임베드
            // NavigationStack 중복을 피하기 위해 직접 구성
            if let historyViewModel = historyViewModel {
                SleepHistoryContentView(
                    viewModel: historyViewModel,
                    container: container
                )
            } else {
                // 로딩 플레이스홀더
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .trends:
            // 📚 학습 포인트: Trends Content View
            // SleepTrendsView의 콘텐츠를 임베드
            if let trendsViewModel = trendsViewModel {
                SleepTrendsContentView(
                    viewModel: trendsViewModel
                )
            } else {
                // 로딩 플레이스홀더
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    /// 추가 버튼
    /// 📚 학습 포인트: Toolbar Button
    /// - 수면 기록 추가 시트 열기
    private var addButton: some View {
        Button(action: {
            showInputSheet = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
        }
    }

    // MARK: - Helper Methods

    /// ViewModel 초기화 (필요한 경우에만)
    /// 📚 학습 포인트: Lazy Initialization Pattern
    /// - 처음 접근 시에만 ViewModel 생성
    /// - 메모리 효율성 향상
    private func initializeViewModelsIfNeeded() {
        if historyViewModel == nil {
            historyViewModel = container.makeSleepHistoryViewModel()
        }
        if trendsViewModel == nil {
            trendsViewModel = container.makeSleepTrendsViewModel()
        }
    }
}

// MARK: - SleepHistoryContentView

/// SleepHistoryView의 콘텐츠 (NavigationStack 제외)
/// 📚 학습 포인트: Content Extraction Pattern
/// - 기존 View에서 콘텐츠만 추출하여 재사용
/// - NavigationStack 중복 방지
fileprivate struct SleepHistoryContentView: View {

    @ObservedObject var viewModel: SleepHistoryViewModel
    let container: DIContainer

    @State private var showAddSheet: Bool = false

    var body: some View {
        ZStack {
            // 메인 콘텐츠
            if viewModel.isLoading && viewModel.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
        // 📚 학습 포인트: refreshable modifier
        // Pull-to-refresh 구현
        .refreshable {
            await viewModel.refresh()
        }
        // 📚 학습 포인트: Sheet for Editing Record
        // 레코드 편집 시트
        .sheet(item: $viewModel.recordToEdit) { record in
            SleepInputSheet(
                viewModel: container.makeSleepInputViewModel(
                    defaultHours: Int(record.duration / 60),
                    defaultMinutes: Int(record.duration % 60)
                ),
                canSkip: true,
                onSkip: nil
            )
        }
        // 📚 학습 포인트: Confirmation Dialog
        // 삭제 확인 대화상자
        .confirmationDialog(
            "수면 기록을 삭제하시겠습니까?",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                Task {
                    await viewModel.deleteRecord()
                }
            }
            Button("취소", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            Text("삭제된 데이터는 복구할 수 없습니다.")
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
        // 📚 학습 포인트: Toast for Success
        // 성공 메시지 표시
        .overlay(alignment: .top) {
            if let successMessage = viewModel.successMessage {
                successToast(message: successMessage)
                    .padding(.top, 60)
            }
        }
    }

    /// 리스트 뷰
    private var listView: some View {
        List {
            // 통계 섹션
            statisticsSection

            // 레코드 리스트 섹션
            recordsSection
        }
        .listStyle(.insetGrouped)
    }

    /// 통계 섹션
    private var statisticsSection: some View {
        Section {
            VStack(spacing: 12) {
                // 평균 수면 시간
                statisticRow(
                    icon: "clock.fill",
                    title: "평균 수면 시간",
                    value: viewModel.averageDurationString,
                    color: .blue
                )

                Divider()

                // 가장 많은 상태
                statisticRow(
                    icon: "moon.stars.fill",
                    title: "가장 많은 상태",
                    value: viewModel.mostCommonStatusString,
                    color: .orange
                )

                Divider()

                // 총 기록 수
                statisticRow(
                    icon: "list.bullet",
                    title: "총 기록 수",
                    value: "\(viewModel.recordCount)개",
                    color: .green
                )
            }
            .padding(.vertical, 8)
        } header: {
            HStack {
                Text("통계 요약")
                Spacer()
                queryModeMenu
            }
        }
    }

    /// 개별 통계 Row
    private func statisticRow(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }

    /// 레코드 리스트 섹션
    private var recordsSection: some View {
        Section {
            ForEach(viewModel.records) { record in
                SleepRecordRow(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.editRecord(record)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.editRecord(record)
                        } label: {
                            Label("편집", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(record: record)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        } header: {
            HStack {
                Text("수면 기록")
                Spacer()
                Text(queryModeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if !viewModel.isEmpty {
                Text("레코드를 탭하면 편집할 수 있습니다.\n스와이프하여 편집 또는 삭제할 수 있습니다.")
                    .font(.caption)
            }
        }
    }

    /// 조회 모드 설명
    private var queryModeDescription: String {
        switch viewModel.selectedMode {
        case .all:
            return "전체"
        case .recent(let days):
            return "최근 \(days)일"
        case .dateRange(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = Locale(identifier: "ko_KR")
            return "\(formatter.string(from: start)) ~ \(formatter.string(from: end))"
        }
    }

    /// 조회 모드 선택 메뉴
    private var queryModeMenu: some View {
        Menu {
            Button {
                viewModel.changeMode(to: .all)
            } label: {
                Label("전체 기록", systemImage: "calendar")
            }

            Divider()

            Button {
                viewModel.changeMode(to: .recent(days: 7))
            } label: {
                Label("최근 7일", systemImage: "7.circle")
            }

            Button {
                viewModel.changeMode(to: .recent(days: 30))
            } label: {
                Label("최근 30일", systemImage: "30.circle")
            }

            Button {
                viewModel.changeMode(to: .recent(days: 90))
            } label: {
                Label("최근 90일", systemImage: "90.circle")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.caption)
                .foregroundStyle(.blue)
        }
    }

    /// 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 80))
                .foregroundStyle(.gray.opacity(0.3))

            VStack(spacing: 12) {
                Text("수면 기록이 없습니다")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("수면 시간을 기록하면\n여기에 표시됩니다.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    /// 로딩 뷰
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("수면 기록을 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 성공 토스트
    private func successToast(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.green)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: viewModel.successMessage != nil)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.clearSuccess()
            }
        }
    }
}

// MARK: - SleepTrendsContentView

/// SleepTrendsView의 콘텐츠 (NavigationStack 제외)
/// 📚 학습 포인트: Content Extraction Pattern
/// - 기존 View에서 콘텐츠만 추출하여 재사용
/// - NavigationStack 중복 방지
fileprivate struct SleepTrendsContentView: View {

    @ObservedObject var viewModel: SleepTrendsViewModel

    var body: some View {
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
        .refreshable {
            await viewModel.refresh()
        }
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

    /// 기간 선택기 섹션
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
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                statisticItem(
                    title: "평균 수면",
                    value: viewModel.averageDurationString,
                    icon: "moon.fill",
                    color: .purple
                )

                statisticItem(
                    title: "가장 많은 상태",
                    value: viewModel.mostCommonStatusString,
                    icon: output.mostCommonStatus?.iconName ?? "moon.stars",
                    color: output.mostCommonStatus?.color ?? .blue
                )

                statisticItem(
                    title: "좋은 수면 비율",
                    value: viewModel.goodSleepPercentageString,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                statisticItem(
                    title: "일관성 점수",
                    value: viewModel.consistencyScoreString,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            }

            // 추세 정보
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
    private func statisticItem(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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
    private var statusDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
    private func statusDistributionCard(statusStats: [FetchSleepStatsUseCase.StatusStats]) -> some View {
        VStack(spacing: 12) {
            ForEach(statusStats) { stat in
                statusDistributionRow(stat: stat)
            }

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
    private func statusDistributionRow(stat: FetchSleepStatsUseCase.StatusStats) -> some View {
        VStack(spacing: 8) {
            HStack {
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

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(stat.status.color)
                        .frame(width: geometry.size.width * CGFloat(stat.percentage), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    /// 로딩 뷰
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

            VStack(spacing: 12) {
                Text("다른 기간을 선택해보세요:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

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
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
    }

    /// 날짜 포맷팅
    private func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("History Tab") {
    SleepTabView()
}

#Preview("Dark Mode") {
    SleepTabView()
        .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepTabView 사용법
///
/// 기본 사용:
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         SleepTabView()
///     }
/// }
/// ```
///
/// DIContainer 명시적 주입:
/// ```swift
/// SleepTabView(container: .shared)
/// ```
///
/// TabView 내에서 사용 (메인 앱):
/// ```swift
/// TabView {
///     SleepTabView()
///         .tabItem {
///             Label("수면", systemImage: "moon.zzz.fill")
///         }
/// }
/// ```
///
/// 주요 기능:
/// - Segmented control로 History/Trends 전환
/// - History: 수면 기록 리스트 및 편집/삭제
/// - Trends: 수면 트렌드 차트 및 통계
/// - 툴바의 추가 버튼으로 수면 기록 입력
///
/// 화면 구성:
/// 1. Navigation Bar: 제목 "수면", 추가 버튼
/// 2. Segmented Control: "기록" / "트렌드" 선택
/// 3. Content Area: 선택된 탭의 View 표시
///
/// 사용자 인터랙션:
/// - Segmented control 탭: 탭 전환
/// - 추가 버튼 탭: SleepInputSheet 표시
/// - History 탭: 리스트 조회, 편집, 삭제
/// - Trends 탭: 차트 조회, 기간 선택
///
/// 탭 구조:
/// - .history: 수면 기록 리스트 (SleepHistoryContentView)
/// - .trends: 수면 트렌드 분석 (SleepTrendsContentView)
///
/// 상태 관리:
/// - selectedTab: 현재 선택된 탭
/// - showInputSheet: 입력 시트 표시 여부
/// - historyViewModel: History 탭 ViewModel (lazy)
/// - trendsViewModel: Trends 탭 ViewModel (lazy)
///
/// ViewModel Lazy Initialization:
/// - 처음 화면이 나타날 때 ViewModel 생성
/// - 메모리 효율성 향상
/// - initializeViewModelsIfNeeded() 메서드에서 처리
///
/// NavigationStack 구조:
/// - SleepTabView: NavigationStack 제공 (최상위)
/// - SleepHistoryContentView: 콘텐츠만 (NavigationStack 없음)
/// - SleepTrendsContentView: 콘텐츠만 (NavigationStack 없음)
/// - 이렇게 하여 NavigationStack 중복 방지
///
/// 의존성:
/// - SleepHistoryViewModel: 기록 리스트 관리
/// - SleepTrendsViewModel: 트렌드 분석 관리
/// - SleepInputSheet: 수면 기록 입력
/// - SleepRecordRow: 개별 레코드 표시
/// - SleepBarChart: 트렌드 차트 표시
/// - DIContainer: ViewModel 생성
///
/// 💡 Android 비교:
/// - Android: ViewPager + TabLayout + Fragment
/// - SwiftUI: Picker + @State + View
/// - Android: FragmentManager for switching
/// - SwiftUI: @ViewBuilder + switch statement
/// - Android: Toolbar with menu items
/// - SwiftUI: NavigationStack + .toolbar
///
/// 접근성:
/// - VoiceOver 지원
/// - Dynamic Type 지원
/// - 충분한 터치 영역
/// - 명확한 레이블과 힌트
///
/// 성능 최적화:
/// - ViewModel lazy initialization
/// - 각 탭은 독립적으로 데이터 로드
/// - Pull-to-refresh로 수동 새로고침
///
/// 실무 팁:
/// - Segmented control은 2-3개 탭에 적합
/// - 각 탭은 독립적인 ViewModel 보유
/// - 추가 버튼은 모든 탭에서 접근 가능
/// - NavigationStack은 최상위에서만 한 번 사용
/// - 콘텐츠 추출 패턴으로 재사용성 향상
///

//
//  DashboardView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Dashboard View with Multiple Cards
// SwiftUI의 대시보드 화면 - 여러 모듈의 요약 정보를 한 곳에 표시
// 💡 Java 비교: Android의 Dashboard Fragment와 유사

import SwiftUI

// MARK: - DashboardView

/// 대시보드 메인 화면
/// 📚 학습 포인트: Dashboard Pattern
/// - 여러 모듈의 요약 정보를 카드 형태로 표시
/// - 각 카드는 해당 모듈로 네비게이션 가능
/// - 주요 지표와 빠른 액세스 제공
/// 💡 Java 비교: Android의 Home Fragment + CardViews와 유사
struct DashboardView: View {

    // MARK: - Properties

    /// Metabolism ViewModel - BMR/TDEE 데이터 관리
    /// 📚 학습 포인트: @StateObject
    /// - View의 생명주기와 연결된 ObservableObject
    /// - Dashboard에서 대사율 데이터 관리
    /// 💡 Java 비교: Android ViewModel과 유사
    @StateObject private var metabolismViewModel: MetabolismViewModel

    /// Goal Progress ViewModel - 목표 진행상황 데이터 관리
    /// 📚 학습 포인트: @StateObject for Goal Progress
    /// - Dashboard에서 목표 진행상황 요약 표시
    /// - 활성 목표 여부 확인 및 진행률 표시
    @StateObject private var goalProgressViewModel: GoalProgressViewModel

    /// 체성분 탭으로 이동하는 콜백
    /// 📚 학습 포인트: Closure-based Navigation
    /// - 부모 View에서 탭 전환 로직을 처리
    /// - 카드 탭 시 호출되어 해당 탭으로 이동
    /// 💡 Java 비교: Callback interface와 유사
    var onNavigateToBody: (() -> Void)?

    /// 사용자 ID (목표 설정 시 필요)
    /// 📚 학습 포인트: User Context
    /// - 목표는 사용자별로 관리됨
    /// - 목표 설정 화면에 userId 전달
    let userId: UUID

    /// Pull-to-refresh 상태
    /// 📚 학습 포인트: Refresh State
    @State private var isRefreshing = false

    /// 목표 진행상황 화면 표시 여부
    /// 📚 학습 포인트: Sheet Navigation State
    /// - 활성 목표가 있을 때 진행상황 화면 표시
    @State private var showGoalProgress = false

    /// 목표 설정 화면 표시 여부
    /// 📚 학습 포인트: Sheet Navigation State
    /// - 활성 목표가 없을 때 목표 설정 화면 표시
    @State private var showGoalSetting = false

    // MARK: - Initialization

    /// DashboardView 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel과 네비게이션 콜백을 외부에서 주입받음
    /// - 테스트 시 Mock ViewModel 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameters:
    ///   - metabolismViewModel: 대사율 ViewModel
    ///   - goalProgressViewModel: 목표 진행상황 ViewModel
    ///   - userId: 사용자 ID (목표 설정 시 필요)
    ///   - onNavigateToBody: 체성분 탭으로 이동하는 콜백
    init(
        metabolismViewModel: MetabolismViewModel,
        goalProgressViewModel: GoalProgressViewModel,
        userId: UUID,
        onNavigateToBody: (() -> Void)? = nil
    ) {
        self._metabolismViewModel = StateObject(wrappedValue: metabolismViewModel)
        self._goalProgressViewModel = StateObject(wrappedValue: goalProgressViewModel)
        self.userId = userId
        self.onNavigateToBody = onNavigateToBody
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 환영 헤더
                    welcomeHeader

                    // 대사율 카드 (BMR/TDEE)
                    metabolismCard

                    // 목표 카드 (Goal Progress)
                    goalCard

                    // 추가 대시보드 카드들 (향후 구현)
                    // - 오늘의 식단 요약
                    // - 오늘의 운동 요약
                    // - 수면 요약
                    // - 주간 트렌드 차트

                    placeholderCards
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
            .task {
                // 📚 학습 포인트: task modifier
                // View가 나타날 때 비동기 작업 실행
                // 💡 Java 비교: onResume()에서 데이터 로드와 유사
                await metabolismViewModel.loadCurrentMetabolism()
                await goalProgressViewModel.loadProgress()
            }
            .alert("오류", isPresented: .constant(metabolismViewModel.errorMessage != nil)) {
                Button("확인") {
                    metabolismViewModel.clearError()
                }
            } message: {
                if let errorMessage = metabolismViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showGoalProgress) {
                // 📚 학습 포인트: Sheet Navigation
                // 목표 진행상황 화면을 모달로 표시
                // 💡 Java 비교: startActivityForResult()와 유사
                let goalProgressVM = DIContainer.shared.makeGoalProgressViewModel()
                GoalProgressView(
                    viewModel: goalProgressVM,
                    onEditGoal: {
                        showGoalProgress = false
                        showGoalSetting = true
                    }
                )
            }
            .sheet(isPresented: $showGoalSetting) {
                // 📚 학습 포인트: Sheet Navigation
                // 목표 설정 화면을 모달로 표시
                let goalSettingVM = DIContainer.shared.makeGoalSettingViewModel(userId: userId)
                GoalSettingView(
                    viewModel: goalSettingVM,
                    onSaveSuccess: {
                        showGoalSetting = false
                        // 목표 설정 후 진행상황 새로고침
                        Task {
                            await goalProgressViewModel.loadProgress()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    /// 환영 헤더
    /// 📚 학습 포인트: Greeting Header
    /// - 현재 시간에 따라 인사말 변경 가능
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingMessage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("오늘의 건강 요약을 확인하세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 날짜 표시
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDate(Date()))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(formatTime(Date()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    /// 대사율 카드
    /// 📚 학습 포인트: Reusable Card Component
    /// - MetabolismDisplayCard 컴포넌트 사용
    /// - 탭하면 체성분 탭으로 이동
    private var metabolismCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "대사율",
                subtitle: "기초대사량과 총 에너지 소비량"
            )

            // 대사율 표시 카드
            MetabolismDisplayCard(
                viewModel: metabolismViewModel,
                onTap: {
                    // 📚 학습 포인트: Callback Navigation
                    // 카드 탭 시 체성분 탭으로 이동 콜백 호출
                    onNavigateToBody?()
                }
            )
        }
    }

    /// 목표 카드
    /// 📚 학습 포인트: Goal Progress Card
    /// - 활성 목표가 있으면 진행상황 요약 표시
    /// - 활성 목표가 없으면 목표 설정 CTA 표시
    /// - 카드 탭 시 해당 화면으로 이동
    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "목표",
                subtitle: goalProgressViewModel.hasGoal ? "목표 달성 진행상황" : "목표를 설정하고 진행상황을 추적하세요"
            )

            // 목표 카드 콘텐츠
            if goalProgressViewModel.isLoading {
                // 로딩 상태
                goalLoadingCard
            } else if goalProgressViewModel.hasNoActiveGoal {
                // 활성 목표 없음 - CTA 표시
                goalEmptyCard
            } else if goalProgressViewModel.hasGoal {
                // 활성 목표 있음 - 진행상황 요약 표시
                goalProgressCard
            } else {
                // 에러 상태
                goalErrorCard
            }
        }
    }

    /// 목표 로딩 카드
    /// 📚 학습 포인트: Loading State Card
    private var goalLoadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("목표 정보를 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 목표 비어있음 카드
    /// 📚 학습 포인트: Empty State with CTA
    /// - 목표가 없을 때 설정 유도 카드 표시
    private var goalEmptyCard: some View {
        Button {
            showGoalSetting = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    Text("목표 설정하기")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("목표를 설정하고 진행상황을 추적하세요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Label("체중 목표", systemImage: "scalemass")
                        Label("체지방 목표", systemImage: "percent")
                        Label("근육량 목표", systemImage: "figure.strengthtraining.traditional")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    /// 목표 진행상황 카드
    /// 📚 학습 포인트: Goal Progress Summary Card
    /// - 전체 진행률과 주요 지표 표시
    /// - 탭하면 상세 진행상황 화면으로 이동
    private var goalProgressCard: some View {
        Button {
            showGoalProgress = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("진행중인 목표")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if let goalType = goalProgressViewModel.currentGoal?.goalType {
                            Text(goalType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // 진행률 배지
                    if let overallProgress = goalProgressViewModel.overallProgress {
                        HStack(spacing: 4) {
                            Text("\(Int(overallProgress.rounded()))%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // 프로그레스 바
                if let overallProgress = goalProgressViewModel.overallProgress {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 배경
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            // 진행률
                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressGradient(for: overallProgress))
                                .frame(
                                    width: geometry.size.width * min(Double(truncating: overallProgress as NSNumber) / 100.0, 1.0),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }

                // 목표 요약
                HStack(spacing: 16) {
                    if let weightProgress = goalProgressViewModel.weightProgress {
                        goalMetricPill(
                            icon: "scalemass",
                            value: "\(Int(weightProgress.percentage.rounded()))%",
                            label: "체중",
                            color: .blue
                        )
                    }

                    if let bodyFatProgress = goalProgressViewModel.bodyFatProgress {
                        goalMetricPill(
                            icon: "percent",
                            value: "\(Int(bodyFatProgress.percentage.rounded()))%",
                            label: "체지방",
                            color: .orange
                        )
                    }

                    if let muscleProgress = goalProgressViewModel.muscleProgress {
                        goalMetricPill(
                            icon: "figure.strengthtraining.traditional",
                            value: "\(Int(muscleProgress.percentage.rounded()))%",
                            label: "근육량",
                            color: .green
                        )
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    /// 목표 에러 카드
    /// 📚 학습 포인트: Error State Card
    private var goalErrorCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)

            Text("목표 정보를 불러올 수 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let errorMessage = goalProgressViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("다시 시도") {
                Task {
                    await goalProgressViewModel.loadProgress()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 목표 지표 필
    /// 📚 학습 포인트: Metric Pill Component
    /// - 작은 공간에서 지표를 표시하는 캡슐형 UI
    private func goalMetricPill(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }

    /// 진행률에 따른 그라디언트 색상
    /// 📚 학습 포인트: Dynamic Gradient
    /// - 진행률에 따라 다른 색상 그라디언트 반환
    private func progressGradient(for progress: Decimal) -> LinearGradient {
        let progressValue = Double(truncating: progress as NSNumber)

        if progressValue >= 100 {
            // 목표 달성: 녹색 그라디언트
            return LinearGradient(
                colors: [.green, .green.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if progressValue >= 75 {
            // 75% 이상: 파란색 그라디언트
            return LinearGradient(
                colors: [.blue, .blue.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if progressValue >= 50 {
            // 50-74%: 보라색 그라디언트
            return LinearGradient(
                colors: [.purple, .purple.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if progressValue >= 25 {
            // 25-49%: 주황색 그라디언트
            return LinearGradient(
                colors: [.orange, .orange.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // 25% 미만: 빨간색 그라디언트
            return LinearGradient(
                colors: [.red, .red.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    /// 플레이스홀더 카드들
    /// 📚 학습 포인트: Future Implementation Placeholder
    /// - 향후 구현할 카드들의 위치 표시
    private var placeholderCards: some View {
        VStack(spacing: 20) {
            // 식단 카드 플레이스홀더
            placeholderCard(
                title: "오늘의 식단",
                subtitle: "칼로리 섭취 및 영양소 요약",
                icon: "fork.knife",
                color: .orange
            )

            // 운동 카드 플레이스홀더
            placeholderCard(
                title: "오늘의 운동",
                subtitle: "운동 시간 및 칼로리 소비",
                icon: "figure.run",
                color: .green
            )

            // 수면 카드 플레이스홀더
            placeholderCard(
                title: "수면 기록",
                subtitle: "수면 시간 및 품질",
                icon: "moon.zzz.fill",
                color: .purple
            )
        }
    }

    /// 섹션 헤더
    /// 📚 학습 포인트: Section Header Component
    /// - 카드 위에 표시되는 섹션 제목
    ///
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - subtitle: 섹션 부제목
    /// - Returns: 섹션 헤더 뷰
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    /// 플레이스홀더 카드
    /// 📚 학습 포인트: Placeholder Card Pattern
    /// - 향후 구현할 기능의 위치를 표시
    /// - 사용자에게 앱의 전체 구조를 미리 보여줌
    ///
    /// - Parameters:
    ///   - title: 카드 제목
    ///   - subtitle: 카드 부제목
    ///   - icon: SF Symbol 아이콘
    ///   - color: 아이콘 색상
    /// - Returns: 플레이스홀더 카드 뷰
    private func placeholderCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()
            }

            // 콘텐츠
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "hourglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("준비 중입니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                Spacer()
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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

    /// 데이터 새로고침
    /// 📚 학습 포인트: Pull-to-Refresh
    /// - 사용자가 아래로 당길 때 실행
    private func refreshData() async {
        isRefreshing = true
        await metabolismViewModel.refresh()
        await goalProgressViewModel.refresh()
        // TODO: 다른 ViewModel들도 새로고침
        isRefreshing = false
    }

    /// 인사말 메시지
    /// 📚 학습 포인트: Time-based Greeting
    /// - 현재 시간에 따라 다른 인사말 반환
    ///
    /// - Returns: 시간대별 인사말
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<6:
            return "좋은 밤입니다 👋"
        case 6..<12:
            return "좋은 아침입니다 ☀️"
        case 12..<18:
            return "좋은 오후입니다 🌤️"
        case 18..<21:
            return "좋은 저녁입니다 🌆"
        default:
            return "좋은 밤입니다 🌙"
        }
    }

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "2026년 1월 12일")
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 시간 포맷팅
    /// 📚 학습 포인트: Time Formatting
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "14:30")
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("대시보드 - 데이터 있음") {
    // TODO: Mock ViewModel 구현 후 Preview 추가
    // DashboardView(
    //     metabolismViewModel: .makePreviewWithData(),
    //     selectedTab: .constant(0)
    // )
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("대시보드 - 빈 상태") {
    // TODO: Mock ViewModel 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("다크 모드") {
    // TODO: Mock ViewModel 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
        .preferredColorScheme(.dark)
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: DashboardView 사용법
///
/// 기본 사용 (ContentView에서):
/// ```swift
/// struct ContentView: View {
///     @State private var selectedTab: Tab = .dashboard
///     let container: DIContainer
///
///     var body: some View {
///         TabView(selection: $selectedTab) {
///             DashboardView(
///                 metabolismViewModel: container.makeMetabolismViewModel(),
///                 onNavigateToBody: {
///                     selectedTab = .body
///                 }
///             )
///             .tabItem {
///                 Label("대시보드", systemImage: "chart.bar.fill")
///             }
///             .tag(Tab.dashboard)
///
///             // 다른 탭들...
///         }
///     }
/// }
/// ```
///
/// 주요 기능:
/// - 대사율 카드: BMR/TDEE 표시, 탭하면 체성분 탭으로 이동
/// - 시간대별 인사말: 현재 시간에 따라 다른 메시지
/// - Pull-to-refresh: 데이터 새로고침
/// - 플레이스홀더 카드: 향후 구현할 기능 표시
///
/// 화면 구성:
/// 1. 환영 헤더: 인사말 + 현재 날짜/시간
/// 2. 대사율 카드: MetabolismDisplayCard 사용
/// 3. 식단 카드: 플레이스홀더 (향후 구현)
/// 4. 운동 카드: 플레이스홀더 (향후 구현)
/// 5. 수면 카드: 플레이스홀더 (향후 구현)
///
/// 네비게이션:
/// - 대사율 카드 탭: onNavigateToBody 콜백 호출
/// - 부모 View에서 탭 전환 로직 처리
///
/// 상태 관리:
/// - MetabolismViewModel: BMR/TDEE 데이터
/// - @StateObject로 ViewModel 생명주기 관리
/// - Closure를 통해 네비게이션 이벤트 전달
///
/// 향후 확장:
/// - DietViewModel 추가: 오늘의 식단 요약
/// - ExerciseViewModel 추가: 오늘의 운동 요약
/// - SleepViewModel 추가: 수면 기록 요약
/// - 주간 트렌드 차트: 체중/체지방 변화 그래프
/// - 목표 달성 진행률: 목표까지의 진척도 표시
///
/// 💡 Android 비교:
/// - Android: Fragment + RecyclerView with CardViews
/// - SwiftUI: View + ScrollView with VStack of Cards
/// - Android: ViewModel + LiveData
/// - SwiftUI: @StateObject + @Published
/// - Android: Fragment navigation via callback
/// - SwiftUI: Closure-based navigation
///
/// 접근성:
/// - VoiceOver 지원
/// - Dynamic Type 지원
/// - 충분한 터치 영역
/// - 명확한 레이블과 힌트
///

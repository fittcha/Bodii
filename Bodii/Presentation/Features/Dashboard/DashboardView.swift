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

    /// Sleep Repository - 수면 데이터 접근
    /// 📚 학습 포인트: Repository Dependency Injection
    /// - Repository 패턴을 통한 데이터 접근 추상화
    /// - 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: @Autowired Repository와 유사
    private let sleepRepository: SleepRepositoryProtocol

    /// 오늘의 수면 기록
    /// 📚 학습 포인트: @State for Data
    /// - 비동기로 로드된 수면 데이터 저장
    /// - nil이면 데이터 없음 상태
    /// 💡 Java 비교: LiveData와 유사
    @State private var todaysSleep: SleepRecord?

    /// 수면 데이터 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 비동기 작업 진행 중 표시
    @State private var isSleepLoading = false

    /// 체성분 탭으로 이동하는 콜백
    /// 📚 학습 포인트: Closure-based Navigation
    /// - 부모 View에서 탭 전환 로직을 처리
    /// - 카드 탭 시 호출되어 해당 탭으로 이동
    /// 💡 Java 비교: Callback interface와 유사
    var onNavigateToBody: (() -> Void)?

    /// 수면 탭으로 이동하는 콜백
    /// 📚 학습 포인트: Closure-based Navigation
    /// - 수면 카드 탭 시 수면 탭으로 이동
    var onNavigateToSleep: (() -> Void)?

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
    /// - ViewModel, Repository와 네비게이션 콜백을 외부에서 주입받음
    /// - 테스트 시 Mock 객체 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameters:
    ///   - metabolismViewModel: 대사율 ViewModel
    ///   - goalProgressViewModel: 목표 진행상황 ViewModel
    ///   - sleepRepository: 수면 데이터 Repository
    ///   - userId: 사용자 ID (목표 설정 시 필요)
    ///   - onNavigateToBody: 체성분 탭으로 이동하는 콜백
    ///   - onNavigateToSleep: 수면 탭으로 이동하는 콜백
    init(
        metabolismViewModel: MetabolismViewModel,
        goalProgressViewModel: GoalProgressViewModel,
        sleepRepository: SleepRepositoryProtocol,
        userId: UUID,
        onNavigateToBody: (() -> Void)? = nil,
        onNavigateToSleep: (() -> Void)? = nil
    ) {
        self._metabolismViewModel = StateObject(wrappedValue: metabolismViewModel)
        self._goalProgressViewModel = StateObject(wrappedValue: goalProgressViewModel)
        self.sleepRepository = sleepRepository
        self.userId = userId
        self.onNavigateToBody = onNavigateToBody
        self.onNavigateToSleep = onNavigateToSleep
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

                    // 수면 카드
                    sleepCard

                    // 목표 카드 (Goal Progress)
                    goalCard

                    // 추가 대시보드 카드들 (향후 구현)
                    // - 오늘의 식단 요약
                    // - 오늘의 운동 요약
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
                await loadTodaysSleep()
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

    /// 수면 카드
    /// 📚 학습 포인트: Sleep Card Component
    /// - SleepDisplayCard 컴포넌트 사용
    /// - 오늘의 수면 기록 표시
    /// - 탭하면 수면 탭으로 이동
    private var sleepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "수면 기록",
                subtitle: "수면 시간 및 품질"
            )

            // 수면 표시 카드
            SleepDisplayCard(
                sleepRecord: todaysSleep,
                isLoading: isSleepLoading,
                onTap: {
                    // 📚 학습 포인트: Callback Navigation
                    // 카드 탭 시 수면 탭으로 이동 콜백 호출
                    onNavigateToSleep?()
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

                        if let goalTypeRaw = goalProgressViewModel.currentGoal?.goalType,
                           let goalType = GoalType(rawValue: goalTypeRaw) {
                            Text(goalType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // 진행률 배지
                    HStack(spacing: 4) {
                        let overallProgress = goalProgressViewModel.overallProgress
                        Text("\(NSDecimalNumber(decimal: overallProgress).intValue)%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // 프로그레스 바
                GeometryReader { geometry in
                    let overallProgress = goalProgressViewModel.overallProgress
                    ZStack(alignment: .leading) {
                        // 배경
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        // 진행률
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressGradient(for: NSDecimalNumber(decimal: overallProgress)))
                            .frame(
                                width: geometry.size.width * min(NSDecimalNumber(decimal: overallProgress).doubleValue / 100.0, 1.0),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)

                // 목표 요약
                HStack(spacing: 16) {
                    if let weightProgress = goalProgressViewModel.weightProgress {
                        goalMetricPill(
                            icon: "scalemass",
                            value: "\(NSDecimalNumber(decimal: weightProgress.percentage).intValue)%",
                            label: "체중",
                            color: .blue
                        )
                    }

                    if let bodyFatProgress = goalProgressViewModel.bodyFatProgress {
                        goalMetricPill(
                            icon: "percent",
                            value: "\(NSDecimalNumber(decimal: bodyFatProgress.percentage).intValue)%",
                            label: "체지방",
                            color: .orange
                        )
                    }

                    if let muscleProgress = goalProgressViewModel.muscleProgress {
                        goalMetricPill(
                            icon: "figure.strengthtraining.traditional",
                            value: "\(NSDecimalNumber(decimal: muscleProgress.percentage).intValue)%",
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

            Button {
                Task {
                    await goalProgressViewModel.loadProgress()
                }
            } label: {
                Text("다시 시도")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 목표 지표 필 (Badge)
    /// 📚 학습 포인트: Metric Pill Component
    /// - 목표별 진행률을 작은 배지로 표시
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - value: 진행률 값 (%)
    ///   - label: 레이블
    ///   - color: 색상
    /// - Returns: 지표 필 뷰
    private func goalMetricPill(
        icon: String,
        value: String,
        label: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(color.opacity(0.1)))
        .cornerRadius(8)
    }

    /// 진행률에 따른 그래디언트
    /// 📚 학습 포인트: Dynamic Gradient
    /// - 진행률에 따라 색상이 변함 (낮음: 빨강, 중간: 주황, 높음: 초록)
    ///
    /// - Parameter progress: 진행률 (0-100)
    /// - Returns: 그래디언트
    private func progressGradient(for progress: NSNumber) -> LinearGradient {
        let progressValue = Double(truncating: progress)

        let startColor: Color
        let endColor: Color

        if progressValue < 33 {
            // 낮음: 빨강
            startColor = .red
            endColor = .orange
        } else if progressValue < 66 {
            // 중간: 주황
            startColor = .orange
            endColor = .yellow
        } else {
            // 높음: 초록
            startColor = .yellow
            endColor = .green
        }

        return LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
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
        await loadTodaysSleep()
        await goalProgressViewModel.loadProgress()
        // TODO: 다른 ViewModel들도 새로고침
        isRefreshing = false
    }

    /// 오늘의 수면 기록 로드
    /// 📚 학습 포인트: Async Data Loading
    /// - Repository로부터 오늘의 수면 데이터를 비동기로 조회
    /// - 02:00 경계 로직 적용 (새벽 2시 이전은 전날)
    /// - 에러가 발생해도 앱이 멈추지 않도록 조용히 처리
    /// 💡 Java 비교: CoroutineScope.launch + Repository 호출과 유사
    private func loadTodaysSleep() async {
        isSleepLoading = true
        defer { isSleepLoading = false }

        do {
            // 📚 학습 포인트: fetch(for:) 사용
            // Repository의 fetch(for:) 메서드는 02:00 경계 로직을 자동 적용
            // 예: 새벽 1시에 호출하면 전날의 수면 기록을 가져옴
            todaysSleep = try await sleepRepository.fetch(for: Date())
        } catch {
            // 📚 학습 포인트: Silent Error Handling
            // 대시보드에서는 수면 데이터가 필수가 아니므로
            // 에러 발생 시 조용히 nil로 처리 (빈 상태 표시)
            // 만약 사용자에게 알려야 한다면 errorMessage State 사용
            todaysSleep = nil
        }
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
///                 goalProgressViewModel: container.makeGoalProgressViewModel(),
///                 sleepRepository: container.makeSleepRepository(),
///                 userId: userId,
///                 onNavigateToBody: {
///                     selectedTab = .body
///                 },
///                 onNavigateToSleep: {
///                     selectedTab = .sleep
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
/// - 수면 카드: 오늘의 수면 기록 표시, 탭하면 수면 탭으로 이동
/// - 목표 카드: 활성 목표 진행상황 표시 또는 목표 설정 유도
/// - 시간대별 인사말: 현재 시간에 따라 다른 메시지
/// - Pull-to-refresh: 데이터 새로고침
/// - 플레이스홀더 카드: 향후 구현할 기능 표시
///
/// 화면 구성:
/// 1. 환영 헤더: 인사말 + 현재 날짜/시간
/// 2. 대사율 카드: MetabolismDisplayCard 사용
/// 3. 수면 카드: SleepDisplayCard 사용
/// 4. 목표 카드: 목표 진행상황 또는 설정 CTA
/// 5. 식단 카드: 플레이스홀더 (향후 구현)
/// 6. 운동 카드: 플레이스홀더 (향후 구현)
///
/// 네비게이션:
/// - 대사율 카드 탭: onNavigateToBody 콜백 호출
/// - 수면 카드 탭: onNavigateToSleep 콜백 호출
/// - 목표 카드 탭: 목표 진행상황 또는 설정 화면 표시
/// - 부모 View에서 탭 전환 로직 처리
///
/// 상태 관리:
/// - MetabolismViewModel: BMR/TDEE 데이터
/// - GoalProgressViewModel: 목표 진행상황 데이터
/// - SleepRepository: 수면 데이터 접근
/// - @StateObject로 ViewModel 생명주기 관리
/// - Closure를 통해 네비게이션 이벤트 전달
///
/// 향후 확장:
/// - DietViewModel 추가: 오늘의 식단 요약
/// - ExerciseViewModel 추가: 오늘의 운동 요약
/// - 주간 트렌드 차트: 체중/체지방 변화 그래프
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
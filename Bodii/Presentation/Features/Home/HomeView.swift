//
//  HomeView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-28.
//

import SwiftUI

// MARK: - Home View

/// 새로운 홈 화면
///
/// **구성**:
/// 1. 날짜 + 인사말
/// 2. 오늘의 칼로리 (섭취 vs 소모)
/// 3. 스와이프 카드 (주간 캘린더 | 체성분 그래프)
/// 4. AI 한줄평
struct HomeView: View {

    // MARK: - Properties

    @StateObject private var viewModel: HomeViewModel

    /// 현재 선택된 카드 인덱스 (0: 캘린더, 1: 그래프)
    @State private var selectedCardIndex: Int = 0

    // MARK: - Initialization

    init(viewModel: HomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 날짜 + 인사말
                headerSection

                // 오늘의 칼로리
                calorieSection

                // 스와이프 카드 (주간 캘린더 | 체성분 그래프)
                swipeCardSection

                // AI 한줄평
                aiCommentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.formattedDate)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(viewModel.greetingMessage)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Calorie Section

    private var calorieSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                // 섭취 칼로리 (목표 ±10% 이내: 초록, 이외: 주황)
                calorieCard(
                    title: "섭취",
                    value: viewModel.intakeCalories,
                    unit: "kcal",
                    icon: "fork.knife",
                    color: viewModel.isIntakeNearTarget ? .green : .orange
                )

                // 구분선
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.vertical, 16)

                // 소모 칼로리 (운동 칼로리만)
                calorieCard(
                    title: "소모",
                    value: viewModel.burnCalories,
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .red
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

            // 칼로리 프로그레스 바
            calorieProgressBar
        }
    }

    /// 칼로리 카드
    private func calorieCard(
        title: String,
        value: Int,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    /// 칼로리 프로그레스 바
    private var calorieProgressBar: some View {
        VStack(spacing: 8) {
            // 프로그레스 바
            GeometryReader { geometry in
                let barWidth = geometry.size.width
                let target = Double(viewModel.effectiveTarget)
                let intake = Double(viewModel.intakeCalories)
                let burn = Double(viewModel.burnCalories)
                // 프로그레스 바 전체 길이 = 목표 칼로리의 120%
                let barMax = target * 1.2
                let intakeWidth = barMax > 0
                    ? min(CGFloat(intake / barMax) * barWidth, barWidth)
                    : 0.0
                let burnWidth = barMax > 0
                    ? min(CGFloat(burn / barMax) * barWidth, intakeWidth)
                    : 0.0
                let targetX = barMax > 0
                    ? min(CGFloat(target / barMax) * barWidth, barWidth)
                    : 0.0
                let barColor: Color = viewModel.isIntakeNearTarget ? .green : .orange

                ZStack(alignment: .leading) {
                    // 배경 (회색)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    // 섭취 바 (조건부 색상)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: max(0, intakeWidth), height: 12)

                    // 소모 칼로리 빨간색 덧칠 (섭취 바 오른쪽 끝에서 왼쪽으로)
                    if burn > 0 && intakeWidth > 0 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red)
                            .frame(width: max(0, burnWidth), height: 12)
                            .offset(x: max(0, intakeWidth - burnWidth))
                    }

                    // 목표 점선 (바 높이 내, 진한 회색)
                    Rectangle()
                        .fill(Color(.systemGray2))
                        .frame(width: 1.5, height: 12)
                        .mask(
                            VStack(spacing: 2) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Rectangle().frame(height: 2)
                                }
                            }
                        )
                        .offset(x: targetX - 0.75)
                }
            }
            .frame(height: 12)

            // 하단 텍스트: 잔여 왼쪽, 목표 오른쪽
            HStack {
                let remaining = viewModel.remainingCalories
                Text(remaining >= 0
                    ? "잔여 \(remaining.formatted()) kcal"
                    : "\(abs(remaining).formatted()) kcal 초과")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(remaining >= 0 ? .secondary : .red)

                Spacer()

                Text("목표 \(viewModel.effectiveTarget.formatted()) kcal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    // MARK: - Swipe Card Section

    private var swipeCardSection: some View {
        VStack(spacing: 12) {
            // 탭 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedCardIndex ? Color.blue : Color(.systemGray4))
                        .frame(width: index == selectedCardIndex ? 20 : 8, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: selectedCardIndex)
                }
            }

            // 스와이프 가능한 카드
            TabView(selection: $selectedCardIndex) {
                // 주간 캘린더
                WeeklyCalendarView(
                    weekData: viewModel.weekData,
                    today: Date()
                )
                .tag(0)

                // 체성분 그래프
                BodyCompositionChartView(
                    data: viewModel.bodyChartData,
                    gender: viewModel.userGender
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
        }
    }

    // MARK: - AI Comment Section

    private var aiCommentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)

                Text("AI 한줄평")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            if let comment = viewModel.aiComment {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                    )
            } else {
                Text("오늘의 데이터를 분석 중입니다...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
}

// MARK: - Home ViewModel

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var intakeCalories: Int = 0
    @Published var burnCalories: Int = 0
    @Published var activeCaloriesOut: Int = 0
    @Published var tdee: Int = 2000
    @Published var dailyCalorieTarget: Int = 0
    @Published var weekData: [DayScore] = []
    @Published var bodyChartData: [BodyChartData] = []
    @Published var aiComment: String?
    @Published var isLoading: Bool = false
    @Published var userGender: Gender = .male

    // MARK: - Private Properties

    private let userId: UUID
    private let sleepRepository: SleepRepositoryProtocol
    private let dietCommentRepository: DietCommentRepository
    private let bodyRepository: BodyRepositoryProtocol
    private let foodRecordRepository: FoodRecordRepositoryProtocol
    private let exerciseRepository: ExerciseRecordRepository
    private let goalRepository: GoalRepositoryProtocol
    private let userRepository: UserRepository
    private let dailyLogRepository: DailyLogRepository
    private let geminiService: GeminiServiceProtocol

    /// 마지막 코칭 생성 시각의 hour (0-23), 중복 호출 방지용
    private var lastCoachingHour: Int?
    /// 코칭 갱신 타이머
    private var coachingTimer: Timer?

    // MARK: - Computed Properties

    /// 총 소모 칼로리 (수동 운동 + HealthKit 활동 칼로리)
    var totalBurnCalories: Int {
        burnCalories + activeCaloriesOut
    }

    /// 순 섭취 칼로리 (섭취 - 총 소모)
    var netIntake: Int {
        max(0, intakeCalories - totalBurnCalories)
    }

    /// 총 섭취 비율 (주황색 바 길이)
    var intakeRatio: Double {
        guard tdee > 0 else { return 0 }
        return Double(intakeCalories) / Double(tdee)
    }

    /// 순 섭취 비율 (주황-빨강 경계 위치)
    var netIntakeRatio: Double {
        guard tdee > 0 else { return 0 }
        return Double(netIntake) / Double(tdee)
    }

    /// 목표 칼로리 위치 비율
    var targetRatio: Double {
        guard tdee > 0 else { return 0 }
        let target = dailyCalorieTarget > 0 ? dailyCalorieTarget : tdee
        return Double(target) / Double(tdee)
    }

    /// 실제 사용할 목표 칼로리
    var effectiveTarget: Int {
        dailyCalorieTarget > 0 ? dailyCalorieTarget : tdee
    }

    /// 목표 대비 남은 칼로리 (목표 - 섭취, 소모 합산 안 함)
    var remainingCalories: Int {
        effectiveTarget - intakeCalories
    }

    /// 섭취 칼로리가 목표의 ±10% 이내인지 여부
    var isIntakeNearTarget: Bool {
        let target = Double(effectiveTarget)
        guard target > 0 else { return false }
        let ratio = Double(intakeCalories) / target
        return ratio >= 0.9 && ratio <= 1.1
    }

    /// 날짜 포맷팅
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }

    /// 인사말 메시지
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 0..<6:
            return "좋은 밤입니다"
        case 6..<12:
            return "좋은 아침입니다"
        case 12..<18:
            return "좋은 오후입니다"
        case 18..<21:
            return "좋은 저녁입니다"
        default:
            return "좋은 밤입니다"
        }
    }

    // MARK: - Initialization

    init(
        userId: UUID,
        sleepRepository: SleepRepositoryProtocol,
        dietCommentRepository: DietCommentRepository,
        bodyRepository: BodyRepositoryProtocol,
        foodRecordRepository: FoodRecordRepositoryProtocol,
        exerciseRepository: ExerciseRecordRepository,
        goalRepository: GoalRepositoryProtocol,
        userRepository: UserRepository,
        dailyLogRepository: DailyLogRepository,
        geminiService: GeminiServiceProtocol
    ) {
        self.userId = userId
        self.sleepRepository = sleepRepository
        self.dietCommentRepository = dietCommentRepository
        self.bodyRepository = bodyRepository
        self.foodRecordRepository = foodRecordRepository
        self.exerciseRepository = exerciseRepository
        self.goalRepository = goalRepository
        self.userRepository = userRepository
        self.dailyLogRepository = dailyLogRepository
        self.geminiService = geminiService
    }

    deinit {
        coachingTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// 데이터 로드
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // 성별 먼저 로드 (체성분 그래프 Y축 범위에 필요)
        loadUserGender()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCalories() }
            group.addTask { await self.loadWeekData() }
            group.addTask { await self.loadBodyChartData() }
        }

        // 칼로리/TDEE 로드 후 코칭 생성 (tdee 값이 필요하므로 순차 실행)
        await loadAICoaching()
    }

    /// 사용자 성별 로드
    private func loadUserGender() {
        do {
            if let user = try userRepository.fetchCurrentUser() {
                userGender = Gender(rawValue: user.gender) ?? .male
            }
        } catch {
            print("❌ 성별 로드 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// 오늘의 칼로리 로드
    private func loadCalories() async {
        do {
            let today = Date()

            // 섭취 칼로리: 오늘 기록된 FoodRecord의 총 칼로리
            let foodRecords = try await foodRecordRepository.findByDate(today, userId: userId)
            intakeCalories = foodRecords.reduce(0) { sum, record in
                sum + Int(record.calculatedCalories)
            }

            // 소모 칼로리: 오늘 기록된 운동의 총 칼로리
            let exerciseRecords = try await exerciseRepository.fetchByDate(today, userId: userId)
            burnCalories = exerciseRecords.reduce(0) { sum, record in
                sum + Int(record.caloriesBurned)
            }

            // HealthKit 활동 칼로리: DailyLog에서 조회
            if let dailyLog = try await dailyLogRepository.fetch(for: today, userId: userId) {
                activeCaloriesOut = Int(dailyLog.activeCaloriesOut)
            }

            // TDEE: User의 currentTDEE (없으면 기본값 2000 유지)
            if let user = try userRepository.fetchCurrentUser(),
               let currentTDEE = user.currentTDEE?.intValue,
               currentTDEE > 0 {
                tdee = currentTDEE
            }

            // 목표 칼로리: 활성 Goal의 dailyCalorieTarget
            if let activeGoal = try await goalRepository.fetchActiveGoal(),
               activeGoal.dailyCalorieTarget > 0 {
                dailyCalorieTarget = Int(activeGoal.dailyCalorieTarget)
            }
        } catch {
            print("❌ 칼로리 로드 실패: \(error.localizedDescription)")
        }
    }

    /// 주간 데이터 로드
    private func loadWeekData() async {
        let calendar = Calendar.current
        let today = Date()

        // 이번 주 일요일 찾기
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return
        }

        var dayScores: [DayScore] = []

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                continue
            }

            // 미래 날짜는 데이터 없음
            if date > today {
                dayScores.append(DayScore(date: date, sleepStatus: nil, dietScore: nil))
                continue
            }

            // 수면 상태 조회
            var sleepStatus: SleepStatus? = nil
            do {
                if let sleepRecord = try await sleepRepository.fetch(for: date) {
                    sleepStatus = SleepStatus(rawValue: Int16(sleepRecord.status))
                }
            } catch {
                // 에러 무시
            }

            // 식단 점수 조회 (캐시된 코멘트에서)
            var dietScore: DietScore? = nil
            do {
                // 일일 전체 코멘트 조회 시도
                if let cachedComment = try await dietCommentRepository.getCachedComment(
                    for: date,
                    userId: userId,
                    mealType: nil
                ) {
                    dietScore = DietScore.from(score: cachedComment.score)
                }
            } catch {
                // 에러 무시
            }

            dayScores.append(DayScore(date: date, sleepStatus: sleepStatus, dietScore: dietScore))
        }

        weekData = dayScores
    }

    /// 체성분 그래프 데이터 로드 (30일)
    private func loadBodyChartData() async {
        do {
            let calendar = Calendar.current
            let today = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -29, to: today) else {
                return
            }

            let entries = try await bodyRepository.fetch(from: startDate, to: today)

            bodyChartData = entries.map { entry -> BodyChartData in
                let fatValue = NSDecimalNumber(decimal: entry.bodyFatPercent).doubleValue
                return BodyChartData(
                    date: entry.date,
                    weight: NSDecimalNumber(decimal: entry.weight).doubleValue,
                    bodyFat: fatValue > 0 ? fatValue : nil
                )
            }.sorted { $0.date < $1.date }
        } catch {
            print("❌ 체성분 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    /// AI 코칭 로드 (스케줄 기반)
    ///
    /// 규칙:
    /// - 8시 이전: 호출하지 않음
    /// - 8시~22시: 홈 진입 시 현재 시각의 정각 기준으로 1회 호출
    /// - 같은 hour에 이미 생성했으면 캐시 사용
    /// - 다음 정각에 자동 갱신 타이머 설정
    private func loadAICoaching() async {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // 8시 이전 또는 23시 이후: 호출하지 않음
        guard currentHour >= 8 && currentHour <= 22 else {
            return
        }

        // 같은 hour에 이미 생성했으면 스킵
        if lastCoachingHour == currentHour && aiComment != nil {
            scheduleNextCoachingTimer()
            return
        }

        await generateCoaching(hour: currentHour)
        scheduleNextCoachingTimer()
    }

    /// 종합 데이터를 수집하여 AI 코칭 생성
    private func generateCoaching(hour: Int) async {
        do {
            let today = Date()

            // 수면 데이터
            var sleepDuration: Int32?
            var sleepStatus: SleepStatus?
            if let sleepRecord = try? await sleepRepository.fetch(for: today) {
                sleepDuration = sleepRecord.duration
                sleepStatus = SleepStatus(rawValue: Int16(sleepRecord.status))
            }

            // 식단 데이터
            let foodRecords = (try? await foodRecordRepository.findByDate(today, userId: userId)) ?? []
            let totalCalories = foodRecords.reduce(0) { $0 + Int($1.calculatedCalories) }
            let totalCarbs = foodRecords.reduce(0.0) { $0 + ($1.calculatedCarbs?.doubleValue ?? 0) }
            let totalProtein = foodRecords.reduce(0.0) { $0 + ($1.calculatedProtein?.doubleValue ?? 0) }
            let totalFat = foodRecords.reduce(0.0) { $0 + ($1.calculatedFat?.doubleValue ?? 0) }
            let mealTypes = Set(foodRecords.map { $0.mealType })

            // 운동 데이터
            let exerciseRecords = (try? await exerciseRepository.fetchByDate(today, userId: userId)) ?? []
            let exerciseCal = exerciseRecords.reduce(0) { $0 + Int($1.caloriesBurned) }
            let exerciseNames = exerciseRecords.compactMap { ExerciseType(rawValue: $0.exerciseType)?.displayName }

            // 목표 정보
            var goalType: GoalType = .maintain
            var targetCalories = tdee
            if let activeGoal = try? await goalRepository.fetchActiveGoal() {
                goalType = GoalType(rawValue: activeGoal.goalType) ?? .maintain
                if activeGoal.dailyCalorieTarget > 0 {
                    targetCalories = Int(activeGoal.dailyCalorieTarget)
                }
            }

            // 체성분 트렌드 (최근 30일)
            var currentWeight: Double?
            var weightChange30d: Double?
            var currentBodyFat: Double?
            var bodyFatChange30d: Double?
            var recentBodyEntries: [BodyDataPoint] = []

            let calendar = Calendar.current
            if let startDate30 = calendar.date(byAdding: .day, value: -29, to: today) {
                let entries = (try? await bodyRepository.fetch(from: startDate30, to: today)) ?? []
                let sorted = entries.sorted { $0.date < $1.date }
                if let latest = sorted.last {
                    currentWeight = NSDecimalNumber(decimal: latest.weight).doubleValue
                    let latestFat = NSDecimalNumber(decimal: latest.bodyFatPercent).doubleValue
                    if latestFat > 0 { currentBodyFat = latestFat }

                    if let oldest = sorted.first, sorted.count >= 2 {
                        let oldWeight = NSDecimalNumber(decimal: oldest.weight).doubleValue
                        weightChange30d = (currentWeight ?? 0) - oldWeight

                        let oldFat = NSDecimalNumber(decimal: oldest.bodyFatPercent).doubleValue
                        if oldFat > 0 && latestFat > 0 {
                            bodyFatChange30d = latestFat - oldFat
                        }
                    }
                }

                // 최근 7일 개별 데이터
                if let startDate7 = calendar.date(byAdding: .day, value: -6, to: today) {
                    recentBodyEntries = sorted
                        .filter { $0.date >= startDate7 }
                        .suffix(7)
                        .map { entry in
                            let fat = NSDecimalNumber(decimal: entry.bodyFatPercent).doubleValue
                            return BodyDataPoint(
                                date: entry.date,
                                weight: NSDecimalNumber(decimal: entry.weight).doubleValue,
                                bodyFat: fat > 0 ? fat : nil
                            )
                        }
                }
            }

            let context = HomeCoachingContext(
                currentHour: hour,
                goalType: goalType,
                tdee: tdee,
                targetCalories: targetCalories,
                sleepDurationMinutes: sleepDuration,
                sleepStatus: sleepStatus,
                intakeCalories: totalCalories,
                totalCarbs: totalCarbs,
                totalProtein: totalProtein,
                totalFat: totalFat,
                mealCount: mealTypes.count,
                exerciseCalories: exerciseCal,
                exerciseCount: exerciseRecords.count,
                exerciseNames: exerciseNames,
                currentWeight: currentWeight,
                weightChange30d: weightChange30d,
                currentBodyFat: currentBodyFat,
                bodyFatChange30d: bodyFatChange30d,
                recentBodyEntries: recentBodyEntries
            )

            let coaching = try await geminiService.generateHomeCoaching(context: context)
            aiComment = coaching
            lastCoachingHour = hour
        } catch {
            print("❌ AI 코칭 생성 실패: \(error.localizedDescription)")
            // 실패해도 기존 코멘트 유지
        }
    }

    /// 다음 정각에 코칭을 갱신하는 타이머 설정
    private func scheduleNextCoachingTimer() {
        coachingTimer?.invalidate()

        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)

        // 22시 이후면 더 이상 타이머 불필요
        guard currentHour < 22 else { return }

        // 다음 정각 계산
        guard let nextHour = calendar.date(bySettingHour: currentHour + 1, minute: 0, second: 0, of: now),
              nextHour > now else { return }

        let interval = nextHour.timeIntervalSince(now)

        coachingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let newHour = Calendar.current.component(.hour, from: Date())
                guard newHour >= 8 && newHour <= 22 else { return }
                await self.generateCoaching(hour: newHour)
                self.scheduleNextCoachingTimer()
            }
        }
    }
}

// MARK: - DIContainer Extension

extension DIContainer {
    /// HomeViewModel 팩토리 메서드
    @MainActor
    func makeHomeViewModel(userId: UUID) -> HomeViewModel {
        HomeViewModel(
            userId: userId,
            sleepRepository: sleepRepository,
            dietCommentRepository: dietCommentRepository,
            bodyRepository: bodyRepository,
            foodRecordRepository: foodRecordRepository,
            exerciseRepository: exerciseRepository,
            goalRepository: goalRepository,
            userRepository: userRepository,
            dailyLogRepository: dailyLogRepository,
            geminiService: geminiService
        )
    }
}

// MARK: - Preview

#Preview("홈 화면") {
    // Preview용 - 실제 앱에서는 DIContainer를 통해 생성
    Text("HomeView Preview")
        .font(.title)
}

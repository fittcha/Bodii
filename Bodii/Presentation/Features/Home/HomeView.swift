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
            Text("오늘의 칼로리")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 0) {
                // 섭취 칼로리
                calorieCard(
                    title: "섭취",
                    value: viewModel.intakeCalories,
                    unit: "kcal",
                    icon: "fork.knife",
                    color: .orange
                )

                // 구분선
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.vertical, 16)

                // 소모 칼로리
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

            // 칼로리 밸런스
            calorieBalanceView
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

    /// 칼로리 밸런스 뷰
    private var calorieBalanceView: some View {
        let balance = viewModel.calorieBalance

        return HStack {
            Image(systemName: balance >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(balance >= 0 ? .red : .green)

            Text(balance >= 0 ? "+\(balance) kcal" : "\(balance) kcal")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(balance >= 0 ? .red : .green)

            Spacer()

            Text(balance >= 0 ? "칼로리 초과" : "칼로리 부족")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill((balance >= 0 ? Color.red : Color.green).opacity(0.1))
        )
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
                    data: viewModel.bodyChartData
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 220)
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
    @Published var weekData: [DayScore] = []
    @Published var bodyChartData: [BodyChartData] = []
    @Published var aiComment: String?
    @Published var isLoading: Bool = false

    // MARK: - Private Properties

    private let userId: UUID
    private let sleepRepository: SleepRepositoryProtocol
    private let dietCommentRepository: DietCommentRepository
    private let bodyRepository: BodyRepositoryProtocol
    private let foodRecordRepository: FoodRecordRepositoryProtocol
    private let exerciseRepository: ExerciseRecordRepository

    // MARK: - Computed Properties

    /// 칼로리 밸런스 (섭취 - 소모)
    var calorieBalance: Int {
        intakeCalories - burnCalories
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
        exerciseRepository: ExerciseRecordRepository
    ) {
        self.userId = userId
        self.sleepRepository = sleepRepository
        self.dietCommentRepository = dietCommentRepository
        self.bodyRepository = bodyRepository
        self.foodRecordRepository = foodRecordRepository
        self.exerciseRepository = exerciseRepository
    }

    // MARK: - Public Methods

    /// 데이터 로드
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCalories() }
            group.addTask { await self.loadWeekData() }
            group.addTask { await self.loadBodyChartData() }
            group.addTask { await self.loadAIComment() }
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

    /// 체성분 그래프 데이터 로드
    private func loadBodyChartData() async {
        do {
            let calendar = Calendar.current
            let today = Date()
            guard let startDate = calendar.date(byAdding: .day, value: -6, to: today) else {
                return
            }

            let entries = try await bodyRepository.fetch(from: startDate, to: today)

            bodyChartData = entries.map { entry -> BodyChartData in
                return BodyChartData(
                    date: entry.date,
                    weight: NSDecimalNumber(decimal: entry.weight).doubleValue,
                    bodyFat: NSDecimalNumber(decimal: entry.bodyFatPercent).doubleValue
                )
            }.sorted { $0.date < $1.date }
        } catch {
            print("❌ 체성분 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    /// AI 한줄평 로드
    private func loadAIComment() async {
        do {
            let today = Date()

            // 오늘의 일일 전체 식단 코멘트 조회 (캐시에서)
            if let cachedComment = try await dietCommentRepository.getCachedComment(
                for: today,
                userId: userId,
                mealType: nil
            ) {
                aiComment = cachedComment.summary
            } else {
                aiComment = nil
            }
        } catch {
            print("❌ AI 코멘트 로드 실패: \(error.localizedDescription)")
            aiComment = nil
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
            exerciseRepository: exerciseRepository
        )
    }
}

// MARK: - Preview

#Preview("홈 화면") {
    // Preview용 - 실제 앱에서는 DIContainer를 통해 생성
    Text("HomeView Preview")
        .font(.title)
}

//
//  WeeklyReportViewModel.swift
//  Bodii
//
//  목표 기간 내 주간 리포트 통계를 관리하는 ViewModel

import Foundation

/// 주간 리포트 ViewModel
///
/// 최근 7일 동안의 체중 변화, 식단 준수, 운동 빈도를 계산합니다.
@MainActor
final class WeeklyReportViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 주간 체중 변화 (kg, 양수=증가, 음수=감소)
    @Published var weeklyWeightChange: Decimal?

    /// 칼로리 목표 달성일 (최근 7일)
    @Published var calorieComplianceDays: Int = 0

    /// 운동한 일수 (최근 7일)
    @Published var exerciseDays: Int = 0

    /// 총 주 일수 (최대 7)
    @Published var totalWeekDays: Int = 7

    /// 로딩 상태
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let exerciseRepository: ExerciseRecordRepository
    private let dailyLogRepository: DailyLogRepository
    private let bodyRepository: BodyRepositoryProtocol

    // MARK: - Initialization

    init(
        exerciseRepository: ExerciseRecordRepository,
        dailyLogRepository: DailyLogRepository,
        bodyRepository: BodyRepositoryProtocol
    ) {
        self.exerciseRepository = exerciseRepository
        self.dailyLogRepository = dailyLogRepository
        self.bodyRepository = bodyRepository
    }

    // MARK: - Computed Properties

    /// 체중 변화 텍스트 (예: "-0.3 kg", "+0.5 kg")
    var weightChangeText: String {
        guard let change = weeklyWeightChange else { return "-" }
        let number = NSDecimalNumber(decimal: change)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        return "\(formatter.string(from: number) ?? "\(change)") kg"
    }

    /// 체중 변화 방향 아이콘
    var weightChangeIcon: String {
        guard let change = weeklyWeightChange else { return "minus" }
        if change > 0 { return "arrow.up" }
        if change < 0 { return "arrow.down" }
        return "minus"
    }

    // MARK: - Public Methods

    /// 최근 7일간 주간 데이터를 로드합니다.
    func loadWeeklyData(userId: UUID, dailyCalorieTarget: Int32) async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        // 실제 경과 일수 (시작일이 목표 시작일 이후일 수 있음)
        totalWeekDays = 7

        // 병렬로 데이터 로드
        async let exerciseTask: () = loadExerciseDays(userId: userId, start: weekAgo, end: today)
        async let dietTask: () = loadCalorieCompliance(userId: userId, start: weekAgo, end: today, target: dailyCalorieTarget)
        async let bodyTask: () = loadWeightChange(start: weekAgo, end: today)

        _ = await (exerciseTask, dietTask, bodyTask)
    }

    // MARK: - Private Methods

    private func loadExerciseDays(userId: UUID, start: Date, end: Date) async {
        do {
            let records = try await exerciseRepository.fetchByDateRange(
                startDate: start,
                endDate: end,
                userId: userId
            )
            let calendar = Calendar.current
            var uniqueDays: Set<Date> = []
            for record in records {
                if let date = record.date {
                    uniqueDays.insert(calendar.startOfDay(for: date))
                }
            }
            exerciseDays = uniqueDays.count
        } catch {
            print("❌ 주간 운동 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    private func loadCalorieCompliance(userId: UUID, start: Date, end: Date, target: Int32) async {
        guard target > 0 else { return }

        do {
            let dailyLogs = try await dailyLogRepository.findByDateRange(
                startDate: start,
                endDate: end,
                userId: userId
            )

            let targetDouble = Double(target)
            let lowerBound = targetDouble * 0.9
            let upperBound = targetDouble * 1.1

            var metCount = 0
            for log in dailyLogs {
                let intake = Double(log.totalCaloriesIn)
                if intake > 0 && intake >= lowerBound && intake <= upperBound {
                    metCount += 1
                }
            }
            calorieComplianceDays = metCount
        } catch {
            print("❌ 주간 식단 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    private func loadWeightChange(start: Date, end: Date) async {
        do {
            let entries = try await bodyRepository.fetch(from: start, to: end)
            guard entries.count >= 2 else {
                weeklyWeightChange = nil
                return
            }

            // 가장 오래된 기록과 가장 최근 기록의 체중 차이
            let sortedByDate = entries.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            if let firstWeight = sortedByDate.first?.weight,
               let lastWeight = sortedByDate.last?.weight {
                weeklyWeightChange = lastWeight - firstWeight
            }
        } catch {
            print("❌ 주간 체중 데이터 로드 실패: \(error.localizedDescription)")
        }
    }
}

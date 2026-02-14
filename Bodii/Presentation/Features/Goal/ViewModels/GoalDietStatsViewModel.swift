//
//  GoalDietStatsViewModel.swift
//  Bodii
//
//  목표 기간 내 식단 통계를 관리하는 ViewModel

import Foundation

/// 목표 기간 내 식단 통계 ViewModel
///
/// 칼로리 목표 달성 일수를 계산합니다.
@MainActor
final class GoalDietStatsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 목표 칼로리 달성 일수
    @Published var targetMetDays: Int = 0

    /// 목표 시작일부터 오늘까지 경과 일수
    @Published var totalDaysElapsed: Int = 0

    /// 로딩 상태
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let dailyLogRepository: DailyLogRepository

    // MARK: - Initialization

    init(dailyLogRepository: DailyLogRepository) {
        self.dailyLogRepository = dailyLogRepository
    }

    // MARK: - Computed Properties

    /// 달성률 퍼센트 (0~100)
    var compliancePercent: Int {
        guard totalDaysElapsed > 0 else { return 0 }
        return min(Int(Double(targetMetDays) / Double(totalDaysElapsed) * 100), 100)
    }

    // MARK: - Public Methods

    /// 목표 기간 내 식단 통계를 로드합니다.
    ///
    /// 칼로리 목표 ±10% 이내인 날을 달성일로 카운트합니다.
    func loadStats(userId: UUID, periodStart: Date, periodEnd: Date, dailyCalorieTarget: Int32) async {
        guard dailyCalorieTarget > 0 else { return }

        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let effectiveEnd = min(today, calendar.startOfDay(for: periodEnd))
        let start = calendar.startOfDay(for: periodStart)

        // 경과 일수 계산
        totalDaysElapsed = max(1, (calendar.dateComponents([.day], from: start, to: effectiveEnd).day ?? 0) + 1)

        do {
            let dailyLogs = try await dailyLogRepository.findByDateRange(
                startDate: periodStart,
                endDate: effectiveEnd,
                userId: userId
            )

            let target = Double(dailyCalorieTarget)
            let lowerBound = target * 0.9
            let upperBound = target * 1.1

            var metCount = 0
            for log in dailyLogs {
                let intake = Double(log.totalCaloriesIn)
                // 섭취량이 0보다 크고, 목표 ±10% 이내면 달성
                if intake > 0 && intake >= lowerBound && intake <= upperBound {
                    metCount += 1
                }
            }

            targetMetDays = metCount

        } catch {
            print("❌ 식단 통계 로드 실패: \(error.localizedDescription)")
        }
    }
}

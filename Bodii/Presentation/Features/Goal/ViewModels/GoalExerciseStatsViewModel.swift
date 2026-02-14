//
//  GoalExerciseStatsViewModel.swift
//  Bodii
//
//  목표 기간 내 운동 통계를 관리하는 ViewModel

import Foundation

/// 목표 기간 내 운동 통계 ViewModel
///
/// 운동 종류별 횟수와 운동일 퍼센트를 계산합니다.
@MainActor
final class GoalExerciseStatsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 운동 종류별 횟수 (횟수 내림차순)
    @Published var exerciseTypeCounts: [(type: ExerciseType, count: Int)] = []

    /// 운동한 고유 일수
    @Published var exerciseDays: Int = 0

    /// 목표 시작일부터 오늘까지 경과 일수
    @Published var totalDaysElapsed: Int = 0

    /// 로딩 상태
    @Published var isLoading: Bool = false

    // MARK: - Dependencies

    private let exerciseRepository: ExerciseRecordRepository

    // MARK: - Initialization

    init(exerciseRepository: ExerciseRecordRepository) {
        self.exerciseRepository = exerciseRepository
    }

    // MARK: - Computed Properties

    /// 운동일 퍼센트 (0~100)
    var exerciseDaysPercent: Int {
        guard totalDaysElapsed > 0 else { return 0 }
        return min(Int(Double(exerciseDays) / Double(totalDaysElapsed) * 100), 100)
    }

    /// 운동 종류 요약 텍스트 (상위 3개 + "외 N종류")
    var exerciseTypeSummary: String {
        guard !exerciseTypeCounts.isEmpty else { return "운동 기록 없음" }

        let top3 = exerciseTypeCounts.prefix(3)
        var parts = top3.map { "\($0.type.displayName) \($0.count)회" }

        let remaining = exerciseTypeCounts.count - 3
        if remaining > 0 {
            parts.append("외 \(remaining)종류")
        }

        return parts.joined(separator: " · ")
    }

    // MARK: - Public Methods

    /// 목표 기간 내 운동 통계를 로드합니다.
    func loadStats(userId: UUID, periodStart: Date, periodEnd: Date) async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let effectiveEnd = min(today, calendar.startOfDay(for: periodEnd))
        let start = calendar.startOfDay(for: periodStart)

        // 경과 일수 계산
        totalDaysElapsed = max(1, (calendar.dateComponents([.day], from: start, to: effectiveEnd).day ?? 0) + 1)

        do {
            let records = try await exerciseRepository.fetchByDateRange(
                startDate: periodStart,
                endDate: effectiveEnd,
                userId: userId
            )

            // 운동 종류별 카운트
            var typeCounts: [ExerciseType: Int] = [:]
            var uniqueDays: Set<Date> = []

            for record in records {
                let exerciseType = ExerciseType(rawValue: record.exerciseType) ?? .other
                typeCounts[exerciseType, default: 0] += 1

                if let date = record.date {
                    uniqueDays.insert(calendar.startOfDay(for: date))
                }
            }

            exerciseTypeCounts = typeCounts
                .map { (type: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }

            exerciseDays = uniqueDays.count

        } catch {
            print("❌ 운동 통계 로드 실패: \(error.localizedDescription)")
        }
    }
}

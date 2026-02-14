//
//  GoalModeService.swift
//  Bodii
//

import Foundation
import CoreData

/// 목표 모드 핵심 로직 서비스
///
/// D-Day 계산, 긴박도 판단, 기간 진행률, 스트릭 계산 등
/// 목표 모드에 필요한 순수 연산을 제공합니다.
enum GoalModeService {

    // MARK: - 목표 모드 상태 확인

    /// 목표 모드가 현재 활성 상태인지 확인
    ///
    /// 다음 조건이 모두 충족되어야 활성:
    /// 1. 활성 목표(isActive) 존재
    /// 2. isGoalModeActive == true
    /// 3. 목표값 1개 이상 설정
    /// 4. goalPeriodEnd가 미래
    static func isGoalModeActive(goal: Goal?) -> Bool {
        guard let goal = goal else { return false }
        guard goal.isActive else { return false }
        guard goal.isGoalModeActive else { return false }
        guard hasTargetValues(goal: goal) else { return false }
        guard let periodEnd = goal.goalPeriodEnd else { return false }
        return periodEnd > Date()
    }

    /// 목표 모드 활성화 가능 여부 확인
    ///
    /// 토글을 켤 수 있는 조건:
    /// 1. 활성 목표 존재
    /// 2. 목표값 1개 이상 설정
    /// 3. 목표 기간 설정됨 (시작, 종료)
    /// 4. 종료일이 미래
    static func canActivateGoalMode(goal: Goal?) -> Bool {
        guard let goal = goal else { return false }
        guard goal.isActive else { return false }
        guard hasTargetValues(goal: goal) else { return false }
        guard let periodEnd = goal.goalPeriodEnd,
              goal.goalPeriodStart != nil else { return false }
        return periodEnd > Date()
    }

    /// 목표값이 1개 이상 설정되어 있는지 확인
    static func hasTargetValues(goal: Goal) -> Bool {
        return goal.targetWeight != nil
            || goal.targetBodyFatPct != nil
            || goal.targetMuscleMass != nil
    }

    // MARK: - D-Day 계산

    /// D-Day 계산
    ///
    /// - Returns: 남은 일수 (양수 = 남은 일, 0 = D-Day, 음수 = 초과)
    static func calculateDDay(from goalPeriodEnd: Date?) -> Int? {
        guard let endDate = goalPeriodEnd else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: today, to: end)
        return components.day
    }

    /// D-Day 텍스트 포맷
    ///
    /// - Returns: "D-45", "D-Day", "D+3" 형식
    static func formatDDay(_ dDay: Int) -> String {
        if dDay > 0 {
            return "D-\(dDay)"
        } else if dDay == 0 {
            return "D-Day"
        } else {
            return "D+\(abs(dDay))"
        }
    }

    // MARK: - 기간 진행률

    /// 목표 기간 진행률 계산 (0.0 ~ 1.0)
    static func periodProgress(start: Date, end: Date) -> Double {
        let now = Date()
        let totalInterval = end.timeIntervalSince(start)
        guard totalInterval > 0 else { return 1.0 }
        let elapsedInterval = now.timeIntervalSince(start)
        let progress = elapsedInterval / totalInterval
        return min(max(progress, 0.0), 1.0)
    }

    // MARK: - 긴박도 레벨

    /// 긴박도 레벨 결정
    ///
    /// 남은 시간 비율 기준:
    /// - relaxed: 60%+ 남음
    /// - steady: 30-60% 남음
    /// - intense: 10-30% 남음
    /// - critical: 10% 미만
    static func urgencyLevel(periodProgress: Double) -> GoalUrgency {
        let remaining = 1.0 - periodProgress
        if remaining > 0.6 {
            return .relaxed
        } else if remaining > 0.3 {
            return .steady
        } else if remaining > 0.1 {
            return .intense
        } else {
            return .critical
        }
    }

    /// Goal 엔티티에서 직접 긴박도 계산
    static func urgencyLevel(for goal: Goal) -> GoalUrgency {
        guard let start = goal.goalPeriodStart,
              let end = goal.goalPeriodEnd else {
            return .relaxed
        }
        let progress = periodProgress(start: start, end: end)
        return urgencyLevel(periodProgress: progress)
    }

    // MARK: - 스트릭 계산

    /// 연속 목표 달성일 계산
    ///
    /// 목표 칼로리 ±10% 이내로 섭취한 연속일 수를 계산합니다.
    /// DailyLog 데이터에서 오늘부터 역순으로 확인합니다.
    ///
    /// - Parameters:
    ///   - dailyLogs: 날짜 내림차순 정렬된 DailyLog 배열
    ///   - targetCalories: 목표 칼로리 (nil이면 스트릭 0)
    /// - Returns: 연속 달성일 수
    static func calculateStreak(dailyLogs: [DailyLog], targetCalories: Int32?) -> Int {
        guard let target = targetCalories, target > 0 else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        // 오늘은 아직 진행 중이므로 어제부터 계산
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
            return 0
        }
        expectedDate = yesterday

        let sortedLogs = dailyLogs.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }

        for log in sortedLogs {
            guard let logDate = log.date else { continue }
            let logDay = calendar.startOfDay(for: logDate)

            // 날짜 연속성 확인
            guard calendar.isDate(logDay, inSameDayAs: expectedDate) else {
                break
            }

            // 목표 칼로리 ±10% 이내인지 확인
            let intake = log.totalCaloriesIn
            let lowerBound = Double(target) * 0.9
            let upperBound = Double(target) * 1.1

            if Double(intake) >= lowerBound && Double(intake) <= upperBound {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: expectedDate) else {
                    break
                }
                expectedDate = prevDay
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - 기간 제약 검증

    /// 목표 기간이 유효한 범위인지 확인
    ///
    /// - 최소: 7일 (1주)
    /// - 최대: 182일 (약 6개월)
    static func validatePeriod(start: Date, end: Date) -> PeriodValidationResult {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        guard let days = calendar.dateComponents([.day], from: startDay, to: endDay).day else {
            return .invalid(message: "기간 계산 오류")
        }

        if days < 7 {
            return .tooShort(minimumDays: 7)
        } else if days > 182 {
            return .tooLong(maximumDays: 182)
        } else {
            return .valid(days: days)
        }
    }

    /// 목표 요약 텍스트 생성
    static func goalSummaryText(goal: Goal) -> String {
        let goalType = GoalType(rawValue: goal.goalType) ?? .maintain
        var targets: [String] = []

        if let weight = goal.targetWeight?.decimalValue {
            targets.append("체중 \(weight)kg")
        }
        if let bodyFat = goal.targetBodyFatPct?.decimalValue {
            targets.append("체지방 \(bodyFat)%")
        }
        if let muscle = goal.targetMuscleMass?.decimalValue {
            targets.append("근육량 \(muscle)kg")
        }

        let targetText = targets.isEmpty ? "" : " \(targets.joined(separator: ", "))"
        return "\(goalType.displayName)\(targetText)"
    }

    /// 기간 텍스트 포맷
    static func periodText(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return "\(formatter.string(from: start)) ~ \(formatter.string(from: end))"
    }
}

// MARK: - Period Validation Result

enum PeriodValidationResult {
    case valid(days: Int)
    case tooShort(minimumDays: Int)
    case tooLong(maximumDays: Int)
    case invalid(message: String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .valid:
            return nil
        case .tooShort(let min):
            return "최소 \(min)일 이상 설정해주세요"
        case .tooLong(let max):
            return "최대 \(max)일(\(max / 30)개월)까지 설정 가능합니다"
        case .invalid(let msg):
            return msg
        }
    }
}

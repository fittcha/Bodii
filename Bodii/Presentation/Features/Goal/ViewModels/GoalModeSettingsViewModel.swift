//
//  GoalModeSettingsViewModel.swift
//  Bodii
//

import Foundation
import Combine

/// 설정 화면의 목표 모드 관리 ViewModel
///
/// 목표 모드 토글, D-Day 표시, 목표 요약 텍스트 등
/// 설정 화면에서 목표 모드와 관련된 상태를 관리합니다.
@MainActor
final class GoalModeSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 현재 활성 목표
    @Published private(set) var activeGoal: Goal?

    /// 목표 모드 토글 상태
    @Published var isGoalModeEnabled: Bool = false

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 목표 기간 만료 결과 표시 여부
    @Published var showCompletionResult: Bool = false

    /// 만료된 목표 (결과 표시용)
    @Published private(set) var expiredGoal: Goal?

    // MARK: - Dependencies

    private let goalRepository: GoalRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(goalRepository: GoalRepositoryProtocol) {
        self.goalRepository = goalRepository
    }

    // MARK: - Computed Properties

    /// 목표 모드 활성화 가능 여부
    var canEnableGoalMode: Bool {
        GoalModeService.canActivateGoalMode(goal: activeGoal)
    }

    /// 목표가 존재하는지
    var hasActiveGoal: Bool {
        activeGoal != nil && (activeGoal?.isActive ?? false)
    }

    /// 목표 모드 상태 메시지
    var goalModeStatusMessage: String {
        guard let goal = activeGoal, goal.isActive else {
            return "목표를 먼저 설정해주세요"
        }

        if !GoalModeService.hasTargetValues(goal: goal) {
            return "목표값을 설정해주세요"
        }

        if goal.goalPeriodStart == nil || goal.goalPeriodEnd == nil {
            return "목표 기간을 설정해주세요"
        }

        if let end = goal.goalPeriodEnd, end <= Date() {
            return "목표 기간이 만료되었습니다"
        }

        if isGoalModeEnabled {
            if let dDay = GoalModeService.calculateDDay(from: goal.goalPeriodEnd) {
                return GoalModeService.formatDDay(dDay)
            }
        }

        return ""
    }

    /// D-Day 텍스트 (목표 모드 활성 시)
    var dDayText: String? {
        guard isGoalModeEnabled,
              let goal = activeGoal else { return nil }
        guard let dDay = GoalModeService.calculateDDay(from: goal.goalPeriodEnd) else { return nil }
        return GoalModeService.formatDDay(dDay)
    }

    /// 목표 요약 텍스트
    var goalSummaryText: String? {
        guard let goal = activeGoal, goal.isActive else { return nil }
        return GoalModeService.goalSummaryText(goal: goal)
    }

    /// 목표 기간 텍스트
    var goalPeriodText: String? {
        guard let goal = activeGoal,
              let start = goal.goalPeriodStart,
              let end = goal.goalPeriodEnd else { return nil }
        return GoalModeService.periodText(start: start, end: end)
    }

    /// 현재 긴박도 레벨
    var urgencyLevel: GoalUrgency? {
        guard isGoalModeEnabled,
              let goal = activeGoal else { return nil }
        return GoalModeService.urgencyLevel(for: goal)
    }

    // MARK: - Public Methods

    /// 활성 목표 데이터를 로드합니다.
    ///
    /// 목표 기간이 만료된 경우 자동으로 목표 모드를 비활성화하고
    /// 결과 요약 팝업 표시를 트리거합니다.
    func loadActiveGoal() async {
        isLoading = true
        defer { isLoading = false }

        do {
            activeGoal = try await goalRepository.fetchActiveGoal()

            // 기간 만료 감지: goalModeActive이지만 기간이 지난 경우
            if let goal = activeGoal,
               goal.isGoalModeActive,
               let end = goal.goalPeriodEnd,
               end <= Date() {
                // 자동 OFF
                try? await goalRepository.setGoalModeActive(false)
                goal.isGoalModeActive = false
                isGoalModeEnabled = false
                expiredGoal = goal
                showCompletionResult = true
                return
            }

            isGoalModeEnabled = GoalModeService.isGoalModeActive(goal: activeGoal)
        } catch {
            errorMessage = "목표 정보를 불러올 수 없습니다."
        }
    }

    /// 목표 모드를 토글합니다.
    func toggleGoalMode(_ enabled: Bool) async {
        guard canEnableGoalMode || !enabled else {
            errorMessage = goalModeStatusMessage
            isGoalModeEnabled = false
            return
        }

        do {
            try await goalRepository.setGoalModeActive(enabled)
            isGoalModeEnabled = enabled

            // 로컬 상태 업데이트
            if let goal = activeGoal {
                goal.isGoalModeActive = enabled
            }
        } catch {
            errorMessage = "목표 모드 변경에 실패했습니다."
            // 롤백
            isGoalModeEnabled = !enabled
        }
    }

    /// 에러를 지웁니다.
    func clearError() {
        errorMessage = nil
    }

    /// 만료 결과 화면을 닫습니다.
    func dismissCompletionResult() {
        showCompletionResult = false
        expiredGoal = nil
    }
}

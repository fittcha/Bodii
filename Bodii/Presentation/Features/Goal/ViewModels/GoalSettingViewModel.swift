//
//  GoalSettingViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation
import Combine

// MARK: - GoalSettingViewModel

/// 목표 설정 화면의 ViewModel
///
/// 목표 유형, 목표값, 목표 달성일을 입력받아
/// 주간 변화율을 자동 계산하고 목표를 저장합니다.
@MainActor
final class GoalSettingViewModel: ObservableObject {

    // MARK: - Form State Properties

    /// 선택된 목표 유형
    @Published var goalType: GoalType = .lose

    // MARK: - Target Enable Toggles

    /// 체중 목표 활성화 여부
    @Published var isWeightEnabled: Bool = false

    /// 체지방률 목표 활성화 여부
    @Published var isBodyFatEnabled: Bool = false

    /// 근육량 목표 활성화 여부
    @Published var isMuscleEnabled: Bool = false

    // MARK: - Target Value Inputs

    /// 목표 체중 입력값 (kg)
    @Published var targetWeightInput: String = ""

    /// 목표 체지방률 입력값 (%)
    @Published var targetBodyFatInput: String = ""

    /// 목표 근육량 입력값 (kg)
    @Published var targetMuscleInput: String = ""

    // MARK: - Target Date

    /// 목표 달성일 (기본값: 3개월 후)
    @Published var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    // MARK: - Optional Fields

    /// 일일 칼로리 목표 입력값 (kcal)
    @Published var dailyCalorieTargetInput: String = ""

    // MARK: - UI State Properties

    /// 저장 중 로딩 상태
    @Published var isSaving: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 저장 성공 여부
    @Published var isSaveSuccess: Bool = false

    /// 필드별 검증 에러
    @Published var validationErrors: GoalValidationErrors = GoalValidationErrors()

    /// 비현실적 변화율 경고 메시지 목록
    @Published var rateWarnings: [String] = []

    // MARK: - Private Dependencies

    /// 목표 설정 유스케이스
    private let setGoalUseCase: SetGoalUseCase

    /// 사용자 ID
    private let userId: UUID

    /// Combine 구독 저장소
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        setGoalUseCase: SetGoalUseCase,
        userId: UUID
    ) {
        self.setGoalUseCase = setGoalUseCase
        self.userId = userId
    }

    // MARK: - Computed Properties

    /// 최소 1개의 목표가 활성화되었는지
    var hasAtLeastOneTarget: Bool {
        isWeightEnabled || isBodyFatEnabled || isMuscleEnabled
    }

    /// 유지(maintain) 목표인지
    var isMaintainGoal: Bool {
        goalType == .maintain
    }

    /// 폼이 유효한지 여부
    var isFormValid: Bool {
        guard hasAtLeastOneTarget else { return false }

        // 활성화된 각 목표의 필수 입력값 확인
        if isWeightEnabled {
            guard !targetWeightInput.isEmpty,
                  parsedTargetWeight != nil else {
                return false
            }
        }

        if isBodyFatEnabled {
            guard !targetBodyFatInput.isEmpty,
                  parsedTargetBodyFat != nil else {
                return false
            }
        }

        if isMuscleEnabled {
            guard !targetMuscleInput.isEmpty,
                  parsedTargetMuscle != nil else {
                return false
            }
        }

        // 유지 목표가 아니면 targetDate 범위 검증
        if !isMaintainGoal {
            if GoalValidationService.validateTargetDateRange(targetDate) != nil {
                return false
            }
        }

        return true
    }

    /// 저장 가능 여부
    var canSave: Bool {
        isFormValid && !isSaving
    }

    // MARK: - Parsed Values

    var parsedTargetWeight: Decimal? {
        guard !targetWeightInput.isEmpty else { return nil }
        return Decimal(string: targetWeightInput)
    }

    var parsedTargetBodyFat: Decimal? {
        guard !targetBodyFatInput.isEmpty else { return nil }
        return Decimal(string: targetBodyFatInput)
    }

    var parsedTargetMuscle: Decimal? {
        guard !targetMuscleInput.isEmpty else { return nil }
        return Decimal(string: targetMuscleInput)
    }

    var parsedDailyCalorieTarget: Int32? {
        guard !dailyCalorieTargetInput.isEmpty else { return nil }
        return Int32(dailyCalorieTargetInput)
    }

    // MARK: - Calculated Weekly Rates (읽기 전용)

    /// targetDate까지의 주 수
    private var weeksToTarget: Decimal? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysBetween = calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
        guard daysBetween > 0 else { return nil }
        return Decimal(daysBetween) / Decimal(7)
    }

    /// 계산된 주간 체중 변화율 (kg/week)
    var calculatedWeeklyWeightRate: Decimal? {
        guard isWeightEnabled,
              let target = parsedTargetWeight,
              let current = getCurrentWeight(),
              let weeks = weeksToTarget,
              weeks > 0 else { return nil }
        return (target - current) / weeks
    }

    /// 계산된 주간 체지방률 변화율 (%/week)
    var calculatedWeeklyBodyFatRate: Decimal? {
        guard isBodyFatEnabled,
              let target = parsedTargetBodyFat,
              let current = getCurrentBodyFat(),
              let weeks = weeksToTarget,
              weeks > 0 else { return nil }
        return (target - current) / weeks
    }

    /// 계산된 주간 근육량 변화율 (kg/week)
    var calculatedWeeklyMuscleRate: Decimal? {
        guard isMuscleEnabled,
              let target = parsedTargetMuscle,
              let current = getCurrentMuscle(),
              let weeks = weeksToTarget,
              weeks > 0 else { return nil }
        return (target - current) / weeks
    }

    /// 달성일까지 남은 일수
    var daysToTarget: Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: today, to: targetDate).day
        return days
    }

    // MARK: - Date Range

    /// DatePicker 최소 날짜 (1주 후)
    var minimumTargetDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
    }

    /// DatePicker 최대 날짜 (104주 = 약 2년 후)
    var maximumTargetDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 104, to: Date()) ?? Date()
    }

    // MARK: - Public Methods

    /// 목표를 저장합니다.
    func save() async {
        guard isFormValid else {
            errorMessage = "입력값을 확인해주세요."
            return
        }

        isSaving = true
        errorMessage = nil
        validationErrors = GoalValidationErrors()
        defer { isSaving = false }

        do {
            _ = try await setGoalUseCase.execute(
                userId: userId,
                goalType: goalType,
                targetWeight: isWeightEnabled ? parsedTargetWeight : nil,
                targetBodyFatPct: isBodyFatEnabled ? parsedTargetBodyFat : nil,
                targetMuscleMass: isMuscleEnabled ? parsedTargetMuscle : nil,
                targetDate: isMaintainGoal ? nil : targetDate,
                dailyCalorieTarget: parsedDailyCalorieTarget
            )

            isSaveSuccess = true

        } catch let error as SetGoalError {
            errorMessage = error.localizedDescription

        } catch let error as GoalValidationError {
            errorMessage = error.localizedDescription

        } catch {
            errorMessage = "목표 저장 실패: \(error.localizedDescription)"
        }
    }

    /// 실시간 입력값 검증
    func validateInputs() {
        validationErrors = GoalValidationErrors()

        if !hasAtLeastOneTarget {
            validationErrors.general = "최소 1개 이상의 목표를 선택해주세요."
        }

        if isWeightEnabled {
            if targetWeightInput.isEmpty {
                validationErrors.targetWeight = "목표 체중을 입력해주세요."
            } else if parsedTargetWeight == nil {
                validationErrors.targetWeight = "올바른 숫자를 입력해주세요."
            }
        }

        if isBodyFatEnabled {
            if targetBodyFatInput.isEmpty {
                validationErrors.targetBodyFat = "목표 체지방률을 입력해주세요."
            } else if parsedTargetBodyFat == nil {
                validationErrors.targetBodyFat = "올바른 숫자를 입력해주세요."
            } else if let bodyFat = parsedTargetBodyFat {
                if bodyFat < 1 || bodyFat > 60 {
                    validationErrors.targetBodyFat = "체지방률은 1% ~ 60% 범위로 입력해주세요."
                }
            }
        }

        if isMuscleEnabled {
            if targetMuscleInput.isEmpty {
                validationErrors.targetMuscle = "목표 근육량을 입력해주세요."
            } else if parsedTargetMuscle == nil {
                validationErrors.targetMuscle = "올바른 숫자를 입력해주세요."
            }
        }

        // targetDate 범위 검증
        if !isMaintainGoal {
            if let dateError = GoalValidationService.validateTargetDateRange(targetDate) {
                validationErrors.targetDate = dateError
            }
        }

        // 변화율 경고 업데이트
        updateRateWarnings()
    }

    /// 폼을 초기화합니다.
    func reset() {
        goalType = .lose
        isWeightEnabled = false
        isBodyFatEnabled = false
        isMuscleEnabled = false
        clearInputs()
        errorMessage = nil
        isSaveSuccess = false
        validationErrors = GoalValidationErrors()
        rateWarnings = []
    }

    /// 입력 필드를 초기화합니다.
    func clearInputs() {
        targetWeightInput = ""
        targetBodyFatInput = ""
        targetMuscleInput = ""
        targetDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        dailyCalorieTargetInput = ""
    }

    /// 에러 메시지를 지웁니다.
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// 변화율 경고 업데이트
    private func updateRateWarnings() {
        var warnings: [String] = []

        if let rate = calculatedWeeklyWeightRate {
            let absRate = abs(NSDecimalNumber(decimal: rate).doubleValue)
            if absRate > 2.0 {
                warnings.append("주간 체중 변화율이 \(formatRate(rate))kg으로 권장 범위(±2.0kg)를 초과합니다.")
            }
        }

        if let rate = calculatedWeeklyBodyFatRate {
            let absRate = abs(NSDecimalNumber(decimal: rate).doubleValue)
            if absRate > 3.0 {
                warnings.append("주간 체지방률 변화율이 \(formatRate(rate))%로 권장 범위(±3.0%)를 초과합니다.")
            }
        }

        if let rate = calculatedWeeklyMuscleRate {
            let absRate = abs(NSDecimalNumber(decimal: rate).doubleValue)
            if absRate > 1.0 {
                warnings.append("주간 근육량 변화율이 \(formatRate(rate))kg으로 권장 범위(±1.0kg)를 초과합니다.")
            }
        }

        rateWarnings = warnings
    }

    /// Decimal을 소수점 2자리 문자열로 포맷
    private func formatRate(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }

    // TODO: BodyRepository 연동 필요
    private func getCurrentWeight() -> Decimal? {
        return Decimal(70.0)
    }

    private func getCurrentBodyFat() -> Decimal? {
        return Decimal(22.0)
    }

    private func getCurrentMuscle() -> Decimal? {
        return Decimal(30.0)
    }
}

// MARK: - GoalValidationErrors

/// 필드별 검증 에러
struct GoalValidationErrors {
    var general: String?
    var targetWeight: String?
    var targetBodyFat: String?
    var targetMuscle: String?
    var targetDate: String?
    var dailyCalorieTarget: String?

    /// 에러가 있는지 여부
    var hasErrors: Bool {
        general != nil ||
        targetWeight != nil ||
        targetBodyFat != nil ||
        targetMuscle != nil ||
        targetDate != nil ||
        dailyCalorieTarget != nil
    }
}

// MARK: - Preview Support

#if DEBUG
extension GoalSettingViewModel {
    static func makePreview() -> GoalSettingViewModel {
        fatalError("Preview support not yet implemented. Need to create Mock SetGoalUseCase.")
    }
}
#endif

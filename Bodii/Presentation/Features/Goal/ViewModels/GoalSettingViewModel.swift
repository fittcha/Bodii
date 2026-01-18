//
//  GoalSettingViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Form ViewModel Pattern for Goal Setting
// 복잡한 다중 목표 설정 폼의 상태를 관리하는 ViewModel
// 💡 Java 비교: Android의 ViewModel with Complex Form State와 유사

import Foundation
import Combine

// MARK: - GoalSettingViewModel

/// 목표 설정 화면의 ViewModel
///
/// 목표 설정 폼의 상태를 관리하고, 실시간 검증 및 예상 달성일 계산을 제공합니다.
///
/// ## 책임
/// - 다중 목표 폼 상태 관리 (체중, 체지방률, 근육량)
/// - 각 목표 활성화/비활성화 토글
/// - 실시간 입력값 검증
/// - 예상 달성일 자동 계산
/// - 목표 저장 처리
///
/// ## 의존성
/// - SetGoalUseCase: 목표 설정 비즈니스 로직
///
/// ## 사용 예시
/// ```swift
/// let viewModel = GoalSettingViewModel(
///     setGoalUseCase: setGoalUseCase,
///     userId: user.id
/// )
///
/// // 목표 유형 선택
/// viewModel.goalType = .lose
///
/// // 체중 목표 활성화 및 설정
/// viewModel.isWeightEnabled = true
/// viewModel.targetWeightInput = "65.0"
/// viewModel.weeklyWeightRateInput = "-0.5"
///
/// // 저장
/// await viewModel.save()
/// ```
@MainActor
final class GoalSettingViewModel: ObservableObject {

    // MARK: - Form State Properties

    // 📚 학습 포인트: Multi-Target Form State
    // 여러 개의 독립적인 목표를 각각 활성화/비활성화하고 관리

    /// 선택된 목표 유형
    /// 📚 학습 포인트: Goal Type Selection
    /// - 감량/유지/증량 중 선택
    /// - 선택에 따라 검증 규칙이 달라짐
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

    // MARK: - Weekly Rate Inputs

    /// 주간 체중 변화율 입력값 (kg/week)
    @Published var weeklyWeightRateInput: String = ""

    /// 주간 체지방률 변화율 입력값 (%/week)
    @Published var weeklyBodyFatRateInput: String = ""

    /// 주간 근육량 변화율 입력값 (kg/week)
    @Published var weeklyMuscleRateInput: String = ""

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
    @Published var validationErrors: ValidationErrors = ValidationErrors()

    // MARK: - Private Dependencies

    /// 목표 설정 유스케이스
    private let setGoalUseCase: SetGoalUseCase

    /// 사용자 ID
    private let userId: UUID

    /// Combine 구독 저장소
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// GoalSettingViewModel 초기화
    ///
    /// - Parameters:
    ///   - setGoalUseCase: 목표 설정 유스케이스
    ///   - userId: 사용자 ID
    init(
        setGoalUseCase: SetGoalUseCase,
        userId: UUID
    ) {
        self.setGoalUseCase = setGoalUseCase
        self.userId = userId

        // 📚 학습 포인트: Auto-fill Weekly Rates on Goal Type Change
        // 목표 유형 변경 시 권장 변화율 자동 입력
        setupGoalTypeObserver()
    }

    // MARK: - Computed Properties

    // 📚 학습 포인트: Real-time Validation with Computed Properties
    // 입력값이 변경될 때마다 자동으로 검증

    /// 최소 1개의 목표가 활성화되었는지
    var hasAtLeastOneTarget: Bool {
        isWeightEnabled || isBodyFatEnabled || isMuscleEnabled
    }

    /// 폼이 유효한지 여부
    var isFormValid: Bool {
        // 최소 1개 목표 활성화
        guard hasAtLeastOneTarget else { return false }

        // 활성화된 각 목표의 필수 입력값 확인
        if isWeightEnabled {
            guard !targetWeightInput.isEmpty,
                  parsedTargetWeight != nil,
                  !weeklyWeightRateInput.isEmpty,
                  parsedWeeklyWeightRate != nil else {
                return false
            }
        }

        if isBodyFatEnabled {
            guard !targetBodyFatInput.isEmpty,
                  parsedTargetBodyFat != nil,
                  !weeklyBodyFatRateInput.isEmpty,
                  parsedWeeklyBodyFatRate != nil else {
                return false
            }
        }

        if isMuscleEnabled {
            guard !targetMuscleInput.isEmpty,
                  parsedTargetMuscle != nil,
                  !weeklyMuscleRateInput.isEmpty,
                  parsedWeeklyMuscleRate != nil else {
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

    /// 파싱된 목표 체중 (kg)
    var parsedTargetWeight: Decimal? {
        guard !targetWeightInput.isEmpty else { return nil }
        return Decimal(string: targetWeightInput)
    }

    /// 파싱된 목표 체지방률 (%)
    var parsedTargetBodyFat: Decimal? {
        guard !targetBodyFatInput.isEmpty else { return nil }
        return Decimal(string: targetBodyFatInput)
    }

    /// 파싱된 목표 근육량 (kg)
    var parsedTargetMuscle: Decimal? {
        guard !targetMuscleInput.isEmpty else { return nil }
        return Decimal(string: targetMuscleInput)
    }

    /// 파싱된 주간 체중 변화율 (kg/week)
    var parsedWeeklyWeightRate: Decimal? {
        guard !weeklyWeightRateInput.isEmpty else { return nil }
        return Decimal(string: weeklyWeightRateInput)
    }

    /// 파싱된 주간 체지방률 변화율 (%/week)
    var parsedWeeklyBodyFatRate: Decimal? {
        guard !weeklyBodyFatRateInput.isEmpty else { return nil }
        return Decimal(string: weeklyBodyFatRateInput)
    }

    /// 파싱된 주간 근육량 변화율 (kg/week)
    var parsedWeeklyMuscleRate: Decimal? {
        guard !weeklyMuscleRateInput.isEmpty else { return nil }
        return Decimal(string: weeklyMuscleRateInput)
    }

    /// 파싱된 일일 칼로리 목표 (kcal)
    var parsedDailyCalorieTarget: Int32? {
        guard !dailyCalorieTargetInput.isEmpty else { return nil }
        return Int32(dailyCalorieTargetInput)
    }

    // MARK: - Estimated Completion Date

    /// 예상 달성일 계산
    ///
    /// 📚 학습 포인트: Real-time Preview Calculation
    /// 입력값이 변경될 때마다 자동으로 예상 달성일이 재계산됨
    ///
    /// - Returns: 예상 달성일 (여러 목표 중 가장 늦은 날짜)
    var estimatedCompletionDate: Date? {
        var dates: [Date] = []

        // 체중 목표 달성일
        if isWeightEnabled,
           let targetWeight = parsedTargetWeight,
           let weeklyRate = parsedWeeklyWeightRate,
           let currentWeight = getCurrentWeight() {
            if let date = calculateCompletionDate(
                current: currentWeight,
                target: targetWeight,
                weeklyRate: weeklyRate
            ) {
                dates.append(date)
            }
        }

        // 체지방률 목표 달성일
        if isBodyFatEnabled,
           let targetBodyFat = parsedTargetBodyFat,
           let weeklyRate = parsedWeeklyBodyFatRate,
           let currentBodyFat = getCurrentBodyFat() {
            if let date = calculateCompletionDate(
                current: currentBodyFat,
                target: targetBodyFat,
                weeklyRate: weeklyRate
            ) {
                dates.append(date)
            }
        }

        // 근육량 목표 달성일
        if isMuscleEnabled,
           let targetMuscle = parsedTargetMuscle,
           let weeklyRate = parsedWeeklyMuscleRate,
           let currentMuscle = getCurrentMuscle() {
            if let date = calculateCompletionDate(
                current: currentMuscle,
                target: targetMuscle,
                weeklyRate: weeklyRate
            ) {
                dates.append(date)
            }
        }

        // 여러 목표 중 가장 늦은 날짜 반환
        return dates.max()
    }

    /// 예상 달성 기간 (일)
    var estimatedDays: Int? {
        guard let completionDate = estimatedCompletionDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: completionDate)
        return components.day
    }

    // MARK: - Public Methods

    /// 목표를 저장합니다.
    ///
    /// ## 실행 순서
    /// 1. 입력값 검증
    /// 2. 로딩 상태 시작
    /// 3. SetGoalUseCase 호출
    /// 4. 성공 시 isSaveSuccess = true
    /// 5. 실패 시 errorMessage 설정
    ///
    /// - Example:
    /// ```swift
    /// Button("저장") {
    ///     Task {
    ///         await viewModel.save()
    ///     }
    /// }
    /// .disabled(!viewModel.canSave)
    /// .onChange(of: viewModel.isSaveSuccess) { success in
    ///     if success {
    ///         dismiss()
    ///     }
    /// }
    /// ```
    func save() async {
        // 1. 입력값 검증
        guard isFormValid else {
            errorMessage = "입력값을 확인해주세요."
            return
        }

        // 2. 로딩 상태 시작
        isSaving = true
        errorMessage = nil
        validationErrors = ValidationErrors()
        defer { isSaving = false }

        do {
            // 3. SetGoalUseCase 호출
            _ = try await setGoalUseCase.execute(
                userId: userId,
                goalType: goalType,
                targetWeight: isWeightEnabled ? parsedTargetWeight : nil,
                targetBodyFatPct: isBodyFatEnabled ? parsedTargetBodyFat : nil,
                targetMuscleMass: isMuscleEnabled ? parsedTargetMuscle : nil,
                weeklyWeightRate: isWeightEnabled ? parsedWeeklyWeightRate : nil,
                weeklyFatPctRate: isBodyFatEnabled ? parsedWeeklyBodyFatRate : nil,
                weeklyMuscleRate: isMuscleEnabled ? parsedWeeklyMuscleRate : nil,
                dailyCalorieTarget: parsedDailyCalorieTarget
            )

            // 4. 성공
            isSaveSuccess = true

        } catch let error as SetGoalError {
            // 5. SetGoalError 처리
            errorMessage = error.localizedDescription

        } catch let error as GoalValidationError {
            // 6. GoalValidationError 처리
            errorMessage = error.localizedDescription

        } catch {
            // 7. 예상하지 못한 에러
            errorMessage = "목표 저장 실패: \(error.localizedDescription)"
        }
    }

    /// 실시간 입력값 검증
    ///
    /// 사용자가 입력할 때마다 호출하여 검증 피드백 제공
    func validateInputs() {
        validationErrors = ValidationErrors()

        // 최소 1개 목표 활성화 검증
        if !hasAtLeastOneTarget {
            validationErrors.general = "최소 1개 이상의 목표를 선택해주세요."
        }

        // 체중 목표 검증
        if isWeightEnabled {
            if targetWeightInput.isEmpty {
                validationErrors.targetWeight = "목표 체중을 입력해주세요."
            } else if parsedTargetWeight == nil {
                validationErrors.targetWeight = "올바른 숫자를 입력해주세요."
            }

            if weeklyWeightRateInput.isEmpty {
                validationErrors.weeklyWeightRate = "주간 변화율을 입력해주세요."
            } else if parsedWeeklyWeightRate == nil {
                validationErrors.weeklyWeightRate = "올바른 숫자를 입력해주세요."
            }
        }

        // 체지방률 목표 검증
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

            if weeklyBodyFatRateInput.isEmpty {
                validationErrors.weeklyBodyFatRate = "주간 변화율을 입력해주세요."
            } else if parsedWeeklyBodyFatRate == nil {
                validationErrors.weeklyBodyFatRate = "올바른 숫자를 입력해주세요."
            }
        }

        // 근육량 목표 검증
        if isMuscleEnabled {
            if targetMuscleInput.isEmpty {
                validationErrors.targetMuscle = "목표 근육량을 입력해주세요."
            } else if parsedTargetMuscle == nil {
                validationErrors.targetMuscle = "올바른 숫자를 입력해주세요."
            }

            if weeklyMuscleRateInput.isEmpty {
                validationErrors.weeklyMuscleRate = "주간 변화율을 입력해주세요."
            } else if parsedWeeklyMuscleRate == nil {
                validationErrors.weeklyMuscleRate = "올바른 숫자를 입력해주세요."
            }
        }
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
        validationErrors = ValidationErrors()
    }

    /// 입력 필드를 초기화합니다.
    func clearInputs() {
        targetWeightInput = ""
        targetBodyFatInput = ""
        targetMuscleInput = ""
        weeklyWeightRateInput = ""
        weeklyBodyFatRateInput = ""
        weeklyMuscleRateInput = ""
        dailyCalorieTargetInput = ""
    }

    /// 에러 메시지를 지웁니다.
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// 목표 유형 변경 시 권장 변화율 자동 입력
    ///
    /// 📚 학습 포인트: Combine Observer Pattern
    /// goalType의 변화를 관찰하여 자동으로 권장값 설정
    private func setupGoalTypeObserver() {
        $goalType
            .sink { [weak self] newGoalType in
                self?.autoFillRecommendedRates(for: newGoalType)
            }
            .store(in: &cancellables)
    }

    /// 목표 유형에 따른 권장 변화율 자동 입력
    private func autoFillRecommendedRates(for goalType: GoalType) {
        switch goalType {
        case .lose:
            // 감량 목표: 음수 변화율
            if weeklyWeightRateInput.isEmpty {
                weeklyWeightRateInput = "-0.5"
            }
            if weeklyBodyFatRateInput.isEmpty {
                weeklyBodyFatRateInput = "-0.5"
            }
            if weeklyMuscleRateInput.isEmpty {
                weeklyMuscleRateInput = "0.0"
            }

        case .maintain:
            // 유지 목표: 0 변화율
            weeklyWeightRateInput = "0.0"
            weeklyBodyFatRateInput = "0.0"
            weeklyMuscleRateInput = "0.0"

        case .gain:
            // 증량 목표: 양수 변화율
            if weeklyWeightRateInput.isEmpty {
                weeklyWeightRateInput = "0.5"
            }
            if weeklyBodyFatRateInput.isEmpty {
                weeklyBodyFatRateInput = "0.0"
            }
            if weeklyMuscleRateInput.isEmpty {
                weeklyMuscleRateInput = "0.2"
            }
        }
    }

    /// 예상 달성일 계산
    private func calculateCompletionDate(
        current: Decimal,
        target: Decimal,
        weeklyRate: Decimal
    ) -> Date? {
        // 변화율이 0이면 계산 불가
        guard weeklyRate != 0 else { return nil }

        let difference = target - current

        // 방향이 맞지 않으면 계산 불가
        if (difference > 0 && weeklyRate < 0) || (difference < 0 && weeklyRate > 0) {
            return nil
        }

        // 예상 소요 주수 계산
        let weeksToGoal = abs(difference / weeklyRate)

        // 주수를 일수로 변환
        let daysToGoal = weeksToGoal * 7

        // 현재 날짜에 일수를 더함
        let calendar = Calendar.current
        let estimatedDate = calendar.date(
            byAdding: .day,
            value: Int((daysToGoal as NSDecimalNumber).doubleValue.rounded()),
            to: Date()
        )

        return estimatedDate
    }

    // 📚 학습 포인트: Current Values from Latest Body Composition
    // 실제 구현에서는 BodyRepository에서 최신 체성분 조회
    // 현재는 더미 데이터 반환 (TODO: BodyRepository 연동)

    private func getCurrentWeight() -> Decimal? {
        // TODO: BodyRepository.fetchLatest()에서 최신 체중 조회
        return Decimal(70.0)
    }

    private func getCurrentBodyFat() -> Decimal? {
        // TODO: BodyRepository.fetchLatest()에서 최신 체지방률 조회
        return Decimal(22.0)
    }

    private func getCurrentMuscle() -> Decimal? {
        // TODO: BodyRepository.fetchLatest()에서 최신 근육량 조회
        return Decimal(30.0)
    }
}

// MARK: - ValidationErrors

/// 필드별 검증 에러
///
/// 📚 학습 포인트: Structured Validation Errors
/// 각 필드별로 에러를 구분하여 UI에 표시
struct ValidationErrors {
    var general: String?
    var targetWeight: String?
    var targetBodyFat: String?
    var targetMuscle: String?
    var weeklyWeightRate: String?
    var weeklyBodyFatRate: String?
    var weeklyMuscleRate: String?
    var dailyCalorieTarget: String?

    /// 에러가 있는지 여부
    var hasErrors: Bool {
        general != nil ||
        targetWeight != nil ||
        targetBodyFat != nil ||
        targetMuscle != nil ||
        weeklyWeightRate != nil ||
        weeklyBodyFatRate != nil ||
        weeklyMuscleRate != nil ||
        dailyCalorieTarget != nil
    }
}

// MARK: - Preview Support

#if DEBUG
extension GoalSettingViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    static func makePreview() -> GoalSettingViewModel {
        // Mock UseCase 및 Repository 필요
        fatalError("Preview support not yet implemented. Need to create Mock SetGoalUseCase.")
    }
}
#endif

// MARK: - Documentation

/// ## GoalSettingViewModel 설명
///
/// 복잡한 다중 목표 설정 폼을 관리하는 ViewModel입니다.
///
/// ### 주요 기능
///
/// 1. **Multi-Target Form Management**:
///    - 체중, 체지방률, 근육량 목표를 독립적으로 활성화/비활성화
///    - 각 목표별 입력 필드 관리
///
/// 2. **Real-time Validation**:
///    - 입력값 변경 시 즉시 검증
///    - 필드별 에러 메시지 제공
///
/// 3. **Estimated Completion Date**:
///    - 입력값을 기반으로 예상 달성일 자동 계산
///    - 여러 목표 중 가장 늦은 날짜 표시
///
/// 4. **Auto-fill Recommended Rates**:
///    - 목표 유형 변경 시 권장 변화율 자동 입력
///    - 감량: -0.5kg/week, 유지: 0.0, 증량: +0.5kg/week
///
/// ### 폼 상태 구조
///
/// ```
/// GoalSettingViewModel
/// ├── goalType: .lose/.maintain/.gain
/// ├── Weight Goal
/// │   ├── isWeightEnabled: true/false
/// │   ├── targetWeightInput: "65.0"
/// │   └── weeklyWeightRateInput: "-0.5"
/// ├── Body Fat Goal
/// │   ├── isBodyFatEnabled: true/false
/// │   ├── targetBodyFatInput: "18.0"
/// │   └── weeklyBodyFatRateInput: "-0.5"
/// └── Muscle Goal
///     ├── isMuscleEnabled: true/false
///     ├── targetMuscleInput: "30.0"
///     └── weeklyMuscleRateInput: "0.0"
/// ```
///
/// ### 사용 예시
///
/// ```swift
/// struct GoalSettingView: View {
///     @StateObject private var viewModel: GoalSettingViewModel
///
///     var body: some View {
///         Form {
///             // 목표 유형 선택
///             Picker("목표 유형", selection: $viewModel.goalType) {
///                 ForEach(GoalType.allCases) { type in
///                     Text(type.displayName).tag(type)
///                 }
///             }
///
///             // 체중 목표
///             Toggle("체중 목표", isOn: $viewModel.isWeightEnabled)
///             if viewModel.isWeightEnabled {
///                 TextField("목표 체중 (kg)", text: $viewModel.targetWeightInput)
///                 TextField("주간 변화율 (kg)", text: $viewModel.weeklyWeightRateInput)
///                 if let error = viewModel.validationErrors.targetWeight {
///                     Text(error).foregroundColor(.red)
///                 }
///             }
///
///             // 예상 달성일
///             if let date = viewModel.estimatedCompletionDate {
///                 Text("예상 달성일: \(date, format: .dateTime)")
///             }
///
///             // 저장 버튼
///             Button("저장") {
///                 Task { await viewModel.save() }
///             }
///             .disabled(!viewModel.canSave)
///         }
///         .onChange(of: viewModel.isSaveSuccess) { success in
///             if success { dismiss() }
///         }
///         .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
///             Button("확인") { viewModel.clearError() }
///         } message: {
///             Text(viewModel.errorMessage ?? "")
///         }
///     }
/// }
/// ```
///

//
//  ExerciseInputViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Form ViewModel Pattern
// 입력 폼을 관리하는 ViewModel 패턴
// 💡 Java 비교: Android의 ViewModel with Form State와 유사

import Foundation
import Observation

/// 운동 입력 폼 뷰 모델
///
/// 운동 입력 폼의 상태를 관리하고, 실시간 칼로리 미리보기를 제공합니다.
///
/// ## 책임
/// - 폼 입력 상태 관리 (운동 종류, 시간, 강도, 메모)
/// - 실시간 칼로리 계산 미리보기
/// - 입력값 검증
/// - 운동 기록 저장
///
/// ## 의존성
/// - AddExerciseRecordUseCase: 운동 기록 추가
///
/// ## 사용 예시
/// ```swift
/// let viewModel = ExerciseInputViewModel(
///     addExerciseRecordUseCase: addExerciseRecordUseCase,
///     userId: user.id,
///     userWeight: user.currentWeight ?? 70.0,
///     userBMR: user.currentBMR ?? 1650,
///     userTDEE: user.currentTDEE ?? 2310
/// )
///
/// // View에서 사용
/// ExerciseTypeGridView(selectedType: $viewModel.selectedExerciseType)
/// DurationInputView(duration: $viewModel.duration)
/// Text("예상 소모: \(viewModel.previewCalories)kcal")
/// Button("저장", action: viewModel.save)
/// ```
@Observable
final class ExerciseInputViewModel {

    // MARK: - Form State Properties

    // 📚 학습 포인트: Form State Management
    // @Observable 매크로로 모든 프로퍼티 변경이 자동으로 View에 반영됨
    // 💡 Java 비교: Android의 MutableStateFlow와 유사

    /// 선택된 운동 종류
    var selectedExerciseType: ExerciseType = .running

    /// 운동 시간 (분)
    var duration: Int32 = 30

    /// 선택된 강도
    var selectedIntensity: Intensity = .medium

    /// 메모 (선택사항)
    var note: String = ""

    /// 운동 날짜
    var selectedDate: Date = Date()

    // MARK: - UI State Properties

    /// 저장 중 로딩 상태
    var isSaving: Bool = false

    /// 에러 메시지
    var errorMessage: String?

    /// 저장 성공 여부
    var isSaveSuccess: Bool = false

    // MARK: - Computed Properties

    // 📚 학습 포인트: Computed Property with Side Effects
    // 폼 상태가 변경될 때마다 자동으로 재계산되는 미리보기 칼로리

    /// 실시간 칼로리 미리보기
    ///
    /// 현재 입력값을 기반으로 예상 소모 칼로리를 계산합니다.
    /// 폼의 어떤 값이든 변경되면 자동으로 재계산됩니다.
    ///
    /// - Returns: 예상 소모 칼로리 (kcal)
    ///
    /// - Note: ExerciseCalcService를 사용하여 MET 기반 계산
    var previewCalories: Int32 {
        guard duration > 0 else { return 0 }

        return ExerciseCalcService.calculateCalories(
            exerciseType: selectedExerciseType,
            duration: duration,
            intensity: selectedIntensity,
            weight: userWeight
        )
    }

    /// 폼이 유효한지 여부
    ///
    /// 최소 1분 이상의 운동 시간이 입력되었는지 검증합니다.
    ///
    /// - Returns: 폼이 유효하면 true
    var isFormValid: Bool {
        duration >= 1
    }

    /// 에러가 있는지 여부
    var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Private Dependencies

    // 📚 학습 포인트: Dependency Injection
    // 필요한 의존성은 생성자를 통해 주입받아 테스트 가능성 향상

    /// 운동 기록 추가 유스케이스
    private let addExerciseRecordUseCase: AddExerciseRecordUseCase

    /// 사용자 ID
    private let userId: UUID

    /// 사용자 체중 (kg) - MET 계산에 사용
    private let userWeight: Decimal

    /// 사용자 BMR - DailyLog 생성 시 사용
    private let userBMR: Decimal

    /// 사용자 TDEE - DailyLog 생성 시 사용
    private let userTDEE: Decimal

    // MARK: - Initialization

    /// ExerciseInputViewModel 초기화
    ///
    /// - Parameters:
    ///   - addExerciseRecordUseCase: 운동 기록 추가 유스케이스
    ///   - userId: 사용자 ID
    ///   - userWeight: 사용자 체중 (kg)
    ///   - userBMR: 사용자 BMR
    ///   - userTDEE: 사용자 TDEE
    ///   - selectedDate: 초기 선택 날짜 (기본값: 오늘)
    init(
        addExerciseRecordUseCase: AddExerciseRecordUseCase,
        userId: UUID,
        userWeight: Decimal,
        userBMR: Decimal,
        userTDEE: Decimal,
        selectedDate: Date = Date()
    ) {
        self.addExerciseRecordUseCase = addExerciseRecordUseCase
        self.userId = userId
        self.userWeight = userWeight
        self.userBMR = userBMR
        self.userTDEE = userTDEE
        self.selectedDate = selectedDate
    }

    // MARK: - Public Methods

    /// 운동 기록을 저장합니다.
    ///
    /// ## 실행 순서
    /// 1. 입력값 검증
    /// 2. 로딩 상태 시작
    /// 3. AddExerciseRecordUseCase 호출
    /// 4. 성공 시 isSaveSuccess = true
    /// 5. 실패 시 errorMessage 설정
    ///
    /// - Note: 성공 시 View가 dismiss되도록 isSaveSuccess 플래그 사용
    ///
    /// - Example:
    /// ```swift
    /// Button("저장") {
    ///     Task {
    ///         await viewModel.save()
    ///     }
    /// }
    /// .onChange(of: viewModel.isSaveSuccess) { success in
    ///     if success {
    ///         dismiss()
    ///     }
    /// }
    /// ```
    @MainActor
    func save() async {
        // 1. 입력값 검증
        guard isFormValid else {
            errorMessage = "운동 시간은 최소 1분 이상이어야 합니다."
            return
        }

        // 2. 로딩 상태 시작
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            // 3. AddExerciseRecordUseCase 호출
            // 📚 학습 포인트: UseCase Pattern
            // ViewModel은 비즈니스 로직을 직접 수행하지 않고 UseCase에 위임
            // 💡 Java 비교: Android의 Use Case Pattern과 동일

            _ = try await addExerciseRecordUseCase.execute(
                userId: userId,
                date: selectedDate,
                exerciseType: selectedExerciseType,
                duration: duration,
                intensity: selectedIntensity,
                note: note.isEmpty ? nil : note,
                userWeight: userWeight,
                userBMR: userBMR,
                userTDEE: userTDEE
            )

            // 4. 성공
            isSaveSuccess = true

        } catch {
            // 5. 실패
            // 📚 학습 포인트: Error Handling
            // Swift의 Error 프로토콜을 사용한 에러 처리
            // localizedDescription으로 사용자 친화적 메시지 제공
            errorMessage = "운동 기록 저장 실패: \(error.localizedDescription)"
        }
    }

    /// 폼을 초기화합니다.
    ///
    /// 모든 입력값을 기본값으로 리셋합니다.
    ///
    /// - Note: 주로 저장 성공 후 또는 취소 시 사용
    ///
    /// - Example:
    /// ```swift
    /// Button("취소") {
    ///     viewModel.reset()
    ///     dismiss()
    /// }
    /// ```
    func reset() {
        selectedExerciseType = .running
        duration = 30
        selectedIntensity = .medium
        note = ""
        selectedDate = Date()
        errorMessage = nil
        isSaveSuccess = false
    }

    /// 에러 메시지를 지웁니다.
    ///
    /// 에러 알림을 닫을 때 호출합니다.
    ///
    /// - Example:
    /// ```swift
    /// .alert("오류", isPresented: $viewModel.hasError) {
    ///     Button("확인") { viewModel.clearError() }
    /// }
    /// ```
    func clearError() {
        errorMessage = nil
    }

    /// 운동 종류를 선택합니다.
    ///
    /// - Parameter type: 선택할 운동 종류
    ///
    /// - Note: 선택 시 previewCalories가 자동으로 재계산됨
    ///
    /// - Example:
    /// ```swift
    /// Button(exerciseType.displayName) {
    ///     viewModel.selectExerciseType(exerciseType)
    /// }
    /// ```
    func selectExerciseType(_ type: ExerciseType) {
        selectedExerciseType = type
    }

    /// 강도를 선택합니다.
    ///
    /// - Parameter intensity: 선택할 강도
    ///
    /// - Note: 선택 시 previewCalories가 자동으로 재계산됨
    ///
    /// - Example:
    /// ```swift
    /// Picker("강도", selection: $viewModel.selectedIntensity) {
    ///     ForEach(Intensity.allCases) { intensity in
    ///         Text(intensity.displayName).tag(intensity)
    ///     }
    /// }
    /// ```
    func selectIntensity(_ intensity: Intensity) {
        selectedIntensity = intensity
    }

    /// 운동 시간을 설정합니다.
    ///
    /// - Parameter minutes: 운동 시간 (분)
    ///
    /// - Note: 0 이상의 값만 허용
    /// - Note: 설정 시 previewCalories가 자동으로 재계산됨
    ///
    /// - Example:
    /// ```swift
    /// Stepper("\(viewModel.duration)분", value: Binding(
    ///     get: { Int(viewModel.duration) },
    ///     set: { viewModel.setDuration(Int32($0)) }
    /// ), in: 1...300)
    /// ```
    func setDuration(_ minutes: Int32) {
        duration = max(0, minutes)
    }
}

// MARK: - Validation Helpers

extension ExerciseInputViewModel {

    /// 운동 시간 검증 에러 메시지
    ///
    /// - Returns: 검증 에러가 있으면 메시지, 없으면 nil
    var durationValidationError: String? {
        if duration < 1 {
            return "최소 1분 이상 입력해주세요"
        }
        return nil
    }
}

// MARK: - Learning Notes

/// ## Form ViewModel Pattern
///
/// Form ViewModel은 사용자 입력 폼의 상태와 로직을 관리하는 패턴입니다.
///
/// ### 주요 책임
///
/// 1. **Form State Management**:
///    - 각 입력 필드의 값 저장 (selectedExerciseType, duration, selectedIntensity, note)
///    - 입력값 변경 시 자동으로 View 업데이트
///
/// 2. **Real-time Validation**:
///    - 입력값이 변경될 때마다 검증 (isFormValid)
///    - 에러 메시지 표시 (durationValidationError)
///
/// 3. **Real-time Preview**:
///    - 입력값을 기반으로 결과 미리보기 (previewCalories)
///    - Computed Property로 자동 재계산
///
/// 4. **Submit Action**:
///    - 저장 액션 처리 (save)
///    - 로딩 상태 관리 (isSaving)
///    - 성공/실패 처리 (isSaveSuccess, errorMessage)
///
/// ### Form ViewModel vs List ViewModel
///
/// **List ViewModel** (ExerciseListViewModel):
/// - 데이터 조회 및 표시
/// - 읽기 전용 작업 위주
/// - 예: 운동 기록 목록 조회
///
/// **Form ViewModel** (ExerciseInputViewModel):
/// - 데이터 입력 및 생성
/// - 쓰기 작업 위주
/// - 예: 새로운 운동 기록 추가
///
/// ### Real-time Calorie Preview
///
/// ```swift
/// var previewCalories: Int32 {
///     // 폼 상태가 변경될 때마다 자동 실행
///     ExerciseCalcService.calculateCalories(
///         exerciseType: selectedExerciseType,  // 변경되면 재계산
///         duration: duration,                   // 변경되면 재계산
///         intensity: selectedIntensity,         // 변경되면 재계산
///         weight: userWeight
///     )
/// }
/// ```
///
/// @Observable 매크로 덕분에 selectedExerciseType, duration, selectedIntensity 중
/// 어떤 것이든 변경되면 previewCalories가 자동으로 재계산되고 View가 업데이트됩니다.
///
/// ### Validation Pattern
///
/// **Immediate Validation**:
/// ```swift
/// var isFormValid: Bool {
///     duration >= 1
/// }
///
/// var durationValidationError: String? {
///     if duration < 1 { return "최소 1분 이상" }
///     return nil
/// }
/// ```
///
/// **Submit Time Validation**:
/// ```swift
/// func save() async {
///     guard isFormValid else {
///         errorMessage = "입력값을 확인해주세요"
///         return
///     }
///     // 저장 로직
/// }
/// ```
///
/// ### UI Integration
///
/// **Form Binding**:
/// ```swift
/// struct ExerciseInputView: View {
///     var viewModel: ExerciseInputViewModel
///
///     var body: some View {
///         VStack {
///             // 운동 종류 선택
///             ExerciseTypeGridView(
///                 selectedType: Binding(
///                     get: { viewModel.selectedExerciseType },
///                     set: { viewModel.selectExerciseType($0) }
///                 )
///             )
///
///             // 운동 시간 입력
///             Stepper("\(viewModel.duration)분",
///                 value: Binding(
///                     get: { Int(viewModel.duration) },
///                     set: { viewModel.setDuration(Int32($0)) }
///                 )
///             )
///
///             // 실시간 칼로리 미리보기
///             Text("예상 소모: \(viewModel.previewCalories)kcal")
///                 .font(.headline)
///
///             // 저장 버튼
///             Button("저장") {
///                 Task { await viewModel.save() }
///             }
///             .disabled(!viewModel.isFormValid || viewModel.isSaving)
///         }
///         .onChange(of: viewModel.isSaveSuccess) { success in
///             if success { dismiss() }
///         }
///         .alert("오류", isPresented: Binding(
///             get: { viewModel.hasError },
///             set: { _ in viewModel.clearError() }
///         )) {
///             Button("확인") { viewModel.clearError() }
///         } message: {
///             Text(viewModel.errorMessage ?? "")
///         }
///     }
/// }
/// ```
///
/// ### Testing
///
/// Form ViewModel은 의존성 주입을 통해 쉽게 테스트할 수 있습니다:
///
/// ```swift
/// func testPreviewCaloriesCalculation() {
///     // given
///     let mockUseCase = MockAddExerciseRecordUseCase()
///     let viewModel = ExerciseInputViewModel(
///         addExerciseRecordUseCase: mockUseCase,
///         userId: UUID(),
///         userWeight: 70.0,
///         userBMR: 1650,
///         userTDEE: 2310
///     )
///
///     // when
///     viewModel.selectedExerciseType = .running  // 8.0 MET
///     viewModel.duration = 30                    // 0.5 hours
///     viewModel.selectedIntensity = .medium      // 1.0 multiplier
///
///     // then
///     // 8.0 × 1.0 × 70 × 0.5 = 280 kcal
///     XCTAssertEqual(viewModel.previewCalories, 280)
/// }
///
/// func testFormValidation() {
///     // given
///     let viewModel = ExerciseInputViewModel(...)
///
///     // when
///     viewModel.duration = 0
///
///     // then
///     XCTAssertFalse(viewModel.isFormValid)
///     XCTAssertEqual(viewModel.durationValidationError, "최소 1분 이상 입력해주세요")
/// }
///
/// func testSaveSuccess() async {
///     // given
///     let mockUseCase = MockAddExerciseRecordUseCase()
///     let viewModel = ExerciseInputViewModel(
///         addExerciseRecordUseCase: mockUseCase,
///         userId: UUID(),
///         userWeight: 70.0,
///         userBMR: 1650,
///         userTDEE: 2310
///     )
///     viewModel.duration = 30
///
///     // when
///     await viewModel.save()
///
///     // then
///     XCTAssertTrue(viewModel.isSaveSuccess)
///     XCTAssertFalse(viewModel.hasError)
///     XCTAssertTrue(mockUseCase.executeCalled)
/// }
/// ```
///
/// ### Best Practices
///
/// 1. **Computed Properties for Derived State**:
///    - previewCalories는 저장하지 않고 계산 (항상 최신 상태 보장)
///
/// 2. **Validation in Multiple Layers**:
///    - UI 레벨: isFormValid로 버튼 disable
///    - Submit 레벨: save()에서 guard 검증
///    - UseCase 레벨: AddExerciseRecordUseCase에서 최종 검증
///
/// 3. **Clear Success Indicator**:
///    - isSaveSuccess 플래그로 View dismiss 시점 명확히
///
/// 4. **Reset Method**:
///    - 저장 성공 후 폼 재사용을 위한 reset() 제공
///
/// 5. **Immutable Dependencies**:
///    - userWeight, userBMR, userTDEE는 let으로 불변성 보장
///    - ViewModel 생성 시점의 값으로 고정

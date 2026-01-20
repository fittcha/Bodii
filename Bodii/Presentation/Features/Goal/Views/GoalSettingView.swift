//
//  GoalSettingView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Complex Multi-Target Form View
// 여러 개의 독립적인 목표를 설정할 수 있는 복잡한 폼 UI 구현
// 💡 Java 비교: Android의 Fragment with Complex Form Layout과 유사

import SwiftUI

// MARK: - Goal Setting View

/// 목표 설정 화면
///
/// 체중, 체지방률, 근육량 목표를 설정하기 위한 입력 폼을 제공합니다.
///
/// **주요 기능:**
/// - 목표 유형 선택 (감량/유지/증량)
/// - 다중 목표 활성화/비활성화 (체중, 체지방률, 근육량)
/// - 각 목표별 목표값 및 주간 변화율 입력
/// - 실시간 예상 달성일 계산
/// - 입력값 검증 및 에러 표시
///
/// **실시간 미리보기:**
/// - 사용자가 입력을 변경할 때마다 예상 달성일이 자동으로 계산됩니다.
/// - 최소 1개 이상의 목표 활성화 필요
///
/// - Example:
/// ```swift
/// .sheet(isPresented: $isShowingGoalSetting) {
///     GoalSettingView(
///         viewModel: viewModel,
///         onSaveSuccess: {
///             isShowingGoalSetting = false
///             dashboardViewModel.refresh()
///         }
///     )
/// }
/// ```
struct GoalSettingView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @StateObject ViewModel
    // ViewModel을 View가 소유하도록 하여 생명주기 관리
    // 💡 Java 비교: ViewModel + ViewModelProvider와 유사

    /// 뷰 모델
    @StateObject var viewModel: GoalSettingViewModel

    /// 저장 성공 시 실행할 콜백
    let onSaveSuccess: (() -> Void)?

    // MARK: - Environment

    /// 모달 닫기 액션
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// 칼로리 목표 입력 포커스 상태
    @FocusState private var isCalorieFocused: Bool

    // MARK: - Initialization

    /// GoalSettingView 초기화
    ///
    /// - Parameters:
    ///   - viewModel: 목표 설정 뷰 모델
    ///   - onSaveSuccess: 저장 성공 시 실행할 콜백 (옵셔널)
    init(
        viewModel: GoalSettingViewModel,
        onSaveSuccess: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onSaveSuccess = onSaveSuccess
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // 📚 학습 포인트: ScrollView for Keyboard Avoidance
            // ScrollView를 사용하면 키보드가 나타날 때 자동으로 스크롤
            ScrollView {
                VStack(spacing: 24) {
                    // 목표 유형 선택
                    goalTypeSection

                    // 목표 선택 안내
                    targetSelectionHint

                    // 체중 목표 입력
                    weightTargetSection

                    // 체지방률 목표 입력
                    bodyFatTargetSection

                    // 근육량 목표 입력
                    muscleTargetSection

                    // 일일 칼로리 목표 (선택사항)
                    calorieTargetSection

                    // 예상 달성일 미리보기
                    if viewModel.hasAtLeastOneTarget {
                        estimatedCompletionCard
                    }

                    // 저장 버튼
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("목표 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
            // 📚 학습 포인트: onChange for Side Effects
            // ViewModel의 상태 변경을 감지하여 부수 효과 실행
            .onChange(of: viewModel.isSaveSuccess) { _, success in
                if success {
                    // 저장 성공 시
                    onSaveSuccess?()
                    dismiss()
                }
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - View Components

    // 📚 학습 포인트: Section-based Form Layout
    // 각 섹션을 독립적인 computed property로 분리
    // 가독성과 재사용성 향상

    /// 목표 유형 선택 섹션
    @ViewBuilder
    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "목표 유형",
                icon: "target"
            )

            // 📚 학습 포인트: Picker with Segmented Style
            // 3가지 선택지를 세그먼트 컨트롤로 표시
            Picker("목표 유형", selection: $viewModel.goalType) {
                ForEach(GoalType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 목표 선택 안내 메시지
    @ViewBuilder
    private var targetSelectionHint: some View {
        if !viewModel.hasAtLeastOneTarget {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)

                Text("최소 1개 이상의 목표를 선택해주세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }

    /// 체중 목표 입력 섹션
    @ViewBuilder
    private var weightTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 토글 헤더
            HStack {
                sectionHeader(
                    title: "체중 목표",
                    icon: "scalemass"
                )

                Spacer()

                Toggle("", isOn: $viewModel.isWeightEnabled)
                    .labelsHidden()
            }

            // 입력 필드 (활성화된 경우에만 표시)
            if viewModel.isWeightEnabled {
                VStack(spacing: 16) {
                    // 목표 체중 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("목표 체중 (kg)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("예: 65.0", text: $viewModel.targetWeightInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )

                        // 검증 에러 표시
                        if let error = viewModel.validationErrors.targetWeight {
                            validationErrorLabel(error)
                        }
                    }

                    // 주간 변화율 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("주간 변화율 (kg/week)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TextField("예: -0.5", text: $viewModel.weeklyWeightRateInput)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )

                            Text("kg/주")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // 검증 에러 표시
                        if let error = viewModel.validationErrors.weeklyWeightRate {
                            validationErrorLabel(error)
                        }

                        // 권장 범위 힌트
                        Text("권장: ±2kg/week 이내")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isWeightEnabled)
    }

    /// 체지방률 목표 입력 섹션
    @ViewBuilder
    private var bodyFatTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 토글 헤더
            HStack {
                sectionHeader(
                    title: "체지방률 목표",
                    icon: "Percent"
                )

                Spacer()

                Toggle("", isOn: $viewModel.isBodyFatEnabled)
                    .labelsHidden()
            }

            // 입력 필드 (활성화된 경우에만 표시)
            if viewModel.isBodyFatEnabled {
                VStack(spacing: 16) {
                    // 목표 체지방률 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("목표 체지방률 (%)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("예: 18.0", text: $viewModel.targetBodyFatInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )

                        // 검증 에러 표시
                        if let error = viewModel.validationErrors.targetBodyFat {
                            validationErrorLabel(error)
                        }
                    }

                    // 주간 변화율 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("주간 변화율 (%/week)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TextField("예: -0.5", text: $viewModel.weeklyBodyFatRateInput)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )

                            Text("%/주")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // 검증 에러 표시
                        if let error = viewModel.validationErrors.weeklyBodyFatRate {
                            validationErrorLabel(error)
                        }

                        // 권장 범위 힌트
                        Text("권장: ±3%/week 이내")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isBodyFatEnabled)
    }

    /// 근육량 목표 입력 섹션
    @ViewBuilder
    private var muscleTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 토글 헤더
            HStack {
                sectionHeader(
                    title: "근육량 목표",
                    icon: "figure.strengthtraining.traditional"
                )

                Spacer()

                Toggle("", isOn: $viewModel.isMuscleEnabled)
                    .labelsHidden()
            }

            // 입력 필드 (활성화된 경우에만 표시)
            if viewModel.isMuscleEnabled {
                VStack(spacing: 16) {
                    // 목표 근육량 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("목표 근육량 (kg)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("예: 32.0", text: $viewModel.targetMuscleInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )

                        // 검증 에러 표시
                        if let error = viewModel.validationErrors.targetMuscle {
                            validationErrorLabel(error)
                        }
                    }

                    // 주간 변화율 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("주간 변화율 (kg/week)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TextField("예: 0.2", text: $viewModel.weeklyMuscleRateInput)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )

                            Text("kg/주")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // 검증 에러 표시
                        if let error = viewModel.validationErrors.weeklyMuscleRate {
                            validationErrorLabel(error)
                        }

                        // 권장 범위 힌트
                        Text("권장: ±1kg/week 이내")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isMuscleEnabled)
    }

    /// 일일 칼로리 목표 섹션 (선택사항)
    @ViewBuilder
    private var calorieTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "일일 칼로리 목표",
                icon: "flame",
                isOptional: true
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TextField("예: 2000", text: $viewModel.dailyCalorieTargetInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                        .focused($isCalorieFocused)

                    Text("kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("목표 달성을 위한 권장 칼로리 섭취량")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 예상 달성일 미리보기 카드
    ///
    /// 사용자가 입력을 변경할 때마다 자동으로 업데이트됩니다.
    @ViewBuilder
    private var estimatedCompletionCard: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(.green)

                Text("예상 달성일")
                    .font(.headline)

                Spacer()
            }

            // 📚 학습 포인트: Real-time Preview
            // ViewModel의 computed property가 자동으로 재계산
            if let completionDate = viewModel.estimatedCompletionDate,
               let days = viewModel.estimatedDays {
                VStack(spacing: 8) {
                    // 날짜 표시
                    Text(completionDate, format: .dateTime.year().month().day())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)

                    // 기간 표시
                    Text("약 \(days)일 후")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                // 계산 불가 상태
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)

                    Text("입력값을 확인해주세요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // 안내 메시지
            Text("현재 설정한 변화율 기준으로 계산된 예상 날짜입니다")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    /// 액션 버튼들 (저장)
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 저장 버튼
            Button(action: {
                // 키보드 숨기기
                isCalorieFocused = false

                // 저장 실행
                Task {
                    await viewModel.save()
                }
            }) {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }

                    Text(viewModel.isSaving ? "저장 중..." : "목표 저장")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canSave ? Color.blue : Color.gray)
                )
                .foregroundStyle(.white)
            }
            .disabled(!viewModel.canSave)

            // 일반 검증 에러 메시지
            if let generalError = viewModel.validationErrors.general {
                validationErrorLabel(generalError)
            }
        }
    }

    /// 취소 버튼
    @ViewBuilder
    private var cancelButton: some View {
        Button("취소") {
            viewModel.reset()
            dismiss()
        }
        .disabled(viewModel.isSaving)
    }

    /// 검증 에러 레이블
    ///
    /// - Parameter message: 에러 메시지
    /// - Returns: 에러 레이블 뷰
    @ViewBuilder
    private func validationErrorLabel(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)

            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.orange)
    }

    /// 섹션 헤더
    ///
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - icon: SF Symbol 아이콘 이름
    ///   - isOptional: 선택사항 여부 (기본값: false)
    /// - Returns: 헤더 뷰
    @ViewBuilder
    private func sectionHeader(
        title: String,
        icon: String,
        isOptional: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.blue)

            Text(title)
                .font(.headline)

            if isOptional {
                Text("(선택사항)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview
// Preview는 Core Data 엔티티 초기화 문제로 인해 임시 비활성화
// TODO: PreviewHelpers를 사용한 Preview 구현 필요

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// Goal은 Core Data 엔티티이므로 struct처럼 초기화 불가
// MockSetGoalUseCase에서 Core Data Goal을 반환해야 함
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("GoalSettingView Preview")
        .font(.headline)
        .padding()
}

// MARK: - Learning Notes

/// ## Complex Multi-Target Form Pattern
///
/// 여러 개의 독립적인 목표를 설정할 수 있는 복잡한 폼 UI 구현 패턴입니다.
///
/// ### 주요 구성 요소
///
/// 1. **Goal Type Selector**:
///    - Picker with Segmented Style
///    - 3가지 목표 유형 선택 (감량/유지/증량)
///
/// 2. **Multi-Target Toggles**:
///    - 각 목표를 독립적으로 활성화/비활성화
///    - 체중, 체지방률, 근육량 목표 선택
///
/// 3. **Conditional Input Fields**:
///    - 토글이 활성화된 경우에만 입력 필드 표시
///    - 애니메이션으로 자연스러운 전환
///
/// 4. **Real-time Validation**:
///    - 입력값 변경 시 즉시 검증
///    - 필드별 에러 메시지 표시
///
/// 5. **Estimated Completion Preview**:
///    - 입력값 기반 예상 달성일 자동 계산
///    - 실시간 업데이트
///
/// ### Toggle-based Conditional Form Pattern
///
/// **Toggle Header with Content**:
/// ```swift
/// VStack(alignment: .leading, spacing: 12) {
///     // 토글 헤더
///     HStack {
///         sectionHeader(title: "체중 목표", icon: "scalemass")
///         Spacer()
///         Toggle("", isOn: $viewModel.isWeightEnabled)
///             .labelsHidden()
///     }
///
///     // 조건부 콘텐츠
///     if viewModel.isWeightEnabled {
///         // 입력 필드들
///     }
/// }
/// .animation(.easeInOut(duration: 0.2), value: viewModel.isWeightEnabled)
/// ```
///
/// **애니메이션 적용**:
/// - `transition(.opacity.combined(with: .move(edge: .top)))`: 페이드 + 슬라이드 효과
/// - `animation(.easeInOut, value: isEnabled)`: 토글 상태 변경 시 애니메이션
///
/// ### Real-time Preview Pattern
///
/// **ViewModel의 Computed Property**:
/// ```swift
/// var estimatedCompletionDate: Date? {
///     // 활성화된 모든 목표의 달성일 계산
///     // 가장 늦은 날짜 반환
/// }
/// ```
///
/// **View의 자동 업데이트**:
/// ```swift
/// if let completionDate = viewModel.estimatedCompletionDate {
///     Text(completionDate, format: .dateTime.year().month().day())
///         .font(.system(size: 32, weight: .bold))
/// }
/// ```
///
/// @StateObject 덕분에:
/// - targetWeightInput 변경 → estimatedCompletionDate 재계산 → View 업데이트
/// - weeklyWeightRateInput 변경 → estimatedCompletionDate 재계산 → View 업데이트
///
/// ### Validation Error Display Pattern
///
/// **Field-level Validation**:
/// ```swift
/// TextField("목표 체중 (kg)", text: $viewModel.targetWeightInput)
///     .keyboardType(.decimalPad)
///
/// if let error = viewModel.validationErrors.targetWeight {
///     HStack {
///         Image(systemName: "exclamationmark.triangle.fill")
///         Text(error)
///     }
///     .foregroundStyle(.orange)
/// }
/// ```
///
/// **General Validation**:
/// ```swift
/// if let generalError = viewModel.validationErrors.general {
///     validationErrorLabel(generalError)
/// }
/// ```
///
/// ### Form Submission Pattern
///
/// **Save Button with Loading State**:
/// ```swift
/// Button(action: {
///     isCalorieFocused = false  // 키보드 숨기기
///     Task { await viewModel.save() }
/// }) {
///     HStack {
///         if viewModel.isSaving {
///             ProgressView().tint(.white)
///         } else {
///             Image(systemName: "checkmark.circle.fill")
///         }
///         Text(viewModel.isSaving ? "저장 중..." : "목표 저장")
///     }
/// }
/// .disabled(!viewModel.canSave)
/// ```
///
/// **Success Callback**:
/// ```swift
/// .onChange(of: viewModel.isSaveSuccess) { _, success in
///     if success {
///         onSaveSuccess?()
///         dismiss()
///     }
/// }
/// ```
///
/// ### Best Practices
///
/// 1. **Section-based Organization**:
///    - 각 목표를 독립적인 섹션으로 분리
///    - 명확한 시각적 구분
///
/// 2. **Progressive Disclosure**:
///    - 토글로 필요한 입력만 표시
///    - 복잡도 감소
///
/// 3. **Real-time Feedback**:
///    - 예상 달성일 즉시 계산
///    - 입력값 검증 즉시 표시
///
/// 4. **Clear Visual Hierarchy**:
///    - 섹션 헤더로 명확한 구분
///    - 아이콘으로 시각적 단서 제공
///
/// 5. **Keyboard Management**:
///    - @FocusState로 키보드 제어
///    - 저장 시 키보드 자동 숨김
///
/// 6. **Accessibility**:
///    - Toggle labels hidden but accessible
///    - Semantic colors for errors
///
/// 7. **Consistent Styling**:
///    - 모든 입력 필드 동일한 스타일
///    - 권장 범위 힌트 일관된 위치
///

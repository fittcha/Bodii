//
//  ExerciseInputView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Form Sheet Modal Pattern
// 모달 시트로 표시되는 입력 폼 구현
// 💡 Java 비교: Android의 BottomSheetDialogFragment + DataBinding과 유사

import SwiftUI

// MARK: - Exercise Input View

/// 운동 입력 모달 뷰
///
/// 새로운 운동 기록을 추가하기 위한 입력 폼을 제공합니다.
///
/// **주요 기능:**
/// - 운동 종류 선택 (8가지)
/// - 운동 시간 입력 (분)
/// - 운동 강도 선택 (저/중/고)
/// - 메모 입력 (선택사항)
/// - 실시간 칼로리 미리보기
/// - 저장/취소 액션
///
/// **실시간 미리보기:**
/// - 사용자가 입력을 변경할 때마다 예상 소모 칼로리가 자동으로 계산됩니다.
/// - ExerciseCalcService의 MET 공식을 사용합니다.
///
/// - Example:
/// ```swift
/// .sheet(isPresented: $isShowingAddSheet) {
///     ExerciseInputView(
///         viewModel: viewModel,
///         onSaveSuccess: {
///             isShowingAddSheet = false
///             listViewModel.refresh()
///         }
///     )
/// }
/// ```
struct ExerciseInputView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @Observable ViewModel (iOS 17+)
    // 이전: @StateObject, @ObservedObject 사용
    // 현재: var로 선언하면 자동으로 관찰됨
    // 💡 Java 비교: ViewModel + LiveData 자동 구독과 유사

    /// 뷰 모델
    var viewModel: ExerciseInputViewModel

    /// 저장 성공 시 실행할 콜백
    let onSaveSuccess: (() -> Void)?

    // MARK: - Environment

    // 📚 학습 포인트: Environment for Dismiss
    // SwiftUI 환경 변수로 모달 닫기 액션에 접근
    // 💡 Java 비교: Activity.finish() 또는 Fragment.dismiss()와 유사

    /// 모달 닫기 액션
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// 메모 입력 포커스 상태
    @FocusState private var isNoteFocused: Bool

    // MARK: - Initialization

    /// ExerciseInputView 초기화
    ///
    /// - Parameters:
    ///   - viewModel: 입력 폼 뷰 모델
    ///   - onSaveSuccess: 저장 성공 시 실행할 콜백 (옵셔널)
    init(
        viewModel: ExerciseInputViewModel,
        onSaveSuccess: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSaveSuccess = onSaveSuccess
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // 📚 학습 포인트: ScrollView for Keyboard Avoidance
            // ScrollView를 사용하면 키보드가 나타날 때 자동으로 스크롤
            // 💡 Java 비교: ScrollView + adjustResize와 유사
            ScrollView {
                VStack(spacing: 24) {
                    // 운동 종류 선택
                    exerciseTypeSection

                    // 운동 시간 입력
                    durationSection

                    // 운동 강도 선택
                    intensitySection

                    // 메모 입력 (선택사항)
                    noteSection

                    // 실시간 칼로리 미리보기
                    caloriePreviewCard

                    // 버튼들 (저장/취소)
                    actionButtons
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            // 📚 학습 포인트: Conditional Title
            // 편집 모드일 때는 "운동 수정", 추가 모드일 때는 "운동 추가" 표시
            .navigationTitle(viewModel.isEditMode ? "운동 수정" : "운동 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
            // 📚 학습 포인트: onChange for Side Effects
            // ViewModel의 상태 변경을 감지하여 부수 효과 실행
            // 💡 Java 비교: LiveData.observe()와 유사
            .onChange(of: viewModel.isSaveSuccess) { _, success in
                if success {
                    // 저장 성공 시
                    onSaveSuccess?()
                    dismiss()
                }
            }
            .alert("오류", isPresented: .constant(viewModel.hasError)) {
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

    /// 운동 종류 선택 섹션
    @ViewBuilder
    private var exerciseTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "운동 종류",
                icon: "figure.run"
            )

            ExerciseTypeGridView(
                selectedType: $viewModel.selectedExerciseType,
                onSelect: { type in
                    // 선택 시 추가 로직 (옵셔널)
                    // 현재는 @Binding으로 자동 업데이트되므로 별도 처리 불필요
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 운동 시간 입력 섹션
    @ViewBuilder
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "운동 시간",
                icon: "clock"
            )

            DurationInputView(
                duration: $viewModel.duration,
                onChange: { minutes in
                    // 시간 변경 시 추가 로직 (옵셔널)
                    // previewCalories가 자동으로 재계산됨
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 운동 강도 선택 섹션
    @ViewBuilder
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "운동 강도",
                icon: "bolt.fill"
            )

            IntensityPickerView(
                selectedIntensity: $viewModel.selectedIntensity,
                showMetMultiplier: true,
                onSelect: { intensity in
                    // 강도 변경 시 추가 로직 (옵셔널)
                    // previewCalories가 자동으로 재계산됨
                }
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 메모 입력 섹션
    @ViewBuilder
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "메모",
                icon: "note.text",
                isOptional: true
            )

            // 📚 학습 포인트: TextField with Focus State
            // @FocusState로 키보드 표시/숨김 제어
            // 💡 Java 비교: EditText.requestFocus()와 유사
            TextField("예: 아침 러닝, 체육관 운동 등", text: $viewModel.note, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .focused($isNoteFocused)
                .lineLimit(3...6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 실시간 칼로리 미리보기 카드
    ///
    /// 사용자가 입력을 변경할 때마다 자동으로 업데이트됩니다.
    @ViewBuilder
    private var caloriePreviewCard: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                Text("예상 소모 칼로리")
                    .font(.headline)

                Spacer()
            }

            // 📚 학습 포인트: Real-time Preview
            // ViewModel의 computed property가 자동으로 재계산
            // @Observable 덕분에 View가 자동으로 업데이트됨
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.previewCalories)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())

                Text("kcal")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.previewCalories)

            // 계산 정보 표시
            VStack(spacing: 4) {
                calculationDetailRow(
                    label: "운동",
                    value: viewModel.selectedExerciseType.displayName
                )

                calculationDetailRow(
                    label: "시간",
                    value: "\(viewModel.duration)분"
                )

                calculationDetailRow(
                    label: "강도",
                    value: viewModel.selectedIntensity.displayName
                )

                calculationDetailRow(
                    label: "MET",
                    value: String(format: "%.1f", viewModel.selectedExerciseType.baseMET * viewModel.selectedIntensity.metMultiplier)
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    /// 계산 상세 정보 행
    ///
    /// - Parameters:
    ///   - label: 레이블
    ///   - value: 값
    /// - Returns: 행 뷰
    @ViewBuilder
    private func calculationDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    /// 액션 버튼들 (저장)
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 저장 버튼
            Button(action: {
                // 키보드 숨기기
                isNoteFocused = false

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

                    Text(viewModel.isSaving ? "저장 중..." : "저장")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isFormValid ? Color.blue : Color.gray)
                )
                .foregroundStyle(.white)
            }
            .disabled(!viewModel.isFormValid || viewModel.isSaving)

            // 폼 검증 에러 메시지
            if let validationError = viewModel.durationValidationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
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

// 📚 학습 포인트: Core Data 엔티티와 Protocol 제약
// AddExerciseRecordUseCase가 ExerciseRecord (Core Data 엔티티)를 반환하므로
// Mock 구현에서 직접 초기화 불가
// TODO: Phase 7에서 UseCase를 protocol 기반으로 리팩토링 후 수정

#Preview("Placeholder") {
    Text("ExerciseInputView Preview")
        .font(.headline)
        .padding()
}

// MARK: - Learning Notes

/// ## Form Sheet Modal Pattern
///
/// 모달 시트로 표시되는 입력 폼은 SwiftUI에서 매우 일반적인 패턴입니다.
///
/// ### 주요 구성 요소
///
/// 1. **NavigationStack**:
///    - 모달 내부에서도 네비게이션 바 제공
///    - 제목, 툴바 버튼 표시
///
/// 2. **ScrollView**:
///    - 키보드가 나타날 때 자동 스크롤
///    - 긴 폼도 수용 가능
///
/// 3. **Section-based Layout**:
///    - 각 입력 필드를 섹션으로 분리
///    - 명확한 시각적 구분
///
/// 4. **Real-time Preview**:
///    - 사용자 입력에 즉각 반응
///    - 결과를 미리 보여주어 사용자 이해도 향상
///
/// ### Sheet Presentation Pattern
///
/// **부모 View (ExerciseListView)**:
/// ```swift
/// @State private var isShowingAddSheet = false
///
/// .toolbar {
///     ToolbarItem(placement: .topBarTrailing) {
///         Button {
///             isShowingAddSheet = true
///         } label: {
///             Image(systemName: "plus")
///         }
///     }
/// }
/// .sheet(isPresented: $isShowingAddSheet) {
///     ExerciseInputView(
///         viewModel: inputViewModel,
///         onSaveSuccess: {
///             isShowingAddSheet = false
///             listViewModel.refresh()
///         }
///     )
/// }
/// ```
///
/// **자식 View (ExerciseInputView)**:
/// ```swift
/// @Environment(\.dismiss) private var dismiss
///
/// Button("취소") {
///     dismiss()
/// }
///
/// .onChange(of: viewModel.isSaveSuccess) { _, success in
///     if success {
///         onSaveSuccess?()
///         dismiss()
///     }
/// }
/// ```
///
/// ### Real-time Calculation Pattern
///
/// **ViewModel의 Computed Property**:
/// ```swift
/// var previewCalories: Int32 {
///     ExerciseCalcService.calculateCalories(
///         exerciseType: selectedExerciseType,
///         duration: duration,
///         intensity: selectedIntensity,
///         weight: userWeight
///     )
/// }
/// ```
///
/// **View의 자동 업데이트**:
/// ```swift
/// Text("\(viewModel.previewCalories)")
///     .contentTransition(.numericText())
///     .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.previewCalories)
/// ```
///
/// @Observable 덕분에:
/// - selectedExerciseType 변경 → previewCalories 재계산 → View 업데이트
/// - duration 변경 → previewCalories 재계산 → View 업데이트
/// - selectedIntensity 변경 → previewCalories 재계산 → View 업데이트
///
/// ### Form Validation Pattern
///
/// **ViewModel의 Validation**:
/// ```swift
/// var isFormValid: Bool {
///     duration >= 1
/// }
///
/// var durationValidationError: String? {
///     if duration < 1 {
///         return "최소 1분 이상 입력해주세요"
///     }
///     return nil
/// }
/// ```
///
/// **View의 Validation Feedback**:
/// ```swift
/// Button("저장") {
///     Task { await viewModel.save() }
/// }
/// .disabled(!viewModel.isFormValid || viewModel.isSaving)
///
/// if let validationError = viewModel.durationValidationError {
///     Text(validationError)
///         .foregroundStyle(.orange)
/// }
/// ```
///
/// ### Loading State Pattern
///
/// **버튼에 로딩 상태 표시**:
/// ```swift
/// Button(action: { Task { await viewModel.save() } }) {
///     HStack {
///         if viewModel.isSaving {
///             ProgressView()
///                 .tint(.white)
///         } else {
///             Image(systemName: "checkmark.circle.fill")
///         }
///
///         Text(viewModel.isSaving ? "저장 중..." : "저장")
///     }
/// }
/// .disabled(viewModel.isSaving)
/// ```
///
/// ### Keyboard Management
///
/// **@FocusState for Keyboard Control**:
/// ```swift
/// @FocusState private var isNoteFocused: Bool
///
/// TextField("메모", text: $viewModel.note)
///     .focused($isNoteFocused)
///
/// Button("저장") {
///     isNoteFocused = false  // 키보드 숨기기
///     Task { await viewModel.save() }
/// }
/// ```
///
/// ### Component Integration
///
/// 이 View는 4개의 커스텀 컴포넌트를 통합합니다:
///
/// 1. **ExerciseTypeGridView**:
///    - 8가지 운동 종류 선택
///    - LazyVGrid 레이아웃
///
/// 2. **DurationInputView**:
///    - Quick Selection + Fine Adjustment
///    - 하이브리드 입력 방식
///
/// 3. **IntensityPickerView**:
///    - 3가지 강도 선택
///    - 세그먼트 컨트롤 스타일
///
/// 4. **TextField**:
///    - 선택적 메모 입력
///    - Multi-line 지원
///
/// 모든 컴포넌트가 @Binding을 통해 ViewModel의 상태와 연결되어
/// 실시간으로 칼로리 미리보기가 업데이트됩니다.
///
/// ### Error Handling
///
/// **Alert로 에러 표시**:
/// ```swift
/// .alert("오류", isPresented: .constant(viewModel.hasError)) {
///     Button("확인") {
///         viewModel.clearError()
///     }
/// } message: {
///     if let errorMessage = viewModel.errorMessage {
///         Text(errorMessage)
///     }
/// }
/// ```
///
/// ### Best Practices
///
/// 1. **Section-based Organization**:
///    - 각 섹션을 computed property로 분리
///    - 가독성과 유지보수성 향상
///
/// 2. **Real-time Feedback**:
///    - 사용자 입력에 즉각 반응하는 미리보기
///    - 사용자 신뢰도와 이해도 향상
///
/// 3. **Clear Visual Hierarchy**:
///    - 섹션 헤더로 명확한 구분
///    - 아이콘으로 시각적 단서 제공
///
/// 4. **Validation Feedback**:
///    - 버튼 disable로 즉각적인 피드백
///    - 에러 메시지로 명확한 가이드
///
/// 5. **Loading State**:
///    - 저장 중 상태 명확히 표시
///    - 중복 제출 방지
///
/// 6. **Keyboard Management**:
///    - @FocusState로 키보드 제어
///    - 저장 시 키보드 자동 숨김
///
/// 7. **Callback Pattern**:
///    - onSaveSuccess 콜백으로 부모 View와 통신
///    - 리스트 새로고침 등의 후속 작업 처리
///

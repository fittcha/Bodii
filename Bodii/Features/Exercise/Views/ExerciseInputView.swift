//
//  ExerciseInputView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import SwiftUI

/// 운동 입력 모달 뷰
///
/// 운동 기록을 추가하거나 수정하는 Sheet 모달 화면입니다.
///
/// **주요 기능**:
/// - 운동 종류 선택 그리드 (8개 운동 종류, 아이콘 + 라벨)
/// - 운동 시간 입력 (스테퍼 또는 텍스트 필드)
/// - 운동 강도 선택 (저/중/고강도, 시각적 인디케이터)
/// - 운동 날짜 선택 (DatePicker)
/// - 실시간 칼로리 소모 미리보기
/// - 저장/취소 버튼
/// - 폼 유효성 검증 피드백
/// - 수정 모드 지원 (기존 값 표시)
///
/// - Example:
/// ```swift
/// // 추가 모드
/// .sheet(isPresented: $showingInputSheet) {
///     ExerciseInputView(viewModel: viewModel)
/// }
///
/// // 수정 모드
/// .sheet(isPresented: $showingInputSheet) {
///     ExerciseInputView(viewModel: editViewModel)
/// }
/// ```
struct ExerciseInputView: View {

    // MARK: - Properties

    /// 운동 입력 ViewModel
    @ObservedObject var viewModel: ExerciseInputViewModel

    /// 모달 Dismiss 액션
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경색
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // 스크롤 콘텐츠
                ScrollView {
                    VStack(spacing: 24) {
                        // 운동 종류 선택
                        exerciseTypeSection

                        // 운동 시간 입력
                        durationSection

                        // 운동 강도 선택
                        intensitySection

                        // 운동 날짜 선택
                        dateSection

                        // 칼로리 미리보기
                        caloriePreviewSection
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 취소 버튼
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                // 저장 버튼
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.saveButtonTitle) {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert("오류", isPresented: $viewModel.showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
            }
            .task {
                viewModel.initialize()
            }
        }
    }

    // MARK: - Exercise Type Section

    /// 운동 종류 선택 섹션
    private var exerciseTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("운동 종류")
                .font(.headline)
                .foregroundStyle(.primary)

            // 운동 종류 그리드
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(ExerciseType.allCases) { exerciseType in
                    exerciseTypeButton(for: exerciseType)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    /// 운동 종류 버튼
    private func exerciseTypeButton(for type: ExerciseType) -> some View {
        let isSelected = viewModel.selectedExerciseType == type

        return Button(action: {
            viewModel.selectedExerciseType = type
        }) {
            VStack(spacing: 8) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(isSelected ? exerciseTypeColor(for: type) : Color(.systemGray5))
                        .frame(width: 50, height: 50)

                    Image(systemName: exerciseTypeIcon(for: type))
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                // 라벨
                Text(type.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? exerciseTypeColor(for: type) : .primary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duration Section

    /// 운동 시간 입력 섹션
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("운동 시간")
                .font(.headline)
                .foregroundStyle(.primary)

            // 시간 입력 필드
            HStack(spacing: 16) {
                // 텍스트 필드
                TextField("분", text: $viewModel.duration)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)

                Text("분")
                    .foregroundStyle(.secondary)

                Spacer()

                // 스테퍼
                HStack(spacing: 12) {
                    // -10분 버튼
                    Button(action: {
                        adjustDuration(by: -10)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .disabled(!canAdjustDuration(by: -10))

                    // +10분 버튼
                    Button(action: {
                        adjustDuration(by: 10)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            // 유효성 검증 메시지
            if let validationMessage = viewModel.durationValidationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Intensity Section

    /// 운동 강도 선택 섹션
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("운동 강도")
                .font(.headline)
                .foregroundStyle(.primary)

            // 강도 선택 버튼
            HStack(spacing: 12) {
                ForEach(Intensity.allCases) { intensity in
                    intensityButton(for: intensity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    /// 강도 선택 버튼
    private func intensityButton(for intensity: Intensity) -> some View {
        let isSelected = viewModel.selectedIntensity == intensity

        return Button(action: {
            viewModel.selectedIntensity = intensity
        }) {
            HStack(spacing: 8) {
                // 강도 아이콘
                Image(systemName: intensityIcon(for: intensity))
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : intensityColor(for: intensity))

                // 강도 이름
                Text(intensity.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? intensityColor(for: intensity) : Color(.systemGray6)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Section

    /// 운동 날짜 선택 섹션
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("운동 날짜")
                .font(.headline)
                .foregroundStyle(.primary)

            // 날짜 선택
            DatePicker(
                "날짜",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Calorie Preview Section

    /// 칼로리 미리보기 섹션
    private var caloriePreviewSection: some View {
        VStack(spacing: 12) {
            // 아이콘
            Image(systemName: "flame.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            // 칼로리 값
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(viewModel.caloriePreview)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)

                Text("kcal")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // 설명
            Text("예상 소모 칼로리")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.1),
                    Color.red.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    /// 운동 시간 조절
    private func adjustDuration(by amount: Int) {
        guard let currentDuration = Int(viewModel.duration) else {
            return
        }
        let newDuration = max(1, currentDuration + amount)
        viewModel.duration = String(newDuration)
    }

    /// 운동 시간 조절 가능 여부
    private func canAdjustDuration(by amount: Int) -> Bool {
        guard let currentDuration = Int(viewModel.duration) else {
            return false
        }
        let newDuration = currentDuration + amount
        return newDuration >= 1
    }

    /// 운동 종류별 아이콘
    private func exerciseTypeIcon(for type: ExerciseType) -> String {
        switch type {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .weight:
            return "dumbbell.fill"
        case .crossfit:
            return "figure.cross.training"
        case .yoga:
            return "figure.yoga"
        case .other:
            return "figure.mixed.cardio"
        }
    }

    /// 운동 종류별 색상
    private func exerciseTypeColor(for type: ExerciseType) -> Color {
        switch type {
        case .walking:
            return .green
        case .running:
            return .blue
        case .cycling:
            return .orange
        case .swimming:
            return .cyan
        case .weight:
            return .red
        case .crossfit:
            return .purple
        case .yoga:
            return .pink
        case .other:
            return .gray
        }
    }

    /// 강도별 아이콘
    private func intensityIcon(for intensity: Intensity) -> String {
        switch intensity {
        case .low:
            return "circle"
        case .medium:
            return "circle.lefthalf.filled"
        case .high:
            return "circle.fill"
        }
    }

    /// 강도별 색상
    private func intensityColor(for intensity: Intensity) -> Color {
        switch intensity {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    // Preview용 Mock 서비스
    let persistenceController = PersistenceController.preview
    let context = persistenceController.container.viewContext

    let exerciseCalcService = ExerciseCalcService()
    let exerciseRecordRepository = ExerciseRecordRepository(context: context)
    let dailyLogRepository = DailyLogRepository(context: context)
    let userRepository = UserRepository(context: context)

    let exerciseRecordService = ExerciseRecordService(
        exerciseCalcService: exerciseCalcService,
        exerciseRecordRepository: exerciseRecordRepository,
        dailyLogRepository: dailyLogRepository,
        userRepository: userRepository
    )

    let viewModel = ExerciseInputViewModel(
        exerciseRecordService: exerciseRecordService,
        userRepository: userRepository
    )

    return ExerciseInputView(viewModel: viewModel)
}

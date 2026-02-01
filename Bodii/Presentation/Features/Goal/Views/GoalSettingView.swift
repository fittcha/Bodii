//
//  GoalSettingView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import SwiftUI

// MARK: - Goal Setting View

/// 목표 설정 화면
///
/// 목표 유형, 목표값, 목표 달성일을 입력하면
/// 주간 변화율을 자동 계산하여 표시합니다.
struct GoalSettingView: View {

    // MARK: - Properties

    @StateObject var viewModel: GoalSettingViewModel

    /// 저장 성공 시 실행할 콜백
    let onSaveSuccess: (() -> Void)?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @FocusState private var isCalorieFocused: Bool

    // MARK: - Initialization

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
            ScrollView {
                VStack(spacing: 24) {
                    // 목표 유형 선택
                    goalTypeSection

                    // 목표 선택 안내
                    targetSelectionHint

                    // 목표 달성일 (유지 목표가 아닐 때만)
                    if !viewModel.isMaintainGoal {
                        targetDateSection
                    }

                    // 체중 목표 입력
                    weightTargetSection

                    // 체지방률 목표 입력
                    bodyFatTargetSection

                    // 근육량 목표 입력
                    muscleTargetSection

                    // 일일 칼로리 목표 (선택사항)
                    calorieTargetSection

                    // 변화율 경고
                    if !viewModel.rateWarnings.isEmpty {
                        rateWarningsSection
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
            .onChange(of: viewModel.isSaveSuccess) { _, success in
                if success {
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

    /// 목표 유형 선택 섹션
    @ViewBuilder
    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "목표 유형",
                icon: "target"
            )

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

    /// 목표 달성일 선택 섹션
    @ViewBuilder
    private var targetDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "목표 달성일",
                icon: "calendar"
            )

            DatePicker(
                "달성일",
                selection: $viewModel.targetDate,
                in: viewModel.minimumTargetDate...viewModel.maximumTargetDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .onChange(of: viewModel.targetDate) { _, _ in
                viewModel.validateInputs()
            }

            // 남은 기간 표시
            if let days = viewModel.daysToTarget, days > 0 {
                HStack {
                    Spacer()
                    Text("약 \(days)일 후 (\(days / 7)주)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // targetDate 검증 에러
            if let error = viewModel.validationErrors.targetDate {
                validationErrorLabel(error)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    /// 체중 목표 입력 섹션
    @ViewBuilder
    private var weightTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(
                    title: "체중 목표",
                    icon: "scalemass"
                )

                Spacer()

                Toggle("", isOn: $viewModel.isWeightEnabled)
                    .labelsHidden()
            }

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
                            .onChange(of: viewModel.targetWeightInput) { _, _ in
                                viewModel.validateInputs()
                            }

                        if let error = viewModel.validationErrors.targetWeight {
                            validationErrorLabel(error)
                        }
                    }

                    // 계산된 주간 변화율 (읽기 전용)
                    if !viewModel.isMaintainGoal {
                        calculatedRateRow(
                            label: "주간 변화율",
                            rate: viewModel.calculatedWeeklyWeightRate,
                            unit: "kg/주"
                        )
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
            HStack {
                sectionHeader(
                    title: "체지방률 목표",
                    icon: "percent"
                )

                Spacer()

                Toggle("", isOn: $viewModel.isBodyFatEnabled)
                    .labelsHidden()
            }

            if viewModel.isBodyFatEnabled {
                VStack(spacing: 16) {
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
                            .onChange(of: viewModel.targetBodyFatInput) { _, _ in
                                viewModel.validateInputs()
                            }

                        if let error = viewModel.validationErrors.targetBodyFat {
                            validationErrorLabel(error)
                        }
                    }

                    // 계산된 주간 변화율 (읽기 전용)
                    if !viewModel.isMaintainGoal {
                        calculatedRateRow(
                            label: "주간 변화율",
                            rate: viewModel.calculatedWeeklyBodyFatRate,
                            unit: "%/주"
                        )
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
            HStack {
                sectionHeader(
                    title: "근육량 목표",
                    icon: "figure.strengthtraining.traditional"
                )

                Spacer()

                Toggle("", isOn: $viewModel.isMuscleEnabled)
                    .labelsHidden()
            }

            if viewModel.isMuscleEnabled {
                VStack(spacing: 16) {
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
                            .onChange(of: viewModel.targetMuscleInput) { _, _ in
                                viewModel.validateInputs()
                            }

                        if let error = viewModel.validationErrors.targetMuscle {
                            validationErrorLabel(error)
                        }
                    }

                    // 계산된 주간 변화율 (읽기 전용)
                    if !viewModel.isMaintainGoal {
                        calculatedRateRow(
                            label: "주간 변화율",
                            rate: viewModel.calculatedWeeklyMuscleRate,
                            unit: "kg/주"
                        )
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

    /// 비현실적 변화율 경고 섹션
    @ViewBuilder
    private var rateWarningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("변화율 경고")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
            }

            ForEach(viewModel.rateWarnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Text("*")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("경고가 있어도 저장할 수 있지만, 건강을 위해 달성일을 조정하는 것을 권장합니다.")
                .font(.caption2)
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

    /// 액션 버튼들 (저장)
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                isCalorieFocused = false
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

    // MARK: - Helper Views

    /// 계산된 변화율 표시 행 (읽기 전용)
    @ViewBuilder
    private func calculatedRateRow(label: String, rate: Decimal?, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let rate = rate {
                let formatted = formatDecimal(rate)
                Text("\(formatted) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(rateColor(for: rate))
            } else {
                Text("-- \(unit)")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    /// 검증 에러 레이블
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

    // MARK: - Helpers

    /// Decimal 포맷 (소수점 2자리)
    private func formatDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }

    /// 변화율에 따른 색상
    private func rateColor(for rate: Decimal) -> Color {
        if rate > 0 {
            return .green
        } else if rate < 0 {
            return .red
        } else {
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview("Placeholder") {
    Text("GoalSettingView Preview")
        .font(.headline)
        .padding()
}

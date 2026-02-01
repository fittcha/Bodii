//
//  CustomFoodEditView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-31.
//

import SwiftUI

/// 커스텀 음식 수정 화면
struct CustomFoodEditView: View {

    @ObservedObject var viewModel: CustomFoodEditViewModel
    let onSave: () -> Void

    @State private var showingSaveSuccess = false
    @FocusState private var focusedField: EditField?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    basicInfoSection
                    macroNutrientsSection
                    optionalNutrientsSection
                    saveButton
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("커스텀 음식 수정")
        .navigationBarTitleDisplayMode(.inline)
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") { viewModel.errorMessage = nil }
        } message: {
            if let msg = viewModel.errorMessage { Text(msg) }
        }
        .alert("수정 완료", isPresented: $showingSaveSuccess) {
            Button("확인") { onSave() }
        } message: {
            Text("음식 정보가 수정되었습니다.")
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("기본 정보")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                editField(title: "음식명", placeholder: "예: 수제 샐러드", text: $viewModel.foodName,
                          isRequired: true, error: viewModel.validationErrors.foodName, field: .foodName)
                Divider().padding(.horizontal, 16)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        requiredLabel("1회 제공량")
                        TextField("예: 250", text: $viewModel.servingSize)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($focusedField, equals: .servingSize)
                        if let err = viewModel.validationErrors.servingSize {
                            Text(err).font(.caption).foregroundColor(.red)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("단위").font(.subheadline)
                        TextField("예: 1인분", text: $viewModel.servingUnit)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($focusedField, equals: .servingUnit)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var macroNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("영양 정보")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                editField(title: "칼로리", placeholder: "예: 350", text: $viewModel.calories,
                          unit: "kcal", isRequired: true, error: viewModel.validationErrors.calories,
                          field: .calories, keyboardType: .numberPad)
                Divider().padding(.horizontal, 16)
                editField(title: "탄수화물", placeholder: "예: 45", text: $viewModel.carbohydrates,
                          unit: "g", field: .carbohydrates, keyboardType: .decimalPad)
                Divider().padding(.horizontal, 16)
                editField(title: "단백질", placeholder: "예: 20", text: $viewModel.protein,
                          unit: "g", field: .protein, keyboardType: .decimalPad)
                Divider().padding(.horizontal, 16)
                editField(title: "지방", placeholder: "예: 15", text: $viewModel.fat,
                          unit: "g", field: .fat, keyboardType: .decimalPad)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var optionalNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("추가 정보").font(.headline)
                Text("선택사항").font(.caption).foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(.systemGray5)).cornerRadius(6)
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                editField(title: "나트륨", placeholder: "예: 500", text: $viewModel.sodium,
                          unit: "mg", field: .sodium, keyboardType: .decimalPad)
                Divider().padding(.horizontal, 16)
                editField(title: "식이섬유", placeholder: "예: 5", text: $viewModel.fiber,
                          unit: "g", field: .fiber, keyboardType: .decimalPad)
                Divider().padding(.horizontal, 16)
                editField(title: "당류", placeholder: "예: 10", text: $viewModel.sugar,
                          unit: "g", field: .sugar, keyboardType: .decimalPad)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var saveButton: some View {
        Button(action: {
            focusedField = nil
            Task {
                do {
                    try await viewModel.saveChanges()
                    showingSaveSuccess = true
                } catch { }
            }
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill").font(.title3)
                    Text("수정 저장").font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSave ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSave)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func editField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        unit: String? = nil,
        isRequired: Bool = false,
        error: String? = nil,
        field: EditField,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title).font(.subheadline)
                if isRequired { Text("*").font(.subheadline).foregroundColor(.red) }
                Spacer()
                if let unit = unit { Text(unit).font(.caption).foregroundColor(.secondary) }
            }
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($focusedField, equals: field)
            if let error = error { Text(error).font(.caption).foregroundColor(.red) }
        }
        .padding(.horizontal, 16)
    }

    private func requiredLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.subheadline)
            Text("*").font(.subheadline).foregroundColor(.red)
        }
    }
}

// MARK: - Focus Field

private enum EditField: Hashable {
    case foodName, servingSize, servingUnit, calories, carbohydrates, protein, fat, sodium, fiber, sugar
}

// MARK: - Preview

#Preview {
    Text("CustomFoodEditView Preview").padding()
}

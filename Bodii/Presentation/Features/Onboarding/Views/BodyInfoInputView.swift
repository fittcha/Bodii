//
//  BodyInfoInputView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 세 번째 화면: 신체 정보 입력
/// 키, 몸무게 입력
struct BodyInfoInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case height
        case weight
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 타이틀
                VStack(spacing: 8) {
                    Text("신체 정보를 입력해주세요")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("BMR(기초대사량) 계산에 사용됩니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                Spacer().frame(height: 40)

                // 키 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("키")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("170", text: $viewModel.height)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .height)

                        Text("cm")
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                    }
                }

                // 몸무게 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("몸무게")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("70", text: $viewModel.weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .weight)

                        Text("kg")
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                    }
                }

                // 유효성 안내
                if !viewModel.height.isEmpty || !viewModel.weight.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if let heightValue = Double(viewModel.height),
                           (heightValue < 100 || heightValue > 250) {
                            Text("키는 100~250cm 사이로 입력해주세요")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if !viewModel.height.isEmpty,
                                  Double(viewModel.height) == nil {
                            Text("키에 숫자만 입력해주세요")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        if let weightValue = Double(viewModel.weight),
                           (weightValue < 20 || weightValue > 300) {
                            Text("몸무게는 20~300kg 사이로 입력해주세요")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if !viewModel.weight.isEmpty,
                                  Double(viewModel.weight) == nil {
                            Text("몸무게에 숫자만 입력해주세요")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Spacer()

                // 네비게이션 버튼
                HStack(spacing: 16) {
                    OnboardingButton(title: "이전", style: .secondary) {
                        viewModel.goToPrevious()
                    }

                    OnboardingButton(
                        title: "다음",
                        isEnabled: viewModel.isBodyInfoValid
                    ) {
                        viewModel.goToNext()
                    }
                }
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    focusedField = nil
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyInfoInputView(viewModel: OnboardingViewModel.bodyInfoPreview)
}

#Preview("With Values") {
    let viewModel = OnboardingViewModel()
    viewModel.height = "175"
    viewModel.weight = "70"
    return BodyInfoInputView(viewModel: viewModel)
}

#Preview("Invalid Values") {
    let viewModel = OnboardingViewModel()
    viewModel.height = "50"
    viewModel.weight = "10"
    return BodyInfoInputView(viewModel: viewModel)
}

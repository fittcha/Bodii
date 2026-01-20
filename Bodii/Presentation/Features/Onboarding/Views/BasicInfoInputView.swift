//
//  BasicInfoInputView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 두 번째 화면: 기본 정보 입력
/// 이름, 성별, 생년월일 입력
struct BasicInfoInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 타이틀
                VStack(spacing: 8) {
                    Text("기본 정보를 입력해주세요")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("정확한 대사량 계산을 위해 필요합니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                Spacer().frame(height: 20)

                // 이름 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("이름")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("이름을 입력하세요", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                }

                // 성별 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("성별")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        GenderButton(
                            title: "남성",
                            icon: "figure.stand",
                            isSelected: viewModel.gender == .male
                        ) {
                            viewModel.gender = .male
                        }

                        GenderButton(
                            title: "여성",
                            icon: "figure.stand.dress",
                            isSelected: viewModel.gender == .female
                        ) {
                            viewModel.gender = .female
                        }
                    }
                }

                // 생년월일 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("생년월일")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        "",
                        selection: $viewModel.birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                }

                // 유효성 안내
                if !viewModel.name.isEmpty && !viewModel.isBasicInfoValid {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.name.trimmingCharacters(in: .whitespaces).count > 20 {
                            Text("이름은 20자 이하로 입력해주세요")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        if viewModel.age < 10 || viewModel.age > 120 {
                            Text("올바른 생년월일을 선택해주세요")
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
                        isEnabled: viewModel.isBasicInfoValid
                    ) {
                        viewModel.goToNext()
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Preview

#Preview {
    BasicInfoInputView(viewModel: OnboardingViewModel.basicInfoPreview)
}

#Preview("With Name") {
    let viewModel = OnboardingViewModel()
    viewModel.name = "홍길동"
    return BasicInfoInputView(viewModel: viewModel)
}

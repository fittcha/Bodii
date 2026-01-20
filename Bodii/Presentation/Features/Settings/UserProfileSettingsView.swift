//
//  UserProfileSettingsView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

// MARK: - UserProfileSettingsView

/// 사용자 프로필 설정 화면
/// BMR/TDEE 계산에 필요한 기본 정보(키, 생년월일, 성별, 활동 수준)를 입력/수정합니다.
struct UserProfileSettingsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = UserProfileSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 신체 정보 섹션
                bodyInfoSection

                // 활동 수준 섹션
                activityLevelSection

                // 계산된 정보 섹션
                calculatedInfoSection
            }
            .navigationTitle("프로필 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await viewModel.saveUserProfile()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                viewModel.loadUserProfile()
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay {
                if let successMessage = viewModel.successMessage {
                    VStack {
                        Spacer()
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.9))
                            .clipShape(Capsule())
                            .padding(.bottom, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.successMessage)
                }
            }
        }
    }

    // MARK: - View Components

    /// 신체 정보 섹션
    @ViewBuilder
    private var bodyInfoSection: some View {
        Section {
            // 키 입력
            HStack {
                Text("키")
                Spacer()
                TextField("170", text: $viewModel.height)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("cm")
                    .foregroundStyle(.secondary)
            }

            // 생년월일
            DatePicker(
                "생년월일",
                selection: $viewModel.birthDate,
                in: ...Date(),
                displayedComponents: .date
            )

            // 성별
            Picker("성별", selection: $viewModel.gender) {
                Text("남성").tag(Gender.male)
                Text("여성").tag(Gender.female)
            }
        } header: {
            Text("신체 정보")
        } footer: {
            Text("BMR(기초대사량) 계산에 필요한 정보입니다.")
        }
    }

    /// 활동 수준 섹션
    @ViewBuilder
    private var activityLevelSection: some View {
        Section {
            Picker("활동 수준", selection: $viewModel.activityLevel) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    VStack(alignment: .leading) {
                        Text(level.displayName)
                    }
                    .tag(level)
                }
            }
            .pickerStyle(.navigationLink)

            // 활동 수준 설명
            VStack(alignment: .leading, spacing: 8) {
                activityLevelDescription
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        } header: {
            Text("활동 수준")
        } footer: {
            Text("TDEE(총 일일 에너지 소비량) 계산에 사용됩니다.")
        }
    }

    /// 활동 수준 설명
    @ViewBuilder
    private var activityLevelDescription: some View {
        switch viewModel.activityLevel {
        case .sedentary:
            Text("거의 운동 안함 (사무직, 재택근무)")
        case .lightlyActive:
            Text("가벼운 운동 (주 1-3회)")
        case .moderatelyActive:
            Text("보통 운동 (주 3-5회)")
        case .veryActive:
            Text("활발한 운동 (주 6-7회)")
        case .extraActive:
            Text("매우 활발 (운동선수, 육체 노동)")
        }
    }

    /// 계산된 정보 섹션
    @ViewBuilder
    private var calculatedInfoSection: some View {
        if viewModel.isLoaded {
            Section {
                HStack {
                    Text("나이")
                    Spacer()
                    Text("\(viewModel.age)세")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("활동 계수")
                    Spacer()
                    Text(String(format: "%.2f", viewModel.activityLevel.multiplier))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("계산 정보")
            }
        }
    }
}

// MARK: - ActivityLevel Korean Extension

extension ActivityLevel {
    /// 한국어 표시 이름
    var koreanDisplayName: String {
        switch self {
        case .sedentary:
            return "비활동적"
        case .lightlyActive:
            return "가벼운 활동"
        case .moderatelyActive:
            return "보통 활동"
        case .veryActive:
            return "활발한 활동"
        case .extraActive:
            return "매우 활발"
        }
    }
}

// MARK: - Preview

#Preview {
    UserProfileSettingsView()
}

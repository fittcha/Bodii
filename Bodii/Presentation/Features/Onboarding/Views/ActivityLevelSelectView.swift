//
//  ActivityLevelSelectView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 네 번째 화면: 활동 수준 선택
/// 5단계 활동 수준 중 하나를 선택
struct ActivityLevelSelectView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 타이틀
            VStack(spacing: 8) {
                Text("활동 수준을 선택해주세요")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("TDEE(일일 소비 칼로리) 계산에 사용됩니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            Spacer().frame(height: 20)

            // 활동 수준 카드들
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.activityLevel = level
                            }
                        }
                    }
                }
            }

            Spacer()

            // 네비게이션 버튼
            HStack(spacing: 16) {
                OnboardingButton(title: "이전", style: .secondary) {
                    viewModel.goToPrevious()
                }

                OnboardingButton(title: "완료") {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(24)
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ActivityLevelSelectView(viewModel: OnboardingViewModel.activityLevelPreview)
}

#Preview("Very Active Selected") {
    let viewModel = OnboardingViewModel()
    viewModel.activityLevel = .veryActive
    return ActivityLevelSelectView(viewModel: viewModel)
}

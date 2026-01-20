//
//  OnboardingContainerView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 컨테이너 뷰
/// TabView를 사용한 페이지 전환
///
/// **플로우**:
/// 1. Welcome - 앱 소개
/// 2. BasicInfo - 이름, 성별, 생년월일
/// 3. BodyInfo - 키, 몸무게
/// 4. ActivityLevel - 활동 수준 선택
/// 5. Complete - BMR/TDEE 결과 표시
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppStateService

    var body: some View {
        VStack(spacing: 0) {
            // 진행 상태 바 (welcome과 complete에서는 숨김)
            if viewModel.currentStep != .welcome && viewModel.currentStep != .complete {
                OnboardingProgressBar(progress: viewModel.progress)
            }

            // 페이지 컨텐츠
            TabView(selection: $viewModel.currentStep) {
                WelcomeView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.welcome)

                BasicInfoInputView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.basicInfo)

                BodyInfoInputView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.bodyInfo)

                ActivityLevelSelectView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.activityLevel)

                OnboardingCompleteView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)
            .interactiveDismissDisabled()
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Preview

#Preview("Welcome") {
    OnboardingContainerView()
        .environmentObject(AppStateService.needsOnboarding)
}

#Preview("Basic Info") {
    let viewModel = OnboardingViewModel()
    viewModel.currentStep = .basicInfo

    return VStack(spacing: 0) {
        OnboardingProgressBar(progress: 0.25)
        BasicInfoInputView(viewModel: viewModel)
    }
    .environmentObject(AppStateService.needsOnboarding)
}

#Preview("Complete") {
    OnboardingCompleteView(viewModel: OnboardingViewModel.completedPreview)
        .environmentObject(AppStateService.needsOnboarding)
}

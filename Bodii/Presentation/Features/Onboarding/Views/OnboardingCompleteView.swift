//
//  OnboardingCompleteView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 마지막 화면: 완료
/// BMR/TDEE 계산 결과를 표시하고 시작 버튼 제공
struct OnboardingCompleteView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppStateService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 완료 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            // 타이틀
            Text("설정 완료!")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 환영 메시지
            if !viewModel.name.isEmpty {
                Text("\(viewModel.name)님, 준비되었습니다")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // 계산된 대사량 표시
            VStack(spacing: 16) {
                MetabolismResultCard(
                    title: "기초대사량 (BMR)",
                    value: viewModel.calculatedBMR ?? 0,
                    unit: "kcal",
                    description: "아무것도 안 해도 소비되는 칼로리"
                )

                MetabolismResultCard(
                    title: "일일 소비 칼로리 (TDEE)",
                    value: viewModel.calculatedTDEE ?? 0,
                    unit: "kcal",
                    description: "하루 동안 소비되는 총 칼로리"
                )
            }

            Spacer()

            // 시작하기 버튼
            OnboardingButton(title: "Bodii 시작하기") {
                appState.completeOnboarding()
            }
        }
        .padding(24)
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompleteView(viewModel: OnboardingViewModel.completedPreview)
        .environmentObject(AppStateService.needsOnboarding)
}

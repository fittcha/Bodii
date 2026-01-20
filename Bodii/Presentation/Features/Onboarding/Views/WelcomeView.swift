//
//  WelcomeView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 첫 번째 화면: 앱 소개
/// 앱 로고와 환영 메시지를 표시하고 시작하기 버튼 제공
struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // 앱 로고
            VStack(spacing: 16) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Bodii")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            // 타이틀
            VStack(spacing: 12) {
                Text("Bodii에 오신 것을")
                    .font(.title)
                    .fontWeight(.bold)

                Text("환영합니다")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // 설명
            VStack(spacing: 8) {
                Text("내 몸 관리 에이전트")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("체성분, 식단, 운동을 한 곳에서 관리하세요")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            // 시작하기 버튼
            OnboardingButton(title: "시작하기") {
                viewModel.goToNext()
            }
        }
        .padding(24)
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(viewModel: OnboardingViewModel())
}

//
//  ContentView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Tab-based Navigation
// SwiftUI의 탭 기반 네비게이션 컨테이너
// 💡 Java 비교: Android의 BottomNavigationView와 유사

import SwiftUI

// MARK: - Content View

/// 앱의 루트 뷰 - 메인 탭 바 UI
struct ContentView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @State
    // View 내부에서 변경 가능한 상태를 관리
    // 탭 선택 상태를 추적하여 현재 활성 탭을 기억
    @State private var selectedTab: Tab = .dashboard

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: Tab Navigation with selection binding
        // selection 바인딩을 통해 프로그래밍적으로 탭 전환 가능
        // 💡 Java 비교: ViewPager + TabLayout 조합과 유사
        TabView(selection: $selectedTab) {
            dashboardTab
            bodyTab
            dietTab
            exerciseTab
            sleepTab
            settingsTab
        }
    }

    // MARK: - Tab Views

    private var dashboardTab: some View {
        // 📚 학습 포인트: tabItem modifier
        // 탭 바에 표시될 아이콘과 텍스트 정의
        // TODO: Phase 6 (6.1, 6.2) - DIContainer에서 ViewModel 주입받도록 변경
        // 현재는 임시로 직접 생성하여 사용
        let bodyRepository = BodyRepository()
        let metabolismViewModel = MetabolismViewModel(bodyRepository: bodyRepository)

        return DashboardView(
            metabolismViewModel: metabolismViewModel,
            onNavigateToBody: {
                // 📚 학습 포인트: Tab Navigation
                // 대사율 카드 탭 시 체성분 탭으로 이동
                selectedTab = .body
            }
        )
        .tabItem {
            Label("대시보드", systemImage: "chart.bar.fill")
        }
        .tag(Tab.dashboard)
    }

    private var bodyTab: some View {
        // 📚 학습 포인트: DIContainer Factory Pattern
        // DIContainer의 factory 메서드를 통해 ViewModel 생성
        // TODO: Phase 7 - UserProfile을 실제 저장된 사용자 데이터로 교체
        // 현재는 임시로 sample 데이터 사용
        let viewModel = DIContainer.shared.makeBodyCompositionViewModel(
            userProfile: UserProfile.sample
        )

        return BodyCompositionView(viewModel: viewModel)
            .tabItem {
                Label("체성분", systemImage: "figure.stand")
            }
            .tag(Tab.body)
    }

    private var dietTab: some View {
        PlaceholderView(title: "식단", systemImage: "fork.knife")
            .tabItem {
                Label("식단", systemImage: "fork.knife")
            }
            .tag(Tab.diet)
    }

    private var exerciseTab: some View {
        PlaceholderView(title: "운동", systemImage: "figure.run")
            .tabItem {
                Label("운동", systemImage: "figure.run")
            }
            .tag(Tab.exercise)
    }

    private var sleepTab: some View {
        PlaceholderView(title: "수면", systemImage: "moon.zzz.fill")
            .tabItem {
                Label("수면", systemImage: "moon.zzz.fill")
            }
            .tag(Tab.sleep)
    }

    private var settingsTab: some View {
        PlaceholderView(title: "설정", systemImage: "gearshape.fill")
            .tabItem {
                Label("설정", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
    }
}

// MARK: - Tab Enum

/// 탭 식별자
// 📚 학습 포인트: Hashable protocol
// 탭 선택에서 각 탭을 고유하게 식별하기 위해 필요
private enum Tab: Hashable {
    case dashboard
    case body
    case diet
    case exercise
    case sleep
    case settings
}

// MARK: - Placeholder View

/// 각 탭의 플레이스홀더 뷰
// 📚 학습 포인트: 재사용 가능한 컴포넌트
// 실제 기능 구현 전 UI 스캐폴딩에 사용
private struct PlaceholderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title)
                .fontWeight(.semibold)

            Text("준비 중입니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

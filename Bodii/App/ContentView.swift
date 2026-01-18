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

    // 📚 학습 포인트: @StateObject for Sleep Prompt Manager
    // 수면 기록 프롬프트 관리자
    // View의 생명주기 동안 유지되는 ObservableObject
    // 💡 Java 비교: ViewModel과 유사한 역할
    @StateObject private var sleepPromptManager = DIContainer.shared.makeSleepPromptManager()

    // 📚 학습 포인트: @Environment(\.scenePhase)
    // 앱의 생명주기 상태를 추적 (active, inactive, background)
    // 앱이 포그라운드로 돌아올 때 수면 프롬프트 체크
    // 💡 Java 비교: Android의 Lifecycle.State와 유사
    @Environment(\.scenePhase) private var scenePhase

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
        // 📚 학습 포인트: Sheet Presentation for Sleep Prompt
        // 아침 수면 기록 프롬프트를 모달 시트로 표시
        // shouldShowPrompt가 true일 때 자동으로 표시됨
        // 💡 Java 비교: BottomSheetDialog 표시와 유사
        .sheet(isPresented: $sleepPromptManager.shouldShowPrompt) {
            // 📚 학습 포인트: Sleep Input Sheet Integration
            // DIContainer를 통해 ViewModel 생성하고 주입
            // TODO: Phase 7 - UserProfile.sample 대신 실제 사용자 데이터 사용
            let viewModel = DIContainer.shared.makeSleepInputViewModel(
                userId: UserProfile.sample.id,
                defaultHours: 7,
                defaultMinutes: 0
            )

            SleepInputSheet(
                viewModel: viewModel,
                canSkip: !sleepPromptManager.isForceEntry,
                onSkip: {
                    // 📚 학습 포인트: Skip Count Management
                    // 사용자가 건너뛰기를 선택하면 횟수 증가
                    // 3회 건너뛰기 후 강제 입력 모드 활성화
                    sleepPromptManager.incrementSkipCount()
                }
            )
        }
        // 📚 학습 포인트: onAppear Lifecycle Hook
        // View가 처음 나타날 때 수면 프롬프트 체크
        // 💡 Java 비교: onCreate() 또는 onResume()과 유사
        .onAppear {
            Task {
                await sleepPromptManager.checkShouldShow()
            }
        }
        // 📚 학습 포인트: Scene Phase Observer
        // 앱이 백그라운드에서 포그라운드로 돌아올 때 체크
        // active 상태가 되면 수면 프롬프트를 다시 확인
        // 💡 Java 비교: onResume() 라이프사이클 콜백과 유사
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // 📚 학습 포인트: Async Task in onChange
                // 앱이 활성화될 때마다 프롬프트 조건 재확인
                Task {
                    await sleepPromptManager.checkShouldShow()
                }
            }
        }
    }

    // MARK: - Tab Views

    private var dashboardTab: some View {
        // 📚 학습 포인트: DIContainer Factory Pattern
        // DIContainer의 factory 메서드를 통해 DashboardViewModel 생성
        // TODO: Phase 7 - UserProfile을 실제 저장된 사용자 데이터로 교체
        // 현재는 임시로 sample 데이터 사용
        let viewModel = DIContainer.shared.makeDashboardViewModel(
            userId: UserProfile.sample.id
        )

        return DashboardView(
            viewModel: viewModel,
            onNavigateToDiet: {
                // 📚 학습 포인트: Tab Navigation from Quick-Add
                // 음식 추가 버튼 탭 시 식단 탭으로 이동
                selectedTab = .diet
            },
            onNavigateToExercise: {
                // 📚 학습 포인트: Tab Navigation from Quick-Add
                // 운동 추가 버튼 탭 시 운동 탭으로 이동
                selectedTab = .exercise
            },
            onNavigateToBody: {
                // 📚 학습 포인트: Tab Navigation from Quick-Add
                // 체성분 기록 버튼 탭 시 체성분 탭으로 이동
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
        DietTabView()
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
        // 📚 학습 포인트: Sleep Container View
        // SleepTabView는 자체적으로 NavigationStack을 포함하고 있음
        // DIContainer를 통해 ViewModel 생성 및 의존성 주입
        // 💡 Java 비교: Android의 Fragment Container와 유사
        SleepTabView(container: DIContainer.shared)
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

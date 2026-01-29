//
//  AppRootView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-28.
//

import SwiftUI

// MARK: - App Root State

/// 앱의 현재 상태를 나타내는 열거형
enum AppRootState {
    /// 로딩 중 (사용자 정보 확인)
    case loading
    /// 온보딩 필요 (신규 사용자)
    case onboarding
    /// 수면 입력 필요 (새벽 2시 이후 첫 실행)
    case sleepInput
    /// 메인 화면
    case main
}

// MARK: - App Root View

/// 앱의 최상위 뷰 - 앱 상태에 따라 적절한 화면을 표시
///
/// **앱 진입 흐름**:
/// 1. 로딩 → 사용자 정보 확인
/// 2. 온보딩 미완료 → OnboardingContainerView
/// 3. 새벽 2시~정오, 오늘 수면 미입력 → 수면 입력 팝업
/// 4. 그 외 → 메인 화면 (ContentView)
struct AppRootView: View {

    // MARK: - Properties

    @StateObject private var rootStateManager = AppRootStateManager()
    @EnvironmentObject var appState: AppStateService
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    var body: some View {
        Group {
            switch rootStateManager.currentState {
            case .loading:
                loadingView

            case .onboarding:
                OnboardingContainerView()

            case .sleepInput:
                sleepInputOverlay

            case .main:
                ContentView()
            }
        }
        .onAppear {
            rootStateManager.checkInitialState(isOnboardingComplete: appState.isOnboardingComplete)
        }
        .onChange(of: appState.isOnboardingComplete) { _, isComplete in
            if isComplete {
                rootStateManager.handleOnboardingComplete()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && rootStateManager.currentState == .main {
                // 앱이 포그라운드로 돌아올 때 수면 입력 필요 여부 재확인
                rootStateManager.checkSleepInputNeeded()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("로딩 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var sleepInputOverlay: some View {
        ZStack {
            // 배경으로 메인 화면 (블러 처리)
            ContentView()
                .blur(radius: 10)
                .disabled(true)

            // 어두운 오버레이
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // 수면 입력 시트
            VStack {
                Spacer()

                SleepInputSheet(
                    viewModel: DIContainer.shared.makeSleepInputViewModel(
                        userId: rootStateManager.currentUserId ?? UUID(),
                        defaultHours: 7,
                        defaultMinutes: 0
                    ),
                    canSkip: !rootStateManager.isForceEntry,
                    onSkip: {
                        rootStateManager.skipSleepInput()
                    },
                    onSave: {
                        rootStateManager.completeSleepInput()
                    }
                )
                .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                .background(Color(.systemBackground))
                .cornerRadius(20, corners: [.topLeft, .topRight])
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - App Root State Manager

/// 앱 루트 상태를 관리하는 ObservableObject
@MainActor
final class AppRootStateManager: ObservableObject {

    // MARK: - Published Properties

    @Published var currentState: AppRootState = .loading
    @Published var currentUserId: UUID?
    @Published var isForceEntry: Bool = false

    // MARK: - Private Properties

    private let userRepository = DIContainer.shared.userRepository
    private var skipCount: Int = 0
    private let maxSkipCount = 3

    // MARK: - UserDefaults Keys

    private let lastSleepCheckDateKey = "lastSleepCheckDate"
    private let sleepSkipCountKey = "sleepSkipCount"

    // MARK: - Public Methods

    /// 앱 시작 시 초기 상태 확인
    func checkInitialState(isOnboardingComplete: Bool) {
        // 온보딩 완료 여부 먼저 확인
        guard isOnboardingComplete else {
            currentState = .onboarding
            return
        }

        // 사용자 ID 로드
        loadCurrentUserId()

        // 수면 입력 필요 여부 확인
        checkSleepInputNeeded()
    }

    /// 온보딩 완료 후 처리
    func handleOnboardingComplete() {
        // 사용자 ID 로드
        loadCurrentUserId()

        // 수면 입력 필요 여부 확인
        checkSleepInputNeeded()
    }

    /// 수면 입력 건너뛰기
    func skipSleepInput() {
        skipCount += 1
        UserDefaults.standard.set(skipCount, forKey: sleepSkipCountKey)

        if skipCount >= maxSkipCount {
            // 3회 이상 건너뛰기 시 강제 입력 모드
            isForceEntry = true
        } else {
            // 오늘 체크 완료로 표시하고 메인으로 이동
            markTodayChecked()
            currentState = .main
        }
    }

    /// 수면 입력 완료
    func completeSleepInput() {
        // 건너뛰기 횟수 초기화
        skipCount = 0
        UserDefaults.standard.set(0, forKey: sleepSkipCountKey)
        isForceEntry = false

        // 오늘 체크 완료로 표시
        markTodayChecked()

        // 메인으로 이동
        currentState = .main
    }

    /// 수면 입력 필요 여부 확인
    func checkSleepInputNeeded() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // 새벽 2시 ~ 정오(12시) 사이인지 확인
        let isInSleepPromptWindow = hour >= 2 && hour < 12

        guard isInSleepPromptWindow else {
            currentState = .main
            return
        }

        // 오늘 이미 체크했는지 확인
        if let lastCheckDate = UserDefaults.standard.object(forKey: lastSleepCheckDateKey) as? Date {
            let logicalToday = DateUtils.getLogicalDate(for: now)
            let lastCheckLogicalDate = DateUtils.getLogicalDate(for: lastCheckDate)

            if calendar.isDate(logicalToday, inSameDayAs: lastCheckLogicalDate) {
                // 오늘 이미 체크함 - 메인으로
                currentState = .main
                return
            }
        }

        // 건너뛰기 횟수 로드
        skipCount = UserDefaults.standard.integer(forKey: sleepSkipCountKey)
        isForceEntry = skipCount >= maxSkipCount

        // 수면 입력 화면 표시
        currentState = .sleepInput
    }

    // MARK: - Private Methods

    /// 현재 사용자 ID 로드
    private func loadCurrentUserId() {
        do {
            currentUserId = try userRepository.fetchCurrentUserId()
        } catch {
            print("❌ 사용자 ID 로드 실패: \(error.localizedDescription)")
        }
    }

    /// 오늘 체크 완료로 표시
    private func markTodayChecked() {
        UserDefaults.standard.set(Date(), forKey: lastSleepCheckDateKey)
    }
}

// MARK: - Preview

#Preview {
    AppRootView()
        .environmentObject(AppStateService.completedOnboarding)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

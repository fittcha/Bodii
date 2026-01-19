//
//  SettingsView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Settings View with Toggle Controls
// 설정 화면 - 앱의 다양한 설정 옵션을 제공
// 💡 Java 비교: Android의 PreferenceScreen이나 SettingsActivity와 유사

import SwiftUI
import HealthKit

// MARK: - SettingsView

/// 앱 설정 화면
///
/// 사용자가 앱의 다양한 설정을 관리할 수 있는 화면입니다.
///
/// **주요 기능:**
/// - HealthKit 연동 토글
/// - 권한 상태 표시
/// - 마지막 동기화 시각 표시
/// - 수동 동기화 트리거
///
/// **HealthKit 연동 흐름:**
/// 1. 토글 ON → 권한 온보딩 화면 표시
/// 2. 권한 허용 → UserDefaults에 저장
/// 3. 자동 동기화 시작
///
/// - Example:
/// ```swift
/// SettingsView(
///     authService: container.healthKitAuthorizationService,
///     syncService: container.healthKitSyncService
/// )
/// ```
struct SettingsView: View {

    // MARK: - Properties

    /// HealthKit 설정 ViewModel
    ///
    /// 📚 학습 포인트: @StateObject for ViewModel
    /// - ViewModel의 생명주기를 View가 관리
    /// - View가 재생성되어도 ViewModel은 유지
    /// 💡 Java 비교: ViewModel by viewModels()
    @StateObject private var viewModel: HealthKitSettingsViewModel

    /// HealthKit 권한 서비스 (Sheet에 전달용)
    ///
    /// 📚 학습 포인트: Service Pass-through
    /// - ViewModel 내부에 있지만 HealthKitPermissionView에 전달 필요
    let authService: HealthKitAuthorizationService

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // HealthKit 섹션
                healthKitSection

                // 앱 정보 섹션
                appInfoSection
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            // 📚 학습 포인트: Sheet Presentation with ViewModel
            // viewModel.showPermissionView가 true일 때 모달 표시
            .sheet(isPresented: $viewModel.showPermissionView) {
                HealthKitPermissionView(
                    authService: authService,
                    onPermissionGranted: {
                        // 📚 학습 포인트: ViewModel Callback
                        // ViewModel의 메서드 호출
                        viewModel.onPermissionGranted()
                    }
                )
            }
            // 권한 거부 안내 화면
            .sheet(isPresented: $viewModel.showDeniedView) {
                HealthKitDeniedView(
                    onOpenSettings: {
                        // 📚 학습 포인트: ViewModel Callback
                        // ViewModel의 메서드 호출
                        viewModel.onSettingsReturned()
                    }
                )
            }
            // 📚 학습 포인트: Error Alert with ViewModel
            // ViewModel의 에러 상태에 바인딩
            .alert("오류", isPresented: $viewModel.showError) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - View Components

    /// HealthKit 연동 섹션
    ///
    /// 📚 학습 포인트: List Section with Toggle
    /// - Section으로 그룹화하여 설정 항목 구성
    /// - Toggle로 on/off 상태 관리
    @ViewBuilder
    private var healthKitSection: some View {
        Section {
            // HealthKit 토글
            Toggle(isOn: $viewModel.isEnabled) {
                HStack(spacing: 12) {
                    // Apple Health 아이콘
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Health 연동")
                            .font(.body)

                        // 권한 상태 표시
                        authorizationStatusText
                    }
                }
            }
            .onChange(of: viewModel.isEnabled) { oldValue, newValue in
                // 📚 학습 포인트: Toggle onChange with ViewModel
                // ViewModel의 메서드 호출
                viewModel.toggleHealthKit(enabled: newValue)
            }

            // 마지막 동기화 시각 표시
            if viewModel.isEnabled {
                lastSyncRow
            }

            // 수동 동기화 버튼
            if viewModel.isEnabled && viewModel.isHealthKitAvailable {
                syncNowButton
            }

        } header: {
            Text("건강 데이터")
        } footer: {
            Text("Apple Health와 연동하여 체중, 운동, 수면 데이터를 자동으로 동기화합니다.")
        }
    }

    /// 권한 상태 텍스트
    ///
    /// 📚 학습 포인트: Dynamic Status Text
    /// - 권한 상태에 따라 다른 메시지 표시
    @ViewBuilder
    private var authorizationStatusText: some View {
        // 📚 학습 포인트: ViewModel State Display
        // ViewModel의 상태를 표시
        if !viewModel.isHealthKitAvailable {
            Text("이 기기에서는 사용할 수 없습니다")
                .font(.caption)
                .foregroundStyle(.red)
        } else if viewModel.isEnabled {
            // 📚 학습 포인트: Enum-based UI State
            // ViewModel의 AuthorizationStatus enum 사용
            Text(viewModel.authorizationStatus.displayText)
                .font(.caption)
                .foregroundStyle(viewModel.authorizationStatus.color)
        } else {
            Text("비활성화")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// 마지막 동기화 시각 행
    ///
    /// 📚 학습 포인트: Date Formatting
    /// - RelativeDateTimeFormatter로 상대 시간 표시 (예: "2시간 전")
    @ViewBuilder
    private var lastSyncRow: some View {
        HStack {
            Text("마지막 동기화")
                .foregroundStyle(.secondary)

            Spacer()

            // 📚 학습 포인트: ViewModel State Display
            // ViewModel의 lastSyncDate 사용
            if let lastSyncDate = viewModel.lastSyncDate {
                // 📚 학습 포인트: RelativeDateTimeFormatter
                // "방금", "5분 전", "2시간 전" 등 상대 시간으로 표시
                Text(lastSyncDate, style: .relative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("동기화 기록 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    /// 지금 동기화 버튼
    ///
    /// 📚 학습 포인트: Button with Loading State
    /// - 동기화 중일 때 ProgressView 표시
    @ViewBuilder
    private var syncNowButton: some View {
        Button(action: {
            // 📚 학습 포인트: ViewModel Method Call
            // ViewModel의 syncNow() 메서드 호출
            Task {
                await viewModel.syncNow()
            }
        }) {
            HStack {
                Text("지금 동기화")

                Spacer()

                // 📚 학습 포인트: ViewModel State Display
                // ViewModel의 isSyncing 상태 사용
                if viewModel.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.blue)
                }
            }
        }
        .disabled(!viewModel.canSync)
    }

    /// 앱 정보 섹션
    ///
    /// 📚 학습 포인트: App Info Section
    /// - 버전 정보, 이용약관, 개인정보 처리방침 등
    @ViewBuilder
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("버전")
                    .foregroundStyle(.secondary)

                Spacer()

                // 📚 학습 포인트: Bundle Version
                // Info.plist의 CFBundleShortVersionString 읽기
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

        } header: {
            Text("앱 정보")
        }
    }

    // MARK: - Initialization

    /// SettingsView 초기화
    ///
    /// 📚 학습 포인트: ViewModel Initialization in View
    /// - ViewModel을 @StateObject로 생성
    /// - 서비스는 ViewModel에 주입
    ///
    /// - Parameters:
    ///   - authService: HealthKit 권한 서비스
    ///   - syncService: HealthKit 동기화 서비스
    init(
        authService: HealthKitAuthorizationService,
        syncService: HealthKitSyncService
    ) {
        self.authService = authService

        // 📚 학습 포인트: @StateObject Initialization
        // _viewModel을 사용하여 StateObject 초기화
        // 💡 Java 비교: by viewModels() 팩토리 함수와 유사
        _viewModel = StateObject(wrappedValue: HealthKitSettingsViewModel(
            authService: authService,
            syncService: syncService
        ))
    }
}


// MARK: - Preview

#Preview("Settings View") {
    // 📚 학습 포인트: Preview with Services
    // 실제 HealthKit 서비스로 Preview 생성

    let healthStore = HKHealthStore()
    let authService = HealthKitAuthorizationService(healthStore: healthStore)
    let readService = HealthKitReadService(healthStore: healthStore)
    let writeService = HealthKitWriteService(healthStore: healthStore)
    let syncService = HealthKitSyncService(
        readService: readService,
        writeService: writeService,
        authService: authService
    )

    return SettingsView(
        authService: authService,
        syncService: syncService
    )
}

#Preview("Settings View - Dark Mode") {
    let healthStore = HKHealthStore()
    let authService = HealthKitAuthorizationService(healthStore: healthStore)
    let readService = HealthKitReadService(healthStore: healthStore)
    let writeService = HealthKitWriteService(healthStore: healthStore)
    let syncService = HealthKitSyncService(
        readService: readService,
        writeService: writeService,
        authService: authService
    )

    return SettingsView(
        authService: authService,
        syncService: syncService
    )
    .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: Settings View Best Practices
///
/// ## 설정 화면 설계 원칙
///
/// 1. **명확한 구조**:
///    - Section으로 관련 설정 그룹화
///    - Header/Footer로 섹션 설명 제공
///
/// 2. **즉각적인 피드백**:
///    - 토글 변경 시 즉시 반영
///    - 권한 상태를 실시간 표시
///    - 동기화 진행 상태 표시
///
/// 3. **에러 처리**:
///    - 사용자 친화적인 에러 메시지
///    - HealthKit 사용 불가 시 안내
///    - 권한 거부 시 설정 앱으로 안내
///
/// 4. **UserDefaults 활용**:
///    - @AppStorage로 자동 저장
///    - 앱 재시작 후에도 설정 유지
///
/// 5. **권한 흐름**:
///    - 토글 ON → 권한 온보딩 → 동기화 시작
///    - 권한 거부 → 거부 안내 → 설정 앱 이동
///
/// ## HealthKit 연동 상태 관리
///
/// **저장 위치**:
/// - `healthKitSyncEnabled`: UserDefaults (앱 설정)
/// - 실제 권한 상태: HealthKit (시스템)
///
/// **상태 불일치 처리**:
/// - 토글 ON이지만 권한 없음 → 권한 요청
/// - 토글 OFF → 동기화만 중단 (권한은 유지)
///
/// ## 동기화 전략
///
/// **자동 동기화**:
/// - 권한 허용 후 즉시 동기화
/// - 백그라운드에서 실행 (Phase 5.4)
///
/// **수동 동기화**:
/// - "지금 동기화" 버튼
/// - Pull-to-refresh (Phase 6.4)
///
/// ## 사용 흐름
///
/// ```swift
/// // 1. ContentView에서 SettingsView 표시
/// private var settingsTab: some View {
///     SettingsView(
///         authService: container.healthKitAuthorizationService,
///         syncService: container.healthKitSyncService
///     )
///     .tabItem {
///         Label("설정", systemImage: "gearshape.fill")
///     }
///     .tag(Tab.settings)
/// }
///
/// // 2. 사용자가 HealthKit 토글 ON
/// // → handleHealthKitToggleChange() 호출
///
/// // 3. requestHealthKitPermission() 호출
/// // → showPermissionView = true
///
/// // 4. HealthKitPermissionView 표시
/// // → 권한 요청
///
/// // 5. 권한 허용 후 onPermissionGranted 콜백
/// // → healthKitSyncEnabled = true
/// // → performSync() 호출
/// ```
///
/// ## 접근성
///
/// - VoiceOver 지원: 모든 컨트롤이 읽힘
/// - Dynamic Type: 텍스트 크기 자동 조정
/// - 토글 컨트롤: 표준 UISwitch 사용
///
/// ## 💡 Android 비교
///
/// **iOS (SwiftUI)**:
/// - @AppStorage로 UserDefaults 자동 저장
/// - Toggle로 on/off 상태 관리
/// - sheet modifier로 모달 표시
///
/// **Android**:
/// - PreferenceFragment + SharedPreferences
/// - SwitchPreference로 on/off 상태 관리
/// - DialogFragment로 다이얼로그 표시
///

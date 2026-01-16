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

    /// HealthKit 권한 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - 권한 요청 및 상태 확인을 담당하는 서비스
    /// 💡 Java 비교: Constructor Injection
    let authService: HealthKitAuthorizationService

    /// HealthKit 동기화 서비스
    ///
    /// 📚 학습 포인트: Service Injection
    /// - 동기화 수행 및 마지막 동기화 시각 조회
    let syncService: HealthKitSyncService

    // MARK: - State

    /// HealthKit 연동 활성화 상태
    ///
    /// 📚 학습 포인트: @AppStorage
    /// - UserDefaults에 자동 저장되는 @State 래퍼
    /// - 앱 재시작 후에도 값 유지
    /// 💡 Java 비교: SharedPreferences와 유사
    @AppStorage("healthKitSyncEnabled") private var healthKitSyncEnabled = false

    /// 권한 온보딩 화면 표시 여부
    ///
    /// 📚 학습 포인트: @State for Sheet Presentation
    /// - sheet modifier와 함께 사용하여 모달 표시
    @State private var showPermissionView = false

    /// 권한 거부 안내 화면 표시 여부
    @State private var showDeniedView = false

    /// 권한 상태 체크 트리거
    ///
    /// 📚 학습 포인트: State for Manual Refresh
    /// - 권한 상태를 다시 확인하기 위한 트리거
    @State private var authorizationCheckTrigger = false

    /// 동기화 중 상태
    @State private var isSyncing = false

    /// 에러 메시지
    @State private var errorMessage: String?

    /// 에러 알림 표시 여부
    @State private var showError = false

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
            // 📚 학습 포인트: Sheet Presentation
            // showPermissionView가 true일 때 모달 표시
            .sheet(isPresented: $showPermissionView) {
                HealthKitPermissionView(
                    authService: authService,
                    onPermissionGranted: {
                        // 📚 학습 포인트: Permission Success Callback
                        // 권한 허용 후 설정 활성화 및 동기화 시작
                        healthKitSyncEnabled = true
                        authorizationCheckTrigger.toggle()

                        // 백그라운드에서 동기화 시작
                        Task {
                            await performSync()
                        }
                    }
                )
            }
            // 권한 거부 안내 화면
            .sheet(isPresented: $showDeniedView) {
                HealthKitDeniedView(
                    onSettingsOpened: {
                        // 설정 앱에서 돌아온 후 권한 상태 재확인
                        authorizationCheckTrigger.toggle()
                    }
                )
            }
            // 📚 학습 포인트: Error Alert
            // 에러 발생 시 알림 표시
            .alert("오류", isPresented: $showError) {
                Button("확인") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
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
            Toggle(isOn: $healthKitSyncEnabled) {
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
            .onChange(of: healthKitSyncEnabled) { oldValue, newValue in
                // 📚 학습 포인트: Toggle onChange
                // 토글 변경 시 권한 요청 또는 비활성화 처리
                handleHealthKitToggleChange(oldValue: oldValue, newValue: newValue)
            }

            // 마지막 동기화 시각 표시
            if healthKitSyncEnabled {
                lastSyncRow
            }

            // 수동 동기화 버튼
            if healthKitSyncEnabled && authService.isHealthDataAvailable() {
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
        // 📚 학습 포인트: HealthKit Availability Check
        // HealthKit 사용 가능 여부 먼저 확인
        if !authService.isHealthDataAvailable() {
            Text("이 기기에서는 사용할 수 없습니다")
                .font(.caption)
                .foregroundStyle(.red)
        } else if healthKitSyncEnabled {
            // 권한 요약 정보 가져오기
            let summary = authService.getAuthorizationSummary()

            if summary.isFullyAuthorized {
                Text("연동됨 · 모든 권한 허용")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if summary.isPartiallyAuthorized {
                Text("연동됨 · 일부 권한만 허용")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if summary.isFullyDenied {
                Text("권한이 거부되었습니다")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("권한 확인 중...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

            if let lastSyncDate = syncService.getLastSyncDate() {
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
            Task {
                await performSync()
            }
        }) {
            HStack {
                Text("지금 동기화")

                Spacer()

                if isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.blue)
                }
            }
        }
        .disabled(isSyncing)
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

    // MARK: - Actions

    /// HealthKit 토글 변경 처리
    ///
    /// 📚 학습 포인트: Toggle Change Handler
    /// - 토글 ON: 권한 요청 또는 권한 거부 안내
    /// - 토글 OFF: 동기화 비활성화
    ///
    /// - Parameters:
    ///   - oldValue: 이전 값
    ///   - newValue: 새 값
    private func handleHealthKitToggleChange(oldValue: Bool, newValue: Bool) {
        // 📚 학습 포인트: Guard HealthKit Availability
        // HealthKit 사용 불가 시 토글 되돌리기
        guard authService.isHealthDataAvailable() else {
            healthKitSyncEnabled = false
            errorMessage = "이 기기에서는 Apple Health를 사용할 수 없습니다."
            showError = true
            return
        }

        if newValue && !oldValue {
            // 토글 ON: 권한 요청
            // 📚 학습 포인트: Request Permission on Toggle
            // 권한이 없으면 온보딩 화면 표시
            requestHealthKitPermission()
        } else if !newValue && oldValue {
            // 토글 OFF: 동기화 비활성화
            // 📚 학습 포인트: Disable Sync
            // UserDefaults에 저장된 값만 변경 (권한은 취소하지 않음)
            // 사용자가 원하면 설정 앱에서 직접 권한 취소 가능
        }
    }

    /// HealthKit 권한 요청
    ///
    /// 📚 학습 포인트: Permission Request Flow
    /// - 권한이 거부된 경우: 거부 안내 화면 표시
    /// - 권한이 없는 경우: 온보딩 화면 표시
    /// - 권한이 이미 허용된 경우: 동기화 시작
    private func requestHealthKitPermission() {
        let summary = authService.getAuthorizationSummary()

        // 📚 학습 포인트: Handle Permission States
        if summary.isFullyDenied {
            // 권한 거부됨 → 설정 앱으로 안내
            showDeniedView = true
            healthKitSyncEnabled = false
        } else if summary.isFullyAuthorized || summary.isPartiallyAuthorized {
            // 이미 권한 허용됨 → 동기화 시작
            Task {
                await performSync()
            }
        } else {
            // 권한 없음 → 온보딩 화면 표시
            showPermissionView = true
        }
    }

    /// 동기화 수행
    ///
    /// 📚 학습 포인트: Async Sync Operation
    /// - 비동기로 동기화 수행
    /// - 로딩 상태 관리
    /// - 에러 처리
    private func performSync() async {
        // 로딩 시작
        isSyncing = true
        defer { isSyncing = false }

        do {
            // 📚 학습 포인트: Call Sync Service
            // TODO: Phase 7 - 실제 userId로 교체
            // 임시로 고정 UUID 사용 (실제 인증 구현 전)
            let tempUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
            try await syncService.sync(userId: tempUserId)

            // 권한 상태 업데이트 트리거
            authorizationCheckTrigger.toggle()

        } catch let error as HealthKitError {
            // 📚 학습 포인트: Error Handling
            // HealthKitError를 사용자 친화적인 메시지로 변환
            errorMessage = error.localizedDescription
            showError = true

            // 권한 에러인 경우 토글 비활성화
            if error.isAuthorizationError {
                healthKitSyncEnabled = false
            }

        } catch {
            // 예상치 못한 에러
            errorMessage = "동기화 중 오류가 발생했습니다."
            showError = true
        }
    }
}

// MARK: - Initialization Extensions

extension SettingsView {
    /// 기본 초기화
    ///
    /// 📚 학습 포인트: Default Initializer
    /// - HKHealthStore를 새로 생성하여 서비스 초기화
    /// - Preview나 간단한 테스트용
    init() {
        let healthStore = HKHealthStore()
        self.authService = HealthKitAuthorizationService(healthStore: healthStore)

        let readService = HealthKitReadService(healthStore: healthStore)
        let writeService = HealthKitWriteService(healthStore: healthStore)
        self.syncService = HealthKitSyncService(
            readService: readService,
            writeService: writeService,
            authService: authService
        )
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

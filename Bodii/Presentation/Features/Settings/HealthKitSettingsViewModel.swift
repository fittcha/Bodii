//
//  HealthKitSettingsViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: ViewModel Pattern for Settings
// 설정 화면의 상태와 비즈니스 로직을 관리하는 ViewModel
// 💡 Java 비교: Android의 SettingsViewModel과 유사

import Foundation
import SwiftUI
import Combine
import HealthKit

// MARK: - HealthKitSettingsViewModel

/// HealthKit 설정 화면을 위한 ViewModel
///
/// HealthKit 연동 설정의 상태를 관리하고 권한 요청, 동기화를 처리합니다.
///
/// **주요 기능:**
/// - HealthKit 연동 활성화/비활성화
/// - 권한 상태 확인 및 표시
/// - 마지막 동기화 시각 조회
/// - 수동 동기화 트리거
/// - 권한 요청 흐름 관리
///
/// **상태 관리:**
/// - `isEnabled`: HealthKit 연동 활성화 상태 (UserDefaults에 자동 저장)
/// - `authorizationStatus`: 현재 권한 상태
/// - `lastSyncDate`: 마지막 동기화 시각
/// - `isSyncing`: 동기화 진행 중 상태
///
/// **권한 요청 흐름:**
/// 1. `toggleHealthKit(enabled:)` 호출
/// 2. 권한이 없으면 `showPermissionView = true`
/// 3. 권한 허용 후 `onPermissionGranted()` 콜백
/// 4. 자동으로 동기화 시작
///
/// - Example:
/// ```swift
/// @StateObject private var viewModel = HealthKitSettingsViewModel(
///     authService: container.healthKitAuthorizationService,
///     syncService: container.healthKitSyncService
/// )
///
/// var body: some View {
///     Toggle("Apple Health 연동", isOn: $viewModel.isEnabled)
///         .onChange(of: viewModel.isEnabled) { _, newValue in
///             viewModel.toggleHealthKit(enabled: newValue)
///         }
/// }
/// ```
///
/// 💡 Java 비교: Android의 ViewModel + LiveData + SharedPreferences
@MainActor
class HealthKitSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// HealthKit 연동 활성화 상태
    ///
    /// 📚 학습 포인트: @AppStorage in ViewModel
    /// - UserDefaults에 자동으로 저장/로드
    /// - View에서 `$viewModel.isEnabled`로 양방향 바인딩
    /// - 앱 재시작 후에도 값 유지
    /// 💡 Java 비교: SharedPreferences + LiveData
    @AppStorage("healthKitSyncEnabled") var isEnabled = false

    /// 마지막 동기화 시각
    ///
    /// 📚 학습 포인트: Optional Published State
    /// - nil이면 동기화 기록 없음
    /// - View에서 "방금", "5분 전" 등으로 표시
    @Published var lastSyncDate: Date?

    /// 권한 상태 요약
    ///
    /// 📚 학습 포인트: Authorization State
    /// - 권한 상태를 구조체로 캡슐화
    /// - View에서 상태에 따라 다른 UI 표시
    @Published var authorizationStatus: AuthorizationStatus = .unknown

    /// 동기화 진행 중 상태
    ///
    /// 📚 학습 포인트: Loading State
    /// - 동기화 중 ProgressView 표시
    /// - 버튼 비활성화 처리
    @Published var isSyncing = false

    /// 에러 메시지
    ///
    /// 📚 학습 포인트: Error Handling
    /// - nil이면 에러 없음
    /// - 값이 있으면 Alert 표시
    @Published var errorMessage: String?

    /// 에러 알림 표시 여부
    @Published var showError = false

    /// 권한 온보딩 화면 표시 여부
    ///
    /// 📚 학습 포인트: Sheet Presentation State
    /// - true일 때 HealthKitPermissionView 표시
    /// - 권한 허용 후 자동으로 false로 변경
    @Published var showPermissionView = false

    /// 권한 거부 안내 화면 표시 여부
    ///
    /// 📚 학습 포인트: Conditional Sheet
    /// - 권한이 거부된 경우 설정 앱으로 안내
    @Published var showDeniedView = false

    // MARK: - Private Properties

    /// HealthKit 권한 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - 권한 요청 및 상태 확인을 담당
    /// - 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: @Inject로 주입받는 Service
    private let authService: HealthKitAuthorizationService

    /// HealthKit 동기화 서비스
    ///
    /// 📚 학습 포인트: Service Injection
    /// - 동기화 수행 및 마지막 동기화 시각 조회
    private let syncService: HealthKitSyncService

    /// Combine 구독 저장소
    ///
    /// 📚 학습 포인트: Combine Framework
    /// - 비동기 이벤트 스트림 관리
    /// - 메모리 누수 방지
    /// 💡 Java 비교: RxJava의 CompositeDisposable
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// HealthKitSettingsViewModel 초기화
    ///
    /// 📚 학습 포인트: Constructor Dependency Injection
    /// - 모든 의존성을 생성자를 통해 주입
    /// - 의존성 역전 원칙 (DIP) 준수
    /// 💡 Java 비교: @Inject constructor
    ///
    /// - Parameters:
    ///   - authService: HealthKit 권한 서비스
    ///   - syncService: HealthKit 동기화 서비스
    init(
        authService: HealthKitAuthorizationService,
        syncService: HealthKitSyncService
    ) {
        self.authService = authService
        self.syncService = syncService

        // 초기 상태 로드
        Task {
            await refreshState()
        }
    }

    // MARK: - Computed Properties

    /// HealthKit 사용 가능 여부
    ///
    /// 📚 학습 포인트: Computed Property
    /// - iPad에서는 HealthKit 사용 불가
    /// - View에서 기능 활성화/비활성화 결정
    var isHealthKitAvailable: Bool {
        authService.isHealthDataAvailable()
    }

    /// 동기화 버튼 활성화 여부
    ///
    /// 📚 학습 포인트: UI State Calculation
    /// - 활성화되어 있고 동기화 중이 아닐 때만 활성화
    var canSync: Bool {
        isEnabled && !isSyncing && isHealthKitAvailable
    }

    // MARK: - Public Methods

    /// HealthKit 토글 변경 처리
    ///
    /// 📚 학습 포인트: Toggle Handler
    /// - 토글 ON: 권한 요청
    /// - 토글 OFF: 동기화 비활성화 (권한은 유지)
    ///
    /// **처리 흐름:**
    /// 1. HealthKit 사용 가능 여부 확인
    /// 2. 활성화 시: 권한 상태 확인
    ///    - 권한 없음: 온보딩 화면 표시
    ///    - 권한 거부: 거부 안내 화면 표시
    ///    - 권한 허용: 동기화 시작
    /// 3. 비활성화 시: UserDefaults만 업데이트
    ///
    /// - Parameter enabled: 활성화 여부
    func toggleHealthKit(enabled: Bool) {
        // 📚 학습 포인트: Guard HealthKit Availability
        // HealthKit 사용 불가 시 토글 되돌리기
        guard isHealthKitAvailable else {
            isEnabled = false
            errorMessage = "이 기기에서는 Apple Health를 사용할 수 없습니다."
            showError = true
            return
        }

        if enabled {
            // 토글 ON: 권한 요청
            requestAuthorization()
        } else {
            // 토글 OFF: 동기화 비활성화
            // 📚 학습 포인트: Soft Disable
            // 권한은 취소하지 않고 동기화만 중단
            // 사용자가 원하면 설정 앱에서 직접 권한 취소 가능
        }
    }

    /// HealthKit 권한 요청
    ///
    /// 📚 학습 포인트: Authorization Request Flow
    /// - 권한 상태에 따라 다른 화면 표시
    /// - 이미 허용된 경우 동기화만 시작
    ///
    /// **상태별 처리:**
    /// - 권한 거부됨: `showDeniedView = true`
    /// - 권한 없음: `showPermissionView = true`
    /// - 권한 허용됨: 동기화 시작
    func requestAuthorization() {
        let summary = authService.getAuthorizationSummary()

        // 📚 학습 포인트: Handle Permission States
        if summary.isFullyDenied {
            // 권한 거부됨 → 설정 앱으로 안내
            showDeniedView = true
            isEnabled = false
        } else if summary.isFullyAuthorized || summary.isPartiallyAuthorized {
            // 이미 권한 허용됨 → 동기화 시작
            Task {
                await syncNow()
            }
        } else {
            // 권한 없음 → 온보딩 화면 표시
            showPermissionView = true
        }
    }

    /// 권한 허용 후 콜백
    ///
    /// 📚 학습 포인트: Permission Success Handler
    /// - HealthKitPermissionView에서 권한 허용 후 호출
    /// - 설정 활성화 및 동기화 시작
    func onPermissionGranted() {
        // 📚 학습 포인트: Success Flow
        // 권한 허용 후 설정 활성화 및 동기화 시작
        isEnabled = true

        // 권한 상태 업데이트
        Task {
            await refreshState()
            await syncNow()
        }
    }

    /// 설정 앱에서 돌아온 후 콜백
    ///
    /// 📚 학습 포인트: Settings Return Handler
    /// - HealthKitDeniedView에서 설정 앱으로 이동 후 호출
    /// - 권한 상태 재확인
    func onSettingsReturned() {
        Task {
            await refreshState()
        }
    }

    /// 수동 동기화 실행
    ///
    /// 📚 학습 포인트: Manual Sync Method
    /// - "지금 동기화" 버튼 클릭 시 호출
    /// - 로딩 상태 관리 및 에러 처리
    ///
    /// **처리 흐름:**
    /// 1. 로딩 시작 (`isSyncing = true`)
    /// 2. 동기화 서비스 호출
    /// 3. 성공 시: 마지막 동기화 시각 업데이트
    /// 4. 실패 시: 에러 메시지 표시
    /// 5. 로딩 종료 (`isSyncing = false`)
    func syncNow() async {
        // 로딩 시작
        isSyncing = true
        defer { isSyncing = false }

        do {
            // 📚 학습 포인트: Call Sync Service
            // TODO: Phase 7 - 실제 userId로 교체
            // 임시로 고정 UUID 사용 (실제 인증 구현 전)
            let tempUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
            try await syncService.sync(userId: tempUserId)

            // 성공 시 상태 업데이트
            await refreshState()

        } catch let error as HealthKitError {
            // 📚 학습 포인트: Specific Error Handling
            // HealthKitError를 사용자 친화적인 메시지로 변환
            errorMessage = error.localizedDescription
            showError = true

            // 권한 에러인 경우 토글 비활성화
            if error.isAuthorizationError {
                isEnabled = false
            }

        } catch {
            // 예상치 못한 에러
            errorMessage = "동기화 중 오류가 발생했습니다."
            showError = true
        }
    }

    /// 상태 새로고침
    ///
    /// 📚 학습 포인트: State Refresh
    /// - 권한 상태 및 마지막 동기화 시각 업데이트
    /// - 권한 상태 변경 후 호출
    func refreshState() async {
        // 📚 학습 포인트: Update Authorization Status
        // 권한 상태 요약 정보 가져오기
        let summary = authService.getAuthorizationSummary()
        authorizationStatus = AuthorizationStatus(from: summary)

        // 📚 학습 포인트: Update Last Sync Date
        // 마지막 동기화 시각 업데이트
        lastSyncDate = syncService.getLastSyncDate()
    }
}

// MARK: - Authorization Status

/// 권한 상태 열거형
///
/// 📚 학습 포인트: UI State Enum
/// - View에서 상태에 따라 다른 UI 표시
/// - HealthKitAuthorizationService.AuthorizationSummary를 간소화
enum AuthorizationStatus {
    /// 모든 권한 허용
    case fullyAuthorized
    /// 일부 권한만 허용
    case partiallyAuthorized
    /// 모든 권한 거부
    case denied
    /// 권한 상태 알 수 없음
    case unknown

    /// AuthorizationSummary에서 생성
    ///
    /// 📚 학습 포인트: Enum Conversion
    /// - 서비스 레이어의 타입을 ViewModel 레이어의 타입으로 변환
    /// - View가 서비스에 직접 의존하지 않도록 추상화
    ///
    /// - Parameter summary: 권한 상태 요약
    init(from summary: HealthKitAuthorizationService.AuthorizationSummary) {
        if summary.isFullyAuthorized {
            self = .fullyAuthorized
        } else if summary.isPartiallyAuthorized {
            self = .partiallyAuthorized
        } else if summary.isFullyDenied {
            self = .denied
        } else {
            self = .unknown
        }
    }

    /// 권한 상태를 사용자에게 표시할 텍스트
    ///
    /// 📚 학습 포인트: Localized Display Text
    /// - View에서 `authorizationStatus.displayText`로 사용
    /// - 한국어로 사용자 친화적인 메시지 제공
    var displayText: String {
        switch self {
        case .fullyAuthorized:
            return "연동됨 · 모든 권한 허용"
        case .partiallyAuthorized:
            return "연동됨 · 일부 권한만 허용"
        case .denied:
            return "권한이 거부되었습니다"
        case .unknown:
            return "권한 확인 중..."
        }
    }

    /// 권한 상태에 따른 색상
    ///
    /// 📚 학습 포인트: Semantic Colors
    /// - View에서 상태를 시각적으로 표현
    /// - 녹색(성공), 주황(경고), 빨강(에러), 회색(중립)
    var color: Color {
        switch self {
        case .fullyAuthorized:
            return .green
        case .partiallyAuthorized:
            return .orange
        case .denied:
            return .red
        case .unknown:
            return .secondary
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension HealthKitSettingsViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture
    static func makePreview(
        isEnabled: Bool = false,
        authorizationStatus: AuthorizationStatus = .unknown
    ) -> HealthKitSettingsViewModel {
        let healthStore = HKHealthStore()
        let authService = HealthKitAuthorizationService(healthStore: healthStore)
        let readService = HealthKitReadService(healthStore: healthStore)
        let writeService = HealthKitWriteService(healthStore: healthStore)
        let syncService = HealthKitSyncService(
            readService: readService,
            writeService: writeService,
            authService: authService
        )

        let viewModel = HealthKitSettingsViewModel(
            authService: authService,
            syncService: syncService
        )

        viewModel.isEnabled = isEnabled
        viewModel.authorizationStatus = authorizationStatus

        return viewModel
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: ViewModel Pattern 이해
///
/// HealthKitSettingsViewModel의 역할:
/// - **상태 관리**: @Published 프로퍼티로 View 자동 업데이트
/// - **비즈니스 로직 호출**: Service를 통해 권한 요청 및 동기화 수행
/// - **에러 처리**: 서비스 에러를 사용자 친화적 메시지로 변환
/// - **권한 흐름 관리**: 권한 상태에 따라 다른 화면 표시
/// - **UserDefaults 관리**: @AppStorage로 설정 영구 저장
///
/// MVVM 패턴에서의 위치:
/// - **Model**: HealthKitAuthorizationService, HealthKitSyncService (서비스 레이어)
/// - **View**: SettingsView (SwiftUI View)
/// - **ViewModel**: 이 클래스 (HealthKitSettingsViewModel)
///
/// 상태 관리:
/// - `isEnabled`: HealthKit 연동 활성화 상태 (UserDefaults)
/// - `authorizationStatus`: 권한 상태 요약
/// - `lastSyncDate`: 마지막 동기화 시각
/// - `isSyncing`: 동기화 진행 중 상태
/// - `showPermissionView`: 권한 온보딩 화면 표시 여부
/// - `showDeniedView`: 권한 거부 안내 화면 표시 여부
///
/// 의존성:
/// - `HealthKitAuthorizationService`: 권한 요청 및 상태 확인
/// - `HealthKitSyncService`: 동기화 수행 및 마지막 동기화 시각 조회
///
/// 사용 예시:
/// ```swift
/// struct SettingsView: View {
///     @StateObject private var viewModel = HealthKitSettingsViewModel(
///         authService: container.healthKitAuthorizationService,
///         syncService: container.healthKitSyncService
///     )
///
///     var body: some View {
///         Toggle("Apple Health 연동", isOn: $viewModel.isEnabled)
///             .onChange(of: viewModel.isEnabled) { _, newValue in
///                 viewModel.toggleHealthKit(enabled: newValue)
///             }
///
///         Text(viewModel.authorizationStatus.displayText)
///             .foregroundStyle(viewModel.authorizationStatus.color)
///
///         Button("지금 동기화") {
///             Task {
///                 await viewModel.syncNow()
///             }
///         }
///         .disabled(!viewModel.canSync)
///
///         .sheet(isPresented: $viewModel.showPermissionView) {
///             HealthKitPermissionView(
///                 authService: authService,
///                 onPermissionGranted: viewModel.onPermissionGranted
///             )
///         }
///     }
/// }
/// ```
///
/// 권한 요청 흐름:
/// ```
/// 1. 사용자가 토글 ON
///    ↓
/// 2. toggleHealthKit(enabled: true) 호출
///    ↓
/// 3. requestAuthorization() 호출
///    ↓
/// 4. 권한 상태 확인
///    ├─ 권한 없음 → showPermissionView = true
///    ├─ 권한 거부 → showDeniedView = true
///    └─ 권한 허용 → syncNow() 호출
///    ↓
/// 5. 권한 허용 후 onPermissionGranted() 콜백
///    ↓
/// 6. isEnabled = true, syncNow() 호출
/// ```
///
/// 💡 Android ViewModel과의 비교:
///
/// **iOS (SwiftUI)**:
/// - `@AppStorage`: UserDefaults 자동 저장
/// - `@Published`: LiveData와 유사한 자동 UI 업데이트
/// - `@MainActor`: 메인 스레드 안전성 보장
/// - `Task { await ... }`: 비동기 작업
///
/// **Android**:
/// - `SharedPreferences`: 설정 저장
/// - `LiveData/StateFlow`: UI 상태 관리
/// - `viewModelScope.launch`: 코루틴 실행
/// - `ViewModel`: 생명주기 인식
///

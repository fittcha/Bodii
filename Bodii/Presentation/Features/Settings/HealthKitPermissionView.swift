//
//  HealthKitPermissionView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Permission Onboarding View Pattern
// 권한 요청 전에 사용자에게 명확한 설명을 제공하는 온보딩 화면
// 💡 Java 비교: Android의 Permission Rationale Dialog와 유사

import SwiftUI
import HealthKit

// MARK: - HealthKit Permission View

/// HealthKit 권한 요청 온보딩 화면
///
/// 사용자에게 HealthKit 권한이 필요한 이유와 각 데이터 타입의 용도를 설명하고,
/// 권한 요청을 진행하는 온보딩 화면입니다.
///
/// **주요 기능:**
/// - HealthKit 통합 기능 설명
/// - 각 데이터 타입별 아이콘과 설명 표시
/// - 권한 요청 버튼
/// - 로딩/성공/실패 상태 처리
///
/// **데이터 타입:**
/// - 읽기: 체중, 체지방률, 활동 칼로리, 걸음 수, 수면, 운동
/// - 쓰기: 체중, 체지방률, 섭취 칼로리, 운동
///
/// - Example:
/// ```swift
/// .sheet(isPresented: $showPermissionView) {
///     HealthKitPermissionView(
///         authService: container.healthKitAuthorizationService,
///         onPermissionGranted: {
///             // 권한 허용 후 처리
///             showPermissionView = false
///         }
///     )
/// }
/// ```
struct HealthKitPermissionView: View {

    // MARK: - Properties

    /// HealthKit 권한 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - 권한 요청 및 상태 확인을 담당하는 서비스
    /// 💡 Java 비교: Constructor Injection
    let authService: HealthKitAuthorizationService

    /// 권한 허용 시 실행할 콜백
    let onPermissionGranted: (() -> Void)?

    // MARK: - State

    /// 권한 요청 중 상태
    ///
    /// 📚 학습 포인트: @State for Loading State
    /// - 비동기 작업 진행 중 UI 업데이트
    @State private var isRequesting = false

    /// 권한 요청 성공 상태
    @State private var requestSuccess = false

    /// 에러 메시지
    @State private var errorMessage: String?

    /// 에러 알림 표시 여부
    @State private var showError = false

    // MARK: - Environment

    /// 모달 닫기 액션
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// HealthKitPermissionView 초기화
    ///
    /// - Parameters:
    ///   - authService: HealthKit 권한 서비스
    ///   - onPermissionGranted: 권한 허용 시 실행할 콜백 (옵셔널)
    init(
        authService: HealthKitAuthorizationService,
        onPermissionGranted: (() -> Void)? = nil
    ) {
        self.authService = authService
        self.onPermissionGranted = onPermissionGranted
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더 섹션
                    headerSection

                    // 이점 설명 섹션
                    benefitsSection

                    // 읽기 권한 섹션
                    readPermissionsSection

                    // 쓰기 권한 섹션
                    writePermissionsSection

                    // 프라이버시 안내
                    privacyNotice

                    // 권한 요청 버튼
                    requestButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Apple Health 연동")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
            .alert("오류", isPresented: $showError) {
                Button("확인") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: requestSuccess) { _, success in
                if success {
                    // 📚 학습 포인트: Success Callback
                    // 권한 요청 성공 시 콜백 실행 후 화면 닫기
                    onPermissionGranted?()
                    dismiss()
                }
            }
        }
    }

    // MARK: - View Components

    /// 헤더 섹션
    ///
    /// Apple Health 아이콘과 메인 설명 표시
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Apple Health 아이콘
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 20)

            // 메인 타이틀
            Text("Apple Health와 연동하세요")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 설명
            Text("Bodii를 Apple Health와 연동하면 건강 데이터를 자동으로 동기화하고, 모든 건강 앱에서 데이터를 공유할 수 있습니다.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    /// 이점 설명 섹션
    ///
    /// HealthKit 연동의 주요 이점 표시
    @ViewBuilder
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "연동 혜택",
                icon: "star.fill"
            )

            VStack(spacing: 12) {
                benefitRow(
                    icon: "applewatch",
                    title: "Apple Watch 데이터 자동 동기화",
                    description: "운동 기록과 활동 칼로리가 자동으로 불러와집니다"
                )

                Divider()

                benefitRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "양방향 데이터 동기화",
                    description: "Bodii에서 입력한 데이터를 다른 건강 앱에서도 확인할 수 있습니다"
                )

                Divider()

                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "정확한 건강 분석",
                    description: "통합된 건강 데이터로 더 정확한 분석 결과를 제공합니다"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
    }

    /// 읽기 권한 섹션
    ///
    /// HealthKit에서 읽어올 데이터 타입들 표시
    @ViewBuilder
    private var readPermissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "읽기 권한",
                icon: "book.fill"
            )

            Text("다음 데이터를 Apple Health에서 불러옵니다")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                permissionRow(
                    icon: "scalemass",
                    iconColor: .blue,
                    title: "체중",
                    description: "체중 기록을 불러와 체성분 관리에 활용합니다"
                )

                permissionRow(
                    icon: "percent",
                    iconColor: .purple,
                    title: "체지방률",
                    description: "체지방률 기록을 불러와 신체 구성 분석에 활용합니다"
                )

                permissionRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "활동 칼로리",
                    description: "하루 소모 칼로리를 불러와 일일 목표 계산에 활용합니다"
                )

                permissionRow(
                    icon: "figure.walk",
                    iconColor: .green,
                    title: "걸음 수",
                    description: "걸음 수를 불러와 활동량을 추적합니다"
                )

                permissionRow(
                    icon: "bed.double.fill",
                    iconColor: .indigo,
                    title: "수면",
                    description: "수면 기록을 불러와 건강 분석에 활용합니다"
                )

                permissionRow(
                    icon: "figure.run",
                    iconColor: .red,
                    title: "운동",
                    description: "운동 기록을 불러와 칼로리 소모량을 계산합니다"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
    }

    /// 쓰기 권한 섹션
    ///
    /// HealthKit에 저장할 데이터 타입들 표시
    @ViewBuilder
    private var writePermissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "쓰기 권한",
                icon: "square.and.pencil"
            )

            Text("다음 데이터를 Apple Health에 저장합니다")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                permissionRow(
                    icon: "scalemass",
                    iconColor: .blue,
                    title: "체중",
                    description: "Bodii에서 입력한 체중을 Apple Health에 저장합니다"
                )

                permissionRow(
                    icon: "percent",
                    iconColor: .purple,
                    title: "체지방률",
                    description: "Bodii에서 입력한 체지방률을 Apple Health에 저장합니다"
                )

                permissionRow(
                    icon: "fork.knife",
                    iconColor: .orange,
                    title: "섭취 칼로리",
                    description: "Bodii에서 기록한 식단을 Apple Health에 저장합니다"
                )

                permissionRow(
                    icon: "figure.run",
                    iconColor: .red,
                    title: "운동",
                    description: "Bodii에서 기록한 운동을 Apple Health에 저장합니다"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
    }

    /// 프라이버시 안내
    ///
    /// 📚 학습 포인트: Privacy Notice
    /// - 사용자에게 데이터 처리 방식을 명확히 안내
    @ViewBuilder
    private var privacyNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("개인정보 보호")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("건강 데이터는 기기에만 저장되며, Bodii 서버로 전송되지 않습니다. 언제든지 설정에서 권한을 변경할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }

    /// 권한 요청 버튼
    ///
    /// 📚 학습 포인트: Async Button with Loading State
    /// - Task를 사용하여 비동기 권한 요청 실행
    /// - 로딩 중 버튼 비활성화 및 ProgressView 표시
    @ViewBuilder
    private var requestButton: some View {
        Button(action: {
            Task {
                await requestPermission()
            }
        }) {
            HStack {
                if isRequesting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "heart.fill")
                        .font(.headline)
                }

                Text(isRequesting ? "권한 요청 중..." : "Apple Health 연동하기")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRequesting ? Color.gray : Color.blue)
            )
            .foregroundStyle(.white)
        }
        .disabled(isRequesting)
        .padding(.bottom, 20)
    }

    /// 닫기 버튼
    @ViewBuilder
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("나중에")
                .font(.body)
        }
        .disabled(isRequesting)
    }

    // MARK: - Subview Builders

    /// 섹션 헤더
    ///
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - icon: SF Symbol 아이콘
    /// - Returns: 섹션 헤더 뷰
    @ViewBuilder
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.blue)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
    }

    /// 이점 설명 행
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - title: 제목
    ///   - description: 설명
    /// - Returns: 이점 행 뷰
    @ViewBuilder
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 권한 설명 행
    ///
    /// 📚 학습 포인트: Permission Item UI
    /// - 아이콘, 타이틀, 설명으로 구성된 권한 항목
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - iconColor: 아이콘 색상
    ///   - title: 데이터 타입 이름
    ///   - description: 사용 목적 설명
    /// - Returns: 권한 행 뷰
    @ViewBuilder
    private func permissionRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
            }

            // 텍스트
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    /// 권한 요청 실행
    ///
    /// 📚 학습 포인트: Async Permission Request
    /// - HealthKit 권한 요청은 비동기 작업
    /// - 성공/실패 상태를 UI에 반영
    /// 💡 Java 비교: requestPermissions() with callback
    private func requestPermission() async {
        // 로딩 시작
        isRequesting = true
        defer { isRequesting = false }

        do {
            // 📚 학습 포인트: HealthKit Availability Check
            // 권한 요청 전에 HealthKit 사용 가능 여부 확인
            guard authService.isHealthDataAvailable() else {
                errorMessage = "이 기기에서는 Apple Health를 사용할 수 없습니다."
                showError = true
                return
            }

            // 📚 학습 포인트: Authorization Request
            // 시스템 권한 다이얼로그 표시
            try await authService.requestAuthorization()

            // 📚 학습 포인트: Success State
            // 권한 요청 완료 (사용자가 일부만 허용해도 성공으로 처리)
            requestSuccess = true

        } catch let error as HealthKitError {
            // 📚 학습 포인트: Error Handling
            // HealthKitError를 사용자 친화적인 메시지로 변환
            errorMessage = error.localizedDescription
            showError = true

        } catch {
            // 예상치 못한 에러
            errorMessage = "권한 요청 중 오류가 발생했습니다."
            showError = true
        }
    }
}

// MARK: - Preview

#Preview("HealthKit Permission View") {
    // 📚 학습 포인트: Preview with Mock Service
    // 실제 HealthKit 없이도 Preview 가능

    let mockAuthService = HealthKitAuthorizationService()

    return HealthKitPermissionView(
        authService: mockAuthService,
        onPermissionGranted: {
            print("✅ 권한 허용 완료")
        }
    )
}

#Preview("HealthKit Permission View - Dark Mode") {
    let mockAuthService = HealthKitAuthorizationService()

    return HealthKitPermissionView(
        authService: mockAuthService,
        onPermissionGranted: {
            print("✅ 권한 허용 완료")
        }
    )
    .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: Permission Onboarding Best Practices
///
/// ## 권한 온보딩 화면 설계 원칙
///
/// 1. **명확한 설명**:
///    - 왜 권한이 필요한지 구체적으로 설명
///    - 각 데이터 타입별로 사용 목적을 명시
///
/// 2. **시각적 가이드**:
///    - 아이콘으로 각 데이터 타입을 시각화
///    - 색상을 활용하여 구분
///
/// 3. **투명성**:
///    - 읽기/쓰기 권한을 명확히 구분
///    - 데이터 처리 방식을 투명하게 공개
///
/// 4. **사용자 선택권**:
///    - "나중에" 버튼으로 강제하지 않음
///    - 언제든지 설정에서 변경 가능함을 안내
///
/// 5. **프라이버시 강조**:
///    - 데이터가 서버로 전송되지 않음을 명시
///    - Apple의 프라이버시 정책 준수
///
/// ## HealthKit 권한 특징
///
/// **읽기 권한**:
/// - 사용자가 거부해도 앱에서 확인 불가 (프라이버시)
/// - 항상 데이터 읽기를 시도하고 실패 시 처리
///
/// **쓰기 권한**:
/// - 거부 여부를 authorizationStatus로 확인 가능
/// - 데이터 저장 전에 권한 확인 필요
///
/// ## 부분 권한 허용 처리
///
/// 사용자는 일부 데이터 타입만 허용할 수 있습니다:
/// - 체중만 허용하고 체지방률은 거부
/// - 읽기는 허용하고 쓰기는 거부
///
/// 앱은 부분 권한 상태에서도 정상 작동해야 합니다.
///
/// ## 권한 재요청
///
/// iOS는 권한 다이얼로그를 한 번만 표시합니다:
/// - 거부 후 재요청해도 다이얼로그가 뜨지 않음
/// - 설정 앱으로 이동하는 버튼 제공 필요
/// - HealthKitDeniedView로 안내
///
/// ## 사용 흐름
///
/// ```swift
/// // 1. 설정 화면에서 HealthKit 토글 ON
/// @State private var showPermissionView = false
///
/// Toggle("Apple Health 연동", isOn: $isHealthKitEnabled)
///     .onChange(of: isHealthKitEnabled) { _, enabled in
///         if enabled {
///             showPermissionView = true
///         }
///     }
///
/// // 2. 권한 온보딩 화면 표시
/// .sheet(isPresented: $showPermissionView) {
///     HealthKitPermissionView(
///         authService: container.healthKitAuthorizationService,
///         onPermissionGranted: {
///             // 권한 허용 후 동기화 시작
///             Task {
///                 await container.healthKitSyncService.sync()
///             }
///         }
///     )
/// }
///
/// // 3. 권한 거부 시 HealthKitDeniedView 표시
/// if authService.getAuthorizationSummary().isFullyDenied {
///     HealthKitDeniedView()
/// }
/// ```
///
/// ## 접근성
///
/// - VoiceOver 지원: 모든 텍스트가 읽힘
/// - Dynamic Type: 텍스트 크기 자동 조정
/// - 색상: 아이콘 색상과 함께 텍스트로도 구분
///
/// ## 💡 Android 비교
///
/// **iOS (HealthKit)**:
/// - 시스템 권한 다이얼로그 (커스터마이징 불가)
/// - 읽기 권한 거부 여부 확인 불가
/// - 한 번에 모든 데이터 타입 권한 요청
///
/// **Android (Health Connect)**:
/// - 시스템 권한 다이얼로그
/// - 모든 권한 상태 확인 가능
/// - 개별 데이터 타입별 권한 관리
///

//
//  HealthKitDeniedView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: Permission Denied Recovery View Pattern
// 권한이 거부되었을 때 사용자가 설정에서 권한을 다시 활성화할 수 있도록 안내하는 화면
// 💡 Java 비교: Android의 Permission Rationale + Settings Intent와 유사

import SwiftUI

// MARK: - HealthKit Denied View

/// HealthKit 권한 거부 안내 화면
///
/// 사용자가 HealthKit 권한을 거부했을 때 표시되는 화면으로,
/// 왜 권한이 필요한지 설명하고 설정 앱에서 권한을 활성화하는 방법을 안내합니다.
///
/// **주요 기능:**
/// - 권한이 필요한 이유 설명
/// - 설정 앱에서 권한을 활성화하는 방법 안내
/// - 설정 앱으로 이동하는 딥링크 버튼
/// - 비강제적 UX (나중에 버튼)
///
/// **사용 시나리오:**
/// - 사용자가 초기 권한 요청을 거부한 경우
/// - HealthKit 기능이 필요한데 권한이 없는 경우
/// - 설정에서 권한을 재확인하고 싶을 때
///
/// - Example:
/// ```swift
/// if !authService.isFullyAuthorized {
///     HealthKitDeniedView(
///         onOpenSettings: {
///             // 설정 앱 열기
///             if let url = URL(string: UIApplication.openSettingsURLString) {
///                 UIApplication.shared.open(url)
///             }
///         }
///     )
/// }
/// ```
struct HealthKitDeniedView: View {

    // MARK: - Properties

    /// 설정 앱 열기 콜백
    ///
    /// 📚 학습 포인트: Callback Pattern
    /// - 부모 뷰에서 설정 앱 열기 로직을 제어할 수 있도록 콜백 제공
    /// 💡 Java 비교: Callback Interface
    let onOpenSettings: (() -> Void)?

    // MARK: - Environment

    /// 모달 닫기 액션
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// HealthKitDeniedView 초기화
    ///
    /// - Parameter onOpenSettings: 설정 앱 열기 콜백 (옵셔널)
    init(onOpenSettings: (() -> Void)? = nil) {
        self.onOpenSettings = onOpenSettings
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더 섹션
                    headerSection

                    // 권한이 필요한 이유
                    reasonSection

                    // 설정 방법 안내
                    instructionsSection

                    // 데이터 타입 설명
                    dataTypesSection

                    // 설정 앱 열기 버튼
                    settingsButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Apple Health 권한")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
        }
    }

    // MARK: - View Components

    /// 헤더 섹션
    ///
    /// 권한 거부 상태를 시각적으로 표시
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 정보 아이콘
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.2), .orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 20)

            // 메인 타이틀
            Text("Apple Health 권한이 필요합니다")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 설명
            Text("Bodii가 건강 데이터를 동기화하려면 Apple Health 접근 권한이 필요합니다.")
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

    /// 권한이 필요한 이유 섹션
    ///
    /// 왜 HealthKit 권한이 필요한지 설명
    @ViewBuilder
    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "권한이 필요한 이유",
                icon: "questionmark.circle.fill"
            )

            VStack(spacing: 12) {
                reasonRow(
                    icon: "applewatch",
                    title: "Apple Watch 데이터 동기화",
                    description: "운동 기록과 활동 칼로리를 자동으로 불러옵니다"
                )

                Divider()

                reasonRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "정확한 건강 분석",
                    description: "체중, 체지방, 수면 데이터를 통합하여 더 정확한 분석을 제공합니다"
                )

                Divider()

                reasonRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "데이터 백업 및 공유",
                    description: "Bodii 데이터를 Apple Health에 저장하여 다른 건강 앱과도 공유할 수 있습니다"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
    }

    /// 설정 방법 안내 섹션
    ///
    /// 📚 학습 포인트: Step-by-Step Instructions
    /// 사용자가 설정 앱에서 권한을 활성화하는 방법을 단계별로 안내
    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "권한 활성화 방법",
                icon: "gearshape.fill"
            )

            VStack(alignment: .leading, spacing: 16) {
                instructionStep(
                    number: 1,
                    text: "아래 '설정으로 이동' 버튼을 탭합니다"
                )

                instructionStep(
                    number: 2,
                    text: "설정 앱에서 'Health' 또는 '건강'을 탭합니다"
                )

                instructionStep(
                    number: 3,
                    text: "'데이터 접근 및 기기' 또는 'Apps'를 탭합니다"
                )

                instructionStep(
                    number: 4,
                    text: "'Bodii'를 찾아서 탭합니다"
                )

                instructionStep(
                    number: 5,
                    text: "필요한 데이터 타입의 권한을 활성화합니다"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
    }

    /// 데이터 타입 설명 섹션
    ///
    /// 어떤 데이터 타입의 권한이 필요한지 간략히 표시
    @ViewBuilder
    private var dataTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "필요한 권한",
                icon: "list.bullet.clipboard.fill"
            )

            VStack(spacing: 8) {
                dataTypeRow(icon: "scalemass", iconColor: .blue, title: "체중")
                dataTypeRow(icon: "percent", iconColor: .purple, title: "체지방률")
                dataTypeRow(icon: "flame.fill", iconColor: .orange, title: "활동 칼로리")
                dataTypeRow(icon: "figure.walk", iconColor: .green, title: "걸음 수")
                dataTypeRow(icon: "bed.double.fill", iconColor: .indigo, title: "수면")
                dataTypeRow(icon: "figure.run", iconColor: .red, title: "운동")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )

            // 프라이버시 안내
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)

                Text("건강 데이터는 기기에만 저장되며, 서버로 전송되지 않습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }

    /// 설정 앱 열기 버튼
    ///
    /// 📚 학습 포인트: Deep Link to Settings
    /// UIApplication.openSettingsURLString을 사용하여 앱 설정 화면으로 이동
    /// 💡 Java 비교: Android의 Intent.ACTION_APPLICATION_DETAILS_SETTINGS
    @ViewBuilder
    private var settingsButton: some View {
        Button(action: {
            openSettings()
        }) {
            HStack {
                Image(systemName: "gear")
                    .font(.headline)

                Text("설정으로 이동")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
            .foregroundStyle(.white)
        }
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

    /// 이유 설명 행
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - title: 제목
    ///   - description: 설명
    /// - Returns: 이유 행 뷰
    @ViewBuilder
    private func reasonRow(icon: String, title: String, description: String) -> some View {
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

    /// 설정 단계 행
    ///
    /// 📚 학습 포인트: Numbered Instructions
    /// 단계별 안내를 숫자와 함께 표시하여 사용자가 따라하기 쉽게 만듦
    ///
    /// - Parameters:
    ///   - number: 단계 번호
    ///   - text: 단계 설명
    /// - Returns: 단계 행 뷰
    @ViewBuilder
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 단계 번호
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            // 단계 설명
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    /// 데이터 타입 행
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - iconColor: 아이콘 색상
    ///   - title: 데이터 타입 이름
    /// - Returns: 데이터 타입 행 뷰
    @ViewBuilder
    private func dataTypeRow(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
            }

            // 타이틀
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
    }

    // MARK: - Actions

    /// 설정 앱 열기
    ///
    /// 📚 학습 포인트: Deep Link to Settings
    /// UIApplication.openSettingsURLString을 사용하여 앱 설정 화면으로 바로 이동
    /// 💡 Java 비교: Android의 startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS))
    ///
    /// **iOS 제약사항:**
    /// - HealthKit 설정 화면으로 직접 이동 불가
    /// - 앱 설정 화면까지만 이동 가능
    /// - 사용자가 수동으로 Health > Bodii로 이동해야 함
    ///
    /// **Android Health Connect 비교:**
    /// - Android는 Health Connect 설정 화면으로 직접 이동 가능
    /// - Intent로 특정 권한 설정 화면까지 이동 가능
    private func openSettings() {
        // 📚 학습 포인트: Settings URL
        // UIApplication.openSettingsURLString은 앱의 설정 화면을 여는 특별한 URL
        if let url = URL(string: UIApplication.openSettingsURLString) {
            // 📚 학습 포인트: UIApplication.shared.open()
            // URL을 열어서 외부 앱(설정 앱)으로 이동
            // 💡 Java 비교: startActivity() with Intent
            UIApplication.shared.open(url) { success in
                if success {
                    // 📚 학습 포인트: Callback Execution
                    // 설정 앱이 성공적으로 열린 경우 콜백 실행
                    onOpenSettings?()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("HealthKit Denied View") {
    // 📚 학습 포인트: Preview with Callback
    // 설정 앱 열기 동작을 프리뷰에서 확인

    HealthKitDeniedView(
        onOpenSettings: {
            print("✅ 설정 앱 열기")
        }
    )
}

#Preview("HealthKit Denied View - Dark Mode") {
    HealthKitDeniedView(
        onOpenSettings: {
            print("✅ 설정 앱 열기")
        }
    )
    .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: Permission Denied Handling Best Practices
///
/// ## 권한 거부 처리 원칙
///
/// 1. **비강제적 UX**:
///    - 사용자가 권한을 거부했다면 그 선택을 존중
///    - "나중에" 버튼으로 쉽게 닫을 수 있도록 함
///    - 권한이 없어도 기본 기능은 사용 가능하도록 설계
///
/// 2. **명확한 설명**:
///    - 왜 권한이 필요한지 구체적으로 설명
///    - 권한을 허용하면 어떤 이점이 있는지 명시
///    - 사용자 데이터가 안전하게 보호됨을 강조
///
/// 3. **쉬운 권한 활성화**:
///    - 설정 앱으로 이동하는 버튼 제공
///    - 단계별 안내로 사용자가 헷갈리지 않도록 함
///    - 어떤 권한을 활성화해야 하는지 명시
///
/// 4. **시각적 피드백**:
///    - 권한 거부 상태를 명확히 표시
///    - 하지만 경고나 에러처럼 부정적으로 보이지 않도록 함
///    - 정보 제공(informative)에 초점
///
/// ## iOS HealthKit 권한 특징
///
/// **권한 요청 제한**:
/// - iOS는 권한 다이얼로그를 한 번만 표시
/// - 사용자가 거부하면 다시 요청해도 다이얼로그가 뜨지 않음
/// - 설정 앱에서만 권한 변경 가능
///
/// **읽기 권한의 프라이버시**:
/// - 읽기 권한 거부 여부를 앱에서 확인 불가
/// - 사용자 프라이버시 보호를 위한 설계
/// - 데이터 읽기를 시도하고 실패하면 권한 없음을 추측
///
/// **쓰기 권한**:
/// - 쓰기 권한은 authorizationStatus로 확인 가능
/// - 거부 상태를 명확히 알 수 있음
///
/// ## 설정 앱 이동 제약사항
///
/// **iOS 제약**:
/// - HealthKit 설정 화면으로 직접 이동 불가
/// - 앱 설정 화면(설정 > Bodii)까지만 딥링크 가능
/// - 사용자가 수동으로 설정 > Health > Bodii로 이동해야 함
///
/// **대안**:
/// - 단계별 안내로 사용자가 쉽게 찾을 수 있도록 함
/// - 스크린샷을 포함하면 더 좋음 (여기서는 텍스트로만 안내)
///
/// ## 사용 흐름
///
/// ```swift
/// // 1. 권한 상태 확인
/// let authService = HealthKitAuthorizationService()
/// let summary = authService.getAuthorizationSummary()
///
/// // 2. 일부 권한이 거부되었거나 권한이 없는 경우
/// if !summary.isFullyAuthorized {
///     // HealthKitDeniedView 표시
///     .sheet(isPresented: $showDeniedView) {
///         HealthKitDeniedView(
///             onOpenSettings: {
///                 // 설정 앱이 열린 후 처리
///                 // (예: 사용자가 돌아왔을 때 권한 재확인)
///             }
///         )
///     }
/// }
///
/// // 3. 앱이 다시 활성화되면 권한 재확인
/// .onAppear {
///     Task {
///         let updated = authService.getAuthorizationSummary()
///         if updated.isFullyAuthorized {
///             // 권한이 활성화되었으므로 동기화 시작
///             await syncService.sync()
///         }
///     }
/// }
/// ```
///
/// ## 접근성
///
/// - VoiceOver 지원: 모든 단계와 버튼 설명 읽힘
/// - Dynamic Type: 텍스트 크기 자동 조정
/// - 명확한 단계 번호로 순서 파악 용이
///
/// ## 💡 Android 비교
///
/// **iOS (HealthKit)**:
/// - 설정 앱으로만 이동 가능
/// - HealthKit 설정 화면 직접 이동 불가
/// - 권한 다이얼로그 재표시 불가
///
/// **Android (Health Connect)**:
/// - Health Connect 설정 화면 직접 이동 가능
/// - 특정 권한 설정 화면까지 딥링크 가능
/// - 권한 다이얼로그 여러 번 표시 가능
///
/// ## 관련 파일
///
/// - `HealthKitPermissionView.swift`: 초기 권한 요청 화면
/// - `HealthKitAuthorizationService.swift`: 권한 상태 확인
/// - `HealthKitError.swift`: 권한 관련 에러 처리
///

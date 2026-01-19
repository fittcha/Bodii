//
//  SleepInputSheet.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Bottom Sheet for Sleep Input
// SwiftUI Sheet를 사용한 수면 시간 입력 화면
// 💡 Java 비교: Android의 BottomSheetDialogFragment와 유사

import SwiftUI

// MARK: - SleepInputSheet

/// 수면 시간 입력을 위한 Bottom Sheet
/// 📚 학습 포인트: Modal Sheet Pattern
/// - DurationPicker로 시간/분 입력
/// - 실시간 상태 미리보기 (SleepStatusBadge)
/// - 저장/건너뛰기 버튼
/// - 3회 건너뛰기 후 강제 입력 지원
/// - ViewModel과 통합하여 MVVM 패턴 구현
/// 💡 Java 비교: Android의 BottomSheetDialog + ViewModel과 유사
struct SleepInputSheet: View {

    // MARK: - Properties

    /// ViewModel - 수면 입력 데이터 관리
    /// 📚 학습 포인트: @StateObject
    /// - Sheet의 생명주기와 연결된 ObservableObject
    /// - Sheet가 사라져도 상태 유지 (재생성 시 새로 생성됨)
    /// 💡 Java 비교: Android ViewModel과 유사
    @StateObject private var viewModel: SleepInputViewModel

    /// Sheet 닫기 액션
    /// 📚 학습 포인트: @Environment(\.dismiss)
    /// - SwiftUI 환경 변수를 통해 Sheet 닫기
    /// - iOS 15+에서 사용 가능
    /// 💡 Java 비교: Activity.finish() 또는 dismiss()와 유사
    @Environment(\.dismiss) var dismiss

    /// 건너뛰기 가능 여부
    /// 📚 학습 포인트: Skip Control
    /// - true: 건너뛰기 버튼 표시 (기본값)
    /// - false: 저장만 가능 (3회 건너뛰기 후 강제 입력)
    var canSkip: Bool = true

    /// 건너뛰기 콜백
    /// 📚 학습 포인트: Optional Callback
    /// - 사용자가 건너뛰기를 선택했을 때 호출
    /// - SleepPromptManager에서 건너뛰기 횟수 증가에 사용
    var onSkip: (() -> Void)?

    // MARK: - Initialization

    /// SleepInputSheet 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel을 외부에서 주입받음
    /// - 테스트 시 Mock ViewModel 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameters:
    ///   - viewModel: 수면 입력 ViewModel
    ///   - canSkip: 건너뛰기 가능 여부 (기본값: true)
    ///   - onSkip: 건너뛰기 콜백 (기본값: nil)
    init(
        viewModel: SleepInputViewModel,
        canSkip: Bool = true,
        onSkip: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.canSkip = canSkip
        self.onSkip = onSkip
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack in Sheet
        // Sheet 내부에 NavigationStack을 넣어 타이틀과 툴바 사용
        NavigationStack {
            // 📚 학습 포인트: ScrollView for Content
            // 키보드가 올라올 때를 대비하여 스크롤 가능하게 구성
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더 섹션
                    headerSection

                    Divider()

                    // 피커 섹션
                    pickerSection

                    // 상태 미리보기 섹션
                    statusPreviewSection

                    // 요약 카드
                    summaryCard

                    Spacer()
                        .frame(height: 20)

                    // 버튼 섹션
                    buttonSection
                }
                .padding()
            }
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 📚 학습 포인트: Toolbar Item
                // 네비게이션 바에 닫기 버튼 추가 (건너뛰기 가능할 때만)
                if canSkip {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("닫기") {
                            dismiss()
                        }
                        .accessibilityLabel("닫기")
                        .accessibilityHint("두 번 탭하여 수면 입력 화면을 닫습니다")
                    }
                }
            }
            // 📚 학습 포인트: onChange Modifier
            // ViewModel의 isCompleted 상태 감지하여 자동으로 Sheet 닫기
            .onChange(of: viewModel.isCompleted) { _, completed in
                if completed {
                    dismiss()
                }
            }
            // 📚 학습 포인트: Alert for Errors
            // 에러 발생 시 알림 표시
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        // 📚 학습 포인트: Presentation Detents
        // Sheet의 높이를 medium으로 설정 (화면의 약 절반)
        .presentationDetents([.medium, .large])
        // 📚 학습 포인트: Interactive Dismiss Control
        // 강제 입력 모드일 때는 스와이프로 닫기 비활성화
        .interactiveDismissDisabled(!canSkip)
    }

    // MARK: - Subviews

    /// 헤더 섹션
    /// 📚 학습 포인트: Header with Icon and Text
    /// - 시각적으로 명확한 화면 목적 전달
    private var headerSection: some View {
        VStack(spacing: 8) {
            // 아이콘
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            // 제목
            Text("어젯밤 수면 시간")
                .font(.title2)
                .fontWeight(.bold)

            // 부제목
            Text("몇 시간 주무셨나요?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 강제 입력 안내 메시지 (건너뛰기 불가능할 때)
            if !canSkip {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Text("오늘은 꼭 입력해주세요")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.1))
                )
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("경고: 오늘은 꼭 입력해주세요")
            }
        }
    }

    /// 피커 섹션
    /// 📚 학습 포인트: Compact Picker in Sheet
    /// - 컴팩트 스타일로 공간 효율적 사용
    private var pickerSection: some View {
        VStack(spacing: 8) {
            Text("수면 시간 선택")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            // 📚 학습 포인트: DurationPicker Component
            // 재사용 가능한 피커 컴포넌트
            // ViewModel의 $hours, $minutes와 양방향 바인딩
            DurationPicker(
                compactStyle: $viewModel.hours,
                minutes: $viewModel.minutes
            )
        }
    }

    /// 상태 미리보기 섹션
    /// 📚 학습 포인트: Real-time Status Preview
    /// - 사용자가 시간을 조정할 때마다 예상 상태 표시
    /// - 즉각적인 피드백으로 UX 향상
    private var statusPreviewSection: some View {
        VStack(spacing: 12) {
            Text("예상 수면 상태")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            // 📚 학습 포인트: SleepStatusBadge Component
            // 재사용 가능한 상태 뱃지 컴포넌트
            // ViewModel의 expectedStatus (computed property)를 실시간으로 표시
            SleepStatusBadge(
                large: viewModel.expectedStatus,
                showBackground: true
            )

            // 상태 설명
            Text(viewModel.statusDescription())
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        // 📚 학습 포인트: Accessibility for Status Preview
        // 상태 미리보기 전체를 하나의 요소로 그룹화
        .accessibilityElement(children: .combine)
        .accessibilityLabel("예상 수면 상태: \(viewModel.expectedStatus.displayName), \(viewModel.statusDescription())")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// 요약 카드
    /// 📚 학습 포인트: Summary Card with Formatted Data
    /// - 입력된 시간을 시각적으로 강조
    private var summaryCard: some View {
        VStack(spacing: 8) {
            Text("총 수면 시간")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            // 📚 학습 포인트: Formatted Duration Display
            // ViewModel의 formattedDuration 사용
            Text(viewModel.formattedDuration)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.blue)

            // 권장 시간 안내
            Text(viewModel.recommendedRange())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.expectedStatus.color.opacity(0.1))
        )
        // 📚 학습 포인트: Accessibility for Summary Card
        // 요약 정보를 하나의 요소로 그룹화
        .accessibilityElement(children: .combine)
        .accessibilityLabel("총 수면 시간: \(viewModel.formattedDuration). \(viewModel.recommendedRange())")
        .accessibilityAddTraits(.isStaticText)
    }

    /// 버튼 섹션
    /// 📚 학습 포인트: Action Buttons
    /// - 저장과 건너뛰기 버튼 제공
    /// - 강제 입력 모드일 때는 저장 버튼만 표시
    private var buttonSection: some View {
        VStack(spacing: 12) {
            // 저장 버튼
            saveButton

            // 건너뛰기 버튼 (건너뛰기 가능할 때만 표시)
            if canSkip {
                skipButton
            }
        }
    }

    /// 저장 버튼
    /// 📚 학습 포인트: Primary Action Button
    /// - 비동기 저장 작업 실행
    /// - 저장 중에는 로딩 인디케이터 표시
    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveSleep()
            }
        }) {
            HStack {
                if viewModel.isSaving {
                    // 📚 학습 포인트: ProgressView
                    // 로딩 인디케이터 표시
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                }

                Text(viewModel.isSaving ? "저장 중..." : "저장")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.canSave ? Color.blue : Color.gray)
            )
            .foregroundStyle(.white)
        }
        .disabled(!viewModel.canSave)
        // 📚 학습 포인트: Accessibility for Save Button
        // VoiceOver가 버튼의 기능과 상태를 명확히 전달
        .accessibilityLabel(viewModel.isSaving ? "저장 중" : "수면 기록 저장")
        .accessibilityHint(viewModel.isSaving ? "" : "두 번 탭하여 \(viewModel.formattedDuration)의 수면 기록을 저장합니다")
    }

    /// 건너뛰기 버튼
    /// 📚 학습 포인트: Secondary Action Button
    /// - 덜 강조된 스타일 (텍스트만)
    /// - 건너뛰기 횟수 관리는 부모에서 처리
    private var skipButton: some View {
        Button(action: {
            // 📚 학습 포인트: Callback Pattern
            // 부모 뷰에서 건너뛰기 처리
            onSkip?()
            dismiss()
        }) {
            HStack {
                Image(systemName: "xmark.circle")
                    .font(.body)

                Text("나중에 입력하기")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.secondary)
        }
        // 📚 학습 포인트: Accessibility for Skip Button
        // VoiceOver가 버튼의 기능을 명확히 전달
        .accessibilityLabel("나중에 입력하기")
        .accessibilityHint("두 번 탭하여 수면 기록을 건너뛰고 나중에 입력합니다")
    }
}

// MARK: - Preview

#Preview("기본 상태 (건너뛰기 가능)") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Button("수면 입력하기") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                // Mock ViewModel 필요
                // SleepInputSheet(
                //     viewModel: .makePreview(),
                //     canSkip: true
                // )
                Text("Preview를 위해 Mock ViewModel이 필요합니다")
            }
        }
    }

    return PreviewWrapper()
}

#Preview("강제 입력 모드 (건너뛰기 불가)") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Button("수면 입력하기") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                // Mock ViewModel 필요
                // SleepInputSheet(
                //     viewModel: .makePreview(),
                //     canSkip: false
                // )
                Text("Preview를 위해 Mock ViewModel이 필요합니다")
            }
        }
    }

    return PreviewWrapper()
}

#Preview("다크 모드") {
    struct PreviewWrapper: View {
        @State private var showSheet = true

        var body: some View {
            Button("수면 입력하기") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                // Mock ViewModel 필요
                Text("Preview를 위해 Mock ViewModel이 필요합니다")
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepInputSheet 사용법
///
/// 기본 사용 (건너뛰기 가능):
/// ```swift
/// struct MyView: View {
///     @State private var showSleepInput = false
///     let container: DIContainer
///
///     var body: some View {
///         Button("수면 입력") {
///             showSleepInput = true
///         }
///         .sheet(isPresented: $showSleepInput) {
///             SleepInputSheet(
///                 viewModel: container.makeSleepInputViewModel(),
///                 canSkip: true
///             )
///         }
///     }
/// }
/// ```
///
/// 강제 입력 모드 (3회 건너뛰기 후):
/// ```swift
/// struct MyView: View {
///     @State private var showSleepInput = false
///     @StateObject private var promptManager = SleepPromptManager()
///     let container: DIContainer
///
///     var body: some View {
///         Button("수면 입력") {
///             showSleepInput = true
///         }
///         .sheet(isPresented: $showSleepInput) {
///             SleepInputSheet(
///                 viewModel: container.makeSleepInputViewModel(),
///                 canSkip: !promptManager.isForceEntry,
///                 onSkip: {
///                     promptManager.incrementSkipCount()
///                 }
///             )
///         }
///     }
/// }
/// ```
///
/// 자동 표시 (아침 프롬프트):
/// ```swift
/// struct ContentView: View {
///     @StateObject private var promptManager = SleepPromptManager()
///     let container: DIContainer
///
///     var body: some View {
///         MainView()
///             .sheet(isPresented: $promptManager.shouldShowPrompt) {
///                 SleepInputSheet(
///                     viewModel: container.makeSleepInputViewModel(),
///                     canSkip: !promptManager.isForceEntry,
///                     onSkip: {
///                         promptManager.incrementSkipCount()
///                     }
///                 )
///             }
///             .onAppear {
///                 promptManager.checkShouldShow()
///             }
///     }
/// }
/// ```
///
/// 주요 기능:
/// - DurationPicker로 시간/분 입력 (10분 단위)
/// - 실시간 수면 상태 미리보기 (SleepStatusBadge)
/// - 상태별 색상 피드백
/// - 저장 중 로딩 인디케이터
/// - 자동 Sheet 닫기 (저장 완료 후)
/// - 건너뛰기 버튼 (조건부 표시)
/// - 강제 입력 모드 (3회 건너뛰기 후)
/// - 에러 알림 표시
///
/// Sheet 설정:
/// - presentationDetents: .medium, .large (화면 절반 또는 전체)
/// - interactiveDismissDisabled: 강제 입력 시 스와이프 닫기 비활성화
/// - 닫기 버튼: 건너뛰기 가능할 때만 표시
///
/// 상태 관리:
/// - ViewModel의 @Published 프로퍼티 관찰
/// - @StateObject로 ViewModel 생명주기 관리
/// - onChange로 isCompleted 감지하여 자동 닫기
///
/// 비즈니스 플로우:
/// 1. Sheet 표시
/// 2. 사용자가 시간/분 선택 (DurationPicker)
/// 3. 실시간으로 expectedStatus 업데이트
/// 4. 저장 버튼 클릭 또는 건너뛰기
/// 5. 저장: ViewModel.saveSleep() 호출
///    - RecordSleepUseCase 실행
///    - 성공 시 isCompleted = true
///    - onChange에서 감지하여 Sheet 닫기
/// 6. 건너뛰기: onSkip 콜백 호출 후 Sheet 닫기
///
/// 건너뛰기 로직:
/// - canSkip = true: 건너뛰기 버튼 표시, 스와이프 닫기 가능
/// - canSkip = false: 저장만 가능, 스와이프 닫기 불가, 경고 메시지 표시
/// - onSkip 콜백: SleepPromptManager에서 건너뛰기 횟수 증가
/// - 3회 건너뛰기 후: canSkip = false로 강제 입력 모드
///
/// 💡 Android 비교:
/// - Android: BottomSheetDialogFragment + ViewModel
/// - SwiftUI: Sheet + @StateObject
/// - Android: DialogFragment.dismiss()
/// - SwiftUI: @Environment(\.dismiss)
/// - Android: setCancelable(false)
/// - SwiftUI: .interactiveDismissDisabled(true)
///
/// 접근성:
/// - VoiceOver 지원 (SF Symbols, 명확한 레이블)
/// - Dynamic Type 지원 (자동 폰트 크기 조정)
/// - 충분한 터치 영역 (버튼 높이 44pt 이상)
/// - 명확한 시각적 피드백 (색상 + 아이콘)
///
/// 실무 팁:
/// - Sheet는 medium detent로 시작하여 스크롤 가능
/// - 강제 입력 모드는 사용자 경험을 고려하여 신중하게 사용
/// - 건너뛰기 횟수는 UserDefaults에 날짜별로 저장
/// - 저장 성공 후 1.5초 대기하여 메시지를 보여준 후 닫기
/// - onChange로 isCompleted를 감지하여 자동 닫기 구현
///

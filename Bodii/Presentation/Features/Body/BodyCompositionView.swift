//
//  BodyCompositionView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Feature View in MVVM Pattern
// SwiftUI의 MVVM 패턴에서 View 역할 - UI만 담당
// 💡 Java 비교: Android의 Activity/Fragment와 유사하지만 더 선언적

import SwiftUI

// MARK: - BodyCompositionView

/// 신체 구성 메인 화면
/// 📚 학습 포인트: Feature View Pattern
/// - 입력 섹션, BMR/TDEE 표시, 최근 기록 리스트 포함
/// - ViewModel을 통해 상태 관리 및 비즈니스 로직 처리
/// - NavigationStack으로 트렌드 뷰로 이동 가능
/// 💡 Java 비교: Android의 Fragment + RecyclerView와 유사
struct BodyCompositionView: View {

    // MARK: - Properties

    /// ViewModel - 신체 구성 데이터 관리
    /// 📚 학습 포인트: @StateObject
    /// - View의 생명주기와 연결된 ObservableObject
    /// - View가 사라져도 상태 유지
    /// 💡 Java 비교: Android ViewModel과 유사
    @StateObject private var viewModel: BodyCompositionViewModel

    /// 트렌드 뷰 네비게이션 상태
    /// 📚 학습 포인트: @State for Navigation
    /// - NavigationStack의 경로 관리
    @State private var showTrendsView = false

    /// 상세 뷰에 표시할 엔트리
    /// 📚 학습 포인트: Optional State
    /// - nil이면 상세 뷰 미표시
    @State private var selectedEntry: BodyCompositionEntry?

    /// Pull-to-refresh 트리거
    /// 📚 학습 포인트: Refresh Control
    /// - 사용자가 당겨서 새로고침 가능
    @State private var isRefreshing = false

    // MARK: - Initialization

    /// BodyCompositionView 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel을 외부에서 주입받음
    /// - 테스트 시 Mock ViewModel 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameter viewModel: 신체 구성 ViewModel
    init(viewModel: BodyCompositionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack
        // iOS 16+의 새로운 네비게이션 시스템
        // 💡 Java 비교: Navigation Component와 유사
        NavigationStack {
            // 📚 학습 포인트: ScrollView with LazyVStack
            // 성능 최적화를 위해 보이는 부분만 렌더링
            ScrollView {
                VStack(spacing: 20) {
                    // 입력 섹션
                    inputSection

                    // BMR/TDEE 표시 섹션
                    if viewModel.latestMetabolism != nil {
                        metabolismSection
                    }

                    // 최근 기록 섹션
                    historySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("체성분")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trendsButton
                }
            }
            // 📚 학습 포인트: refreshable modifier
            // Pull-to-refresh 구현
            .refreshable {
                await refreshData()
            }
            // 📚 학습 포인트: Alert for Errors
            // 에러 발생 시 알림 표시
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            // 📚 학습 포인트: Toast-style Success Message
            // 성공 메시지를 화면 상단에 표시
            .overlay(alignment: .top) {
                if let successMessage = viewModel.successMessage {
                    successToast(message: successMessage)
                }
            }
            // 📚 학습 포인트: Sheet Navigation
            // 트렌드 뷰를 모달로 표시
            .sheet(isPresented: $showTrendsView) {
                // TODO: DIContainer에서 trendsViewModel을 주입받아 사용
                // BodyTrendsView(
                //     viewModel: container.makeBodyTrendsViewModel(),
                //     userGender: viewModel.userProfile?.gender,
                //     goalWeight: viewModel.userProfile?.goalWeight,
                //     goalBodyFat: viewModel.userProfile?.goalBodyFat
                // )
                Text("트렌드 뷰 (DIContainer 연결 필요)")
            }
        }
    }

    // MARK: - Subviews

    /// 입력 섹션
    /// 📚 학습 포인트: Extracted View
    /// - 복잡한 View를 작은 단위로 분리
    /// - 코드 가독성 및 재사용성 향상
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "신체 데이터 입력",
                icon: "square.and.pencil"
            )

            // 입력 카드
            BodyCompositionInputCard(
                weight: $viewModel.weightInput,
                bodyFatPercent: $viewModel.bodyFatPercentInput,
                muscleMass: $viewModel.muscleMassInput,
                validationMessages: viewModel.validationMessages,
                isEnabled: !viewModel.isSaving,
                onInputChanged: {
                    viewModel.validateInputs()
                }
            )

            // 저장 버튼
            saveButton
        }
    }

    /// BMR/TDEE 섹션
    /// 📚 학습 포인트: Conditional View
    /// - 최근 대사율 데이터가 있을 때만 표시
    private var metabolismSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "최근 대사율",
                icon: "flame.fill"
            )

            // 대사율 카드
            if let metabolism = viewModel.latestMetabolism {
                metabolismCard(metabolism: metabolism)
            }
        }
    }

    /// 최근 기록 섹션
    /// 📚 학습 포인트: List in ScrollView
    /// - 제한된 높이의 리스트로 표시
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack {
                sectionHeader(
                    title: "최근 기록",
                    icon: "clock.arrow.circlepath"
                )

                Spacer()

                // 기록 개수 표시
                if !viewModel.history.isEmpty {
                    Text("\(viewModel.history.count)개")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 기록 리스트
            if viewModel.isLoading {
                loadingView
            } else if viewModel.history.isEmpty {
                emptyHistoryView
            } else {
                historyList
            }
        }
    }

    /// 저장 버튼
    /// 📚 학습 포인트: Button with Async Action
    /// - Task를 사용하여 비동기 작업 실행
    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveBodyComposition()
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
    }

    /// 트렌드 버튼
    /// 📚 학습 포인트: Toolbar Item
    /// - 네비게이션 바에 버튼 추가
    private var trendsButton: some View {
        Button(action: {
            showTrendsView = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.subheadline)
                Text("트렌드")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
        }
    }

    /// 대사율 카드
    /// 📚 학습 포인트: Reusable Component Function
    /// - 반복되는 UI 패턴을 함수로 추출
    ///
    /// - Parameter metabolism: 대사율 데이터
    /// - Returns: 대사율 표시 카드
    private func metabolismCard(metabolism: MetabolismData) -> some View {
        VStack(spacing: 16) {
            // BMR/TDEE 값
            HStack(spacing: 20) {
                // BMR
                metabolismValueItem(
                    title: "BMR",
                    value: formatCalories(metabolism.bmr),
                    icon: "bed.double.fill",
                    color: .blue
                )

                Divider()
                    .frame(height: 50)

                // TDEE
                metabolismValueItem(
                    title: "TDEE",
                    value: formatCalories(metabolism.tdee),
                    icon: "figure.walk",
                    color: .green
                )
            }

            Divider()

            // 활동 수준
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("활동 수준")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(metabolism.activityLevel.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // 활동 계수 표시
                Text("\(String(format: "%.2f", metabolism.activityLevel.multiplier))x")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }

            // 측정 날짜
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("측정일: \(formatDate(metabolism.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 개별 대사량 값 아이템
    /// 📚 학습 포인트: Reusable Component Function
    ///
    /// - Parameters:
    ///   - title: 제목 (BMR, TDEE 등)
    ///   - value: 칼로리 값
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 색상
    /// - Returns: 값 표시 뷰
    private func metabolismValueItem(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 레이블
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            // 값
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // 단위
            Text("kcal/일")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 기록 리스트
    /// 📚 학습 포인트: LazyVStack for Performance
    /// - 보이는 부분만 렌더링하여 성능 최적화
    private var historyList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.history) { entry in
                historyRow(entry: entry)
                    .onTapGesture {
                        selectedEntry = entry
                    }
            }
        }
    }

    /// 기록 행
    /// 📚 학습 포인트: List Item Component
    /// - 각 기록을 카드 형태로 표시
    ///
    /// - Parameter entry: 신체 구성 엔트리
    /// - Returns: 기록 행 뷰
    private func historyRow(entry: BodyCompositionEntry) -> some View {
        HStack(spacing: 16) {
            // 날짜
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDateShort(entry.date))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(formatTime(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // HealthKit 출처 표시
                if entry.isFromHealthKit {
                    HStack(spacing: 2) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 8))
                        Text("동기화")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(.green)
                    .padding(.top, 2)
                }
            }
            .frame(width: 60, alignment: .leading)

            Divider()
                .frame(height: 40)

            // 측정값들
            VStack(alignment: .leading, spacing: 4) {
                // 체중
                measurementRow(
                    icon: "scalemass",
                    label: "체중",
                    value: "\(formatDecimal(entry.weight)) kg"
                )

                // 체지방률
                measurementRow(
                    icon: "percent",
                    label: "체지방률",
                    value: "\(formatDecimal(entry.bodyFatPercent))%"
                )

                // 근육량
                measurementRow(
                    icon: "figure.strengthtraining.traditional",
                    label: "근육량",
                    value: "\(formatDecimal(entry.muscleMass)) kg"
                )
            }

            Spacer()

            // 삭제 버튼
            Button(action: {
                Task {
                    await viewModel.deleteEntry(id: entry.id)
                }
            }) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(cardBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    /// 측정값 행
    /// 📚 학습 포인트: Micro Component
    /// - 매우 작은 단위의 재사용 가능한 컴포넌트
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - label: 레이블
    ///   - value: 값
    /// - Returns: 측정값 행 뷰
    private func measurementRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("기록을 불러오는 중...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }

    /// 빈 히스토리 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyHistoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("아직 기록이 없습니다")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text("위에서 신체 데이터를 입력하고\n저장 버튼을 눌러 기록을 시작하세요")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    /// 섹션 헤더
    /// 📚 학습 포인트: Section Header Component
    ///
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - icon: SF Symbol 아이콘
    /// - Returns: 섹션 헤더 뷰
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }

    /// 성공 토스트
    /// 📚 학습 포인트: Toast Notification
    /// - 저장 성공 시 화면 상단에 표시
    ///
    /// - Parameter message: 성공 메시지
    /// - Returns: 토스트 뷰
    private func successToast(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: viewModel.successMessage != nil)
    }

    /// 카드 배경
    /// 📚 학습 포인트: Adaptive Colors
    /// - 라이트/다크 모드에 자동 대응하는 색상
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
    }

    // MARK: - Helper Methods

    /// 데이터 새로고침
    /// 📚 학습 포인트: Pull-to-Refresh
    /// - 사용자가 아래로 당길 때 실행
    private func refreshData() async {
        await viewModel.loadHistory()
    }

    /// 칼로리 값 포맷팅
    /// 📚 학습 포인트: Number Formatting
    ///
    /// - Parameter calories: 칼로리 값
    /// - Returns: 포맷된 문자열 (예: "1,650")
    private func formatCalories(_ calories: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let number = NSDecimalNumber(decimal: calories)
        return formatter.string(from: number) ?? "\(calories)"
    }

    /// Decimal 값 포맷팅
    /// 📚 학습 포인트: Decimal Formatting
    ///
    /// - Parameter value: Decimal 값
    /// - Returns: 포맷된 문자열 (예: "70.5")
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? "\(value)"
    }

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "2026년 1월 12일")
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 짧은 날짜 포맷팅
    /// 📚 학습 포인트: Short Date Format
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "01/12")
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    /// 시간 포맷팅
    /// 📚 학습 포인트: Time Formatting
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "14:30")
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("기본 상태") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    // BodyCompositionView(viewModel: .makePreview())
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("데이터 있음") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("빈 상태") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("다크 모드") {
    // TODO: ViewModel Mock 구현 후 Preview 추가
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
        .preferredColorScheme(.dark)
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: BodyCompositionView 사용법
///
/// 기본 사용 (DIContainer에서 생성):
/// ```swift
/// struct ContentView: View {
///     let container: DIContainer
///
///     var body: some View {
///         TabView {
///             BodyCompositionView(
///                 viewModel: container.makeBodyCompositionViewModel()
///             )
///             .tabItem {
///                 Label("체성분", systemImage: "figure.stand")
///             }
///         }
///     }
/// }
/// ```
///
/// 주요 기능:
/// - 신체 데이터 입력 (체중, 체지방률, 근육량)
/// - 실시간 입력 검증 및 피드백
/// - 자동 BMR/TDEE 계산 및 표시
/// - 최근 기록 리스트 표시
/// - 기록 삭제 기능
/// - Pull-to-refresh 새로고침
/// - 트렌드 뷰로 이동
/// - 성공/에러 메시지 표시
///
/// 화면 구성:
/// 1. 입력 섹션: BodyCompositionInputCard 사용
/// 2. 대사율 섹션: 최근 BMR/TDEE 표시
/// 3. 히스토리 섹션: 최근 30일 기록 리스트
///
/// 네비게이션:
/// - NavigationStack 사용
/// - 트렌드 버튼으로 BodyTrendsView(sheet) 이동
/// - 기록 탭으로 BodyRecordDetailView 이동 (TODO)
///
/// 상태 관리:
/// - ViewModel의 @Published 프로퍼티 관찰
/// - @StateObject로 ViewModel 생명주기 관리
/// - @State로 로컬 UI 상태 관리
///
/// 에러 처리:
/// - Alert로 에러 메시지 표시
/// - ViewModel에서 에러 상태 관리
/// - 사용자 친화적인 한글 메시지
///
/// 💡 Android 비교:
/// - Android: Fragment + RecyclerView + ViewModel
/// - SwiftUI: View + ScrollView + LazyVStack + @StateObject
/// - Android: LiveData.observe()
/// - SwiftUI: @Published + automatic updates
/// - Android: SwipeRefreshLayout
/// - SwiftUI: .refreshable modifier
///
/// 접근성:
/// - VoiceOver 지원
/// - Dynamic Type 지원
/// - 충분한 터치 영역
/// - 명확한 레이블과 힌트
///

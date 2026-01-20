//
//  SleepHistoryView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: List View with CRUD Operations
// 수면 기록 리스트 화면 (편집/삭제 기능 포함)
// 💡 Java 비교: Android의 RecyclerView + CRUD Fragment와 유사

import SwiftUI

// MARK: - SleepHistoryView

/// 수면 기록 리스트 화면
/// 📚 학습 포인트: List View with Edit/Delete
/// - 수면 기록 리스트 표시
/// - 스와이프로 삭제 기능
/// - 탭으로 편집 기능
/// - 플로팅 추가 버튼
/// - 빈 상태 처리
/// - 통계 요약 표시
/// 💡 Java 비교: Android의 CRUD Fragment + RecyclerView와 유사
struct SleepHistoryView: View {

    // MARK: - Properties

    /// ViewModel - 수면 기록 리스트 관리
    /// 📚 학습 포인트: @StateObject
    /// - View의 생명주기와 연결된 ObservableObject
    /// - View가 사라져도 상태 유지
    /// 💡 Java 비교: Android ViewModel과 유사
    @StateObject private var viewModel: SleepHistoryViewModel

    /// DIContainer for creating ViewModels
    /// 📚 학습 포인트: Dependency Injection
    /// - 새 레코드 추가/편집 시 ViewModel 생성에 사용
    let container: DIContainer

    /// 사용자 ID
    /// 📚 학습 포인트: User Context
    /// - 수면 기록 추가/편집 시 사용자 식별에 사용
    let userId: UUID

    /// 추가 버튼 표시 여부
    /// 📚 학습 포인트: Optional Feature Toggle
    /// - true: 플로팅 추가 버튼 표시 (기본값)
    /// - false: 추가 버튼 숨김
    var showAddButton: Bool = true

    /// 새 레코드 추가 시트 표시 여부
    /// 📚 학습 포인트: Sheet State
    /// - true일 때 SleepInputSheet 표시
    @State private var showAddSheet: Bool = false

    /// 화면 닫기 액션
    /// 📚 학습 포인트: Environment Dismiss
    /// - Sheet나 NavigationStack에서 화면을 닫을 때 사용
    /// 💡 Java 비교: finish() 또는 popBackStack()과 유사
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// SleepHistoryView 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel과 DIContainer를 외부에서 주입받음
    /// - 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameters:
    ///   - viewModel: 수면 기록 리스트 ViewModel
    ///   - container: DIContainer for creating ViewModels
    ///   - userId: 사용자 ID
    ///   - showAddButton: 추가 버튼 표시 여부 (기본값: true)
    init(
        viewModel: SleepHistoryViewModel,
        container: DIContainer,
        userId: UUID,
        showAddButton: Bool = true
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
        self.userId = userId
        self.showAddButton = showAddButton
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack
        // iOS 16+의 새로운 네비게이션 시스템
        // 💡 Java 비교: Navigation Component와 유사
        NavigationStack {
            ZStack {
                // 메인 리스트
                if viewModel.isLoading && viewModel.isEmpty {
                    // 📚 학습 포인트: Loading State
                    // 초기 로딩 중일 때만 표시
                    loadingView
                } else if viewModel.isEmpty {
                    // 📚 학습 포인트: Empty State
                    // 데이터가 없을 때 안내 메시지
                    emptyStateView
                } else {
                    // 📚 학습 포인트: List with Sections
                    // 통계 섹션 + 레코드 리스트
                    listView
                }

                // 플로팅 추가 버튼
                if showAddButton {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            addButton
                        }
                    }
                }
            }
            .navigationTitle("수면 기록")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // 조회 모드 선택 메뉴
                ToolbarItem(placement: .navigationBarTrailing) {
                    queryModeMenu
                }
            }
            // 📚 학습 포인트: refreshable modifier
            // Pull-to-refresh 구현
            .refreshable {
                await viewModel.refresh()
            }
            // 📚 학습 포인트: Sheet for Adding New Record
            // 새 레코드 추가 시트
            .sheet(isPresented: $showAddSheet) {
                SleepInputSheet(
                    viewModel: container.makeSleepInputViewModel(userId: userId),
                    canSkip: true,
                    onSkip: nil
                )
            }
            // 📚 학습 포인트: Sheet for Editing Record
            // 레코드 편집 시트
            .sheet(item: $viewModel.recordToEdit) { record in
                SleepInputSheet(
                    viewModel: container.makeSleepInputViewModel(
                        userId: userId,
                        defaultHours: Int(record.duration / 60),
                        defaultMinutes: Int(record.duration % 60)
                    ),
                    canSkip: true,
                    onSkip: nil
                )
            }
            // 📚 학습 포인트: Confirmation Dialog
            // 삭제 확인 대화상자
            .confirmationDialog(
                "수면 기록을 삭제하시겠습니까?",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive) {
                    Task {
                        await viewModel.deleteRecord()
                    }
                }
                Button("취소", role: .cancel) {
                    viewModel.cancelDelete()
                }
            } message: {
                Text("삭제된 데이터는 복구할 수 없습니다.")
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
            // 📚 학습 포인트: Toast for Success
            // 성공 메시지 표시 (간단한 방법)
            .overlay(alignment: .top) {
                if let successMessage = viewModel.successMessage {
                    successToast(message: successMessage)
                        .padding(.top, 60)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 리스트 뷰
    /// 📚 학습 포인트: List with Sections
    /// - 통계 섹션 + 레코드 리스트
    private var listView: some View {
        List {
            // 통계 섹션
            statisticsSection

            // 레코드 리스트 섹션
            recordsSection
        }
        .listStyle(.insetGrouped)
    }

    /// 통계 섹션
    /// 📚 학습 포인트: Statistics Summary Section
    /// - 평균 수면 시간, 가장 많은 상태 표시
    private var statisticsSection: some View {
        Section {
            VStack(spacing: 12) {
                // 평균 수면 시간
                statisticRow(
                    icon: "clock.fill",
                    title: "평균 수면 시간",
                    value: viewModel.averageDurationString,
                    color: .blue
                )

                Divider()

                // 가장 많은 상태
                statisticRow(
                    icon: "moon.stars.fill",
                    title: "가장 많은 상태",
                    value: viewModel.mostCommonStatusString,
                    color: .orange
                )

                Divider()

                // 총 기록 수
                statisticRow(
                    icon: "list.bullet",
                    title: "총 기록 수",
                    value: "\(viewModel.recordCount)개",
                    color: .green
                )
            }
            .padding(.vertical, 8)
        } header: {
            Text("통계 요약")
        }
    }

    /// 개별 통계 Row
    /// 📚 학습 포인트: Reusable Statistic Row
    /// - 통계 정보를 일관된 형식으로 표시
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - title: 통계 제목
    ///   - value: 통계 값
    ///   - color: 아이콘 색상
    /// - Returns: 통계 Row 뷰
    private func statisticRow(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            // 제목
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // 값
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        // 📚 학습 포인트: Accessibility for Statistic Row
        // 통계 정보를 하나의 요소로 그룹화하여 VoiceOver가 읽어줌
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityAddTraits(.isStaticText)
    }

    /// 레코드 리스트 섹션
    /// 📚 학습 포인트: List Section with ForEach
    /// - 레코드를 반복하여 Row 표시
    /// - 스와이프 액션으로 편집/삭제
    private var recordsSection: some View {
        Section {
            ForEach(viewModel.records) { record in
                // 📚 학습 포인트: SleepRecordRow Component
                // 재사용 가능한 Row 컴포넌트
                SleepRecordRow(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 📚 학습 포인트: Tap to Edit
                        // 탭하여 편집 시트 열기
                        viewModel.editRecord(record)
                    }
                    // 📚 학습 포인트: Swipe Actions
                    // 왼쪽 스와이프: 편집
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.editRecord(record)
                        } label: {
                            Label("편집", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    // 오른쪽 스와이프: 삭제
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(record: record)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        } header: {
            HStack {
                Text("수면 기록")
                Spacer()
                Text(queryModeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if !viewModel.isEmpty {
                Text("레코드를 탭하면 편집할 수 있습니다.\n스와이프하여 편집 또는 삭제할 수 있습니다.")
                    .font(.caption)
            }
        }
    }

    /// 조회 모드 설명
    /// 📚 학습 포인트: Dynamic Description
    /// - 현재 선택된 조회 모드에 따라 다른 문구 표시
    private var queryModeDescription: String {
        switch viewModel.selectedMode {
        case .all:
            return "전체"
        case .recent(let days):
            return "최근 \(days)일"
        case .dateRange(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = Locale(identifier: "ko_KR")
            return "\(formatter.string(from: start)) ~ \(formatter.string(from: end))"
        }
    }

    /// 조회 모드 선택 메뉴
    /// 📚 학습 포인트: Menu for Query Mode Selection
    /// - 전체, 최근 7일/30일/90일 선택
    private var queryModeMenu: some View {
        Menu {
            Button {
                viewModel.changeMode(to: .all)
            } label: {
                Label("전체 기록", systemImage: "calendar")
            }

            Divider()

            Button {
                viewModel.changeMode(to: .recent(days: 7))
            } label: {
                Label("최근 7일", systemImage: "7.circle")
            }

            Button {
                viewModel.changeMode(to: .recent(days: 30))
            } label: {
                Label("최근 30일", systemImage: "30.circle")
            }

            Button {
                viewModel.changeMode(to: .recent(days: 90))
            } label: {
                Label("최근 90일", systemImage: "90.circle")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.body)
                .foregroundStyle(.blue)
        }
        // 📚 학습 포인트: Accessibility for Menu
        // VoiceOver가 메뉴의 기능을 명확히 전달
        .accessibilityLabel("조회 기간 필터")
        .accessibilityHint("두 번 탭하여 표시할 기록의 기간을 선택합니다. 현재 \(queryModeDescription)")
    }

    /// 플로팅 추가 버튼
    /// 📚 학습 포인트: Floating Action Button
    /// - 화면 오른쪽 하단에 고정
    /// - 새 레코드 추가 시트 열기
    private var addButton: some View {
        Button(action: {
            showAddSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("추가")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        // 📚 학습 포인트: Accessibility for Floating Button
        // VoiceOver가 버튼의 기능을 명확히 전달
        .accessibilityLabel("수면 기록 추가")
        .accessibilityHint("두 번 탭하여 새로운 수면 기록을 추가합니다")
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 아이콘
            Image(systemName: "moon.zzz")
                .font(.system(size: 80))
                .foregroundStyle(.gray.opacity(0.3))
                .accessibilityHidden(true)

            // 메시지
            VStack(spacing: 12) {
                Text("수면 기록이 없습니다")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("수면 시간을 기록하면\n여기에 표시됩니다.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 추가 버튼 (플로팅 버튼이 없을 때만)
            if !showAddButton {
                Button(action: {
                    showAddSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("수면 기록 추가하기")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
                .padding(.top, 8)
                .accessibilityLabel("수면 기록 추가하기")
                .accessibilityHint("두 번 탭하여 첫 번째 수면 기록을 추가합니다")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
        // 📚 학습 포인트: Accessibility for Empty State
        // 빈 상태 전체에 대한 설명 추가
        .accessibilityElement(children: .contain)
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("수면 기록을 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 📚 학습 포인트: Accessibility for Loading State
        // VoiceOver가 로딩 상태를 명확히 전달
        .accessibilityElement(children: .combine)
        .accessibilityLabel("수면 기록을 불러오는 중입니다")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// 성공 토스트
    /// 📚 학습 포인트: Success Toast Message
    /// - 삭제 성공 시 짧은 메시지 표시
    ///
    /// - Parameter message: 표시할 메시지
    /// - Returns: 토스트 뷰
    private func successToast(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.green)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: viewModel.successMessage != nil)
        .onAppear {
            // 📚 학습 포인트: Auto-dismiss Toast
            // 2초 후 자동으로 토스트 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.clearSuccess()
            }
        }
    }
}

// MARK: - Preview

#Preview("기본 상태 (데이터 있음)") {
    // Mock ViewModel 필요
    // SleepHistoryView(
    //     viewModel: .makePreviewWithData(),
    //     container: .shared
    // )
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("빈 상태") {
    // Mock ViewModel 필요
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("로딩 중") {
    // Mock ViewModel 필요
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
}

#Preview("다크 모드") {
    // Mock ViewModel 필요
    Text("Preview를 위해 Mock ViewModel이 필요합니다")
        .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepHistoryView 사용법
///
/// 기본 사용 (DIContainer에서 생성):
/// ```swift
/// struct ContentView: View {
///     let container: DIContainer
///
///     var body: some View {
///         SleepHistoryView(
///             viewModel: container.makeSleepHistoryViewModel(),
///             container: container
///         )
///     }
/// }
/// ```
///
/// NavigationLink로 표시:
/// ```swift
/// NavigationLink("수면 기록") {
///     SleepHistoryView(
///         viewModel: historyViewModel,
///         container: container
///     )
/// }
/// ```
///
/// Sheet로 표시:
/// ```swift
/// struct MyView: View {
///     @State private var showHistory = false
///
///     var body: some View {
///         Button("수면 기록 보기") {
///             showHistory = true
///         }
///         .sheet(isPresented: $showHistory) {
///             SleepHistoryView(
///                 viewModel: historyViewModel,
///                 container: container
///             )
///         }
///     }
/// }
/// ```
///
/// 추가 버튼 없이 사용:
/// ```swift
/// SleepHistoryView(
///     viewModel: historyViewModel,
///     container: container,
///     showAddButton: false
/// )
/// ```
///
/// 주요 기능:
/// - 수면 기록 리스트 표시
/// - 통계 요약 (평균 수면 시간, 가장 많은 상태, 총 기록 수)
/// - 조회 모드 선택 (전체, 최근 7/30/90일)
/// - 레코드 탭으로 편집
/// - 레코드 스와이프로 편집/삭제
/// - 플로팅 추가 버튼
/// - 삭제 확인 대화상자
/// - Pull-to-refresh 새로고침
/// - 빈 상태 처리
/// - 로딩 상태 처리
/// - 에러 알림 표시
/// - 성공 토스트 메시지
///
/// 화면 구성:
/// 1. 통계 요약 섹션: 평균 수면 시간, 가장 많은 상태, 총 기록 수
/// 2. 수면 기록 섹션: SleepRecordRow로 각 레코드 표시
/// 3. 플로팅 추가 버튼: 화면 오른쪽 하단 고정
/// 4. 조회 모드 메뉴: 네비게이션 바 오른쪽
///
/// 사용자 인터랙션:
/// - 탭: 레코드 편집 시트 열기
/// - 왼쪽 스와이프: 편집 버튼 표시
/// - 오른쪽 스와이프: 삭제 버튼 표시
/// - 플로팅 버튼: 새 레코드 추가 시트 열기
/// - Pull-to-refresh: 데이터 새로고침
/// - 조회 모드 메뉴: 표시 기간 변경
///
/// 비즈니스 플로우:
/// 1. ViewModel 초기화 시 자동으로 데이터 로드
/// 2. 사용자가 조회 모드 변경 → 자동 리로드
/// 3. 레코드 탭 → editRecord() 호출 → 편집 시트 표시
/// 4. 레코드 스와이프 삭제 → confirmDelete() → 확인 대화상자 → deleteRecord()
/// 5. 플로팅 버튼 탭 → 추가 시트 표시
/// 6. 시트에서 저장 완료 → 시트 닫힘 → didFinishEditing() → 데이터 리로드
///
/// 삭제 플로우:
/// 1. 사용자가 레코드를 오른쪽 스와이프
/// 2. 삭제 버튼 표시
/// 3. 삭제 버튼 탭 → confirmDelete()
/// 4. 확인 대화상자 표시
/// 5. "삭제" 선택 → deleteRecord()
/// 6. Repository를 통해 레코드 삭제
/// 7. 성공 토스트 표시
/// 8. 데이터 리로드
///
/// 편집 플로우:
/// 1. 사용자가 레코드를 탭 (또는 왼쪽 스와이프 후 편집 버튼)
/// 2. editRecord() 호출
/// 3. recordToEdit 설정
/// 4. .sheet(item:) 트리거
/// 5. SleepInputSheet 표시 (기존 값으로 초기화)
/// 6. 편집 완료 → didFinishEditing()
/// 7. recordToEdit = nil → 시트 닫힘
/// 8. 데이터 리로드
///
/// 상태 관리:
/// - viewModel.historyOutput: 조회된 레코드 리스트
/// - viewModel.selectedMode: 현재 조회 모드
/// - viewModel.isLoading: 로딩 중 상태
/// - viewModel.isEmpty: 빈 상태 여부
/// - viewModel.recordToEdit: 편집할 레코드 (시트 트리거)
/// - viewModel.showDeleteConfirmation: 삭제 확인 대화상자 표시 여부
/// - viewModel.errorMessage: 에러 메시지
/// - viewModel.successMessage: 성공 메시지
/// - showAddSheet: 추가 시트 표시 여부
///
/// 조회 모드:
/// - .all: 전체 기록
/// - .recent(days: 7): 최근 7일
/// - .recent(days: 30): 최근 30일 (기본값)
/// - .recent(days: 90): 최근 90일
/// - .dateRange(start, end): 날짜 범위 (향후 구현)
///
/// 💡 Android 비교:
/// - Android: Fragment + RecyclerView + SwipeRefreshLayout
/// - SwiftUI: View + List + .refreshable
/// - Android: RecyclerView.ItemTouchHelper for swipe
/// - SwiftUI: .swipeActions modifier
/// - Android: FloatingActionButton
/// - SwiftUI: Floating Button in ZStack
/// - Android: Menu for filter options
/// - SwiftUI: Menu for query mode selection
/// - Android: BottomSheetDialogFragment for input
/// - SwiftUI: .sheet for SleepInputSheet
///
/// 접근성:
/// - VoiceOver: 모든 버튼과 레코드에 명확한 레이블
/// - Dynamic Type: 자동 폰트 크기 조정
/// - 충분한 터치 영역: 최소 44pt
/// - 색상 + 아이콘: 이중 시각적 표시
/// - 명확한 피드백: 토스트, 알림, 확인 대화상자
///
/// 성능 최적화:
/// - List는 자동으로 보이는 부분만 렌더링
/// - ViewModel에서 데이터 캐싱
/// - selectedMode 변경 시 debounce로 중복 호출 방지
/// - Pull-to-refresh는 async/await로 구현
///
/// 실무 팁:
/// - 삭제는 반드시 확인 대화상자로 사용자 확인 받기
/// - 성공/에러 메시지로 명확한 피드백 제공
/// - 빈 상태에서 명확한 안내와 액션 버튼 제공
/// - 플로팅 버튼은 리스트와 겹치지 않도록 padding 조정
/// - 스와이프 액션은 직관적인 색상과 아이콘 사용
/// - 통계 요약으로 데이터에 대한 인사이트 제공
/// - 조회 모드로 사용자가 원하는 범위의 데이터만 조회
///
/// 의존성:
/// - SleepHistoryViewModel: 데이터 로드, 편집/삭제 로직
/// - SleepRecordRow: 개별 레코드 표시 컴포넌트
/// - SleepInputSheet: 추가/편집 입력 시트
/// - DIContainer: ViewModel 생성을 위한 팩토리
///

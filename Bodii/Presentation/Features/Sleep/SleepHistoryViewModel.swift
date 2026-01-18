//
//  SleepHistoryViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: History List ViewModel Pattern
// 수면 기록 히스토리 리스트 표시 및 편집/삭제를 위한 ViewModel
// 💡 Java 비교: Android의 ViewModel과 유사하지만 SwiftUI의 @Published 사용

import Foundation
import SwiftUI
import Combine

// MARK: - SleepHistoryViewModel

/// 수면 기록 히스토리 리스트를 위한 ViewModel
/// 📚 학습 포인트: MVVM Pattern for List View
/// - 히스토리 데이터 로드 및 관리
/// - 레코드 삭제 기능
/// - 레코드 편집 트리거
/// - 조회 모드 변경 (전체, 최근 N일, 날짜 범위)
/// - 빈 상태 및 로딩 상태 처리
/// 💡 Java 비교: Android ViewModel + LiveData<List> 패턴
@MainActor
class SleepHistoryViewModel: ObservableObject {

    // MARK: - Published Properties (View State)

    /// 히스토리 데이터 출력
    /// 📚 학습 포인트: Optional State
    /// - nil이면 아직 데이터 로드 안 됨
    /// - 값이 있으면 리스트에 표시
    /// 💡 Java 비교: LiveData<HistoryOutput?>와 유사
    @Published var historyOutput: FetchSleepHistoryUseCase.Output?

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 데이터 조회 중 로딩 인디케이터 표시
    /// - 삭제 작업 중에도 true
    @Published var isLoading: Bool = false

    /// 에러 메시지
    /// 📚 학습 포인트: Error State
    /// - nil이면 에러 없음
    /// - 값이 있으면 에러 메시지 표시 (Alert 등)
    @Published var errorMessage: String?

    /// 성공 메시지
    /// 📚 학습 포인트: Success Feedback
    /// - 삭제 성공 시 사용자에게 피드백 제공
    @Published var successMessage: String?

    /// 선택된 조회 모드
    /// 📚 학습 포인트: Query Mode State
    /// - 사용자가 선택한 조회 모드
    /// - 변경 시 자동으로 데이터 다시 로드
    /// 💡 Java 비교: LiveData<QueryMode>와 유사
    @Published var selectedMode: FetchSleepHistoryUseCase.QueryMode = .recent(days: 30)

    /// 편집할 레코드
    /// 📚 학습 포인트: Sheet Trigger State
    /// - nil이면 편집 시트 닫힘
    /// - 값이 있으면 편집 시트 열림
    /// - SwiftUI의 .sheet(item:) 바인딩에 사용
    @Published var recordToEdit: SleepRecord?

    /// 삭제 확인 대화상자 표시 여부
    /// 📚 학습 포인트: Confirmation Dialog State
    /// - 삭제 전 사용자 확인 받기
    @Published var showDeleteConfirmation: Bool = false

    /// 삭제할 레코드 ID
    /// 📚 학습 포인트: Pending Action State
    /// - 삭제 확인 대기 중인 레코드
    private var recordIdToDelete: UUID?

    // MARK: - Private Properties

    /// 수면 히스토리 조회 Use Case
    /// 📚 학습 포인트: Dependency Injection
    /// - Use Case를 외부에서 주입받아 사용
    /// - 테스트 시 Mock으로 교체 가능
    private let fetchSleepHistoryUseCase: FetchSleepHistoryUseCase

    /// 수면 데이터 저장소
    /// 📚 학습 포인트: Repository Pattern
    /// - 삭제 및 업데이트 작업을 위해 필요
    /// - Protocol을 통해 주입받아 사용
    private let sleepRepository: SleepRepositoryProtocol

    /// Combine 구독 저장소
    /// 📚 학습 포인트: Reactive Programming
    /// - selectedMode 변경 시 자동으로 데이터 다시 로드
    /// - 메모리 누수 방지를 위한 구독 관리
    /// 💡 Java 비교: RxJava의 CompositeDisposable과 유사
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// SleepHistoryViewModel 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - fetchSleepHistoryUseCase: 수면 히스토리 조회 Use Case
    ///   - sleepRepository: 수면 데이터 저장소
    ///   - defaultMode: 기본 조회 모드 (기본값: 최근 30일)
    init(
        fetchSleepHistoryUseCase: FetchSleepHistoryUseCase,
        sleepRepository: SleepRepositoryProtocol,
        defaultMode: FetchSleepHistoryUseCase.QueryMode = .recent(days: 30)
    ) {
        self.fetchSleepHistoryUseCase = fetchSleepHistoryUseCase
        self.sleepRepository = sleepRepository
        self.selectedMode = defaultMode

        // 📚 학습 포인트: Reactive State Observation
        // selectedMode 변경 시 자동으로 데이터 다시 로드
        setupModeObserver()

        // 초기 데이터 로드
        Task {
            await loadHistory()
        }
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    /// 📚 학습 포인트: Computed Property for Empty State
    /// - View에서 empty state UI 표시 여부 결정
    var isEmpty: Bool {
        historyOutput?.isEmpty ?? true
    }

    /// 데이터 개수
    /// 📚 학습 포인트: Quick Access Property
    /// - UI에서 바로 사용할 수 있는 편의 속성
    var recordCount: Int {
        historyOutput?.count ?? 0
    }

    /// 수면 기록 배열
    /// 📚 학습 포인트: Convenience Property
    /// - View에서 직접 접근 가능한 레코드 배열
    /// - List에 바로 사용 가능
    var records: [SleepRecord] {
        historyOutput?.records ?? []
    }

    /// 평균 수면 시간 문자열
    /// 📚 학습 포인트: UI Helper Property
    /// - 통계 표시를 위한 포맷팅된 문자열
    var averageDurationString: String {
        guard let avg = historyOutput?.averageDurationFormatted else {
            return "-"
        }
        if avg.minutes == 0 {
            return "\(avg.hours)시간"
        } else {
            return "\(avg.hours)시간 \(avg.minutes)분"
        }
    }

    /// 가장 많은 수면 상태 문자열
    /// 📚 학습 포인트: Statistics Display
    /// - 사용자의 주된 수면 패턴 표시
    var mostCommonStatusString: String {
        guard let status = historyOutput?.mostCommonStatus else {
            return "-"
        }
        return status.displayName
    }

    // MARK: - Public Methods

    /// 히스토리 데이터 로드
    /// 📚 학습 포인트: Async Data Loading
    /// - Use Case를 호출하여 데이터 조회
    /// - 로딩 상태 및 에러 처리
    /// 💡 Java 비교: Kotlin Coroutines의 suspend function과 유사
    func loadHistory() async {
        isLoading = true
        errorMessage = nil

        do {
            // 📚 학습 포인트: Use Case Execution
            // 선택된 모드에 따라 데이터 조회
            let input = FetchSleepHistoryUseCase.Input(mode: selectedMode)
            historyOutput = try await fetchSleepHistoryUseCase.execute(input: input)

        } catch let error as FetchSleepHistoryUseCase.HistoryError {
            // 📚 학습 포인트: Specific Error Handling
            // Use Case의 도메인 에러를 사용자 친화적 메시지로 변환
            errorMessage = error.localizedDescription
            historyOutput = nil
        } catch {
            // 📚 학습 포인트: Generic Error Handling
            errorMessage = "히스토리 로드 실패: \(error.localizedDescription)"
            historyOutput = nil
        }

        isLoading = false
    }

    /// 조회 모드 변경
    /// 📚 학습 포인트: State Update Method
    /// - 모드 변경 시 자동으로 데이터 다시 로드 (observer를 통해)
    ///
    /// - Parameter mode: 새로운 조회 모드
    func changeMode(to mode: FetchSleepHistoryUseCase.QueryMode) {
        selectedMode = mode
    }

    /// 새로고침
    /// 📚 학습 포인트: Manual Refresh
    /// - Pull-to-refresh 등에서 사용
    /// - 현재 모드로 데이터 다시 로드
    func refresh() async {
        await loadHistory()
    }

    /// 레코드 편집 시트 표시
    /// 📚 학습 포인트: Sheet Trigger Method
    /// - recordToEdit를 설정하여 편집 시트 트리거
    /// - View에서 .sheet(item: $viewModel.recordToEdit) 사용
    ///
    /// - Parameter record: 편집할 수면 기록
    func editRecord(_ record: SleepRecord) {
        recordToEdit = record
    }

    /// 레코드 편집 완료
    /// 📚 학습 포인트: Completion Handler
    /// - 편집 완료 후 시트를 닫고 데이터 다시 로드
    func didFinishEditing() {
        recordToEdit = nil
        Task {
            await loadHistory()
        }
    }

    /// 레코드 삭제 확인
    /// 📚 학습 포인트: Confirmation Dialog Trigger
    /// - 삭제 전 사용자 확인 받기
    /// - recordIdToDelete에 ID 저장 후 다이얼로그 표시
    ///
    /// - Parameter record: 삭제할 수면 기록
    func confirmDelete(record: SleepRecord) {
        recordIdToDelete = record.id
        showDeleteConfirmation = true
    }

    /// 레코드 삭제 실행
    /// 📚 학습 포인트: Async Delete Operation
    /// - Repository를 통해 삭제 수행
    /// - 성공 시 히스토리 다시 로드
    /// - 실패 시 에러 메시지 표시
    func deleteRecord() async {
        guard let recordId = recordIdToDelete else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            // 📚 학습 포인트: Repository Delete Operation
            // Repository의 delete 메서드 호출
            // - Core Data에서 레코드 삭제
            // - 해당 날짜의 DailyLog 업데이트
            try await sleepRepository.delete(by: recordId)

            // 성공 메시지
            successMessage = "수면 기록이 삭제되었습니다."

            // 히스토리 다시 로드
            await loadHistory()

        } catch let error as RepositoryError {
            // 📚 학습 포인트: Repository Error Handling
            switch error {
            case .notFound:
                errorMessage = "삭제할 수면 기록을 찾을 수 없습니다."
            case .deleteFailed(let message):
                errorMessage = "삭제 실패: \(message)"
            default:
                errorMessage = "삭제 중 오류가 발생했습니다."
            }
        } catch {
            // 📚 학습 포인트: Generic Error Handling
            errorMessage = "삭제 중 오류가 발생했습니다: \(error.localizedDescription)"
        }

        isLoading = false
        recordIdToDelete = nil
        showDeleteConfirmation = false
    }

    /// 삭제 취소
    /// 📚 학습 포인트: Cancel Action
    /// - 확인 대화상자에서 취소 버튼 누를 때
    func cancelDelete() {
        recordIdToDelete = nil
        showDeleteConfirmation = false
    }

    /// 에러 메시지 제거
    /// 📚 학습 포인트: State Cleanup
    /// - 사용자가 에러 확인 후 호출
    func clearError() {
        errorMessage = nil
    }

    /// 성공 메시지 제거
    /// 📚 학습 포인트: State Cleanup
    /// - 사용자가 성공 메시지 확인 후 호출
    func clearSuccess() {
        successMessage = nil
    }

    // MARK: - Private Methods

    /// 조회 모드 변경 감지 설정
    /// 📚 학습 포인트: Combine Publisher Observation
    /// - @Published 프로퍼티 변경을 감지하여 자동 동작 실행
    /// - debounce로 연속 변경 시 마지막만 처리
    /// 💡 Java 비교: RxJava의 Observable.debounce()와 유사
    private func setupModeObserver() {
        // selectedMode 변경 시 자동으로 데이터 다시 로드
        $selectedMode
            .dropFirst() // 초기값 무시
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main) // 300ms 딜레이
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.loadHistory()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Helper Methods

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting Helper
    /// - 일관된 날짜 표시를 위한 헬퍼 메서드
    ///
    /// - Parameters:
    ///   - date: 포맷할 날짜
    ///   - style: 날짜 스타일 (기본값: .medium)
    /// - Returns: 포맷된 문자열
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 수면 시간 포맷팅
    /// 📚 학습 포인트: Duration Formatting Helper
    /// - 분 단위를 시간:분 형식으로 변환
    ///
    /// - Parameter minutes: 수면 시간 (분)
    /// - Returns: 포맷된 문자열 (예: "7시간 30분")
    func formatDuration(_ minutes: Int32) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if mins == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(mins)분"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension SleepHistoryViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview() -> SleepHistoryViewModel {
        // Mock Repository와 Use Case 필요 (실제로는 DIContainer에서 주입)
        fatalError("Preview support not yet implemented. Use DIContainer.shared.makeSleepHistoryViewModel() instead.")
    }

    /// 샘플 데이터가 있는 ViewModel
    /// 📚 학습 포인트: Sample Data for Preview
    /// - 리스트 미리보기를 위한 샘플 데이터 포함
    static func makePreviewWithData(
        fetchSleepHistoryUseCase: FetchSleepHistoryUseCase,
        sleepRepository: SleepRepositoryProtocol
    ) -> SleepHistoryViewModel {
        let viewModel = SleepHistoryViewModel(
            fetchSleepHistoryUseCase: fetchSleepHistoryUseCase,
            sleepRepository: sleepRepository
        )

        // 샘플 데이터 설정
        viewModel.historyOutput = FetchSleepHistoryUseCase.sampleOutput()

        return viewModel
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: SleepHistoryViewModel 이해
///
/// SleepHistoryViewModel의 역할:
/// - 수면 기록 히스토리 리스트 관리
/// - 조회 모드 변경 (전체, 최근 N일, 날짜 범위)
/// - 레코드 삭제 기능
/// - 레코드 편집 트리거
/// - 빈 상태 및 로딩 상태 처리
/// - 통계 정보 제공 (평균 수면 시간, 가장 많은 상태 등)
///
/// MVVM 패턴에서의 위치:
/// - Model: Domain entities (SleepRecord, SleepStatus)
/// - View: SwiftUI Views (SleepHistoryView, SleepRecordRow)
/// - ViewModel: 이 클래스 (SleepHistoryViewModel)
///
/// 상태 관리:
/// - historyOutput: 조회된 히스토리 데이터
/// - selectedMode: 사용자가 선택한 조회 모드
/// - isLoading: 로딩 중 상태
/// - errorMessage/successMessage: 사용자 피드백
/// - recordToEdit: 편집할 레코드 (시트 트리거)
/// - showDeleteConfirmation: 삭제 확인 대화상자 표시 여부
///
/// 비즈니스 플로우:
/// 1. ViewModel 초기화 시 자동으로 히스토리 로드
/// 2. 사용자가 조회 모드 변경 (전체/최근 7일/30일/90일)
/// 3. selectedMode 변경 감지 → 자동으로 loadHistory() 호출
/// 4. Use Case를 통해 데이터 조회
/// 5. historyOutput 업데이트 → View 자동 업데이트
///
/// 삭제 플로우:
/// 1. 사용자가 레코드를 swipe하여 삭제 버튼 클릭
/// 2. confirmDelete() 호출 → showDeleteConfirmation = true
/// 3. 확인 대화상자 표시
/// 4. 사용자가 "삭제" 선택 → deleteRecord() 호출
/// 5. Repository를 통해 레코드 삭제
/// 6. 성공 시 히스토리 다시 로드
///
/// 편집 플로우:
/// 1. 사용자가 레코드를 탭하여 편집
/// 2. editRecord() 호출 → recordToEdit 설정
/// 3. View에서 .sheet(item: $viewModel.recordToEdit) 트리거
/// 4. SleepInputSheet 표시 (편집 모드)
/// 5. 편집 완료 → didFinishEditing() 호출
/// 6. recordToEdit = nil → 시트 닫힘
/// 7. 히스토리 다시 로드
///
/// 의존성:
/// - FetchSleepHistoryUseCase: 히스토리 데이터 조회
/// - SleepRepositoryProtocol: 삭제/업데이트 작업
///
/// 사용 예시:
/// ```swift
/// struct SleepHistoryView: View {
///     @StateObject private var viewModel: SleepHistoryViewModel
///
///     var body: some View {
///         List {
///             // 통계 섹션
///             Section("통계") {
///                 HStack {
///                     Text("평균 수면 시간")
///                     Spacer()
///                     Text(viewModel.averageDurationString)
///                 }
///                 HStack {
///                     Text("가장 많은 상태")
///                     Spacer()
///                     Text(viewModel.mostCommonStatusString)
///                 }
///             }
///
///             // 레코드 리스트
///             Section("수면 기록") {
///                 if viewModel.isEmpty {
///                     Text("수면 기록이 없습니다.")
///                         .foregroundColor(.secondary)
///                 } else {
///                     ForEach(viewModel.records) { record in
///                         SleepRecordRow(record: record)
///                             .onTapGesture {
///                                 viewModel.editRecord(record)
///                             }
///                             .swipeActions(edge: .trailing) {
///                                 Button(role: .destructive) {
///                                     viewModel.confirmDelete(record: record)
///                                 } label: {
///                                     Label("삭제", systemImage: "trash")
///                                 }
///                             }
///                     }
///                 }
///             }
///         }
///         .refreshable {
///             await viewModel.refresh()
///         }
///         .sheet(item: $viewModel.recordToEdit) { record in
///             SleepInputSheet(
///                 viewModel: makeSleepInputViewModel(for: record),
///                 onComplete: { viewModel.didFinishEditing() }
///             )
///         }
///         .confirmationDialog(
///             "수면 기록을 삭제하시겠습니까?",
///             isPresented: $viewModel.showDeleteConfirmation
///         ) {
///             Button("삭제", role: .destructive) {
///                 Task { await viewModel.deleteRecord() }
///             }
///             Button("취소", role: .cancel) {
///                 viewModel.cancelDelete()
///             }
///         }
///         .alert("에러", isPresented: .constant(viewModel.errorMessage != nil)) {
///             Button("확인") { viewModel.clearError() }
///         } message: {
///             Text(viewModel.errorMessage ?? "")
///         }
///     }
/// }
/// ```
///
/// 💡 Android ViewModel과의 비교:
/// - Android: ViewModel + LiveData<List<SleepRecord>>
/// - SwiftUI: ObservableObject + @Published
/// - Android: viewModelScope.launch로 비동기 작업
/// - SwiftUI: Task { await ... } with @MainActor
///
/// 💡 실무 팁:
/// - 삭제는 확인 대화상자를 통해 사용자 확인 받기
/// - 편집은 .sheet(item:) 바인딩으로 자동 관리
/// - selectedMode 변경 시 자동 리로드로 UX 향상
/// - 통계 정보를 computed property로 제공하여 View 간소화
/// - Pull-to-refresh로 수동 새로고침 지원
///
/// FetchSleepHistoryUseCase와의 협력:
/// - ViewModel: UI 상태 관리 및 사용자 액션 처리
/// - Use Case: 비즈니스 로직 (데이터 조회, 통계 계산)
/// - ViewModel은 Use Case의 결과만 받아서 UI 업데이트
///
/// SleepRepository와의 협력:
/// - ViewModel: 삭제/업데이트 요청
/// - Repository: 실제 데이터 작업 수행
/// - Repository는 DailyLog 자동 업데이트도 처리
///

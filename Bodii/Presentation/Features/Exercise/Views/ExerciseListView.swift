//
//  ExerciseListView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: SwiftUI List View with MVVM
// 운동 기록 목록을 표시하는 메인 뷰
// 💡 Java 비교: Android의 RecyclerView + ViewModel과 유사한 구조

import SwiftUI

// MARK: - Exercise List View

/// 운동 기록 목록 뷰
///
/// 특정 날짜의 운동 기록 목록과 일일 집계를 표시하는 메인 화면입니다.
///
/// **주요 기능:**
/// - 날짜 네비게이션 (이전/다음 날)
/// - 일일 운동 요약 (총 칼로리, 총 시간, 운동 횟수)
/// - 운동 기록 카드 리스트
/// - 스와이프 삭제
/// - 운동 추가 버튼
/// - Pull-to-Refresh
/// - 빈 상태 UI
///
/// - Example:
/// ```swift
/// ExerciseListView(viewModel: viewModel)
/// ```
struct ExerciseListView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @Observable ViewModel (iOS 17+)
    // 이전: @StateObject, @ObservedObject 사용
    // 현재: var로 선언하면 자동으로 관찰됨
    // 💡 Java 비교: ViewModel + LiveData 자동 구독과 유사

    /// 뷰 모델
    var viewModel: ExerciseListViewModel

    /// 운동 추가 시트 표시 상태
    @State private var isShowingAddSheet = false

    /// 운동 편집 시트 표시 상태
    @State private var isShowingEditSheet = false

    /// 편집할 운동 기록
    @State private var selectedExercise: ExerciseRecord?

    /// 삭제할 운동 기록 (확인 다이얼로그용)
    @State private var exerciseToDelete: ExerciseRecord?

    // 📚 학습 포인트: User Data State
    // ExerciseInputViewModel 생성 시 필요한 사용자 데이터
    // TODO: 추후 User entity나 AuthenticationService에서 가져오도록 개선
    /// 사용자 체중 (kg) - 칼로리 계산에 사용
    @State private var userWeight: Decimal = 70.0
    /// 사용자 기초대사량 (kcal)
    @State private var userBMR: Int32 = 1650
    /// 사용자 활동대사량 (kcal)
    @State private var userTDEE: Int32 = 2310

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // 📚 학습 포인트: ZStack으로 레이어 구성
            // Empty State와 Content를 겹쳐서 조건부 렌더링
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("운동")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .onAppear {
                viewModel.onAppear()
            }
            .sheet(isPresented: $isShowingAddSheet) {
                // 📚 학습 포인트: Modal Sheet with DI (Add Mode)
                // DIContainer를 통해 ExerciseInputViewModel 생성
                // onSaveSuccess 콜백으로 저장 성공 시 시트 닫기 및 데이터 새로고침
                ExerciseInputView(
                    viewModel: DIContainer.shared.makeExerciseInputViewModel(
                        userId: viewModel.userId,
                        userWeight: userWeight,
                        userBMR: userBMR,
                        userTDEE: userTDEE
                    ),
                    onSaveSuccess: {
                        isShowingAddSheet = false
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
            }
            .sheet(isPresented: $isShowingEditSheet) {
                // 📚 학습 포인트: Modal Sheet with DI (Edit Mode)
                // editingExercise 파라미터를 전달하여 편집 모드로 진입
                // 💡 Java 비교: Intent에 Parcelable 객체를 담아 전달하는 패턴과 유사
                if let exercise = selectedExercise {
                    ExerciseInputView(
                        viewModel: DIContainer.shared.makeExerciseInputViewModel(
                            userId: viewModel.userId,
                            userWeight: userWeight,
                            userBMR: userBMR,
                            userTDEE: userTDEE,
                            editingExercise: exercise
                        ),
                        onSaveSuccess: {
                            isShowingEditSheet = false
                            selectedExercise = nil
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    )
                }
            }
            // 📚 학습 포인트: Delete Confirmation Alert
            // 삭제 전 확인 다이얼로그로 사용자 실수 방지
            // 💡 Java 비교: AlertDialog with positive/negative buttons와 유사
            .alert("운동 기록 삭제", isPresented: .constant(exerciseToDelete != nil)) {
                Button("취소", role: .cancel) {
                    exerciseToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let exercise = exerciseToDelete {
                        Task {
                            await viewModel.deleteExercise(id: exercise.id)
                            exerciseToDelete = nil
                        }
                    }
                }
            } message: {
                if let exercise = exerciseToDelete {
                    Text("\(exercise.exerciseType.displayName) 기록을 삭제하시겠습니까?")
                }
            }
            .alert("오류", isPresented: .constant(viewModel.hasError)) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - View Components

    // 📚 학습 포인트: Computed Properties for View Composition
    // 복잡한 View를 작은 단위로 분리하여 가독성 향상
    // 💡 Java 비교: Compose의 @Composable function과 유사

    /// 로딩 뷰
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("운동 기록 불러오는 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 📚 학습 포인트: SF Symbols
            // iOS 시스템 아이콘 라이브러리
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("운동 기록이 없습니다")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("오늘 운동을 기록해보세요!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: { isShowingAddSheet = true }) {
                Label("운동 추가", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    /// 메인 컨텐츠 뷰
    private var contentView: some View {
        VStack(spacing: 0) {
            // 날짜 네비게이션 헤더
            dateNavigationHeader
                .padding(.horizontal)
                .padding(.top, 8)

            // 📚 학습 포인트: List with Pull-to-Refresh
            // refreshable modifier로 간단하게 구현 가능
            // 💡 Java 비교: SwipeRefreshLayout과 유사
            List {
                // 일일 요약 섹션
                Section {
                    dailySummarySection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                // 운동 기록 리스트 섹션
                Section {
                    ForEach(viewModel.exerciseRecords) { exercise in
                        ExerciseCardView(
                            exercise: exercise,
                            onDelete: {
                                // 📚 학습 포인트: Confirmation Before Delete
                                // 실수로 삭제하는 것을 방지하기 위한 확인 다이얼로그
                                // 💡 Java 비교: AlertDialog.Builder().show()와 유사
                                exerciseToDelete = exercise
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        // 📚 학습 포인트: Loading State During Delete
                        // 삭제 중인 카드는 반투명 처리 + 로딩 인디케이터 표시
                        // 💡 Java 비교: ViewHolder에 ProgressBar 표시와 유사
                        .opacity(viewModel.isDeletingId == exercise.id ? 0.5 : 1.0)
                        .overlay {
                            if viewModel.isDeletingId == exercise.id {
                                ProgressView()
                                    .scaleEffect(1.5)
                            }
                        }
                        // 📚 학습 포인트: Tap Gesture for Edit
                        // 운동 카드를 탭하면 편집 모드로 진입
                        // 💡 Java 비교: RecyclerView Item Click Listener와 유사
                        .onTapGesture {
                            selectedExercise = exercise
                            isShowingEditSheet = true
                        }
                    }
                } header: {
                    if !viewModel.exerciseRecords.isEmpty {
                        Text("운동 기록")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .refreshable {
                // 📚 학습 포인트: async/await with SwiftUI
                // refreshable modifier는 자동으로 async 함수 지원
                await viewModel.refresh()
            }
        }
    }

    /// 날짜 네비게이션 헤더
    private var dateNavigationHeader: some View {
        HStack(spacing: 16) {
            // 이전 날짜 버튼
            Button(action: viewModel.goToPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }

            // 날짜 표시
            VStack(spacing: 4) {
                Text(viewModel.formattedSelectedDate)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if viewModel.isToday {
                    Text("오늘")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)

            // 다음 날짜 버튼
            // 📚 학습 포인트: Conditional Styling
            // 미래 날짜는 비활성화 처리
            Button(action: viewModel.goToNextDay) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isFuture ? .secondary : .primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .disabled(viewModel.isFuture)
            .opacity(viewModel.isFuture ? 0.5 : 1.0)
        }
        .padding(.vertical, 12)
    }

    /// 일일 요약 섹션
    private var dailySummarySection: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                Text("오늘의 운동")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            // 📚 학습 포인트: HStack with Equal Spacing
            // 세 개의 통계를 균등하게 배치
            HStack(spacing: 12) {
                // 소모 칼로리
                summaryCard(
                    title: "소모 칼로리",
                    value: "\(viewModel.totalCaloriesOut)",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )

                // 운동 시간
                summaryCard(
                    title: "운동 시간",
                    value: formatMinutes(viewModel.exerciseMinutes),
                    unit: "",
                    icon: "clock.fill",
                    color: .blue
                )

                // 운동 횟수
                summaryCard(
                    title: "운동 횟수",
                    value: "\(viewModel.exerciseCount)",
                    unit: "회",
                    icon: "figure.run",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// 요약 카드 (재사용 가능한 단위 컴포넌트)
    /// - Parameters:
    ///   - title: 제목 (예: "소모 칼로리")
    ///   - value: 값 (예: "450")
    ///   - unit: 단위 (예: "kcal")
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 색상
    private func summaryCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            // 아이콘
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            // 값
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 제목
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }

    /// 운동 추가 버튼
    private var addButton: some View {
        Button(action: { isShowingAddSheet = true }) {
            Image(systemName: "plus")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Helper Methods

    /// 분 단위를 "X시간 Y분" 형식으로 변환
    /// - Parameter minutes: 분 단위 시간
    /// - Returns: 포맷팅된 문자열 (예: "1시간 30분", "45분")
    private func formatMinutes(_ minutes: Int32) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)시간 \(remainingMinutes)분"
            } else {
                return "\(hours)시간"
            }
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Preview

#Preview("With Data") {
    // 📚 학습 포인트: Preview with Mock Data
    // 개발 중 빠른 피드백을 위한 샘플 데이터 프리뷰

    // Mock ViewModel
    let mockViewModel = ExerciseListViewModel(
        getExerciseRecordsUseCase: MockGetExerciseRecordsUseCase(),
        deleteExerciseRecordUseCase: MockDeleteExerciseRecordUseCase(),
        dailyLogRepository: MockDailyLogRepository(),
        userId: UUID()
    )

    // Mock 데이터 주입
    mockViewModel.exerciseRecords = [
        ExerciseRecord(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            exerciseType: .running,
            duration: 30,
            intensity: .high,
            caloriesBurned: 350,
            createdAt: Date()
        ),
        ExerciseRecord(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            exerciseType: .weight,
            duration: 45,
            intensity: .medium,
            caloriesBurned: 250,
            createdAt: Date()
        ),
        ExerciseRecord(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            exerciseType: .yoga,
            duration: 60,
            intensity: .low,
            caloriesBurned: 120,
            createdAt: Date()
        )
    ]

    mockViewModel.dailyLog = DailyLog(
        id: UUID(),
        userId: UUID(),
        date: Date(),
        totalCaloriesIn: 1800,
        totalCarbs: Decimal(200),
        totalProtein: Decimal(100),
        totalFat: Decimal(60),
        carbsRatio: Decimal(45),
        proteinRatio: Decimal(22),
        fatRatio: Decimal(28),
        bmr: 1500,
        tdee: 2100,
        netCalories: -300,
        totalCaloriesOut: 720,
        exerciseMinutes: 135,
        exerciseCount: 3,
        steps: 8500,
        weight: Decimal(70),
        bodyFatPct: Decimal(20),
        sleepDuration: 420,
        sleepStatus: .good,
        createdAt: Date(),
        updatedAt: Date()
    )

    return ExerciseListView(viewModel: mockViewModel)
}

#Preview("Empty State") {
    let mockViewModel = ExerciseListViewModel(
        getExerciseRecordsUseCase: MockGetExerciseRecordsUseCase(),
        deleteExerciseRecordUseCase: MockDeleteExerciseRecordUseCase(),
        dailyLogRepository: MockDailyLogRepository(),
        userId: UUID()
    )

    // 빈 상태
    mockViewModel.exerciseRecords = []
    mockViewModel.dailyLog = nil

    return ExerciseListView(viewModel: mockViewModel)
}

#Preview("Loading State") {
    let mockViewModel = ExerciseListViewModel(
        getExerciseRecordsUseCase: MockGetExerciseRecordsUseCase(),
        deleteExerciseRecordUseCase: MockDeleteExerciseRecordUseCase(),
        dailyLogRepository: MockDailyLogRepository(),
        userId: UUID()
    )

    // 로딩 상태
    mockViewModel.isLoading = true

    return ExerciseListView(viewModel: mockViewModel)
}

// MARK: - Mock Implementations

// 📚 학습 포인트: Mock Objects for Preview
// Preview에서 실제 UseCase를 사용하지 않고 Mock 객체 사용
// 💡 Java 비교: Mockito의 Mock과 유사한 개념

/// GetExerciseRecordsUseCase Mock
private class MockGetExerciseRecordsUseCase: GetExerciseRecordsUseCase {
    init() {
        // Mock에서는 실제 repository 불필요
        super.init(exerciseRecordRepository: MockExerciseRecordRepository())
    }
}

/// DeleteExerciseRecordUseCase Mock
private class MockDeleteExerciseRecordUseCase: DeleteExerciseRecordUseCase {
    init() {
        // Mock에서는 실제 repository 불필요
        super.init(
            exerciseRecordRepository: MockExerciseRecordRepository(),
            dailyLogService: MockDailyLogService()
        )
    }
}

/// DailyLogRepository Mock
private class MockDailyLogRepository: DailyLogRepository {
    func fetch(for date: Date, userId: UUID) async throws -> DailyLog? {
        return nil
    }

    func getOrCreate(for date: Date, userId: UUID, userBMR: Int32, userTDEE: Int32) async throws -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: userId,
            date: date,
            totalCaloriesIn: 0,
            totalCarbs: 0,
            totalProtein: 0,
            totalFat: 0,
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil,
            bmr: userBMR,
            tdee: userTDEE,
            netCalories: 0,
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0,
            steps: nil,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func update(_ dailyLog: DailyLog) async throws {}
    func delete(for date: Date, userId: UUID) async throws {}
}

/// ExerciseRecordRepository Mock
private class MockExerciseRecordRepository: ExerciseRecordRepository {
    func create(_ record: ExerciseRecord) async throws {}
    func fetchById(_ id: UUID) async throws -> ExerciseRecord? { return nil }
    func fetchByDate(_ date: Date, userId: UUID) async throws -> [ExerciseRecord] { return [] }
    func fetchByDateRange(startDate: Date, endDate: Date, userId: UUID) async throws -> [ExerciseRecord] { return [] }
    func fetchAll(userId: UUID) async throws -> [ExerciseRecord] { return [] }
    func update(_ record: ExerciseRecord) async throws {}
    func delete(_ id: UUID) async throws {}
    func count(userId: UUID) async throws -> Int { return 0 }
    func totalDuration(userId: UUID) async throws -> Int32 { return 0 }
    func totalCaloriesBurned(userId: UUID) async throws -> Int32 { return 0 }
}

/// DailyLogService Mock
private class MockDailyLogService: DailyLogService {
    init() {
        // Mock에서는 실제 repository 불필요
        super.init(dailyLogRepository: MockDailyLogRepository())
    }
}

// MARK: - Learning Notes

/// ## SwiftUI List View 패턴
///
/// ### 주요 개념
///
/// 1. **View Composition**
///    - body를 작은 computed property로 분리
///    - 각 섹션은 독립적인 View로 구성
///    - 재사용 가능한 컴포넌트 생성
///
/// 2. **State Management**
///    - @Observable ViewModel로 상태 관리 (iOS 17+)
///    - @State로 로컬 UI 상태 관리 (시트 표시 등)
///    - Binding으로 양방향 데이터 흐름
///
/// 3. **List 최적화**
///    - listRowInsets로 커스텀 패딩
///    - listRowBackground로 배경 제거
///    - listRowSeparator(.hidden)로 구분선 제거
///
/// 4. **Pull-to-Refresh**
///    - refreshable modifier 사용
///    - async/await 함수 자동 지원
///
/// 5. **Empty State 처리**
///    - ZStack으로 조건부 렌더링
///    - Loading, Empty, Content 상태 분리
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | NavigationStack | NavController |
/// | List | RecyclerView |
/// | ForEach | RecyclerView.Adapter |
/// | @Observable | ViewModel + LiveData |
/// | .refreshable | SwipeRefreshLayout |
/// | .sheet | BottomSheetDialog |
/// | .alert | AlertDialog |
///
/// ### 모범 사례
///
/// 1. **View 분리**: body는 최대한 간단하게, 복잡한 로직은 computed property로
/// 2. **재사용**: 반복되는 UI는 함수나 별도 컴포넌트로 추출
/// 3. **접근성**: SF Symbols와 Label 사용으로 자동 접근성 지원
/// 4. **Preview**: 다양한 상태의 Preview로 개발 속도 향상
/// 5. **Loading State**: 사용자 경험을 위한 로딩 상태 필수
///

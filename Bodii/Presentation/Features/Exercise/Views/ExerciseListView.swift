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

    /// 캘린더 DatePicker 표시 상태
    @State private var showDatePicker = false

    // 📚 학습 포인트: User Data State
    // ExerciseInputViewModel 생성 시 필요한 사용자 데이터
    // TODO: 추후 User entity나 AuthenticationService에서 가져오도록 개선
    /// 사용자 체중 (kg) - 칼로리 계산에 사용
    @State private var userWeight: Decimal = 70.0
    /// 사용자 성별 - 칼로리 보정에 사용
    @State private var userGender: Gender = .male
    /// 사용자 기초대사량 (kcal)
    @State private var userBMR: Decimal = 1650
    /// 사용자 활동대사량 (kcal)
    @State private var userTDEE: Decimal = 2310

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 날짜 네비게이션 헤더 (항상 표시)
                dateNavigationHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

                // 콘텐츠 영역
                if viewModel.isLoading {
                    Spacer()
                    loadingView
                    Spacer()
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    exerciseListContent
                }
            }
            .background(Color(.systemGroupedBackground))
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
                        userGender: userGender,
                        userBMR: userBMR,
                        userTDEE: userTDEE,
                        selectedDate: viewModel.selectedDate
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
                            userGender: userGender,
                            userBMR: userBMR,
                            userTDEE: userTDEE,
                            editingExercise: exercise,
                            selectedDate: viewModel.selectedDate
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
                    if let exercise = exerciseToDelete, let exerciseId = exercise.id {
                        Task {
                            await viewModel.deleteExercise(id: exerciseId)
                            exerciseToDelete = nil
                        }
                    }
                }
            } message: {
                if let exercise = exerciseToDelete {
                    let exerciseTypeName = ExerciseType(rawValue: exercise.exerciseType)?.displayName ?? "운동"
                    Text("\(exerciseTypeName) 기록을 삭제하시겠습니까?")
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
            .sheet(isPresented: $showDatePicker) {
                calendarDatePicker
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
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("운동 기록이 없습니다")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(viewModel.isToday ? "오늘 운동을 기록해보세요!" : "이 날짜에 운동을 추가해보세요!")
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

            Spacer()
        }
        .padding()
    }

    /// 운동 기록 리스트 (날짜 헤더 제외)
    private var exerciseListContent: some View {
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
                            exerciseToDelete = exercise
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .opacity(viewModel.isDeletingId == exercise.id ? 0.5 : 1.0)
                    .overlay {
                        if viewModel.isDeletingId == exercise.id {
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                    }
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
        .refreshable {
            await viewModel.refresh()
        }
    }

    /// 날짜 네비게이션 헤더
    private var dateNavigationHeader: some View {
        HStack {
            // 이전 날짜 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.goToPreviousDay()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("이전 날짜")

            Spacer()

            // 날짜 표시 (탭하면 캘린더 오픈)
            VStack(spacing: 4) {
                Text(viewModel.formattedSelectedDate)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if viewModel.isToday {
                    Text("오늘")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onTapGesture {
                showDatePicker = true
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(viewModel.isToday ? "오늘, \(viewModel.formattedSelectedDate)" : viewModel.formattedSelectedDate)
            .accessibilityHint("탭하여 캘린더에서 날짜를 선택하세요")

            Spacer()

            // 다음 날짜 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.goToNextDay()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .disabled(viewModel.isFuture)
            .opacity(viewModel.isFuture ? 0.3 : 1.0)
            .accessibilityLabel("다음 날짜")
            .accessibilityHint(viewModel.isFuture ? "미래 날짜는 볼 수 없습니다" : "다음 날 운동 보기")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    /// 캘린더 날짜 선택 시트
    private var calendarDatePicker: some View {
        NavigationStack {
            DatePicker(
                "날짜 선택",
                selection: Binding(
                    get: { viewModel.selectedDate },
                    set: { newDate in
                        viewModel.selectDate(newDate)
                        showDatePicker = false
                    }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("날짜 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// 일일 요약 섹션
    private var dailySummarySection: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                Text(viewModel.isToday ? "오늘의 운동" : viewModel.formattedSelectedDate)
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
// Preview는 Core Data 엔티티 초기화 문제로 인해 임시 비활성화
// TODO: PreviewHelpers를 사용한 Preview 구현 필요

// 📚 학습 포인트: Core Data/UseCase 의존성 Preview 제한
// ExerciseRecord, DailyLog는 Core Data 엔티티이므로 Preview에서 직접 초기화 불가
// Mock 클래스가 final class를 상속하거나 프로토콜을 준수하지 않아 사용 불가
// TODO: Phase 7에서 Preview용 Core Data context helper 구현 후 수정

#Preview("Placeholder") {
    Text("ExerciseListView Preview")
        .font(.headline)
        .padding()
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

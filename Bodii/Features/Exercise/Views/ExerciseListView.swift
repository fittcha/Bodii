//
//  ExerciseListView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import SwiftUI

/// 운동 기록 목록 뷰
///
/// 선택된 날짜의 운동 기록 목록을 표시하고, 날짜 탐색 및 일일 통계를 제공합니다.
///
/// **주요 기능**:
/// - 날짜 헤더 (이전/다음 날짜 버튼, 오늘 버튼)
/// - 일일 요약 카드 (총 칼로리, 총 운동 시간, 운동 횟수)
/// - 운동 기록 목록 (운동 종류 아이콘, 이름, 시간, 칼로리)
/// - 스와이프로 삭제 기능
/// - 탭하여 수정 기능
/// - 플로팅 추가 버튼
/// - 빈 상태 화면
///
/// - Example:
/// ```swift
/// ExerciseListView()
///     .environmentObject(viewModel)
/// ```
struct ExerciseListView: View {

    // MARK: - Properties

    /// 운동 기록 ViewModel
    @StateObject private var viewModel: ExerciseViewModel

    /// 운동 입력 모달 표시 여부
    @State private var showingInputSheet: Bool = false

    /// 수정할 운동 기록
    @State private var exerciseToEdit: ExerciseRecord?

    /// 삭제 확인 알림 표시 여부
    @State private var showingDeleteAlert: Bool = false

    /// 삭제할 운동 기록 ID
    @State private var exerciseToDelete: UUID?

    // MARK: - Initialization

    /// ExerciseListView 초기화
    ///
    /// - Parameter viewModel: 운동 기록 ViewModel
    init(viewModel: ExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경색
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // 메인 콘텐츠
                VStack(spacing: 0) {
                    // 날짜 헤더
                    dateHeaderView
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))

                    // 스크롤 콘텐츠
                    ScrollView {
                        VStack(spacing: 16) {
                            // 일일 요약 카드
                            dailySummaryCard
                                .padding(.horizontal)
                                .padding(.top, 16)

                            // 운동 목록
                            if viewModel.exercises.isEmpty {
                                emptyStateView
                                    .padding(.top, 40)
                            } else {
                                exerciseListSection
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 100) // 플로팅 버튼 공간
                    }
                }

                // 플로팅 추가 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("운동")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingInputSheet) {
                // 운동 입력 모달
                ExerciseInputView(
                    viewModel: viewModel.makeInputViewModel(for: exerciseToEdit)
                )
            }
            .alert("운동 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    if let id = exerciseToDelete {
                        Task {
                            await viewModel.deleteExercise(id: id)
                        }
                    }
                }
            } message: {
                Text("이 운동 기록을 삭제하시겠습니까?")
            }
            .alert("오류", isPresented: $viewModel.showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
            }
            .task {
                viewModel.initialize()
            }
        }
    }

    // MARK: - Date Header View

    /// 날짜 헤더 뷰
    private var dateHeaderView: some View {
        HStack(spacing: 16) {
            // 이전 날짜 버튼
            Button(action: {
                viewModel.goToPreviousDay()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // 날짜 표시
            VStack(spacing: 4) {
                Text(viewModel.dateDisplayString)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if !viewModel.isToday {
                    Button(action: {
                        viewModel.goToToday()
                    }) {
                        Text("오늘")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            // 다음 날짜 버튼
            Button(action: {
                viewModel.goToNextDay()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Daily Summary Card

    /// 일일 요약 카드
    private var dailySummaryCard: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("오늘의 운동")
                    .font(.headline)
                Spacer()
            }

            // 통계
            HStack(spacing: 0) {
                // 총 칼로리
                summaryItem(
                    icon: "flame.fill",
                    iconColor: .orange,
                    value: "\(viewModel.totalCaloriesBurned)",
                    unit: "kcal",
                    label: "소모 칼로리"
                )

                Divider()
                    .frame(height: 50)

                // 총 운동 시간
                summaryItem(
                    icon: "clock.fill",
                    iconColor: .green,
                    value: "\(viewModel.totalExerciseMinutes)",
                    unit: "분",
                    label: "운동 시간"
                )

                Divider()
                    .frame(height: 50)

                // 운동 횟수
                summaryItem(
                    icon: "checkmark.circle.fill",
                    iconColor: .blue,
                    value: "\(viewModel.exerciseCount)",
                    unit: "회",
                    label: "운동 횟수"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    /// 요약 통계 아이템
    private func summaryItem(
        icon: String,
        iconColor: Color,
        value: String,
        unit: String,
        label: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercise List Section

    /// 운동 목록 섹션
    private var exerciseListSection: some View {
        VStack(spacing: 12) {
            // 섹션 헤더
            HStack {
                Text("운동 기록")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.exercises.count)개")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // 운동 카드 목록
            ForEach(viewModel.exercises) { exercise in
                exerciseCard(for: exercise)
                    .onTapGesture {
                        exerciseToEdit = exercise
                        showingInputSheet = true
                    }
            }
        }
    }

    /// 운동 카드
    private func exerciseCard(for exercise: ExerciseRecord) -> some View {
        HStack(spacing: 16) {
            // 운동 종류 아이콘
            ZStack {
                Circle()
                    .fill(exerciseTypeColor(for: exercise.exerciseType).opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: exerciseTypeIcon(for: exercise.exerciseType))
                    .font(.title3)
                    .foregroundStyle(exerciseTypeColor(for: exercise.exerciseType))
            }

            // 운동 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseType.displayName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(exercise.duration)분", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(exercise.intensity.displayName, systemImage: intensityIcon(for: exercise.intensity))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 칼로리
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(exercise.caloriesBurned)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)

                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                exerciseToDelete = exercise.id
                showingDeleteAlert = true
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State View

    /// 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("운동 기록이 없습니다")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("하단의 + 버튼을 눌러\n운동 기록을 추가해보세요")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Add Button

    /// 플로팅 추가 버튼
    private var addButton: some View {
        Button(action: {
            exerciseToEdit = nil
            showingInputSheet = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Helper Methods

    /// 운동 종류별 아이콘
    private func exerciseTypeIcon(for type: ExerciseType) -> String {
        switch type {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .weight:
            return "dumbbell.fill"
        case .crossfit:
            return "figure.cross.training"
        case .yoga:
            return "figure.yoga"
        case .other:
            return "figure.mixed.cardio"
        }
    }

    /// 운동 종류별 색상
    private func exerciseTypeColor(for type: ExerciseType) -> Color {
        switch type {
        case .walking:
            return .green
        case .running:
            return .blue
        case .cycling:
            return .orange
        case .swimming:
            return .cyan
        case .weight:
            return .red
        case .crossfit:
            return .purple
        case .yoga:
            return .pink
        case .other:
            return .gray
        }
    }

    /// 강도별 아이콘
    private func intensityIcon(for intensity: Intensity) -> String {
        switch intensity {
        case .low:
            return "circle"
        case .medium:
            return "circle.lefthalf.filled"
        case .high:
            return "circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    // Preview용 Mock 서비스
    let persistenceController = PersistenceController.preview
    let context = persistenceController.container.viewContext

    let exerciseCalcService = ExerciseCalcService()
    let exerciseRecordRepository = ExerciseRecordRepository(context: context)
    let dailyLogRepository = DailyLogRepository(context: context)
    let userRepository = UserRepository(context: context)

    let exerciseRecordService = ExerciseRecordService(
        exerciseCalcService: exerciseCalcService,
        exerciseRecordRepository: exerciseRecordRepository,
        dailyLogRepository: dailyLogRepository,
        userRepository: userRepository
    )

    let viewModel = ExerciseViewModel(
        exerciseRecordService: exerciseRecordService,
        dailyLogRepository: dailyLogRepository,
        userRepository: userRepository
    )

    return ExerciseListView(viewModel: viewModel)
}

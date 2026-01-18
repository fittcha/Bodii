//
//  ExerciseViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import Combine

/// 운동 목록 ViewModel
///
/// 운동 기록 목록을 관리하고, 날짜 탐색 및 일일 통계를 제공합니다.
/// 운동 추가/수정/삭제 기능을 처리합니다.
///
/// **주요 기능**:
/// - 선택된 날짜의 운동 기록 목록 로드
/// - 날짜 탐색 (이전/다음 날짜, 오늘로 이동)
/// - DailyLog에서 일일 통계 조회 (총 칼로리, 총 시간, 운동 횟수)
/// - 운동 추가/수정/삭제 메서드 제공
/// - 로딩 및 에러 상태 관리
/// - 데이터 변경 시 자동 새로고침
///
/// - Example:
/// ```swift
/// let viewModel = ExerciseViewModel(
///     exerciseRecordService: exerciseService,
///     dailyLogRepository: dailyLogRepo,
///     userRepository: userRepo
/// )
///
/// // 운동 목록 로드
/// viewModel.loadExercises()
///
/// // 날짜 이동
/// viewModel.goToPreviousDay()
/// viewModel.goToNextDay()
/// viewModel.goToToday()
///
/// // 운동 추가
/// viewModel.addExercise(
///     exerciseType: .running,
///     duration: 30,
///     intensity: .high
/// )
///
/// // 운동 삭제
/// viewModel.deleteExercise(exerciseId)
/// ```
@MainActor
final class ExerciseViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 선택된 날짜
    @Published var selectedDate: Date = Date()

    /// 운동 기록 목록
    @Published var exercises: [ExerciseRecord] = []

    /// 일일 총 칼로리 소모 (kcal)
    @Published var totalCaloriesBurned: Int32 = 0

    /// 일일 총 운동 시간 (분)
    @Published var totalExerciseMinutes: Int32 = 0

    /// 일일 운동 횟수
    @Published var exerciseCount: Int16 = 0

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 에러 표시 여부
    @Published var showError: Bool = false

    // MARK: - Private Properties

    /// 운동 기록 서비스
    private let exerciseRecordService: ExerciseRecordService

    /// 일일 집계 Repository
    private let dailyLogRepository: DailyLogRepository

    /// 사용자 Repository
    private let userRepository: UserRepository

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    // MARK: - Computed Properties

    /// 선택된 날짜가 오늘인지 확인
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// 날짜 표시 문자열 (예: "2026년 1월 13일")
    var dateDisplayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: selectedDate)
    }

    /// 간단한 날짜 표시 문자열 (예: "1월 13일")
    var simpleDateDisplayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Initialization

    /// ViewModel 초기화
    ///
    /// - Parameters:
    ///   - exerciseRecordService: 운동 기록 서비스
    ///   - dailyLogRepository: 일일 집계 Repository
    ///   - userRepository: 사용자 Repository
    init(
        exerciseRecordService: ExerciseRecordService,
        dailyLogRepository: DailyLogRepository,
        userRepository: UserRepository
    ) {
        self.exerciseRecordService = exerciseRecordService
        self.dailyLogRepository = dailyLogRepository
        self.userRepository = userRepository
    }

    // MARK: - Public Methods

    /// 초기 데이터 로드
    ///
    /// 현재 사용자를 조회하고, 오늘 날짜의 운동 기록을 로드합니다.
    func initialize() {
        Task {
            await loadCurrentUser()
            await loadExercises()
        }
    }

    /// 선택된 날짜의 운동 기록 로드
    ///
    /// **처리 과정**:
    /// 1. 사용자 ID 확인
    /// 2. 운동 기록 목록 조회
    /// 3. DailyLog에서 일일 통계 조회
    /// 4. 에러 발생 시 에러 상태 업데이트
    func loadExercises() async {
        guard let userId = currentUserId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            // 운동 기록 목록 조회
            let records = try exerciseRecordService.fetchExercises(for: userId, on: selectedDate)
            exercises = records

            // DailyLog에서 통계 조회
            await loadDailyStatistics(userId: userId)

        } catch {
            errorMessage = "운동 기록을 불러올 수 없습니다: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    /// 이전 날짜로 이동
    func goToPreviousDay() {
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else {
            return
        }
        selectedDate = previousDay
        Task {
            await loadExercises()
        }
    }

    /// 다음 날짜로 이동
    func goToNextDay() {
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else {
            return
        }
        selectedDate = nextDay
        Task {
            await loadExercises()
        }
    }

    /// 오늘 날짜로 이동
    func goToToday() {
        selectedDate = Date()
        Task {
            await loadExercises()
        }
    }

    /// 특정 날짜로 이동
    ///
    /// - Parameter date: 이동할 날짜
    func goToDate(_ date: Date) {
        selectedDate = date
        Task {
            await loadExercises()
        }
    }

    /// 운동 추가
    ///
    /// 새로운 운동 기록을 추가하고, 목록을 새로고침합니다.
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - date: 운동 날짜 (기본값: 선택된 날짜)
    /// - Returns: 성공 여부
    @discardableResult
    func addExercise(
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        date: Date? = nil
    ) async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            showError = true
            return false
        }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let exerciseDate = date ?? selectedDate
            _ = try exerciseRecordService.addExercise(
                userId: userId,
                date: exerciseDate,
                exerciseType: exerciseType,
                duration: duration,
                intensity: intensity
            )

            // 추가된 날짜가 현재 선택된 날짜와 같으면 목록 새로고침
            let calendar = Calendar.current
            if calendar.isDate(exerciseDate, inSameDayAs: selectedDate) {
                await loadExercises()
            }

            isLoading = false
            return true

        } catch {
            isLoading = false
            errorMessage = "운동 기록을 추가할 수 없습니다: \(error.localizedDescription)"
            showError = true
            return false
        }
    }

    /// 운동 수정
    ///
    /// 기존 운동 기록을 수정하고, 목록을 새로고침합니다.
    ///
    /// - Parameters:
    ///   - id: 수정할 운동 기록 ID
    ///   - exerciseType: 새 운동 종류
    ///   - duration: 새 운동 시간 (분)
    ///   - intensity: 새 운동 강도
    ///   - date: 새 운동 날짜
    /// - Returns: 성공 여부
    @discardableResult
    func updateExercise(
        id: UUID,
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        date: Date
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            try exerciseRecordService.updateExercise(
                id: id,
                date: date,
                exerciseType: exerciseType,
                duration: duration,
                intensity: intensity
            )

            // 목록 새로고침 (날짜가 변경되었을 수 있으므로)
            await loadExercises()

            isLoading = false
            return true

        } catch {
            isLoading = false
            errorMessage = "운동 기록을 수정할 수 없습니다: \(error.localizedDescription)"
            showError = true
            return false
        }
    }

    /// 운동 삭제
    ///
    /// 운동 기록을 삭제하고, 목록을 새로고침합니다.
    ///
    /// - Parameter id: 삭제할 운동 기록 ID
    /// - Returns: 성공 여부
    @discardableResult
    func deleteExercise(id: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            try exerciseRecordService.deleteExercise(id: id)

            // 목록 새로고침
            await loadExercises()

            isLoading = false
            return true

        } catch {
            isLoading = false
            errorMessage = "운동 기록을 삭제할 수 없습니다: \(error.localizedDescription)"
            showError = true
            return false
        }
    }

    /// 데이터 새로고침
    ///
    /// 현재 선택된 날짜의 운동 기록을 다시 로드합니다.
    func refresh() {
        Task {
            await loadExercises()
        }
    }

    /// ExerciseInputViewModel 생성
    ///
    /// ExerciseInputView에서 사용할 ViewModel을 생성합니다.
    /// Create 모드 또는 Edit 모드에 따라 적절한 ViewModel을 반환합니다.
    ///
    /// - Parameter exercise: 수정할 운동 기록 (nil인 경우 Create 모드)
    /// - Returns: ExerciseInputViewModel 인스턴스
    func makeInputViewModel(for exercise: ExerciseRecord?) -> ExerciseInputViewModel {
        return ExerciseInputViewModel(
            exerciseRecordService: exerciseRecordService,
            userRepository: userRepository,
            existingRecord: exercise
        )
    }

    // MARK: - Private Methods

    /// 현재 사용자 로드
    private func loadCurrentUser() async {
        do {
            if let user = try userRepository.fetchCurrentUser() {
                currentUserId = user.id
            } else {
                errorMessage = "사용자 정보를 찾을 수 없습니다."
                showError = true
            }
        } catch {
            errorMessage = "사용자 정보를 불러올 수 없습니다: \(error.localizedDescription)"
            showError = true
        }
    }

    /// 일일 통계 로드
    ///
    /// DailyLog에서 선택된 날짜의 운동 통계를 조회합니다.
    ///
    /// - Parameter userId: 사용자 ID
    private func loadDailyStatistics(userId: UUID) async {
        do {
            if let dailyLog = try dailyLogRepository.fetch(by: userId, date: selectedDate) {
                totalCaloriesBurned = dailyLog.totalCaloriesOut
                totalExerciseMinutes = dailyLog.exerciseMinutes
                exerciseCount = dailyLog.exerciseCount
            } else {
                // DailyLog가 없으면 0으로 초기화
                totalCaloriesBurned = 0
                totalExerciseMinutes = 0
                exerciseCount = 0
            }
        } catch {
            // DailyLog 조회 실패는 조용히 처리 (치명적이지 않음)
            totalCaloriesBurned = 0
            totalExerciseMinutes = 0
            exerciseCount = 0
        }
    }
}

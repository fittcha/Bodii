//
//  ExerciseInputViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import Combine

/// 운동 입력 폼 ViewModel
///
/// 운동 추가/수정 모달의 폼 상태를 관리하고, 실시간 칼로리 미리보기 계산 및 유효성 검증을 처리합니다.
///
/// **주요 기능**:
/// - 폼 상태 관리 (운동 종류, 시간, 강도, 날짜)
/// - 입력 변경 시 실시간 칼로리 미리보기 계산
/// - Duration 유효성 검증 (>= 1분)
/// - 저장 동작 (ExerciseRecordService 호출)
/// - 수정 모드 지원 (기존 레코드 수정)
/// - 저장 성공 시 모달 닫기
///
/// **모드**:
/// - Create 모드: 새 운동 기록 추가
/// - Edit 모드: 기존 운동 기록 수정
///
/// - Example:
/// ```swift
/// // Create 모드
/// let viewModel = ExerciseInputViewModel(
///     exerciseRecordService: service,
///     userRepository: userRepo
/// )
///
/// // Edit 모드
/// let viewModel = ExerciseInputViewModel(
///     exerciseRecordService: service,
///     userRepository: userRepo,
///     existingRecord: exerciseRecord
/// )
///
/// // 폼 저장
/// if await viewModel.save() {
///     // 저장 성공, 모달 닫기
/// }
/// ```
@MainActor
final class ExerciseInputViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 선택된 운동 종류
    @Published var selectedExerciseType: ExerciseType = .running

    /// 운동 시간 (분)
    @Published var duration: String = "30"

    /// 선택된 운동 강도
    @Published var selectedIntensity: Intensity = .medium

    /// 운동 날짜
    @Published var selectedDate: Date = Date()

    /// 예상 소모 칼로리 (실시간 미리보기)
    @Published var caloriePreview: Int32 = 0

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 에러 표시 여부
    @Published var showError: Bool = false

    /// 저장 성공 여부 (모달 닫기 트리거)
    @Published var shouldDismiss: Bool = false

    // MARK: - Private Properties

    /// 운동 기록 서비스
    private let exerciseRecordService: ExerciseRecordService

    /// 사용자 Repository
    private let userRepository: UserRepository

    /// 수정 중인 운동 기록 (Edit 모드인 경우)
    private let existingRecord: ExerciseRecord?

    /// 현재 사용자 체중 (칼로리 계산용)
    private var currentWeight: Double?

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// 수정 모드 여부
    var isEditMode: Bool {
        existingRecord != nil
    }

    /// 제목 (추가 vs 수정)
    var title: String {
        isEditMode ? "운동 수정" : "운동 추가"
    }

    /// 저장 버튼 텍스트
    var saveButtonTitle: String {
        isEditMode ? "수정" : "추가"
    }

    /// Duration 유효성 검증
    var isDurationValid: Bool {
        guard let durationInt = Int32(duration) else {
            return false
        }
        return durationInt >= 1
    }

    /// Duration 유효성 검증 메시지
    var durationValidationMessage: String? {
        guard !duration.isEmpty else {
            return nil
        }
        guard let durationInt = Int32(duration) else {
            return "숫자를 입력해주세요"
        }
        if durationInt < 1 {
            return "최소 1분 이상 입력해주세요"
        }
        return nil
    }

    /// 저장 가능 여부
    var canSave: Bool {
        isDurationValid && !isLoading
    }

    // MARK: - Initialization

    /// ViewModel 초기화
    ///
    /// - Parameters:
    ///   - exerciseRecordService: 운동 기록 서비스
    ///   - userRepository: 사용자 Repository
    ///   - existingRecord: 수정할 기존 레코드 (Edit 모드인 경우)
    init(
        exerciseRecordService: ExerciseRecordService,
        userRepository: UserRepository,
        existingRecord: ExerciseRecord? = nil
    ) {
        self.exerciseRecordService = exerciseRecordService
        self.userRepository = userRepository
        self.existingRecord = existingRecord

        // Edit 모드인 경우 기존 값으로 폼 초기화
        if let record = existingRecord {
            self.selectedExerciseType = record.exerciseType
            self.duration = String(record.duration)
            self.selectedIntensity = record.intensity
            self.selectedDate = record.date
            self.caloriePreview = record.caloriesBurned
        }

        setupBindings()
    }

    // MARK: - Public Methods

    /// 초기화 작업
    ///
    /// 사용자 체중을 조회하고, 초기 칼로리 미리보기를 계산합니다.
    func initialize() {
        Task {
            await loadUserWeight()
            updateCaloriePreview()
        }
    }

    /// 운동 저장
    ///
    /// 폼 유효성 검증 후, 운동 기록을 추가하거나 수정합니다.
    ///
    /// **처리 과정**:
    /// 1. Duration 유효성 검증
    /// 2. Create 모드: ExerciseRecordService.addExercise() 호출
    /// 3. Edit 모드: ExerciseRecordService.updateExercise() 호출
    /// 4. 성공 시 shouldDismiss를 true로 설정하여 모달 닫기
    /// 5. 실패 시 에러 메시지 표시
    ///
    /// - Returns: 저장 성공 여부
    func save() async -> Bool {
        // 유효성 검증
        guard canSave else {
            errorMessage = "입력값을 확인해주세요"
            showError = true
            return false
        }

        guard let durationInt = Int32(duration) else {
            errorMessage = "운동 시간을 올바르게 입력해주세요"
            showError = true
            return false
        }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            if let record = existingRecord {
                // Edit 모드: 기존 레코드 수정
                try exerciseRecordService.updateExercise(
                    id: record.id,
                    date: selectedDate,
                    exerciseType: selectedExerciseType,
                    duration: durationInt,
                    intensity: selectedIntensity
                )
            } else {
                // Create 모드: 새 레코드 추가
                // 사용자 ID 조회
                guard let user = try userRepository.fetchCurrentUser() else {
                    errorMessage = "사용자 정보를 찾을 수 없습니다"
                    showError = true
                    isLoading = false
                    return false
                }

                _ = try exerciseRecordService.addExercise(
                    userId: user.id,
                    date: selectedDate,
                    exerciseType: selectedExerciseType,
                    duration: durationInt,
                    intensity: selectedIntensity
                )
            }

            isLoading = false
            shouldDismiss = true
            return true

        } catch {
            isLoading = false
            errorMessage = "운동 기록을 저장할 수 없습니다: \(error.localizedDescription)"
            showError = true
            return false
        }
    }

    /// 폼 초기화
    ///
    /// 모든 폼 필드를 기본값으로 재설정합니다.
    func reset() {
        selectedExerciseType = .running
        duration = "30"
        selectedIntensity = .medium
        selectedDate = Date()
        caloriePreview = 0
        errorMessage = nil
        showError = false
        shouldDismiss = false
        updateCaloriePreview()
    }

    // MARK: - Private Methods

    /// 사용자 체중 로드
    ///
    /// 칼로리 계산에 필요한 사용자의 현재 체중을 조회합니다.
    private func loadUserWeight() async {
        do {
            if let weight = try userRepository.getCurrentWeight() {
                currentWeight = Double(truncating: weight as NSDecimalNumber)
            } else {
                errorMessage = "체중 정보를 찾을 수 없습니다. 프로필에서 체중을 설정해주세요."
                showError = true
            }
        } catch {
            errorMessage = "사용자 정보를 불러올 수 없습니다: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Combine 바인딩 설정
    ///
    /// 폼 필드가 변경될 때마다 칼로리 미리보기를 자동으로 업데이트합니다.
    private func setupBindings() {
        // 운동 종류, 시간, 강도 변경 시 칼로리 미리보기 업데이트
        Publishers.CombineLatest3(
            $selectedExerciseType,
            $duration,
            $selectedIntensity
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.updateCaloriePreview()
        }
        .store(in: &cancellables)
    }

    /// 칼로리 미리보기 업데이트
    ///
    /// 현재 입력값을 기반으로 예상 소모 칼로리를 계산합니다.
    private func updateCaloriePreview() {
        guard let durationInt = Int32(duration),
              durationInt >= 1,
              let weight = currentWeight,
              weight > 0 else {
            caloriePreview = 0
            return
        }

        caloriePreview = ExerciseCalcService.calculateCaloriesBurned(
            exerciseType: selectedExerciseType,
            duration: durationInt,
            intensity: selectedIntensity,
            weight: weight
        )
    }
}

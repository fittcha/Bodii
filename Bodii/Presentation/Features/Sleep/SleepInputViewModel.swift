//
//  SleepInputViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Sleep Input ViewModel Pattern
// 수면 시간 입력 및 저장을 위한 ViewModel
// 💡 Java 비교: Android의 ViewModel과 유사하지만 SwiftUI의 @Published 사용

import Foundation
import SwiftUI
import Combine

// MARK: - SleepInputViewModel

/// 수면 시간 입력을 위한 ViewModel
/// 📚 학습 포인트: MVVM Pattern
/// - View의 상태를 관리하고 비즈니스 로직 호출
/// - @Published로 상태 변경 시 자동으로 View 업데이트
/// - @MainActor로 UI 스레드에서 안전하게 실행
/// - 시간/분 피커 상태 관리
/// - 수면 상태 자동 계산 및 미리보기
/// - 유효성 검증 및 저장
/// 💡 Java 비교: Android ViewModel + LiveData와 유사
@MainActor
class SleepInputViewModel: ObservableObject {

    // MARK: - Published Properties (Input State)

    /// 수면 시간 (시간 단위: 0-24)
    /// 📚 학습 포인트: @Published
    /// - 값이 변경되면 자동으로 View 업데이트
    /// - Picker와 양방향 바인딩
    /// 💡 Java 비교: LiveData와 유사
    @Published var hours: Int = 7

    /// 수면 시간 (분 단위: 0, 10, 20, 30, 40, 50)
    /// 📚 학습 포인트: 10분 단위 입력
    /// - UI에서 10분 간격으로 선택 가능
    /// - 더 간단한 UX 제공
    @Published var minutes: Int = 0

    // MARK: - Published Properties (View State)

    /// 저장 중 상태
    /// 📚 학습 포인트: Loading State
    /// - API 호출 중 로딩 인디케이터 표시에 사용
    /// - 저장 버튼 비활성화에 사용
    @Published var isSaving: Bool = false

    /// 에러 메시지
    /// 📚 학습 포인트: Optional Error State
    /// - nil이면 에러 없음, 값이 있으면 에러 메시지 표시
    @Published var errorMessage: String?

    /// 성공 메시지
    /// 📚 학습 포인트: Success Feedback
    /// - 저장 성공 시 사용자에게 피드백 제공
    @Published var successMessage: String?

    /// 입력 완료 상태 (저장 완료 후 시트 닫기 트리거)
    /// 📚 학습 포인트: Completion State
    /// - View에서 시트/팝업 닫기 위한 상태
    @Published var isCompleted: Bool = false

    // MARK: - Private Properties

    /// 수면 기록 Use Case
    private let recordSleepUseCase: RecordSleepUseCase

    /// 수면 데이터 저장소 (편집 시 update 호출용)
    private let sleepRepository: SleepRepositoryProtocol?

    /// 사용자 ID
    private let userId: UUID

    /// 편집 중인 기존 기록의 ID (nil이면 새 기록 생성 모드)
    private let editingRecordId: UUID?

    /// 편집 중인 기록의 원본 날짜
    private let editingDate: Date?

    /// Combine 구독 저장소
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// SleepInputViewModel 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - recordSleepUseCase: 수면 기록 Use Case
    ///   - userId: 사용자 ID
    ///   - defaultHours: 기본 수면 시간 (시간, 기본값: 7)
    ///   - defaultMinutes: 기본 수면 시간 (분, 기본값: 0)
    init(
        recordSleepUseCase: RecordSleepUseCase,
        userId: UUID,
        defaultHours: Int = 7,
        defaultMinutes: Int = 0,
        sleepRepository: SleepRepositoryProtocol? = nil,
        editingRecordId: UUID? = nil,
        editingDate: Date? = nil
    ) {
        self.recordSleepUseCase = recordSleepUseCase
        self.userId = userId
        self.hours = defaultHours
        self.minutes = defaultMinutes
        self.sleepRepository = sleepRepository
        self.editingRecordId = editingRecordId
        self.editingDate = editingDate
    }

    // MARK: - Computed Properties

    /// 총 수면 시간 (분 단위)
    /// 📚 학습 포인트: Computed Property
    /// - 시간과 분을 합산하여 총 분 단위로 변환
    /// - Use Case 호출 및 상태 계산에 사용
    var totalMinutes: Int32 {
        return Int32(hours * 60 + minutes)
    }

    /// 예상 수면 상태
    /// 📚 학습 포인트: Real-time Status Preview
    /// - 사용자가 시간을 조정할 때마다 예상 상태 표시
    /// - SleepStatus.from(durationMinutes:) 사용
    var expectedStatus: SleepStatus {
        return SleepStatus.from(durationMinutes: totalMinutes)
    }

    /// 입력 값이 유효한지 확인
    /// 📚 학습 포인트: Validation Logic
    /// - 수면 시간이 0-24시간 범위인지 확인
    /// - 0분도 허용 (밤샘의 경우)
    var isInputValid: Bool {
        let total = totalMinutes
        return total >= 0 && total <= 1440 // 0-24시간
    }

    /// 저장 버튼 활성화 여부
    /// 📚 학습 포인트: UI State Calculation
    /// - 입력이 유효하고 저장 중이 아닐 때만 활성화
    var canSave: Bool {
        isInputValid && !isSaving
    }

    /// 수면 시간 포맷팅 (예: "7시간 30분")
    /// 📚 학습 포인트: Display Formatting
    /// - 사용자에게 보여줄 포맷된 문자열
    var formattedDuration: String {
        if minutes == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(minutes)분"
        }
    }

    // MARK: - Public Methods

    /// 수면 기록 저장
    /// 📚 학습 포인트: Async Method in ViewModel
    /// - Use Case를 호출하여 비즈니스 로직 실행
    /// - 성공/실패 처리 및 UI 상태 업데이트
    /// 💡 Java 비교: Kotlin Coroutines의 suspend function과 유사
    /// 편집 모드 여부
    var isEditing: Bool {
        editingRecordId != nil
    }

    func saveSleep() async {
        guard isInputValid else {
            errorMessage = "수면 시간이 유효하지 않습니다."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        isCompleted = false

        do {
            if let recordId = editingRecordId, let repository = sleepRepository {
                // 편집 모드: 기존 기록 업데이트
                guard let existing = try await repository.fetch(by: recordId) else {
                    errorMessage = "수면 기록을 찾을 수 없습니다."
                    isSaving = false
                    return
                }

                let newDuration = Int32(hours * 60 + minutes)
                let newStatus = SleepStatus.from(durationMinutes: newDuration)
                existing.duration = newDuration
                existing.status = Int16(newStatus.rawValue)
                existing.updatedAt = Date()

                _ = try await repository.update(sleepRecord: existing)

                let (h, m) = (Int(newDuration) / 60, Int(newDuration) % 60)
                successMessage = "수정되었습니다. \(h)시간 \(m)분 - \(newStatus.displayName)"
            } else {
                // 생성 모드: 새 기록 생성
                let result = try await recordSleepUseCase.execute(
                    userId: userId,
                    date: Date(),
                    hours: hours,
                    minutes: minutes
                )

                let (h, m) = result.durationFormatted
                successMessage = "저장되었습니다. \(h)시간 \(m)분 - \(result.status.displayName)"
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isCompleted = true
            }

        } catch let error as RecordSleepUseCase.RecordError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        }

        isSaving = false
    }

    /// 입력 필드 초기화
    /// 📚 학습 포인트: State Reset
    /// - 기본값으로 리셋 (7시간 0분)
    func reset() {
        hours = 7
        minutes = 0
        errorMessage = nil
        successMessage = nil
        isCompleted = false
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

    /// 수면 시간 설정 (분 단위)
    /// 📚 학습 포인트: Convenience Method
    /// - 외부에서 분 단위로 직접 설정 가능
    /// - 예: 이전 기록으로부터 복원할 때
    ///
    /// - Parameter minutes: 총 수면 시간 (분 단위)
    func setDuration(minutes: Int) {
        self.hours = minutes / 60
        self.minutes = minutes % 60
    }

    /// 수면 시간 설정 (시간/분 단위)
    /// 📚 학습 포인트: Convenience Method
    /// - 외부에서 시간/분 단위로 직접 설정 가능
    ///
    /// - Parameters:
    ///   - hours: 수면 시간 (시간)
    ///   - minutes: 수면 시간 (분)
    func setDuration(hours: Int, minutes: Int) {
        self.hours = hours
        self.minutes = minutes
    }

    // MARK: - Helper Methods

    /// 수면 상태 설명 문자열
    /// 📚 학습 포인트: Status Description
    /// - 사용자에게 현재 선택한 수면 시간의 의미 설명
    ///
    /// - Returns: 상태 설명 문자열
    func statusDescription() -> String {
        switch expectedStatus {
        case .bad:
            return "수면 부족 - 충분한 수면을 권장합니다"
        case .soso:
            return "보통 - 조금 더 주무시면 좋습니다"
        case .good:
            return "적정 수면 - 좋은 컨디션이 기대됩니다"
        case .excellent:
            return "매우 좋음 - 최적의 수면 시간입니다"
        case .oversleep:
            return "과다 수면 - 너무 긴 수면은 피로를 유발할 수 있습니다"
        }
    }

    /// 수면 권장 시간 범위 문자열
    /// 📚 학습 포인트: Guideline Information
    /// - 사용자에게 권장 수면 시간 정보 제공
    ///
    /// - Returns: 권장 시간 문자열
    func recommendedRange() -> String {
        return "권장 수면 시간: 7시간 30분 ~ 9시간"
    }
}

// MARK: - Preview Support

#if DEBUG
extension SleepInputViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview(
        userId: UUID = UUID(),
        hours: Int = 7,
        minutes: Int = 30
    ) -> SleepInputViewModel {
        // Mock Use Case 필요 (실제로는 DIContainer에서 주입)
        // 여기서는 임시로 fatalError 사용
        fatalError("Preview support not yet implemented. Use DIContainer.shared.makeSleepInputViewModel() instead.")
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: SleepInputViewModel 이해
///
/// SleepInputViewModel의 역할:
/// - 수면 시간 입력 상태 관리 (시간/분 피커)
/// - 실시간 수면 상태 계산 및 미리보기
/// - 입력 유효성 검증
/// - 수면 기록 저장 (RecordSleepUseCase 호출)
/// - 저장 성공/실패 피드백
///
/// MVVM 패턴에서의 위치:
/// - Model: Domain entities (SleepRecord, SleepStatus)
/// - View: SwiftUI Views (SleepInputSheet)
/// - ViewModel: 이 클래스 (SleepInputViewModel)
///
/// 상태 관리:
/// - hours/minutes: Picker와 양방향 바인딩
/// - expectedStatus: 실시간으로 계산되어 미리보기 표시
/// - isSaving: 저장 중 로딩 인디케이터
/// - errorMessage/successMessage: 사용자 피드백
/// - isCompleted: 저장 완료 후 시트 닫기
///
/// 비즈니스 플로우:
/// 1. 사용자가 시간/분 Picker 조정
/// 2. expectedStatus 자동 업데이트 (computed property)
/// 3. 저장 버튼 클릭
/// 4. saveSleep() 호출
/// 5. RecordSleepUseCase.execute() 실행
///    - SleepStatus 자동 계산
///    - 02:00 경계 로직 적용
///    - DailyLog 자동 업데이트
/// 6. 성공 메시지 표시
/// 7. 1.5초 후 isCompleted = true
/// 8. View에서 시트 닫기
///
/// 의존성:
/// - RecordSleepUseCase: 수면 기록 저장
/// - userId: 사용자 식별자
///
/// 사용 예시:
/// ```swift
/// struct SleepInputSheet: View {
///     @StateObject private var viewModel: SleepInputViewModel
///     @Environment(\.dismiss) var dismiss
///
///     var body: some View {
///         VStack {
///             // 시간/분 피커
///             HStack {
///                 Picker("시간", selection: $viewModel.hours) {
///                     ForEach(0...24, id: \.self) { hour in
///                         Text("\(hour)시간").tag(hour)
///                     }
///                 }
///                 .pickerStyle(.wheel)
///
///                 Picker("분", selection: $viewModel.minutes) {
///                     ForEach([0, 10, 20, 30, 40, 50], id: \.self) { min in
///                         Text("\(min)분").tag(min)
///                     }
///                 }
///                 .pickerStyle(.wheel)
///             }
///
///             // 예상 상태 미리보기
///             SleepStatusBadge(status: viewModel.expectedStatus)
///             Text(viewModel.statusDescription())
///
///             // 저장 버튼
///             Button("저장") {
///                 Task {
///                     await viewModel.saveSleep()
///                 }
///             }
///             .disabled(!viewModel.canSave)
///         }
///         .onChange(of: viewModel.isCompleted) { completed in
///             if completed {
///                 dismiss()
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
/// - Android: ViewModel + LiveData + Use Cases
/// - SwiftUI: ObservableObject + @Published + Use Cases
/// - Android: viewModelScope.launch
/// - SwiftUI: Task { await ... } with @MainActor
///
/// 💡 실무 팁:
/// - Picker의 양방향 바인딩을 위해 @Published 사용
/// - expectedStatus는 computed property로 실시간 계산
/// - 저장 성공 후 1.5초 대기하여 메시지를 보여준 후 시트 닫기
/// - isCompleted를 onChange로 감지하여 dismiss() 호출
/// - 에러는 alert로 표시하여 사용자가 확인 가능
///
/// RecordSleepUseCase와의 협력:
/// - ViewModel: UI 상태 관리 및 입력 수집
/// - Use Case: 비즈니스 로직 (상태 계산, 저장, DailyLog 업데이트)
/// - ViewModel은 Use Case의 결과만 받아서 UI 업데이트
///

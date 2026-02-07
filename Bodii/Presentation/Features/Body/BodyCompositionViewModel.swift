//
//  BodyCompositionViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: ViewModel Pattern in SwiftUI
// MVVM 패턴의 ViewModel - View와 비즈니스 로직을 연결
// 💡 Java 비교: Android의 ViewModel과 유사하지만 SwiftUI의 @Published 사용

import Foundation
import SwiftUI
import Combine

// MARK: - BodyCompositionViewModel

/// 신체 구성 입력 및 히스토리 표시를 위한 ViewModel
/// 📚 학습 포인트: MVVM Pattern
/// - View의 상태를 관리하고 비즈니스 로직 호출
/// - @Published로 상태 변경 시 자동으로 View 업데이트
/// - @MainActor로 UI 스레드에서 안전하게 실행
/// 💡 Java 비교: Android ViewModel + LiveData와 유사
@MainActor
class BodyCompositionViewModel: ObservableObject {

    // MARK: - Published Properties (Input State)

    /// 체중 입력 값 (kg)
    /// 📚 학습 포인트: @Published
    /// - 값이 변경되면 자동으로 View 업데이트
    /// - SwiftUI의 양방향 바인딩 지원
    /// 💡 Java 비교: LiveData와 유사
    @Published var weightInput: String = ""

    /// 체지방률 입력 값 (%)
    @Published var bodyFatPercentInput: String = ""

    /// 근육량 입력 값 (kg)
    @Published var muscleMassInput: String = ""

    /// 입력 날짜 (과거 날짜 데이터 입력 지원)
    @Published var inputDate: Date = Date()

    // MARK: - Published Properties (View State)

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - API 호출 중 로딩 인디케이터 표시에 사용
    @Published var isLoading: Bool = false

    /// 저장 중 상태
    /// 📚 학습 포인트: Separate Loading States
    /// - 데이터 조회와 저장을 구분하여 UX 개선
    @Published var isSaving: Bool = false

    /// 에러 메시지
    /// 📚 학습 포인트: Optional Error State
    /// - nil이면 에러 없음, 값이 있으면 에러 메시지 표시
    @Published var errorMessage: String?

    /// 성공 메시지
    /// 📚 학습 포인트: Success Feedback
    /// - 저장 성공 시 사용자에게 피드백 제공
    @Published var successMessage: String?

    /// 신체 구성 기록 히스토리
    /// 📚 학습 포인트: Collection State
    /// - 최근 기록들을 리스트로 표시
    @Published var history: [BodyCompositionEntry] = []

    /// 최근 대사율 데이터
    /// 📚 학습 포인트: Optional State
    /// - 가장 최근 계산된 BMR/TDEE 표시
    @Published var latestMetabolism: MetabolismData?

    /// 입력 유효성 검증 메시지
    /// 📚 학습 포인트: Validation Feedback
    /// - 실시간 입력 검증 피드백
    @Published var validationMessages: [String] = []

    // MARK: - Private Properties

    /// 신체 구성 기록 Use Case
    /// 📚 학습 포인트: Dependency Injection
    /// - Use Case를 외부에서 주입받아 사용
    /// - 테스트 시 Mock으로 교체 가능
    private let recordBodyCompositionUseCase: RecordBodyCompositionUseCase

    /// 신체 트렌드 조회 Use Case
    private let fetchBodyTrendsUseCase: FetchBodyTrendsUseCase

    /// 신체 데이터 저장소
    /// 📚 학습 포인트: Protocol-Oriented Programming
    /// - 구현체가 아닌 프로토콜에 의존
    private let bodyRepository: BodyRepositoryProtocol

    /// 사용자 프로필
    /// 📚 학습 포인트: User Context
    /// - BMR/TDEE 계산에 필요한 사용자 정보
    /// - TODO: UserRepository에서 조회하도록 개선
    private var userProfile: UserProfile

    /// Combine 구독 저장소
    /// 📚 학습 포인트: Combine Framework
    /// - 비동기 이벤트 스트림 관리
    /// - 메모리 누수 방지를 위한 구독 관리
    /// 💡 Java 비교: RxJava의 CompositeDisposable과 유사
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// BodyCompositionViewModel 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - recordBodyCompositionUseCase: 신체 구성 기록 Use Case
    ///   - fetchBodyTrendsUseCase: 신체 트렌드 조회 Use Case
    ///   - bodyRepository: 신체 데이터 저장소
    ///   - userProfile: 사용자 프로필 (기본값: 샘플 데이터)
    init(
        recordBodyCompositionUseCase: RecordBodyCompositionUseCase,
        fetchBodyTrendsUseCase: FetchBodyTrendsUseCase,
        bodyRepository: BodyRepositoryProtocol,
        userProfile: UserProfile = .sample
    ) {
        self.recordBodyCompositionUseCase = recordBodyCompositionUseCase
        self.fetchBodyTrendsUseCase = fetchBodyTrendsUseCase
        self.bodyRepository = bodyRepository
        self.userProfile = userProfile

        // 초기 데이터 로드
        Task {
            await loadHistory()
            await loadLatestMetabolism()
        }
    }

    // MARK: - Computed Properties

    /// 입력 값이 유효한지 확인
    /// 📚 학습 포인트: Computed Property for Validation
    /// - 실시간으로 입력 유효성 검증
    /// - View에서 저장 버튼 활성화/비활성화에 사용
    var isInputValid: Bool {
        // 체중은 필수
        guard let weight = Decimal(string: weightInput) else {
            return false
        }
        guard weight >= 20 && weight <= 200 else { return false }

        // 체지방률은 선택 (입력 시 범위 검증)
        if !bodyFatPercentInput.isEmpty {
            guard let bodyFatPercent = Decimal(string: bodyFatPercentInput),
                  bodyFatPercent >= 1 && bodyFatPercent <= 60 else { return false }
        }

        // 근육량은 선택 (입력 시 범위 검증)
        if !muscleMassInput.isEmpty {
            guard let muscleMass = Decimal(string: muscleMassInput),
                  muscleMass >= 10 && muscleMass <= 100 else { return false }
            if muscleMass >= weight { return false }
        }

        return true
    }

    /// 저장 버튼 활성화 여부
    /// 📚 학습 포인트: UI State Calculation
    /// - 입력이 유효하고 저장 중이 아닐 때만 활성화
    var canSave: Bool {
        isInputValid && !isSaving
    }

    // MARK: - Public Methods

    /// 신체 구성 데이터 저장
    /// 📚 학습 포인트: Async Method in ViewModel
    /// - Use Case를 호출하여 비즈니스 로직 실행
    /// - 성공/실패 처리 및 UI 상태 업데이트
    /// 💡 Java 비교: Kotlin Coroutines의 suspend function과 유사
    func saveBodyComposition() async {
        // 📚 학습 포인트: Guard Statement
        // 입력이 유효하지 않으면 조기 리턴
        guard isInputValid else {
            errorMessage = "입력 값이 유효하지 않습니다."
            return
        }

        // 입력 값을 Decimal로 변환 (체중 필수, 나머지 선택)
        guard let weight = Decimal(string: weightInput) else {
            errorMessage = "체중을 올바르게 입력해주세요."
            return
        }
        let bodyFatPercent = Decimal(string: bodyFatPercentInput)
        let muscleMass = Decimal(string: muscleMassInput)

        // 저장 시작
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            // 📚 학습 포인트: Use Case Execution
            // 비즈니스 로직은 Use Case에 위임
            let result = try await recordBodyCompositionUseCase.execute(
                date: inputDate,
                weight: weight,
                bodyFatPercent: bodyFatPercent,
                muscleMass: muscleMass,
                userProfile: userProfile
            )

            // 성공 처리
            successMessage = "저장되었습니다. BMR: \(formatCalories(result.bmr)) kcal/day"

            // 최근 대사율 데이터 업데이트
            latestMetabolism = result.metabolismData

            // 입력 필드 초기화
            clearInputs()

            // 히스토리 새로고침
            await loadHistory()

            // 📚 학습 포인트: Delayed Message Clear
            // 3초 후 성공 메시지 자동 제거
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초
                successMessage = nil
            }

        } catch let error as RecordBodyCompositionUseCase.RecordError {
            // 📚 학습 포인트: Specific Error Handling
            // Use Case의 도메인 에러를 사용자 친화적 메시지로 변환
            errorMessage = error.localizedDescription
        } catch {
            // 📚 학습 포인트: Generic Error Handling
            // 예상하지 못한 에러 처리
            errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        }

        isSaving = false
    }

    /// 히스토리 로드
    /// 📚 학습 포인트: Data Loading Method
    /// - Repository에서 최근 데이터 조회
    /// - 에러 처리 및 로딩 상태 관리
    func loadHistory() async {
        isLoading = true
        errorMessage = nil

        do {
            // 📚 학습 포인트: Repository Query
            // 최근 30일 데이터 조회 (최신순 정렬)
            let entries = try await bodyRepository.fetchRecent(days: 30)
            history = entries.sorted { $0.date > $1.date }
        } catch {
            errorMessage = "히스토리 로드 실패: \(error.localizedDescription)"
            history = []
        }

        isLoading = false
    }

    /// 최근 대사율 데이터 로드
    /// 📚 학습 포인트: Related Data Loading
    /// - 가장 최근 기록의 대사율 데이터 조회
    private func loadLatestMetabolism() async {
        do {
            // 가장 최근 기록 조회
            if let latestEntry = try await bodyRepository.fetchLatest() {
                // 해당 기록의 대사율 데이터 조회
                latestMetabolism = try await bodyRepository.fetchMetabolismData(for: latestEntry.id)
            }
        } catch {
            // 📚 학습 포인트: Silent Failure
            // 선택적 데이터 로드 실패는 조용히 처리
            print("⚠️ 최근 대사율 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    /// 특정 기록 삭제
    /// 📚 학습 포인트: Delete Operation
    /// - 사용자 확인 후 호출
    /// - 삭제 후 히스토리 새로고침
    ///
    /// - Parameter id: 삭제할 기록 ID
    func deleteEntry(id: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            try await bodyRepository.delete(by: id)

            // 📚 학습 포인트: Optimistic Update
            // 서버 응답을 기다리지 않고 즉시 UI에서 제거
            history.removeAll { $0.id == id }

            successMessage = "삭제되었습니다."

            // 3초 후 메시지 제거
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                successMessage = nil
            }

        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 사용자 성별 (트렌드 차트 건강 구간에 사용)
    var userGender: Gender {
        userProfile.gender
    }

    /// 입력 필드 초기화
    /// 📚 학습 포인트: State Reset
    /// - 저장 후 입력 필드 클리어
    func clearInputs() {
        weightInput = ""
        bodyFatPercentInput = ""
        muscleMassInput = ""
        inputDate = Date()
        validationMessages = []
    }

    /// 입력 검증 및 검증 메시지 업데이트
    /// 📚 학습 포인트: Real-time Validation
    /// - 사용자가 입력할 때마다 실시간 검증
    /// - 구체적인 에러 메시지 제공
    func validateInputs() {
        validationMessages = []

        // 체중 검증
        if !weightInput.isEmpty {
            if let weight = Decimal(string: weightInput) {
                if weight < 20 {
                    validationMessages.append("체중은 20kg 이상이어야 합니다.")
                } else if weight > 200 {
                    validationMessages.append("체중은 200kg 이하여야 합니다.")
                }
            } else {
                validationMessages.append("체중을 올바르게 입력해주세요.")
            }
        }

        // 체지방률 검증
        if !bodyFatPercentInput.isEmpty {
            if let bodyFatPercent = Decimal(string: bodyFatPercentInput) {
                if bodyFatPercent < 1 {
                    validationMessages.append("체지방률은 1% 이상이어야 합니다.")
                } else if bodyFatPercent > 60 {
                    validationMessages.append("체지방률은 60% 이하여야 합니다.")
                }
            } else {
                validationMessages.append("체지방률을 올바르게 입력해주세요.")
            }
        }

        // 근육량 검증
        if !muscleMassInput.isEmpty {
            if let muscleMass = Decimal(string: muscleMassInput) {
                if muscleMass < 10 {
                    validationMessages.append("근육량은 10kg 이상이어야 합니다.")
                } else if muscleMass > 100 {
                    validationMessages.append("근육량은 100kg 이하여야 합니다.")
                }

                // 근육량이 체중보다 큰지 검증
                if let weight = Decimal(string: weightInput), muscleMass >= weight {
                    validationMessages.append("근육량은 체중보다 작아야 합니다.")
                }
            } else {
                validationMessages.append("근육량을 올바르게 입력해주세요.")
            }
        }
    }

    /// 사용자 프로필 업데이트
    /// 📚 학습 포인트: Profile Management
    /// - BMR/TDEE 계산에 사용되는 프로필 업데이트
    /// - TODO: UserRepository를 통해 영구 저장
    ///
    /// - Parameter newProfile: 새로운 사용자 프로필
    func updateUserProfile(_ newProfile: UserProfile) {
        self.userProfile = newProfile
    }

    // MARK: - Helper Methods

    /// 칼로리 값 포맷팅
    /// 📚 학습 포인트: Number Formatting
    /// - Decimal을 읽기 쉬운 문자열로 변환
    /// - 소수점 없이 정수로 표시
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
}

// MARK: - Preview Support

#if DEBUG
extension BodyCompositionViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview() -> BodyCompositionViewModel {
        // Mock Repository 생성 (실제 구현 필요)
        // 여기서는 샘플 데이터를 반환하는 Mock 사용
        fatalError("Preview support not yet implemented. Need to create MockBodyRepository.")
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: ViewModel Pattern 이해
///
/// BodyCompositionViewModel의 역할:
/// - View의 상태 관리: @Published 프로퍼티로 View 자동 업데이트
/// - 비즈니스 로직 호출: Use Case를 통해 도메인 로직 실행
/// - 에러 처리: 도메인 에러를 사용자 친화적 메시지로 변환
/// - 입력 검증: 실시간 입력 검증 및 피드백
/// - 데이터 로딩: Repository를 통해 히스토리 조회
///
/// MVVM 패턴에서의 위치:
/// - Model: Domain entities (BodyCompositionEntry, MetabolismData)
/// - View: SwiftUI Views (BodyCompositionView)
/// - ViewModel: 이 클래스 (BodyCompositionViewModel)
///
/// 상태 관리:
/// - @Published: 값 변경 시 자동으로 View 업데이트
/// - @MainActor: 모든 메서드가 메인 스레드에서 실행되어 UI 안전 보장
/// - Combine: 비동기 이벤트 스트림 관리
///
/// 의존성:
/// - RecordBodyCompositionUseCase: 신체 구성 저장
/// - FetchBodyTrendsUseCase: 트렌드 데이터 조회
/// - BodyRepositoryProtocol: 데이터 영속화
/// - UserProfile: BMR/TDEE 계산용 사용자 정보
///
/// 사용 예시:
/// ```swift
/// struct BodyCompositionView: View {
///     @StateObject private var viewModel = BodyCompositionViewModel(
///         recordBodyCompositionUseCase: recordUseCase,
///         fetchBodyTrendsUseCase: trendsUseCase,
///         bodyRepository: repository
///     )
///
///     var body: some View {
///         Form {
///             Section("입력") {
///                 TextField("체중 (kg)", text: $viewModel.weightInput)
///                 TextField("체지방률 (%)", text: $viewModel.bodyFatPercentInput)
///                 TextField("근육량 (kg)", text: $viewModel.muscleMassInput)
///
///                 Button("저장") {
///                     Task {
///                         await viewModel.saveBodyComposition()
///                     }
///                 }
///                 .disabled(!viewModel.canSave)
///             }
///
///             Section("최근 기록") {
///                 ForEach(viewModel.history) { entry in
///                     BodyEntryRow(entry: entry)
///                 }
///             }
///         }
///         .alert("에러", isPresented: .constant(viewModel.errorMessage != nil)) {
///             Button("확인") { viewModel.errorMessage = nil }
///         } message: {
///             Text(viewModel.errorMessage ?? "")
///         }
///     }
/// }
/// ```
///
/// 💡 Android ViewModel과의 비교:
/// - Android: ViewModel + LiveData + Repository
/// - SwiftUI: ObservableObject + @Published + Use Cases
/// - Android: viewModelScope.launch
/// - SwiftUI: Task { await ... } with @MainActor
///

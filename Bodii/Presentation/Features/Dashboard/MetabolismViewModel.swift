//
//  MetabolismViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Dashboard-Focused ViewModel Pattern
// 대시보드에서 BMR/TDEE 및 칼로리 균형을 표시하기 위한 ViewModel
// 💡 Java 비교: Android의 ViewModel과 유사하지만 대시보드 전용 상태 관리

import Foundation
import SwiftUI
import Combine

// MARK: - MetabolismViewModel

/// 대시보드에서 BMR/TDEE 표시를 위한 ViewModel
/// 📚 학습 포인트: Dashboard Data Management
/// - 현재 BMR/TDEE 데이터 관리
/// - 칼로리 섭취/소비 비교
/// - 칼로리 잉여/결핍 계산
/// - 신체 기록 변경 시 자동 새로고침
/// 💡 Java 비교: Android ViewModel + Dashboard state management
@MainActor
class MetabolismViewModel: ObservableObject {

    // MARK: - Published Properties (View State)

    /// 현재 대사율 데이터
    /// 📚 학습 포인트: Optional State
    /// - nil이면 아직 데이터 로드 안 됨 또는 기록 없음
    /// - 값이 있으면 대시보드에 표시
    /// 💡 Java 비교: LiveData<MetabolismData?>와 유사
    @Published var currentMetabolism: MetabolismData?

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 데이터 조회 중 로딩 인디케이터 표시
    @Published var isLoading: Bool = false

    /// 에러 메시지
    /// 📚 학습 포인트: Error State
    /// - nil이면 에러 없음
    /// - 값이 있으면 에러 메시지 표시
    @Published var errorMessage: String?

    /// 일일 칼로리 섭취량 (kcal)
    /// 📚 학습 포인트: External Data Integration
    /// - 다이어트 모듈에서 제공하는 섭취 칼로리
    /// - 대시보드에서 균형 계산에 사용
    @Published var dailyCalorieIntake: Decimal = 0

    /// 일일 칼로리 소비량 (kcal)
    /// 📚 학습 포인트: External Data Integration
    /// - 운동 모듈에서 제공하는 소비 칼로리
    /// - TDEE에 추가되어 총 소비량 계산
    @Published var dailyCalorieExpenditure: Decimal = 0

    // MARK: - Private Properties

    /// 신체 데이터 저장소
    /// 📚 학습 포인트: Dependency Injection
    /// - Repository를 외부에서 주입받아 사용
    /// - 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: @Inject로 주입받는 Repository와 유사
    private let bodyRepository: BodyRepositoryProtocol

    /// Combine 구독 저장소
    /// 📚 학습 포인트: Reactive Programming
    /// - 데이터 변경 감지 및 자동 새로고침
    /// - 메모리 누수 방지를 위한 구독 관리
    /// 💡 Java 비교: RxJava의 CompositeDisposable과 유사
    private var cancellables = Set<AnyCancellable>()

    /// 마지막 새로고침 시간
    /// 📚 학습 포인트: Refresh Tracking
    /// - 중복 새로고침 방지
    /// - 캐싱 전략에 사용 가능
    private var lastRefreshDate: Date?

    // MARK: - Initialization

    /// MetabolismViewModel 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameter bodyRepository: 신체 데이터 저장소
    init(bodyRepository: BodyRepositoryProtocol) {
        self.bodyRepository = bodyRepository

        // 초기 데이터 로드
        Task {
            await loadCurrentMetabolism()
        }
    }

    // MARK: - Computed Properties

    /// BMR이 있는지 확인
    /// 📚 학습 포인트: Computed Property for State Check
    /// - View에서 데이터 표시 여부 결정
    var hasBMR: Bool {
        currentMetabolism != nil
    }

    /// 현재 BMR (kcal/day)
    /// 📚 학습 포인트: Convenience Property
    /// - View에서 직접 접근 가능한 편의 속성
    var bmr: Decimal? {
        currentMetabolism?.bmr
    }

    /// 현재 TDEE (kcal/day)
    /// 📚 학습 포인트: Convenience Property
    /// - View에서 직접 접근 가능한 편의 속성
    var tdee: Decimal? {
        currentMetabolism?.tdee
    }

    /// 활동 수준
    /// 📚 학습 포인트: Convenience Property
    var activityLevel: ActivityLevel? {
        currentMetabolism?.activityLevel
    }

    /// 칼로리 균형 (섭취 - 소비)
    /// 📚 학습 포인트: Calorie Balance Calculation
    /// - 양수: 칼로리 잉여 (체중 증가 경향)
    /// - 음수: 칼로리 결핍 (체중 감소 경향)
    /// - 0 또는 근접: 유지 상태
    var calorieBalance: Decimal? {
        guard let tdee = tdee else { return nil }
        let totalExpenditure = tdee + dailyCalorieExpenditure
        return dailyCalorieIntake - totalExpenditure
    }

    /// 칼로리 잉여 상태인지 확인
    /// 📚 학습 포인트: State Classification
    /// - View에서 색상이나 메시지 결정에 사용
    var isCalorieSurplus: Bool {
        guard let balance = calorieBalance else { return false }
        return balance > 0
    }

    /// 칼로리 결핍 상태인지 확인
    var isCalorieDeficit: Bool {
        guard let balance = calorieBalance else { return false }
        return balance < 0
    }

    /// 칼로리 균형 상태 (유지)인지 확인
    /// 📚 학습 포인트: Tolerance Range
    /// - ±100 kcal 범위는 유지 상태로 간주
    var isCalorieMaintenance: Bool {
        guard let balance = calorieBalance else { return false }
        return abs(balance as NSDecimalNumber).doubleValue <= 100
    }

    /// 총 칼로리 소비량 (TDEE + 운동)
    /// 📚 학습 포인트: Total Expenditure
    /// - TDEE (기본 대사량 + 활동 대사량) + 추가 운동
    var totalCalorieExpenditure: Decimal? {
        guard let tdee = tdee else { return nil }
        return tdee + dailyCalorieExpenditure
    }

    /// 예상 주간 체중 변화 (kg/week)
    /// 📚 학습 포인트: Weight Change Prediction
    /// - 현재 칼로리 균형을 기반으로 예측
    var estimatedWeeklyWeightChange: Decimal? {
        guard let metabolism = currentMetabolism else { return nil }
        return metabolism.estimatedWeeklyWeightChange(calorieIntake: dailyCalorieIntake)
    }

    // MARK: - Public Methods

    /// 현재 대사율 데이터 로드
    /// 📚 학습 포인트: Async Data Loading
    /// - Repository에서 최신 데이터 조회
    /// - 로딩 상태 및 에러 처리
    /// 💡 Java 비교: Kotlin Coroutines의 suspend function과 유사
    func loadCurrentMetabolism() async {
        isLoading = true
        errorMessage = nil

        do {
            // 📚 학습 포인트: Latest Record Query
            // 가장 최근 신체 기록의 대사율 데이터 조회
            if let latestEntry = try await bodyRepository.fetchLatest() {
                currentMetabolism = try await bodyRepository.fetchMetabolismData(for: latestEntry.id)
                lastRefreshDate = Date()
            } else {
                // 📚 학습 포인트: No Data State
                // 기록이 없는 경우 nil로 설정
                currentMetabolism = nil
            }

        } catch let error as RepositoryError {
            // 📚 학습 포인트: Specific Error Handling
            // Repository의 도메인 에러를 사용자 친화적 메시지로 변환
            errorMessage = error.localizedDescription
            currentMetabolism = nil
        } catch {
            // 📚 학습 포인트: Generic Error Handling
            errorMessage = "대사율 데이터 로드 실패: \(error.localizedDescription)"
            currentMetabolism = nil
        }

        isLoading = false
    }

    /// 칼로리 섭취량 업데이트
    /// 📚 학습 포인트: External Data Update
    /// - 다이어트 모듈에서 호출
    /// - 칼로리 균형 자동 재계산 (computed property)
    ///
    /// - Parameter intake: 일일 칼로리 섭취량 (kcal)
    func updateCalorieIntake(_ intake: Decimal) {
        dailyCalorieIntake = intake
    }

    /// 칼로리 소비량 업데이트
    /// 📚 학습 포인트: External Data Update
    /// - 운동 모듈에서 호출
    /// - 칼로리 균형 자동 재계산 (computed property)
    ///
    /// - Parameter expenditure: 추가 칼로리 소비량 (kcal)
    func updateCalorieExpenditure(_ expenditure: Decimal) {
        dailyCalorieExpenditure = expenditure
    }

    /// 새로고침
    /// 📚 학습 포인트: Manual Refresh
    /// - 신체 기록 추가 후 호출
    /// - Pull-to-refresh 등에서 사용
    func refresh() async {
        // 📚 학습 포인트: Debounce Check
        // 짧은 시간 내 중복 새로고침 방지 (1초 이내)
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < 1.0 {
            return
        }

        await loadCurrentMetabolism()
    }

    /// 에러 메시지 제거
    /// 📚 학습 포인트: State Cleanup
    /// - 사용자가 에러 확인 후 호출
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Helper Methods

    /// 칼로리 값 포맷팅 (정수)
    /// 📚 학습 포인트: Number Formatting
    /// - Decimal을 읽기 쉬운 문자열로 변환
    /// - 소수점 없이 정수로 표시
    ///
    /// - Parameter calories: 칼로리 값
    /// - Returns: 포맷된 문자열 (예: "1,650")
    func formatCalories(_ calories: Decimal?) -> String {
        guard let calories = calories else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let number = NSDecimalNumber(decimal: calories)
        return formatter.string(from: number) ?? "\(calories)"
    }

    /// 칼로리 균형 포맷팅 (부호 포함)
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    /// - 색상 결정에도 사용 가능
    ///
    /// - Parameter balance: 칼로리 균형
    /// - Returns: 포맷된 문자열 (예: "+300 kcal", "-150 kcal")
    func formatCalorieBalance(_ balance: Decimal?) -> String {
        guard let balance = balance else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: balance)
        return (formatter.string(from: number) ?? "\(balance)") + " kcal"
    }

    /// 체중 변화 포맷팅
    /// 📚 학습 포인트: Weight Change Formatting
    /// - 주간 예상 체중 변화를 포맷팅
    ///
    /// - Parameter change: 체중 변화량 (kg/week)
    /// - Returns: 포맷된 문자열 (예: "+0.5 kg/week", "-0.3 kg/week")
    func formatWeightChange(_ change: Decimal?) -> String {
        guard let change = change else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + " kg/주"
    }

    /// 칼로리 균형 상태 문자열
    /// 📚 학습 포인트: State Description
    /// - 사용자에게 현재 상태를 명확히 전달
    ///
    /// - Returns: 상태 문자열 ("잉여", "결핍", "유지")
    func calorieBalanceStatusText() -> String {
        guard calorieBalance != nil else { return "데이터 없음" }

        if isCalorieMaintenance {
            return "유지"
        } else if isCalorieSurplus {
            return "잉여"
        } else {
            return "결핍"
        }
    }

    /// 칼로리 균형 상태 색상
    /// 📚 학습 포인트: UI State Mapping
    /// - 상태에 따른 색상 제공
    ///
    /// - Returns: 상태에 맞는 색상
    func calorieBalanceStatusColor() -> Color {
        guard calorieBalance != nil else { return .gray }

        if isCalorieMaintenance {
            return .green
        } else if isCalorieSurplus {
            return .orange
        } else {
            return .blue
        }
    }

    /// 칼로리 균형 상태 아이콘
    /// 📚 학습 포인트: SF Symbols Integration
    /// - 상태에 따른 아이콘 제공
    ///
    /// - Returns: SF Symbol 이름
    func calorieBalanceStatusIcon() -> String {
        guard calorieBalance != nil else { return "questionmark.circle" }

        if isCalorieMaintenance {
            return "equal.circle.fill"
        } else if isCalorieSurplus {
            return "arrow.up.circle.fill"
        } else {
            return "arrow.down.circle.fill"
        }
    }

    /// BMR/TDEE 차이 설명 문자열
    /// 📚 학습 포인트: Educational Content
    /// - 사용자에게 BMR과 TDEE의 차이 설명
    ///
    /// - Returns: 설명 문자열
    func metabolismExplanation() -> String {
        guard let metabolism = currentMetabolism else {
            return "신체 기록을 추가하면 BMR과 TDEE가 자동으로 계산됩니다."
        }

        let activityCalories = metabolism.activityCalories
        return "활동으로 인한 추가 소비: \(formatCalories(activityCalories)) kcal/일"
    }
}

// MARK: - Preview Support

#if DEBUG
extension MetabolismViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview() -> MetabolismViewModel {
        // Mock Repository 생성 (실제 구현 필요)
        fatalError("Preview support not yet implemented. Need to create MockBodyRepository.")
    }

    /// 샘플 데이터가 있는 ViewModel
    /// 📚 학습 포인트: Sample Data for Preview
    /// - 대시보드 미리보기를 위한 샘플 데이터 포함
    static func makePreviewWithData(repository: BodyRepositoryProtocol) -> MetabolismViewModel {
        let viewModel = MetabolismViewModel(bodyRepository: repository)

        // 샘플 데이터 설정
        viewModel.currentMetabolism = MetabolismData.sample
        viewModel.dailyCalorieIntake = Decimal(2000)
        viewModel.dailyCalorieExpenditure = Decimal(300)

        return viewModel
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: Dashboard ViewModel Pattern 이해
///
/// MetabolismViewModel의 역할:
/// - BMR/TDEE 표시: 최신 대사율 데이터 조회 및 표시
/// - 칼로리 균형 계산: 섭취 vs 소비 비교
/// - 상태 분류: 잉여/결핍/유지 상태 판단
/// - 자동 새로고침: 신체 기록 추가 시 자동 업데이트
/// - UI 헬퍼: 포맷팅, 색상, 아이콘 제공
///
/// 주요 기능:
/// 1. 최신 BMR/TDEE 로드
/// 2. 칼로리 섭취/소비 추적
/// 3. 칼로리 균형 계산 (자동)
/// 4. 예상 체중 변화 계산
/// 5. 상태별 시각적 피드백 (색상, 아이콘)
///
/// 데이터 흐름:
/// - BodyRepository → 최신 MetabolismData 조회
/// - DietModule → dailyCalorieIntake 업데이트
/// - ExerciseModule → dailyCalorieExpenditure 업데이트
/// - Computed Properties → calorieBalance, estimatedWeightChange 자동 계산
///
/// 상태 관리:
/// - @Published: 값 변경 시 자동으로 View 업데이트
/// - @MainActor: 모든 메서드가 메인 스레드에서 실행
/// - Computed Properties: BMR/TDEE 기반 실시간 계산
///
/// 의존성:
/// - BodyRepositoryProtocol: 대사율 데이터 조회
///
/// 사용 예시:
/// ```swift
/// struct DashboardView: View {
///     @StateObject private var viewModel = MetabolismViewModel(
///         bodyRepository: repository
///     )
///
///     var body: some View {
///         VStack {
///             // BMR/TDEE 카드
///             if let bmr = viewModel.bmr, let tdee = viewModel.tdee {
///                 HStack {
///                     VStack {
///                         Text("BMR")
///                         Text("\(viewModel.formatCalories(bmr)) kcal")
///                     }
///                     VStack {
///                         Text("TDEE")
///                         Text("\(viewModel.formatCalories(tdee)) kcal")
///                     }
///                 }
///             }
///
///             // 칼로리 균형
///             if let balance = viewModel.calorieBalance {
///                 HStack {
///                     Image(systemName: viewModel.calorieBalanceStatusIcon())
///                         .foregroundColor(viewModel.calorieBalanceStatusColor())
///                     Text(viewModel.calorieBalanceStatusText())
///                     Text(viewModel.formatCalorieBalance(balance))
///                 }
///             }
///
///             // 예상 체중 변화
///             if let change = viewModel.estimatedWeeklyWeightChange {
///                 Text("예상 체중 변화: \(viewModel.formatWeightChange(change))")
///             }
///         }
///         .task {
///             await viewModel.loadCurrentMetabolism()
///         }
///     }
/// }
/// ```
///
/// 💡 Android ViewModel과의 비교:
/// - Android: ViewModel + StateFlow + Dashboard data
/// - SwiftUI: ObservableObject + @Published + Dashboard data
/// - Android: combine으로 여러 Flow 결합
/// - SwiftUI: Computed properties로 여러 상태 결합
///

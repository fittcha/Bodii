//
//  OnboardingViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import Foundation
import SwiftUI
import CoreData

/// 온보딩 ViewModel
/// 전체 온보딩 플로우 상태 관리
///
/// **주요 기능**:
/// - 온보딩 단계 전환 관리
/// - 입력 값 유효성 검증
/// - BMR/TDEE 계산 및 User 생성
///
/// - Example:
/// ```swift
/// @StateObject private var viewModel = OnboardingViewModel()
///
/// // 다음 단계로 이동
/// viewModel.goToNext()
///
/// // 온보딩 완료
/// await viewModel.completeOnboarding()
/// ```
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Onboarding Steps

    /// 온보딩 단계
    enum Step: Int, CaseIterable {
        case welcome = 0
        case basicInfo = 1
        case bodyInfo = 2
        case activityLevel = 3
        case complete = 4
    }

    // MARK: - Published Properties

    // 현재 단계
    @Published var currentStep: Step = .welcome

    // Step 2: 기본 정보
    @Published var name: String = ""
    @Published var gender: Gender = .male
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()

    // Step 3: 신체 정보
    @Published var height: String = ""     // cm
    @Published var weight: String = ""     // kg

    // Step 4: 활동 수준
    @Published var activityLevel: ActivityLevel = .moderatelyActive

    // 상태
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // 계산된 결과 (Step 5에서 표시)
    @Published var calculatedBMR: Int?
    @Published var calculatedTDEE: Int?

    // MARK: - Private Properties

    private let context: NSManagedObjectContext

    // MARK: - Computed Properties

    /// 현재 단계 진행률 (0.0 ~ 1.0)
    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    /// 다음 버튼 활성화 여부
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .basicInfo:
            return isBasicInfoValid
        case .bodyInfo:
            return isBodyInfoValid
        case .activityLevel:
            return true
        case .complete:
            return true
        }
    }

    /// 나이 계산
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }

    // MARK: - Validation

    /// Step 2 유효성 검증
    var isBasicInfoValid: Bool {
        // 이름: 1자 이상, 20자 이하, 공백만으로 이루어지지 않음
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty && trimmedName.count <= 20 else {
            return false
        }

        // 나이: 10세 이상, 120세 이하
        guard age >= 10 && age <= 120 else {
            return false
        }

        return true
    }

    /// Step 3 유효성 검증
    var isBodyInfoValid: Bool {
        // 키: 100cm ~ 250cm
        guard let heightValue = Double(height),
              heightValue >= 100 && heightValue <= 250 else {
            return false
        }

        // 몸무게: 20kg ~ 300kg
        guard let weightValue = Double(weight),
              weightValue >= 20 && weightValue <= 300 else {
            return false
        }

        return true
    }

    // MARK: - Initialization

    /// OnboardingViewModel 초기화
    /// - Parameter context: Core Data NSManagedObjectContext (기본값: viewContext)
    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - Methods

    /// 다음 단계로 이동
    func goToNext() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextStep
        }
    }

    /// 이전 단계로 이동
    func goToPrevious() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = previousStep
        }
    }

    /// 온보딩 완료 처리 (User 생성 + BMR/TDEE 계산)
    func completeOnboarding() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            // 1. User 생성
            let user = User(context: context)
            user.id = UUID()
            user.name = name.trimmingCharacters(in: .whitespaces)
            user.gender = gender.rawValue
            user.birthDate = birthDate
            user.height = NSDecimalNumber(string: height)
            user.activityLevel = activityLevel.rawValue
            user.currentWeight = NSDecimalNumber(string: weight)
            user.createdAt = Date()
            user.updatedAt = Date()

            // 2. BMR 계산 (Mifflin-St Jeor)
            let weightDecimal = Decimal(string: weight) ?? 0
            let heightDecimal = Decimal(string: height) ?? 0

            let bmr = calculateBMR(
                weight: weightDecimal,
                height: heightDecimal,
                age: age,
                gender: gender
            )

            // 3. TDEE 계산
            let tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel)

            user.currentBMR = NSDecimalNumber(decimal: bmr)
            user.currentTDEE = NSDecimalNumber(decimal: tdee)
            user.metabolismUpdatedAt = Date()

            // 4. 저장
            try context.save()

            // 5. UI 업데이트
            self.calculatedBMR = Int(truncating: NSDecimalNumber(decimal: bmr))
            self.calculatedTDEE = Int(truncating: NSDecimalNumber(decimal: tdee))

            withAnimation(.easeInOut(duration: 0.3)) {
                self.currentStep = .complete
            }
        } catch {
            self.errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 에러 제거
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// BMR 계산 (Mifflin-St Jeor 공식)
    /// 남성: BMR = (10 × weight) + (6.25 × height) - (5 × age) + 5
    /// 여성: BMR = (10 × weight) + (6.25 × height) - (5 × age) - 161
    private func calculateBMR(
        weight: Decimal,
        height: Decimal,
        age: Int,
        gender: Gender
    ) -> Decimal {
        let weightComponent = Decimal(10) * weight
        let heightComponent = Decimal(6.25) * height
        let ageComponent = Decimal(5) * Decimal(age)
        let genderAdjustment = Decimal(gender.bmrAdjustment)

        return weightComponent + heightComponent - ageComponent + genderAdjustment
    }

    /// TDEE 계산
    /// TDEE = BMR × Activity Level Multiplier
    private func calculateTDEE(bmr: Decimal, activityLevel: ActivityLevel) -> Decimal {
        return bmr * Decimal(activityLevel.multiplier)
    }
}

// MARK: - Preview Helpers

extension OnboardingViewModel {
    /// Preview용 완료된 ViewModel
    static var completedPreview: OnboardingViewModel {
        let viewModel = OnboardingViewModel()
        viewModel.name = "테스트"
        viewModel.gender = .male
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        viewModel.height = "175"
        viewModel.weight = "70"
        viewModel.activityLevel = .moderatelyActive
        viewModel.calculatedBMR = 1650
        viewModel.calculatedTDEE = 2558
        viewModel.currentStep = .complete
        return viewModel
    }

    /// Preview용 기본 정보 입력 단계 ViewModel
    static var basicInfoPreview: OnboardingViewModel {
        let viewModel = OnboardingViewModel()
        viewModel.currentStep = .basicInfo
        return viewModel
    }

    /// Preview용 신체 정보 입력 단계 ViewModel
    static var bodyInfoPreview: OnboardingViewModel {
        let viewModel = OnboardingViewModel()
        viewModel.name = "테스트"
        viewModel.currentStep = .bodyInfo
        return viewModel
    }

    /// Preview용 활동 수준 선택 단계 ViewModel
    static var activityLevelPreview: OnboardingViewModel {
        let viewModel = OnboardingViewModel()
        viewModel.name = "테스트"
        viewModel.height = "175"
        viewModel.weight = "70"
        viewModel.currentStep = .activityLevel
        return viewModel
    }
}

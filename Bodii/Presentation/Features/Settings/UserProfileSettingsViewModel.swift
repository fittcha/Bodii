//
//  UserProfileSettingsViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import Foundation
import SwiftUI
import CoreData

// MARK: - UserProfileSettingsViewModel

/// 사용자 프로필 설정 ViewModel
/// BMR/TDEE 계산에 필요한 사용자 기본 정보를 관리합니다.
@MainActor
class UserProfileSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 키 (cm)
    @Published var height: String = ""

    /// 생년월일
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()

    /// 성별
    @Published var gender: Gender = .male

    /// 활동 수준
    @Published var activityLevel: ActivityLevel = .moderatelyActive

    /// 저장 중 상태
    @Published var isSaving: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 성공 메시지
    @Published var successMessage: String?

    /// 데이터 로딩 완료 여부
    @Published var isLoaded: Bool = false

    // MARK: - Private Properties

    private let persistenceController: PersistenceController

    // MARK: - Computed Properties

    /// 키 값 (Decimal)
    var heightDecimal: Decimal? {
        guard let doubleValue = Double(height) else { return nil }
        return Decimal(doubleValue)
    }

    /// 나이 계산
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }

    /// 입력값 유효성 검증
    var isValid: Bool {
        guard let h = heightDecimal else { return false }
        return h >= 100 && h <= 250 && age >= 10 && age <= 120
    }

    /// 저장 버튼 활성화 여부
    var canSave: Bool {
        isValid && !isSaving
    }

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Public Methods

    /// 현재 사용자 정보 로드
    func loadUserProfile() {
        let context = persistenceController.viewContext

        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            if let user = try context.fetch(fetchRequest).first {
                // 기존 사용자 정보 로드
                if let heightValue = user.height?.decimalValue {
                    height = "\(heightValue)"
                }
                if let birthDateValue = user.birthDate {
                    birthDate = birthDateValue
                }
                gender = Gender(rawValue: user.gender) ?? .male
                activityLevel = ActivityLevel(rawValue: user.activityLevel) ?? .moderatelyActive
            }
            isLoaded = true
        } catch {
            errorMessage = "사용자 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }

    /// 사용자 정보 저장
    func saveUserProfile() async {
        guard isValid else {
            errorMessage = "입력값을 확인해주세요."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        let context = persistenceController.newBackgroundContext()

        do {
            try await context.perform {
                let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
                fetchRequest.fetchLimit = 1

                let user: User
                if let existingUser = try context.fetch(fetchRequest).first {
                    user = existingUser
                } else {
                    // 새 사용자 생성
                    user = User(context: context)
                    user.id = UUID()
                    user.name = "User"
                    user.createdAt = Date()
                }

                // 프로필 정보 업데이트
                if let heightValue = self.heightDecimal {
                    user.height = NSDecimalNumber(decimal: heightValue)
                }
                user.birthDate = self.birthDate
                user.gender = self.gender.rawValue
                user.activityLevel = self.activityLevel.rawValue
                user.updatedAt = Date()

                try context.save()
            }

            successMessage = "프로필이 저장되었습니다."

            // 성공 메시지 자동 제거
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }

        } catch {
            errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        }

        isSaving = false
    }

    /// 에러 메시지 제거
    func clearError() {
        errorMessage = nil
    }
}

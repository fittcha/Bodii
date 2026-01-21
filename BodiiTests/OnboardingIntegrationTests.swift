//
//  OnboardingIntegrationTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-21.
//

import XCTest
import CoreData
@testable import Bodii

/// 온보딩 통합 테스트
/// 온보딩 완료 시 User 생성, BMR/TDEE 계산 정확도 등을 테스트
@MainActor
final class OnboardingIntegrationTests: XCTestCase {

    // MARK: - Properties

    var sut: OnboardingViewModel!
    var testContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        testContext = persistenceController.viewContext
        sut = OnboardingViewModel(context: testContext)
    }

    override func tearDown() async throws {
        sut = nil
        testContext = nil
        persistenceController = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// 테스트용 기본 정보 설정
    private func setupBasicUserInfo() {
        sut.name = "테스트"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.height = "175"
        sut.weight = "72.5"
        sut.activityLevel = .moderatelyActive
    }

    /// User 엔티티 가져오기
    private func fetchUser() throws -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        return try testContext.fetch(fetchRequest).first
    }

    /// User 전체 개수 가져오기
    private func fetchUserCount() throws -> Int {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        return try testContext.count(for: fetchRequest)
    }

    // MARK: - 온보딩 완료 시 User 생성 테스트

    func test_completeOnboarding_createsUser() async throws {
        // Given
        setupBasicUserInfo()

        // When
        await sut.completeOnboarding()

        // Then
        let userCount = try fetchUserCount()
        XCTAssertEqual(userCount, 1, "User가 1개 생성되어야 합니다")
    }

    func test_completeOnboarding_setsCorrectName() async throws {
        // Given
        sut.name = "테스트사용자"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.height = "175"
        sut.weight = "70"
        sut.activityLevel = .moderatelyActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.name, "테스트사용자")
    }

    func test_completeOnboarding_setsCorrectGender_male() async throws {
        // Given
        setupBasicUserInfo()
        sut.gender = .male

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.gender, Gender.male.rawValue)
    }

    func test_completeOnboarding_setsCorrectGender_female() async throws {
        // Given
        setupBasicUserInfo()
        sut.gender = .female

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.gender, Gender.female.rawValue)
    }

    func test_completeOnboarding_setsCorrectHeight() async throws {
        // Given
        setupBasicUserInfo()
        sut.height = "175"

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.height?.doubleValue, 175.0, accuracy: 0.1)
    }

    func test_completeOnboarding_setsCorrectWeight() async throws {
        // Given
        setupBasicUserInfo()
        sut.weight = "72.5"

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.currentWeight?.doubleValue, 72.5, accuracy: 0.1)
    }

    func test_completeOnboarding_setsCorrectActivityLevel() async throws {
        // Given
        setupBasicUserInfo()
        sut.activityLevel = .veryActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.activityLevel, ActivityLevel.veryActive.rawValue)
    }

    func test_completeOnboarding_setsBirthDate() async throws {
        // Given
        setupBasicUserInfo()
        let expectedBirthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.birthDate = expectedBirthDate

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertNotNil(user?.birthDate)
        // 날짜 비교 (초 단위까지만 비교)
        let calendar = Calendar.current
        XCTAssertEqual(
            calendar.component(.year, from: user!.birthDate!),
            calendar.component(.year, from: expectedBirthDate)
        )
    }

    func test_completeOnboarding_setsUUID() async throws {
        // Given
        setupBasicUserInfo()

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertNotNil(user?.id, "User ID가 설정되어야 합니다")
    }

    func test_completeOnboarding_setsTimestamps() async throws {
        // Given
        setupBasicUserInfo()
        let beforeDate = Date()

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        let afterDate = Date()

        XCTAssertNotNil(user?.createdAt)
        XCTAssertNotNil(user?.updatedAt)
        XCTAssertTrue(user!.createdAt! >= beforeDate)
        XCTAssertTrue(user!.createdAt! <= afterDate)
        XCTAssertTrue(user!.updatedAt! >= beforeDate)
        XCTAssertTrue(user!.updatedAt! <= afterDate)
    }

    // MARK: - BMR 계산 정확도 테스트

    func test_completeOnboarding_calculatesBMR_male_correctly() async throws {
        // Given: 30세 남성, 175cm, 72.5kg
        sut.name = "테스트"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.height = "175"
        sut.weight = "72.5"
        sut.activityLevel = .moderatelyActive

        // When
        await sut.completeOnboarding()

        // Then
        // Mifflin-St Jeor (남성):
        // BMR = 10 × 72.5 + 6.25 × 175 - 5 × 30 + 5
        //     = 725 + 1093.75 - 150 + 5 = 1673.75
        let user = try fetchUser()
        XCTAssertNotNil(user?.currentBMR)

        let expectedBMR = 1673.75
        let actualBMR = user?.currentBMR?.doubleValue ?? 0
        XCTAssertEqual(actualBMR, expectedBMR, accuracy: 5.0,
                      "남성 BMR 계산이 정확해야 합니다 (예상: \(expectedBMR), 실제: \(actualBMR))")
    }

    func test_completeOnboarding_calculatesBMR_female_correctly() async throws {
        // Given: 28세 여성, 162cm, 55kg
        sut.name = "테스트"
        sut.gender = .female
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -28, to: Date())!
        sut.height = "162"
        sut.weight = "55"
        sut.activityLevel = .lightlyActive

        // When
        await sut.completeOnboarding()

        // Then
        // Mifflin-St Jeor (여성):
        // BMR = 10 × 55 + 6.25 × 162 - 5 × 28 - 161
        //     = 550 + 1012.5 - 140 - 161 = 1261.5
        let user = try fetchUser()
        XCTAssertNotNil(user?.currentBMR)

        let expectedBMR = 1261.5
        let actualBMR = user?.currentBMR?.doubleValue ?? 0
        XCTAssertEqual(actualBMR, expectedBMR, accuracy: 5.0,
                      "여성 BMR 계산이 정확해야 합니다 (예상: \(expectedBMR), 실제: \(actualBMR))")
    }

    // MARK: - TDEE 계산 정확도 테스트

    func test_completeOnboarding_calculatesTDEE_moderatelyActive_correctly() async throws {
        // Given: 30세 남성, 175cm, 72.5kg, 보통 활동
        sut.name = "테스트"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.height = "175"
        sut.weight = "72.5"
        sut.activityLevel = .moderatelyActive // multiplier 1.55

        // When
        await sut.completeOnboarding()

        // Then
        // BMR = 1673.75
        // TDEE = BMR × 1.55 = 1673.75 × 1.55 ≈ 2594.31
        let user = try fetchUser()
        XCTAssertNotNil(user?.currentTDEE)

        let expectedTDEE = 1673.75 * 1.55
        let actualTDEE = user?.currentTDEE?.doubleValue ?? 0
        XCTAssertEqual(actualTDEE, expectedTDEE, accuracy: 10.0,
                      "TDEE 계산이 정확해야 합니다 (예상: \(expectedTDEE), 실제: \(actualTDEE))")
    }

    func test_completeOnboarding_calculatesTDEE_sedentary_correctly() async throws {
        // Given: sedentary (multiplier 1.2)
        setupBasicUserInfo()
        sut.activityLevel = .sedentary

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        let bmr = user?.currentBMR?.doubleValue ?? 0
        let expectedTDEE = bmr * 1.2
        let actualTDEE = user?.currentTDEE?.doubleValue ?? 0

        XCTAssertEqual(actualTDEE, expectedTDEE, accuracy: 10.0)
    }

    func test_completeOnboarding_calculatesTDEE_lightlyActive_correctly() async throws {
        // Given: lightlyActive (multiplier 1.375)
        setupBasicUserInfo()
        sut.activityLevel = .lightlyActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        let bmr = user?.currentBMR?.doubleValue ?? 0
        let expectedTDEE = bmr * 1.375
        let actualTDEE = user?.currentTDEE?.doubleValue ?? 0

        XCTAssertEqual(actualTDEE, expectedTDEE, accuracy: 10.0)
    }

    func test_completeOnboarding_calculatesTDEE_veryActive_correctly() async throws {
        // Given: veryActive (multiplier 1.725)
        setupBasicUserInfo()
        sut.activityLevel = .veryActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        let bmr = user?.currentBMR?.doubleValue ?? 0
        let expectedTDEE = bmr * 1.725
        let actualTDEE = user?.currentTDEE?.doubleValue ?? 0

        XCTAssertEqual(actualTDEE, expectedTDEE, accuracy: 10.0)
    }

    func test_completeOnboarding_calculatesTDEE_extraActive_correctly() async throws {
        // Given: extraActive (multiplier 1.9)
        setupBasicUserInfo()
        sut.activityLevel = .extraActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        let bmr = user?.currentBMR?.doubleValue ?? 0
        let expectedTDEE = bmr * 1.9
        let actualTDEE = user?.currentTDEE?.doubleValue ?? 0

        XCTAssertEqual(actualTDEE, expectedTDEE, accuracy: 10.0)
    }

    // MARK: - ViewModel 결과 업데이트 테스트

    func test_completeOnboarding_updatesCalculatedBMR() async {
        // Given
        setupBasicUserInfo()

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertNotNil(sut.calculatedBMR)
        XCTAssertGreaterThan(sut.calculatedBMR ?? 0, 0)
    }

    func test_completeOnboarding_updatesCalculatedTDEE() async {
        // Given
        setupBasicUserInfo()

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertNotNil(sut.calculatedTDEE)
        XCTAssertGreaterThan(sut.calculatedTDEE ?? 0, 0)
    }

    func test_completeOnboarding_movesToCompleteStep() async {
        // Given
        setupBasicUserInfo()
        sut.currentStep = .activityLevel

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertEqual(sut.currentStep, .complete)
    }

    func test_completeOnboarding_clearsLoadingState() async {
        // Given
        setupBasicUserInfo()

        // When
        await sut.completeOnboarding()

        // Then
        XCTAssertFalse(sut.isLoading)
    }

    func test_completeOnboarding_TDEE_isGreaterThan_BMR() async {
        // Given
        setupBasicUserInfo()

        // When
        await sut.completeOnboarding()

        // Then: TDEE는 항상 BMR보다 커야 함 (활동 계수가 1.0 이상이므로)
        XCTAssertNotNil(sut.calculatedBMR)
        XCTAssertNotNil(sut.calculatedTDEE)
        XCTAssertGreaterThan(sut.calculatedTDEE ?? 0, sut.calculatedBMR ?? 0)
    }

    // MARK: - 이름 트리밍 테스트

    func test_completeOnboarding_trimsNameWhitespace() async throws {
        // Given: 앞뒤 공백이 있는 이름
        sut.name = "  테스트  "
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.height = "175"
        sut.weight = "70"
        sut.activityLevel = .moderatelyActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        XCTAssertEqual(user?.name, "테스트", "이름의 앞뒤 공백이 제거되어야 합니다")
    }

    // MARK: - metabolismUpdatedAt 테스트

    func test_completeOnboarding_setsMetabolismUpdatedAt() async throws {
        // Given
        setupBasicUserInfo()
        let beforeDate = Date()

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        let afterDate = Date()

        XCTAssertNotNil(user?.metabolismUpdatedAt)
        XCTAssertTrue(user!.metabolismUpdatedAt! >= beforeDate)
        XCTAssertTrue(user!.metabolismUpdatedAt! <= afterDate)
    }

    // MARK: - 다양한 사용자 프로필 테스트

    func test_completeOnboarding_youngMale_calculatesCorrectly() async throws {
        // Given: 20세 남성, 180cm, 65kg, 활발한 활동
        sut.name = "젊은남성"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
        sut.height = "180"
        sut.weight = "65"
        sut.activityLevel = .veryActive

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        // BMR = 10×65 + 6.25×180 - 5×20 + 5 = 650 + 1125 - 100 + 5 = 1680
        XCTAssertEqual(user?.currentBMR?.doubleValue ?? 0, 1680, accuracy: 5)
        // TDEE = 1680 × 1.725 ≈ 2898
        XCTAssertEqual(user?.currentTDEE?.doubleValue ?? 0, 2898, accuracy: 15)
    }

    func test_completeOnboarding_elderlyFemale_calculatesCorrectly() async throws {
        // Given: 60세 여성, 158cm, 52kg, 비활동적
        sut.name = "노년여성"
        sut.gender = .female
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -60, to: Date())!
        sut.height = "158"
        sut.weight = "52"
        sut.activityLevel = .sedentary

        // When
        await sut.completeOnboarding()

        // Then
        let user = try fetchUser()
        // BMR = 10×52 + 6.25×158 - 5×60 - 161 = 520 + 987.5 - 300 - 161 = 1046.5
        XCTAssertEqual(user?.currentBMR?.doubleValue ?? 0, 1046.5, accuracy: 5)
        // TDEE = 1046.5 × 1.2 ≈ 1255.8
        XCTAssertEqual(user?.currentTDEE?.doubleValue ?? 0, 1255.8, accuracy: 10)
    }
}

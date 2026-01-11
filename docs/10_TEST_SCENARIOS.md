# Bodii - 테스트 시나리오

## 1. 테스트 전략 개요

### 1.1 테스트 피라미드

```
              ┌─────────┐
              │   E2E   │  10% (주요 플로우)
              ├─────────┤
           ┌──┴─────────┴──┐
           │  Integration  │  20% (서비스 연동)
           ├───────────────┤
      ┌────┴───────────────┴────┐
      │         Unit            │  70% (비즈니스 로직)
      └─────────────────────────┘
```

### 1.2 테스트 범위

| 레이어 | 테스트 대상 | 도구 |
|--------|------------|------|
| **Unit** | Service, Utils, 계산 로직 | XCTest |
| **Integration** | Core Data, API 연동 | XCTest + Mock |
| **UI** | 화면 플로우, 사용자 인터랙션 | XCUITest |
| **Snapshot** | UI 컴포넌트 렌더링 | swift-snapshot-testing |

---

## 2. Unit 테스트

### 2.1 MetabolismService 테스트

```swift
class MetabolismServiceTests: XCTestCase {
    
    var sut: MetabolismService!
    
    override func setUp() {
        sut = MetabolismService()
    }
    
    // MARK: - BMR 계산 (Katch-McArdle)
    
    func test_calculateBMR_withBodyFat_usesKatchMcArdle() {
        // Given
        let weight: Decimal = 72.5
        let bodyFatPct: Decimal = 18.0
        
        // When
        let bmr = sut.calculateBMR(weight: weight, bodyFatPct: bodyFatPct)
        
        // Then
        // LBM = 72.5 × (1 - 0.18) = 59.45
        // BMR = 370 + (21.6 × 59.45) = 1654.12
        XCTAssertEqual(bmr, 1654, accuracy: 1)
    }
    
    func test_calculateBMR_withoutBodyFat_usesMifflinStJeor_male() {
        // Given
        let weight: Decimal = 72.5
        let height: Decimal = 175
        let age = 30
        let gender: Gender = .male
        
        // When
        let bmr = sut.calculateBMR(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            bodyFatPct: nil
        )
        
        // Then
        // BMR = 10 × 72.5 + 6.25 × 175 - 5 × 30 + 5 = 1669
        XCTAssertEqual(bmr, 1669, accuracy: 1)
    }
    
    func test_calculateBMR_withoutBodyFat_usesMifflinStJeor_female() {
        // Given
        let weight: Decimal = 55
        let height: Decimal = 162
        let age = 28
        let gender: Gender = .female
        
        // When
        let bmr = sut.calculateBMR(
            weight: weight,
            height: height,
            age: age,
            gender: gender,
            bodyFatPct: nil
        )
        
        // Then
        // BMR = 10 × 55 + 6.25 × 162 - 5 × 28 - 161 = 1290.5
        XCTAssertEqual(bmr, 1291, accuracy: 1)
    }
    
    // MARK: - TDEE 계산
    
    func test_calculateTDEE_sedentary() {
        // Given
        let bmr: Decimal = 1650
        let activityLevel: ActivityLevel = .sedentary // 1.2
        
        // When
        let tdee = sut.calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        
        // Then
        XCTAssertEqual(tdee, 1980, accuracy: 1)
    }
    
    func test_calculateTDEE_veryActive() {
        // Given
        let bmr: Decimal = 1650
        let activityLevel: ActivityLevel = .veryActive // 1.9
        
        // When
        let tdee = sut.calculateTDEE(bmr: bmr, activityLevel: activityLevel)
        
        // Then
        XCTAssertEqual(tdee, 3135, accuracy: 1)
    }
}
```

### 2.2 ExerciseCalcService 테스트

```swift
class ExerciseCalcServiceTests: XCTestCase {
    
    var sut: ExerciseCalcService!
    
    override func setUp() {
        sut = ExerciseCalcService()
    }
    
    // MARK: - MET 기반 칼로리 계산
    
    func test_calculateCalories_running_medium() {
        // Given
        let exerciseType: ExerciseType = .running
        let intensity: Intensity = .medium // MET 8.0
        let duration: Int = 30 // 분
        let weight: Decimal = 72.5
        
        // When
        let calories = sut.calculateCalories(
            type: exerciseType,
            intensity: intensity,
            duration: duration,
            weight: weight
        )
        
        // Then
        // 칼로리 = MET × 체중(kg) × 시간(h)
        // = 8.0 × 72.5 × 0.5 = 290
        XCTAssertEqual(calories, 290, accuracy: 5)
    }
    
    func test_calculateCalories_crossfit_high() {
        // Given
        let exerciseType: ExerciseType = .crossfit
        let intensity: Intensity = .high // MET 10.0
        let duration: Int = 45
        let weight: Decimal = 72.5
        
        // When
        let calories = sut.calculateCalories(
            type: exerciseType,
            intensity: intensity,
            duration: duration,
            weight: weight
        )
        
        // Then
        // = 10.0 × 72.5 × 0.75 = 543.75
        XCTAssertEqual(calories, 544, accuracy: 5)
    }
    
    func test_calculateCalories_zeroWeight_returnsZero() {
        // Given
        let weight: Decimal = 0
        
        // When
        let calories = sut.calculateCalories(
            type: .running,
            intensity: .medium,
            duration: 30,
            weight: weight
        )
        
        // Then
        XCTAssertEqual(calories, 0)
    }
    
    func test_calculateCalories_zeroDuration_returnsZero() {
        // Given
        let duration = 0
        
        // When
        let calories = sut.calculateCalories(
            type: .running,
            intensity: .medium,
            duration: duration,
            weight: 72.5
        )
        
        // Then
        XCTAssertEqual(calories, 0)
    }
}
```

### 2.3 SleepCalcService 테스트

```swift
class SleepCalcServiceTests: XCTestCase {
    
    var sut: SleepCalcService!
    
    override func setUp() {
        sut = SleepCalcService()
    }
    
    // MARK: - 수면 상태 계산
    
    func test_calculateStatus_lessThan330_returnsBad() {
        // Given
        let duration = 320 // 5시간 20분
        
        // When
        let status = sut.calculateStatus(durationMinutes: duration)
        
        // Then
        XCTAssertEqual(status, .bad)
    }
    
    func test_calculateStatus_330to390_returnsSoso() {
        // Given
        let duration = 360 // 6시간
        
        // When
        let status = sut.calculateStatus(durationMinutes: duration)
        
        // Then
        XCTAssertEqual(status, .soso)
    }
    
    func test_calculateStatus_390to450_returnsGood() {
        // Given
        let duration = 420 // 7시간
        
        // When
        let status = sut.calculateStatus(durationMinutes: duration)
        
        // Then
        XCTAssertEqual(status, .good)
    }
    
    func test_calculateStatus_450to540_returnsExcellent() {
        // Given
        let duration = 480 // 8시간
        
        // When
        let status = sut.calculateStatus(durationMinutes: duration)
        
        // Then
        XCTAssertEqual(status, .excellent)
    }
    
    func test_calculateStatus_over540_returnsOversleep() {
        // Given
        let duration = 600 // 10시간
        
        // When
        let status = sut.calculateStatus(durationMinutes: duration)
        
        // Then
        XCTAssertEqual(status, .oversleep)
    }
    
    func test_calculateStatus_zero_returnsBad() {
        // Given (밤샘)
        let duration = 0
        
        // When
        let status = sut.calculateStatus(durationMinutes: duration)
        
        // Then
        XCTAssertEqual(status, .bad)
    }
    
    // MARK: - 경계값 테스트
    
    func test_calculateStatus_exactly330_returnsSoso() {
        XCTAssertEqual(sut.calculateStatus(durationMinutes: 330), .soso)
    }
    
    func test_calculateStatus_exactly390_returnsGood() {
        XCTAssertEqual(sut.calculateStatus(durationMinutes: 390), .good)
    }
    
    func test_calculateStatus_exactly450_returnsExcellent() {
        XCTAssertEqual(sut.calculateStatus(durationMinutes: 450), .excellent)
    }
    
    func test_calculateStatus_exactly540_returnsExcellent() {
        XCTAssertEqual(sut.calculateStatus(durationMinutes: 540), .excellent)
    }
    
    func test_calculateStatus_541_returnsOversleep() {
        XCTAssertEqual(sut.calculateStatus(durationMinutes: 541), .oversleep)
    }
}
```

### 2.4 DateUtils 테스트

```swift
class DateUtilsTests: XCTestCase {
    
    var sut: DateUtils!
    var calendar: Calendar!
    
    override func setUp() {
        sut = DateUtils()
        calendar = Calendar.current
    }
    
    // MARK: - 수면 날짜 계산 (02:00 기준)
    
    func test_getSleepDate_at0100_returnsPreviousDay() {
        // Given: 2026-01-11 01:00
        let date = createDate(year: 2026, month: 1, day: 11, hour: 1, minute: 0)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2026-01-10
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 10)
    }
    
    func test_getSleepDate_at0159_returnsPreviousDay() {
        // Given: 2026-01-11 01:59
        let date = createDate(year: 2026, month: 1, day: 11, hour: 1, minute: 59)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2026-01-10
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 10)
    }
    
    func test_getSleepDate_at0200_returnsCurrentDay() {
        // Given: 2026-01-11 02:00
        let date = createDate(year: 2026, month: 1, day: 11, hour: 2, minute: 0)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2026-01-11
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 11)
    }
    
    func test_getSleepDate_at1400_returnsCurrentDay() {
        // Given: 2026-01-11 14:00
        let date = createDate(year: 2026, month: 1, day: 11, hour: 14, minute: 0)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2026-01-11
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 11)
    }
    
    func test_getSleepDate_at0000_returnsPreviousDay() {
        // Given: 2026-01-11 00:00 (자정)
        let date = createDate(year: 2026, month: 1, day: 11, hour: 0, minute: 0)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2026-01-10
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 10)
    }
    
    // MARK: - 월/년 경계 테스트
    
    func test_getSleepDate_at0100_onFirstOfMonth_returnsPreviousMonth() {
        // Given: 2026-02-01 01:00
        let date = createDate(year: 2026, month: 2, day: 1, hour: 1, minute: 0)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2026-01-31
        XCTAssertEqual(calendar.component(.month, from: sleepDate), 1)
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 31)
    }
    
    func test_getSleepDate_at0100_onFirstOfYear_returnsPreviousYear() {
        // Given: 2026-01-01 01:00
        let date = createDate(year: 2026, month: 1, day: 1, hour: 1, minute: 0)
        
        // When
        let sleepDate = sut.getSleepDate(for: date)
        
        // Then: 2025-12-31
        XCTAssertEqual(calendar.component(.year, from: sleepDate), 2025)
        XCTAssertEqual(calendar.component(.month, from: sleepDate), 12)
        XCTAssertEqual(calendar.component(.day, from: sleepDate), 31)
    }
    
    // MARK: - Helper
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
```

### 2.5 ValidationService 테스트

```swift
class ValidationServiceTests: XCTestCase {
    
    var sut: ValidationService!
    
    override func setUp() {
        sut = ValidationService()
    }
    
    // MARK: - 체성분 검증
    
    func test_validateWeight_valid() {
        XCTAssertTrue(sut.validateWeight(72.5).isValid)
        XCTAssertTrue(sut.validateWeight(20).isValid)
        XCTAssertTrue(sut.validateWeight(300).isValid)
    }
    
    func test_validateWeight_invalid() {
        XCTAssertFalse(sut.validateWeight(19.9).isValid)
        XCTAssertFalse(sut.validateWeight(300.1).isValid)
        XCTAssertFalse(sut.validateWeight(0).isValid)
        XCTAssertFalse(sut.validateWeight(-50).isValid)
    }
    
    func test_validateHeight_valid() {
        XCTAssertTrue(sut.validateHeight(175).isValid)
        XCTAssertTrue(sut.validateHeight(100).isValid)
        XCTAssertTrue(sut.validateHeight(250).isValid)
    }
    
    func test_validateHeight_invalid() {
        XCTAssertFalse(sut.validateHeight(99).isValid)
        XCTAssertFalse(sut.validateHeight(251).isValid)
    }
    
    func test_validateBodyFatPct_valid() {
        XCTAssertTrue(sut.validateBodyFatPct(18.5).isValid)
        XCTAssertTrue(sut.validateBodyFatPct(1).isValid)
        XCTAssertTrue(sut.validateBodyFatPct(60).isValid)
    }
    
    func test_validateBodyFatPct_invalid() {
        XCTAssertFalse(sut.validateBodyFatPct(0.5).isValid)
        XCTAssertFalse(sut.validateBodyFatPct(60.1).isValid)
    }
    
    // MARK: - 운동 검증
    
    func test_validateExerciseDuration_valid() {
        XCTAssertTrue(sut.validateExerciseDuration(30).isValid)
        XCTAssertTrue(sut.validateExerciseDuration(1).isValid)
    }
    
    func test_validateExerciseDuration_invalid() {
        XCTAssertFalse(sut.validateExerciseDuration(0).isValid)
        XCTAssertFalse(sut.validateExerciseDuration(-10).isValid)
    }
    
    // MARK: - 음식 검증
    
    func test_validateFoodQuantity_valid() {
        XCTAssertTrue(sut.validateFoodQuantity(1.0).isValid)
        XCTAssertTrue(sut.validateFoodQuantity(0.1).isValid)
    }
    
    func test_validateFoodQuantity_invalid() {
        XCTAssertFalse(sut.validateFoodQuantity(0).isValid)
        XCTAssertFalse(sut.validateFoodQuantity(-0.5).isValid)
    }
}
```

### 2.6 DailyLog 계산 테스트

```swift
class DailyLogCalculationTests: XCTestCase {
    
    // MARK: - 매크로 비율 계산
    
    func test_calculateMacroRatios_normal() {
        // Given
        let carbs: Decimal = 200
        let protein: Decimal = 100
        let fat: Decimal = 50
        
        // When
        let ratios = DailyLogService.calculateMacroRatios(
            carbs: carbs, protein: protein, fat: fat
        )
        
        // Then
        // 총 = 350, 탄 = 57.1%, 단 = 28.6%, 지 = 14.3%
        XCTAssertEqual(ratios.carbsRatio, 57, accuracy: 1)
        XCTAssertEqual(ratios.proteinRatio, 29, accuracy: 1)
        XCTAssertEqual(ratios.fatRatio, 14, accuracy: 1)
    }
    
    func test_calculateMacroRatios_allZero_returnsNil() {
        // Given
        let carbs: Decimal = 0
        let protein: Decimal = 0
        let fat: Decimal = 0
        
        // When
        let ratios = DailyLogService.calculateMacroRatios(
            carbs: carbs, protein: protein, fat: fat
        )
        
        // Then
        XCTAssertNil(ratios.carbsRatio)
        XCTAssertNil(ratios.proteinRatio)
        XCTAssertNil(ratios.fatRatio)
    }
    
    // MARK: - 순 칼로리 계산
    
    func test_calculateNetCalories_deficit() {
        // Given
        let caloriesIn: Int32 = 1500
        let tdee: Int32 = 2100
        
        // When
        let net = DailyLogService.calculateNetCalories(
            caloriesIn: caloriesIn, tdee: tdee
        )
        
        // Then
        XCTAssertEqual(net, -600) // 적자
    }
    
    func test_calculateNetCalories_surplus() {
        // Given
        let caloriesIn: Int32 = 2500
        let tdee: Int32 = 2100
        
        // When
        let net = DailyLogService.calculateNetCalories(
            caloriesIn: caloriesIn, tdee: tdee
        )
        
        // Then
        XCTAssertEqual(net, 400) // 흑자
    }
}
```

---

## 3. Integration 테스트

### 3.1 Core Data 서비스 테스트

```swift
class BodyRecordServiceIntegrationTests: XCTestCase {
    
    var sut: BodyRecordService!
    var coreDataStack: TestCoreDataStack!
    var metabolismService: MetabolismService!
    var dailyLogService: DailyLogService!
    
    override func setUp() {
        coreDataStack = TestCoreDataStack()
        metabolismService = MetabolismService()
        dailyLogService = DailyLogService(context: coreDataStack.context)
        sut = BodyRecordService(
            context: coreDataStack.context,
            metabolismService: metabolismService,
            dailyLogService: dailyLogService
        )
        
        // 테스트 User 생성
        createTestUser()
    }
    
    override func tearDown() {
        coreDataStack = nil
    }
    
    // MARK: - 체성분 저장 연쇄 업데이트 테스트
    
    func test_saveBodyRecord_updatesUserCurrentValues() throws {
        // Given
        let record = BodyRecord(
            weight: 72.5,
            bodyFatPercent: 18.0,
            muscleMass: 32.0,
            date: Date()
        )
        
        // When
        try sut.save(record)
        
        // Then
        let user = fetchUser()
        XCTAssertEqual(user.currentWeight, 72.5)
        XCTAssertEqual(user.currentBodyFatPct, 18.0)
        XCTAssertEqual(user.currentMuscleMass, 32.0)
        XCTAssertNotNil(user.currentBMR)
        XCTAssertNotNil(user.currentTDEE)
    }
    
    func test_saveBodyRecord_createsMetabolismSnapshot() throws {
        // Given
        let record = BodyRecord(weight: 72.5, bodyFatPercent: 18.0, date: Date())
        
        // When
        try sut.save(record)
        
        // Then
        let snapshots = fetchMetabolismSnapshots()
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.weight, 72.5)
        XCTAssertEqual(snapshots.first?.bodyFatPct, 18.0)
    }
    
    func test_saveBodyRecord_updatesDailyLog_whenToday() throws {
        // Given
        let today = Date()
        let record = BodyRecord(weight: 72.5, bodyFatPercent: 18.0, date: today)
        
        // 먼저 DailyLog 생성
        _ = dailyLogService.getOrCreate(for: today)
        
        // When
        try sut.save(record)
        
        // Then
        let dailyLog = dailyLogService.get(for: today)
        XCTAssertEqual(dailyLog?.weight, 72.5)
        XCTAssertEqual(dailyLog?.bodyFatPct, 18.0)
    }
    
    func test_deleteBodyRecord_updatesUserToLatest() throws {
        // Given: 2개 체성분 기록
        let oldRecord = BodyRecord(weight: 75.0, date: Date().addingDays(-7))
        let newRecord = BodyRecord(weight: 72.5, date: Date())
        
        try sut.save(oldRecord)
        try sut.save(newRecord)
        
        // When: 최신 기록 삭제
        try sut.delete(newRecord)
        
        // Then: 이전 기록으로 User 업데이트
        let user = fetchUser()
        XCTAssertEqual(user.currentWeight, 75.0)
    }
}
```

### 3.2 FoodRecord 서비스 테스트

```swift
class FoodRecordServiceIntegrationTests: XCTestCase {
    
    var sut: FoodRecordService!
    var dailyLogService: DailyLogService!
    var coreDataStack: TestCoreDataStack!
    
    override func setUp() {
        coreDataStack = TestCoreDataStack()
        dailyLogService = DailyLogService(context: coreDataStack.context)
        sut = FoodRecordService(
            context: coreDataStack.context,
            dailyLogService: dailyLogService
        )
        
        createTestUser()
    }
    
    // MARK: - 음식 추가 연쇄 업데이트
    
    func test_addFoodRecord_updatesDailyLogTotals() throws {
        // Given
        let today = Date()
        let food = createTestFood(calories: 300, carbs: 40, protein: 20, fat: 10)
        let record = FoodRecord(
            food: food,
            date: today,
            mealType: .lunch,
            quantity: 1.0
        )
        
        // When
        try sut.add(record)
        
        // Then
        let dailyLog = dailyLogService.get(for: today)!
        XCTAssertEqual(dailyLog.totalCaloriesIn, 300)
        XCTAssertEqual(dailyLog.totalCarbs, 40)
        XCTAssertEqual(dailyLog.totalProtein, 20)
        XCTAssertEqual(dailyLog.totalFat, 10)
    }
    
    func test_addMultipleFoodRecords_accumulates() throws {
        // Given
        let today = Date()
        let food1 = createTestFood(calories: 300, carbs: 40, protein: 20, fat: 10)
        let food2 = createTestFood(calories: 500, carbs: 60, protein: 30, fat: 15)
        
        // When
        try sut.add(FoodRecord(food: food1, date: today, mealType: .lunch, quantity: 1.0))
        try sut.add(FoodRecord(food: food2, date: today, mealType: .dinner, quantity: 1.0))
        
        // Then
        let dailyLog = dailyLogService.get(for: today)!
        XCTAssertEqual(dailyLog.totalCaloriesIn, 800)
        XCTAssertEqual(dailyLog.totalCarbs, 100)
    }
    
    func test_deleteFoodRecord_decreasesDailyLog() throws {
        // Given
        let today = Date()
        let food = createTestFood(calories: 300, carbs: 40, protein: 20, fat: 10)
        let record = FoodRecord(food: food, date: today, mealType: .lunch, quantity: 1.0)
        
        try sut.add(record)
        XCTAssertEqual(dailyLogService.get(for: today)!.totalCaloriesIn, 300)
        
        // When
        try sut.delete(record)
        
        // Then
        let dailyLog = dailyLogService.get(for: today)!
        XCTAssertEqual(dailyLog.totalCaloriesIn, 0)
    }
    
    func test_addFoodRecord_updatesMacroRatios() throws {
        // Given
        let today = Date()
        let food = createTestFood(calories: 300, carbs: 60, protein: 30, fat: 10)
        
        // When
        try sut.add(FoodRecord(food: food, date: today, mealType: .lunch, quantity: 1.0))
        
        // Then
        let dailyLog = dailyLogService.get(for: today)!
        // 탄:단:지 = 60:30:10 = 60%:30%:10%
        XCTAssertEqual(dailyLog.carbsRatio!, 60, accuracy: 1)
        XCTAssertEqual(dailyLog.proteinRatio!, 30, accuracy: 1)
        XCTAssertEqual(dailyLog.fatRatio!, 10, accuracy: 1)
    }
}
```

---

## 4. UI 테스트 (E2E)

### 4.1 온보딩 플로우

```swift
class OnboardingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }
    
    func test_completeOnboarding_navigatesToHome() {
        // 온보딩 1: 앱 소개
        XCTAssertTrue(app.staticTexts["Bodii에 오신 것을 환영합니다"].exists)
        app.buttons["다음"].tap()
        
        // 온보딩 2: 기본 정보
        app.textFields["이름"].tap()
        app.textFields["이름"].typeText("테스트")
        app.buttons["남성"].tap()
        // DatePicker 조작...
        app.buttons["다음"].tap()
        
        // 온보딩 3: 체성분
        app.textFields["키 (cm)"].tap()
        app.textFields["키 (cm)"].typeText("175")
        app.textFields["몸무게 (kg)"].tap()
        app.textFields["몸무게 (kg)"].typeText("72.5")
        app.buttons["다음"].tap()
        
        // 온보딩 4: 활동 수준
        app.buttons["보통 활동"].tap()
        app.buttons["다음"].tap()
        
        // 온보딩 5: HealthKit (스킵)
        app.buttons["나중에"].tap()
        
        // 홈 화면 확인
        XCTAssertTrue(app.tabBars.buttons["홈"].exists)
        XCTAssertTrue(app.staticTexts["오늘의 칼로리"].exists)
    }
    
    func test_onboardingValidation_showsError() {
        app.buttons["다음"].tap() // 기본 정보로 이동
        
        // 이름 없이 다음 클릭
        app.buttons["다음"].tap()
        
        // 에러 메시지 확인
        XCTAssertTrue(app.staticTexts["이름을 입력해주세요"].exists)
    }
}
```

### 4.2 체성분 입력 플로우

```swift
class BodyRecordUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
        app.launch()
    }
    
    func test_addBodyRecord_updatesUI() {
        // 홈에서 체성분 카드 탭
        app.buttons["체성분 기록하기"].tap()
        
        // 체성분 입력
        app.textFields["몸무게 (kg)"].tap()
        app.textFields["몸무게 (kg)"].clearAndTypeText("72.0")
        
        app.textFields["체지방률 (%)"].tap()
        app.textFields["체지방률 (%))"].clearAndTypeText("17.5")
        
        // 저장
        app.buttons["저장"].tap()
        
        // 홈으로 돌아와 업데이트 확인
        XCTAssertTrue(app.staticTexts["72.0kg"].exists)
        XCTAssertTrue(app.staticTexts["17.5%"].exists)
    }
    
    func test_invalidBodyRecord_showsError() {
        app.buttons["체성분 기록하기"].tap()
        
        app.textFields["몸무게 (kg)"].tap()
        app.textFields["몸무게 (kg)"].typeText("500") // 범위 초과
        
        app.buttons["저장"].tap()
        
        XCTAssertTrue(app.staticTexts["몸무게는 20~300kg 사이로 입력해주세요"].exists)
    }
}
```

### 4.3 식단 입력 플로우

```swift
class FoodRecordUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
        app.launch()
    }
    
    func test_searchAndAddFood_updatesDashboard() {
        // 식단 탭으로 이동
        app.tabBars.buttons["식단"].tap()
        
        // 점심에 음식 추가
        app.buttons["점심 음식 추가"].tap()
        
        // 검색
        app.searchFields["음식 검색..."].tap()
        app.searchFields["음식 검색..."].typeText("김치찌개")
        
        // 결과에서 선택
        app.cells["김치찌개 (돼지고기)"].tap()
        
        // 섭취량 입력 및 추가
        app.buttons["추가하기"].tap()
        
        // 식단 화면에서 확인
        XCTAssertTrue(app.staticTexts["김치찌개"].exists)
        
        // 홈 대시보드 확인
        app.tabBars.buttons["홈"].tap()
        XCTAssertTrue(app.staticTexts["180"].exists) // 칼로리
    }
    
    func test_deleteFood_updatesDashboard() {
        // ... 음식 추가 후
        
        // 스와이프 삭제
        app.cells["김치찌개"].swipeLeft()
        app.buttons["삭제"].tap()
        
        // 삭제 확인
        XCTAssertFalse(app.staticTexts["김치찌개"].exists)
        
        // 대시보드 업데이트 확인
        app.tabBars.buttons["홈"].tap()
        XCTAssertTrue(app.staticTexts["0 kcal"].exists)
    }
}
```

---

## 5. 성능 테스트

### 5.1 대시보드 로딩

```swift
class PerformanceTests: XCTestCase {
    
    func test_dashboardLoading_under500ms() {
        measure(metrics: [XCTClockMetric()]) {
            // Given
            let viewModel = DashboardViewModel()
            
            // When
            viewModel.loadDashboard()
            
            // Then: 500ms 이내 로딩
        }
    }
    
    func test_bodyRecordGraph_with1000Records() {
        measure {
            // Given: 1000개 체성분 데이터
            let records = (1...1000).map { i in
                MetabolismSnapshot(
                    date: Date().addingDays(-i),
                    weight: Decimal(70 + (Double(i) * 0.01)),
                    bmr: 1650,
                    tdee: 2100
                )
            }
            
            // When: 그래프 데이터 변환
            let chartData = ChartDataConverter.convert(records)
            
            // Then: 빠른 변환
            XCTAssertEqual(chartData.count, 1000)
        }
    }
}
```

---

## 6. 테스트 커버리지 목표

| 레이어 | 목표 커버리지 | 우선순위 |
|--------|--------------|----------|
| MetabolismService | 100% | Critical |
| ExerciseCalcService | 100% | Critical |
| SleepCalcService | 100% | Critical |
| DateUtils | 100% | Critical |
| ValidationService | 90% | High |
| DailyLogService | 80% | High |
| BodyRecordService | 80% | High |
| FoodRecordService | 80% | High |
| ViewModel | 70% | Medium |
| UI Components | 50% | Low |

---

## 7. 테스트 실행 체크리스트

### Phase 1 출시 전 필수

- [ ] 모든 Unit 테스트 통과
- [ ] BMR/TDEE 계산 정확도 검증
- [ ] 수면 02:00 경계 테스트
- [ ] DailyLog 증분/감소 테스트
- [ ] 온보딩 E2E 테스트
- [ ] 체성분 입력 E2E 테스트
- [ ] 식단 입력 E2E 테스트
- [ ] 대시보드 로딩 500ms 이내

### CI/CD 자동화

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          xcodebuild test \
            -scheme Bodii \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -resultBundlePath TestResults.xcresult
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

---

*문서 버전: 1.0*
*작성일: 2026-01-11*

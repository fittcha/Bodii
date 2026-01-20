# Bodii - 온보딩 상세 개발 명세서

> 작성일: 2026-01-20
> 우선순위: Critical
> 예상 개발 시간: 8~12시간

---

## 1. 개요

### 1.1 목적
앱 첫 실행 시 사용자의 기본 정보를 수집하여 BMR/TDEE 계산의 기반 데이터를 확보합니다.

### 1.2 온보딩 플로우

```
앱 첫 실행
    ↓
┌─────────────────┐
│  앱 소개 화면    │ Step 1: Welcome
│  (1~2 페이지)    │
└────────┬────────┘
         ↓
┌─────────────────┐
│  기본 정보 입력  │ Step 2: BasicInfo
│  이름/성별/생년월일│
└────────┬────────┘
         ↓
┌─────────────────┐
│  신체 정보 입력  │ Step 3: BodyInfo
│  키/몸무게       │
└────────┬────────┘
         ↓
┌─────────────────┐
│  활동 수준 선택  │ Step 4: ActivityLevel
│  5단계 중 선택   │
└────────┬────────┘
         ↓
┌─────────────────┐
│  완료 화면      │ Step 5: Complete
│  BMR/TDEE 표시  │
└────────┬────────┘
         ↓
    메인 화면 진입
```

---

## 2. 파일 구조

```
Bodii/Presentation/Features/Onboarding/
├── ViewModels/
│   └── OnboardingViewModel.swift       # 온보딩 상태 관리
├── Views/
│   ├── OnboardingContainerView.swift   # 전체 컨테이너 (PageView)
│   ├── WelcomeView.swift               # Step 1: 앱 소개
│   ├── BasicInfoInputView.swift        # Step 2: 기본 정보
│   ├── BodyInfoInputView.swift         # Step 3: 신체 정보
│   ├── ActivityLevelSelectView.swift   # Step 4: 활동 수준
│   └── OnboardingCompleteView.swift    # Step 5: 완료
└── Components/
    ├── OnboardingProgressBar.swift     # 진행 상태 표시
    ├── OnboardingButton.swift          # 공통 버튼 스타일
    └── ActivityLevelCard.swift         # 활동 수준 카드

Bodii/App/
└── AppStateService.swift               # 온보딩 완료 플래그 관리
```

---

## 3. 상세 개발 항목

### 3.1 AppStateService (앱 상태 관리)

**파일**: `Bodii/App/AppStateService.swift`

```swift
/// 앱 전역 상태 관리 서비스
/// UserDefaults 기반 상태 저장
final class AppStateService: ObservableObject {

    // MARK: - Keys
    private enum Keys {
        static let isOnboardingComplete = "isOnboardingComplete"
        static let isFirstLaunch = "isFirstLaunch"
    }

    // MARK: - Published Properties
    @Published var isOnboardingComplete: Bool

    // MARK: - Initialization
    init() {
        // UserDefaults에서 상태 로드
    }

    // MARK: - Methods

    /// 온보딩 완료 처리
    func completeOnboarding()

    /// 첫 실행 여부 확인
    func isFirstLaunch() -> Bool

    /// 첫 실행 플래그 설정
    func markAsLaunched()
}
```

**구현 항목**:
| 항목 | 설명 | 저장 위치 |
|------|------|----------|
| `isOnboardingComplete` | 온보딩 완료 여부 | UserDefaults |
| `isFirstLaunch` | 앱 최초 실행 여부 | UserDefaults |
| `completeOnboarding()` | 온보딩 완료 처리 | - |

---

### 3.2 OnboardingViewModel

**파일**: `Bodii/Presentation/Features/Onboarding/ViewModels/OnboardingViewModel.swift`

```swift
/// 온보딩 ViewModel
/// 전체 온보딩 플로우 상태 관리
@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Onboarding Steps
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
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

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

    // MARK: - Computed Properties

    /// 현재 단계 진행률 (0.0 ~ 1.0)
    var progress: Double

    /// 다음 버튼 활성화 여부
    var canProceed: Bool

    /// 나이 계산
    var age: Int

    // MARK: - Validation

    /// Step 2 유효성 검증
    var isBasicInfoValid: Bool

    /// Step 3 유효성 검증
    var isBodyInfoValid: Bool

    // MARK: - Methods

    /// 다음 단계로 이동
    func goToNext()

    /// 이전 단계로 이동
    func goToPrevious()

    /// 온보딩 완료 처리 (User 생성 + BMR/TDEE 계산)
    func completeOnboarding() async

    /// 에러 제거
    func clearError()
}
```

**유효성 검증 규칙**:

| 필드 | 검증 규칙 | 에러 메시지 |
|------|----------|------------|
| 이름 | 1자 이상, 20자 이하 | "이름을 입력해주세요" / "이름은 20자 이하로 입력해주세요" |
| 성별 | 선택 필수 | (기본값 있어서 에러 없음) |
| 생년월일 | 10세 이상, 120세 이하 | "올바른 생년월일을 선택해주세요" |
| 키 | 100cm ~ 250cm | "키는 100~250cm 사이로 입력해주세요" |
| 몸무게 | 20kg ~ 300kg | "몸무게는 20~300kg 사이로 입력해주세요" |
| 활동 수준 | 선택 필수 | (기본값 있어서 에러 없음) |

---

### 3.3 View 구현 상세

#### 3.3.1 OnboardingContainerView

**파일**: `Bodii/Presentation/Features/Onboarding/Views/OnboardingContainerView.swift`

```swift
/// 온보딩 컨테이너 뷰
/// TabView를 사용한 페이지 전환
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 진행 상태 바
            OnboardingProgressBar(progress: viewModel.progress)

            // 페이지 컨텐츠
            TabView(selection: $viewModel.currentStep) {
                WelcomeView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.welcome)

                BasicInfoInputView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.basicInfo)

                BodyInfoInputView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.bodyInfo)

                ActivityLevelSelectView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.activityLevel)

                OnboardingCompleteView(viewModel: viewModel)
                    .tag(OnboardingViewModel.Step.complete)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

#### 3.3.2 WelcomeView (Step 1)

```swift
/// 앱 소개 화면
struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // 앱 로고
            Image("BodiiLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            // 타이틀
            Text("Bodii에 오신 것을\n환영합니다")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 설명
            Text("내 몸 관리 에이전트\n체성분, 식단, 운동을 한 곳에서 관리하세요")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // 시작하기 버튼
            OnboardingButton(title: "시작하기") {
                viewModel.goToNext()
            }
        }
        .padding(24)
    }
}
```

#### 3.3.3 BasicInfoInputView (Step 2)

```swift
/// 기본 정보 입력 화면
struct BasicInfoInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 타이틀
            Text("기본 정보를 입력해주세요")
                .font(.title2)
                .fontWeight(.bold)

            Text("정확한 대사량 계산을 위해 필요합니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer().frame(height: 20)

            // 이름 입력
            VStack(alignment: .leading, spacing: 8) {
                Text("이름")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("이름을 입력하세요", text: $viewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
            }

            // 성별 선택
            VStack(alignment: .leading, spacing: 8) {
                Text("성별")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    GenderButton(
                        title: "남성",
                        icon: "figure.stand",
                        isSelected: viewModel.gender == .male
                    ) {
                        viewModel.gender = .male
                    }

                    GenderButton(
                        title: "여성",
                        icon: "figure.stand.dress",
                        isSelected: viewModel.gender == .female
                    ) {
                        viewModel.gender = .female
                    }
                }
            }

            // 생년월일 선택
            VStack(alignment: .leading, spacing: 8) {
                Text("생년월일")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                DatePicker(
                    "",
                    selection: $viewModel.birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            }

            Spacer()

            // 네비게이션 버튼
            HStack(spacing: 16) {
                OnboardingButton(title: "이전", style: .secondary) {
                    viewModel.goToPrevious()
                }

                OnboardingButton(title: "다음", isEnabled: viewModel.isBasicInfoValid) {
                    viewModel.goToNext()
                }
            }
        }
        .padding(24)
    }
}
```

#### 3.3.4 BodyInfoInputView (Step 3)

```swift
/// 신체 정보 입력 화면
struct BodyInfoInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case height, weight
    }

    var body: some View {
        VStack(spacing: 24) {
            // 타이틀
            Text("신체 정보를 입력해주세요")
                .font(.title2)
                .fontWeight(.bold)

            Text("BMR(기초대사량) 계산에 사용됩니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer().frame(height: 40)

            // 키 입력
            VStack(alignment: .leading, spacing: 8) {
                Text("키")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("170", text: $viewModel.height)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .height)

                    Text("cm")
                        .foregroundStyle(.secondary)
                }
            }

            // 몸무게 입력
            VStack(alignment: .leading, spacing: 8) {
                Text("몸무게")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("70", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .weight)

                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            }

            // 유효성 안내
            if !viewModel.height.isEmpty || !viewModel.weight.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if let heightValue = Double(viewModel.height),
                       (heightValue < 100 || heightValue > 250) {
                        Text("키는 100~250cm 사이로 입력해주세요")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if let weightValue = Double(viewModel.weight),
                       (weightValue < 20 || weightValue > 300) {
                        Text("몸무게는 20~300kg 사이로 입력해주세요")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            // 네비게이션 버튼
            HStack(spacing: 16) {
                OnboardingButton(title: "이전", style: .secondary) {
                    viewModel.goToPrevious()
                }

                OnboardingButton(title: "다음", isEnabled: viewModel.isBodyInfoValid) {
                    viewModel.goToNext()
                }
            }
        }
        .padding(24)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    focusedField = nil
                }
            }
        }
    }
}
```

#### 3.3.5 ActivityLevelSelectView (Step 4)

```swift
/// 활동 수준 선택 화면
struct ActivityLevelSelectView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 타이틀
            Text("활동 수준을 선택해주세요")
                .font(.title2)
                .fontWeight(.bold)

            Text("TDEE(일일 소비 칼로리) 계산에 사용됩니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer().frame(height: 20)

            // 활동 수준 카드들
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            viewModel.activityLevel = level
                        }
                    }
                }
            }

            Spacer()

            // 네비게이션 버튼
            HStack(spacing: 16) {
                OnboardingButton(title: "이전", style: .secondary) {
                    viewModel.goToPrevious()
                }

                OnboardingButton(title: "완료") {
                    Task {
                        await viewModel.completeOnboarding()
                    }
                }
            }
        }
        .padding(24)
    }
}
```

#### 3.3.6 OnboardingCompleteView (Step 5)

```swift
/// 온보딩 완료 화면
struct OnboardingCompleteView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppStateService

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 완료 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            // 타이틀
            Text("설정 완료!")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 계산된 대사량 표시
            VStack(spacing: 16) {
                MetabolismResultCard(
                    title: "기초대사량 (BMR)",
                    value: viewModel.calculatedBMR ?? 0,
                    unit: "kcal",
                    description: "아무것도 안 해도 소비되는 칼로리"
                )

                MetabolismResultCard(
                    title: "일일 소비 칼로리 (TDEE)",
                    value: viewModel.calculatedTDEE ?? 0,
                    unit: "kcal",
                    description: "하루 동안 소비되는 총 칼로리"
                )
            }

            Spacer()

            // 시작하기 버튼
            OnboardingButton(title: "Bodii 시작하기") {
                appState.completeOnboarding()
            }
        }
        .padding(24)
    }
}
```

---

### 3.4 컴포넌트 구현

#### 3.4.1 OnboardingProgressBar

```swift
/// 온보딩 진행 상태 바
struct OnboardingProgressBar: View {
    let progress: Double // 0.0 ~ 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                // 진행 바
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}
```

#### 3.4.2 OnboardingButton

```swift
/// 온보딩 공통 버튼
struct OnboardingButton: View {
    enum Style {
        case primary, secondary
    }

    let title: String
    var style: Style = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundColor)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? .blue : .gray.opacity(0.3)
        case .secondary:
            return .gray.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? .white : .gray
        case .secondary:
            return .primary
        }
    }
}
```

#### 3.4.3 ActivityLevelCard

```swift
/// 활동 수준 선택 카드
struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 아이콘
                Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 40)

                // 텍스트
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.koreanDisplayName)
                        .font(.headline)

                    Text(level.koreanDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 활동 계수
                Text("×\(String(format: "%.2f", level.multiplier))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch level {
        case .sedentary: return "figure.seated.seatbelt"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.highintensity.intervaltraining"
        case .extraActive: return "figure.strengthtraining.traditional"
        }
    }
}
```

---

### 3.5 ActivityLevel 한국어 확장

```swift
// ActivityLevel+Korean.swift (또는 기존 파일에 추가)

extension ActivityLevel {
    /// 한국어 설명
    var koreanDescription: String {
        switch self {
        case .sedentary:
            return "거의 운동 안 함 (사무직, 재택근무)"
        case .lightlyActive:
            return "가벼운 운동 (주 1-3회)"
        case .moderatelyActive:
            return "보통 운동 (주 3-5회)"
        case .veryActive:
            return "활발한 운동 (주 6-7회)"
        case .extraActive:
            return "매우 활발 (운동선수, 육체 노동)"
        }
    }
}
```

---

### 3.6 BodiiApp 수정

```swift
// BodiiApp.swift

@main
struct BodiiApp: App {
    @StateObject private var appState = AppStateService()

    var body: some Scene {
        WindowGroup {
            if appState.isOnboardingComplete {
                ContentView()
                    .environmentObject(appState)
            } else {
                OnboardingContainerView()
                    .environmentObject(appState)
            }
        }
    }
}
```

---

## 4. 데이터 저장

### 4.1 온보딩 완료 시 저장 항목

| Entity | Field | 값 |
|--------|-------|-----|
| User | id | UUID() |
| User | name | 입력값 |
| User | gender | 선택값 (0: male, 1: female) |
| User | birthDate | 선택값 |
| User | height | 입력값 (Decimal) |
| User | activityLevel | 선택값 (0~4) |
| User | currentWeight | 입력값 (Decimal) |
| User | currentBMR | 계산값 (Int32) |
| User | currentTDEE | 계산값 (Int32) |
| User | createdAt | Date() |
| User | updatedAt | Date() |

### 4.2 completeOnboarding() 구현

```swift
/// 온보딩 완료 처리
func completeOnboarding() async {
    isLoading = true

    do {
        let context = PersistenceController.shared.newBackgroundContext()

        try await context.perform {
            // 1. User 생성
            let user = User(context: context)
            user.id = UUID()
            user.name = self.name
            user.gender = self.gender.rawValue
            user.birthDate = self.birthDate
            user.height = NSDecimalNumber(string: self.height)
            user.activityLevel = self.activityLevel.rawValue
            user.currentWeight = NSDecimalNumber(string: self.weight)
            user.createdAt = Date()
            user.updatedAt = Date()

            // 2. BMR 계산
            let weight = Decimal(string: self.weight) ?? 0
            let height = Decimal(string: self.height) ?? 0

            let bmr = MetabolismCalculator.calculateBMR(
                weight: weight,
                height: height,
                age: self.age,
                gender: self.gender,
                bodyFatPct: nil
            )

            // 3. TDEE 계산
            let tdee = MetabolismCalculator.calculateTDEE(
                bmr: bmr,
                activityLevel: self.activityLevel
            )

            user.currentBMR = Int32(bmr)
            user.currentTDEE = Int32(tdee)

            // 4. 저장
            try context.save()

            // 5. UI 업데이트
            await MainActor.run {
                self.calculatedBMR = Int(bmr)
                self.calculatedTDEE = Int(tdee)
                self.currentStep = .complete
            }
        }
    } catch {
        await MainActor.run {
            self.errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }

    isLoading = false
}
```

---

## 5. 테스트 케이스

### 5.1 Unit Tests - OnboardingViewModel

```swift
class OnboardingViewModelTests: XCTestCase {

    var sut: OnboardingViewModel!

    override func setUp() {
        sut = OnboardingViewModel()
    }

    override func tearDown() {
        sut = nil
    }

    // MARK: - 초기 상태 테스트

    func test_initialState_isWelcomeStep() {
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func test_initialProgress_isZero() {
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)
    }

    func test_initialGender_isMale() {
        XCTAssertEqual(sut.gender, .male)
    }

    func test_initialActivityLevel_isModeratelyActive() {
        XCTAssertEqual(sut.activityLevel, .moderatelyActive)
    }

    // MARK: - 단계 이동 테스트

    func test_goToNext_fromWelcome_movesToBasicInfo() {
        // Given
        sut.currentStep = .welcome

        // When
        sut.goToNext()

        // Then
        XCTAssertEqual(sut.currentStep, .basicInfo)
    }

    func test_goToNext_fromBasicInfo_movesToBodyInfo() {
        // Given
        sut.currentStep = .basicInfo
        sut.name = "테스트"

        // When
        sut.goToNext()

        // Then
        XCTAssertEqual(sut.currentStep, .bodyInfo)
    }

    func test_goToPrevious_fromBasicInfo_movesToWelcome() {
        // Given
        sut.currentStep = .basicInfo

        // When
        sut.goToPrevious()

        // Then
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func test_goToPrevious_fromWelcome_staysAtWelcome() {
        // Given
        sut.currentStep = .welcome

        // When
        sut.goToPrevious()

        // Then
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    // MARK: - 진행률 테스트

    func test_progress_atWelcome_isZero() {
        sut.currentStep = .welcome
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)
    }

    func test_progress_atBasicInfo_is25Percent() {
        sut.currentStep = .basicInfo
        XCTAssertEqual(sut.progress, 0.25, accuracy: 0.01)
    }

    func test_progress_atBodyInfo_is50Percent() {
        sut.currentStep = .bodyInfo
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01)
    }

    func test_progress_atActivityLevel_is75Percent() {
        sut.currentStep = .activityLevel
        XCTAssertEqual(sut.progress, 0.75, accuracy: 0.01)
    }

    func test_progress_atComplete_is100Percent() {
        sut.currentStep = .complete
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.01)
    }

    // MARK: - 기본 정보 유효성 테스트

    func test_isBasicInfoValid_emptyName_returnsFalse() {
        sut.name = ""
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_validName_returnsTrue() {
        sut.name = "테스트"
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_tooLongName_returnsFalse() {
        sut.name = String(repeating: "가", count: 21) // 21자
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_maxLengthName_returnsTrue() {
        sut.name = String(repeating: "가", count: 20) // 20자
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_ageTooYoung_returnsFalse() {
        // Given: 9세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -9, to: Date())!

        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_ageTooOld_returnsFalse() {
        // Given: 121세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -121, to: Date())!

        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_validAge_returnsTrue() {
        // Given: 30세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        XCTAssertTrue(sut.isBasicInfoValid)
    }

    // MARK: - 신체 정보 유효성 테스트

    func test_isBodyInfoValid_emptyHeight_returnsFalse() {
        sut.height = ""
        sut.weight = "70"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_emptyWeight_returnsFalse() {
        sut.height = "175"
        sut.weight = ""
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_heightTooLow_returnsFalse() {
        sut.height = "99"
        sut.weight = "70"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_heightTooHigh_returnsFalse() {
        sut.height = "251"
        sut.weight = "70"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_weightTooLow_returnsFalse() {
        sut.height = "175"
        sut.weight = "19"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_weightTooHigh_returnsFalse() {
        sut.height = "175"
        sut.weight = "301"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_validValues_returnsTrue() {
        sut.height = "175"
        sut.weight = "70"
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_boundaryMinHeight_returnsTrue() {
        sut.height = "100"
        sut.weight = "70"
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_boundaryMaxHeight_returnsTrue() {
        sut.height = "250"
        sut.weight = "70"
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_boundaryMinWeight_returnsTrue() {
        sut.height = "175"
        sut.weight = "20"
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_boundaryMaxWeight_returnsTrue() {
        sut.height = "175"
        sut.weight = "300"
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_nonNumericHeight_returnsFalse() {
        sut.height = "abc"
        sut.weight = "70"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_nonNumericWeight_returnsFalse() {
        sut.height = "175"
        sut.weight = "abc"
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_decimalValues_returnsTrue() {
        sut.height = "175.5"
        sut.weight = "70.3"
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    // MARK: - 나이 계산 테스트

    func test_age_30YearsAgo_returns30() {
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        XCTAssertEqual(sut.age, 30)
    }

    func test_age_25YearsAgo_returns25() {
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        XCTAssertEqual(sut.age, 25)
    }

    // MARK: - canProceed 테스트

    func test_canProceed_atWelcome_alwaysTrue() {
        sut.currentStep = .welcome
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atBasicInfo_dependsOnValidation() {
        sut.currentStep = .basicInfo
        sut.name = ""
        XCTAssertFalse(sut.canProceed)

        sut.name = "테스트"
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atBodyInfo_dependsOnValidation() {
        sut.currentStep = .bodyInfo
        sut.height = ""
        sut.weight = ""
        XCTAssertFalse(sut.canProceed)

        sut.height = "175"
        sut.weight = "70"
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atActivityLevel_alwaysTrue() {
        sut.currentStep = .activityLevel
        XCTAssertTrue(sut.canProceed)
    }

    // MARK: - 에러 처리 테스트

    func test_clearError_removesErrorMessage() {
        sut.errorMessage = "테스트 에러"
        sut.clearError()
        XCTAssertNil(sut.errorMessage)
    }
}
```

### 5.2 Unit Tests - AppStateService

```swift
class AppStateServiceTests: XCTestCase {

    var sut: AppStateService!
    var userDefaults: UserDefaults!

    override func setUp() {
        // 테스트용 UserDefaults 사용
        userDefaults = UserDefaults(suiteName: "TestDefaults")
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = AppStateService(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = nil
    }

    // MARK: - 초기 상태 테스트

    func test_initialState_isOnboardingComplete_isFalse() {
        XCTAssertFalse(sut.isOnboardingComplete)
    }

    func test_initialState_isFirstLaunch_isTrue() {
        XCTAssertTrue(sut.isFirstLaunch())
    }

    // MARK: - 온보딩 완료 테스트

    func test_completeOnboarding_setsFlag() {
        sut.completeOnboarding()
        XCTAssertTrue(sut.isOnboardingComplete)
    }

    func test_completeOnboarding_persistsToUserDefaults() {
        sut.completeOnboarding()

        // 새 인스턴스 생성하여 확인
        let newInstance = AppStateService(userDefaults: userDefaults)
        XCTAssertTrue(newInstance.isOnboardingComplete)
    }

    // MARK: - 첫 실행 테스트

    func test_markAsLaunched_setsFlag() {
        sut.markAsLaunched()
        XCTAssertFalse(sut.isFirstLaunch())
    }

    func test_markAsLaunched_persistsToUserDefaults() {
        sut.markAsLaunched()

        let newInstance = AppStateService(userDefaults: userDefaults)
        XCTAssertFalse(newInstance.isFirstLaunch())
    }
}
```

### 5.3 Integration Tests - 온보딩 완료 시 User 생성

```swift
class OnboardingIntegrationTests: XCTestCase {

    var viewModel: OnboardingViewModel!
    var coreDataStack: TestCoreDataStack!

    override func setUp() {
        coreDataStack = TestCoreDataStack()
        viewModel = OnboardingViewModel(context: coreDataStack.context)
    }

    override func tearDown() {
        coreDataStack = nil
        viewModel = nil
    }

    // MARK: - 온보딩 완료 통합 테스트

    func test_completeOnboarding_createsUser() async throws {
        // Given
        viewModel.name = "테스트"
        viewModel.gender = .male
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.height = "175"
        viewModel.weight = "72.5"
        viewModel.activityLevel = .moderatelyActive

        // When
        await viewModel.completeOnboarding()

        // Then
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let users = try coreDataStack.context.fetch(fetchRequest)

        XCTAssertEqual(users.count, 1)

        let user = users.first!
        XCTAssertEqual(user.name, "테스트")
        XCTAssertEqual(user.gender, Gender.male.rawValue)
        XCTAssertEqual(user.height?.doubleValue, 175.0, accuracy: 0.1)
        XCTAssertEqual(user.currentWeight?.doubleValue, 72.5, accuracy: 0.1)
        XCTAssertEqual(user.activityLevel, ActivityLevel.moderatelyActive.rawValue)
    }

    func test_completeOnboarding_calculatesBMRCorrectly() async throws {
        // Given
        viewModel.name = "테스트"
        viewModel.gender = .male
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.height = "175"
        viewModel.weight = "72.5"
        viewModel.activityLevel = .moderatelyActive

        // When
        await viewModel.completeOnboarding()

        // Then
        let user = try fetchUser()

        // Mifflin-St Jeor (체지방률 없음):
        // BMR = 10 × 72.5 + 6.25 × 175 - 5 × 30 + 5 = 1669
        XCTAssertEqual(user.currentBMR, 1669, accuracy: 5)
    }

    func test_completeOnboarding_calculatesTDEECorrectly() async throws {
        // Given
        viewModel.name = "테스트"
        viewModel.gender = .male
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.height = "175"
        viewModel.weight = "72.5"
        viewModel.activityLevel = .moderatelyActive // 1.55

        // When
        await viewModel.completeOnboarding()

        // Then
        let user = try fetchUser()

        // TDEE = BMR × 1.55 = 1669 × 1.55 ≈ 2587
        XCTAssertEqual(user.currentTDEE, 2587, accuracy: 10)
    }

    func test_completeOnboarding_female_calculatesBMRCorrectly() async throws {
        // Given
        viewModel.name = "테스트"
        viewModel.gender = .female
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -28, to: Date())!
        viewModel.height = "162"
        viewModel.weight = "55"
        viewModel.activityLevel = .lightlyActive

        // When
        await viewModel.completeOnboarding()

        // Then
        let user = try fetchUser()

        // Mifflin-St Jeor 여성:
        // BMR = 10 × 55 + 6.25 × 162 - 5 × 28 - 161 = 1291
        XCTAssertEqual(user.currentBMR, 1291, accuracy: 5)
    }

    func test_completeOnboarding_updatesViewModelWithResults() async {
        // Given
        viewModel.name = "테스트"
        viewModel.gender = .male
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.height = "175"
        viewModel.weight = "72.5"
        viewModel.activityLevel = .moderatelyActive

        // When
        await viewModel.completeOnboarding()

        // Then
        XCTAssertNotNil(viewModel.calculatedBMR)
        XCTAssertNotNil(viewModel.calculatedTDEE)
        XCTAssertEqual(viewModel.currentStep, .complete)
    }

    func test_completeOnboarding_setsCorrectTimestamps() async throws {
        // Given
        let beforeDate = Date()
        viewModel.name = "테스트"
        viewModel.gender = .male
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.height = "175"
        viewModel.weight = "72.5"
        viewModel.activityLevel = .moderatelyActive

        // When
        await viewModel.completeOnboarding()

        // Then
        let user = try fetchUser()
        let afterDate = Date()

        XCTAssertNotNil(user.createdAt)
        XCTAssertNotNil(user.updatedAt)
        XCTAssertTrue(user.createdAt! >= beforeDate)
        XCTAssertTrue(user.createdAt! <= afterDate)
    }

    // MARK: - Helper

    private func fetchUser() throws -> User {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        return try coreDataStack.context.fetch(fetchRequest).first!
    }
}
```

### 5.4 UI Tests - 온보딩 플로우

```swift
class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
        app.launch()
    }

    // MARK: - Welcome Screen Tests

    func test_welcomeScreen_displaysCorrectElements() {
        // 앱 로고 확인
        XCTAssertTrue(app.images["BodiiLogo"].exists)

        // 타이틀 확인
        XCTAssertTrue(app.staticTexts["Bodii에 오신 것을"].exists)
        XCTAssertTrue(app.staticTexts["환영합니다"].exists)

        // 시작하기 버튼 확인
        XCTAssertTrue(app.buttons["시작하기"].exists)
    }

    func test_welcomeScreen_tapStart_navigatesToBasicInfo() {
        // When
        app.buttons["시작하기"].tap()

        // Then
        XCTAssertTrue(app.staticTexts["기본 정보를 입력해주세요"].exists)
    }

    // MARK: - Basic Info Screen Tests

    func test_basicInfoScreen_displaysCorrectElements() {
        // Navigate to BasicInfo
        app.buttons["시작하기"].tap()

        // 타이틀 확인
        XCTAssertTrue(app.staticTexts["기본 정보를 입력해주세요"].exists)

        // 입력 필드 확인
        XCTAssertTrue(app.textFields["이름을 입력하세요"].exists)
        XCTAssertTrue(app.buttons["남성"].exists)
        XCTAssertTrue(app.buttons["여성"].exists)
        XCTAssertTrue(app.datePickers.firstMatch.exists)

        // 버튼 확인
        XCTAssertTrue(app.buttons["이전"].exists)
        XCTAssertTrue(app.buttons["다음"].exists)
    }

    func test_basicInfoScreen_emptyName_nextButtonDisabled() {
        // Navigate to BasicInfo
        app.buttons["시작하기"].tap()

        // 이름 비어있음
        XCTAssertFalse(app.buttons["다음"].isEnabled)
    }

    func test_basicInfoScreen_enterName_nextButtonEnabled() {
        // Navigate to BasicInfo
        app.buttons["시작하기"].tap()

        // 이름 입력
        let nameField = app.textFields["이름을 입력하세요"]
        nameField.tap()
        nameField.typeText("테스트")

        // 다음 버튼 활성화 확인
        XCTAssertTrue(app.buttons["다음"].isEnabled)
    }

    func test_basicInfoScreen_selectGender_updatesSelection() {
        // Navigate to BasicInfo
        app.buttons["시작하기"].tap()

        // 여성 선택
        app.buttons["여성"].tap()

        // 선택 확인 (체크마크 또는 선택 상태)
        // 구현에 따라 확인 방법 조정
    }

    func test_basicInfoScreen_tapPrevious_navigatesToWelcome() {
        // Navigate to BasicInfo
        app.buttons["시작하기"].tap()

        // When
        app.buttons["이전"].tap()

        // Then
        XCTAssertTrue(app.staticTexts["Bodii에 오신 것을"].exists)
    }

    // MARK: - Body Info Screen Tests

    func test_bodyInfoScreen_displaysCorrectElements() {
        // Navigate to BodyInfo
        navigateToBodyInfo()

        // 타이틀 확인
        XCTAssertTrue(app.staticTexts["신체 정보를 입력해주세요"].exists)

        // 입력 필드 확인
        XCTAssertTrue(app.textFields["170"].exists) // 키 placeholder
        XCTAssertTrue(app.textFields["70"].exists)  // 몸무게 placeholder
        XCTAssertTrue(app.staticTexts["cm"].exists)
        XCTAssertTrue(app.staticTexts["kg"].exists)
    }

    func test_bodyInfoScreen_emptyFields_nextButtonDisabled() {
        // Navigate to BodyInfo
        navigateToBodyInfo()

        // 빈 필드
        XCTAssertFalse(app.buttons["다음"].isEnabled)
    }

    func test_bodyInfoScreen_validInput_nextButtonEnabled() {
        // Navigate to BodyInfo
        navigateToBodyInfo()

        // 키 입력
        let heightField = app.textFields["170"]
        heightField.tap()
        heightField.typeText("175")

        // 몸무게 입력
        let weightField = app.textFields["70"]
        weightField.tap()
        weightField.typeText("72.5")

        // 다음 버튼 활성화 확인
        XCTAssertTrue(app.buttons["다음"].isEnabled)
    }

    func test_bodyInfoScreen_invalidHeight_showsError() {
        // Navigate to BodyInfo
        navigateToBodyInfo()

        // 잘못된 키 입력
        let heightField = app.textFields["170"]
        heightField.tap()
        heightField.typeText("50") // 범위 초과

        // 에러 메시지 확인
        XCTAssertTrue(app.staticTexts["키는 100~250cm 사이로 입력해주세요"].exists)
    }

    func test_bodyInfoScreen_invalidWeight_showsError() {
        // Navigate to BodyInfo
        navigateToBodyInfo()

        // 키 입력
        let heightField = app.textFields["170"]
        heightField.tap()
        heightField.typeText("175")

        // 잘못된 몸무게 입력
        let weightField = app.textFields["70"]
        weightField.tap()
        weightField.typeText("10") // 범위 초과

        // 에러 메시지 확인
        XCTAssertTrue(app.staticTexts["몸무게는 20~300kg 사이로 입력해주세요"].exists)
    }

    // MARK: - Activity Level Screen Tests

    func test_activityLevelScreen_displaysAllLevels() {
        // Navigate to ActivityLevel
        navigateToActivityLevel()

        // 5개 활동 수준 카드 확인
        XCTAssertTrue(app.staticTexts["비활동적"].exists)
        XCTAssertTrue(app.staticTexts["가벼운 활동"].exists)
        XCTAssertTrue(app.staticTexts["보통 활동"].exists)
        XCTAssertTrue(app.staticTexts["활발한 활동"].exists)
        XCTAssertTrue(app.staticTexts["매우 활발"].exists)
    }

    func test_activityLevelScreen_selectLevel_updatesSelection() {
        // Navigate to ActivityLevel
        navigateToActivityLevel()

        // 활발한 활동 선택
        app.buttons["활발한 활동"].tap()

        // 선택 확인 (체크마크)
        // 구현에 따라 확인 방법 조정
    }

    func test_activityLevelScreen_tapComplete_navigatesToCompleteScreen() {
        // Navigate to ActivityLevel
        navigateToActivityLevel()

        // When
        app.buttons["완료"].tap()

        // Then (로딩 후)
        let completeTitle = app.staticTexts["설정 완료!"]
        XCTAssertTrue(completeTitle.waitForExistence(timeout: 5))
    }

    // MARK: - Complete Screen Tests

    func test_completeScreen_displaysBMRandTDEE() {
        // Complete onboarding
        completeFullOnboarding()

        // 완료 화면 확인
        XCTAssertTrue(app.staticTexts["설정 완료!"].exists)
        XCTAssertTrue(app.staticTexts["기초대사량 (BMR)"].exists)
        XCTAssertTrue(app.staticTexts["일일 소비 칼로리 (TDEE)"].exists)
    }

    func test_completeScreen_tapStart_navigatesToMainScreen() {
        // Complete onboarding
        completeFullOnboarding()

        // When
        app.buttons["Bodii 시작하기"].tap()

        // Then - 메인 화면 (탭바) 확인
        XCTAssertTrue(app.tabBars.buttons["홈"].exists)
    }

    // MARK: - Full Flow Test

    func test_fullOnboardingFlow_success() {
        // Step 1: Welcome
        XCTAssertTrue(app.staticTexts["Bodii에 오신 것을"].exists)
        app.buttons["시작하기"].tap()

        // Step 2: Basic Info
        XCTAssertTrue(app.staticTexts["기본 정보를 입력해주세요"].exists)
        app.textFields["이름을 입력하세요"].tap()
        app.textFields["이름을 입력하세요"].typeText("테스트사용자")
        app.buttons["남성"].tap()
        app.buttons["다음"].tap()

        // Step 3: Body Info
        XCTAssertTrue(app.staticTexts["신체 정보를 입력해주세요"].exists)
        app.textFields["170"].tap()
        app.textFields["170"].typeText("175")
        app.textFields["70"].tap()
        app.textFields["70"].typeText("72")
        app.buttons["다음"].tap()

        // Step 4: Activity Level
        XCTAssertTrue(app.staticTexts["활동 수준을 선택해주세요"].exists)
        app.buttons["보통 활동"].tap()
        app.buttons["완료"].tap()

        // Step 5: Complete
        let completeTitle = app.staticTexts["설정 완료!"]
        XCTAssertTrue(completeTitle.waitForExistence(timeout: 5))

        // 메인 화면 진입
        app.buttons["Bodii 시작하기"].tap()
        XCTAssertTrue(app.tabBars.buttons["홈"].exists)
    }

    // MARK: - Progress Bar Tests

    func test_progressBar_updatesCorrectly() {
        // Welcome (0%)
        // 진행 바 확인 로직 (구현에 따라)

        // BasicInfo (25%)
        app.buttons["시작하기"].tap()
        // 진행 바 확인

        // BodyInfo (50%)
        app.textFields["이름을 입력하세요"].tap()
        app.textFields["이름을 입력하세요"].typeText("테스트")
        app.buttons["다음"].tap()
        // 진행 바 확인
    }

    // MARK: - Helpers

    private func navigateToBodyInfo() {
        app.buttons["시작하기"].tap()
        app.textFields["이름을 입력하세요"].tap()
        app.textFields["이름을 입력하세요"].typeText("테스트")
        app.buttons["다음"].tap()
    }

    private func navigateToActivityLevel() {
        navigateToBodyInfo()
        app.textFields["170"].tap()
        app.textFields["170"].typeText("175")
        app.textFields["70"].tap()
        app.textFields["70"].typeText("72")
        app.buttons["다음"].tap()
    }

    private func completeFullOnboarding() {
        app.buttons["시작하기"].tap()

        app.textFields["이름을 입력하세요"].tap()
        app.textFields["이름을 입력하세요"].typeText("테스트")
        app.buttons["다음"].tap()

        app.textFields["170"].tap()
        app.textFields["170"].typeText("175")
        app.textFields["70"].tap()
        app.textFields["70"].typeText("72")
        app.buttons["다음"].tap()

        app.buttons["완료"].tap()

        // 완료 화면 대기
        let completeTitle = app.staticTexts["설정 완료!"]
        _ = completeTitle.waitForExistence(timeout: 5)
    }
}
```

### 5.5 Edge Case Tests

```swift
class OnboardingEdgeCaseTests: XCTestCase {

    var viewModel: OnboardingViewModel!

    override func setUp() {
        viewModel = OnboardingViewModel()
    }

    // MARK: - 이름 Edge Cases

    func test_name_whitespaceOnly_isInvalid() {
        viewModel.name = "   "
        XCTAssertFalse(viewModel.isBasicInfoValid)
    }

    func test_name_withLeadingTrailingSpaces_trimmed_isValid() {
        viewModel.name = "  테스트  "
        // 구현에 따라: trim 후 유효성 검사
        // XCTAssertTrue(viewModel.isBasicInfoValid)
    }

    func test_name_withEmoji_isValid() {
        viewModel.name = "테스트😀"
        XCTAssertTrue(viewModel.isBasicInfoValid)
    }

    func test_name_withSpecialCharacters_isValid() {
        viewModel.name = "김철수-Jr."
        XCTAssertTrue(viewModel.isBasicInfoValid)
    }

    // MARK: - 키/몸무게 Edge Cases

    func test_height_withLeadingZero_isValid() {
        viewModel.height = "0175"
        viewModel.weight = "70"
        // 구현에 따라 결과 확인
    }

    func test_height_negativeValue_isInvalid() {
        viewModel.height = "-175"
        viewModel.weight = "70"
        XCTAssertFalse(viewModel.isBodyInfoValid)
    }

    func test_weight_verySmallDecimal_isHandled() {
        viewModel.height = "175"
        viewModel.weight = "70.123456"
        // 소수점 처리 확인
    }

    // MARK: - 나이 Edge Cases

    func test_age_exactly10_isValid() {
        viewModel.name = "테스트"
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        XCTAssertTrue(viewModel.isBasicInfoValid)
    }

    func test_age_exactly120_isValid() {
        viewModel.name = "테스트"
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: -120, to: Date())!
        XCTAssertTrue(viewModel.isBasicInfoValid)
    }

    func test_birthDate_futureDate_isInvalid() {
        viewModel.name = "테스트"
        viewModel.birthDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        XCTAssertFalse(viewModel.isBasicInfoValid)
    }

    // MARK: - 활동 수준 Edge Cases

    func test_activityLevel_allLevels_calculateCorrectTDEE() {
        let bmr: Decimal = 1500

        let expectedTDEE: [ActivityLevel: Decimal] = [
            .sedentary: 1800,       // 1500 × 1.2
            .lightlyActive: 2063,   // 1500 × 1.375
            .moderatelyActive: 2325, // 1500 × 1.55
            .veryActive: 2588,      // 1500 × 1.725
            .extraActive: 2850      // 1500 × 1.9
        ]

        for (level, expected) in expectedTDEE {
            let tdee = MetabolismCalculator.calculateTDEE(bmr: bmr, activityLevel: level)
            XCTAssertEqual(tdee, expected, accuracy: 5, "Failed for \(level)")
        }
    }

    // MARK: - 동시성 Edge Cases

    func test_completeOnboarding_calledTwice_onlyCreatesOneUser() async throws {
        // Given
        let coreDataStack = TestCoreDataStack()
        viewModel = OnboardingViewModel(context: coreDataStack.context)
        viewModel.name = "테스트"
        viewModel.height = "175"
        viewModel.weight = "70"

        // When - 동시에 두 번 호출
        async let result1: Void = viewModel.completeOnboarding()
        async let result2: Void = viewModel.completeOnboarding()

        _ = await (result1, result2)

        // Then - User가 하나만 생성되어야 함
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        let users = try coreDataStack.context.fetch(fetchRequest)
        XCTAssertEqual(users.count, 1)
    }
}
```

---

## 6. 테스트 체크리스트

### 6.1 Unit Test 체크리스트

- [ ] OnboardingViewModel 초기 상태 테스트
- [ ] 단계 이동 (goToNext/goToPrevious) 테스트
- [ ] 진행률 계산 테스트
- [ ] 기본 정보 유효성 검증 테스트
- [ ] 신체 정보 유효성 검증 테스트
- [ ] 나이 계산 테스트
- [ ] canProceed 조건 테스트
- [ ] 에러 처리 테스트
- [ ] AppStateService 상태 저장 테스트

### 6.2 Integration Test 체크리스트

- [ ] 온보딩 완료 시 User 생성 테스트
- [ ] BMR 계산 정확도 테스트 (남성)
- [ ] BMR 계산 정확도 테스트 (여성)
- [ ] TDEE 계산 정확도 테스트
- [ ] 타임스탬프 설정 테스트
- [ ] ViewModel 결과 업데이트 테스트

### 6.3 UI Test 체크리스트

- [ ] Welcome 화면 요소 표시 테스트
- [ ] Basic Info 화면 요소 표시 테스트
- [ ] Body Info 화면 요소 표시 테스트
- [ ] Activity Level 화면 요소 표시 테스트
- [ ] Complete 화면 요소 표시 테스트
- [ ] 입력 유효성 에러 메시지 표시 테스트
- [ ] 버튼 활성화/비활성화 테스트
- [ ] 화면 전환 테스트
- [ ] 전체 플로우 테스트
- [ ] 진행 바 업데이트 테스트

### 6.4 Edge Case 체크리스트

- [ ] 이름 공백/특수문자/이모지 테스트
- [ ] 키/몸무게 경계값 테스트
- [ ] 나이 경계값 테스트
- [ ] 미래 생년월일 테스트
- [ ] 동시성 처리 테스트

---

## 7. 개발 순서

### 단계 1: 기반 구조 (2시간)
1. AppStateService 구현
2. OnboardingViewModel 기본 구조

### 단계 2: View 구현 (4시간)
1. OnboardingContainerView
2. WelcomeView
3. BasicInfoInputView
4. BodyInfoInputView
5. ActivityLevelSelectView
6. OnboardingCompleteView

### 단계 3: 컴포넌트 (1시간)
1. OnboardingProgressBar
2. OnboardingButton
3. ActivityLevelCard
4. GenderButton
5. MetabolismResultCard

### 단계 4: 통합 (1시간)
1. BodiiApp 수정
2. completeOnboarding() 구현
3. User 생성 + BMR/TDEE 계산

### 단계 5: 테스트 (2~4시간)
1. Unit Tests 작성 및 실행
2. Integration Tests 작성 및 실행
3. UI Tests 작성 및 실행
4. Edge Case Tests 작성 및 실행

---

*문서 버전: 1.0*
*작성일: 2026-01-20*

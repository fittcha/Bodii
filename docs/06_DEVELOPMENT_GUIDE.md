# Bodii - 개발 가이드

## 1. 아키텍처

### 1.1 아키텍처 선택: MVVM + Clean 하이브리드

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │    View     │ ←→ │  ViewModel  │ ←→ │   UseCase   │         │
│  │  (SwiftUI)  │    │ (@Observable)│    │             │         │
│  └─────────────┘    └─────────────┘    └──────┬──────┘         │
└──────────────────────────────────────────────┬─────────────────┘
                                               │
┌──────────────────────────────────────────────┼─────────────────┐
│                       Domain Layer           │                  │
│  ┌─────────────┐    ┌─────────────┐    ┌────┴────┐             │
│  │   Entity    │    │  Interface  │ ←──│ UseCase │             │
│  │ (순수 모델) │    │ (Protocol)  │    │  Impl   │             │
│  └─────────────┘    └──────┬──────┘    └─────────┘             │
└────────────────────────────┼───────────────────────────────────┘
                             │
┌────────────────────────────┼───────────────────────────────────┐
│                       Data Layer                                │
│  ┌─────────────┐    ┌──────┴──────┐    ┌─────────────┐         │
│  │ Repository  │ ←──│  Protocol   │    │    DTO      │         │
│  │   (Impl)    │    │   Impl      │    │             │         │
│  └──────┬──────┘    └─────────────┘    └─────────────┘         │
│         │                                                       │
│  ┌──────┴──────┐    ┌─────────────┐                            │
│  │  Local DS   │    │  Remote DS  │                            │
│  │ (Core Data) │    │   (API)     │                            │
│  └─────────────┘    └─────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 폴더 구조

```
Bodii/
├── App/
│   ├── BodiiApp.swift              # 앱 진입점
│   ├── ContentView.swift           # 루트 뷰 (탭바)
│   └── DIContainer.swift           # 의존성 주입 컨테이너
│
├── Presentation/                    # UI Layer
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── Views/
│   │   │   │   ├── OnboardingView.swift
│   │   │   │   └── OnboardingPageView.swift
│   │   │   └── ViewModels/
│   │   │       └── OnboardingViewModel.swift
│   │   │
│   │   ├── Dashboard/
│   │   │   ├── Views/
│   │   │   │   ├── DashboardView.swift
│   │   │   │   ├── CalorieProgressCard.swift
│   │   │   │   └── MacroChartCard.swift
│   │   │   └── ViewModels/
│   │   │       └── DashboardViewModel.swift
│   │   │
│   │   ├── Body/                   # 체성분
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   ├── Diet/                   # 식단
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   ├── Exercise/               # 운동
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   ├── Sleep/                  # 수면
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   ├── Goal/                   # 목표 (Phase 2)
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   │
│   │   └── Settings/
│   │       ├── Views/
│   │       └── ViewModels/
│   │
│   └── Components/                 # 재사용 UI 컴포넌트
│       ├── Charts/
│       │   ├── CircularProgressView.swift
│       │   ├── MacroBarChart.swift
│       │   └── LineChartView.swift
│       ├── Cards/
│       │   └── SummaryCard.swift
│       └── Common/
│           ├── LoadingView.swift
│           └── ErrorView.swift
│
├── Domain/                         # Business Logic Layer
│   ├── Entities/                   # 순수 비즈니스 모델
│   │   ├── User.swift
│   │   ├── BodyRecord.swift
│   │   ├── Food.swift
│   │   ├── FoodRecord.swift
│   │   ├── ExerciseRecord.swift
│   │   ├── SleepRecord.swift
│   │   ├── Goal.swift
│   │   └── DailyLog.swift
│   │
│   ├── UseCases/                   # 비즈니스 로직 단위
│   │   ├── Body/
│   │   │   ├── CalculateBMRUseCase.swift
│   │   │   ├── CalculateTDEEUseCase.swift
│   │   │   └── RecordBodyUseCase.swift
│   │   ├── Diet/
│   │   │   ├── SearchFoodUseCase.swift
│   │   │   ├── RecordMealUseCase.swift
│   │   │   └── GenerateDietCommentUseCase.swift
│   │   ├── Exercise/
│   │   │   ├── CalculateMETUseCase.swift
│   │   │   └── RecordExerciseUseCase.swift
│   │   ├── Sleep/
│   │   │   ├── CalculateSleepStatusUseCase.swift
│   │   │   └── RecordSleepUseCase.swift
│   │   └── Goal/
│   │       ├── SetGoalUseCase.swift
│   │       ├── ValidateGoalUseCase.swift
│   │       └── CalculateProgressUseCase.swift
│   │
│   └── Interfaces/                 # Repository 프로토콜
│       ├── UserRepositoryProtocol.swift
│       ├── BodyRepositoryProtocol.swift
│       ├── FoodRepositoryProtocol.swift
│       ├── ExerciseRepositoryProtocol.swift
│       ├── SleepRepositoryProtocol.swift
│       └── GoalRepositoryProtocol.swift
│
├── Data/                           # Data Layer
│   ├── Repositories/               # 프로토콜 구현체
│   │   ├── UserRepository.swift
│   │   ├── BodyRepository.swift
│   │   ├── FoodRepository.swift
│   │   ├── ExerciseRepository.swift
│   │   ├── SleepRepository.swift
│   │   └── GoalRepository.swift
│   │
│   ├── DataSources/
│   │   ├── Local/                  # Core Data
│   │   │   ├── CoreDataManager.swift
│   │   │   └── Entities/           # Core Data 모델
│   │   │       ├── UserEntity+CoreData.swift
│   │   │       └── ...
│   │   └── Remote/                 # API
│   │       ├── FoodAPIDataSource.swift
│   │       ├── USDAAPIDataSource.swift
│   │       └── GeminiAPIDataSource.swift
│   │
│   ├── DTOs/                       # 데이터 전송 객체
│   │   ├── FoodAPIResponse.swift
│   │   ├── USDAAPIResponse.swift
│   │   └── GeminiResponse.swift
│   │
│   └── Mappers/                    # DTO ↔ Entity 변환
│       ├── FoodMapper.swift
│       └── ...
│
├── Infrastructure/                 # 외부 의존성
│   ├── Network/
│   │   ├── NetworkManager.swift
│   │   ├── APIEndpoint.swift
│   │   ├── APIError.swift
│   │   └── HTTPMethod.swift
│   │
│   ├── HealthKit/
│   │   └── HealthKitManager.swift
│   │
│   └── Persistence/
│       ├── PersistenceController.swift
│       └── Bodii.xcdatamodeld
│
├── Shared/
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Double+Extensions.swift
│   │   ├── Color+Extensions.swift
│   │   └── View+Extensions.swift
│   │
│   ├── Utils/
│   │   ├── Constants.swift
│   │   ├── Validators.swift
│   │   └── Formatters.swift
│   │
│   └── Enums/
│       ├── Gender.swift
│       ├── ActivityLevel.swift
│       ├── MealType.swift
│       ├── ExerciseType.swift
│       └── SleepStatus.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    ├── Config.plist                # API 키 등
    └── LaunchScreen.storyboard
```

### 1.3 레이어별 책임

| 레이어 | 책임 | 예시 |
|--------|------|------|
| **Presentation** | UI 렌더링, 사용자 입력 처리 | SwiftUI View, ViewModel |
| **Domain** | 비즈니스 로직, 규칙 | BMR 계산, 목표 검증 |
| **Data** | 데이터 저장/조회, 외부 API | Core Data, REST API |
| **Infrastructure** | 프레임워크 의존성 | HealthKit, Network |

### 1.4 의존성 규칙

```
Presentation → Domain ← Data
                 ↑
            Infrastructure
```

- **Presentation**은 Domain만 알고 있음
- **Data**는 Domain의 Protocol을 구현
- **Domain**은 외부 의존성 없음 (순수 Swift)

---

## 2. 학습 모드 개발 프로세스

### 2.1 프로세스 개요

```
┌─────────────────────────────────────────────────────────────────┐
│  1️⃣ 태스크 시작 전                                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Claude: "이 태스크에서 배울 Swift/iOS 개념들" 브리핑    │   │
│  │ - 핵심 개념 설명                                        │   │
│  │ - 관련 공식 문서 링크                                   │   │
│  │ - Java와 비교 (익숙한 개념 연결)                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  2️⃣ 코드 작성                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Claude: 코드 작성 + 학습 주석                           │   │
│  │ - 왜 이렇게 작성하는지                                  │   │
│  │ - Swift 특유의 패턴 설명                                │   │
│  │ - 주의할 점                                             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  3️⃣ 코드 리뷰 & Q&A                                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 승밍: 궁금한 부분 질문                                  │   │
│  │ Claude: 상세 설명 + 심화 개념 연결                      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  4️⃣ 복습 노트                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Claude: 학습 내용 요약 (블로그/노션용)                  │   │
│  │ - 오늘 배운 것                                          │   │
│  │ - 핵심 코드 스니펫                                      │   │
│  │ - 추가 학습 자료                                        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 학습 주석 컨벤션

```swift
// 📚 학습 포인트: [개념명]
// 이 코드에서 배울 핵심 개념

// 💡 Java 비교: 
// Java에서는 이렇게 했지만, Swift에서는...

// ⚠️ 주의:
// 실수하기 쉬운 부분

// 🔗 참고:
// 관련 문서나 추가 학습 자료

// ✅ 모범 사례:
// 이렇게 하는 게 Swift스러운 방식

// ❌ 안티 패턴:
// 이렇게 하면 안 되는 이유
```

### 2.3 예시: BMR 계산 UseCase

```swift
// 📚 학습 포인트: Protocol, Enum, 의존성 주입
// BMR(기초대사량) 계산 로직을 UseCase로 분리

import Foundation

// MARK: - Protocol 정의
// 📚 학습 포인트: Protocol
// Java의 interface와 비슷하지만 더 강력함
// - 프로퍼티 요구사항 정의 가능
// - extension으로 기본 구현 제공 가능

protocol CalculateBMRUseCaseProtocol {
    func execute(user: User, bodyRecord: BodyRecord) -> Double
}

// MARK: - UseCase 구현
// 📚 학습 포인트: final class
// final: 상속 불가 → 컴파일러 최적화 가능
// 💡 Java 비교: final class와 동일

final class CalculateBMRUseCase: CalculateBMRUseCaseProtocol {
    
    // MARK: - Execute
    /// BMR 계산 실행
    /// - Parameters:
    ///   - user: 사용자 정보 (성별, 나이)
    ///   - bodyRecord: 체성분 기록 (체중, 키, 체지방률)
    /// - Returns: BMR (kcal)
    func execute(user: User, bodyRecord: BodyRecord) -> Double {
        // 📚 학습 포인트: Optional Binding (if let)
        // 체지방률이 있으면 Katch-McArdle, 없으면 Mifflin-St Jeor
        // 💡 Java 비교: if (bodyFatPercent != null)
        
        if let bodyFatPercent = bodyRecord.bodyFatPercent {
            return calculateKatchMcArdle(
                weight: bodyRecord.weight,
                bodyFatPercent: bodyFatPercent
            )
        } else {
            return calculateMifflinStJeor(
                weight: bodyRecord.weight,
                height: user.height,
                age: user.age,
                gender: user.gender
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Katch-McArdle 공식 (체지방률 있을 때)
    /// BMR = 370 + (21.6 × 제지방량)
    private func calculateKatchMcArdle(weight: Double, bodyFatPercent: Double) -> Double {
        // 📚 학습 포인트: 연산자와 타입
        // Swift는 타입에 엄격 → Double끼리만 연산 가능
        // 💡 Java 비교: 자동 형변환 없음
        
        let leanBodyMass = weight * (1 - bodyFatPercent / 100)
        return 370 + (21.6 * leanBodyMass)
    }
    
    /// Mifflin-St Jeor 공식 (체지방률 없을 때)
    /// 남성: BMR = 10×체중 + 6.25×키 - 5×나이 + 5
    /// 여성: BMR = 10×체중 + 6.25×키 - 5×나이 - 161
    private func calculateMifflinStJeor(
        weight: Double,
        height: Double,
        age: Int,
        gender: Gender
    ) -> Double {
        // 📚 학습 포인트: switch 표현식
        // Swift의 switch는 표현식으로 사용 가능 (값 반환)
        // 💡 Java 비교: Java 14+ switch expression과 유사
        
        let base = 10 * weight + 6.25 * height - 5 * Double(age)
        
        // ✅ 모범 사례: switch는 모든 케이스 처리 필수 (exhaustive)
        let adjustment: Double = switch gender {
        case .male: 5
        case .female: -161
        }
        
        return base + adjustment
    }
}

// MARK: - Gender Enum
// 📚 학습 포인트: Enum with Raw Value
// 💡 Java 비교: Java enum보다 강력 - 연산 프로퍼티, 메서드 가능

enum Gender: Int, CaseIterable, Codable {
    case male = 0
    case female = 1
    
    // 📚 학습 포인트: Computed Property
    // 저장 공간 없이 계산되는 프로퍼티
    var displayName: String {
        switch self {
        case .male: "남성"
        case .female: "여성"
        }
    }
}
```

### 2.4 복습 노트 템플릿

```markdown
# 📝 학습 노트: [태스크 ID] [태스크명]

## 📅 날짜
2026-01-XX

## 🎯 오늘 배운 것

### 1. [개념 1]
- 설명
- 코드 예시
- Java와 비교

### 2. [개념 2]
- 설명
- 코드 예시

## 💻 핵심 코드

```swift
// 오늘 작성한 핵심 코드
```

## 🤔 어려웠던 점
- 

## 💡 깨달은 점
- 

## 📚 추가 학습 자료
- [공식 문서](링크)
- [관련 WWDC 세션](링크)

## ✅ 다음에 할 것
- 
```

---

## 3. 코딩 컨벤션

### 3.1 네이밍 규칙

| 종류 | 규칙 | 예시 |
|------|------|------|
| **타입** | UpperCamelCase | `BodyRecord`, `FoodRepository` |
| **변수/상수** | lowerCamelCase | `bodyFatPercent`, `dailyCalories` |
| **함수** | lowerCamelCase + 동사 | `calculateBMR()`, `fetchFoods()` |
| **프로토콜** | 형용사 or ~able/~Protocol | `Identifiable`, `BodyRepositoryProtocol` |
| **열거형 케이스** | lowerCamelCase | `.sedentary`, `.veryActive` |

### 3.2 파일 구조

```swift
// MARK: - [섹션명]

import Foundation
import SwiftUI

// MARK: - Protocol (있으면)

protocol SomeProtocol {
    // ...
}

// MARK: - Main Type

final class SomeClass {
    
    // MARK: - Properties
    
    private let dependency: SomeDependency
    @Published var state: State
    
    // MARK: - Initialization
    
    init(dependency: SomeDependency) {
        self.dependency = dependency
    }
    
    // MARK: - Public Methods
    
    func doSomething() {
        // ...
    }
    
    // MARK: - Private Methods
    
    private func helper() {
        // ...
    }
}

// MARK: - Extensions

extension SomeClass: SomeProtocol {
    // ...
}

// MARK: - Preview (SwiftUI)

#Preview {
    SomeView()
}
```

### 3.3 SwiftUI View 구조

```swift
struct SomeView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: SomeViewModel
    @State private var isPresented = false
    
    // MARK: - Body
    
    var body: some View {
        content
            .onAppear { viewModel.onAppear() }
            .sheet(isPresented: $isPresented) { sheetContent }
    }
    
    // MARK: - View Components
    
    private var content: some View {
        VStack {
            headerSection
            mainSection
            footerSection
        }
    }
    
    private var headerSection: some View {
        // ...
    }
    
    private var mainSection: some View {
        // ...
    }
}
```

### 3.4 SwiftLint 규칙

```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - closure_spacing
  - contains_over_first_not_nil
  - discouraged_object_literal
  - empty_string
  - first_where
  - modifier_order
  - operator_usage_whitespace
  - overridden_super_call
  - private_action
  - private_outlet
  - sorted_imports

line_length:
  warning: 120
  error: 150

file_length:
  warning: 400
  error: 500

type_body_length:
  warning: 300
  error: 400

function_body_length:
  warning: 40
  error: 60

identifier_name:
  min_length: 2
  max_length: 50
```

---

## 4. Git 브랜치 전략

### 4.1 브랜치 구조

```
main
  │
  ├── develop
  │     │
  │     ├── feature/TASK-001-project-setup
  │     ├── feature/TASK-010-onboarding-ui
  │     ├── feature/TASK-040-body-record
  │     └── ...
  │
  └── release/1.0.0
```

### 4.2 브랜치 네이밍

| 타입 | 패턴 | 예시 |
|------|------|------|
| **기능** | `feature/TASK-XXX-설명` | `feature/TASK-040-body-record` |
| **버그** | `bugfix/TASK-XXX-설명` | `bugfix/TASK-041-validation-fix` |
| **핫픽스** | `hotfix/설명` | `hotfix/crash-on-launch` |
| **릴리즈** | `release/버전` | `release/1.0.0` |

### 4.3 커밋 메시지

```
[TASK-XXX] 타입: 제목

본문 (선택)

타입:
- feat: 새 기능
- fix: 버그 수정
- refactor: 리팩토링
- docs: 문서
- style: 포맷팅
- test: 테스트
- chore: 기타
```

예시:
```
[TASK-043] feat: BMR/TDEE 계산 UseCase 구현

- Katch-McArdle 공식 구현 (체지방률 있을 때)
- Mifflin-St Jeor 공식 구현 (체지방률 없을 때)
- 단위 테스트 추가
```

---

## 5. 테스트 전략

### 5.1 테스트 피라미드

```
        ┌───────────┐
        │    UI     │  ← 적게 (주요 플로우만)
        │   Tests   │
        ├───────────┤
        │Integration│  ← 중간 (Repository)
        │   Tests   │
        ├───────────┤
        │   Unit    │  ← 많이 (UseCase, Service)
        │   Tests   │
        └───────────┘
```

### 5.2 테스트 대상

| 레이어 | 테스트 대상 | 예시 |
|--------|------------|------|
| **Domain** | UseCase 로직 | BMR 계산 정확성 |
| **Data** | Repository 동작 | CRUD 정상 동작 |
| **Presentation** | ViewModel 상태 | 입력 검증 |

### 5.3 테스트 네이밍

```swift
func test_[메서드명]_[조건]_[기대결과]() {
    // given
    // when
    // then
}

// 예시
func test_calculateBMR_withBodyFatPercent_returnsKatchMcArdleResult() {
    // given
    let useCase = CalculateBMRUseCase()
    let user = User(gender: .male, age: 30, height: 175)
    let bodyRecord = BodyRecord(weight: 70, bodyFatPercent: 15)
    
    // when
    let result = useCase.execute(user: user, bodyRecord: bodyRecord)
    
    // then
    XCTAssertEqual(result, 1656.2, accuracy: 0.1)
}
```

---

*문서 버전: 1.0*
*작성일: 2026-01-11*

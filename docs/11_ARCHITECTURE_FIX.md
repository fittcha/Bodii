# Bodii 아키텍처 문제점 분석 및 수정 가이드

## 문서 개요
- **작성일**: 2026-01-19
- **목적**: 대량 빌드 오류의 근본 원인 분석 및 아키텍처 수정 방향 정의
- **대상**: 모든 개발자 (Auto-Claude 포함)

---

## 1. 근본 원인 분석

### 1.1 Core Data vs Domain Model 혼란 (가장 중요)

**문제 상황**:
```
Core Data (codeGenerationType="class")
├── User (NSManagedObject)        ← 자동 생성 클래스
├── Food (NSManagedObject)        ← 자동 생성 클래스
├── BodyRecord (NSManagedObject)  ← 자동 생성 클래스
└── ...

코드에서 기대하는 타입:
├── User (struct with initializer) ← 존재하지 않음!
├── Food (struct with initializer) ← 존재하지 않음!
└── ...
```

**증상**:
- `Argument passed to call that takes no arguments` (struct initializer 기대)
- `Cannot assign to property 'x' on immutable value` (struct 기대)
- `Invalid redeclaration of 'X'` (중복 정의 시도)

**근본 원인**:
Core Data의 `codeGenerationType="class"`가 자동으로 NSManagedObject 서브클래스를 생성하지만,
코드에서는 일반 Swift struct의 memberwise initializer를 기대함.

### 1.2 타입 불일치 (NSDecimalNumber vs Decimal, Optional vs Non-Optional)

**Core Data 엔티티의 실제 타입**:
```swift
// Core Data 자동 생성
class Food: NSManagedObject {
    @NSManaged public var name: String?          // Optional!
    @NSManaged public var calories: NSDecimalNumber?  // NSDecimalNumber!
    @NSManaged public var protein: NSDecimalNumber?
    @NSManaged public var date: Date?           // Optional!
}
```

**코드에서 기대하는 타입**:
```swift
// 기대하는 struct
struct Food {
    let name: String           // Non-optional
    let calories: Decimal      // Decimal
    let protein: Decimal
    let date: Date            // Non-optional
}
```

### 1.3 Mapper 설계 결함

**기존 Mapper 패턴 (문제)**:
```swift
func mapToBodyRecord(from sample: HKQuantitySample) -> BodyRecord {
    // ❌ Core Data 엔티티를 직접 반환하려 하지만
    // NSManagedObjectContext 없이는 생성 불가!
    return BodyRecord(...)  // 컴파일 오류
}
```

**수정된 Mapper 패턴 (DTO 사용)**:
```swift
// 1단계: HK → DTO
func mapToBodyDataDTO(from sample: HKQuantitySample) -> BodyDataDTO {
    return BodyDataDTO(
        date: sample.startDate,
        weight: Decimal(sample.quantity.doubleValue(for: .gram())),
        ...
    )
}

// 2단계: DTO → Core Data Entity (context 필요)
func createBodyRecord(from dto: BodyDataDTO, context: NSManagedObjectContext) -> BodyRecord {
    let record = BodyRecord(context: context)
    record.date = dto.date
    record.weight = NSDecimalNumber(decimal: dto.weight)
    return record
}
```

### 1.4 워크트리 동기화 문제

병렬 워크트리 작업 시:
- 각 워크트리가 독립적으로 파일 추가
- project.pbxproj 충돌 시 불완전한 병합
- 타입 정의 중복 또는 누락

---

## 2. 아키텍처 수정 방향

### 2.1 3단계 데이터 변환 패턴 (권장)

```
[외부 데이터]     [내부 DTO]      [Core Data Entity]
HKSample    ──→   DataDTO    ──→   NSManagedObject
API Response ──→              ──→
                              ↑
                     NSManagedObjectContext 필요
```

**구현 예시**:
```swift
// Data/DTOs/BodyDataDTO.swift
struct BodyDataDTO {
    let date: Date
    let weight: Decimal
    let bodyFatMass: Decimal?
    let bodyFatPercent: Decimal?
    let muscleMass: Decimal?
    let healthKitId: String?
}

// Data/Mappers/HealthKitMapper.swift
struct HealthKitMapper {
    // Phase 1: External → DTO
    func mapToBodyDataDTO(from sample: HKQuantitySample) -> BodyDataDTO { ... }

    // Phase 2: DTO → Core Data (requires context)
    func createBodyRecord(from dto: BodyDataDTO, context: NSManagedObjectContext) -> BodyRecord { ... }
}
```

### 2.2 Core Data 속성 접근 규칙

**필수 패턴: Optional 처리**
```swift
// ❌ 잘못된 코드
let weight = record.weight  // NSDecimalNumber? → 바로 사용 불가

// ✅ 올바른 코드
let weight = record.weight?.decimalValue ?? Decimal.zero
```

**필수 패턴: NSDecimalNumber 변환**
```swift
// Core Data에서 읽기
let decimalValue: Decimal = nsDecimalNumber?.decimalValue ?? .zero

// Core Data에 쓰기
record.weight = NSDecimalNumber(decimal: decimalValue)
```

### 2.3 Preview/Mock에서의 Core Data 사용

```swift
// ❌ 잘못된 코드 - Food struct initializer 기대
let sampleFood = Food(name: "사과", calories: 52, ...)

// ✅ 올바른 코드 - Core Data context 사용
let context = PersistenceController.preview.container.viewContext
let sampleFood = Food(context: context)
sampleFood.name = "사과"
sampleFood.calories = NSDecimalNumber(value: 52)
```

---

## 3. 수정 완료 목록 (2026-01-19)

### 3.1 Mapper 수정 완료
| 파일 | 수정 내용 |
|------|-----------|
| `Data/Mappers/HealthKitMapper.swift` | DTO 패턴 도입, context 기반 엔티티 생성 |
| `Data/Mappers/USDAFoodMapper.swift` | NSDecimalNumber 변환 수정 |
| `Data/Mappers/KFDAFoodMapper.swift` | NSDecimalNumber 변환 수정 |
| `Data/Mappers/MetabolismSnapshotMapper.swift` | context 파라미터 추가 |
| `Data/Mappers/SleepRecordMapper.swift` | Int16 ↔ enum 변환 수정 |

### 3.2 HealthKit 수정 완료
| 파일 | 수정 내용 |
|------|-----------|
| `Infrastructure/HealthKit/HealthKitDataTypes.swift` | CaseIterable 추가, hkCategoryType alias |
| `Infrastructure/HealthKit/HealthKitBackgroundSync.swift` | String→UUID 변환, 중복 extension 제거 |
| `Infrastructure/HealthKit/HealthKitReadService.swift` | 타입 정리 |

### 3.3 Service/UseCase 수정 완료
| 파일 | 수정 내용 |
|------|-----------|
| `Domain/Services/LocalFoodSearchService.swift` | context 파라미터 추가 |
| `Domain/Services/TrendProjectionService.swift` | NSDecimalNumber→Decimal 변환 |
| `Domain/Services/NutritionCalculator.swift` | Decimal→Int32 변환 수정 |
| `Domain/UseCases/Exercise/DeleteExerciseRecordUseCase.swift` | userId 접근, date unwrap 수정 |

### 3.4 View/ViewModel 수정 완료
| 파일 | 수정 내용 |
|------|-----------|
| `Presentation/Features/Dashboard/DashboardView.swift` | Decimal→NSNumber 변환, optional 처리 |
| `Presentation/Features/PhotoRecognition/Views/FoodMatchCard.swift` | optional 처리 |
| `Presentation/Features/PhotoRecognition/Models/EditedFoodItem.swift` | multiplier 계산 수정 |
| `Presentation/Features/Diet/ViewModels/FoodDetailViewModel.swift` | servingSize 타입 변환 |
| `Presentation/Features/Diet/Views/FoodDetailView.swift` | optional String, NSDecimalNumber 처리 |
| `Presentation/Components/Charts/SleepBarChart.swift` | BarMark .overlay → .annotation |

### 3.5 DataSource 수정 완료
| 파일 | 수정 내용 |
|------|-----------|
| `Data/DataSources/Local/SleepLocalDataSource.swift` | nil → 0 (Int32/Int16 non-optional) |

### 3.6 새 파일 생성
| 파일 | 내용 |
|------|------|
| `Presentation/Components/BodyCompositionInputCard.swift` | 체성분 입력 카드 UI 컴포넌트 |

### 3.7 KFDA 음식 데이터 로컬 검색 시스템 (2026-02-04~05)

KFDA API의 검색 품질 문제 (예: "꿀" 검색 시 1000번째 이후에야 관련 결과 반환)를 해결하기 위해,
전체 KFDA 음식 데이터를 앱 번들에 JSON으로 포함하고 로컬에서 연관성 기반 검색하는 시스템 구축.

| 파일 | 수정/생성 | 내용 |
|------|-----------|------|
| `scripts/download_kfda_foods.py` | 생성 | KFDA API v2에서 전체 250,110개 음식 데이터 다운로드 스크립트 |
| `Bodii/Resources/kfda_foods.json` | 생성 | 250,110개 KFDA 음식 데이터 (63.9MB, .gitignore에 추가) |
| `Data/DataSources/Local/KFDAFoodImporter.swift` | 생성 | 번들 JSON → Core Data 배치 임포트 (500개 단위, 버전 기반 시딩) |
| `Infrastructure/Persistence/PersistenceController.swift` | 수정 | 앱 시작 시 KFDAFoodImporter 호출, SampleFoods 폴백 |
| `Data/Repositories/FoodRepository.swift` | 수정 | 연관성 점수 기반 검색 (정확일치 100 > 접두사 80 > 단어경계 60 > 부분일치 40) |
| `Domain/Services/LocalFoodSearchService.swift` | 수정 | stable sort로 FoodRepository 연관성 순서 보존 |
| `.gitignore` | 수정 | `Bodii/Resources/kfda_foods.json` 추가 (63.9MB는 git에 부적합) |

**데이터 흐름**:
```
앱 첫 실행 → PersistenceController → KFDAFoodImporter
  → Bundle.main의 kfda_foods.json (250,110개)
  → Core Data 배치 삽입 (500개/배치, 백그라운드 컨텍스트)

검색 "꿀" → LocalFoodSearchService → FoodRepository.search()
  → Core Data CONTAINS[cd] 쿼리 (fetchLimit 200)
  → 연관성 점수 정렬 → 상위 50개 반환
  → (결과 5개 이상이면 API 폴백 생략)
```

**JSON 재생성 방법**:
```bash
python3 scripts/download_kfda_foods.py --api-key <KFDA_API_KEY> --all
```

---

## 4. 남은 수정 필요 사항

### 4.1 우선순위 높음 - Core Data 타입 변환

다음 파일들에서 NSDecimalNumber/Optional 처리 필요:
- [ ] `Presentation/Features/Sleep/SleepRecordRow.swift`
- [ ] `Presentation/Features/Dashboard/DashboardViewModel.swift`
- [ ] `Presentation/Features/Exercise/Views/ExerciseListView.swift`
- [ ] `Presentation/Features/Goal/ViewModels/GoalProgressViewModel.swift`
- [ ] `Data/Repositories/SleepRepository.swift`
- [ ] `Data/Repositories/BodyRepository.swift`

### 4.2 우선순위 중간 - Mock 클래스 업데이트

프로토콜 변경으로 Mock 클래스 수정 필요:
- [ ] `MockDailyLogRepository`
- [ ] `MockFoodRepository`
- [ ] `MockExerciseRecordRepository`
- [ ] `MockSleepRepository`
- [ ] `MockBodyRepository`

### 4.3 우선순위 낮음 - Preview 데이터 수정

Core Data context 기반으로 샘플 데이터 생성 수정:
- [ ] `Data/SampleData/SampleFoods.swift`
- [ ] 각 View의 `#Preview` 섹션

---

## 5. 개발 규칙 (앞으로 준수)

### 5.1 Core Data 엔티티 직접 생성 금지

```swift
// ❌ 절대 금지
let food = Food(name: "사과", ...)

// ✅ 반드시 context 사용
let food = Food(context: context)
food.name = "사과"
```

### 5.2 DTO 우선 패턴

외부 데이터 → DTO → Core Data Entity 순서 준수

### 5.3 타입 변환 헬퍼 사용

```swift
// Shared/Extensions/CoreDataHelpers.swift에 정의
extension NSDecimalNumber {
    var safeDecimalValue: Decimal {
        return self.decimalValue
    }
}

extension Optional where Wrapped == NSDecimalNumber {
    var decimalOrZero: Decimal {
        return self?.decimalValue ?? .zero
    }
}
```

### 5.4 새 파일 생성 전 확인

```bash
# 기존 타입/파일 확인
grep -r "struct Food" Bodii/
grep -r "class Food" Bodii/
find Bodii -name "Food*.swift"
```

---

## 6. 태스크 진행 현황 업데이트

| 태스크 ID | 상태 | 비고 |
|-----------|------|------|
| TASK-001 | ✅ 완료 | Xcode 프로젝트 생성 |
| TASK-002 | ✅ 완료 | Core Data 모델 설정 |
| TASK-003 | ✅ 완료 | 앱 아키텍처 설정 |
| TASK-070~072 | 🔧 진행중 | HealthKit 연동 (빌드 오류 수정 중) |
| TASK-040~044 | 🔧 진행중 | 체성분 관리 (빌드 오류 수정 중) |
| TASK-050~056 | 🔧 진행중 | 식단 관리 (빌드 오류 수정 중) |
| TASK-060~063 | 🔧 진행중 | 운동 관리 (빌드 오류 수정 중) |
| TASK-075~078 | 🔧 진행중 | 수면 관리 (빌드 오류 수정 중) |
| TASK-030~031 | 🔧 진행중 | 대시보드 (빌드 오류 수정 중) |
| TASK-110~112 | 🔧 진행중 | 목표 관리 (빌드 오류 수정 중) |

**현재 상태**: 기능 구현은 대부분 완료되었으나, 아키텍처 혼란으로 인한 빌드 오류 수정 중

---

*문서 버전: 1.1*
*최종 수정: 2026-02-05*

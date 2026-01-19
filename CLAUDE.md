
## 참고 문서
프로젝트 기획 문서들이 docs/ 폴더에 있습니다:
- docs/01_PRD.md - 제품 요구사항
- docs/02_FEATURE_SPEC.md - 기능 명세
- docs/04_ERD.md - 데이터 모델
- docs/05_TASKS.md - 태스크 목록 (이 순서대로 구현)
- docs/06_ALGORITHM.md - BMR/TDEE 계산 공식
- docs/08_EDGE_CASES.md - 예외 처리
- **docs/11_ARCHITECTURE_FIX.md - 아키텍처 문제 분석 및 수정 가이드 (중요!)**

태스크 생성 시 docs/05_TASKS.md를 참고하세요.

---

## 아키텍처 핵심 규칙 (2026-01-19 정리)

### 1. Core Data는 `codeGenerationType="class"` 사용 중

Core Data가 자동 생성하는 NSManagedObject 서브클래스:
- `User`, `Food`, `BodyRecord`, `ExerciseRecord`, `SleepRecord`, `DailyLog`, `Goal`, `FoodRecord`, `MetabolismSnapshot`

**절대 금지**: Domain/Entities/에 위 이름과 동일한 struct 생성

### 2. 3단계 데이터 변환 패턴 (필수)

```
[외부 데이터]     [DTO]           [Core Data Entity]
HKSample    ──→   DataDTO    ──→   NSManagedObject
API Response ──→              ──→
                              ↑
                     NSManagedObjectContext 필수!
```

**올바른 패턴**:
```swift
// Phase 1: 외부 데이터 → DTO
func mapToBodyDataDTO(from sample: HKQuantitySample) -> BodyDataDTO

// Phase 2: DTO → Core Data Entity (context 필수)
func createBodyRecord(from dto: BodyDataDTO, context: NSManagedObjectContext) -> BodyRecord
```

### 3. Core Data 타입 변환 규칙

```swift
// NSDecimalNumber → Decimal 읽기
let value: Decimal = record.weight?.decimalValue ?? .zero

// Decimal → NSDecimalNumber 쓰기
record.weight = NSDecimalNumber(decimal: value)

// Int16 → enum
let status = SleepStatus(rawValue: Int(record.status)) ?? .good

// enum → Int16
record.status = Int16(status.rawValue)
```

### 4. Preview/Sample 데이터 생성

```swift
// ❌ 금지: struct initializer 사용
let food = Food(name: "사과", calories: 52)

// ✅ 필수: Core Data context 사용
let context = PersistenceController.preview.container.viewContext
let food = Food(context: context)
food.name = "사과"
food.calories = NSDecimalNumber(value: 52)
```

---

## Git 워크트리 작업 규칙 (필수)

### 1. 작업 시작 전 (매번 반드시)
```bash
# main 브랜치 최신화
git fetch origin
git checkout main
git pull origin main

# 워크트리 브랜치에서 main 병합
git checkout <worktree-branch>
git merge main
# 충돌 발생 시 main 기준으로 해결
```

### 2. 커밋/푸시 전 (매번 반드시)
```bash
# 빌드 확인 (Xcode에서 Cmd+B)
# 프로젝트 파일 유효성 검사
plutil -lint Bodii.xcodeproj/project.pbxproj

# main과 동기화 확인
git fetch origin
git merge origin/main
# 충돌 시 main 기준으로 해결
```

### 3. 충돌 해결 원칙
- **project.pbxproj 충돌**: main 버전 사용 후, 필요한 파일만 Xcode에서 다시 추가
- **Swift 파일 충돌**: main 버전 우선, 워크트리 변경사항을 수동으로 적용
- **문서 충돌**: main 버전 우선

---

## 빌드 오류 방지 규칙 (필수)

### 1. Core Data 엔티티 이름 충돌 방지
**문제**: Core Data가 `codeGenerationType="class"`로 자동 생성하는 클래스와 도메인 struct 이름 충돌
**방지책**:
- Core Data 엔티티 이름: `User`, `Food`, `ExerciseRecord` 등 (자동 생성)
- 도메인 struct는 다른 이름 사용: `UserModel`, `FoodModel` 등
- 또는 Core Data `codeGenerationType="Manual/None"`으로 변경

**금지 사항**:
- `Bodii/Domain/Entities/`에 Core Data 엔티티와 동일한 이름의 struct 생성 금지
  - 금지: `User.swift`, `ExerciseRecord.swift`, `Food.swift`, `FoodRecord.swift`, `Goal.swift`, `DailyLog.swift`, `SleepRecord.swift`, `BodyRecord.swift`, `MetabolismSnapshot.swift`

### 2. 파일 중복 방지
**문제**: 같은 이름의 파일이 여러 위치에 존재하면 빌드 오류 발생
**방지책**:
- 새 파일 생성 전 `find Bodii -name "파일명.swift"` 로 중복 확인
- Enum은 `Shared/Enums/`에만 정의
- Utils는 `Shared/Utils/`에만 정의
- Repository Protocol은 `Domain/Interfaces/`에만 정의
- Repository Impl은 `Data/Repositories/` 또는 `Infrastructure/Repositories/`에만 정의

### 3. 타입 중복 선언 방지
**문제**: `RepositoryError`, `ValidationErrors` 등이 여러 파일에서 중복 선언
**방지책**:
- 공용 Error 타입은 `Shared/Errors/` 폴더에 단일 파일로 정의
- 새로운 Error 타입 생성 전 기존 정의 확인: `grep -r "enum.*Error" Bodii/`

### 4. Xcode 프로젝트 파일 관리
**문제**: project.pbxproj 파일 손상 또는 파일 누락
**방지책**:
- 파일 추가/삭제는 반드시 Xcode를 통해 수행
- 프로젝트 저장 후 유효성 검사: `plutil -lint Bodii.xcodeproj/project.pbxproj`
- 빌드 전 항상 `Product → Clean Build Folder` (Cmd+Shift+K)

### 5. Mock/Preview 클래스 프로토콜 준수
**문제**: Mock 클래스가 프로토콜 변경사항을 반영하지 않아 빌드 오류
**방지책**:
- 프로토콜 수정 시 해당 프로토콜을 구현하는 모든 Mock 클래스도 함께 수정
- `grep -r "class Mock.*Protocol" Bodii/` 로 Mock 클래스 목록 확인

---

## 수정 완료 현황 (2026-01-19)

### 완료된 수정
| 카테고리 | 파일 | 수정 내용 |
|----------|------|-----------|
| Mapper | `HealthKitMapper.swift` | DTO 패턴 도입, context 기반 엔티티 생성 |
| Mapper | `USDAFoodMapper.swift` | NSDecimalNumber 변환 |
| Mapper | `KFDAFoodMapper.swift` | NSDecimalNumber 변환 |
| Mapper | `MetabolismSnapshotMapper.swift` | context 파라미터 추가 |
| Mapper | `SleepRecordMapper.swift` | Int16 ↔ enum 변환 |
| HealthKit | `HealthKitDataTypes.swift` | CaseIterable, hkCategoryType |
| HealthKit | `HealthKitBackgroundSync.swift` | String→UUID, 중복 extension 제거 |
| Service | `LocalFoodSearchService.swift` | context 파라미터 |
| Service | `TrendProjectionService.swift` | NSDecimalNumber→Decimal |
| Service | `NutritionCalculator.swift` | Decimal→Int32 |
| UseCase | `DeleteExerciseRecordUseCase.swift` | userId, date 처리 |
| View | `DashboardView.swift` | Decimal→NSNumber, optional |
| View | `FoodMatchCard.swift` | optional 처리 |
| View | `FoodDetailView.swift` | optional String, NSDecimalNumber |
| View | `SleepBarChart.swift` | BarMark .annotation |
| ViewModel | `FoodDetailViewModel.swift` | servingSize 타입 |
| Model | `EditedFoodItem.swift` | multiplier 계산 |
| DataSource | `SleepLocalDataSource.swift` | nil → 0 |
| Component | `BodyCompositionInputCard.swift` | 신규 생성 |

### 남은 작업
자세한 내용은 `docs/11_ARCHITECTURE_FIX.md` 참조

**우선순위 높음**:
- [ ] SleepRecordRow.swift - 타입 변환
- [ ] DashboardViewModel.swift - Mock 클래스
- [ ] ExerciseListView.swift - Mock 클래스
- [ ] GoalProgressViewModel.swift - 타입 변환
- [ ] SleepRepository.swift - 타입 변환
- [ ] BodyRepository.swift - 타입 변환

**우선순위 중간**:
- [ ] Mock 클래스 전체 업데이트
- [ ] SampleFoods.swift - Core Data context 사용

---

## 파일 구조 규칙

```
Bodii/
├── App/                    # 앱 진입점, DI 컨테이너
├── Domain/
│   ├── Entities/          # 도메인 모델 (Core Data와 이름 충돌 금지!)
│   ├── UseCases/          # 비즈니스 로직
│   └── Interfaces/        # Repository 프로토콜
├── Data/
│   ├── Repositories/      # Repository 구현체
│   ├── DataSources/       # Local/Remote 데이터 소스
│   ├── DTOs/              # 데이터 전송 객체 ← HealthKitMapper DTO 등
│   └── Mappers/           # 엔티티 변환 (DTO 패턴 사용!)
├── Infrastructure/
│   ├── Persistence/       # Core Data (Bodii.xcdatamodeld)
│   ├── HealthKit/         # HealthKit 연동
│   └── Network/           # 네트워크 설정
├── Presentation/
│   ├── Features/          # 화면별 View/ViewModel
│   └── Components/        # 공용 UI 컴포넌트
├── Shared/
│   ├── Enums/            # 공용 Enum (단일 정의!)
│   ├── Extensions/       # Swift Extensions
│   ├── Utils/            # 유틸리티 (단일 정의!)
│   └── Errors/           # 공용 Error 타입 (단일 정의!)
└── Resources/            # 에셋, 설정 파일
```

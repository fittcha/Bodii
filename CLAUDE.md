
## 참고 문서
프로젝트 기획 문서들이 docs/ 폴더에 있습니다:
- docs/01_PRD.md - 제품 요구사항
- docs/02_FEATURE_SPEC.md - 기능 명세
- docs/04_ERD.md - 데이터 모델
- docs/05_TASKS.md - 태스크 목록 (이 순서대로 구현)
- docs/06_ALGORITHM.md - BMR/TDEE 계산 공식
- docs/08_EDGE_CASES.md - 예외 처리

태스크 생성 시 docs/05_TASKS.md를 참고하세요.

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

## 긴급 수정 필요 사항 (2024-01-18 기준)

### 우선순위 1: Core Data/Domain 타입 충돌
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `Domain/Entities/User.swift` | Invalid redeclaration of 'User' | Core Data 자동 생성 User 클래스와 충돌 | 삭제 완료 (Core Data 클래스 사용) |
| `Domain/Entities/ExerciseRecord.swift` | 'ExerciseRecord' is ambiguous | Core Data 자동 생성 클래스와 충돌 | 삭제 완료 (Core Data 클래스 사용) |

### 우선순위 2: 타입 중복 선언
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `Data/Repositories/FoodRepository.swift:383` | Invalid redeclaration of 'RepositoryError' | 여러 파일에서 RepositoryError 중복 정의 | 하나의 파일로 통합 |
| `Presentation/.../ManualFoodEntryViewModel.swift:391` | Invalid redeclaration of 'ValidationErrors' | 여러 파일에서 ValidationErrors 중복 정의 | 하나의 파일로 통합 |
| `Domain/Services/NutritionCalculator.swift:338` | Invalid redeclaration of 'rounded' | Decimal extension 중복 | 하나의 파일로 통합 |

### 우선순위 3: Food 타입 초기화 문제
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `Data/SampleData/SampleFoods.swift` (다수) | Argument passed to call that takes no arguments | Food 초기화 인자가 Core Data 클래스와 불일치 | Core Data Food 엔티티 사용 방식으로 변경 |
| 여러 Preview/Component 파일들 | Cannot infer contextual base in reference to member | FoodSource 등 enum 참조 실패 | import 확인 및 전체 경로 사용 |

### 우선순위 4: 프로토콜 불일치
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `DashboardViewModel.swift:573` | MockDailyLogRepository does not conform to DailyLogRepository | Mock 클래스가 최신 프로토콜 미반영 | Mock 클래스 업데이트 |
| `DailyMealView.swift:419` | MockFoodRepository does not conform to FoodRepositoryProtocol | 메서드 시그니처 불일치 | search(by:) → search(name:) 수정 |
| `ExerciseListView.swift:633` | MockExerciseRecordRepository does not conform | Mock 클래스 프로토콜 미준수 | Mock 클래스 업데이트 |
| 기타 Mock 클래스들 | does not conform to protocol | 프로토콜 변경 미반영 | 각 Mock 클래스 프로토콜 메서드 구현 |

### 우선순위 5: SwiftUI ViewBuilder 오류
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| 여러 View 파일들 | Cannot use explicit 'return' statement in ViewBuilder | SwiftUI ViewBuilder에서 return 사용 불가 | return 키워드 제거 |

### 우선순위 6: Optional/타입 오류
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `FoodEntity+CoreData.swift:74` | Optional type must be unwrapped | Date? 타입 언래핑 필요 | ?? 또는 guard let 사용 |
| `HealthKitSyncService.swift:198` | does not conform to 'Error' | 잘못된 에러 throw | HealthKitError 생성 방식 수정 |
| `RecordSleepUseCase.swift:84` | Cannot convert Int16 to SleepStatus | 타입 변환 필요 | SleepStatus(rawValue:) 사용 |

### 우선순위 7: API/프로토콜 메서드 누락
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `KFDAFoodAPIService.swift:153` | has no member 'buildKFDAURL' | APIConfigProtocol에 메서드 누락 | 프로토콜에 메서드 추가 또는 구현 변경 |

### 우선순위 8: 기타
| 파일 | 오류 | 원인 | 해결 방법 |
|------|------|------|-----------|
| `WeightTrendChart.swift:720` | unable to type-check expression | 표현식이 너무 복잡 | 표현식을 여러 변수로 분리 |
| `FoodWithQuantity.swift:94` | Cannot find type 'CalculatedNutrition' | 타입 정의 누락 | 타입 정의 추가 또는 import 확인 |
| `GetGoalProgressUseCase.swift:284` | Property uses internal type | 접근 제어자 불일치 | public → internal 변경 또는 타입 공개 |

---

## 내일 작업 순서

1. **main 브랜치에서 오류 수정** (위 우선순위 순서대로)
2. **빌드 성공 확인** (`plutil -lint` + Xcode 빌드)
3. **main에 커밋/푸시**
4. **워크트리 브랜치 업데이트**
   ```bash
   git checkout <worktree-branch>
   git merge main
   ```
5. **개발 작업 재개**

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
│   ├── DTOs/              # 데이터 전송 객체
│   └── Mappers/           # 엔티티 변환
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

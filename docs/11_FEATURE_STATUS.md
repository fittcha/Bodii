# Bodii 기능 현황 목록 (PRD 기준)

> 작성일: 2026-01-20
> 기준 문서: 01_PRD.md, 02_FEATURE_SPEC.md, 05_TASKS.md

---

## Phase 1: MVP (기본 추적 시스템)

### 1. 체성분 관리

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **1.1 체성분 입력** | 키, 몸무게, 체지방량, 체지방률, 골격근량, 측정일 입력 | ✅ 완료 | BodyCompositionView, BodyRecordDetailView |
| **1.2 체지방 자동 계산** | 체지방량/체지방률 상호 자동 계산 | ✅ 완료 | NutritionCalculator |
| **1.3 체성분 히스토리** | 기록 목록, 수정/삭제 | ✅ 완료 | BodyCompositionView |
| **1.4 체성분 그래프** | 라인 차트, 기간 필터 | ✅ 완료 | BodyTrendsView, WeightTrendChart, BodyFatTrendChart |
| **1.5 User.current* 업데이트** | 최신 체성분으로 User 자동 업데이트 | ✅ 완료 | BodyRepository |

### 2. 기초/활동 대사량 계산

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **2.1 BMR 계산 (Katch-McArdle)** | 체지방률 있을 때 | ✅ 완료 | CalculateBMRUseCase |
| **2.2 BMR 계산 (Mifflin-St Jeor)** | 체지방률 없을 때 | ✅ 완료 | CalculateBMRUseCase |
| **2.3 TDEE 계산** | BMR × 활동계수 | ✅ 완료 | CalculateTDEEUseCase |
| **2.4 MetabolismSnapshot 생성** | 체성분 입력 시 자동 생성 | ✅ 완료 | MetabolismSnapshotMapper |
| **2.5 활동 수준 설정** | 5단계 활동계수 | ✅ 완료 | UserProfileSettingsView |

### 3. 음식 기록

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **3.1 음식 검색** | 식약처 + USDA 통합 검색 | ✅ 완료 | UnifiedFoodSearchService, KFDAFoodAPIService, USDAFoodAPIService |
| **3.2 음식 직접 입력** | DB에 없는 음식 입력 | ✅ 완료 | ManualFoodEntryView |
| **3.3 일일 식단 조회** | 끼니별 그룹핑, 합계 | ✅ 완료 | DailyMealView |
| **3.4 매크로 시각화** | 탄/단/지 비율 원 그래프 | ✅ 완료 | MacroRatioChart |
| **3.5 섭취 칼로리 그래프** | 일별 추이 | ✅ 완료 | Dashboard에서 표시 |
| **3.6 AI 식단 코멘트** | Gemini API 연동, 목표 칼로리 기반 평가 | ✅ 완료 | GeminiService, DietCommentPopupView |
| **3.7 DailyLog 연쇄 업데이트** | 음식 추가/삭제 시 | ✅ 완료 | FoodRecordService |
| **3.8 식단 기록 수정** | 기존 기록 수량/단위/끼니 수정 | ✅ 완료 | FoodDetailView (수정 모드), FoodRecordService.updateFoodRecord |

### 4. 운동 기록

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **4.1 운동 입력** | 종류, 시간, 강도, 날짜 | ✅ 완료 | ExerciseInputView |
| **4.2 MET 기반 칼로리 계산** | MET × 체중 × 시간 | ✅ 완료 | ExerciseCalcService |
| **4.3 운동 히스토리** | 기록 목록 | ✅ 완료 | ExerciseListView |
| **4.4 DailyLog 연쇄 업데이트** | 운동 추가/삭제 시 | ✅ 완료 | ExerciseRecordService |

### 5. Apple HealthKit 연동

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **5.1 권한 요청** | HealthKit Capability | ✅ 완료 | HealthKitAuthorizationService |
| **5.2 데이터 읽기** | 걸음 수, 활동 칼로리, 운동, 체중 | ✅ 완료 | HealthKitReadService |
| **5.3 데이터 쓰기** | 체중, 체지방률, 식이 칼로리 | ✅ 완료 | HealthKitWriteService |
| **5.4 백그라운드 동기화** | 앱 실행 시 또는 수동 | ✅ 완료 | HealthKitBackgroundSync |
| **5.5 운동 중복 처리** | healthKitId로 확인 | ✅ 완료 | HealthKitMapper |

### 6. 수면 관리

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **6.1 수면 입력 팝업** | 새벽 2시 이후 첫 실행 시 | ⚠️ 부분 | SleepInputSheet 있음, 자동 팝업 로직 미확인 |
| **6.2 하루 기준 로직** | 02:00 ~ 다음날 02:00 | ✅ 완료 | DateUtils |
| **6.3 "나중에" 버튼** | 최대 3회 재팝업 | ⚠️ 미확인 | AppStateService 필요 |
| **6.4 수면 상태 계산** | 5단계 (Bad~Oversleep) | ✅ 완료 | SleepStatus enum |
| **6.5 수면 히스토리** | 목록, 수정 | ✅ 완료 | SleepHistoryView |
| **6.6 수면 그래프** | 바 차트, 기간 필터, 평균선 | ✅ 완료 | SleepTrendsView, SleepBarChart |
| **6.7 DailyLog 연쇄 업데이트** | 수면 입력 시 | ✅ 완료 | SleepRepository |

### 7. 대시보드

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **7.1 일일 요약** | 섭취 칼로리/TDEE, 남은 칼로리 | ✅ 완료 | DashboardView |
| **7.2 매크로 현황** | 탄/단/지 비율 | ✅ 완료 | MacroBreakdownCard |
| **7.3 운동 요약** | 소모 칼로리 | ✅ 완료 | ExerciseSummaryCard |
| **7.4 수면 상태** | 색상 아이콘 | ✅ 완료 | SleepDisplayCard, SleepQualityCard |
| **7.5 체성분 요약** | 최신 체중 | ✅ 완료 | BodyCompositionCard |
| **7.6 날짜 네비게이션** | 좌우 이동 | ✅ 완료 | DateNavigationHeader |

### 8. 온보딩

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **8.1 온보딩 PageView** | 앱 소개 화면들 | ✅ 완료 | OnboardingContainerView, WelcomeView |
| **8.2 기본 정보 입력** | 이름, 성별, 생년월일 | ✅ 완료 | BasicInfoInputView |
| **8.3 체성분 입력** | 키, 몸무게 | ✅ 완료 | BodyInfoInputView |
| **8.4 활동 수준 선택** | 5단계 | ✅ 완료 | ActivityLevelSelectView |
| **8.5 온보딩 완료 플래그** | UserDefaults 저장 | ✅ 완료 | AppStateService |

### 9. 설정

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **9.1 설정 화면 UI** | 설정 목록 | ✅ 완료 | SettingsView |
| **9.2 프로필 수정** | 키, 생년월일, 성별, 활동수준 | ✅ 완료 | UserProfileSettingsView |
| **9.3 HealthKit 토글** | 연동 on/off | ✅ 완료 | HealthKitSettingsViewModel |
| **9.4 권한 거부 안내** | 설정 앱 이동 | ✅ 완료 | HealthKitDeniedView |

### 10. DailyLog 관리

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **10.1 getOrCreate 로직** | 없으면 User.current*로 생성 | ✅ 완료 | DailyLogLocalDataSource |
| **10.2 초기화 값 설정** | bmr, tdee 복사, 나머지 0 | ✅ 완료 | DailyLogService |
| **10.3 과거 날짜 정책** | 당시 스냅샷 유지 | ✅ 완료 | |

### 11. 유틸리티/공용

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **11.1 날짜 유틸리티** | 02:00 기준, 포맷터 | ✅ 완료 | DateUtils, Date+Extensions |
| **11.2 입력 검증** | 체성분, 음식, 수면, 운동 | ✅ 완료 | ValidationService, BodyMeasurementValidator |
| **11.3 앱 상태 관리** | 첫 실행, 온보딩 완료 | ✅ 완료 | AppStateService |

---

## Phase 2: AI 기능

### 12. 음식 사진 인식

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **12.1 카메라/갤러리 접근** | 권한 요청 | ✅ 완료 | CameraView, PhotoCaptureService |
| **12.2 Google Vision API** | Label Detection | ✅ 완료 | VisionAPIService |
| **12.3 인식 결과 → DB 매칭** | 라벨로 음식 검색 | ✅ 완료 | FoodLabelMatcherService |
| **12.4 인식 결과 수정 UI** | 선택/수정/삭제/양 조절 | ✅ 완료 | FoodMatchEditorView, RecognitionResultsView |
| **12.5 사용량 추적** | 월 1,000건 제한 | ✅ 완료 | VisionAPIUsageTracker |
| **12.6 오프라인 처리** | 네트워크 필요 메시지 | ✅ 완료 | PhotoRecognitionOfflineView |

### 13. 목표 관리

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **13.1 목표 설정** | 감량/유지/증량, 다중 목표 | ✅ 완료 | GoalSettingView, GoalSettingViewModel |
| **13.2 목표 정합성 검증** | 복수 목표 물리적 검증 | ✅ 완료 | GoalValidationService |
| **13.3 예상 진행 그래프** | 실제 vs 예상 라인 | ✅ 완료 | GoalProgressChart |
| **13.4 목표 달성률** | 항목별 퍼센트, 예상 달성일 | ✅ 완료 | GoalProgressView, GetGoalProgressUseCase |
| **13.5 마일스톤 축하** | 달성 시 축하 UI | ✅ 완료 | MilestoneCelebrationView, ConfettiEffect |

---

## Phase 3: 소셜 기능 (미구현)

| 기능 | PRD 요구사항 | 개발 상태 | 비고 |
|------|-------------|----------|------|
| **14.1 회원가입/로그인** | 이메일, Apple 로그인 | ❌ 미구현 | Phase 3 범위 |
| **14.2 프로필 공개 설정** | 전체/친구/비공개 | ❌ 미구현 | |
| **15.1 친구 추가** | 검색, 요청/수락 | ❌ 미구현 | |
| **15.2 친구 목록** | 활동 요약 | ❌ 미구현 | |
| **16.1 피드** | 활동 공유, 좋아요, 댓글 | ❌ 미구현 | |
| **16.2 챌린지** | 그룹 목표 | ❌ 미구현 | |
| **16.3 랭킹** | 순위 | ❌ 미구현 | |

---

## 요약

### Phase 1 (MVP) 완료 현황

| 파트 | 전체 기능 | 완료 | 부분 | 미완료 | 완료율 |
|------|----------|------|------|--------|--------|
| 체성분 관리 | 5 | 5 | 0 | 0 | 100% |
| BMR/TDEE 계산 | 5 | 5 | 0 | 0 | 100% |
| 음식 기록 | 8 | 8 | 0 | 0 | 100% |
| 운동 기록 | 4 | 4 | 0 | 0 | 100% |
| HealthKit 연동 | 5 | 5 | 0 | 0 | 100% |
| 수면 관리 | 7 | 5 | 2 | 0 | ~85% |
| 대시보드 | 6 | 6 | 0 | 0 | 100% |
| **온보딩** | 5 | 5 | 0 | 0 | **100%** |
| 설정 | 4 | 4 | 0 | 0 | 100% |
| DailyLog 관리 | 3 | 3 | 0 | 0 | 100% |
| 유틸리티 | 3 | 3 | 0 | 0 | 100% |
| **Phase 1 합계** | **55** | **52** | **3** | **0** | **~96%** |

### Phase 2 (AI) 완료 현황

| 파트 | 전체 기능 | 완료 | 부분 | 미완료 | 완료율 |
|------|----------|------|------|--------|--------|
| 사진 인식 | 6 | 6 | 0 | 0 | 100% |
| 목표 관리 | 5 | 5 | 0 | 0 | 100% |
| **Phase 2 합계** | **11** | **11** | **0** | **0** | **100%** |

### Phase 3 (소셜) 완료 현황

| 파트 | 전체 기능 | 완료 | 부분 | 미완료 | 완료율 |
|------|----------|------|------|--------|--------|
| 소셜 기능 | 7 | 0 | 0 | 7 | 0% |

---

## 긴급 개발 필요 항목

### ~~1. 온보딩 (Phase 1 필수) - 우선순위: Critical~~ ✅ 완료 (2026-01-20)

온보딩 기능이 구현되었습니다.

| 파일 | 설명 | 상태 |
|------|------|------|
| `OnboardingContainerView.swift` | 앱 소개 PageView | ✅ 완료 |
| `WelcomeView.swift` | 환영 화면 | ✅ 완료 |
| `BasicInfoInputView.swift` | 이름, 성별, 생년월일 입력 | ✅ 완료 |
| `BodyInfoInputView.swift` | 키, 몸무게 입력 | ✅ 완료 |
| `ActivityLevelSelectView.swift` | 활동 수준 선택 | ✅ 완료 |
| `OnboardingCompleteView.swift` | BMR/TDEE 결과 표시 | ✅ 완료 |
| `OnboardingViewModel.swift` | 상태 관리 | ✅ 완료 |
| `AppStateService.swift` | 온보딩 완료 플래그 | ✅ 완료 |

**구현된 온보딩 플로우:**
```
앱 첫 실행 (isOnboardingComplete == false)
    ↓
환영 화면 (WelcomeView)
    ↓
기본 정보 입력 (BasicInfoInputView: 이름, 성별, 생년월일)
    ↓
신체 정보 입력 (BodyInfoInputView: 키, 몸무게)
    ↓
활동 수준 선택 (ActivityLevelSelectView: 5단계)
    ↓
결과 화면 (OnboardingCompleteView: BMR/TDEE 표시)
    ↓
User 생성 + 온보딩 완료 플래그 저장
    ↓
메인 화면 진입 (ContentView)
```

### 1. 수면 팝업 자동 표시 (Phase 1) - 우선순위: High

| 항목 | 요구사항 | 상태 |
|------|---------|------|
| 자동 팝업 조건 | 새벽 2시 이후 앱 첫 실행 시 | ⚠️ 미확인 |
| "나중에" 버튼 | 최대 3회까지 재팝업 | ⚠️ 미확인 |
| 3회 스킵 시 | 수면 탭에서 직접 입력 유도 | ⚠️ 미확인 |

### 2. 앱 상태 관리 서비스 (Phase 1) - 우선순위: High

| 기능 | 설명 | 상태 |
|------|------|------|
| `isOnboardingComplete` | 온보딩 완료 여부 | ✅ 완료 |
| `sleepPromptSkipCount` | 수면 팝업 스킵 횟수 (오늘) | ✅ 완료 |
| `lastSleepPromptDate` | 마지막 수면 팝업 표시 날짜 | ✅ 완료 |

---

## 테스트 필요 항목 (기존 구현된 기능)

### 핵심 플로우 테스트

| # | 테스트 항목 | 상태 |
|---|-----------|------|
| 1 | 체성분 입력 → User.current* 업데이트 → MetabolismSnapshot 생성 | ✅ 구현됨 |
| 2 | 음식 추가/삭제 → DailyLog 칼로리/매크로 업데이트 | ✅ 구현됨 |
| 3 | 운동 추가/삭제 → DailyLog 소모 칼로리 업데이트 | ✅ 구현됨 |
| 4 | 수면 입력 → DailyLog 수면 상태 업데이트 | ✅ 구현됨 |
| 5 | 수면 팝업 자동 표시 (02:00 기준) | ⚠️ 테스트 필요 |
| 6 | 사진 인식 → 음식 매칭 → 기록 저장 | ✅ 구현됨 |
| 7 | 목표 설정 → 진행률 계산 → 그래프 표시 | ✅ 구현됨 |

### UI 테스트

| # | 화면 | 테스트 항목 |
|---|------|-----------|
| 1 | Dashboard | 데이터 로딩, 날짜 이동, 카드 표시 |
| 2 | Diet | 끼니별 목록, 음식 추가/삭제, AI 코멘트 |
| 3 | Exercise | 운동 입력, 칼로리 계산, 목록 표시 |
| 4 | Body | 체성분 입력, 그래프, 히스토리 |
| 5 | Sleep | 수면 입력, 그래프, 히스토리 |
| 6 | Goal | 목표 설정, 진행률, 마일스톤 |
| 7 | Settings | 프로필 수정, HealthKit 토글 |
| 8 | PhotoRecognition | 카메라, 인식 결과, 수정 UI |

---

## 개발 우선순위

### ~~즉시 (Critical)~~ ✅ 완료
~~1. **온보딩 구현** - 앱 사용의 시작점~~ ✅ 완료 (2026-01-20)

### 단기 (High)
1. **수면 팝업 자동 표시 검증** - PRD 명세대로 동작하는지 확인

### 중기 (Medium)
2. **전체 플로우 테스트** - 각 기능 간 연동 확인
3. **에러 핸들링 검증** - 네트워크 오류, 저장 실패 등

### 장기 (Low)
4. **Phase 3 소셜 기능** - 서버 구축 후 진행

---

## 변경 이력

### 2026-02-01: 식단 기록 수정 기능 구현

기존에 입력한 식단 기록을 수정할 수 있는 기능을 구현했습니다.

**문제**: 식단 기록 탭 시 `onEditFood` 콜백이 TODO print문으로만 되어 있어 수정 불가

**변경 파일 및 내용**:
| 파일 | 변경 내용 |
|------|-----------|
| `FoodDetailViewModel.swift` | `isEditMode`, `editingFoodRecordId` 프로퍼티 추가, `onAppearForEdit()` 메서드 추가, `saveFoodRecord()`에서 수정/추가 모드 분기 |
| `FoodDetailView.swift` | 네비게이션 타이틀·버튼·토스트 메시지를 수정 모드에 맞게 동적 변경 |
| `DailyMealView.swift` | `onEditFood: ((FoodRecordWithFood) -> Void)?` 콜백 추가, TODO 코드 → 실제 콜백 호출로 교체 |
| `DailyMealViewModel.swift` | `findFoodRecordWithFood(by:)` 헬퍼 메서드 추가 |
| `DietTabView.swift` | `editingFoodRecord`, `showingEditFood` 상태 추가, `editFoodSheet(item:)` 메서드 추가 |

**동작 흐름**:
```
음식 기록 탭 → FoodRecordRow.onEdit → MealSectionView.onEditFood(UUID)
  → DailyMealView에서 UUID로 FoodRecordWithFood 조회
    → DietTabView.onEditFood 콜백 → 수정 시트 표시
      → FoodDetailView (수정 모드) → FoodRecordService.updateFoodRecord()
        → 시트 닫기 + 데이터 새로고침 + AI 코멘트 재생성
```

---

### 2026-01-31: AI 식단 분석 개선 및 칼로리 표시 최적화

#### 1. 목표 칼로리(targetCalories) 파라미터 체인 구축
사용자의 실제 목표 섭취 칼로리가 AI 분석 프롬프트에 정확히 전달되도록 전체 호출 체인을 구축했습니다.

**문제**: AI가 사용자의 목표 섭취량(예: 1500 kcal)이 아닌 TDEE(예: 1958 kcal)를 기준으로 평가하고 있었음

**변경 파일 및 내용**:
| 파일 | 변경 내용 |
|------|-----------|
| `DietCommentRepository.swift` | `generateComment()`에 `targetCalories: Int` 파라미터 추가 |
| `DietCommentRepositoryImpl.swift` | `targetCalories`를 GeminiService로 전달 |
| `GenerateDietCommentUseCase.swift` | `execute()`, `executeIgnoringCache()`에 `targetCalories` 파라미터 추가 |
| `GeminiServiceProtocol.swift` | 프로토콜 메서드에 `targetCalories` 추가 |
| `GeminiService.swift` | `generateDietComment()`, `buildPrompt()`에 `targetCalories` 반영 |
| `DietCommentViewModel.swift` | `userTargetCalories` 프로퍼티 추가, init 파라미터 추가 |
| `DailyMealViewModel.swift` | `goalRepository` 의존성 추가, `loadTargetCalories()` 메서드 추가 |
| `DIContainer.swift` | `makeDietCommentViewModel()`에 `targetCalories` 파라미터 추가 |
| `DietTabView.swift` | `DailyMealViewModel` 생성 시 `goalRepository` 전달 |

**호출 체인**:
```
Goal Entity (dailyCalorieTarget)
  → GoalRepository.fetchActiveGoal()
    → DailyMealViewModel.currentTargetCalories
      → DietCommentViewModel.userTargetCalories
        → GenerateDietCommentUseCase.execute(targetCalories:)
          → DietCommentRepository.generateComment(targetCalories:)
            → GeminiService.buildPrompt(targetCalories:)
              → AI 프롬프트: "하루 권장 섭취량: {targetCalories} kcal"
```

#### 2. 일일 칼로리 표시 변경 (TDEE → 목표 섭취량)
NutritionSummaryCard 상단의 칼로리 표시를 TDEE 대신 사용자의 목표 섭취량으로 변경했습니다.

**변경 내용**:
- `DailyMealViewModel.displayTargetCalories`: 목표 섭취량 > 0이면 목표 섭취량, 아니면 TDEE를 반환
- `remainingCalories`, `calorieIntakePercentage`도 `displayTargetCalories` 기준으로 계산
- `NutritionSummaryCard`에 `targetCalories: Int32` 파라미터 추가

**동작**:
- 목표 설정 O → "섭취량 / 목표 섭취량 kcal" 표시
- 목표 설정 X → "섭취량 / TDEE kcal" 표시 (기존 동작 유지)

#### 3. AI 분석 호출 최적화 (탭 이동 시 재호출 방지)
탭을 이동할 때마다 AI 분석이 재호출되던 문제를 수정하여, 식단이 실제로 변경된 경우에만 AI 분석을 실행하도록 변경했습니다.

**문제**: `onAppear` → `loadData()` → `generateDailyComment()` 체인으로 인해 탭 전환마다 Gemini API 호출 발생

**변경 내용**:
| 변경 | 내용 |
|------|------|
| `loadData()`에서 `generateDailyComment()` 제거 | 탭 이동 시 AI 재호출 방지 |
| `refreshAfterDietChange()` 메서드 추가 | `loadData()` + `generateDailyComment()` 결합 |
| `deleteFoodRecord()` 수정 | 삭제 후 AI 분석 재생성 호출 |
| `DietTabView` onSave 콜백 4곳 수정 | `refresh()` → `refreshAfterDietChange()` |
| 날짜 변경 시 AI 결과 초기화 | `dailyComment`, `dailyCommentError`를 nil로 설정 |

**AI 분석이 호출되는 시점 (변경 후)**:
- 음식 저장 (검색 선택, 수동 입력, 사진 인식)
- 음식 삭제
- 사용자가 수동으로 AI 분석 버튼 클릭

**AI 분석이 호출되지 않는 시점 (변경 후)**:
- 탭 이동 (식단 탭 ↔ 다른 탭)
- 날짜 변경 (이전/다음 날짜)
- 새로고침 버튼

#### 4. Gemini API 모델 변경 및 프롬프트 개선 (이전 세션)
- API 모델: `gemini-2.0-flash` → `gemini-2.5-flash-lite` (비용 최적화)
- `maxTokensReached` 오류 수정: `maxOutputTokens` 2048 → finish reason 체크 추가
- 프롬프트 개선: 시간 인식 평가, 음식명 직접 언급, 끼니별 그룹핑, 5단계 엄격 점수 체계

---

*문서 버전: 1.2*
*최종 수정: 2026-02-01*
*기준: PRD v2.0, FEATURE_SPEC v2.0*

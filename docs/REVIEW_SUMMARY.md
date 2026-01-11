# Bodii 기획 문서 수정 및 점검 결과

## 📋 수정 완료 문서

| 문서 | 버전 | 주요 수정 내용 |
|------|------|----------------|
| 01_PRD.md | 2.0 | 데이터 저장 전략 섹션 추가, 일정 업데이트 |
| 02_FEATURE_SPEC.md | 2.0 | BMR/TDEE 저장 전략, 연쇄 업데이트 정책, DailyLog 관리 섹션 추가 |
| 03_USER_FLOW.md | 2.0 | 저장 처리 로직 추가, 데이터 소스 명시, 연쇄 업데이트 플로우 |
| 04_ERD.md | 2.0 | User 필드 추가, DailyLog 확장, MetabolismSnapshot 신규, Goal.goalType 추가 |
| 05_TASKS.md | 2.0 | 서비스 레이어 분리, 연쇄 업데이트 태스크 추가, 의존성 재정리 |

---

## 🔄 핵심 변경사항 요약

### 1. 데이터 저장 전략

**원칙**: "계산은 변경 시점에 한 번, 조회는 저장된 값으로 빠르게"

```
┌─────────────────────────────────────────────────────────────┐
│  User (현재 상태)                                           │
│  - currentWeight, currentBodyFatPct, currentMuscleMass     │
│  - currentBMR, currentTDEE                                 │
│  - metabolismUpdatedAt                                      │
└──────────────────────────┬──────────────────────────────────┘
                           │ 업데이트
                           ↓
┌──────────────────────────────────────────────────────────────┐
│  트리거 이벤트                                               │
│  - 체성분 입력 → User.current*, MetabolismSnapshot, DailyLog │
│  - 활동 수준 변경 → User.currentTDEE                        │
│  - 키/나이 변경 → User.currentBMR, currentTDEE              │
└──────────────────────────────────────────────────────────────┘
```

### 2. 신규 Entity: MetabolismSnapshot

```
MetabolismSnapshot (1:1 with BodyRecord)
├── bodyRecordId (FK, UNIQUE)
├── weight, bodyFatPct
├── bmr, tdee
├── activityLevel (계산 당시 값)
└── 용도: 체성분 변화에 따른 대사량 추이 그래프
```

### 3. DailyLog 확장

**기존 필드** + **신규 필드**:
```
DailyLog
├── 섭취: totalCaloriesIn, totalCarbs/Protein/Fat, *Ratio (신규)
├── 대사량: bmr, tdee, netCalories (신규)
├── 운동: totalCaloriesOut, exerciseMinutes (신규), exerciseCount (신규)
├── 체성분: weight, bodyFatPct (신규, 스냅샷)
├── 수면: sleepDuration, sleepStatus (신규)
└── HealthKit: steps
```

### 4. 서비스 레이어 분리

| 서비스 | 담당 |
|--------|------|
| **BodyRecordService** | 체성분 저장 + User/Snapshot/DailyLog 연쇄 업데이트 |
| **FoodRecordService** | 음식 저장 + DailyLog 증분/감소 |
| **ExerciseRecordService** | 운동 저장 + DailyLog 증분/감소 |
| **SleepRecordService** | 수면 저장 + DailyLog 업데이트 |
| **DailyLogService** | DailyLog 생성/업데이트/조회 |
| **MetabolismService** | BMR/TDEE 계산 |

---

## ✅ 문서 간 일관성 검증

### 검증 항목

| 항목 | 상태 | 비고 |
|------|------|------|
| Entity 이름 | ✅ 통일 | User, BodyRecord, MetabolismSnapshot, Food, FoodRecord, ExerciseRecord, SleepRecord, DailyLog, Goal |
| 필드명 | ✅ 통일 | bodyFatPercent (ERD) = bodyFatPct (축약형) 명시 |
| Phase 구분 | ✅ 통일 | Phase 1(MVP), Phase 2(AI), Phase 3(Social) |
| 활동 수준 코드 | ✅ 통일 | 1~5, 명칭 포함 |
| 수면 상태 코드 | ✅ 통일 | 0~4 (Bad/Soso/Good/Excellent/Oversleep) |
| 끼니 코드 | ✅ 통일 | 0~3 (아침/점심/저녁/간식) |
| 목표 유형 코드 | ✅ 추가 | 0~2 (감량/유지/증량) |
| 음식 출처 코드 | ✅ 통일 | 0~2 (식약처/USDA/사용자) |

---

## 🆕 추가된 태스크

| 태스크 ID | 이름 | 예상 시간 | 설명 |
|-----------|------|-----------|------|
| TASK-035 | DailyLog 서비스 | 4h | DailyLog 생성/업데이트/조회 |
| TASK-044 | 체성분 저장 서비스 | 3h | 체성분 + 연쇄 업데이트 |
| TASK-056 | 음식 기록 서비스 | 2h | 음식 + DailyLog 연쇄 업데이트 |
| TASK-063 | 운동 기록 서비스 | 2h | 운동 + DailyLog 연쇄 업데이트 |
| TASK-078 | 수면 기록 서비스 | 2h | 수면 + DailyLog 연쇄 업데이트 |

---

## 📊 일정 업데이트

### Phase 1 (MVP)

| 항목 | 이전 | 변경 |
|------|------|------|
| 총 태스크 | 35개 | 43개 |
| 예상 시간 | ~95h | ~118h |
| 병렬 작업 시 | ~48h | ~60h (5주) |

### 주차별 계획

| 주차 | 작업 내용 |
|------|----------|
| 1주 | 프로젝트 설정, 온보딩, 탭 구조 |
| 2주 | 핵심 서비스 (Metabolism, DailyLog), 체성분 기능, HealthKit |
| 3주 | 식단, 운동, 수면 기능 |
| 4주 | 대시보드, 설정 |
| 5주 | 테스트, 앱스토어 제출 |

---

## ⚠️ 추가 검토 필요 사항

### 1. 엣지 케이스 (별도 문서 권장)

| 카테고리 | 케이스 | 정책 필요 |
|----------|--------|-----------|
| 온보딩 | 중간 종료 후 재실행 | 진행 상태 복구 |
| 체성분 | 삭제 시 User.current* | 최신 기록으로 재계산 |
| 체성분 | 극단적 체지방률 (3% 미만) | 경고 메시지 |
| 식단 | 자정 이후 간식 기록 | 어느 날짜? (현재 날짜로) |
| 수면 | 02:00 경계 테스트 | 단위 테스트 필수 |
| 과거 | 과거 날짜 기록 추가 | DailyLog 생성 (현재 User 값 사용) |

### 2. API 에러 핸들링 정책 (별도 문서 권장)

| API | 에러 케이스 | 처리 방안 |
|-----|------------|-----------|
| 식약처 | 타임아웃 | 재시도 1회 → USDA 폴백 |
| USDA | Rate Limit | 메시지 표시 |
| Gemini | 15 RPM 초과 | 큐잉 또는 메시지 |
| Vision | 월 1000건 초과 | 직접 입력 유도 |

### 3. Core Data 마이그레이션

```
향후 Entity 변경 시:
- Lightweight Migration 가능 여부 확인
- 불가능 시 Manual Migration 계획
- 첫 출시 전 스키마 확정 권장
```

---

## 📁 최종 문서 구조

```
Bodii/docs/
├── 01_PRD.md              (v2.0) - 제품 요구사항
├── 02_FEATURE_SPEC.md     (v2.0) - 기능 명세 + 저장 전략
├── 03_USER_FLOW.md        (v2.0) - 사용자 흐름도
├── 04_ERD.md              (v2.0) - 데이터베이스 설계
├── 05_TASKS.md            (v2.0) - 태스크 목록
├── 06_DEVELOPMENT_GUIDE.md (v1.0) - 개발 가이드 (수정 불필요)
└── 07_PORTFOLIO_STUDY.md   (v1.0) - 포트폴리오 가이드 (수정 불필요)
```

---

## ✨ 추가 문서 작성 완료

| 문서 | 설명 |
|------|------|
| **08_EDGE_CASES.md** | 온보딩, 체성분, 식단, 운동, 수면, DailyLog, 목표, 시스템 엣지 케이스 |
| **09_ERROR_HANDLING.md** | API별 에러 핸들링, 로그 정책, 재시도 전략, 폴백 전략 |
| **10_TEST_SCENARIOS.md** | Unit/Integration/UI 테스트 코드 예시, 커버리지 목표 |

---

## 📁 최종 문서 구조

```
Bodii/docs/
├── 01_PRD.md              (v2.0) - 제품 요구사항
├── 02_FEATURE_SPEC.md     (v2.0) - 기능 명세 + 저장 전략
├── 03_USER_FLOW.md        (v2.0) - 사용자 흐름도
├── 04_ERD.md              (v2.0) - 데이터베이스 설계
├── 05_TASKS.md            (v2.0) - 태스크 목록
├── 06_ALGORITHM.md        (v1.0) - 알고리즘 정리
├── 06_DEVELOPMENT_GUIDE.md (v1.0) - 개발 가이드
├── 07_PORTFOLIO_STUDY.md   (v1.0) - 포트폴리오 가이드
├── 08_EDGE_CASES.md       (v1.0) - 엣지 케이스 정의 ✅ NEW
├── 09_ERROR_HANDLING.md   (v1.0) - 에러 핸들링 정책 ✅ NEW
├── 10_TEST_SCENARIOS.md   (v1.0) - 테스트 시나리오 ✅ NEW
└── REVIEW_SUMMARY.md      - 문서 수정 요약
```

---

## ✅ 다음 단계

문서 작성 완료! 이제 **개발 시작** 가능합니다.

**권장 순서:**
1. TASK-001: Xcode 프로젝트 생성
2. TASK-002: Core Data 모델 설정
3. TASK-004: 앱 상태 관리 서비스
4. TASK-005: 날짜 유틸리티 서비스
5. TASK-043: BMR/TDEE 계산 서비스

---

*작

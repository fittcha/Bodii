# Bodii - ERD (Entity Relationship Diagram)

## 1. 전체 ERD 다이어그램

```
┌─────────────────────┐
│        User         │
├─────────────────────┤
│ PK id: UUID         │
│    name: String     │
│    gender: Int16    │
│    birthDate: Date  │
│    height: Decimal  │
│    activityLevel    │
│    ─────────────────│
│    currentWeight    │
│    currentBodyFatPct│
│    currentMuscleMass│
│    currentBMR       │
│    currentTDEE      │
│    metabolismUpdatedAt│
│    ─────────────────│
│    createdAt: Date  │
│    updatedAt: Date  │
└─────────┬───────────┘
          │
          │ 1:N
          ▼
┌─────────────────────┐       ┌─────────────────────┐
│    BodyRecord       │       │ MetabolismSnapshot  │
├─────────────────────┤       ├─────────────────────┤
│ PK id: UUID         │──1:1──│ PK id: UUID         │
│ FK userId: UUID     │       │ FK userId: UUID     │
│    date: Date       │       │ FK bodyRecordId     │
│    weight: Decimal  │       │    date: Date       │
│    bodyFatMass      │       │    weight: Decimal  │
│    bodyFatPercent   │       │    bodyFatPct       │
│    muscleMass       │       │    bmr: Decimal     │
│    createdAt: Date  │       │    tdee: Decimal    │
└─────────────────────┘       │    activityLevel    │
                              │    createdAt: Date  │
                              └─────────────────────┘

┌─────────────────────┐       ┌─────────────────────┐
│    FoodRecord       │       │       Food          │
├─────────────────────┤       ├─────────────────────┤
│ PK id: UUID         │       │ PK id: UUID         │
│ FK userId: UUID     │──N:1──│    name: String     │
│ FK foodId: UUID     │       │    calories: Int32  │
│    date: Date       │       │    carbs: Decimal   │
│    mealType: Int16  │       │    protein: Decimal │
│    quantity: Decimal│       │    fat: Decimal     │
│    quantityUnit     │       │    sodium: Decimal  │
│    calculatedCal    │       │    fiber: Decimal   │
│    createdAt: Date  │       │    sugar: Decimal   │
└─────────────────────┘       │    servingSize      │
                              │    servingUnit      │
                              │    source: Int16    │
                              │    apiCode: String  │
                              │ FK createdByUserId  │
                              │    createdAt: Date  │
                              └─────────────────────┘

┌─────────────────────┐       ┌─────────────────────┐
│   ExerciseRecord    │       │     SleepRecord     │
├─────────────────────┤       ├─────────────────────┤
│ PK id: UUID         │       │ PK id: UUID         │
│ FK userId: UUID     │       │ FK userId: UUID     │
│    date: Date       │       │    date: Date       │
│    exerciseType     │       │    duration: Int32  │
│    duration: Int32  │       │    status: Int16    │
│    intensity: Int16 │       │    createdAt: Date  │
│    caloriesBurned   │       │    updatedAt: Date  │
│    note: String     │       └─────────────────────┘
│    fromHealthKit    │
│    healthKitId      │
│    createdAt: Date  │
└─────────────────────┘

┌───────────────────────────────────────────────────┐
│                    DailyLog                       │
├───────────────────────────────────────────────────┤
│ PK id: UUID                                       │
│ FK userId: UUID                                   │
│    date: Date (UNIQUE per user)                   │
│    ─────────────────────────────────────────────  │
│    // 섭취                                        │
│    totalCaloriesIn: Int32                         │
│    totalCarbs: Decimal                            │
│    totalProtein: Decimal                          │
│    totalFat: Decimal                              │
│    carbsRatio: Decimal?                           │
│    proteinRatio: Decimal?                         │
│    fatRatio: Decimal?                             │
│    ─────────────────────────────────────────────  │
│    // 대사량 스냅샷                                │
│    bmr: Int32                                     │
│    tdee: Int32                                    │
│    netCalories: Int32                             │
│    ─────────────────────────────────────────────  │
│    // 소모 & 운동                                 │
│    totalCaloriesOut: Int32                        │
│    exerciseMinutes: Int32                         │
│    exerciseCount: Int16                           │
│    steps: Int32?                                  │
│    ─────────────────────────────────────────────  │
│    // 체성분 스냅샷                                │
│    weight: Decimal?                               │
│    bodyFatPct: Decimal?                           │
│    ─────────────────────────────────────────────  │
│    // 수면                                        │
│    sleepDuration: Int32?                          │
│    sleepStatus: Int16?                            │
│    ─────────────────────────────────────────────  │
│    createdAt: Date                                │
│    updatedAt: Date                                │
└───────────────────────────────────────────────────┘

┌─────────────────────────────┐
│           Goal              │
├─────────────────────────────┤
│ PK id: UUID                 │
│ FK userId: UUID             │
│    goalType: Int16          │
│    ─────────────────────────│
│    // 목표값                 │
│    targetWeight?            │
│    targetBodyFatPct?        │
│    targetMuscleMass?        │
│    ─────────────────────────│
│    // 주간 변화율            │
│    weeklyWeightRate?        │
│    weeklyFatPctRate?        │
│    weeklyMuscleRate?        │
│    ─────────────────────────│
│    // 시작 시점 기록         │
│    startWeight?             │
│    startBodyFatPct?         │
│    startMuscleMass?         │
│    startBMR?                │
│    startTDEE?               │
│    ─────────────────────────│
│    dailyCalorieTarget?      │
│    isActive: Bool           │
│    createdAt: Date          │
│    updatedAt: Date          │
└─────────────────────────────┘
```

---

## 2. Entity 상세 정의

### 2.1 User (사용자)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| name | String | NOT NULL | 사용자 이름 |
| gender | Int16 | NOT NULL | 성별 (0: 남성, 1: 여성) |
| birthDate | Date | NOT NULL | 생년월일 |
| height | Decimal | NOT NULL | 키 (cm) |
| activityLevel | Int16 | NOT NULL | 활동 수준 (1~5) |
| **currentWeight** | Decimal | NULL | 최신 체중 (kg) |
| **currentBodyFatPct** | Decimal | NULL | 최신 체지방률 (%) |
| **currentMuscleMass** | Decimal | NULL | 최신 골격근량 (kg) |
| **currentBMR** | Decimal | NULL | 현재 기초대사량 (kcal) |
| **currentTDEE** | Decimal | NULL | 현재 활동대사량 (kcal) |
| **metabolismUpdatedAt** | Date | NULL | 대사량 마지막 계산 시점 |
| createdAt | Date | NOT NULL | 생성일시 |
| updatedAt | Date | NOT NULL | 수정일시 |

**활동 수준 (activityLevel) 코드:**
```
1: 비활동적 (Sedentary) - 좌식 생활, 계수 1.2
2: 가벼운 활동 (Light) - 주 1-3일 운동, 계수 1.375
3: 보통 활동 (Moderate) - 주 3-5일 운동, 계수 1.55
4: 활동적 (Active) - 주 6-7일 운동, 계수 1.725
5: 매우 활동적 (Very Active) - 고강도 매일, 계수 1.9
```

**User.current* 필드 업데이트 트리거:**
| 이벤트 | 업데이트 항목 |
|--------|---------------|
| 체성분 입력 | currentWeight, currentBodyFatPct, currentMuscleMass, currentBMR, currentTDEE, metabolismUpdatedAt |
| 체성분 삭제 | 최신 기록 기준으로 재계산 |
| 활동 수준 변경 | currentTDEE, metabolismUpdatedAt |
| 키 변경 | currentBMR, currentTDEE (체지방률 없을 때만 BMR 영향) |
| 생년월일 변경 | currentBMR, currentTDEE (체지방률 없을 때만 BMR 영향) |

---

### 2.2 BodyRecord (체성분 기록)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| date | Date | NOT NULL, DEFAULT now() | 측정일시 (기본값: 현재 일시) |
| weight | Decimal | NOT NULL | 몸무게 (kg) |
| bodyFatMass | Decimal | NULL | 체지방량 (kg) |
| bodyFatPercent | Decimal | NULL | 체지방률 (%) |
| muscleMass | Decimal | NULL | 골격근량 (kg) |
| createdAt | Date | NOT NULL | 생성일시 |

**체지방 자동 계산 (앱 레벨):**
```
bodyFatMass 입력 시: bodyFatPercent = (bodyFatMass / weight) × 100
bodyFatPercent 입력 시: bodyFatMass = weight × (bodyFatPercent / 100)
```

**인덱스:**
- idx_bodyrecord_user_date (userId, date)

---

### 2.3 MetabolismSnapshot (대사량 스냅샷) - 신규

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| bodyRecordId | UUID | FK, UNIQUE, NOT NULL | BodyRecord 참조 (1:1) |
| date | Date | NOT NULL | 측정일시 |
| weight | Decimal | NOT NULL | 체중 (kg) |
| bodyFatPct | Decimal | NULL | 체지방률 (%) |
| bmr | Decimal | NOT NULL | 기초대사량 (kcal) |
| tdee | Decimal | NOT NULL | 활동대사량 (kcal) |
| activityLevel | Int16 | NOT NULL | 계산 당시 활동 수준 |
| createdAt | Date | NOT NULL | 생성일시 |

**용도:**
- BodyRecord 입력 시 자동 생성 (1:1 관계)
- 체성분 변화에 따른 BMR/TDEE 추이 그래프
- "언제 대사량이 가장 높았나?" 분석

**인덱스:**
- idx_metabolism_user_date (userId, date)
- idx_metabolism_bodyrecord (bodyRecordId) UNIQUE

---

### 2.4 Food (음식 마스터)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| name | String | NOT NULL | 음식명 |
| calories | Int32 | NOT NULL | 칼로리 (kcal) |
| carbohydrates | Decimal | NOT NULL | 탄수화물 (g) |
| protein | Decimal | NOT NULL | 단백질 (g) |
| fat | Decimal | NOT NULL | 지방 (g) |
| sodium | Decimal | NULL | 나트륨 (mg) |
| fiber | Decimal | NULL | 식이섬유 (g) |
| sugar | Decimal | NULL | 당류 (g) |
| servingSize | Decimal | NOT NULL | 1회 제공량 (g) |
| servingUnit | String | NULL | 단위 (예: "1인분", "1개") |
| source | Int16 | NOT NULL | 출처 |
| apiCode | String | NULL | API 식품코드 |
| createdByUserId | UUID | FK, NULL | 사용자 정의 음식 생성자 |
| createdAt | Date | NOT NULL | 생성일시 |

**source 코드:**
```
0: 식약처 API (공공데이터) - 한국 음식
1: USDA FoodData Central - 외국 음식
2: 사용자 직접 입력
```

**인덱스:**
- idx_food_name (name)
- idx_food_apicode (apiCode)
- idx_food_source (source)

---

### 2.5 FoodRecord (식단 기록)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| foodId | UUID | FK, NOT NULL | Food 참조 |
| date | Date | NOT NULL | 섭취일 |
| mealType | Int16 | NOT NULL | 끼니 종류 |
| quantity | Decimal | NOT NULL | 섭취량 |
| quantityUnit | Int16 | NOT NULL | 단위 (0: 인분, 1: g) |
| calculatedCalories | Int32 | NOT NULL | 계산된 칼로리 |
| calculatedCarbs | Decimal | NOT NULL | 계산된 탄수화물 (g) |
| calculatedProtein | Decimal | NOT NULL | 계산된 단백질 (g) |
| calculatedFat | Decimal | NOT NULL | 계산된 지방 (g) |
| createdAt | Date | NOT NULL | 생성일시 |

**mealType 코드:**
```
0: 아침
1: 점심
2: 저녁
3: 간식
```

**인덱스:**
- idx_foodrecord_user_date (userId, date)
- idx_foodrecord_date_meal (date, mealType)

---

### 2.6 ExerciseRecord (운동 기록)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| date | Date | NOT NULL | 운동일 |
| exerciseType | Int16 | NOT NULL | 운동 종류 |
| duration | Int32 | NOT NULL | 운동 시간 (분) |
| intensity | Int16 | NOT NULL | 강도 (0: 저, 1: 중, 2: 고) |
| caloriesBurned | Int32 | NOT NULL | 소모 칼로리 |
| note | String | NULL | 메모 |
| fromHealthKit | Bool | NOT NULL, DEFAULT false | HealthKit 연동 여부 |
| healthKitId | String | NULL | HealthKit UUID |
| createdAt | Date | NOT NULL | 생성일시 |

**exerciseType 코드 및 MET 값:**
```
0: 걷기 - MET 3.5 (저), 4.0 (중), 5.0 (고)
1: 달리기 - MET 7.0 (저), 8.0 (중), 10.0 (고)
2: 자전거 - MET 5.0 (저), 6.0 (중), 8.0 (고)
3: 수영 - MET 6.0 (저), 7.0 (중), 9.0 (고)
4: 웨이트 - MET 4.0 (저), 6.0 (중), 8.0 (고)
5: 크로스핏 - MET 6.0 (저), 8.0 (중), 10.0 (고)
6: 요가 - MET 2.5 (저), 3.0 (중), 4.0 (고)
7: 기타 - MET 4.0 (저), 5.0 (중), 6.0 (고)
```

**인덱스:**
- idx_exerciserecord_user_date (userId, date)
- idx_exerciserecord_healthkit (healthKitId)

---

### 2.7 SleepRecord (수면 기록)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| date | Date | NOT NULL | 수면 기준일 (02:00 기준) |
| duration | Int32 | NOT NULL | 수면 시간 (분 단위) |
| status | Int16 | NOT NULL | 상태 (0~4) |
| createdAt | Date | NOT NULL | 생성일시 |
| updatedAt | Date | NOT NULL | 수정일시 |

**status 코드 및 기준:**
```
0: Bad (🔴) - 5시간 30분 미만 (< 330분)
1: Soso (🟡) - 5시간 30분 ~ 6시간 30분 (330 ~ 390분)
2: Good (🟢) - 6시간 30분 ~ 7시간 30분 (390 ~ 450분)
3: Excellent (🔵) - 7시간 30분 ~ 9시간 (450 ~ 540분)
4: Oversleep (🟠) - 9시간 초과 (> 540분)
```

**하루 기준 (02:00 기준):**
```
02:00 ~ 다음날 02:00 = 하루
예: 2026-01-11 03:00에 입력 → date = 2026-01-11
예: 2026-01-11 01:00에 입력 → date = 2026-01-10
```

**인덱스:**
- idx_sleeprecord_user_date (userId, date) UNIQUE

---

### 2.8 DailyLog (일일 집계)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| date | Date | NOT NULL | 날짜 |
| **섭취** ||||
| totalCaloriesIn | Int32 | NOT NULL, DEFAULT 0 | 총 섭취 칼로리 |
| totalCarbs | Decimal | NOT NULL, DEFAULT 0 | 총 탄수화물 (g) |
| totalProtein | Decimal | NOT NULL, DEFAULT 0 | 총 단백질 (g) |
| totalFat | Decimal | NOT NULL, DEFAULT 0 | 총 지방 (g) |
| carbsRatio | Decimal | NULL | 탄수화물 비율 (%) |
| proteinRatio | Decimal | NULL | 단백질 비율 (%) |
| fatRatio | Decimal | NULL | 지방 비율 (%) |
| **대사량 스냅샷** ||||
| bmr | Int32 | NOT NULL | 해당일 BMR |
| tdee | Int32 | NOT NULL | 해당일 TDEE |
| netCalories | Int32 | NOT NULL | 순 칼로리 (섭취 - TDEE) |
| **소모 & 운동** ||||
| totalCaloriesOut | Int32 | NOT NULL, DEFAULT 0 | 운동 소모 칼로리 |
| exerciseMinutes | Int32 | NOT NULL, DEFAULT 0 | 총 운동 시간 (분) |
| exerciseCount | Int16 | NOT NULL, DEFAULT 0 | 운동 횟수 |
| steps | Int32 | NULL | 걸음 수 (HealthKit) |
| **체성분 스냅샷** ||||
| weight | Decimal | NULL | 해당일 체중 |
| bodyFatPct | Decimal | NULL | 해당일 체지방률 |
| **수면** ||||
| sleepDuration | Int32 | NULL | 수면 시간 (분) |
| sleepStatus | Int16 | NULL | 수면 상태 (0~4) |
| **메타** ||||
| createdAt | Date | NOT NULL | 생성일시 |
| updatedAt | Date | NOT NULL | 수정일시 |

**DailyLog 생성/업데이트 트리거:**
| 이벤트 | 업데이트 항목 |
|--------|---------------|
| DailyLog 최초 생성 | User.current* 값으로 bmr, tdee, netCalories 초기화 |
| 음식 추가 | totalCaloriesIn, totalCarbs/Protein/Fat 증가, 매크로 비율 재계산, netCalories 재계산 |
| 음식 삭제 | totalCaloriesIn, totalCarbs/Protein/Fat 감소, 매크로 비율 재계산, netCalories 재계산 |
| 운동 추가 | totalCaloriesOut 증가, exerciseMinutes/Count 증가 |
| 운동 삭제 | totalCaloriesOut 감소, exerciseMinutes/Count 감소 |
| 체성분 입력 (당일) | bmr, tdee, netCalories, weight, bodyFatPct 업데이트 |
| 수면 입력 | sleepDuration, sleepStatus 업데이트 |
| HealthKit 동기화 | steps 업데이트 |

**인덱스:**
- idx_dailylog_user_date (userId, date) UNIQUE

---

### 2.9 Goal (목표) - Phase 2

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK | 고유 식별자 |
| userId | UUID | FK, NOT NULL | User 참조 |
| goalType | Int16 | NOT NULL | 목표 유형 |
| **목표값** ||||
| targetWeight | Decimal | NULL | 목표 체중 (kg) |
| targetBodyFatPct | Decimal | NULL | 목표 체지방률 (%) |
| targetMuscleMass | Decimal | NULL | 목표 근육량 (kg) |
| **주간 변화율** ||||
| weeklyWeightRate | Decimal | NULL | 주간 체중 변화 (kg) |
| weeklyFatPctRate | Decimal | NULL | 주간 체지방률 변화 (%) |
| weeklyMuscleRate | Decimal | NULL | 주간 근육량 변화 (kg) |
| **시작 시점 기록** ||||
| startWeight | Decimal | NULL | 시작 체중 (kg) |
| startBodyFatPct | Decimal | NULL | 시작 체지방률 (%) |
| startMuscleMass | Decimal | NULL | 시작 근육량 (kg) |
| startBMR | Decimal | NULL | 시작 BMR |
| startTDEE | Decimal | NULL | 시작 TDEE |
| **기타** ||||
| dailyCalorieTarget | Int32 | NULL | 일일 칼로리 목표 |
| isActive | Bool | NOT NULL, DEFAULT true | 활성 목표 여부 |
| createdAt | Date | NOT NULL | 생성일시 |
| updatedAt | Date | NOT NULL | 수정일시 |

**goalType 코드:**
```
0: 감량 (Lose)
1: 유지 (Maintain)
2: 증량 (Gain)
```

**목표 설정 규칙:**
```
- 최소 1개 이상 목표 설정 필수 (targetWeight, targetBodyFatPct, targetMuscleMass 중)
- 목표 설정 시 해당 시작값과 주간 변화율 함께 저장
- 목표 미설정 항목은 NULL
- startBMR, startTDEE는 목표 설정 시점의 값 저장
```

**목표 정합성 검증 (앱 레벨):**
```
복수 목표 설정 시 물리적 정합성 체크:

1. 체지방량 = 목표체중 × (목표체지방률 / 100)
2. 제지방량 = 목표체중 - 체지방량
3. 제지방량 ≥ 목표근육량 (근육은 제지방의 일부)

예시:
- 목표: 53kg, 18%, 25kg
- 체지방량 = 53 × 0.18 = 9.54kg
- 제지방량 = 53 - 9.54 = 43.46kg
- 43.46 ≥ 25 ✅ 유효
```

---

## 3. Phase 3 추가 Entity (소셜)

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│    Account      │       │   Friendship    │       │      Post       │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ PK id: UUID     │       │ PK id: UUID     │       │ PK id: UUID     │
│ FK userId: UUID │──1:N──│ FK userId: UUID │       │ FK accountId    │
│    email: String│       │ FK friendId     │       │    type: Int    │
│    nickname     │       │    status: Int  │       │    content: Str │
│    profileImage │       │    createdAt    │       │    imageUrl     │
│    bio: String  │       └─────────────────┘       │    createdAt    │
│    isPublic:Bool│                                 └─────────────────┘
│    createdAt    │
└─────────────────┘
```

> Phase 3 상세 설계는 MVP 완료 후 진행

---

## 4. 데이터 저장 전략

### 4.1 저장 원칙

```
📌 "계산은 변경 시점에 한 번, 조회는 저장된 값으로 빠르게"

- 값이 변경될 때만 계산하고 저장
- 조회 시에는 저장된 값 그대로 사용
- 관련 데이터 연쇄 업데이트 (트리거)
```

### 4.2 저장 위치 요약

| 데이터 | 저장 위치 | 업데이트 시점 |
|--------|-----------|---------------|
| 현재 BMR/TDEE | User.currentBMR/TDEE | 체성분/활동수준/키 변경 시 |
| 현재 체중/체지방률 | User.current* | 체성분 입력 시 |
| 체성분별 대사량 이력 | MetabolismSnapshot | 체성분 입력 시 (1:1 생성) |
| 일일 BMR/TDEE | DailyLog.bmr/tdee | DailyLog 생성 시 (User에서 복사) |
| 일일 섭취/소모 | DailyLog.total* | 음식/운동 입력/삭제 시 증분 |
| 일일 매크로 비율 | DailyLog.*Ratio | 음식 입력/삭제 시 재계산 |
| 일일 체성분 | DailyLog.weight/bodyFatPct | 체성분 입력 시 (당일만) |
| 일일 수면 | DailyLog.sleep* | 수면 입력 시 |

### 4.3 조회 성능 예시

| 화면 | 필요 쿼리 | 계산 여부 |
|------|-----------|-----------|
| 대시보드 | User 1건 + DailyLog 1건 | ❌ 계산 없음 |
| 체성분 그래프 | MetabolismSnapshot N건 | ❌ 계산 없음 |
| 주간 리포트 | DailyLog 7건 | 합계/평균만 |
| 목표 진행률 | User 1건 + Goal 1건 | ❌ 계산 없음 |

### 4.4 과거 날짜 DailyLog 생성 정책

```
과거 날짜에 기록 추가 시 DailyLog가 없으면:

1. 해당 날짜 이전의 가장 가까운 MetabolismSnapshot 찾기
2. 있으면 해당 스냅샷의 bmr/tdee 사용
3. 없으면 현재 User.currentBMR/TDEE 사용 (fallback)

예시:
- 1/1: 체성분 입력 (70kg) → BMR 1600
- 1/5: 체성분 입력 (72kg) → BMR 1650
- 1/10: 현재

1/3에 음식 추가 → 1/1 스냅샷 사용 (BMR 1600)
1/7에 음식 추가 → 1/5 스냅샷 사용 (BMR 1650)
12/25에 추가 → 현재 값 사용 (fallback)
```

---

*문서 버전: 2.1*
*작성일: 2026-01-11*
*수정: User 필드 추가, DailyLog 확장, MetabolismSnapshot 신규, Goal.goalType 추가, 데이터 저장 전략 섹션 추가*

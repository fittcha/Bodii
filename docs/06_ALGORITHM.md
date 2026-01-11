# Bodii - 알고리즘 명세서

## 1. 대사량 계산

### 1.1 선택: 하이브리드 방식

체지방률 입력 여부에 따라 다른 공식 적용

```
if 체지방률 != nil:
    Katch-McArdle 공식 사용
else:
    Mifflin-St Jeor 공식 사용
```

### 1.2 Mifflin-St Jeor 공식 (1990)

체지방률 없을 때 사용. 현재 가장 널리 검증된 공식.

**공식:**
```
남성: BMR = 10 × 체중(kg) + 6.25 × 키(cm) - 5 × 나이 + 5
여성: BMR = 10 × 체중(kg) + 6.25 × 키(cm) - 5 × 나이 - 161
```

**예시 (남성, 75kg, 175cm, 30세):**
```
BMR = 10 × 75 + 6.25 × 175 - 5 × 30 + 5
    = 750 + 1093.75 - 150 + 5
    = 1,698.75 kcal
```

### 1.3 Katch-McArdle 공식 (1975)

체지방률 있을 때 사용. 체성분 반영하여 더 정확.

**공식:**
```
제지방량(LBM) = 체중 × (1 - 체지방률/100)
BMR = 370 + (21.6 × LBM)
```

**예시 (75kg, 체지방률 18%):**
```
LBM = 75 × (1 - 18/100) = 75 × 0.82 = 61.5kg
BMR = 370 + (21.6 × 61.5) = 370 + 1328.4 = 1,698.4 kcal
```

### 1.4 활동대사량 (TDEE) 계산

**공식:**
```
TDEE = BMR × 활동계수
```

**활동계수 테이블:**

| 레벨 | 설명 | 계수 |
|------|------|------|
| 1 | 비활동적 (좌식 생활, 운동 안 함) | 1.2 |
| 2 | 가벼운 활동 (주 1-3일 가벼운 운동) | 1.375 |
| 3 | 보통 활동 (주 3-5일 적당한 운동) | 1.55 |
| 4 | 활동적 (주 6-7일 강한 운동) | 1.725 |
| 5 | 매우 활동적 (하루 2회 운동, 육체 노동) | 1.9 |

**예시 (BMR 1,698 kcal, 활동 레벨 3):**
```
TDEE = 1,698 × 1.55 = 2,631.9 kcal
```

### 1.5 구현 의사 코드

```swift
func calculateBMR(user: User, bodyRecord: BodyRecord) -> Double {
    if let bodyFatPercent = bodyRecord.bodyFatPercent {
        // Katch-McArdle
        let lbm = bodyRecord.weight * (1 - bodyFatPercent / 100)
        return 370 + (21.6 * lbm)
    } else {
        // Mifflin-St Jeor
        let age = calculateAge(from: user.birthDate)
        let base = 10 * bodyRecord.weight + 6.25 * user.height - 5 * Double(age)
        return user.gender == .male ? base + 5 : base - 161
    }
}

func calculateTDEE(bmr: Double, activityLevel: Int) -> Double {
    let multipliers = [1.2, 1.375, 1.55, 1.725, 1.9]
    return bmr * multipliers[activityLevel - 1]
}
```

---

## 2. 운동 칼로리 소모 계산

### 2.1 선택: HealthKit 우선 + MET 기반 (강도 보정)

```
if HealthKit 운동 데이터 있음:
    HealthKit 활동 칼로리 사용
else:
    MET 기반 계산 (강도 보정 적용)
```

### 2.2 MET (Metabolic Equivalent of Task)

1 MET = 안정 시 산소 소비량 = 약 1 kcal/kg/hour

**공식:**
```
소모 칼로리 = MET × 체중(kg) × 시간(hour)
```

### 2.3 운동별 MET 값

| 운동 종류 | 코드 | 기본 MET | 저강도 | 중강도 | 고강도 |
|----------|------|---------|--------|--------|--------|
| 걷기 | 0 | 3.5 | 2.8 | 3.5 | 4.2 |
| 러닝 | 1 | 8.0 | 6.4 | 8.0 | 9.6 |
| 자전거 | 2 | 6.0 | 4.8 | 6.0 | 7.2 |
| 수영 | 3 | 7.0 | 5.6 | 7.0 | 8.4 |
| 웨이트 | 4 | 6.0 | 4.8 | 6.0 | 7.2 |
| 크로스핏 | 5 | 8.0 | 6.4 | 8.0 | 9.6 |
| 요가 | 6 | 3.0 | 2.4 | 3.0 | 3.6 |
| 기타 | 7 | 5.0 | 4.0 | 5.0 | 6.0 |

### 2.4 강도 보정 계수

```
저강도: 기본 MET × 0.8
중강도: 기본 MET × 1.0
고강도: 기본 MET × 1.2
```

### 2.5 예시

**크로스핏 45분, 고강도, 체중 75kg:**
```
보정 MET = 8.0 × 1.2 = 9.6
시간 = 45분 = 0.75시간
소모 칼로리 = 9.6 × 75 × 0.75 = 540 kcal
```

### 2.6 구현 의사 코드

```swift
struct METTable {
    static let values: [ExerciseType: Double] = [
        .walking: 3.5,
        .running: 8.0,
        .cycling: 6.0,
        .swimming: 7.0,
        .weight: 6.0,
        .crossfit: 8.0,
        .yoga: 3.0,
        .other: 5.0
    ]
}

func calculateExerciseCalories(
    type: ExerciseType,
    duration: Int,  // 분
    intensity: Intensity,
    weight: Double
) -> Int {
    let baseMET = METTable.values[type] ?? 5.0
    
    let intensityMultiplier: Double
    switch intensity {
    case .low: intensityMultiplier = 0.8
    case .medium: intensityMultiplier = 1.0
    case .high: intensityMultiplier = 1.2
    }
    
    let adjustedMET = baseMET * intensityMultiplier
    let hours = Double(duration) / 60.0
    
    return Int(adjustedMET * weight * hours)
}
```

---

## 3. 목표 체중 달성 예측

### 3.1 선택: 단계별 전환

데이터 양에 따라 예측 알고리즘 자동 전환

```
if 데이터 < 7일:
    선형 예측
else if 데이터 < 14일:
    지수 평활법 (α = 0.2)
else:
    7일 이동 평균 기반 예측
```

### 3.2 선형 예측

데이터 부족 시 목표 기반 단순 예측

**공식:**
```
일일 목표 변화량 = 주간 목표 / 7
N일 후 예상 체중 = 현재 체중 + (일일 목표 변화량 × N)
예상 달성일 = 시작일 + (목표까지 남은 체중 / 일일 목표 변화량)
```

**예시 (현재 75kg, 목표 70kg, 주 0.5kg 감량):**
```
일일 목표 = -0.5 / 7 = -0.071 kg/일
남은 체중 = 75 - 70 = 5kg
예상 일수 = 5 / 0.071 = 70일
```

### 3.3 지수 평활법 (Exponential Smoothing)

7~14일 데이터 시 사용. 최근 데이터에 가중치.

**공식:**
```
S(t) = α × Y(t) + (1 - α) × S(t-1)

S(t): 시점 t의 평활값
Y(t): 시점 t의 실제 측정값
α: 평활 계수 (0.2 사용)
S(t-1): 이전 평활값
```

**초기값:**
```
S(1) = Y(1)  // 첫 번째 측정값
```

**추세 계산:**
```
일일 추세 = S(오늘) - S(어제)
예상 달성일 = 오늘 + (남은 체중 / |일일 추세|)
```

**예시 (α = 0.2):**
```
Day 1: Y=75.0, S=75.0
Day 2: Y=74.8, S = 0.2×74.8 + 0.8×75.0 = 74.96
Day 3: Y=75.2, S = 0.2×75.2 + 0.8×74.96 = 75.01
Day 4: Y=74.5, S = 0.2×74.5 + 0.8×75.01 = 74.91
...
```

### 3.4 이동 평균 기반 예측

14일 이상 데이터 시 사용. 가장 정확.

**공식:**
```
MA(t) = (Y(t) + Y(t-1) + ... + Y(t-6)) / 7

주간 추세 = MA(오늘) - MA(7일 전)
일일 추세 = 주간 추세 / 7
예상 달성일 = 오늘 + (남은 체중 / |일일 추세|)
```

**예시:**
```
이번 주 평균: 74.2kg
지난 주 평균: 74.9kg
주간 추세 = 74.2 - 74.9 = -0.7kg
일일 추세 = -0.7 / 7 = -0.1kg/일

현재: 74.2kg, 목표: 70kg
남은: 4.2kg
예상 일수 = 4.2 / 0.1 = 42일
```

### 3.5 구현 의사 코드

```swift
func predictGoalAchievement(
    records: [BodyRecord],
    goal: Goal
) -> Date? {
    let sortedRecords = records.sorted { $0.date < $1.date }
    let dayCount = sortedRecords.count
    
    guard let currentWeight = sortedRecords.last?.weight else { return nil }
    let remainingWeight = abs(currentWeight - goal.targetWeight)
    
    let dailyTrend: Double
    
    if dayCount < 7 {
        // 선형 예측
        dailyTrend = goal.weeklyRate / 7
    } else if dayCount < 14 {
        // 지수 평활법
        dailyTrend = calculateExponentialSmoothing(records: sortedRecords, alpha: 0.2)
    } else {
        // 이동 평균
        dailyTrend = calculateMovingAverageTrend(records: sortedRecords, window: 7)
    }
    
    guard dailyTrend != 0 else { return nil }
    
    let daysToGoal = Int(remainingWeight / abs(dailyTrend))
    return Calendar.current.date(byAdding: .day, value: daysToGoal, to: Date())
}
```

---

## 4. 음식 검색/매칭

### 4.1 선택: 복합 검색 + AI 매핑 테이블

**1차 MVP (수동 검색):**
```
1순위: Contains (포함 검색)
2순위: 초성 검색
3순위: Levenshtein 유사도 (거리 ≤ 2)
```

**2차 AI (영어 라벨 → 한글):**
```
1순위: 매핑 테이블
2순위: DB 영문명 검색
3순위: 사용자 직접 선택
```

### 4.2 Contains 검색

**로직:**
```
검색어가 음식명에 포함되어 있는지 확인
"김치" → "김치찌개", "김치볶음밥", "백김치" 등
```

### 4.3 초성 검색

한글 초성만으로 검색 가능

**초성 추출:**
```
'가' ~ '깋' → 'ㄱ'
'나' ~ '닣' → 'ㄴ'
...

초성 유니코드 = (문자코드 - 0xAC00) / 588
```

**예시:**
```
"ㄱㅊㅉㄱ" → "김치찌개"
"ㅂㅂㅂ" → "비빔밥"
"ㄷㄱㅅㅅ" → "닭가슴살"
```

### 4.4 Levenshtein Distance (편집 거리)

오타 허용 검색

**정의:**
```
두 문자열 간 한 문자를 삽입/삭제/교체하여 
같게 만드는 최소 연산 횟수
```

**예시:**
```
"김치찌게" vs "김치찌개" → 거리 1 (교체: 게→개)
"삼겹살" vs "삼겹쌀" → 거리 1 (교체: 살→쌀)
```

**임계값:**
```
거리 ≤ 2 → 매칭 허용
거리 > 2 → 매칭 안 함
```

### 4.5 검색 우선순위 로직

```swift
func searchFood(query: String, database: [Food]) -> [Food] {
    var results: [(food: Food, priority: Int)] = []
    
    for food in database {
        // 1순위: 정확히 포함
        if food.name.contains(query) {
            results.append((food, 1))
            continue
        }
        
        // 2순위: 초성 매칭
        let queryChosung = extractChosung(query)
        let foodChosung = extractChosung(food.name)
        if foodChosung.contains(queryChosung) {
            results.append((food, 2))
            continue
        }
        
        // 3순위: 유사도 (Levenshtein ≤ 2)
        let distance = levenshteinDistance(query, food.name)
        if distance <= 2 {
            results.append((food, 3))
        }
    }
    
    // 우선순위순 정렬
    return results.sorted { $0.priority < $1.priority }.map { $0.food }
}
```

### 4.6 AI 영어→한글 매핑 테이블

Google Vision API 결과를 한글 음식명으로 변환

**매핑 구조:**
```swift
let foodMapping: [String: [String]] = [
    // 밥류
    "rice": ["밥", "공기밥", "흰쌀밥"],
    "fried rice": ["볶음밥", "김치볶음밥", "새우볶음밥"],
    "bibimbap": ["비빔밥"],
    
    // 국/찌개
    "soup": ["국", "찌개", "탕"],
    "stew": ["찌개", "전골"],
    "kimchi stew": ["김치찌개"],
    
    // 고기
    "chicken": ["닭고기", "치킨", "닭가슴살"],
    "pork": ["돼지고기", "삼겹살"],
    "beef": ["소고기", "불고기"],
    
    // 반찬
    "kimchi": ["김치", "배추김치"],
    "egg": ["계란", "달걀", "계란프라이"],
    
    // ... 상위 100개 음식 매핑
]
```

---

## 5. 그래프 데이터 처리

### 5.1 선택: 레이어 방식 + 조건부 보간

**레이어 구성:**
```
레이어 1: 원본 데이터 점 (30일 이내 선형 보간, 초과 시 끊김)
레이어 2: 이동 평균선 (7일+, 항상 연결)
레이어 3: 목표선 (Phase 2, 목표 설정 시)
```

### 5.2 원본 데이터 처리

**보간 규칙:**
```
if 두 점 사이 간격 ≤ 30일:
    선형 보간으로 연결
else:
    연결 안 함 (끊김)
```

**선형 보간 공식:**
```
Y(t) = Y(t1) + (Y(t2) - Y(t1)) × (t - t1) / (t2 - t1)

t: 보간할 시점
t1, t2: 양쪽 측정 시점
Y(t1), Y(t2): 양쪽 측정값
```

**예시:**
```
1/1: 75kg, 1/5: 73kg (간격 4일 ≤ 30일 → 보간)

1/2: 75 + (73-75) × (1/4) = 74.5kg
1/3: 75 + (73-75) × (2/4) = 74.0kg
1/4: 75 + (73-75) × (3/4) = 73.5kg
```

### 5.3 이동 평균선 (추세선)

**7일 이동 평균:**
```
MA(t) = Σ Y(t-i) / n, where i = 0 to 6 (존재하는 데이터만)
```

**끊김 없이 연결:**
- 데이터 없는 날도 이전 평균값 유지
- 새 데이터 들어오면 평균 업데이트

### 5.4 구현 의사 코드

```swift
struct ChartDataPoint {
    let date: Date
    let value: Double
    let isInterpolated: Bool  // 보간된 값인지 여부
}

func processChartData(records: [BodyRecord]) -> (
    original: [ChartDataPoint],
    movingAverage: [ChartDataPoint]
) {
    var originalPoints: [ChartDataPoint] = []
    var maPoints: [ChartDataPoint] = []
    
    let sorted = records.sorted { $0.date < $1.date }
    
    for i in 0..<sorted.count {
        let current = sorted[i]
        
        // 원본 점 추가
        originalPoints.append(ChartDataPoint(
            date: current.date,
            value: current.weight,
            isInterpolated: false
        ))
        
        // 이전 점과 보간 (7일 이내)
        if i > 0 {
            let previous = sorted[i - 1]
            let daysBetween = Calendar.current.dateComponents(
                [.day], from: previous.date, to: current.date
            ).day ?? 0
            
            if daysBetween <= 30 && daysBetween > 1 {
                // 선형 보간
                for d in 1..<daysBetween {
                    let ratio = Double(d) / Double(daysBetween)
                    let interpolatedValue = previous.weight + 
                        (current.weight - previous.weight) * ratio
                    let interpolatedDate = Calendar.current.date(
                        byAdding: .day, value: d, to: previous.date
                    )!
                    
                    originalPoints.append(ChartDataPoint(
                        date: interpolatedDate,
                        value: interpolatedValue,
                        isInterpolated: true
                    ))
                }
            }
        }
    }
    
    // 이동 평균 계산 (항상 연결)
    maPoints = calculateMovingAverage(points: originalPoints, window: 7)
    
    return (originalPoints.sorted { $0.date < $1.date }, maPoints)
}
```

### 5.5 시각적 구분

```
● 실제 측정값 (진한 색, 큰 점)
○ 보간값 (연한 색, 작은 점 또는 선만)
─ 원본 연결선 (30일 이내만)
╌ 이동 평균선 (점선, 항상 연결)
┄ 목표선 (다른 색 점선)
```

---

## 6. 알고리즘 선택 요약

| 영역 | 알고리즘 | 선택 이유 |
|------|----------|-----------|
| **대사량** | 하이브리드 (Katch-McArdle + Mifflin-St Jeor) | 체지방률 유무에 따라 최적 공식 적용 |
| **운동 칼로리** | HealthKit 우선 + MET (강도 보정) | 정확도 높은 데이터 우선, 없으면 표준 계산 |
| **목표 예측** | 단계별 전환 (선형→지수평활→이동평균) | 데이터 축적에 따라 정확도 향상 |
| **음식 검색** | 복합 (Contains→초성→유사도) | 한글 특성 반영, 오타 허용 |
| **그래프** | 조건부 보간 (30일 이내) + 추세선 연결 | 정직한 표현 + 추세 파악 용이, 주 1회 측정자 고려 |

---

*문서 버전: 1.0*
*작성일: 2026-01-11*

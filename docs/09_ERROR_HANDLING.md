# Bodii - 에러 핸들링 정책

## 1. 에러 분류 체계

### 1.1 에러 심각도

| 레벨 | 이름 | 설명 | 예시 |
|------|------|------|------|
| **Critical** | 치명적 | 앱 사용 불가 | Core Data 초기화 실패 |
| **Error** | 오류 | 기능 사용 불가 | API 호출 실패 |
| **Warning** | 경고 | 기능 제한 | 네트워크 불안정 |
| **Info** | 정보 | 사용자 안내 | 검색 결과 없음 |

### 1.2 에러 타입

```swift
enum BodiiError: Error {
    // 네트워크
    case networkUnavailable
    case networkTimeout
    case serverError(code: Int)
    
    // API
    case apiRateLimitExceeded
    case apiKeyInvalid
    case apiResponseParsingFailed
    case apiQuotaExceeded
    
    // 데이터
    case coreDataSaveFailed
    case coreDataFetchFailed
    case dataValidationFailed(field: String, reason: String)
    case dataNotFound
    
    // 권한
    case healthKitPermissionDenied
    case cameraPermissionDenied
    case photoLibraryPermissionDenied
    
    // 비즈니스
    case userNotOnboarded
    case insufficientData
}
```

---

## 2. API별 에러 핸들링

### 2.1 식약처 API (공공데이터포털)

| 에러 상황 | HTTP 코드 | 처리 방안 | 사용자 메시지 |
|----------|-----------|-----------|---------------|
| 네트워크 끊김 | - | USDA 폴백 불가, 로컬 데이터만 | "네트워크 연결을 확인해주세요" |
| 타임아웃 (5초) | - | 1회 재시도 → USDA 폴백 | (자동 처리, 메시지 없음) |
| 서버 에러 | 500 | USDA 폴백 | (자동 처리, 메시지 없음) |
| 인증 오류 | 401 | 로그 기록 + USDA 폴백 | (자동 처리, 메시지 없음) |
| 데이터 없음 | 200 (빈 배열) | USDA 폴백 | (자동 처리, 메시지 없음) |
| 파싱 실패 | - | USDA 폴백 | (자동 처리, 메시지 없음) |

**구현:**
```swift
class FoodAPIService {
    private let timeout: TimeInterval = 5.0
    private let maxRetry = 1
    
    func searchFood(_ query: String) async throws -> [Food] {
        do {
            return try await searchFromFoodSafetyKorea(query)
        } catch {
            // 식약처 실패 → USDA 폴백
            return try await searchFromUSDA(query)
        }
    }
}
```

### 2.2 USDA API

| 에러 상황 | HTTP 코드 | 처리 방안 | 사용자 메시지 |
|----------|-----------|-----------|---------------|
| 네트워크 끊김 | - | 로컬 데이터만 표시 | "네트워크 연결을 확인해주세요" |
| 타임아웃 (5초) | - | 1회 재시도 | "검색 중..." |
| Rate Limit | 429 | 30초 대기 후 재시도 | "잠시 후 다시 시도해주세요" |
| API 키 오류 | 401 | 로그 기록 | "음식 검색에 문제가 있습니다" |
| 데이터 없음 | 200 (빈 배열) | 직접 입력 유도 | "검색 결과가 없습니다. 직접 입력해주세요" |

### 2.3 Gemini API (AI 코멘트)

| 에러 상황 | 처리 방안 | 사용자 메시지 |
|----------|-----------|---------------|
| 네트워크 끊김 | 코멘트 버튼 비활성화 | "네트워크 연결 시 AI 코멘트를 받을 수 있어요" |
| Rate Limit (15 RPM) | 요청 큐잉, 순차 처리 | "잠시만 기다려주세요..." |
| 월 쿼터 초과 | 기능 비활성화 | "이번 달 AI 코멘트 사용량을 초과했습니다" |
| 응답 파싱 실패 | 기본 코멘트 표시 | 사전 정의된 일반 코멘트 |
| 타임아웃 (10초) | 1회 재시도 | "응답 대기 중..." |
| 콘텐츠 필터링 | 기본 코멘트 표시 | 사전 정의된 일반 코멘트 |

**기본 코멘트 예시:**
```swift
let defaultComment = AIComment(
    good: "오늘도 식단 기록을 잘 하고 계시네요!",
    improve: "다양한 영양소를 섭취해보세요.",
    summary: "꾸준한 기록이 건강의 시작입니다.",
    score: 7
)
```

### 2.4 Google Cloud Vision API (Phase 2)

| 에러 상황 | 처리 방안 | 사용자 메시지 |
|----------|-----------|---------------|
| 네트워크 끊김 | 수동 검색 유도 | "네트워크 연결을 확인해주세요. 직접 검색할 수 있어요" |
| 월 쿼터 초과 (1000건) | 기능 비활성화 | "이번 달 사진 인식 사용량을 초과했습니다. 검색으로 입력해주세요" |
| 인식 실패 | 수동 검색 유도 | "음식을 인식하지 못했어요. 직접 검색해주세요" |
| 이미지 너무 큼 | 리사이징 후 재시도 | (자동 처리, 메시지 없음) |

---

## 3. 로컬 에러 핸들링

### 3.1 Core Data

| 에러 상황 | 처리 방안 | 사용자 메시지 |
|----------|-----------|---------------|
| 저장 실패 | 3회 재시도 → 실패 시 알림 | "저장에 실패했습니다. 다시 시도해주세요" |
| 조회 실패 | 빈 데이터로 표시 | "데이터를 불러올 수 없습니다" |
| 마이그레이션 실패 | 앱 재설치 유도 | "앱을 재설치해주세요. 데이터가 손실될 수 있습니다" |
| 저장 공간 부족 | 저장 차단 + 알림 | "저장 공간이 부족합니다" |

**구현:**
```swift
class PersistenceController {
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        var retryCount = 0
        while retryCount < 3 {
            do {
                try context.save()
                return
            } catch {
                retryCount += 1
                if retryCount >= 3 {
                    throw BodiiError.coreDataSaveFailed
                }
            }
        }
    }
}
```

### 3.2 HealthKit

| 에러 상황 | 처리 방안 | 사용자 메시지 |
|----------|-----------|---------------|
| 권한 거부 | 설정 앱 유도 | "건강 앱에서 Bodii 권한을 허용해주세요" + [설정 열기] 버튼 |
| 권한 미결정 | 권한 요청 재시도 | (권한 요청 다이얼로그) |
| 데이터 없음 | 빈 상태 표시 | "HealthKit에 데이터가 없습니다" |
| 동기화 실패 | 백그라운드 재시도 | (사용자에게 알리지 않음) |

**설정 앱 열기:**
```swift
func openHealthSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

### 3.3 입력 검증

| 검증 실패 | 처리 방안 | 사용자 메시지 |
|----------|-----------|---------------|
| 필수 필드 누락 | 저장 버튼 비활성화 + 필드 강조 | "필수 항목을 입력해주세요" |
| 범위 초과 | 저장 차단 + 필드 에러 표시 | "[필드명]은 [범위]여야 합니다" |
| 형식 오류 | 입력 무시 또는 자동 수정 | (실시간 수정) |

---

## 4. 사용자 알림 가이드

### 4.1 알림 유형

| 유형 | 사용 상황 | UI 컴포넌트 | 지속 시간 |
|------|----------|-------------|-----------|
| **Toast** | 성공, 간단한 정보 | 하단 슬라이드 | 2초 |
| **Snackbar** | 경고, 되돌리기 가능 | 하단 고정 + 액션 버튼 | 5초 |
| **Alert** | 중요 결정, 확인 필요 | 모달 다이얼로그 | 사용자 액션까지 |
| **Banner** | 지속적 상태 알림 | 상단 고정 배너 | 상태 해제까지 |
| **Inline** | 필드별 에러 | 필드 아래 텍스트 | 수정까지 |

### 4.2 메시지 작성 원칙

```
✅ 좋은 예시:
- "체중은 20~300kg 사이로 입력해주세요"
- "네트워크 연결을 확인해주세요"
- "저장에 실패했습니다. 다시 시도해주세요"

❌ 나쁜 예시:
- "Error: Invalid input"
- "Network Error 500"
- "Something went wrong"
```

**원칙:**
1. **구체적으로** - 무엇이 문제인지
2. **해결책 제시** - 어떻게 해결하는지
3. **친근하게** - 기술 용어 배제
4. **한국어로** - 영어 에러 메시지 금지

### 4.3 에러 메시지 표

| 에러 코드 | 사용자 메시지 | 액션 버튼 |
|----------|---------------|-----------|
| `networkUnavailable` | 네트워크 연결을 확인해주세요 | [다시 시도] |
| `networkTimeout` | 응답이 늦어지고 있어요. 다시 시도해주세요 | [다시 시도] |
| `apiRateLimitExceeded` | 잠시 후 다시 시도해주세요 | - |
| `apiQuotaExceeded` | 이번 달 사용량을 초과했습니다 | - |
| `coreDataSaveFailed` | 저장에 실패했습니다. 다시 시도해주세요 | [다시 시도] |
| `healthKitPermissionDenied` | 건강 앱에서 권한을 허용해주세요 | [설정 열기] |
| `userNotOnboarded` | 먼저 기본 정보를 입력해주세요 | [시작하기] |
| `dataValidationFailed` | {field}을(를) 확인해주세요 | - |

---

## 5. 로깅 정책

### 5.1 로그 레벨

| 레벨 | 용도 | 예시 |
|------|------|------|
| **Debug** | 개발용 상세 로그 | API 요청/응답 전체 |
| **Info** | 주요 이벤트 | 사용자 액션, 화면 전환 |
| **Warning** | 경고 상황 | Rate Limit 근접, 재시도 |
| **Error** | 에러 발생 | API 실패, 저장 실패 |
| **Critical** | 치명적 에러 | 앱 크래시, 데이터 손상 |

### 5.2 로그 포맷

```swift
// 개발 환경
[2026-01-11 14:30:45] [ERROR] [FoodAPIService] 
  식약처 API 호출 실패
  - URL: https://api.example.com/food
  - Status: 500
  - Response: {"error": "Internal Server Error"}
  - 재시도: 1/1

// 프로덕션 환경 (민감 정보 제외)
[2026-01-11 14:30:45] [ERROR] [FoodAPIService] 
  식약처 API 호출 실패 (Status: 500)
```

### 5.3 수집 항목

| 항목 | 개발 환경 | 프로덕션 환경 |
|------|----------|---------------|
| API URL | ✅ | ✅ |
| HTTP Status | ✅ | ✅ |
| Request Body | ✅ | ❌ |
| Response Body | ✅ | ❌ |
| 사용자 ID | ✅ | ❌ (익명화) |
| 기기 정보 | ✅ | ✅ (모델, OS만) |
| 스택 트레이스 | ✅ | ✅ (에러 시) |

---

## 6. 재시도 정책

### 6.1 API별 재시도

| API | 재시도 횟수 | 대기 시간 | 백오프 |
|-----|------------|-----------|--------|
| 식약처 | 1회 | 0초 | - |
| USDA | 1회 | 0초 | - |
| Gemini | 1회 | 1초 | 지수 (2초) |
| Vision | 1회 | 0초 | - |
| HealthKit | 3회 | 1초 | 지수 (2초, 4초) |

### 6.2 Core Data 재시도

```swift
func saveWithRetry(maxAttempts: Int = 3) async throws {
    var attempt = 0
    var lastError: Error?
    
    while attempt < maxAttempts {
        do {
            try context.save()
            return
        } catch {
            lastError = error
            attempt += 1
            
            // 지수 백오프
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
            }
        }
    }
    
    throw lastError ?? BodiiError.coreDataSaveFailed
}
```

---

## 7. 폴백 전략

### 7.1 음식 검색 폴백

```
사용자 검색
    ↓
┌─────────────┐
│  식약처 API  │
└──────┬──────┘
       │ 실패
       ↓
┌─────────────┐
│  USDA API   │
└──────┬──────┘
       │ 실패
       ↓
┌─────────────┐
│ 로컬 캐시   │
│ (최근 검색) │
└──────┬──────┘
       │ 없음
       ↓
┌─────────────┐
│ 직접 입력   │
│    유도     │
└─────────────┘
```

### 7.2 오프라인 모드

```swift
class OfflineManager {
    var isOffline: Bool {
        !NetworkMonitor.shared.isConnected
    }
    
    func getAvailableFeatures() -> [Feature] {
        if isOffline {
            return [
                .bodyRecordInput,
                .bodyRecordHistory,
                .foodRecordFromRecent,  // 최근 음식만
                .foodRecordDirect,       // 직접 입력
                .exerciseRecord,
                .sleepRecord,
                .dashboard,
                .charts
            ]
        }
        return Feature.allCases
    }
    
    func getDisabledFeatures() -> [Feature] {
        if isOffline {
            return [
                .foodSearch,        // API 필요
                .aiComment,         // API 필요
                .photoRecognition   // API 필요
            ]
        }
        return []
    }
}
```

---

## 8. 에러 복구 시나리오

### 8.1 앱 크래시 후 재시작

```
앱 크래시
    ↓
앱 재시작
    ↓
┌─────────────────────────────────────┐
│ 1. Core Data 무결성 검사            │
│ 2. 미저장 데이터 복구 시도          │
│ 3. DailyLog 정합성 검증             │
│ 4. 정상 화면으로 진입               │
└─────────────────────────────────────┘
```

### 8.2 데이터 정합성 복구

```swift
class DataIntegrityService {
    
    func verifyAndRepair() async {
        // 1. DailyLog 합계 검증
        await verifyDailyLogTotals()
        
        // 2. User.current* 검증
        await verifyUserCurrentValues()
        
        // 3. 고아 레코드 정리
        await cleanOrphanRecords()
    }
    
    private func verifyDailyLogTotals() async {
        let dailyLogs = fetchAllDailyLogs()
        
        for log in dailyLogs {
            let actualCalories = calculateActualCalories(for: log.date)
            
            if log.totalCaloriesIn != actualCalories {
                log.totalCaloriesIn = actualCalories
                // 다른 필드도 재계산...
            }
        }
        
        try? await save()
    }
}
```

---

## 9. 테스트 체크리스트

### 9.1 네트워크 에러 테스트

- [ ] 비행기 모드에서 음식 검색
- [ ] 느린 네트워크에서 API 타임아웃
- [ ] 네트워크 전환 중 API 호출 (WiFi → LTE)
- [ ] 서버 500 에러 시뮬레이션

### 9.2 데이터 에러 테스트

- [ ] Core Data 저장 실패 시뮬레이션
- [ ] 유효하지 않은 데이터 입력
- [ ] 저장 공간 부족 시뮬레이션
- [ ] 앱 강제 종료 후 데이터 복구

### 9.3 권한 에러 테스트

- [ ] HealthKit 권한 거부 → 재요청
- [ ] 카메라 권한 거부 (Phase 2)
- [ ] 알림 권한 거부

---

*문서 버전: 1.0*
*작성일: 2026-01-11*

# Bodii - 포트폴리오 & 학습 포인트

## 1. 개요

이 문서는 Bodii 프로젝트를 통해 학습할 수 있는 기술과 이직 포트폴리오에서 어필할 수 있는 포인트를 정리합니다.

---

## 2. 아키텍처 어필 포인트

### 2.1 Clean Architecture + MVVM

**면접 어필:**
> "Clean Architecture를 적용하여 Domain, Data, Presentation 레이어를 분리했습니다. 
> UseCase 패턴으로 비즈니스 로직을 캡슐화하여 단위 테스트가 용이하고,
> Repository 패턴으로 데이터 소스 교체가 쉬운 구조로 설계했습니다."

**구체적 설명:**
```
✅ 강점:
- 레이어 분리로 관심사 분리 (SoC)
- UseCase별 단위 테스트 가능
- Protocol로 의존성 역전 (DIP)
- 데이터 소스 교체 용이 (OCP)

📝 코드 예시:
- CalculateBMRUseCase: 체지방률 유무에 따른 공식 분기
- BodyRepositoryProtocol: Core Data ↔ Mock 교체 가능
```

### 2.2 SOLID 원칙 적용

| 원칙 | 적용 예시 | 설명 |
|------|----------|------|
| **SRP** | UseCase 분리 | CalculateBMR, CalculateTDEE 각각 분리 |
| **OCP** | Repository Protocol | 새 데이터소스 추가 시 기존 코드 수정 없음 |
| **LSP** | Protocol 구현 | MockRepository가 실제 Repository 대체 가능 |
| **ISP** | 작은 Protocol | BodyRepositoryProtocol에 Body 관련만 |
| **DIP** | Protocol 의존 | ViewModel이 Protocol에 의존, 구현체 아님 |

---

## 3. 직접 구현 vs 라이브러리

### 3.1 직접 구현 (포트폴리오 어필용)

#### 네트워크 레이어

**면접 어필:**
> "URLSession과 async/await를 활용하여 네트워크 레이어를 직접 구현했습니다.
> Generic을 활용한 타입 안전한 API 클라이언트를 만들어
> 라이브러리 의존성 없이도 깔끔한 네트워크 처리가 가능함을 보여드릴 수 있습니다."

```swift
// 📚 학습 포인트: Generic, async/await, Result 타입

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
}

final class NetworkManager {
    static let shared = NetworkManager()
    
    // Generic을 활용한 타입 안전한 API 호출
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        guard let url = buildURL(from: endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

**어필 포인트:**
- ✅ Swift Concurrency (async/await) 이해
- ✅ Generic을 활용한 타입 안전성
- ✅ 에러 핸들링 (커스텀 Error 타입)
- ✅ Protocol 기반 설계 (테스트 용이)

---

#### 이미지 캐싱

**면접 어필:**
> "NSCache를 활용한 메모리 캐싱과 FileManager를 활용한 디스크 캐싱을 직접 구현하여
> 이미지 로딩 최적화를 구현했습니다."

```swift
// 📚 학습 포인트: NSCache, FileManager, Actor

actor ImageCacheManager {
    static let shared = ImageCacheManager()
    
    // 메모리 캐시 (빠름, 휘발성)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // 디스크 캐시 경로
    private let diskCacheURL: URL
    
    init() {
        let cacheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // 캐시 폴더 생성
        try? FileManager.default.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )
    }
    
    func image(for url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString
        
        // 1. 메모리 캐시 확인
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }
        
        // 2. 디스크 캐시 확인
        let diskPath = diskCacheURL.appendingPathComponent(key.hash.description)
        if let data = try? Data(contentsOf: diskPath),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        // 3. 네트워크 요청
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidData
        }
        
        // 캐시 저장
        memoryCache.setObject(image, forKey: key)
        try? data.write(to: diskPath)
        
        return image
    }
}
```

**어필 포인트:**
- ✅ Actor를 활용한 동시성 안전
- ✅ 2단계 캐싱 전략 (메모리 → 디스크)
- ✅ FileManager 활용
- ✅ NSCache 메모리 관리

---

#### 에러 핸들링

**면접 어필:**
> "Swift의 Error 프로토콜을 활용하여 도메인별 커스텀 에러 타입을 설계하고,
> 사용자 친화적인 에러 메시지를 제공했습니다."

```swift
// 📚 학습 포인트: Error Protocol, LocalizedError, Associated Value

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(underlying: Error)
    case networkError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .invalidResponse:
            return "서버 응답을 처리할 수 없습니다"
        case .httpError(let statusCode):
            return "서버 오류가 발생했습니다 (코드: \(statusCode))"
        case .decodingError:
            return "데이터 형식이 올바르지 않습니다"
        case .networkError:
            return "네트워크 연결을 확인해주세요"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Wi-Fi 또는 데이터 연결을 확인하고 다시 시도해주세요"
        default:
            return "잠시 후 다시 시도해주세요"
        }
    }
}
```

**어필 포인트:**
- ✅ LocalizedError 프로토콜 활용
- ✅ Associated Value로 상세 정보 전달
- ✅ 사용자 친화적 에러 메시지

---

### 3.2 사용할 라이브러리

| 라이브러리 | 용도 | 이유 |
|------------|------|------|
| **SwiftLint** | 코드 컨벤션 | 코드 품질 관리 필수 |
| **Swift Charts** | 차트 | 애플 공식, 서드파티 불필요 |

### 3.3 사용하지 않을 라이브러리

| 라이브러리 | 대체 | 포트폴리오 어필 |
|------------|------|----------------|
| Alamofire | URLSession + async/await | "Swift Concurrency 이해" |
| RxSwift | Combine | "애플 프레임워크 활용" |
| Kingfisher | 직접 구현 (간단 버전) | "캐싱 원리 이해" |
| SnapKit | SwiftUI 네이티브 | "최신 UI 프레임워크" |

---

## 4. Swift/iOS 핵심 학습 포인트

### 4.1 Swift 문법

| 개념 | 태스크 | 학습 내용 |
|------|--------|----------|
| **Optional** | TASK-041 | if let, guard let, ?? 연산자 |
| **Enum** | TASK-076 | Raw Value, Associated Value, 연산 프로퍼티 |
| **Protocol** | TASK-043 | 프로토콜 정의, 기본 구현, 의존성 주입 |
| **Generic** | 네트워크 | 타입 파라미터, where 절, 타입 제약 |
| **Closure** | API 콜백 | 탈출 클로저, 약한 참조, 후행 클로저 |
| **async/await** | TASK-052 | 비동기 프로그래밍, Task, MainActor |

### 4.2 SwiftUI

| 개념 | 태스크 | 학습 내용 |
|------|--------|----------|
| **@State** | 모든 View | 뷰 내부 상태 관리 |
| **@Binding** | TASK-041 | 부모-자식 상태 공유 |
| **@Observable** | ViewModel | iOS 17+ 상태 관리 |
| **@Environment** | DI | 의존성 주입 |
| **NavigationStack** | TASK-020 | iOS 16+ 네비게이션 |
| **Charts** | TASK-042 | Swift Charts 프레임워크 |

### 4.3 iOS 프레임워크

| 프레임워크 | 태스크 | 학습 내용 |
|------------|--------|----------|
| **Core Data** | TASK-002 | 모델 정의, CRUD, 관계 |
| **HealthKit** | TASK-070 | 권한 요청, 데이터 읽기/쓰기 |
| **Combine** | ViewModel | Publisher, Subscriber |
| **Foundation** | 전체 | Date, Calendar, NumberFormatter |

---

## 5. 태스크별 학습 매핑

### Phase 1: MVP

| 태스크 | 핵심 학습 | 난이도 | 포폴 가치 |
|--------|----------|--------|----------|
| TASK-002 Core Data | Entity, Relationship, Migration | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| TASK-010 온보딩 | PageView, Navigation, State | ⭐⭐ | ⭐⭐ |
| TASK-041 체성분 입력 | Form, Validation, Sheet | ⭐⭐ | ⭐⭐ |
| TASK-042 그래프 | Swift Charts, 데이터 변환 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| TASK-043 BMR/TDEE | 비즈니스 로직, UseCase | ⭐⭐ | ⭐⭐⭐ |
| TASK-052 식약처 API | URLSession, async/await, JSON | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| TASK-052-B USDA API | 다중 API 통합, 우선순위 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| TASK-055 AI 코멘트 | Gemini API, 프롬프트 설계 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| TASK-070 HealthKit | 권한, 데이터 동기화 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| TASK-076 수면 상태 | Enum, 비즈니스 규칙 | ⭐⭐ | ⭐⭐⭐ |

### Phase 2: AI

| 태스크 | 핵심 학습 | 난이도 | 포폴 가치 |
|--------|----------|--------|----------|
| TASK-101 Vision API | 이미지 처리, ML API | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| TASK-110 목표 설정 | 복잡한 Form, 검증 로직 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| TASK-112 예측 그래프 | 데이터 분석, 시각화 | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 6. 면접 예상 질문 & 답변

### 6.1 아키텍처

**Q: 왜 Clean Architecture를 선택했나요?**
> A: 테스트 용이성과 유지보수성을 위해 선택했습니다. 
> UseCase로 비즈니스 로직을 분리하여 단위 테스트가 쉽고,
> Repository Protocol로 데이터 소스를 추상화하여 Mock 테스트가 가능합니다.
> 실제로 BMR 계산 UseCase의 테스트 커버리지를 90% 이상 달성했습니다.

**Q: MVVM과 MVC의 차이는?**
> A: MVC에서는 Controller가 비대해지는 Massive View Controller 문제가 있습니다.
> MVVM은 View와 비즈니스 로직을 ViewModel로 분리하여 이 문제를 해결합니다.
> SwiftUI에서는 @Observable과 함께 사용하면 양방향 바인딩이 자연스럽습니다.

### 6.2 Swift

**Q: Optional을 어떻게 안전하게 처리하나요?**
> A: guard let으로 early return 패턴을 선호합니다.
> 옵셔널 체이닝과 nil 병합 연산자도 상황에 따라 사용합니다.
> 강제 언래핑(!)은 절대 사용하지 않습니다.

**Q: async/await의 장점은?**
> A: 콜백 지옥을 해결하고 동기 코드처럼 읽기 쉽습니다.
> 에러 핸들링도 try-catch로 일관되게 처리할 수 있습니다.
> 이 프로젝트에서는 모든 API 호출에 async/await를 사용했습니다.

### 6.3 iOS

**Q: Core Data와 Realm의 차이는?**
> A: Core Data는 애플 공식 프레임워크로 SwiftUI와 통합이 좋습니다.
> Realm은 더 간단하지만 외부 의존성이 추가됩니다.
> 이 프로젝트에서는 의존성 최소화를 위해 Core Data를 선택했습니다.

**Q: HealthKit 사용 시 주의점은?**
> A: 사용자 권한을 먼저 요청해야 하고, 백그라운드 동기화 설정이 필요합니다.
> 민감한 건강 데이터이므로 App Store 심사 시 사용 목적을 명확히 해야 합니다.

---

## 7. 포트폴리오 README 템플릿

```markdown
# Bodii - AI 건강 관리 앱

## 📱 소개
체성분, 식단, 운동, 수면을 통합 관리하는 iOS 앱

## 🛠 기술 스택
- **Architecture**: Clean Architecture + MVVM
- **UI**: SwiftUI, Swift Charts
- **Storage**: Core Data
- **Networking**: URLSession + async/await
- **Health**: HealthKit
- **AI**: Google Gemini API

## 🏗 아키텍처
[아키텍처 다이어그램]

### 주요 설계 결정
1. **UseCase 패턴**: 비즈니스 로직 캡슐화
2. **Repository 패턴**: 데이터 소스 추상화
3. **의존성 주입**: Protocol 기반 DI

## ✨ 주요 기능
- 체성분 기록 및 추이 그래프
- 음식 검색 (식약처 + USDA API)
- AI 식단 코멘트 (Gemini)
- HealthKit 연동

## 📚 학습 포인트
- Swift Concurrency (async/await)
- Protocol 기반 설계
- 네트워크 레이어 직접 구현

## 🧪 테스트
- UseCase 단위 테스트 (커버리지 85%)
- Repository 통합 테스트

## 📸 스크린샷
[스크린샷들]
```

---

## 8. 학습 로드맵

```
Week 1-2: 프로젝트 설정 & 기본 UI
├── Swift 문법 복습
├── SwiftUI 기초
└── Core Data 기초

Week 3-4: 체성분 & 대시보드
├── MVVM 패턴
├── Swift Charts
└── UseCase 패턴

Week 5-6: 식단 기능
├── URLSession + async/await
├── JSON 파싱
└── 에러 핸들링

Week 7-8: 운동 & 수면
├── HealthKit
├── 비즈니스 로직 분리
└── 단위 테스트

Week 9-10: AI & 마무리
├── Gemini API
├── UI 폴리싱
└── 테스트 & 리팩토링
```

---

*문서 버전: 1.0*
*작성일: 2026-01-11*

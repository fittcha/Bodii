//
//  APIConfig.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: API Configuration Management
// 외부 API의 엔드포인트와 인증 키를 안전하게 관리하는 설정 클래스
// 💡 Java 비교: BuildConfig와 유사하지만 런타임에 설정 가능

import Foundation

/// API 설정 프로토콜
///
/// 📚 학습 포인트: Protocol-Oriented Programming
/// 프로토콜을 사용해 테스트 시 Mock 구현체로 교체 가능
/// 💡 Java 비교: Interface와 유사하지만 더 강력한 기능 제공
///
/// - Note: 프로덕션에서는 APIConfigImpl 사용, 테스트에서는 MockAPIConfig 사용
protocol APIConfigProtocol {
    /// 식약처(KFDA) API 기본 URL
    var kfdaBaseURL: String { get }

    /// 식약처(KFDA) API 키
    var kfdaAPIKey: String { get }

    /// USDA FoodData Central API 기본 URL
    var usdaBaseURL: String { get }

    /// USDA API 키
    var usdaAPIKey: String { get }

    /// Google Gemini API 기본 URL
    var geminiBaseURL: String { get }

    /// Google Gemini API 키
    var geminiAPIKey: String { get }

    /// Google Cloud Vision API 기본 URL
    var visionBaseURL: String { get }

    /// Google Cloud Vision API 키
    var visionAPIKey: String { get }

    /// 현재 환경 (개발/프로덕션)
    var environment: APIEnvironment { get }

    /// Vision API URL 생성
    func buildVisionURL(endpoint: VisionEndpoint) -> URL?
}

/// Vision API 엔드포인트
enum VisionEndpoint {
    case annotate

    var path: String {
        switch self {
        case .annotate:
            return "/images:annotate"
        }
    }
}

// MARK: - API Environment

/// API 환경 열거형
///
/// 📚 학습 포인트: Enum for Configuration
/// 개발/프로덕션 환경별로 다른 설정 적용 가능
/// 💡 Java 비교: BuildConfig.BUILD_TYPE과 유사
enum APIEnvironment: String {
    case development
    case production

    /// 환경 표시 이름
    var displayName: String {
        switch self {
        case .development: return "개발"
        case .production: return "프로덕션"
        }
    }
}

// MARK: - APIConfig Implementation

/// API 설정 구현체
///
/// 📚 학습 포인트: Secure API Key Management
/// Info.plist를 통해 API 키를 안전하게 관리
/// Bundle에서 키를 읽어오므로 소스 코드에 하드코딩하지 않음
/// 💡 Java 비교: BuildConfig.API_KEY와 유사하지만 더 유연
///
/// **보안 참고사항:**
/// - API 키는 Info.plist에 저장 (Git 저장소에 커밋하지 않음)
/// - 실제 키는 .gitignore에 추가된 Info.plist에만 존재
/// - CI/CD 환경에서는 환경 변수로 주입
///
/// **Info.plist 설정 예시:**
/// ```xml
/// <key>KFDA_API_KEY</key>
/// <string>your-kfda-api-key</string>
/// <key>USDA_API_KEY</key>
/// <string>your-usda-api-key</string>
/// <key>GEMINI_API_KEY</key>
/// <string>your-gemini-api-key</string>
/// ```
///
/// **사용 예시:**
/// ```swift
/// let config = APIConfig.shared
/// let url = "\(config.kfdaBaseURL)/foods?serviceKey=\(config.kfdaAPIKey)"
/// ```
final class APIConfig: APIConfigProtocol {

    // MARK: - Singleton

    /// 공유 인스턴스
    ///
    /// 📚 학습 포인트: Singleton Pattern
    /// 앱 전역에서 동일한 설정 인스턴스 사용
    /// 💡 Java 비교: getInstance()와 동일
    static let shared = APIConfig()

    // MARK: - Initialization

    /// private init으로 외부 인스턴스화 방지
    private init() {}

    // MARK: - Environment

    /// 현재 API 환경
    ///
    /// 📚 학습 포인트: Conditional Compilation
    /// #if DEBUG를 사용해 빌드 타입에 따라 다른 환경 설정
    /// 💡 Java 비교: BuildConfig.DEBUG와 유사
    var environment: APIEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    // MARK: - KFDA API Configuration

    /// 식약처(KFDA) API 기본 URL
    ///
    /// 공공데이터포털(data.go.kr)의 식품영양성분 DB API
    ///
    /// - API 문서: https://www.data.go.kr/data/15127578/openapi.do
    /// - 대체 URL: https://various.foodsafetykorea.go.kr (식품안전나라)
    ///
    /// 📚 학습 포인트: Computed Property
    /// 환경에 따라 다른 URL 반환 가능
    /// 💡 Java 비교: getter 메서드와 동일하지만 더 간결
    var kfdaBaseURL: String {
        // 식약처 API 기본 URL (공공데이터포털)
        return "https://apis.data.go.kr/1471000/FoodNtrIrdntInfoService1"
    }

    /// 식약처(KFDA) API 키
    ///
    /// 📚 학습 포인트: Info.plist Configuration
    /// Bundle에서 Info.plist의 값을 읽어옴
    /// 💡 Java 비교: BuildConfig.API_KEY와 유사
    ///
    /// - Returns: API 키 문자열 (없으면 "DEMO_KEY" 반환)
    ///
    /// - Important: 프로덕션 빌드에서는 반드시 실제 API 키 설정 필요
    ///
    /// - Warning: Info.plist에 KFDA_API_KEY가 없으면 DEMO_KEY 사용 (제한된 요청 가능)
    var kfdaAPIKey: String {
        // Info.plist에서 키 읽기
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "KFDA_API_KEY") as? String,
           !apiKey.isEmpty {
            return apiKey
        }

        // 개발 환경에서는 DEMO_KEY 허용
        if environment == .development {
            return "DEMO_KEY"
        }

        // 프로덕션에서 키가 없으면 경고
        assertionFailure("⚠️ KFDA API 키가 Info.plist에 설정되지 않았습니다!")
        return ""
    }

    // MARK: - USDA API Configuration

    /// USDA FoodData Central API 기본 URL
    ///
    /// USDA(미국 농무부)의 식품 데이터 중앙 API
    ///
    /// - API 문서: https://fdc.nal.usda.gov/api-guide.html
    /// - API 키 신청: https://fdc.nal.usda.gov/api-key-signup.html
    ///
    /// 📚 학습 포인트: REST API Base URL
    /// 버전 정보(/v1)를 base URL에 포함
    /// 💡 Java 비교: Retrofit의 BASE_URL과 동일
    var usdaBaseURL: String {
        // USDA FoodData Central API v1
        return "https://api.nal.usda.gov/fdc/v1"
    }

    /// USDA FoodData Central API 키
    ///
    /// 📚 학습 포인트: API Key from Environment
    /// Info.plist 또는 환경 변수에서 API 키 읽기
    /// 💡 Java 비교: System.getenv()와 유사
    ///
    /// - Returns: API 키 문자열 (없으면 "DEMO_KEY" 반환)
    ///
    /// - Important: DEMO_KEY는 낮은 rate limit (30 requests/hour, 50 requests/day)
    ///
    /// - Note: 프로덕션에서는 반드시 실제 API 키 사용 권장
    var usdaAPIKey: String {
        // Info.plist에서 키 읽기
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String,
           !apiKey.isEmpty {
            return apiKey
        }

        // 프로세스 환경 변수에서 키 읽기 (CI/CD용)
        if let envKey = ProcessInfo.processInfo.environment["USDA_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }

        // 개발 환경에서는 DEMO_KEY 허용
        if environment == .development {
            return "DEMO_KEY"
        }

        // 프로덕션에서 키가 없으면 경고
        assertionFailure("⚠️ USDA API 키가 Info.plist 또는 환경 변수에 설정되지 않았습니다!")
        return ""
    }

    // MARK: - Gemini API Configuration

    /// Google Gemini API 기본 URL
    ///
    /// Google의 Gemini AI 모델 API
    ///
    /// - API 문서: https://ai.google.dev/api/rest
    /// - 모델: gemini-1.5-flash (빠른 응답, 무료 티어)
    /// - Rate Limit: 15 requests/minute (무료 티어)
    ///
    /// 📚 학습 포인트: AI API Integration
    /// 생성형 AI API를 통한 개인화된 식단 코멘트 제공
    /// 💡 Java 비교: REST API 호출과 동일하지만 AI 응답 처리 필요
    var geminiBaseURL: String {
        // Gemini API v1 기본 URL
        return "https://generativelanguage.googleapis.com/v1beta"
    }

    /// Google Gemini API 키
    ///
    /// 📚 학습 포인트: Secure API Key Management
    /// Info.plist 또는 환경 변수에서 API 키 읽기
    /// 💡 Java 비교: BuildConfig.API_KEY와 유사
    ///
    /// - Returns: API 키 문자열 (없으면 빈 문자열)
    ///
    /// - Important: 프로덕션 빌드에서는 반드시 실제 API 키 설정 필요
    ///
    /// - Note: API 키 신청: https://makersuite.google.com/app/apikey
    ///
    /// - Warning: 무료 티어는 15 RPM (requests per minute) 제한
    var geminiAPIKey: String {
        // Info.plist에서 키 읽기
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !apiKey.isEmpty {
            return apiKey
        }

        // 프로세스 환경 변수에서 키 읽기 (CI/CD용)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }

        // 개발 환경에서도 Gemini는 실제 키 필요 (DEMO_KEY 미제공)
        if environment == .development {
            assertionFailure("⚠️ Gemini API 키가 Info.plist 또는 환경 변수에 설정되지 않았습니다!")
        }

        return ""
    }

    // MARK: - Vision API Configuration

    /// Google Cloud Vision API 기본 URL
    ///
    /// Google Cloud Vision API
    ///
    /// - API 문서: https://cloud.google.com/vision/docs/reference/rest
    /// - Free Tier: 1,000 requests/month
    var visionBaseURL: String {
        return "https://vision.googleapis.com/v1"
    }

    /// Google Cloud Vision API 키
    ///
    /// - Returns: API 키 문자열 (없으면 빈 문자열)
    var visionAPIKey: String {
        // Info.plist에서 키 읽기
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "VISION_API_KEY") as? String,
           !apiKey.isEmpty {
            return apiKey
        }

        // 프로세스 환경 변수에서 키 읽기 (CI/CD용)
        if let envKey = ProcessInfo.processInfo.environment["VISION_API_KEY"],
           !envKey.isEmpty {
            return envKey
        }

        // 개발 환경에서도 Vision API는 실제 키 필요
        if environment == .development {
            assertionFailure("⚠️ Vision API 키가 Info.plist 또는 환경 변수에 설정되지 않았습니다!")
        }

        return ""
    }

    // MARK: - API Endpoints

    /// 식약처 API 엔드포인트
    enum KFDAEndpoint {
        /// 식품 영양 성분 정보 조회 (검색)
        ///
        /// - Parameter query: 검색어 (식품명)
        /// - Parameter startIdx: 시작 인덱스 (페이징)
        /// - Parameter endIdx: 종료 인덱스 (페이징)
        ///
        /// - Returns: API 경로
        ///
        /// - Example:
        /// ```swift
        /// let path = KFDAEndpoint.search(query: "김치찌개", startIdx: 1, endIdx: 10)
        /// let url = "\(APIConfig.shared.kfdaBaseURL)\(path)"
        /// ```
        case search(query: String, startIdx: Int, endIdx: Int)

        /// 식품 상세 정보 조회
        ///
        /// - Parameter foodCode: 식품 코드
        ///
        /// - Returns: API 경로
        case detail(foodCode: String)

        /// API 경로 생성
        var path: String {
            switch self {
            case .search:
                return "/getFoodNtrItdntList1"
            case .detail:
                return "/getFoodNtrItdntList1"
            }
        }

        /// 쿼리 파라미터 생성
        ///
        /// 📚 학습 포인트: URLQueryItem
        /// URL 쿼리 파라미터를 타입 안전하게 생성
        /// 💡 Java 비교: HttpUrl.Builder.addQueryParameter()와 유사
        var queryItems: [URLQueryItem] {
            switch self {
            case .search(let query, let startIdx, let endIdx):
                return [
                    URLQueryItem(name: "desc_kor", value: query),
                    URLQueryItem(name: "startIdx", value: "\(startIdx)"),
                    URLQueryItem(name: "endIdx", value: "\(endIdx)"),
                    URLQueryItem(name: "type", value: "json")
                ]
            case .detail(let foodCode):
                return [
                    URLQueryItem(name: "food_cd", value: foodCode),
                    URLQueryItem(name: "type", value: "json")
                ]
            }
        }
    }

    /// USDA FoodData Central API 엔드포인트
    enum USDAEndpoint {
        /// 식품 검색
        ///
        /// - Parameter query: 검색어
        /// - Parameter pageSize: 페이지 크기 (기본 25)
        /// - Parameter pageNumber: 페이지 번호 (기본 1)
        ///
        /// - Returns: API 경로
        ///
        /// - Example:
        /// ```swift
        /// let path = USDAEndpoint.search(query: "apple", pageSize: 10, pageNumber: 1)
        /// let url = "\(APIConfig.shared.usdaBaseURL)\(path)"
        /// ```
        case search(query: String, pageSize: Int, pageNumber: Int)

        /// 식품 상세 정보 조회
        ///
        /// - Parameter fdcId: FDC ID (USDA 식품 고유 ID)
        ///
        /// - Returns: API 경로
        case food(fdcId: String)

        /// 여러 식품 정보 조회
        ///
        /// - Parameter fdcIds: FDC ID 목록
        ///
        /// - Returns: API 경로
        case foods(fdcIds: [String])

        /// API 경로 생성
        var path: String {
            switch self {
            case .search:
                return "/foods/search"
            case .food(let fdcId):
                return "/food/\(fdcId)"
            case .foods:
                return "/foods"
            }
        }

        /// 쿼리 파라미터 생성
        var queryItems: [URLQueryItem] {
            switch self {
            case .search(let query, let pageSize, let pageNumber):
                return [
                    URLQueryItem(name: "query", value: query),
                    URLQueryItem(name: "pageSize", value: "\(pageSize)"),
                    URLQueryItem(name: "pageNumber", value: "\(pageNumber)")
                ]
            case .food:
                // 경로에 ID 포함되므로 추가 쿼리 파라미터 없음
                return []
            case .foods(let fdcIds):
                return fdcIds.map { URLQueryItem(name: "fdcIds", value: $0) }
            }
        }
    }

    /// Google Gemini API 엔드포인트
    enum GeminiEndpoint {
        /// 텍스트 생성 (Diet Comment 생성용)
        ///
        /// - Parameter model: 사용할 Gemini 모델 (기본: gemini-1.5-flash)
        ///
        /// - Returns: API 경로
        ///
        /// - Example:
        /// ```swift
        /// let endpoint = GeminiEndpoint.generateContent(model: "gemini-1.5-flash")
        /// let url = APIConfig.shared.buildGeminiURL(endpoint: endpoint)
        /// ```
        ///
        /// - Note: gemini-1.5-flash는 빠른 응답과 무료 티어 제공
        case generateContent(model: String = "gemini-1.5-flash")

        /// API 경로 생성
        var path: String {
            switch self {
            case .generateContent(let model):
                return "/models/\(model):generateContent"
            }
        }

        /// 쿼리 파라미터 생성
        ///
        /// 📚 학습 포인트: API Key in Query Parameter
        /// Gemini API는 API 키를 쿼리 파라미터로 전달
        /// 💡 Java 비교: HttpUrl.Builder.addQueryParameter()와 유사
        var queryItems: [URLQueryItem] {
            switch self {
            case .generateContent:
                // API 키는 buildGeminiURL에서 추가됨
                return []
            }
        }
    }
}

// MARK: - URL Builder Helper

extension APIConfig {

    /// KFDA API URL 생성 헬퍼
    ///
    /// 📚 학습 포인트: URL Building with URLComponents
    /// 쿼리 파라미터를 안전하게 URL에 추가
    /// 💡 Java 비교: UriComponentsBuilder와 유사
    ///
    /// - Parameter endpoint: KFDA 엔드포인트
    ///
    /// - Returns: 완성된 URL (API 키 포함)
    ///
    /// - Example:
    /// ```swift
    /// let url = APIConfig.shared.buildKFDAURL(
    ///     endpoint: .search(query: "김치찌개", startIdx: 1, endIdx: 10)
    /// )
    /// ```
    func buildKFDAURL(endpoint: KFDAEndpoint) -> URL? {
        var components = URLComponents(string: kfdaBaseURL + endpoint.path)

        // 쿼리 파라미터 추가
        var queryItems = endpoint.queryItems
        // API 키 추가
        queryItems.append(URLQueryItem(name: "serviceKey", value: kfdaAPIKey))

        components?.queryItems = queryItems

        return components?.url
    }

    /// USDA API URL 생성 헬퍼
    ///
    /// 📚 학습 포인트: URL Building with Components
    /// URLComponents로 안전한 URL 생성
    /// 💡 Java 비교: HttpUrl.Builder와 유사
    ///
    /// - Parameter endpoint: USDA 엔드포인트
    ///
    /// - Returns: 완성된 URL (API 키 포함)
    ///
    /// - Example:
    /// ```swift
    /// let url = APIConfig.shared.buildUSDAURL(
    ///     endpoint: .search(query: "apple", pageSize: 10, pageNumber: 1)
    /// )
    /// ```
    func buildUSDAURL(endpoint: USDAEndpoint) -> URL? {
        var components = URLComponents(string: usdaBaseURL + endpoint.path)

        // 쿼리 파라미터 추가
        var queryItems = endpoint.queryItems
        // API 키 추가
        queryItems.append(URLQueryItem(name: "api_key", value: usdaAPIKey))

        components?.queryItems = queryItems

        return components?.url
    }

    /// Gemini API URL 생성 헬퍼
    ///
    /// 📚 학습 포인트: AI API URL Building
    /// Gemini API는 API 키를 쿼리 파라미터로 전달
    /// 💡 Java 비교: UriComponentsBuilder와 유사
    ///
    /// - Parameter endpoint: Gemini 엔드포인트
    ///
    /// - Returns: 완성된 URL (API 키 포함)
    ///
    /// - Example:
    /// ```swift
    /// let url = APIConfig.shared.buildGeminiURL(
    ///     endpoint: .generateContent(model: "gemini-1.5-flash")
    /// )
    /// ```
    ///
    /// - Note: POST 요청으로 사용, 요청 본문은 GeminiRequestDTO로 전달
    func buildGeminiURL(endpoint: GeminiEndpoint) -> URL? {
        var components = URLComponents(string: geminiBaseURL + endpoint.path)

        // 쿼리 파라미터 추가
        var queryItems = endpoint.queryItems
        // API 키 추가 (Gemini API는 쿼리 파라미터로 키 전달)
        queryItems.append(URLQueryItem(name: "key", value: geminiAPIKey))

        components?.queryItems = queryItems

        return components?.url
    }

    /// Vision API URL 생성 헬퍼
    ///
    /// 📚 학습 포인트: Vision API URL Building
    /// Google Cloud Vision API는 API 키를 쿼리 파라미터로 전달
    ///
    /// - Parameter endpoint: Vision 엔드포인트
    ///
    /// - Returns: 완성된 URL (API 키 포함)
    func buildVisionURL(endpoint: VisionEndpoint) -> URL? {
        var components = URLComponents(string: visionBaseURL + endpoint.path)

        // API 키 추가 (Vision API는 쿼리 파라미터로 키 전달)
        components?.queryItems = [
            URLQueryItem(name: "key", value: visionAPIKey)
        ]

        return components?.url
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock API 설정
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockAPIConfig: APIConfigProtocol {
    var kfdaBaseURL: String
    var kfdaAPIKey: String
    var usdaBaseURL: String
    var usdaAPIKey: String
    var geminiBaseURL: String
    var geminiAPIKey: String
    var visionBaseURL: String
    var visionAPIKey: String
    var environment: APIEnvironment

    init(
        kfdaBaseURL: String = "https://mock.kfda.api",
        kfdaAPIKey: String = "MOCK_KFDA_KEY",
        usdaBaseURL: String = "https://mock.usda.api",
        usdaAPIKey: String = "MOCK_USDA_KEY",
        geminiBaseURL: String = "https://mock.gemini.api",
        geminiAPIKey: String = "MOCK_GEMINI_KEY",
        visionBaseURL: String = "https://mock.vision.api",
        visionAPIKey: String = "MOCK_VISION_KEY",
        environment: APIEnvironment = .development
    ) {
        self.kfdaBaseURL = kfdaBaseURL
        self.kfdaAPIKey = kfdaAPIKey
        self.usdaBaseURL = usdaBaseURL
        self.usdaAPIKey = usdaAPIKey
        self.geminiBaseURL = geminiBaseURL
        self.geminiAPIKey = geminiAPIKey
        self.visionBaseURL = visionBaseURL
        self.visionAPIKey = visionAPIKey
        self.environment = environment
    }

    func buildVisionURL(endpoint: VisionEndpoint) -> URL? {
        var components = URLComponents(string: visionBaseURL + endpoint.path)
        components?.queryItems = [
            URLQueryItem(name: "key", value: visionAPIKey)
        ]
        return components?.url
    }
}
#endif

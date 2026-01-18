# API 키 설정 가이드

이 문서는 Bodii 앱에서 사용하는 외부 API 키를 안전하게 설정하는 방법을 설명합니다.

## 📋 필요한 API 키

### 1. 식약처(KFDA) API 키

**API 이름:** 식품영양성분DB정보 (Food Nutrition Database API)

**발급처:** 공공데이터포털 (data.go.kr)

**발급 방법:**
1. [공공데이터포털](https://www.data.go.kr/) 회원가입 및 로그인
2. [식품영양성분DB정보 API](https://www.data.go.kr/data/15127578/openapi.do) 페이지 접속
3. "활용신청" 버튼 클릭
4. 신청 양식 작성 및 제출
5. 승인 후 API 키(서비스 키) 발급 (일반적으로 즉시 승인)

**참고 링크:**
- API 문서: https://www.data.go.kr/data/15127578/openapi.do
- 식품안전나라 API: https://various.foodsafetykorea.go.kr/nutrient/industry/openApi/info.do

### 2. USDA FoodData Central API 키

**API 이름:** FoodData Central API

**발급처:** USDA (미국 농무부)

**발급 방법:**
1. [USDA API 키 신청 페이지](https://fdc.nal.usda.gov/api-key-signup.html) 접속
2. 필수 정보 입력:
   - First Name
   - Last Name
   - Email Address
3. "Signup" 버튼 클릭
4. 입력한 이메일로 API 키 수신 (즉시 발급)

**참고 링크:**
- API 가이드: https://fdc.nal.usda.gov/api-guide.html
- API 문서: https://fdc.nal.usda.gov/api-spec/fdc_api.html

**DEMO_KEY 사용:**
- API 키가 없어도 DEMO_KEY로 테스트 가능
- 제한사항: 시간당 30회, 일일 50회 요청 제한
- 개발 초기 테스트용으로만 사용 권장

## 🔐 API 키 설정 방법

### 방법 1: Info.plist 설정 (권장)

1. Xcode에서 `Bodii/Info.plist` 파일 열기
   - 프로젝트 네비게이터에서 `Bodii` 폴더 → `Info.plist` 선택

2. 다음 키-값 쌍 추가:

**Property List 편집기에서:**
```
- KFDA_API_KEY (String) = "your-kfda-api-key-here"
- USDA_API_KEY (String) = "your-usda-api-key-here"
```

**XML로 직접 편집할 경우:**
```xml
<key>KFDA_API_KEY</key>
<string>your-kfda-api-key-here</string>
<key>USDA_API_KEY</key>
<string>your-usda-api-key-here</string>
```

3. 파일 저장

4. ⚠️ **중요: Info.plist를 .gitignore에 추가**
   ```
   # .gitignore에 추가
   Bodii/Info.plist
   ```

### 방법 2: 환경 변수 설정 (CI/CD용)

CI/CD 환경이나 팀 협업 시 환경 변수 사용:

**Xcode에서 설정:**
1. Product → Scheme → Edit Scheme...
2. Run → Arguments → Environment Variables
3. 다음 환경 변수 추가:
   - `KFDA_API_KEY` = `your-kfda-api-key`
   - `USDA_API_KEY` = `your-usda-api-key`

**GitHub Actions 예시:**
```yaml
- name: Run tests
  env:
    KFDA_API_KEY: ${{ secrets.KFDA_API_KEY }}
    USDA_API_KEY: ${{ secrets.USDA_API_KEY }}
  run: xcodebuild test ...
```

### 방법 3: 개발 모드 (DEMO_KEY)

API 키 없이 개발/테스트:

1. Info.plist에 API 키를 설정하지 않음
2. 자동으로 `DEMO_KEY` 사용 (DEBUG 빌드에만 해당)
3. 제한된 요청 횟수로 기본 테스트 가능

**주의:** 프로덕션 빌드에서는 반드시 실제 API 키 필요

## 🧪 설정 확인

API 키가 올바르게 설정되었는지 확인:

```swift
import Foundation

// APIConfig가 올바르게 로드되는지 확인
let config = APIConfig.shared

print("환경: \(config.environment.displayName)")
print("KFDA Base URL: \(config.kfdaBaseURL)")
print("KFDA API Key: \(config.kfdaAPIKey.prefix(10))...") // 보안상 일부만 출력
print("USDA Base URL: \(config.usdaBaseURL)")
print("USDA API Key: \(config.usdaAPIKey.prefix(10))...")

// URL 빌더 테스트
if let url = config.buildKFDAURL(
    endpoint: .search(query: "김치", startIdx: 1, endIdx: 10)
) {
    print("✅ KFDA URL 생성 성공: \(url)")
}

if let url = config.buildUSDAURL(
    endpoint: .search(query: "apple", pageSize: 10, pageNumber: 1)
) {
    print("✅ USDA URL 생성 성공: \(url)")
}
```

## 🔒 보안 모범 사례

### DO ✅
- API 키를 Info.plist에 저장하고 .gitignore에 추가
- 환경 변수 사용 (CI/CD)
- 팀원에게 별도 채널(Slack, 이메일 등)로 API 키 공유
- 프로덕션/개발 환경 분리

### DON'T ❌
- API 키를 소스 코드에 하드코딩
- API 키를 Git에 커밋
- API 키를 공개 저장소에 업로드
- 프로덕션 키를 개발 환경에서 사용

## 🐛 문제 해결

### "API 키가 설정되지 않았습니다" 경고

**증상:**
```
⚠️ KFDA API 키가 Info.plist에 설정되지 않았습니다!
```

**해결방법:**
1. Info.plist에 `KFDA_API_KEY` 또는 `USDA_API_KEY` 추가
2. 키 값이 빈 문자열이 아닌지 확인
3. Xcode를 재시작하고 Clean Build Folder (Cmd+Shift+K)

### API 요청이 실패함

**증상:**
- 401 Unauthorized
- 403 Forbidden

**해결방법:**
1. API 키가 올바른지 확인 (복사-붙여넣기 시 공백 주의)
2. 식약처 API: 활용신청이 승인되었는지 확인
3. USDA API: DEMO_KEY 사용 시 rate limit 초과 여부 확인

### Rate Limit 초과

**USDA DEMO_KEY 제한:**
- 시간당 30회, 일일 50회 제한
- 실제 API 키 발급 권장

**해결방법:**
1. 실제 API 키 발급받기
2. 캐싱 기능 활용하여 API 호출 최소화
3. 요청 횟수 모니터링

## 📚 참고 자료

### 식약처(KFDA) API
- [공공데이터포털 - 식품영양성분DB](https://www.data.go.kr/data/15127578/openapi.do)
- [식품안전나라 - OpenAPI 안내](https://various.foodsafetykorea.go.kr/nutrient/industry/openApi/info.do)
- [식품영양정보 표준DB](https://data.mfds.go.kr/nsd/obaaa/stdDbSrchRsltList.do)

### USDA FoodData Central API
- [API Guide](https://fdc.nal.usda.gov/api-guide.html)
- [API Key Signup](https://fdc.nal.usda.gov/api-key-signup.html)
- [API Specification](https://fdc.nal.usda.gov/api-spec/fdc_api.html)
- [Postman Documentation](https://www.postman.com/api-evangelist/agricultural-research-service-ars/documentation/nex4lq6/food-data-central-api)

## ❓ 추가 도움이 필요하신가요?

문제가 해결되지 않으면:
1. `APIConfig.swift` 파일의 주석 확인
2. 프로젝트 문서 참조
3. 팀 리드에게 문의

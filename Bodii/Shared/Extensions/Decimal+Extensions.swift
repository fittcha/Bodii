//
//  Decimal+Extensions.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Extension Pattern
// 기존 타입에 새로운 기능을 추가하여 코드 재사용성 향상
// 💡 Java 비교: Utility 클래스와 유사하지만 더 자연스러운 API 제공

import Foundation

// MARK: - Decimal Formatting Extensions

/// Decimal 타입에 대한 확장 - 포맷팅 기능 추가
/// 📚 학습 포인트: Type Extension
/// - Swift의 강력한 기능: 기존 타입에 메서드와 computed property 추가 가능
/// - 외부 라이브러리나 시스템 타입도 확장 가능
/// 💡 Java 비교: Utility 클래스(DecimalUtils.format())보다 자연스러운 사용법
///   - Java: DecimalUtils.format(value, 1)
///   - Swift: value.formatted(decimalPlaces: 1)
extension Decimal {

    // MARK: - Display Formatting

    /// 일반 표시용 포맷팅 (1자리 소수점)
    /// 📚 학습 포인트: Default Parameter
    /// - decimalPlaces 기본값 1로 설정하여 대부분의 경우 간단히 사용
    /// - 체중, 체지방률, 근육량 등 신체 측정값에 적합
    ///
    /// - Parameter decimalPlaces: 소수점 자릿수 (기본값: 1)
    /// - Returns: 포맷된 문자열 (예: "70.5", "18.3")
    ///
    /// 사용 예시:
    /// ```swift
    /// let weight = Decimal(70.543)
    /// print(weight.formatted())  // "70.5"
    /// ```
    func formatted(decimalPlaces: Int = 1) -> String {
        // 📚 학습 포인트: NumberFormatter Configuration
        // NumberFormatter를 사용하여 로케일에 맞는 숫자 포맷팅
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces

        // 📚 학습 포인트: NSDecimalNumber Bridge
        // Swift의 Decimal을 Foundation의 NSDecimalNumber로 변환
        // NSDecimalNumber는 NumberFormatter와 호환
        let number = NSDecimalNumber(decimal: self)

        // 📚 학습 포인트: Nil Coalescing for Fallback
        // formatter 실패 시 기본 문자열 표현 사용
        return formatter.string(from: number) ?? "\(self)"
    }

    /// 칼로리 표시용 포맷팅 (소수점 없음)
    /// 📚 학습 포인트: Specialized Formatting Method
    /// - BMR, TDEE, 칼로리 섭취량 등에 적합
    /// - 칼로리는 정수로 표시하는 것이 일반적
    /// - 1000 단위 구분자 포함 (예: "1,650")
    ///
    /// - Returns: 포맷된 문자열 (예: "1650", "2,280")
    ///
    /// 사용 예시:
    /// ```swift
    /// let bmr = Decimal(1648.234)
    /// print(bmr.formattedAsCalories())  // "1,648"
    /// ```
    func formattedAsCalories() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        let number = NSDecimalNumber(decimal: self)
        return formatter.string(from: number) ?? "\(self)"
    }

    /// 백분율 표시용 포맷팅
    /// 📚 학습 포인트: Domain-Specific Formatting
    /// - 체지방률, 근육 비율 등에 적합
    /// - "%" 기호는 포함하지 않음 (UI에서 별도로 추가)
    ///
    /// - Parameter decimalPlaces: 소수점 자릿수 (기본값: 1)
    /// - Returns: 포맷된 문자열 (예: "18.5", "20.0")
    ///
    /// 사용 예시:
    /// ```swift
    /// let bodyFat = Decimal(18.543)
    /// Text("\(bodyFat.formattedAsPercent())%")  // "18.5%"
    /// ```
    func formattedAsPercent(decimalPlaces: Int = 1) -> String {
        // 📚 학습 포인트: Method Delegation
        // 기존 메서드를 재사용하여 코드 중복 제거
        return formatted(decimalPlaces: decimalPlaces)
    }

    /// 무게 표시용 포맷팅 (kg)
    /// 📚 학습 포인트: Semantic Method Name
    /// - 메서드 이름으로 사용 의도를 명확히 표현
    /// - 체중, 근육량, 체지방량 등에 적합
    ///
    /// - Parameter decimalPlaces: 소수점 자릿수 (기본값: 1)
    /// - Returns: 포맷된 문자열 (예: "70.5", "32.0")
    ///
    /// 사용 예시:
    /// ```swift
    /// let weight = Decimal(70.543)
    /// Text("\(weight.formattedAsWeight()) kg")  // "70.5 kg"
    /// ```
    func formattedAsWeight(decimalPlaces: Int = 1) -> String {
        return formatted(decimalPlaces: decimalPlaces)
    }

    // MARK: - Locale-Aware Formatting

    /// 특정 로케일에 맞춘 포맷팅
    /// 📚 학습 포인트: Locale-Aware Formatting
    /// - 각 국가의 숫자 표기법에 맞게 포맷팅
    /// - 한국: "1,234.5", 독일: "1.234,5", 프랑스: "1 234,5"
    /// 💡 Java 비교: DecimalFormat with Locale과 유사
    ///
    /// - Parameters:
    ///   - locale: 로케일 (기본값: 현재 로케일)
    ///   - decimalPlaces: 소수점 자릿수 (기본값: 1)
    /// - Returns: 로케일에 맞춘 포맷된 문자열
    ///
    /// 사용 예시:
    /// ```swift
    /// let value = Decimal(1234.567)
    /// print(value.formatted(locale: Locale(identifier: "ko_KR")))  // "1,234.6"
    /// print(value.formatted(locale: Locale(identifier: "de_DE")))  // "1.234,6"
    /// ```
    func formatted(locale: Locale = .current, decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces

        let number = NSDecimalNumber(decimal: self)
        return formatter.string(from: number) ?? "\(self)"
    }

    // MARK: - Rounding Helpers

    /// 반올림된 정수값 반환
    /// 📚 학습 포인트: Rounding Mode
    /// - NSDecimalNumber의 기본 반올림 모드 사용 (plain)
    /// - 칼로리 계산 등에서 정수값이 필요할 때 사용
    ///
    /// - Returns: 반올림된 정수값
    ///
    /// 사용 예시:
    /// ```swift
    /// let bmr = Decimal(1648.543)
    /// print(bmr.roundedInt())  // 1649
    /// ```
    func roundedInt() -> Int {
        // 📚 학습 포인트: NSDecimalNumber Rounding
        // NSDecimalNumber는 정확한 반올림을 제공
        // Double의 부동소수점 오차 문제가 없음
        return NSDecimalNumber(decimal: self).rounding(accordingToBehavior: nil).intValue
    }

    /// 지정된 소수점 자릿수로 반올림
    /// 📚 학습 포인트: Precise Rounding
    /// - Decimal의 정밀도를 유지하면서 반올림
    /// - Double과 달리 정확한 결과 보장
    ///
    /// - Parameter scale: 소수점 자릿수 (기본값: 2)
    /// - Returns: 반올림된 Decimal 값
    ///
    /// 사용 예시:
    /// ```swift
    /// let value = Decimal(70.5678)
    /// print(value.rounded(toPlaces: 1))  // 70.6
    /// print(value.rounded(toPlaces: 2))  // 70.57
    /// ```
    func rounded(toPlaces scale: Int16 = 2) -> Decimal {
        // 📚 학습 포인트: NSDecimalNumberHandler
        // 반올림 모드와 정밀도를 제어하는 핸들러
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,      // 일반 반올림 (0.5 이상 올림)
            scale: scale,              // 소수점 자릿수
            raiseOnExactness: false,   // 정확도 예외 미발생
            raiseOnOverflow: false,    // 오버플로우 예외 미발생
            raiseOnUnderflow: false,   // 언더플로우 예외 미발생
            raiseOnDivideByZero: false // 0으로 나누기 예외 미발생
        )

        let number = NSDecimalNumber(decimal: self)
        return number.rounding(accordingToBehavior: handler) as Decimal
    }

    // MARK: - Validation Helpers

    /// 유효한 숫자인지 확인
    /// 📚 학습 포인트: NaN Check
    /// - Decimal도 NaN(Not a Number) 상태를 가질 수 있음
    /// - 계산 전 유효성 검증에 사용
    ///
    /// - Returns: 유효한 숫자이면 true, NaN이면 false
    ///
    /// 사용 예시:
    /// ```swift
    /// let value = Decimal(70.5)
    /// if value.isValid {
    ///     print("유효한 값입니다")
    /// }
    /// ```
    var isValid: Bool {
        // 📚 학습 포인트: NSDecimalNumber.notANumber
        // Decimal의 NaN 상태를 확인하는 표준 방법
        return !self.isNaN
    }
}

// MARK: - String to Decimal Conversion

/// String 타입에 대한 확장 - Decimal 변환 헬퍼
/// 📚 학습 포인트: Convenience Extension
/// - 사용자 입력(TextField)을 Decimal로 안전하게 변환
extension String {

    /// 문자열을 Decimal로 변환 (로케일 고려)
    /// 📚 학습 포인트: Locale-Aware Parsing
    /// - 각 국가의 숫자 표기법을 자동으로 인식
    /// - "1,234.5" (한국) 또는 "1.234,5" (독일) 모두 처리 가능
    /// 💡 Java 비교: DecimalFormat.parse()와 유사
    ///
    /// - Parameter locale: 로케일 (기본값: 현재 로케일)
    /// - Returns: 변환된 Decimal 값 (실패 시 nil)
    ///
    /// 사용 예시:
    /// ```swift
    /// let input = "70.5"
    /// if let weight = input.toDecimal() {
    ///     print("체중: \(weight) kg")
    /// }
    /// ```
    func toDecimal(locale: Locale = .current) -> Decimal? {
        // 📚 학습 포인트: NumberFormatter for Parsing
        // 문자열을 숫자로 변환할 때도 NumberFormatter 사용
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale

        // 📚 학습 포인트: Safe Unwrapping Chain
        // number(from:) → decimalValue 순서로 안전하게 변환
        guard let number = formatter.number(from: self) else {
            return nil
        }

        return number.decimalValue
    }
}

// MARK: - Sample Usage

extension Decimal {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Extension의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 신체 측정값
    struct SampleValues {
        static let weight = Decimal(70.543)          // 체중
        static let bodyFatPercent = Decimal(18.543)  // 체지방률
        static let muscleMass = Decimal(32.167)      // 근육량
        static let bmr = Decimal(1648.234)           // 기초대사량
        static let tdee = Decimal(2280.123)          // 총 에너지 소비량

        /// 포맷팅 예시 출력
        /// 📚 학습 포인트: Example Output
        /// 실제 사용 시 어떻게 표시되는지 확인
        static func printExamples() {
            print("=== Decimal 포맷팅 예시 ===")
            print("체중: \(weight.formattedAsWeight()) kg")
            print("체지방률: \(bodyFatPercent.formattedAsPercent())%")
            print("근육량: \(muscleMass.formattedAsWeight()) kg")
            print("BMR: \(bmr.formattedAsCalories()) kcal/일")
            print("TDEE: \(tdee.formattedAsCalories()) kcal/일")
            print("===========================")
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Decimal Extension 사용 가이드
///
/// ## 왜 Decimal을 사용하는가?
///
/// Double vs Decimal:
/// - Double: 부동소수점 방식, 빠르지만 정확도 문제
///   - 0.1 + 0.2 = 0.30000000000000004 (오차 발생!)
/// - Decimal: 10진수 방식, 느리지만 정확
///   - 0.1 + 0.2 = 0.3 (정확한 결과)
///
/// 금융, 의료, 신체 측정 등 정확한 계산이 필요한 곳에서 Decimal 사용 필수
///
/// ## 포맷팅 메서드 선택 가이드
///
/// ### 1. formatted(decimalPlaces:) - 범용
/// - 대부분의 경우 사용
/// - 소수점 자릿수 조절 가능
/// ```swift
/// let value = Decimal(70.543)
/// value.formatted()           // "70.5" (기본 1자리)
/// value.formatted(decimalPlaces: 2)  // "70.54"
/// ```
///
/// ### 2. formattedAsCalories() - 칼로리 전용
/// - BMR, TDEE, 섭취/소비 칼로리
/// - 항상 정수로 표시
/// ```swift
/// let bmr = Decimal(1648.234)
/// bmr.formattedAsCalories()   // "1,648"
/// ```
///
/// ### 3. formattedAsPercent() - 백분율 전용
/// - 체지방률, 근육 비율
/// - "%" 기호는 UI에서 별도로 추가
/// ```swift
/// let bodyFat = Decimal(18.543)
/// "\(bodyFat.formattedAsPercent())%"  // "18.5%"
/// ```
///
/// ### 4. formattedAsWeight() - 무게 전용
/// - 체중, 근육량, 체지방량
/// - "kg" 단위는 UI에서 별도로 추가
/// ```swift
/// let weight = Decimal(70.543)
/// "\(weight.formattedAsWeight()) kg"  // "70.5 kg"
/// ```
///
/// ### 5. formatted(locale:decimalPlaces:) - 다국어 지원
/// - 해외 사용자를 위한 로케일 지원
/// - 숫자 표기법이 다른 국가에서 사용
/// ```swift
/// let value = Decimal(1234.567)
/// value.formatted(locale: Locale(identifier: "ko_KR"))  // "1,234.6"
/// value.formatted(locale: Locale(identifier: "de_DE"))  // "1.234,6"
/// ```
///
/// ## UI에서 사용 예시 (SwiftUI)
///
/// ```swift
/// struct BodyCompositionView: View {
///     let entry: BodyCompositionEntry
///
///     var body: some View {
///         VStack {
///             Text("체중: \(entry.weight.formattedAsWeight()) kg")
///             Text("체지방률: \(entry.bodyFatPercent.formattedAsPercent())%")
///             Text("근육량: \(entry.muscleMass.formattedAsWeight()) kg")
///             Text("BMR: \(entry.bmr.formattedAsCalories()) kcal/일")
///         }
///     }
/// }
/// ```
///
/// ## String to Decimal 변환 (TextField 입력 처리)
///
/// ```swift
/// struct InputView: View {
///     @State private var weightInput = ""
///
///     var body: some View {
///         TextField("체중 (kg)", text: $weightInput)
///             .keyboardType(.decimalPad)
///             .onChange(of: weightInput) { newValue in
///                 if let weight = newValue.toDecimal() {
///                     print("유효한 체중: \(weight)")
///                 }
///             }
///     }
/// }
/// ```
///
/// ## 반올림 사용 예시
///
/// ```swift
/// let value = Decimal(70.5678)
/// value.rounded(toPlaces: 1)  // 70.6
/// value.roundedInt()          // 71
/// ```
///
/// ## 주의사항
///
/// 1. TextField 입력값은 항상 검증:
///    - toDecimal() 사용하여 안전하게 변환
///    - nil 체크 필수
///
/// 2. 계산 전 유효성 확인:
///    - isValid 프로퍼티로 NaN 체크
///
/// 3. 로케일 고려:
///    - 다국어 앱이면 locale 파라미터 사용
///    - 기본값(.current)은 사용자의 시스템 설정 따름
///
/// ## 성능 고려사항
///
/// - Decimal은 Double보다 느림 (약 10-100배)
/// - 하지만 UI 표시나 간단한 계산에는 영향 없음
/// - 대량의 복잡한 계산이 아니라면 Decimal 사용 권장
///
/// ## 💡 Java 개발자를 위한 비교
///
/// | Swift Decimal | Java BigDecimal |
/// |---------------|-----------------|
/// | Decimal(70.5) | new BigDecimal("70.5") |
/// | value.formatted() | DecimalFormat.format(value) |
/// | value.rounded(toPlaces: 2) | value.setScale(2, RoundingMode.HALF_UP) |
/// | value.roundedInt() | value.intValue() |
/// | "70.5".toDecimal() | new BigDecimal("70.5") |
///

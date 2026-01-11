//
//  Formatters.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Centralized Formatters for Performance
// DateFormatter와 NumberFormatter는 생성 비용이 높으므로 재사용 필수
// 💡 Java 비교: DateTimeFormatter와 NumberFormat의 재사용 패턴과 동일

import Foundation

// MARK: - Formatters

/// 중앙 집중식 포매터 관리
/// - 성능 최적화를 위해 포매터 인스턴스를 재사용
/// - 루프나 반복 작업에서 포매터 생성 금지
///
/// ## 성능 최적화
/// DateFormatter와 NumberFormatter는 생성 비용이 높음:
/// - 인스턴스 생성마다 수백 마이크로초 소요
/// - 반복문에서 매번 생성하면 성능 저하 발생
/// - static lazy로 한 번만 생성하여 재사용
///
/// ## 사용 예시
/// ```swift
/// // ❌ 나쁜 예: 반복문에서 매번 생성
/// for record in records {
///     let formatter = NumberFormatter()
///     formatter.numberStyle = .decimal
///     formatter.minimumFractionDigits = 1
///     let text = formatter.string(from: record.weight)
/// }
///
/// // ✅ 좋은 예: 공유 인스턴스 재사용
/// for record in records {
///     let text = Formatters.weight.string(from: record.weight)
/// }
/// ```
enum Formatters {

    // MARK: - Number Formatters

    /// 체중용 포매터 (소수점 1자리, 단위 구분 없음)
    /// - 예: "67.5", "70.0"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let weight = 67.5
    /// let text = Formatters.weight.string(from: NSNumber(value: weight)) // "67.5"
    /// weightLabel.text = "\(text ?? "0")kg"
    /// ```
    static let weight: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.groupingSeparator = "" // 천 단위 구분 기호 없음
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 체지방률용 포매터 (소수점 1자리)
    /// - 예: "18.3", "15.0"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let bodyFat = 18.3
    /// let text = Formatters.bodyFat.string(from: NSNumber(value: bodyFat)) // "18.3"
    /// bodyFatLabel.text = "\(text ?? "0")%"
    /// ```
    static let bodyFat: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.groupingSeparator = ""
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 칼로리용 포매터 (정수, 천 단위 구분)
    /// - 예: "2,150", "350"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let calories = 2150
    /// let text = Formatters.calories.string(from: NSNumber(value: calories)) // "2,150"
    /// caloriesLabel.text = "\(text ?? "0")kcal"
    /// ```
    static let calories: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 영양소(탄수화물/단백질/지방)용 포매터 (정수)
    /// - 예: "250", "80"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let carbs = 250
    /// let text = Formatters.macros.string(from: NSNumber(value: carbs)) // "250"
    /// carbsLabel.text = "\(text ?? "0")g"
    /// ```
    static let macros: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "" // 영양소는 천 단위 구분 불필요
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 퍼센트용 포매터 (소수점 1자리, % 기호 포함)
    /// - 예: "25.5%", "100.0%"
    ///
    /// ## 사용 예시
    /// ```swift
    /// // 탄수화물 비율: 0.255 (25.5%)
    /// let carbRatio = 0.255
    /// let text = Formatters.percentage.string(from: NSNumber(value: carbRatio)) // "25.5%"
    /// ratioLabel.text = text
    /// ```
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 범용 소수용 포매터 (소수점 2자리)
    /// - 예: "1.25", "3.50"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let multiplier = 1.375
    /// let text = Formatters.decimal.string(from: NSNumber(value: multiplier)) // "1.38"
    /// ```
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    // MARK: - Date Formatters

    /// 전체 날짜 포매터 (yyyy년 MM월 dd일)
    /// - 예: "2024년 01월 15일"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let date = Date()
    /// let text = Formatters.fullDate.string(from: date) // "2024년 01월 15일"
    /// dateLabel.text = text
    /// ```
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 짧은 날짜 포매터 (M월 d일)
    /// - 예: "1월 15일"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let date = Date()
    /// let text = Formatters.shortDate.string(from: date) // "1월 15일"
    /// chartLabel.text = text
    /// ```
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 요일 포함 날짜 포매터 (M월 d일 (E))
    /// - 예: "1월 15일 (월)"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let date = Date()
    /// let text = Formatters.dateWithWeekday.string(from: date) // "1월 15일 (월)"
    /// headerLabel.text = text
    /// ```
    static let dateWithWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 시간 포매터 (HH:mm)
    /// - 예: "14:30", "09:05"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let date = Date()
    /// let text = Formatters.time.string(from: date) // "14:30"
    /// timeLabel.text = text
    /// ```
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 날짜+시간 포매터 (M월 d일 HH:mm)
    /// - 예: "1월 15일 14:30"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let date = Date()
    /// let text = Formatters.dateTime.string(from: date) // "1월 15일 14:30"
    /// timestampLabel.text = text
    /// ```
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// ISO 8601 날짜 포매터 (API 통신용)
    /// - 예: "2024-01-15T14:30:00Z"
    ///
    /// ## 사용 예시
    /// ```swift
    /// let date = Date()
    /// let text = Formatters.iso8601.string(from: date) // "2024-01-15T14:30:00Z"
    /// apiRequest.timestamp = text
    /// ```
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    // MARK: - Convenience Methods

    /// Decimal을 체중 형식으로 포매팅
    /// - Parameter value: Decimal 값
    /// - Returns: "67.5" 형식의 문자열
    ///
    /// ## 사용 예시
    /// ```swift
    /// let weight: Decimal = 67.5
    /// let text = Formatters.formatWeight(weight) // "67.5"
    /// ```
    static func formatWeight(_ value: Decimal) -> String {
        weight.string(from: NSDecimalNumber(decimal: value)) ?? "0.0"
    }

    /// Decimal을 체지방률 형식으로 포매팅
    /// - Parameter value: Decimal 값
    /// - Returns: "18.3" 형식의 문자열
    ///
    /// ## 사용 예시
    /// ```swift
    /// let bodyFat: Decimal = 18.3
    /// let text = Formatters.formatBodyFat(bodyFat) // "18.3"
    /// ```
    static func formatBodyFat(_ value: Decimal) -> String {
        bodyFat.string(from: NSDecimalNumber(decimal: value)) ?? "0.0"
    }

    /// Decimal을 칼로리 형식으로 포매팅
    /// - Parameter value: Decimal 값
    /// - Returns: "2,150" 형식의 문자열
    ///
    /// ## 사용 예시
    /// ```swift
    /// let cal: Decimal = 2150
    /// let text = Formatters.formatCalories(cal) // "2,150"
    /// ```
    static func formatCalories(_ value: Decimal) -> String {
        calories.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }

    /// Decimal을 영양소(그램) 형식으로 포매팅
    /// - Parameter value: Decimal 값
    /// - Returns: "250" 형식의 문자열
    ///
    /// ## 사용 예시
    /// ```swift
    /// let carbs: Decimal = 250
    /// let text = Formatters.formatMacros(carbs) // "250"
    /// ```
    static func formatMacros(_ value: Decimal) -> String {
        macros.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
}

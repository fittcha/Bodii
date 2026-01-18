//
//  Date+Extensions.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Swift Extensions for Convenience API
// Foundation의 Date 타입을 확장하여 편리한 날짜 처리 메서드 제공
// 💡 Java 비교: Kotlin의 extension functions와 유사

import Foundation

// MARK: - Date Extensions

/// Date 타입 확장
/// - DateUtils의 기능을 Date 인스턴스에서 직접 호출할 수 있도록 편의 메서드 제공
/// - 더 자연스러운 API: `date.startOfDay` vs `DateUtils.startOfDay(for: date)`
///
/// ## 예시
/// ```swift
/// let today = Date()
/// let dayStart = today.startOfDay // 오늘 00:00:00
/// let dayEnd = today.endOfDay // 오늘 23:59:59
/// let tomorrow = today.isSameDay(as: otherDate)
/// let age = Date.age(from: birthDate)
/// ```
extension Date {

    // MARK: - Day Boundaries

    /// 이 날짜의 시작 시간 (00:00:00)
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-15 14:30:25 → 2024-01-15 00:00:00
    /// let start = date.startOfDay
    /// ```
    var startOfDay: Date {
        DateUtils.startOfDay(for: self)
    }

    /// 이 날짜의 종료 시간 (23:59:59)
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-15 14:30:25 → 2024-01-15 23:59:59
    /// let end = date.endOfDay
    /// ```
    var endOfDay: Date {
        DateUtils.endOfDay(for: self)
    }

    // MARK: - Date Comparison

    /// 다른 날짜와 같은 날인지 비교
    /// - Parameter other: 비교할 날짜
    /// - Returns: 같은 날이면 true
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-15 09:00과 2024-01-15 18:00 → true
    /// // 2024-01-15 23:00과 2024-01-16 01:00 → false
    /// if date1.isSameDay(as: date2) {
    ///     print("같은 날입니다")
    /// }
    /// ```
    func isSameDay(as other: Date) -> Bool {
        DateUtils.isSameDay(self, other)
    }

    /// 이 날짜가 오늘인지 확인
    ///
    /// ## 예시
    /// ```swift
    /// if recordDate.isToday {
    ///     print("오늘 기록입니다")
    /// }
    /// ```
    var isToday: Bool {
        DateUtils.isToday(self)
    }

    /// 다른 날짜까지의 일수 차이 계산
    /// - Parameter other: 비교할 날짜
    /// - Returns: 일수 차이 (other - self)
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-10부터 2024-01-15까지
    /// let days = startDate.daysBetween(and: endDate) // 5
    /// ```
    func daysBetween(and other: Date) -> Int {
        DateUtils.daysBetween(self, and: other)
    }

    // MARK: - Age Calculation

    /// 생년월일로부터 나이 계산
    /// - Parameters:
    ///   - birthDate: 생년월일
    ///   - referenceDate: 기준 날짜 (기본값: 현재)
    /// - Returns: 만 나이
    ///
    /// ## 예시
    /// ```swift
    /// // 1990-05-15 생일 → 2024-01-15 기준 33세
    /// let age = Date.age(from: birthDate)
    ///
    /// // 특정 날짜 기준 나이
    /// let ageAt2023 = Date.age(from: birthDate, referenceDate: someDate)
    /// ```
    static func age(from birthDate: Date, referenceDate: Date = Date()) -> Int {
        DateUtils.age(from: birthDate, referenceDate: referenceDate)
    }

    // MARK: - Formatting

    /// 날짜 포맷 스타일
    /// - 한국어 로케일 기반 날짜 포매팅 옵션
    enum FormatStyle {
        /// "yyyy년 MM월 dd일" (예: "2024년 01월 15일")
        case full
        /// "M월 d일" (예: "1월 15일")
        case short
        /// "M월 d일 (E)" (예: "1월 15일 (월)")
        case withWeekday
        /// "HH:mm" (예: "14:30")
        case time
        /// "M월 d일 HH:mm" (예: "1월 15일 14:30")
        case dateTime

        /// 포맷 문자열
        fileprivate var formatString: String {
            switch self {
            case .full:
                return "yyyy년 MM월 dd일"
            case .short:
                return "M월 d일"
            case .withWeekday:
                return "M월 d일 (E)"
            case .time:
                return "HH:mm"
            case .dateTime:
                return "M월 d일 HH:mm"
            }
        }
    }

    /// 날짜를 지정된 스타일로 포맷
    /// - Parameter style: 포맷 스타일
    /// - Returns: 포맷된 날짜 문자열
    ///
    /// ## 예시
    /// ```swift
    /// let fullDate = date.formatted(style: .full) // "2024년 01월 15일"
    /// let shortDate = date.formatted(style: .short) // "1월 15일"
    /// let withDay = date.formatted(style: .withWeekday) // "1월 15일 (월)"
    /// let timeOnly = date.formatted(style: .time) // "14:30"
    /// let dateTime = date.formatted(style: .dateTime) // "1월 15일 14:30"
    /// ```
    func formatted(style: FormatStyle) -> String {
        DateUtils.format(self, format: style.formatString)
    }
}

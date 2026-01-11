//
//  DateUtils.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Date Utilities with Sleep Boundary Logic
// 수면 경계 시간(02:00)을 적용한 날짜 처리 유틸리티
// 💡 Java 비교: Joda-Time/java.time.LocalDateTime의 사용자 정의 날짜 경계 로직과 유사

import Foundation

// MARK: - DateUtils

/// 날짜 처리 유틸리티
/// - 02:00 수면 경계 로직을 적용한 논리적 날짜 계산
/// - 한국 로케일 기반 날짜 포매팅
///
/// ## 수면 경계 로직
/// 실제 활동은 02:00 이전까지는 전날의 연장으로 간주:
/// - 00:00 ~ 01:59 → 전날로 간주
/// - 02:00 ~ 23:59 → 당일로 간주
///
/// ## 예시
/// ```swift
/// // 2024년 1월 2일 01:30 → 2024년 1월 1일 (전날)
/// let date1 = DateUtils.getLogicalDate(for: jan2_0130)
///
/// // 2024년 1월 2일 02:00 → 2024년 1월 2일 (당일)
/// let date2 = DateUtils.getLogicalDate(for: jan2_0200)
///
/// // 새로운 날 시작 여부 확인
/// let isNewDay = DateUtils.isNewDayForSleep(at: date)
/// ```
enum DateUtils {

    // MARK: - Sleep Boundary Logic

    /// 논리적 날짜 반환 (02:00 수면 경계 적용)
    /// - Parameter date: 실제 날짜/시간
    /// - Returns: 논리적 날짜 (시간 정보 제거된 순수 날짜)
    ///
    /// ## 로직
    /// - 시간이 00:00 ~ 01:59 사이이면 전날 반환
    /// - 시간이 02:00 ~ 23:59 사이이면 당일 반환
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-02 01:59 → 2024-01-01
    /// // 2024-01-02 02:00 → 2024-01-02
    /// // 2024-01-02 12:00 → 2024-01-02
    /// ```
    static func getLogicalDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        // 02:00 이전이면 전날로 간주
        if hour < Constants.Sleep.boundaryHour {
            // 하루를 빼고 시간 정보 제거
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return calendar.startOfDay(for: date)
            }
            return calendar.startOfDay(for: previousDay)
        }

        // 02:00 이후면 당일, 시간 정보 제거
        return calendar.startOfDay(for: date)
    }

    /// 수면 경계를 넘어 새로운 날인지 확인
    /// - Parameter date: 확인할 날짜/시간
    /// - Returns: true면 새로운 날 시작 (02:00 이후), false면 아직 전날 (02:00 이전)
    ///
    /// ## 사용 예시
    /// - 수면 기록 저장 시 새로운 날인지 확인
    /// - DailyLog 업데이트 여부 판단
    ///
    /// ## 예시
    /// ```swift
    /// // 01:59 → false (아직 전날)
    /// // 02:00 → true (새로운 날)
    /// // 12:00 → true (새로운 날)
    /// ```
    static func isNewDayForSleep(at date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour >= Constants.Sleep.boundaryHour
    }

    // MARK: - Day Boundaries

    /// 특정 날짜의 시작 시간 반환 (00:00:00)
    /// - Parameter date: 기준 날짜
    /// - Returns: 해당 날짜의 00:00:00
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-15 14:30:25 → 2024-01-15 00:00:00
    /// ```
    static func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }

    /// 특정 날짜의 종료 시간 반환 (23:59:59)
    /// - Parameter date: 기준 날짜
    /// - Returns: 해당 날짜의 23:59:59
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-15 14:30:25 → 2024-01-15 23:59:59
    /// ```
    static func endOfDay(for date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.day = 1
        components.second = -1

        guard let endDate = calendar.date(byAdding: components, to: startOfDay(for: date)) else {
            return date
        }
        return endDate
    }

    // MARK: - Date Formatting

    /// 공유 DateFormatter (한국 로케일)
    /// - 성능 최적화를 위해 static으로 재사용
    private static let sharedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    /// 날짜를 한국어 형식으로 포맷
    /// - Parameters:
    ///   - date: 포맷할 날짜
    ///   - format: 날짜 포맷 문자열 (예: "yyyy년 MM월 dd일")
    /// - Returns: 포맷된 날짜 문자열
    ///
    /// ## 예시
    /// ```swift
    /// DateUtils.format(date, format: "yyyy년 MM월 dd일") // "2024년 01월 15일"
    /// DateUtils.format(date, format: "M월 d일 (E)") // "1월 15일 (월)"
    /// DateUtils.format(date, format: "HH:mm") // "14:30"
    /// ```
    static func format(_ date: Date, format: String) -> String {
        sharedFormatter.dateFormat = format
        return sharedFormatter.string(from: date)
    }

    /// 날짜를 "yyyy년 MM월 dd일" 형식으로 포맷
    /// - Parameter date: 포맷할 날짜
    /// - Returns: "2024년 01월 15일" 형식의 문자열
    static func formatFullDate(_ date: Date) -> String {
        return format(date, format: "yyyy년 MM월 dd일")
    }

    /// 날짜를 "M월 d일" 형식으로 포맷
    /// - Parameter date: 포맷할 날짜
    /// - Returns: "1월 15일" 형식의 문자열
    static func formatShortDate(_ date: Date) -> String {
        return format(date, format: "M월 d일")
    }

    /// 날짜를 "M월 d일 (E)" 형식으로 포맷 (요일 포함)
    /// - Parameter date: 포맷할 날짜
    /// - Returns: "1월 15일 (월)" 형식의 문자열
    static func formatDateWithWeekday(_ date: Date) -> String {
        return format(date, format: "M월 d일 (E)")
    }

    /// 시간을 "HH:mm" 형식으로 포맷
    /// - Parameter date: 포맷할 날짜/시간
    /// - Returns: "14:30" 형식의 문자열
    static func formatTime(_ date: Date) -> String {
        return format(date, format: "HH:mm")
    }

    /// 날짜와 시간을 "M월 d일 HH:mm" 형식으로 포맷
    /// - Parameter date: 포맷할 날짜/시간
    /// - Returns: "1월 15일 14:30" 형식의 문자열
    static func formatDateTime(_ date: Date) -> String {
        return format(date, format: "M월 d일 HH:mm")
    }

    // MARK: - Date Comparison

    /// 두 날짜가 같은 날인지 비교
    /// - Parameters:
    ///   - date1: 첫 번째 날짜
    ///   - date2: 두 번째 날짜
    /// - Returns: 같은 날이면 true
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-15 09:00과 2024-01-15 18:00 → true
    /// // 2024-01-15 23:00과 2024-01-16 01:00 → false
    /// ```
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    /// 날짜가 오늘인지 확인
    /// - Parameter date: 확인할 날짜
    /// - Returns: 오늘이면 true
    static func isToday(_ date: Date) -> Bool {
        return isSameDay(date, Date())
    }

    /// 두 날짜 사이의 일수 차이 계산
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 일수 차이 (endDate - startDate)
    ///
    /// ## 예시
    /// ```swift
    /// // 2024-01-10부터 2024-01-15까지 → 5일
    /// ```
    static func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay(for: startDate), to: startOfDay(for: endDate))
        return components.day ?? 0
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
    /// let age = DateUtils.age(from: birthDate)
    /// ```
    static func age(from birthDate: Date, referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: referenceDate)
        return ageComponents.year ?? 0
    }
}

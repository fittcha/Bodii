//
//  Constants.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// App-wide configuration constants
enum Constants {

    // MARK: - Validation Ranges

    enum Validation {
        /// Height validation range (cm)
        enum Height {
            static let min: Double = 100
            static let max: Double = 250
        }

        /// Weight validation range (kg)
        enum Weight {
            static let min: Double = 20
            static let max: Double = 300
        }

        /// Body fat percentage validation range (%)
        enum BodyFatPercentage {
            static let min: Double = 1
            static let max: Double = 60
        }

        /// Name length validation range
        enum Name {
            static let minLength: Int = 1
            static let maxLength: Int = 20
        }

        /// Birth year validation range
        enum BirthYear {
            static let min: Int = 1900
            static var max: Int {
                Calendar.current.component(.year, from: Date())
            }
        }

        /// Exercise duration validation (minutes)
        enum Exercise {
            static let minDuration: Int = 1
        }

        /// Food serving size validation
        enum Serving {
            static let min: Double = 0.1
        }
    }

    // MARK: - Warning Thresholds

    enum Threshold {
        /// Body fat percentage warning thresholds (%)
        enum BodyFat {
            static let extremeLow: Double = 3
            static let extremeHigh: Double = 50
        }

        /// Weight change warning threshold (kg)
        enum WeightChange {
            static let rapid: Double = 3
        }

        /// Exercise duration warning threshold (minutes)
        enum Exercise {
            static let excessive: Int = 480 // 8 hours
        }

        /// Food serving size warning threshold
        enum Serving {
            static let excessive: Double = 100
        }
    }

    // MARK: - Sleep Constants

    enum Sleep {
        /// Sleep day boundary hour (02:00)
        /// Hours 00:00-01:59 belong to previous day
        static let boundaryHour: Int = 2

        /// Maximum sleep popup retry count
        static let maxPopupRetries: Int = 3

        /// Sleep duration ranges for status (minutes)
        enum Duration {
            static let badMax: Int = 330        // < 5h 30m
            static let sosoMax: Int = 390       // 5h 30m - 6h 30m
            static let goodMax: Int = 450       // 6h 30m - 7h 30m
            static let excellentMax: Int = 540  // 7h 30m - 9h
            // > 540 = Oversleep
        }
    }

    // MARK: - Activity Level Multipliers (TDEE)

    enum ActivityLevel {
        static let sedentary: Double = 1.2
        static let light: Double = 1.375
        static let moderate: Double = 1.55
        static let active: Double = 1.725
        static let veryActive: Double = 1.9
    }

    // MARK: - BMR Formula Constants

    enum BMR {
        /// Katch-McArdle formula (used when body fat % is available)
        enum KatchMcArdle {
            static let base: Double = 370
            static let multiplier: Double = 21.6
        }

        /// Mifflin-St Jeor formula (used when body fat % is unavailable)
        enum MifflinStJeor {
            static let weightMultiplier: Double = 10
            static let heightMultiplier: Double = 6.25
            static let ageMultiplier: Double = 5
            static let maleConstant: Double = 5
            static let femaleConstant: Double = -161
        }
    }

    // MARK: - Diet Score Ranges

    enum DietScore {
        static let greatMin: Int = 8
        static let greatMax: Int = 10
        static let goodMin: Int = 5
        static let goodMax: Int = 7
        static let needsWorkMin: Int = 0
        static let needsWorkMax: Int = 4
    }

    // MARK: - API Limits

    enum API {
        /// Google Gemini API rate limits
        enum Gemini {
            static let requestsPerMinute: Int = 15
        }

        /// Google Cloud Vision API limits
        enum Vision {
            static let monthlyFreeRequests: Int = 1000
        }

        /// 식약처(KFDA) API 설정
        enum KFDA {
            /// 기본 페이지 크기
            static let defaultPageSize: Int = 10

            /// 최대 페이지 크기
            static let maxPageSize: Int = 100

            /// API 타임아웃 (초)
            static let timeout: TimeInterval = 30

            /// 최대 재시도 횟수
            static let maxRetries: Int = 2
        }

        /// USDA FoodData Central API 설정
        enum USDA {
            /// 기본 페이지 크기
            static let defaultPageSize: Int = 25

            /// 최대 페이지 크기
            static let maxPageSize: Int = 200

            /// API 타임아웃 (초)
            static let timeout: TimeInterval = 30

            /// 최대 재시도 횟수
            static let maxRetries: Int = 2

            /// DEMO_KEY rate limits
            enum DemoKeyLimits {
                /// 시간당 요청 제한
                static let requestsPerHour: Int = 30

                /// 일일 요청 제한
                static let requestsPerDay: Int = 50
            }
        }

        /// 식품 검색 캐시 설정
        enum FoodCache {
            /// 캐시 최대 크기 (개수)
            static let maxCachedFoods: Int = 500

            /// 캐시 유효 기간 (일)
            static let cacheExpirationDays: Int = 30

            /// 최근 검색 식품 표시 개수
            static let recentFoodsCount: Int = 10
        }
    }

    // MARK: - HealthKit Sync

    enum HealthKit {
        /// Default number of days to sync from HealthKit
        static let defaultSyncDays: Int = 7
    }
}

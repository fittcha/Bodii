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

        /// Morning prompt hour (06:00)
        /// Show sleep recording prompt at 6 AM or later
        /// 📚 학습 포인트: Separation of Concerns
        /// - boundaryHour: Date assignment logic (when sleep belongs to previous day)
        /// - promptHour: User notification timing (when to show prompt)
        /// 💡 Java 비교: Different constants for different business rules
        static let promptHour: Int = 6

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
        /// KFDA (식약처) API configuration
        enum KFDA {
            static let timeout: TimeInterval = 30
            static let maxRetries: Int = 2
            static let defaultPageSize: Int = 10
            static let maxPageSize: Int = 100
        }

        /// USDA FoodData Central API configuration
        enum USDA {
            static let timeout: TimeInterval = 30
            static let maxRetries: Int = 2
            static let defaultPageSize: Int = 25
            static let maxPageSize: Int = 200
        }

        /// Google Gemini API configuration
        enum Gemini {
            static let requestsPerMinute: Int = 15
            static let timeout: TimeInterval = 60
            static let maxRetries: Int = 2
            static let rateLimitWindow: TimeInterval = 60 // 1 minute in seconds
        }

        /// Google Cloud Vision API limits
        enum Vision {
            static let monthlyFreeRequests: Int = 1000
        }
    }

    // MARK: - HealthKit Sync

    enum HealthKit {
        /// Default number of days to sync from HealthKit
        static let defaultSyncDays: Int = 7
    }
}
# Apple HealthKit Integration

Bidirectional sync with Apple HealthKit for weight, body fat, active calories, sleep, and workout data. Read existing data and write Bodii records to maintain ecosystem connectivity.

## Rationale
Essential for iOS health app ecosystem. Users expect Apple Health integration. Differentiator vs. cross-platform apps that have limited HealthKit support. Native SwiftUI provides optimal integration quality that Flutter/React Native can't match.

## User Stories
- As an Apple Watch user, I want my workout data to sync to Bodii automatically
- As a user, I want my Bodii data in Apple Health so that my doctors can see it

## Acceptance Criteria
- [ ] HealthKit entitlements properly configured
- [ ] Permission request explains all data types needed
- [ ] Read weight, body fat, active calories from HealthKit
- [ ] Write Bodii records to HealthKit (weight, workouts, sleep)
- [ ] Background sync when app is closed
- [ ] Conflict resolution for duplicate entries
- [ ] Graceful handling when user denies permissions

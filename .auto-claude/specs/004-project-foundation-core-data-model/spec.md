# Specification: Project Foundation & Core Data Model

## Overview

This task establishes the foundation layer for the Bodii health/fitness tracking iOS application. It implements the complete type system (enums), utility services for date handling with a critical **02:00 sleep boundary** rule, domain entities representing the core business objects, and Core Data persistence extensions. This foundation enables all subsequent features including body composition tracking, meal logging, exercise tracking, and sleep monitoring.

## Workflow Type

**Type**: feature

**Rationale**: This is a new feature implementation that creates the entire foundation layer from scratch. It involves multiple interconnected components (enums, utilities, domain entities, persistence) that must work together cohesively. The domain-driven design requires careful implementation of business rules embedded in the type system.

## Task Scope

### Services Involved
- **main** (primary) - Single iOS application with SwiftUI and Core Data

### This Task Will:
- [ ] Define all application enums (Gender, ActivityLevel, MealType, ExerciseType, Intensity, FoodSource, GoalType, SleepStatus, QuantityUnit, Constants)
- [ ] Implement DateUtils with 02:00 sleep boundary logic
- [ ] Create ValidationService for input validation
- [ ] Add Date+Extensions and Decimal+Extensions
- [ ] Build Formatters utility for display formatting
- [ ] Define 9 domain entities (User, BodyRecord, MetabolismSnapshot, Food, FoodRecord, ExerciseRecord, SleepRecord, DailyLog, Goal)
- [ ] Create Core Data entity extensions for persistence mapping
- [ ] Write unit tests for DateUtils, ValidationService, and SleepStatus

### Out of Scope:
- UI/View layer implementation
- Repository/Service layer implementation
- HealthKit integration
- API integration (Food search, AI features)
- iCloud synchronization

## Service Context

### Main Service (iOS App)

**Tech Stack:**
- Language: Swift
- Framework: SwiftUI
- Persistence: Core Data
- Package Manager: Xcode

**Entry Point:** `Bodii/App/BodiiApp.swift`

**How to Run:**
```bash
open Bodii.xcodeproj
# Build and run in Xcode (Cmd+R)
```

**Port:** N/A (Native iOS application)

**Key Directories:**
- `Bodii/Shared/Enums/` - Type definitions
- `Bodii/Shared/Utils/` - Utility services
- `Bodii/Shared/Extensions/` - Swift extensions
- `Bodii/Domain/Entities/` - Domain models
- `Bodii/Infrastructure/Persistence/` - Core Data

## Files to Modify

| File | Service | What to Change |
|------|---------|---------------|
| `Bodii/Shared/Enums/Gender.swift` | main | Create Gender enum with male/female cases, Int16 rawValue |
| `Bodii/Shared/Enums/ActivityLevel.swift` | main | Create ActivityLevel enum with 5 levels and multiplier property |
| `Bodii/Shared/Enums/MealType.swift` | main | Create MealType enum (breakfast/lunch/dinner/snack) |
| `Bodii/Shared/Enums/ExerciseType.swift` | main | Create ExerciseType enum with 8 exercise types and MET values |
| `Bodii/Shared/Enums/Intensity.swift` | main | Create Intensity enum (low/medium/high) with multipliers |
| `Bodii/Shared/Enums/FoodSource.swift` | main | Create FoodSource enum (API sources, user-defined) |
| `Bodii/Shared/Enums/GoalType.swift` | main | Create GoalType enum (lose/maintain/gain) |
| `Bodii/Shared/Enums/SleepStatus.swift` | main | Create SleepStatus enum with duration-based factory method |
| `Bodii/Shared/Enums/QuantityUnit.swift` | main | Create QuantityUnit enum (serving/grams) |
| `Bodii/Shared/Utils/Constants.swift` | main | Create Constants enum with app-wide configuration values |
| `Bodii/Shared/Utils/DateUtils.swift` | main | Create DateUtils with 02:00 sleep boundary logic |
| `Bodii/Shared/Utils/ValidationService.swift` | main | Create ValidationService with input validation rules |
| `Bodii/Shared/Utils/Formatters.swift` | main | Create Formatters for consistent display formatting |
| `Bodii/Shared/Extensions/Date+Extensions.swift` | main | Add date manipulation and age calculation extensions |
| `Bodii/Shared/Extensions/Decimal+Extensions.swift` | main | Add decimal formatting and arithmetic extensions |
| `Bodii/Domain/Entities/User.swift` | main | Create User domain entity struct |
| `Bodii/Domain/Entities/BodyRecord.swift` | main | Create BodyRecord domain entity struct |
| `Bodii/Domain/Entities/MetabolismSnapshot.swift` | main | Create MetabolismSnapshot domain entity struct |
| `Bodii/Domain/Entities/Food.swift` | main | Create Food domain entity struct |
| `Bodii/Domain/Entities/FoodRecord.swift` | main | Create FoodRecord domain entity struct |
| `Bodii/Domain/Entities/ExerciseRecord.swift` | main | Create ExerciseRecord domain entity struct |
| `Bodii/Domain/Entities/SleepRecord.swift` | main | Create SleepRecord domain entity struct |
| `Bodii/Domain/Entities/DailyLog.swift` | main | Create DailyLog domain entity struct |
| `Bodii/Domain/Entities/Goal.swift` | main | Create Goal domain entity struct |
| `Bodii/Infrastructure/Persistence/Bodii.xcdatamodeld` | main | Define Core Data entities matching domain models |
| `BodiiTests/DateUtilsTests.swift` | main | Unit tests for DateUtils including 02:00 boundary |
| `BodiiTests/ValidationServiceTests.swift` | main | Unit tests for ValidationService |
| `BodiiTests/SleepStatusTests.swift` | main | Unit tests for SleepStatus.from(durationMinutes:) |

## Files to Reference

These files show patterns to follow:

| File | Pattern to Copy |
|------|----------------|
| `docs/04_ERD.md` | Entity structure, relationships, field types, and constraints |
| `docs/02_FEATURE_SPEC.md` | Business rules, validation ranges, calculation formulas |
| `docs/06_ALGORITHM.md` | BMR/TDEE formulas, MET values, calculation logic |
| `docs/08_EDGE_CASES.md` | Edge cases, validation rules, error handling |

## Patterns to Follow

### Pattern 1: Enum with Int16 RawValue for Core Data

From existing codebase pattern:

```swift
enum Gender: Int16, CaseIterable, Codable {
    case male = 0
    case female = 1

    var displayName: String {
        switch self {
        case .male: return "남성"
        case .female: return "여성"
        }
    }
}

extension Gender: Identifiable {
    var id: Int16 { rawValue }
}
```

**Key Points:**
- Use Int16 rawValue for Core Data compatibility
- Implement CaseIterable for iteration in UI
- Implement Codable for serialization
- Add displayName computed property for Korean localization
- Extend with Identifiable for SwiftUI

### Pattern 2: Domain Entity as Struct

From existing codebase pattern:

```swift
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var gender: Gender
    // ... other properties

    var age: Int {
        Date.age(from: birthDate)
    }
}

extension User: CustomStringConvertible {
    var description: String { /* debug output */ }
}
```

**Key Points:**
- Use struct for immutability and value semantics
- Implement Identifiable, Codable, Equatable
- Use let for immutable fields (id, createdAt)
- Use var for mutable fields
- Add computed properties for derived values
- Extend with CustomStringConvertible for debugging

### Pattern 3: Static Utility Methods

From DateUtils pattern:

```swift
enum DateUtils {
    static func getLogicalDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if hour < Constants.Sleep.boundaryHour {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return calendar.startOfDay(for: date)
            }
            return calendar.startOfDay(for: previousDay)
        }
        return calendar.startOfDay(for: date)
    }
}
```

**Key Points:**
- Use enum with no cases as namespace for static methods
- Reference Constants for magic numbers
- Document with comprehensive docstrings
- Handle edge cases with guard statements

### Pattern 4: Factory Method in Enum

From SleepStatus pattern:

```swift
static func from(durationMinutes: Int) -> SleepStatus {
    switch durationMinutes {
    case ..<330: return .bad
    case 330..<390: return .soso
    case 390..<450: return .good
    case 450...540: return .excellent
    default: return .oversleep
    }
}
```

**Key Points:**
- Use static factory method for creating enum from input
- Use range matching for cleaner logic
- Document threshold values in comments

## Requirements

### Functional Requirements

1. **Enum Type Safety**
   - Description: All enums must use Int16 rawValue for Core Data storage
   - Acceptance: Enum values correctly serialize/deserialize with Core Data

2. **02:00 Sleep Boundary**
   - Description: Activities between 00:00-01:59 count toward previous day for sleep tracking
   - Acceptance: `DateUtils.getLogicalDate(Date("2024-01-02 01:30"))` returns 2024-01-01

3. **SleepStatus Auto-Determination**
   - Description: Sleep status automatically determined from duration in minutes
   - Acceptance: `SleepStatus.from(durationMinutes: 400)` returns `.good`

4. **Validation Service**
   - Description: Centralized validation for all user inputs
   - Acceptance: ValidationService correctly validates:
     - Height: 100-250cm
     - Weight: 20-300kg
     - Body fat %: 3-60%
     - Name: 1-20 characters

5. **Domain Entity Completeness**
   - Description: All 9 domain entities match ERD specification
   - Acceptance: Each entity contains all fields from docs/04_ERD.md

6. **ActivityLevel Multipliers**
   - Description: Each activity level provides correct TDEE multiplier
   - Acceptance: Multipliers match: sedentary=1.2, light=1.375, moderate=1.55, active=1.725, veryActive=1.9

7. **ExerciseType MET Values**
   - Description: Each exercise type provides base MET value for calorie calculation
   - Acceptance: MET values match docs/06_ALGORITHM.md specification

### Edge Cases

1. **Midnight Boundary** - Date at exactly 00:00:00 should be treated as previous day
2. **02:00 Exact Boundary** - Date at exactly 02:00:00 should be treated as current day
3. **Leap Year** - Age calculation handles leap years correctly
4. **Decimal Precision** - Body measurements maintain proper decimal precision (1 decimal place for display)
5. **Zero Sleep Duration** - 0 minutes sleep should return `.bad` status (밤샘)
6. **Maximum Sleep Duration** - Very long durations (>24 hours) should return `.oversleep`

## Implementation Notes

### DO
- Follow the enum pattern with Int16 rawValue for all enums
- Use `Decimal` type for body measurements (weight, height, body fat %) for precision
- Implement comprehensive docstrings with examples (Korean language)
- Use Constants for all magic numbers (sleep boundary = 2, validation ranges)
- Create unit tests for critical business logic (DateUtils, ValidationService, SleepStatus)
- Reference docs/04_ERD.md for exact field names and types

### DON'T
- Create repository or service layer (out of scope for this task)
- Implement Core Data fetch/save operations (only entity definitions)
- Use Float/Double for financial or measurement calculations
- Hardcode validation ranges (use Constants)
- Skip unit tests for DateUtils 02:00 boundary logic

## Development Environment

### Start Services

```bash
# Open project in Xcode
open Bodii.xcodeproj

# Run tests from command line
xcodebuild test -project Bodii.xcodeproj -scheme Bodii -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Service URLs
- N/A (Native iOS application)

### Required Environment Variables
- None required for this foundation task

## Success Criteria

The task is complete when:

1. [ ] All 10 enums defined with Int16 rawValue and displayName
2. [ ] DateUtils implements 02:00 sleep boundary correctly
3. [ ] ValidationService validates all input ranges per docs/08_EDGE_CASES.md
4. [ ] All 9 domain entities defined matching docs/04_ERD.md
5. [ ] Unit tests pass for DateUtils, ValidationService, SleepStatus
6. [ ] No Xcode build errors or warnings
7. [ ] Code follows existing patterns (docstrings, MARK comments)

## QA Acceptance Criteria

**CRITICAL**: These criteria must be verified by the QA Agent before sign-off.

### Unit Tests
| Test | File | What to Verify |
|------|------|----------------|
| DateUtils Sleep Boundary | `BodiiTests/DateUtilsTests.swift` | 01:59 returns previous day, 02:00 returns current day |
| DateUtils Edge Cases | `BodiiTests/DateUtilsTests.swift` | Midnight (00:00), end of day (23:59), leap years |
| ValidationService Height | `BodiiTests/ValidationServiceTests.swift` | Valid 100-250cm, invalid <100 or >250 |
| ValidationService Weight | `BodiiTests/ValidationServiceTests.swift` | Valid 20-300kg, invalid <20 or >300 |
| ValidationService BodyFat | `BodiiTests/ValidationServiceTests.swift` | Valid 3-60%, invalid <3 or >60 |
| ValidationService Name | `BodiiTests/ValidationServiceTests.swift` | Valid 1-20 chars, invalid empty or >20 |
| SleepStatus Factory | `BodiiTests/SleepStatusTests.swift` | All duration ranges map to correct status |
| SleepStatus Zero | `BodiiTests/SleepStatusTests.swift` | 0 minutes returns .bad |
| SleepStatus Boundaries | `BodiiTests/SleepStatusTests.swift` | 329->bad, 330->soso, 389->soso, 390->good, etc. |

### Integration Tests
| Test | Services | What to Verify |
|------|----------|----------------|
| Domain Entity Serialization | Domain ↔ Codable | All entities encode/decode correctly via Codable |
| Enum Raw Value Mapping | Enums ↔ Int16 | All enums convert to/from Int16 correctly |

### End-to-End Tests
| Flow | Steps | Expected Outcome |
|------|-------|------------------|
| Type System Completeness | 1. Review all enums 2. Check rawValue types | All 10 enums have Int16 rawValue |
| Domain Model Completeness | 1. Compare entities to ERD 2. Verify all fields | All 9 entities match docs/04_ERD.md |

### Browser Verification (if frontend)
| Page/Component | URL | Checks |
|----------------|-----|--------|
| N/A | N/A | No UI in this task - foundation layer only |

### Database Verification (if applicable)
| Check | Query/Command | Expected |
|-------|---------------|----------|
| Core Data Model | Open Bodii.xcdatamodeld in Xcode | All entities defined with correct attributes |
| Entity Attributes | Inspect each entity | Fields match docs/04_ERD.md types |

### QA Sign-off Requirements
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All E2E tests pass
- [ ] Xcode builds without errors or warnings
- [ ] Code follows established patterns (MARK comments, docstrings)
- [ ] No regressions in existing functionality
- [ ] Documentation inline with code (Korean language)
- [ ] Critical 02:00 sleep boundary logic verified

## Implementation Order

The recommended implementation sequence based on dependencies:

1. **Phase 1: Constants & Enums** (no dependencies)
   - Constants.swift
   - Gender, ActivityLevel, MealType, ExerciseType, Intensity, FoodSource, GoalType, SleepStatus, QuantityUnit

2. **Phase 2: Extensions** (depends on enums)
   - Date+Extensions.swift
   - Decimal+Extensions.swift

3. **Phase 3: Utilities** (depends on Constants, Extensions)
   - DateUtils.swift
   - ValidationService.swift
   - Formatters.swift

4. **Phase 4: Domain Entities** (depends on Enums, Utilities)
   - User, BodyRecord, MetabolismSnapshot
   - Food, FoodRecord
   - ExerciseRecord, SleepRecord
   - DailyLog, Goal

5. **Phase 5: Core Data Model** (depends on Domain Entities)
   - Bodii.xcdatamodeld entities

6. **Phase 6: Unit Tests** (parallel with implementation)
   - DateUtilsTests.swift
   - ValidationServiceTests.swift
   - SleepStatusTests.swift

## Critical Business Rules Reference

### Sleep Boundary (02:00)
```
00:00 ~ 01:59 → Previous day (for sleep tracking)
02:00 ~ 23:59 → Current day
```

### Sleep Status Thresholds (minutes)
```
< 330 (< 5.5h)     → Bad 🔴
330-389 (5.5-6.5h) → Soso 🟡
390-449 (6.5-7.5h) → Good 🟢
450-540 (7.5-9h)   → Excellent 🔵
> 540 (> 9h)       → Oversleep 🟠
```

### Activity Level Multipliers
```
1: Sedentary    → 1.2
2: Light        → 1.375
3: Moderate     → 1.55
4: Active       → 1.725
5: Very Active  → 1.9
```

### BMR Formulas
```
With body fat %: Katch-McArdle
  LBM = weight × (1 - bodyFatPct/100)
  BMR = 370 + (21.6 × LBM)

Without body fat %: Mifflin-St Jeor
  Male: BMR = 10 × weight + 6.25 × height - 5 × age + 5
  Female: BMR = 10 × weight + 6.25 × height - 5 × age - 161
```

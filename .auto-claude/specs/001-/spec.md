# Specification: Xcode Project Initial Setup (Bodii iOS App)

## Overview

This task establishes the foundational Xcode project for Bodii, a health and fitness iOS application that tracks body composition, diet, exercise, and sleep. The setup includes creating a SwiftUI-based iOS 17+ project with Clean Architecture folder structure and Core Data model configuration. This is a greenfield project setup that will serve as the scaffold for all future feature development.

## Workflow Type

**Type**: feature

**Rationale**: This is a new feature implementation task that creates the initial project structure from scratch. Although it's primarily scaffolding, it establishes critical architectural decisions (Clean Architecture, Core Data model) that affect all future development.

## Task Scope

### Services Involved
- **Bodii** (primary) - iOS application with Clean Architecture

### This Task Will:
- [ ] Create new Xcode project with SwiftUI App lifecycle
- [ ] Configure project settings (iOS 17+, Bundle ID: com.seungming.bodii)
- [ ] Create Clean Architecture folder structure (App, Domain, Data, Presentation, Core)
- [ ] Generate Core Data model file (Bodii.xcdatamodeld) with entity definitions from ERD
- [ ] Set up initial placeholder files for each architectural layer

### Out of Scope:
- Full entity implementation (only Core Data model schema)
- UI implementation (only placeholder views)
- Business logic implementation (only folder structure)
- Repository implementations
- API integrations
- HealthKit integration
- Unit tests (will be added in subsequent tasks)

## Service Context

### Bodii iOS App

**Tech Stack:**
- Language: Swift 5.9+
- Framework: SwiftUI
- UI Target: iOS 17.0+
- Data Persistence: Core Data
- Architecture: MVVM + Clean Architecture Hybrid
- Key directories: App/, Domain/, Data/, Presentation/, Core/

**Entry Point:** `Bodii/App/BodiiApp.swift`

**How to Run:**
```bash
# Open in Xcode
open Bodii.xcodeproj

# Build and Run
# Use Xcode: Cmd + R
# Or via xcodebuild:
xcodebuild -project Bodii.xcodeproj -scheme Bodii -destination 'platform=iOS Simulator,name=iPhone 15' build
```

**Port:** N/A (iOS App)

## Files to Create

| File | Directory | Purpose |
|------|-----------|---------|
| `Bodii.xcodeproj` | Root | Xcode project file |
| `BodiiApp.swift` | App/ | Application entry point |
| `ContentView.swift` | App/ | Root view (tab bar) |
| `DIContainer.swift` | App/ | Dependency injection container |
| `Bodii.xcdatamodeld` | Infrastructure/Persistence/ | Core Data model |
| `PersistenceController.swift` | Infrastructure/Persistence/ | Core Data stack manager |

### Folder Structure to Create

```
Bodii/
├── App/
│   ├── BodiiApp.swift
│   ├── ContentView.swift
│   └── DIContainer.swift
│
├── Presentation/
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   ├── Dashboard/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   ├── Body/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   ├── Diet/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   ├── Exercise/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   ├── Sleep/
│   │   │   ├── Views/
│   │   │   └── ViewModels/
│   │   └── Settings/
│   │       ├── Views/
│   │       └── ViewModels/
│   └── Components/
│       ├── Charts/
│       ├── Cards/
│       └── Common/
│
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Interfaces/
│
├── Data/
│   ├── Repositories/
│   ├── DataSources/
│   │   ├── Local/
│   │   │   └── Entities/
│   │   └── Remote/
│   ├── DTOs/
│   └── Mappers/
│
├── Infrastructure/
│   ├── Network/
│   ├── HealthKit/
│   └── Persistence/
│       └── Bodii.xcdatamodeld
│
├── Shared/
│   ├── Extensions/
│   ├── Utils/
│   └── Enums/
│
└── Resources/
    └── Assets.xcassets
```

## Files to Reference

These documentation files provide patterns and requirements:

| File | Pattern to Copy |
|------|----------------|
| `docs/06_DEVELOPMENT_GUIDE.md` | Architecture patterns, folder structure, coding conventions, file structure templates |
| `docs/04_ERD.md` | Core Data entity definitions, relationships, data types, indexes |

## Patterns to Follow

### Clean Architecture Layer Pattern

From `docs/06_DEVELOPMENT_GUIDE.md`:

```
Presentation → Domain ← Data
                 ↑
            Infrastructure
```

**Key Points:**
- Presentation layer depends only on Domain
- Data layer implements Domain protocols
- Domain layer has NO external dependencies (pure Swift)
- Infrastructure provides framework-specific implementations

### File Structure Pattern

From `docs/06_DEVELOPMENT_GUIDE.md`:

```swift
// MARK: - [Section Name]

import Foundation
import SwiftUI

// MARK: - Protocol (if applicable)

protocol SomeProtocol {
    // ...
}

// MARK: - Main Type

final class SomeClass {

    // MARK: - Properties

    private let dependency: SomeDependency
    @Published var state: State

    // MARK: - Initialization

    init(dependency: SomeDependency) {
        self.dependency = dependency
    }

    // MARK: - Public Methods

    func doSomething() {
        // ...
    }

    // MARK: - Private Methods

    private func helper() {
        // ...
    }
}

// MARK: - Extensions

extension SomeClass: SomeProtocol {
    // ...
}

// MARK: - Preview (SwiftUI)

#Preview {
    SomeView()
}
```

**Key Points:**
- Use MARK comments for section organization
- Follow UpperCamelCase for types, lowerCamelCase for variables/functions
- Use `final class` when inheritance is not needed
- Keep protocols separate from implementations

### Core Data Entity Pattern

From `docs/04_ERD.md`, entities to create:

| Entity | Primary Key | Key Attributes |
|--------|-------------|----------------|
| User | id: UUID | name, gender, birthDate, height, activityLevel, current* fields |
| BodyRecord | id: UUID | userId (FK), date, weight, bodyFatMass, bodyFatPercent, muscleMass |
| MetabolismSnapshot | id: UUID | userId (FK), bodyRecordId (FK), bmr, tdee, activityLevel |
| Food | id: UUID | name, calories, carbs, protein, fat, servingSize, source |
| FoodRecord | id: UUID | userId (FK), foodId (FK), date, mealType, quantity, calculated* |
| ExerciseRecord | id: UUID | userId (FK), date, exerciseType, duration, intensity, caloriesBurned |
| SleepRecord | id: UUID | userId (FK), date, duration, status |
| DailyLog | id: UUID | userId (FK), date (UNIQUE), totals*, bmr, tdee, netCalories |
| Goal | id: UUID | userId (FK), goalType, target*, weekly*Rate, start*, isActive |

## Requirements

### Functional Requirements

1. **Xcode Project Creation**
   - Description: Create new iOS project with SwiftUI lifecycle
   - Acceptance: Project opens in Xcode without errors, builds successfully for iOS Simulator

2. **Project Configuration**
   - Description: Configure bundle ID, deployment target, and build settings
   - Acceptance: Bundle ID is `com.seungming.bodii`, minimum iOS 17.0, SwiftUI App lifecycle

3. **Folder Structure**
   - Description: Create Clean Architecture folder hierarchy
   - Acceptance: All folders from structure diagram exist with correct naming

4. **Core Data Model**
   - Description: Create xcdatamodeld file with all entities from ERD
   - Acceptance: Bodii.xcdatamodeld contains all 9 entities with correct attributes and relationships

5. **Entry Point Files**
   - Description: Create minimal App entry point and ContentView
   - Acceptance: BodiiApp.swift and ContentView.swift compile and run showing placeholder UI

### Edge Cases

1. **Xcode Version Compatibility** - Ensure project format supports Xcode 15+
2. **Core Data Migration** - Use automatic lightweight migration for future schema changes
3. **Simulator Target** - Ensure project runs on both iPhone and iPad simulators

## Implementation Notes

### DO
- Follow the exact folder structure from `docs/06_DEVELOPMENT_GUIDE.md`
- Use UUID for all entity primary keys (as specified in ERD)
- Use Int16 for enum-backed attributes (gender, mealType, status, etc.)
- Use Decimal for numeric values requiring precision (weight, percentages)
- Add indexes as specified in ERD for frequently queried columns
- Configure relationships with proper delete rules
- Use `@main` attribute for SwiftUI App entry point
- Include `.gitkeep` files in empty folders to preserve structure in Git

### DON'T
- Create UIKit files or storyboards (except LaunchScreen if needed)
- Implement actual business logic (only placeholders)
- Add third-party dependencies yet
- Create unit tests (separate task)
- Set up CI/CD pipelines (separate task)

## Development Environment

### Prerequisites

```bash
# Required
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS Simulator 17.0+
```

### Project Creation Commands

```bash
# Option 1: Create via Xcode UI
# File > New > Project > iOS App
# - Product Name: Bodii
# - Interface: SwiftUI
# - Language: Swift
# - Storage: Core Data (checked)
# - Include Tests: No (add later)

# Option 2: Alternative - scaffold structure manually after Xcode creation
mkdir -p Bodii/{App,Presentation/{Features/{Onboarding,Dashboard,Body,Diet,Exercise,Sleep,Settings}/{Views,ViewModels},Components/{Charts,Cards,Common}},Domain/{Entities,UseCases,Interfaces},Data/{Repositories,DataSources/{Local/Entities,Remote},DTOs,Mappers},Infrastructure/{Network,HealthKit,Persistence},Shared/{Extensions,Utils,Enums},Resources}
```

### Service URLs
- N/A (iOS application - no web URLs)

### Required Environment Variables
- None required for initial setup
- Future: API keys will be stored in `Resources/Config.plist`

## Success Criteria

The task is complete when:

1. [ ] Xcode project `Bodii.xcodeproj` exists and opens without errors
2. [ ] Project builds successfully for iOS Simulator (iPhone 15)
3. [ ] Bundle identifier is set to `com.seungming.bodii`
4. [ ] Minimum deployment target is iOS 17.0
5. [ ] All Clean Architecture folders exist as specified
6. [ ] `Bodii.xcdatamodeld` contains all 9 entities from ERD
7. [ ] Core Data entities have correct attributes and types
8. [ ] Core Data relationships are properly configured
9. [ ] `BodiiApp.swift` runs and displays ContentView
10. [ ] No console errors or warnings on launch
11. [ ] Git repository initialized with `.gitignore` for Xcode

## QA Acceptance Criteria

**CRITICAL**: These criteria must be verified by the QA Agent before sign-off.

### Unit Tests
| Test | File | What to Verify |
|------|------|----------------|
| N/A | - | No unit tests in this scaffolding task |

### Integration Tests
| Test | Services | What to Verify |
|------|----------|----------------|
| Core Data Stack | PersistenceController | Container loads without errors |

### End-to-End Tests
| Flow | Steps | Expected Outcome |
|------|-------|------------------|
| App Launch | 1. Open project in Xcode 2. Build and Run on Simulator | App launches, shows ContentView |
| Core Data | 1. Inspect xcdatamodeld 2. Verify all entities | 9 entities with correct attributes |

### Build Verification
| Check | Command | Expected |
|-------|---------|----------|
| Build Success | `xcodebuild -project Bodii.xcodeproj -scheme Bodii build` | Build Succeeded |
| Simulator Launch | Run on iPhone 15 Simulator | App launches without crash |

### Project Configuration Verification
| Check | Location | Expected |
|-------|----------|----------|
| Bundle ID | Project Settings > General | `com.seungming.bodii` |
| iOS Target | Project Settings > General | iOS 17.0+ |
| Swift Version | Build Settings | Swift 5 |
| UI Framework | Info.plist / Project | SwiftUI App |

### Core Data Model Verification
| Entity | Required Attributes | Required Relationships |
|--------|---------------------|----------------------|
| User | id, name, gender, birthDate, height, activityLevel, current* | bodyRecords, foodRecords, etc. |
| BodyRecord | id, userId, date, weight | user, metabolismSnapshot |
| MetabolismSnapshot | id, userId, bodyRecordId, bmr, tdee | user, bodyRecord |
| Food | id, name, calories, carbs, protein, fat | foodRecords |
| FoodRecord | id, userId, foodId, date, mealType | user, food |
| ExerciseRecord | id, userId, date, exerciseType, duration | user |
| SleepRecord | id, userId, date, duration, status | user |
| DailyLog | id, userId, date, totals*, bmr, tdee | user |
| Goal | id, userId, goalType, target*, isActive | user |

### Folder Structure Verification
| Path | Must Exist |
|------|------------|
| `Bodii/App/` | Yes |
| `Bodii/Presentation/Features/` | Yes |
| `Bodii/Presentation/Components/` | Yes |
| `Bodii/Domain/Entities/` | Yes |
| `Bodii/Domain/UseCases/` | Yes |
| `Bodii/Domain/Interfaces/` | Yes |
| `Bodii/Data/Repositories/` | Yes |
| `Bodii/Data/DataSources/Local/` | Yes |
| `Bodii/Infrastructure/Persistence/` | Yes |
| `Bodii/Shared/Extensions/` | Yes |
| `Bodii/Resources/` | Yes |

### QA Sign-off Requirements
- [ ] Project builds without errors
- [ ] Project builds without warnings (or only expected warnings)
- [ ] App launches on iOS Simulator
- [ ] All 9 Core Data entities exist with correct schema
- [ ] All Clean Architecture folders created
- [ ] Entry point files (BodiiApp.swift, ContentView.swift) functional
- [ ] Bundle ID correctly configured
- [ ] iOS 17+ deployment target set
- [ ] No regressions (N/A - new project)
- [ ] Code follows established patterns from development guide

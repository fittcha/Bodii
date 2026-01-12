# Project Foundation & Core Data Model

Set up Xcode project with SwiftUI, MVVM architecture, Core Data persistence layer with 9 entities (User, BodyRecord, MetabolismSnapshot, Food, FoodRecord, ExerciseRecord, SleepRecord, DailyLog, Goal), and utility services for date handling and input validation.

## Rationale
Essential infrastructure for all other features. Core Data provides reliable local storage addressing competitor pain points of app crashes and data loss (InBody, Noom, MyFitnessPal data corruption incidents). Local-first approach ensures privacy and reliability.

## User Stories
- As a developer, I want a well-structured project so that I can build features efficiently
- As a user, I want my data stored locally so that it's always available even offline

## Acceptance Criteria
- [ ] Xcode project created with iOS 17+ target and SwiftUI lifecycle
- [ ] Core Data model implements all 9 entities from ERD
- [ ] MVVM folder structure established (Views, ViewModels, Models, Services, Utils)
- [ ] PersistenceController manages Core Data stack with save/fetch operations
- [ ] DateUtils handles 02:00 sleep boundary logic correctly
- [ ] ValidationService validates all input ranges (height 100-250cm, weight 20-300kg, etc.)

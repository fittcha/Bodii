# QA Fix Request

**Status**: REJECTED ❌
**Date**: 2026-01-14T13:00:00Z
**QA Session**: 1

---

## Summary

The exercise tracking feature has **excellent implementation** of individual components but is **not functional** due to missing UI integration. All 23 subtasks were marked "completed," but critical wiring is missing between components.

**Impact**: Users cannot add, edit, or delete exercises. The feature shows only an empty list.

---

## Critical Issues to Fix

### 1. ❌ ExerciseInputView Not Integrated (BLOCKER)

**Problem**: Add exercise modal shows placeholder text instead of actual form

**Location**: `Bodii/Presentation/Features/Exercise/Views/ExerciseListView.swift:73-76`

**Current Code**:
```swift
.sheet(isPresented: $isShowingAddSheet) {
    // TODO: ExerciseInputView 구현 후 추가
    Text("운동 추가 화면 (Phase 4)")
}
```

**Required Fix**:
```swift
.sheet(isPresented: $isShowingAddSheet) {
    ExerciseInputView(
        viewModel: DIContainer.shared.makeExerciseInputViewModel(
            userId: viewModel.userId,  // Add userId getter to ExerciseListViewModel
            userWeight: userWeight ?? 70.0,
            userBMR: userBMR ?? 1650,
            userTDEE: userTDEE ?? 2310
        ),
        onSaveSuccess: {
            isShowingAddSheet = false
            Task {
                await viewModel.refresh()
            }
        }
    )
}
```

**Additional Changes**:
1. Add user data properties to `ExerciseListView`:
   ```swift
   @State private var userWeight: Decimal = 70.0  // TODO: Fetch from User entity
   @State private var userBMR: Int32 = 1650
   @State private var userTDEE: Int32 = 2310
   ```

2. Add public getter to `ExerciseListViewModel`:
   ```swift
   var userId: UUID { self.userId }  // Expose private userId
   ```

3. Add `refresh()` method to `ExerciseListViewModel` if not exists:
   ```swift
   @MainActor
   func refresh() async {
       await loadData()
   }
   ```

**Verification**:
- [ ] Tap + button → ExerciseInputView modal appears (not placeholder)
- [ ] Select exercise → Duration → Intensity → See calorie preview
- [ ] Tap Save → Exercise appears in list
- [ ] Daily summary updates (calories, minutes, count)

---

### 2. ❌ Delete Functionality Not Integrated (BLOCKER)

**Problem**: Delete callback just prints to console, doesn't actually delete

**Location**: `Bodii/Presentation/Features/Exercise/Views/ExerciseListView.swift:161-164`

**Current Code**:
```swift
onDelete: {
    // TODO: DeleteExerciseRecordUseCase 연동 (Phase 5)
    print("Delete exercise: \(exercise.id)")
}
```

**Required Fix (3 files)**:

**File 1: ExerciseListViewModel.swift**
```swift
// Add property
private let deleteExerciseRecordUseCase: DeleteExerciseRecordUseCase

// Update init
init(
    getExerciseRecordsUseCase: GetExerciseRecordsUseCase,
    deleteExerciseRecordUseCase: DeleteExerciseRecordUseCase,  // ← ADD THIS
    dailyLogRepository: DailyLogRepository,
    userId: UUID,
    selectedDate: Date = Date()
) {
    self.getExerciseRecordsUseCase = getExerciseRecordsUseCase
    self.deleteExerciseRecordUseCase = deleteExerciseRecordUseCase  // ← ADD THIS
    self.dailyLogRepository = dailyLogRepository
    self.userId = userId
    self.selectedDate = selectedDate
}

// Add delete method
@MainActor
func deleteExercise(id: UUID) async {
    do {
        try await deleteExerciseRecordUseCase.execute(
            recordId: id,
            userId: userId
        )
        // Reload data to reflect deletion
        await loadData()
    } catch {
        errorMessage = "운동 기록 삭제 실패: \(error.localizedDescription)"
    }
}
```

**File 2: DIContainer.swift**
```swift
func makeExerciseListViewModel(userId: UUID) -> ExerciseListViewModel {
    ExerciseListViewModel(
        getExerciseRecordsUseCase: getExerciseRecordsUseCase,
        deleteExerciseRecordUseCase: deleteExerciseRecordUseCase,  // ← ADD THIS
        dailyLogRepository: dailyLogRepository,
        userId: userId
    )
}
```

**File 3: ExerciseListView.swift**
```swift
onDelete: {
    Task {
        await viewModel.deleteExercise(id: exercise.id)
    }
}
```

**Verification**:
- [ ] Swipe left on exercise → Delete button appears
- [ ] Tap delete → Exercise removed from list
- [ ] Daily summary decreases (calories, minutes, count)
- [ ] DailyLog updated correctly in database

---

### 3. ❌ UpdateExerciseRecordUseCase Never Used (BLOCKER)

**Problem**: Edit functionality is completely missing - no way to update existing exercises

**Location**: `UpdateExerciseRecordUseCase.swift` exists but is never imported or used anywhere

**Required Fix (3 files)**:

**File 1: ExerciseListViewModel.swift**
```swift
// Add property
private let updateExerciseRecordUseCase: UpdateExerciseRecordUseCase

// Update init to include update use case
init(
    getExerciseRecordsUseCase: GetExerciseRecordsUseCase,
    deleteExerciseRecordUseCase: DeleteExerciseRecordUseCase,
    updateExerciseRecordUseCase: UpdateExerciseRecordUseCase,  // ← ADD THIS
    dailyLogRepository: DailyLogRepository,
    userId: UUID,
    selectedDate: Date = Date()
) {
    // ... assign all properties
}
```

**File 2: ExerciseListView.swift**
```swift
// Add state for edit
@State private var isShowingEditSheet = false
@State private var selectedExercise: ExerciseRecord?

// Add tap gesture to exercise cards
ForEach(viewModel.exerciseRecords) { exercise in
    ExerciseCardView(
        exercise: exercise,
        onDelete: { ... }
    )
    .onTapGesture {
        selectedExercise = exercise
        isShowingEditSheet = true
    }
}

// Add edit sheet
.sheet(isPresented: $isShowingEditSheet) {
    if let exercise = selectedExercise {
        ExerciseInputView(
            viewModel: DIContainer.shared.makeExerciseInputViewModel(
                userId: viewModel.userId,
                userWeight: userWeight,
                userBMR: userBMR,
                userTDEE: userTDEE,
                editingExercise: exercise  // ← Pass exercise for edit mode
            ),
            onSaveSuccess: {
                isShowingEditSheet = false
                Task { await viewModel.refresh() }
            }
        )
    }
}
```

**File 3: ExerciseInputViewModel.swift**
```swift
// Add property
private let updateExerciseRecordUseCase: UpdateExerciseRecordUseCase?
private let editingExercise: ExerciseRecord?

// Update init
init(
    addExerciseRecordUseCase: AddExerciseRecordUseCase,
    updateExerciseRecordUseCase: UpdateExerciseRecordUseCase? = nil,  // ← ADD THIS
    userId: UUID,
    userWeight: Decimal,
    userBMR: Int32,
    userTDEE: Int32,
    editingExercise: ExerciseRecord? = nil  // ← ADD THIS
) {
    self.addExerciseRecordUseCase = addExerciseRecordUseCase
    self.updateExerciseRecordUseCase = updateExerciseRecordUseCase  // ← ADD THIS
    self.editingExercise = editingExercise  // ← ADD THIS
    // ... other assignments

    // Pre-fill form if editing
    if let exercise = editingExercise {
        self.selectedExerciseType = exercise.exerciseType
        self.duration = exercise.duration
        self.selectedIntensity = exercise.intensity
        self.note = exercise.note ?? ""
        self.selectedDate = exercise.date
    }
}

// Update save method
func save() async {
    guard isFormValid else { return }

    isSaving = true
    defer { isSaving = false }

    do {
        if let editingExercise = editingExercise,
           let updateUseCase = updateExerciseRecordUseCase {
            // UPDATE EXISTING EXERCISE
            let updated = try await updateUseCase.execute(
                recordId: editingExercise.id,
                userId: userId,
                date: selectedDate,
                exerciseType: selectedExerciseType,
                duration: duration,
                intensity: selectedIntensity,
                note: note.isEmpty ? nil : note,
                userWeight: userWeight,
                userBMR: userBMR,
                userTDEE: userTDEE
            )
        } else {
            // ADD NEW EXERCISE
            let record = try await addExerciseRecordUseCase.execute(
                userId: userId,
                date: selectedDate,
                exerciseType: selectedExerciseType,
                duration: duration,
                intensity: selectedIntensity,
                note: note.isEmpty ? nil : note,
                userWeight: userWeight,
                userBMR: userBMR,
                userTDEE: userTDEE
            )
        }
        isSaveSuccess = true
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

**File 4: DIContainer.swift**
```swift
// Update factory method
func makeExerciseInputViewModel(
    userId: UUID,
    userWeight: Decimal,
    userBMR: Int32,
    userTDEE: Int32,
    editingExercise: ExerciseRecord? = nil  // ← ADD THIS
) -> ExerciseInputViewModel {
    ExerciseInputViewModel(
        addExerciseRecordUseCase: addExerciseRecordUseCase,
        updateExerciseRecordUseCase: editingExercise != nil ? updateExerciseRecordUseCase : nil,  // ← ADD THIS
        userId: userId,
        userWeight: userWeight,
        userBMR: userBMR,
        userTDEE: userTDEE,
        editingExercise: editingExercise  // ← ADD THIS
    )
}
```

**Verification**:
- [ ] Tap exercise card → Edit modal appears
- [ ] Form pre-filled with existing data
- [ ] Change duration → Calorie preview updates
- [ ] Save → Exercise updates in list
- [ ] Daily summary reflects new values (difference applied)

---

### 4. ⚠️ Add Delete Confirmation Dialog (UX IMPROVEMENT)

**Problem**: Swipe-to-delete immediately removes exercise without confirmation

**Location**: `ExerciseListView.swift` delete callback

**Required Fix**:
```swift
// Add state
@State private var exerciseToDelete: ExerciseRecord?

// Update delete callback
onDelete: {
    exerciseToDelete = exercise
}

// Add confirmation alert
.alert("운동 기록 삭제", isPresented: .constant(exerciseToDelete != nil)) {
    Button("취소", role: .cancel) {
        exerciseToDelete = nil
    }
    Button("삭제", role: .destructive) {
        if let exercise = exerciseToDelete {
            Task {
                await viewModel.deleteExercise(id: exercise.id)
                exerciseToDelete = nil
            }
        }
    }
} message: {
    if let exercise = exerciseToDelete {
        Text("\(exercise.exerciseType.displayName) 기록을 삭제하시겠습니까?")
    }
}
```

**Verification**:
- [ ] Swipe left → Tap delete → Confirmation dialog appears
- [ ] Tap cancel → Exercise not deleted
- [ ] Tap delete → Exercise deleted

---

### 5. ⚠️ Add Error Handling and Loading States (UX IMPROVEMENT)

**Problem**: No visual feedback during operations, no error handling for failures

**Required Fix in ExerciseListViewModel**:
```swift
// Add loading state for delete
var isDeletingId: UUID?

// Update delete method
@MainActor
func deleteExercise(id: UUID) async {
    isDeletingId = id
    defer { isDeletingId = nil }

    do {
        try await deleteExerciseRecordUseCase.execute(
            recordId: id,
            userId: userId
        )
        await loadData()
    } catch {
        errorMessage = "운동 기록 삭제 실패: \(error.localizedDescription)"
    }
}
```

**Required Fix in ExerciseListView**:
```swift
// Show loading indicator on card being deleted
ExerciseCardView(
    exercise: exercise,
    onDelete: { ... }
)
.opacity(viewModel.isDeletingId == exercise.id ? 0.5 : 1.0)
.overlay {
    if viewModel.isDeletingId == exercise.id {
        ProgressView()
    }
}
```

**Verification**:
- [ ] During delete → Card shows loading indicator
- [ ] On delete failure → Error alert appears
- [ ] On save failure → Error alert appears

---

## After Fixes

Once fixes are complete:

1. **Commit Changes**:
   ```bash
   git add .
   git commit -m "fix: Integrate ExerciseInputView and delete functionality (qa-requested)"
   ```

2. **Self-Test Checklist**:
   - [ ] Add exercise flow works end-to-end
   - [ ] Delete exercise flow works end-to-end
   - [ ] Edit exercise flow works end-to-end
   - [ ] Daily summary updates correctly
   - [ ] Error handling works
   - [ ] No console errors or warnings

3. **QA Will Re-run**:
   - All critical fixes must be verified working
   - Feature must be fully functional
   - No new issues introduced

---

## Priority

**CRITICAL** - Feature is non-functional without these fixes

**Estimated Time**: 2-4 hours

**Order of Fixes**:
1. Fix #2 (Delete) - Simplest, proves integration pattern
2. Fix #1 (Add) - Makes feature usable
3. Fix #3 (Edit) - Completes CRUD operations
4. Fix #4 & #5 (UX) - Polish and error handling

---

## Questions?

If anything is unclear:
1. Check QA report for detailed context: `qa_report.md`
2. Review existing implementations:
   - `AddExerciseRecordUseCase.swift` - Shows how to structure use case calls
   - `DailyLogService.swift` - Shows how repositories are used
   - `ExerciseInputViewModel.swift` - Shows form state management

The backend is solid. Just need to wire the UI! 🔌

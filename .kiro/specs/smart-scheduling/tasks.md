# Implementation Plan: Smart Scheduling

## Overview

Implementasi fitur Smart Scheduling pada aplikasi Tugasku menggunakan Flutter/Dart. Fitur ini menambahkan backward scheduling dari deadline, strict monotasking enforcement, conflict resolution berbasis SAW Score, visualisasi time block 24 jam, dan AI-powered auto task creation. Implementasi mengextend arsitektur existing (TaskProvider, SAWService, SharedPreferences).

## Tasks

- [x] 1. Set up models dan core interfaces
  - [x] 1.1 Create TimeBlock model (`lib/models/time_block_model.dart`)
    - Implement `TimeBlockStatus` enum (active, missed, manuallyMoved)
    - Implement `TimeBlock` class with fields: id, taskId, startTime, endTime, status, isManuallyPlaced
    - Implement `toJson()` and `fromJson()` serialization
    - Implement `copyWith()` method
    - Ensure startTime always on hour boundary and endTime = startTime + 1 hour
    - _Requirements: 1.2, 1.4, 9.1_

  - [x] 1.2 Create ScheduleConfig model (`lib/models/schedule_config_model.dart`)
    - Implement `ScheduleConfig` class with workStartHour, workStartMinute, workEndHour, workEndMinute
    - Implement `isWithinWorkHours(DateTime slotStart)` supporting cross-midnight (e.g., 22:00–06:00)
    - Implement `isCrossMidnight` getter
    - Implement `toJson()` and `fromJson()` serialization
    - Default values: 08:00–17:00
    - _Requirements: 6.1_

  - [x] 1.3 Create ScheduleResult, ScheduleConflict, and ScheduleWarning classes (`lib/models/schedule_result_model.dart`)
    - Implement `ScheduleResult` with fields: timeBlocks, conflicts, warnings
    - Implement `ScheduleConflict` with fields: slotTime, taskIds, winnerId, sawScores
    - Implement `ScheduleWarning` with fields: taskId, message, type
    - Implement `WarningType` enum (insufficientSlots, pastDeadline, unschedulable)
    - _Requirements: 1.5, 1.6, 3.2, 4.5_

  - [x] 1.4 Write property tests for TimeBlock and ScheduleConfig models
    - **Property 2: TimeBlock Duration Invariant** — verify duration is exactly 1 hour and startTime on hour boundary
    - **Property 7: Primary Work Hours Cross-Midnight Correctness** — verify isWithinWorkHours for all configurations including cross-midnight
    - **Property 14: Schedule Serialization Round Trip** — verify toJson/fromJson produces equivalent objects
    - **Validates: Requirements 1.2, 1.4, 6.1, 9.1, 9.6**

- [x] 2. Implement Smart Scheduler Service core algorithm
  - [x] 2.1 Create SmartSchedulerService (`lib/services/smart_scheduler_service.dart`) with slot utilities
    - Implement `getAvailableSlots()` — returns available hour-aligned slots between `from` and `until`, excluding occupied slots, prioritizing PWH slots first
    - Implement `validateNoOverlaps()` — checks no two TimeBlocks share the same slot
    - _Requirements: 1.1, 2.1, 6.2_

  - [x] 2.2 Implement backward scheduling algorithm
    - Implement `backwardSchedule()` method
    - Calculate slots backward from deadline, prioritizing Primary Work Hours slots
    - Fill non-PWH slots only after PWH slots are exhausted
    - Emit warning if insufficient slots available
    - Reject scheduling if deadline is in the past
    - Ensure no block is allocated before current time
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 1.6, 1.7, 6.2, 6.3_

  - [x] 2.3 Implement conflict detection
    - Implement `detectConflicts()` method
    - Identify all slots where multiple TimeBlocks overlap
    - Return list of ScheduleConflict with competing task IDs and SAW scores
    - _Requirements: 3.1, 3.2_

  - [x] 2.4 Implement conflict resolution with recursive shift
    - Implement `resolveConflicts()` method
    - Higher SAW Score wins the slot; tiebreaker: earliest deadline, then earliest createdAt
    - Losers shifted backward (Recursive_Shift) to next available slot
    - Mark task as unschedulable if no slot found
    - Loop until no conflicts remain
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 2.5 Implement `rescheduleAll()` main entry point
    - Sort tasks by SAW Score descending
    - Preserve manually placed blocks (isManuallyPlaced=true)
    - Run backward scheduling for each task
    - Detect and resolve conflicts
    - Validate no overlaps in final result
    - Return ScheduleResult with blocks, conflicts, and warnings
    - _Requirements: 7.5, 8.1, 8.2, 8.3_

  - [x] 2.6 Write property tests for backward scheduling
    - **Property 3: Backward Scheduling Respects Deadline** — all blocks before deadline and after current time
    - **Property 6: Primary Work Hours Preference Ordering** — PWH slots filled before non-PWH
    - **Property 8: Partial Scheduling Maximizes Allocation** — allocates min(estimation, availableSlots) blocks
    - **Validates: Requirements 1.1, 1.3, 1.4, 1.5, 1.7, 6.2, 6.3, 6.4**

  - [x] 2.7 Write property tests for conflict resolution
    - **Property 1: Strict Monotasking Invariant (No Overlaps)** — no two blocks share a slot after resolution
    - **Property 4: Conflict Resolution Priority Ordering** — higher SAW wins, tiebreaker by deadline then createdAt
    - **Property 5: Recursive Shift Produces Valid Placement** — losers shifted to valid earlier slot or marked unschedulable
    - **Validates: Requirements 2.1, 2.3, 4.2, 4.3, 4.4, 4.5, 4.6, 8.1, 8.5**

- [x] 3. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Extend TaskProvider with scheduling capabilities
  - [x] 4.1 Add scheduling fields and getters to TaskProvider
    - Add `_timeBlocks`, `_scheduleConfig`, `_scheduler` fields
    - Add getters: `timeBlocks`, `scheduleConfig`, `getTimeBlocksForDate(date)`, `getTimeBlocksForTask(taskId)`
    - _Requirements: 5.1, 9.2_

  - [x] 4.2 Implement `_runScheduler()` method
    - Called after SAW recalculation completes
    - Waits for all SAW scores to be available before scheduling
    - Calls `rescheduleAll()` with current tasks and manual blocks
    - Updates `_timeBlocks` and calls `notifyListeners()`
    - Handles SAW Service failure gracefully (retain last valid schedule)
    - _Requirements: 8.2, 8.6, 8.7_

  - [x] 4.3 Implement manual block management methods
    - `moveTimeBlock(blockId, newSlot)` — validate target slot empty and before deadline, update block
    - `deleteTimeBlock(blockId)` — confirm and free slot
    - Handle task completion: remove all related TimeBlocks
    - Handle task edit: recalculate blocks for edited task only, preserve other manual blocks
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x] 4.4 Implement schedule persistence methods
    - `_saveSchedule()` — serialize timeBlocks and scheduleConfig to SharedPreferences as JSON
    - `_loadSchedule()` — deserialize on app start, handle corrupt data gracefully (empty schedule)
    - `updateScheduleConfig(config)` — save new config and trigger reschedule
    - Mark missed blocks on load (endTime < now and task not complete)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

  - [x] 4.5 Write property tests for TaskProvider scheduling integration
    - **Property 9: Manual Block Preservation on Reschedule** — manually placed blocks of other tasks unchanged after reschedule
    - **Property 10: Move Validation** — move to empty slot succeeds, occupied/past-deadline rejected
    - **Property 11: Task Completion Cleanup** — all blocks removed when task marked complete
    - **Property 12: Missed Block Detection** — past blocks of incomplete tasks marked as missed
    - **Property 13: Estimation Change Reallocates Without SAW Modification** — old blocks removed, new allocated, SAW unchanged
    - **Validates: Requirements 7.1, 7.2, 7.3, 7.5, 7.6, 8.4, 9.4**

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement Schedule View UI
  - [x] 6.1 Create ScheduleScreen with 24-hour timeline (`lib/screens/schedule_screen.dart`)
    - Build 24-hour vertical timeline (00:00–23:59) with 1-hour granularity
    - Display TimeBlocks with task name, start/end time
    - Show empty state message when no blocks scheduled for the day
    - Implement day navigation via horizontal swipe and date navigation buttons
    - _Requirements: 5.1, 5.6, 5.7_

  - [x] 6.2 Implement visual styling and indicators
    - Color-code TimeBlocks by task category (kuliah, praktikum, project, lainnya)
    - Visual distinction for PWH vs non-PWH slots (dimmer background for non-PWH)
    - Visual distinction for active vs missed blocks (dimmed/strikethrough for missed)
    - Show empty slot, filled slot, and PWH indicators simultaneously distinguishable
    - Current time indicator (horizontal line) updated every 60 seconds
    - _Requirements: 5.2, 5.4, 5.5, 6.5, 9.5_

  - [x] 6.3 Implement TimeBlock interaction
    - Tap on TimeBlock shows detail: task name, mata kuliah, deadline, remaining unscheduled hours
    - Drag-and-drop to move TimeBlock to different slot
    - Show error messages for invalid moves (occupied slot, past deadline)
    - Delete TimeBlock with confirmation dialog
    - _Requirements: 5.3, 7.1, 7.2, 7.3, 7.4_

  - [x] 6.4 Implement conflict notification UI
    - Display notification within 2 seconds of conflict detection
    - Show conflicting task names, slot time, SAW scores
    - Show recommendation (winner and shifted tasks)
    - Update notification with resolution result (new slot allocations)
    - _Requirements: 3.2, 3.3, 3.4, 3.5_

  - [x] 6.5 Write unit tests for Schedule View
    - Test timeline renders 24 slots correctly
    - Test category color mapping consistency
    - Test empty state display
    - Test day navigation
    - Test current time indicator positioning
    - _Requirements: 5.1, 5.2, 5.6, 5.7_

- [x] 7. Implement Primary Work Hours settings UI
  - [x] 7.1 Create settings screen for Primary Work Hours (`lib/screens/schedule_settings_screen.dart`)
    - Time picker for work start and work end hours
    - Support cross-midnight configuration (e.g., 22:00–06:00)
    - Minimum 1-hour range validation
    - Save triggers reschedule of all active tasks
    - _Requirements: 6.1, 6.6_

  - [x] 7.2 Write unit tests for Primary Work Hours settings
    - Test default values (08:00–17:00)
    - Test cross-midnight configuration saves correctly
    - Test minimum range validation
    - _Requirements: 6.1_

- [x] 8. Implement AI Task Creator
  - [x] 8.1 Create AITaskCreatorService (`lib/services/ai_task_creator_service.dart`)
    - Implement `extractTasks(String inputText)` method
    - Return list of `TaskSuggestion` with: namaTugas, deadline, estimasiWaktu, tingkatKepentingan, tingkatUrgensi
    - Handle timeout (30 seconds max)
    - Handle extraction failure gracefully
    - _Requirements: 10.2, 10.6_

  - [x] 8.2 Create TaskSuggestion model and AI Task Creator UI (`lib/screens/ai_task_creator_screen.dart`)
    - Text input field with 50–10,000 character validation
    - Disable process button when input < 50 characters with hint message
    - Loading indicator during AI processing
    - Preview list of suggested tasks with edit/delete/confirm per task
    - On confirm: save tasks, trigger SAW + Smart Scheduler pipeline
    - Maximum 50 tasks per extraction
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

  - [x] 8.3 Write unit tests for AI Task Creator
    - Test input validation (< 50 chars disabled)
    - Test timeout handling (30 seconds)
    - Test extraction failure error message
    - Test max 50 tasks limit
    - _Requirements: 10.6, 10.7_

- [x] 9. Integration and wiring
  - [x] 9.1 Wire scheduling into existing task CRUD flow
    - Hook `_runScheduler()` into `tambahTugas()`, `editTugas()`, `hapusTugas()`, `tandaiSelesai()` methods
    - Ensure SAW recalculation completes before scheduling starts
    - Ensure scheduling completes within 3 seconds of SAW completion
    - _Requirements: 8.2, 8.7_

  - [x] 9.2 Add Schedule View navigation to app
    - Add navigation entry point to ScheduleScreen from main app
    - Ensure schedule data loads on app startup (within 3 seconds)
    - Handle corrupt data gracefully on startup
    - _Requirements: 9.2, 9.3_

  - [x] 9.3 Write integration tests
    - Test full flow: add task → SAW calculation → scheduling → persistence → reload
    - Test SAW recalculation triggers rescheduling within 3 seconds
    - Test AI task creation → confirmation → SAW + scheduling pipeline
    - Test SharedPreferences read/write cycle for schedule data
    - _Requirements: 8.2, 9.1, 9.2, 10.5_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document (14 properties)
- Unit tests validate specific examples and edge cases
- The project uses Dart/Flutter with Provider state management and SharedPreferences for persistence
- AI Task Creator (Requirement 10) is an optional feature — can be deferred if needed
- All scheduling logic is in SmartSchedulerService (pure logic, easily testable), while TaskProvider handles state and persistence

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["1.4", "2.1"] },
    { "id": 2, "tasks": ["2.2", "2.3"] },
    { "id": 3, "tasks": ["2.4"] },
    { "id": 4, "tasks": ["2.5"] },
    { "id": 5, "tasks": ["2.6", "2.7"] },
    { "id": 6, "tasks": ["4.1"] },
    { "id": 7, "tasks": ["4.2", "4.3", "4.4"] },
    { "id": 8, "tasks": ["4.5"] },
    { "id": 9, "tasks": ["6.1", "7.1", "8.1"] },
    { "id": 10, "tasks": ["6.2", "6.3", "6.4", "7.2", "8.2"] },
    { "id": 11, "tasks": ["6.5", "8.3"] },
    { "id": 12, "tasks": ["9.1", "9.2"] },
    { "id": 13, "tasks": ["9.3"] }
  ]
}
```

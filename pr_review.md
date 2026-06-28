# Code Review - PR #4: Bug Fixes Implementation

## ✅ Overall Assessment
Good work on implementing the bug fixes! The code addresses the critical issues identified in issue #3. However, there are some improvements needed for production readiness.

---

## 🔴 Critical Issues

### 1. Race Condition in Dialog State Management
**Location:** `add_edit_task_screen.dart` line 257-324

**Problem:**
```dart
bool _isAddingScope = false;  // This is outside the class!

Future<void> _showAddScopeDialog(TaskProvider provider) async {
  // ...
  finally {
    if (dialogContext.mounted) {
      Future.microtask(() {
        if (mounted) {
          setState(() => _isAddingScope = false);
        }
      });
    }
  }
}
```

**Issues:**
1. `_isAddingScope` is declared **outside the class** - this should be a class member variable
2. Using `Future.microtask` in finally block is overly complex and can cause race conditions
3. Reset at the end of method (`_isAddingScope = false;`) might execute before the microtask

**Recommended Fix:**
```dart
// Inside _AddEditTaskScreenState class
bool _isAddingScope = false;
bool _isAddingCategory = false;

Future<void> _showAddScopeDialog(TaskProvider provider) async {
  if (_isAddingScope) return; // Prevent double-tap
  
  final ctrl = TextEditingController();
  
  try {
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismiss while loading
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          // ... existing code ...
          onPressed: _isAddingScope
              ? null
              : () async {
                  if (ctrl.text.trim().isEmpty) return;
                  
                  setState(() => _isAddingScope = true);
                  setDialogState(() {});
                  
                  try {
                    await provider.addScope(ctrl.text.trim());
                    
                    if (mounted) {
                      setState(() {
                        _lingkupTugas = ctrl.text.trim();
                        _isAddingScope = false;
                      });
                    }
                    
                    if (c.mounted) Navigator.pop(c);
                  } catch (e) {
                    setState(() => _isAddingScope = false);
                    if (c.mounted) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
        ),
      ),
    );
  } finally {
    ctrl.dispose();
    if (mounted && _isAddingScope) {
      setState(() => _isAddingScope = false);
    }
  }
}
```

---

## 🟡 Important Improvements

### 2. Deprecated API Usage
**Location:** `add_edit_task_screen.dart` line 340

**Problem:**
```dart
DropdownButtonFormField<String>(
  value: validCategory,  // ⚠️ 'value' is deprecated
  // ...
)
```

**Fix:**
```dart
DropdownButtonFormField<String>(
  initialValue: validCategory,
  // ...
)
```

### 3. Inefficient Block Filtering
**Location:** `schedule_screen.dart` line 283-290

**Problem:**
```dart
// This cleanup runs on EVERY build, can be expensive
final invalidBlocks = blocks.where((b) => !validBlocks.contains(b)).toList();
for (final invalid in invalidBlocks) {
  provider.deleteTimeBlock(invalid.id);  // Multiple provider calls in build!
}
```

**Issues:**
- Calling `provider.deleteTimeBlock()` inside build method violates Flutter best practices
- This triggers `notifyListeners()` which causes rebuild loop
- O(n²) complexity with nested loops

**Recommended Fix:**
```dart
Widget _buildDayTimeline(DateTime date) {
  return Consumer<TaskProvider>(
    builder: (context, provider, _) {
      final blocks = provider.getTimeBlocksForDate(date);
      final config = provider.scheduleConfig;

      if (blocks.isEmpty) {
        return _buildEmptyState();
      }

      // Bug #4 Fix: Filter blocks dengan valid task
      final validBlocks = blocks.where((block) {
        return provider.tasks.any((t) => t.id == block.taskId);
      }).toList();
      
      // Cleanup invalid blocks OUTSIDE build, using post-frame callback
      final invalidBlocks = blocks.where((b) => !validBlocks.contains(b)).toList();
      if (invalidBlocks.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final invalid in invalidBlocks) {
            provider.deleteTimeBlock(invalid.id);
          }
        });
      }
      
      if (validBlocks.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        // ... rest of code
      );
    },
  );
}
```

---

## 🟢 Nice to Have

### 4. Add Logging for Debugging
**Location:** `task_provider.dart` line 251-299

**Suggestion:**
```dart
Future<void> _loadTasks() async {
  final prefs = await SharedPreferences.getInstance();
  
  try {
    final String? tasksJson = prefs.getString(_storageKey);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((t) => Task.fromJson(t)).toList();
      _recalculateSAW();
      await _runScheduler();
      notifyListeners();
      debugPrint('✅ Loaded ${_tasks.length} tasks successfully');
      return;
    }
  } catch (e) {
    debugPrint('❌ Failed to load tasks: $e');
    debugPrint('   Trying backup...');
    
    try {
      final String? backupJson = prefs.getString('${_storageKey}_backup');
      if (backupJson != null) {
        final List<dynamic> decoded = jsonDecode(backupJson);
        _tasks = decoded.map((t) => Task.fromJson(t)).toList();
        _recalculateSAW();
        await _runScheduler();
        notifyListeners();
        debugPrint('✅ Loaded ${_tasks.length} tasks from backup');
        return;
      }
    } catch (backupError) {
      debugPrint('❌ Backup also failed: $backupError');
    }
  }
  
  _tasks = [];
  debugPrint('⚠️ Starting with empty task list');
  notifyListeners();
}
```

### 5. Timer Optimization
**Location:** `schedule_screen.dart` line 75-88

**Suggestion:**
Update timer only to next minute boundary instead of every 60 seconds:
```dart
void _startCurrentTimeTimer() {
  _currentTimeTimer?.cancel();
  
  // Calculate delay to next minute
  final now = DateTime.now();
  final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
  final delayToNextMinute = nextMinute.difference(now);
  
  // First timer to sync to minute boundary
  Timer(delayToNextMinute, () {
    if (mounted) {
      setState(() => _currentTime = DateTime.now());
      
      // Then periodic timer every 60 seconds
      _currentTimeTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) {
          setState(() => _currentTime = DateTime.now());
        }
      });
    }
  });
}
```

---

## 📊 Testing Recommendations

Before merging, please test:

### Critical Tests:
- [ ] Add 10+ scopes/categories rapidly (test race condition)
- [ ] Kill app during save operation (test backup mechanism)
- [ ] Delete task with existing schedule blocks (test cleanup)
- [ ] Switch between schedule screens 20+ times (test timer cleanup)

### Edge Cases:
- [ ] Fill device storage completely
- [ ] Corrupt SharedPreferences manually
- [ ] Create 1000+ notifications (test ID collision)
- [ ] Delete all categories while editing task

---

## 🎯 Summary

**Priority 1 (Must Fix Before Merge):**
1. Fix `_isAddingScope` variable placement and race condition
2. Move `deleteTimeBlock` calls outside build method
3. Replace deprecated `value` with `initialValue`

**Priority 2 (Should Fix):**
4. Add comprehensive logging
5. Optimize timer to minute boundaries

**Priority 3 (Nice to Have):**
6. Add unit tests for critical paths
7. Add integration tests for async operations

---

## Approval Status: ⏸️ Changes Requested

Great start on the bug fixes! Please address the Critical Issues (#1 and #3) before merging. The Important Improvements (#2) should also be fixed to avoid future deprecation warnings.

Once these are addressed, this PR will be ready to merge! 🚀

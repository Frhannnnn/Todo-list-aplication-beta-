// lib/services/ai_task_creator_service.dart

/// Model representing a task suggestion extracted from text input.
class TaskSuggestion {
  final String namaTugas;
  final DateTime? deadline;
  final int estimasiWaktu; // hours (1-10)
  final int tingkatKepentingan; // 1-5
  final int tingkatUrgensi; // 1-5
  bool isSelected; // For user confirmation UI

  TaskSuggestion({
    required this.namaTugas,
    this.deadline,
    required this.estimasiWaktu,
    required this.tingkatKepentingan,
    required this.tingkatUrgensi,
    this.isSelected = true,
  });
}

/// Exception thrown when AI task extraction fails.
class AIExtractionException implements Exception {
  final String message;
  final AIExtractionFailureReason reason;

  AIExtractionException({
    required this.message,
    required this.reason,
  });

  @override
  String toString() => 'AIExtractionException: $message';
}

/// Reasons for AI extraction failure.
enum AIExtractionFailureReason {
  timeout,
  inputTooShort,
  inputTooLong,
  extractionFailed,
}

/// Service for extracting tasks from text input using AI-powered analysis.
///
/// Currently implements a simple text parser that splits input by newlines
/// and treats each non-empty line as a potential task. The actual AI integration
/// can be swapped in later by replacing the internal extraction logic.
class AITaskCreatorService {
  /// Maximum number of tasks that can be extracted per input.
  static const int maxTasksPerExtraction = 50;

  /// Minimum input text length in characters.
  static const int minInputLength = 50;

  /// Maximum input text length in characters.
  static const int maxInputLength = 10000;

  /// Timeout duration for extraction processing.
  static const Duration extractionTimeout = Duration(seconds: 30);

  /// Extract tasks from text input (syllabus, project brief, task list).
  ///
  /// Takes [inputText] with length between 50 and 10,000 characters.
  /// Returns a list of [TaskSuggestion] with a maximum of 50 items.
  ///
  /// Throws [AIExtractionException] if:
  /// - Input is too short (< 50 characters)
  /// - Input is too long (> 10,000 characters)
  /// - Extraction times out (> 30 seconds)
  /// - Extraction fails for other reasons
  Future<List<TaskSuggestion>> extractTasks(String inputText) async {
    // Validate input length
    if (inputText.length < minInputLength) {
      throw AIExtractionException(
        message:
            'Input terlalu pendek untuk diekstrak (minimum $minInputLength karakter)',
        reason: AIExtractionFailureReason.inputTooShort,
      );
    }

    if (inputText.length > maxInputLength) {
      throw AIExtractionException(
        message:
            'Input terlalu panjang (maksimum $maxInputLength karakter)',
        reason: AIExtractionFailureReason.inputTooLong,
      );
    }

    try {
      final result = await _performExtraction(inputText)
          .timeout(extractionTimeout);
      return result;
    } on AIExtractionException {
      rethrow;
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw AIExtractionException(
          message:
              'Ekstraksi gagal — proses melebihi batas waktu 30 detik. Coba perjelas input atau buat tugas manual.',
          reason: AIExtractionFailureReason.timeout,
        );
      }
      throw AIExtractionException(
        message:
            'Ekstraksi gagal — input tidak dapat diproses. Coba perjelas input atau buat tugas manual.',
        reason: AIExtractionFailureReason.extractionFailed,
      );
    }
  }

  /// Internal extraction logic.
  ///
  /// Currently implements a simple text parser. This method can be replaced
  /// with actual AI API integration in the future.
  Future<List<TaskSuggestion>> _performExtraction(String inputText) async {
    // Simulate async processing (represents future AI API call)
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final lines = inputText.split('\n');
    final List<TaskSuggestion> suggestions = [];

    for (final line in lines) {
      if (suggestions.length >= maxTasksPerExtraction) break;

      final trimmed = _cleanLine(line);
      if (trimmed.isEmpty) continue;

      suggestions.add(_parseLine(trimmed));
    }

    if (suggestions.isEmpty) {
      throw AIExtractionException(
        message:
            'Tidak ada tugas yang dapat diekstrak dari input. Coba perjelas input atau buat tugas manual.',
        reason: AIExtractionFailureReason.extractionFailed,
      );
    }

    return suggestions;
  }

  /// Clean a line by removing common list prefixes and whitespace.
  String _cleanLine(String line) {
    String cleaned = line.trim();

    // Remove common list markers: "- ", "* ", "• ", "1. ", "1) ", etc.
    cleaned = cleaned.replaceFirst(RegExp(r'^[-*•]\s+'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');

    return cleaned.trim();
  }

  /// Parse a single line into a TaskSuggestion with default values.
  ///
  /// Assigns reasonable defaults for deadline, estimation, importance, and urgency.
  /// A future AI implementation would extract these from context.
  TaskSuggestion _parseLine(String taskName) {
    // Estimate importance and urgency based on simple heuristics
    final int kepentingan = _estimateKepentingan(taskName);
    final int urgensi = _estimateUrgensi(taskName);
    final int estimasi = _estimateWaktu(taskName);

    return TaskSuggestion(
      namaTugas: taskName,
      deadline: null, // No deadline inference in simple parser
      estimasiWaktu: estimasi,
      tingkatKepentingan: kepentingan,
      tingkatUrgensi: urgensi,
    );
  }

  /// Estimate importance level (1-5) based on keywords.
  int _estimateKepentingan(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('uts') ||
        lower.contains('uas') ||
        lower.contains('ujian') ||
        lower.contains('final')) {
      return 5;
    }
    if (lower.contains('tugas besar') ||
        lower.contains('project') ||
        lower.contains('proyek')) {
      return 4;
    }
    if (lower.contains('quiz') ||
        lower.contains('kuis') ||
        lower.contains('presentasi')) {
      return 3;
    }
    return 3; // Default middle importance
  }

  /// Estimate urgency level (1-5) based on keywords.
  int _estimateUrgensi(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('besok') ||
        lower.contains('hari ini') ||
        lower.contains('segera')) {
      return 5;
    }
    if (lower.contains('minggu ini') || lower.contains('deadline')) {
      return 4;
    }
    return 3; // Default middle urgency
  }

  /// Estimate time needed (1-10 hours) based on keywords.
  int _estimateWaktu(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('tugas besar') ||
        lower.contains('project') ||
        lower.contains('proyek') ||
        lower.contains('makalah')) {
      return 5;
    }
    if (lower.contains('laporan') || lower.contains('presentasi')) {
      return 3;
    }
    if (lower.contains('quiz') || lower.contains('kuis')) {
      return 1;
    }
    return 2; // Default estimation
  }
}

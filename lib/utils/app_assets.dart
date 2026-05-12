import '../models/task_model.dart';

class AppAssets {
  static const logo = 'assets/images/logo.png';
  static const emptyTasks = 'assets/images/empty_tasks.png';
  static const emptyCalendar = 'assets/images/empty_calendar.png';
  static const emptyPriority = 'assets/images/empty_priority.png';

  static const categoryKuliah = 'assets/icons/category_kuliah.png';
  static const categoryPraktikum = 'assets/icons/category_praktikum.png';
  static const categoryProject = 'assets/icons/category_project.png';
  static const categoryLainnya = 'assets/icons/category_lainnya.png';

  static String categoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.kuliah:
        return categoryKuliah;
      case TaskCategory.praktikum:
        return categoryPraktikum;
      case TaskCategory.project:
        return categoryProject;
      case TaskCategory.lainnya:
        return categoryLainnya;
    }
  }

  static String categoryLabel(TaskCategory category) {
    switch (category) {
      case TaskCategory.kuliah:
        return 'Kuliah';
      case TaskCategory.praktikum:
        return 'Praktikum';
      case TaskCategory.project:
        return 'Project';
      case TaskCategory.lainnya:
        return 'Lainnya';
    }
  }
}

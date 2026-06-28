class AppAssets {
  static const logo = 'assets/images/logo.png';
  static const emptyTasks = 'assets/images/empty_tasks.png';
  static const emptyCalendar = 'assets/images/empty_calendar.png';
  static const emptyPriority = 'assets/images/empty_priority.png';

  static const categoryKuliah = 'assets/icons/category_kuliah.png';
  static const categoryPraktikum = 'assets/icons/category_praktikum.png';
  static const categoryProject = 'assets/icons/category_project.png';
  static const categoryLainnya = 'assets/icons/category_lainnya.png';

  /// Mengembalikan icon path berdasarkan nama kategori (String-based).
  static String categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kuliah':
        return categoryKuliah;
      case 'praktikum':
        return categoryPraktikum;
      case 'proyek':
      case 'project':
        return categoryProject;
      default:
        return categoryLainnya;
    }
  }
}

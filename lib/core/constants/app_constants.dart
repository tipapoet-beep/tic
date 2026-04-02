class AppConstants {
  static const String appName = 'Фитнес Экосистема';
  static const String appVersion = '1.0.0';
  
  // Ключи для Hive
  static const String workoutsBox = 'workouts_box';
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  
  // Настройки уведомлений
  static const int notificationChannelId = 1;
  static const String notificationChannelName = 'Фитнес напоминания';
  static const String notificationChannelDescription = 'Напоминания о тренировках';
  
  // Тайминги
  static const int splashDuration = 2;
  static const int workoutRestDefault = 60; // секунд
  static const int notificationTimeout = 5; // секунд
  
  // Лимиты
  static const int maxWorkoutTitleLength = 100;
  static const int maxExerciseNameLength = 50;
  static const int maxSetsPerExercise = 10;
  static const int maxRepsPerSet = 100;
  static const int maxWeight = 500; // кг
  
  // Пути к ассетам
  static const String logoPath = 'assets/images/logo.png';
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  
  // API Endpoints (если используете прямой HTTP)
  static const String baseUrl = 'https://your-api.com/api';
  static const String workoutsEndpoint = '$baseUrl/workouts';
  static const String exercisesEndpoint = '$baseUrl/exercises';
  static const String progressEndpoint = '$baseUrl/progress';
  
  // Сообщения об ошибках
  static const String networkError = 'Ошибка сети. Проверьте подключение к интернету';
  static const String serverError = 'Ошибка сервера. Попробуйте позже';
  static const String authError = 'Ошибка авторизации';
  static const String unknownError = 'Неизвестная ошибка';
  static const String validationError = 'Проверьте введенные данные';
}

class SharedPrefsKeys {
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String firstLaunch = 'first_launch';
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
}
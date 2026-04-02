class Logger {
  static void log(String message) {
    // В разработке оставляем print
    // В продакшене можно отключить
    // ignore: avoid_print
    print(message);
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    // ignore: avoid_print
    print('❌ $message');
    if (error != null) {
      // ignore: avoid_print
      print('Error details: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
    }
  }
  
  static void success(String message) {
    // ignore: avoid_print
    print('✅ $message');
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Форматирование даты
  static String formatDate(DateTime date, {String pattern = 'dd.MM.yyyy'}) {
    return DateFormat(pattern).format(date);
  }
  
  static String formatTime(DateTime time, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern).format(time);
  }
  
  // Форматирование времени тренировки
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
  
  // Конвертация веса
  static String formatWeight(double weight) {
    return '${weight.toStringAsFixed(1)} кг';
  }
  
  // Показ SnackBar
  static void showSnackBar(BuildContext context, String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  // Валидация email
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }
  
  // Валидация пароля (мин 6 символов)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  // Расчет прогресса
  static double calculateProgress(int current, int total) {
    if (total == 0) return 0;
    return current / total;
  }
  
  // Получение дня недели
  static String getWeekdayName(DateTime date) {
    final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[date.weekday - 1];
  }
  
  // Форматирование числа с суффиксом
  static String formatWithSuffix(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Класс для логирования
class Logger {
  static void log(String message, {String tag = 'DEBUG'}) {
    debugPrint('[$tag] $message');
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('❌ [ERROR] $message');
    if (error != null) debugPrint('Error details: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }
  
  static void success(String message) {
    debugPrint('✅ [SUCCESS] $message');
  }
  
  static void warning(String message) {
    debugPrint('⚠️ [WARNING] $message');
  }
}
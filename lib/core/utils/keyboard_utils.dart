import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardUtils {
  /// Скрыть клавиатуру
  static void dismiss(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  /// Показать клавиатуру
  static void show(BuildContext context, FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
  }
  
  /// Добавить слушатель изменения высоты клавиатуры
  static void addKeyboardListener({
    required BuildContext context,
    required VoidCallback onKeyboardShow,
    required VoidCallback onKeyboardHide,
  }) {
    // Используем WidgetsBinding для отслеживания изменений
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialBottom = MediaQuery.of(context).viewInsets.bottom;
      
      // Создаём слушатель через ValueNotifier
      final listener = ValueNotifier<double>(initialBottom);
      
      // Используем анимацию для отслеживания изменений
      listener.addListener(() {
        final currentBottom = listener.value;
        if (currentBottom > initialBottom && currentBottom > 100) {
          onKeyboardShow();
        } else if (currentBottom == 0) {
          onKeyboardHide();
        }
      });
      
      // Обновляем значение при изменении
      WidgetsBinding.instance.addPostFrameCallback((_) {
        listener.value = MediaQuery.of(context).viewInsets.bottom;
      });
    });
  }
  
  /// Альтернативный способ - через анимацию
  static void addKeyboardListenerWithAnimation({
    required BuildContext context,
    required VoidCallback onKeyboardShow,
    required VoidCallback onKeyboardHide,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      if (keyboardHeight > 100) {
        onKeyboardShow();
      } else if (keyboardHeight == 0) {
        onKeyboardHide();
      }
    });
  }
  
  /// Обернуть виджет в GestureDetector для скрытия клавиатуры
  static Widget wrapWithDismissGesture({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        }
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
  
  /// Получить высоту клавиатуры
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
  
  /// Проверить, открыта ли клавиатура
  static bool isKeyboardOpen(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 100;
  }
  
  /// Добавить слушатель фокуса для поля ввода
  static void addFocusListener({
    required FocusNode focusNode,
    required VoidCallback onFocus,
    required VoidCallback onUnfocus,
  }) {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        onFocus();
      } else {
        onUnfocus();
      }
    });
  }
  
  /// Автоматический скролл к полю ввода
  static void scrollToField({
    required ScrollController scrollController,
    required BuildContext context,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        );
      }
    });
  }
}
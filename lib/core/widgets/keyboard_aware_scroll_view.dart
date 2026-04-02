import 'package:flutter/material.dart';

/// Виджет, который автоматически подстраивается под клавиатуру
class KeyboardAwareScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final ScrollController? controller;
  final bool reverse;
  final bool isDismissible;
  
  const KeyboardAwareScrollView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.reverse = false,
    this.isDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Скрываем клавиатуру при тапе вне полей ввода
      onTap: isDismissible ? () => _dismissKeyboard(context) : null,
      child: SingleChildScrollView(
        controller: controller,
        reverse: reverse,
        padding: padding,
        child: child,
      ),
    );
  }

  void _dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
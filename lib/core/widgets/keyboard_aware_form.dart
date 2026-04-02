import 'package:flutter/material.dart';

/// Форма с автоматической подстройкой под клавиатуру
class KeyboardAwareForm extends StatefulWidget {
  final Widget child;
  final GlobalKey<FormState>? formKey;
  final EdgeInsets padding;
  final bool isDismissible;
  
  const KeyboardAwareForm({
    super.key,
    required this.child,
    this.formKey,
    this.padding = const EdgeInsets.all(16),
    this.isDismissible = true,
  });

  @override
  State<KeyboardAwareForm> createState() => _KeyboardAwareFormState();
}

class _KeyboardAwareFormState extends State<KeyboardAwareForm> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isDismissible ? _dismissKeyboard : null,
      child: SingleChildScrollView(
        padding: widget.padding,
        child: Form(
          key: widget.formKey,
          child: widget.child,
        ),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
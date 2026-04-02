import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;
  
  const LoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Кастомный индикатор с жёлтым цветом
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                message!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    
    if (fullScreen) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: content,
      );
    }
    
    return content;
  }
}
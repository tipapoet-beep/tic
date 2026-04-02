import 'package:flutter/material.dart';

/// Элегантный фон (только градиент, без текстуры)
class PremiumBackground extends StatelessWidget {
  final Widget child;
  final Color startColor;
  final Color endColor;
  
  const PremiumBackground({
    super.key,
    required this.child,
    this.startColor = const Color(0xFF0F1115),
    this.endColor = const Color(0xFF1A1D24),
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [startColor, endColor],
        ),
      ),
      child: child,
    );
  }
}

/// Элегантная карточка
class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final BorderRadius? borderRadius;
  
  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevation = 2,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1D24),
            const Color(0xFF22262F),
          ],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}
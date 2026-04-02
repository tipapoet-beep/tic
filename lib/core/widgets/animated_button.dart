import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double? height;
  final Color? color;
  
  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = 54,
    this.color,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> 
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !widget.isLoading;
    
    Widget button;
    
    if (widget.isOutlined) {
      button = OutlinedButton(
        onPressed: isEnabled ? widget.onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.color ?? theme.primaryColor,
          side: BorderSide(color: widget.color ?? theme.primaryColor),
          minimumSize: Size(widget.width ?? double.infinity, widget.height!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(),
      );
    } else {
      button = ElevatedButton(
        onPressed: isEnabled ? widget.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color ?? theme.primaryColor,
          foregroundColor: Colors.black,
          minimumSize: Size(widget.width ?? double.infinity, widget.height!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(),
      );
    }
    
    if (widget.width == null) {
      return button;
    }
    
    return Center(child: SizedBox(width: widget.width, child: button));
  }
  
  Widget _buildChild() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    return widget.child;
  }
}
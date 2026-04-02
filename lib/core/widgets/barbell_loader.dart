import 'package:flutter/material.dart';

class BarbellLoader extends StatefulWidget {
  final VoidCallback? onCycleComplete;
  
  const BarbellLoader({super.key, this.onCycleComplete});

  @override
  State<BarbellLoader> createState() => _BarbellLoaderState();
}

class _BarbellLoaderState extends State<BarbellLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPlateIndex = 0;
  final int _totalPlatesPerSide = 3;
  String _loadingMessage = 'Подготовка штанги...';
  
  final List<String> _messages = [
    'Подготовка штанги...',
    'Надеваем первый диск...',
    'Надеваем второй диск...',
    'Надеваем третий диск...',
    'Загружаем приложение...',
  ];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _startLoadingCycle();
  }
  
  void _startLoadingCycle() {
    _currentPlateIndex = 0;
    _updateMessage();
    
    // Анимация добавления дисков
    Future<void> addPlates() async {
      for (int i = 1; i <= _totalPlatesPerSide; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _currentPlateIndex = i;
            _updateMessage();
          });
          // Анимация появления диска
          _controller.forward(from: 0.0);
        }
      }
      
      // Пауза перед сбросом
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        // Сброс и повтор
        setState(() {
          _currentPlateIndex = 0;
          _updateMessage();
        });
        _startLoadingCycle();
        if (widget.onCycleComplete != null) {
          widget.onCycleComplete!();
        }
      }
    }
    
    addPlates();
  }
  
  void _updateMessage() {
    setState(() {
      if (_currentPlateIndex == 0) {
        _loadingMessage = _messages[0];
      } else if (_currentPlateIndex == 1) {
        _loadingMessage = _messages[1];
      } else if (_currentPlateIndex == 2) {
        _loadingMessage = _messages[2];
      } else if (_currentPlateIndex == 3) {
        _loadingMessage = _messages[3];
      } else {
        _loadingMessage = _messages[4];
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 200),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: CustomPaint(
                      size: const Size(280, 120),
                      painter: BarbellPainter(
                        plateCount: _currentPlateIndex,
                        animationValue: _controller.value,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _loadingMessage,
              key: ValueKey(_loadingMessage),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarbellPainter extends CustomPainter {
  final int plateCount;
  final double animationValue;
  
  BarbellPainter({
    required this.plateCount,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Цвета (стиль приложения)
    final barColor = const Color(0xFF2C2C2C);
    final plateColor = Colors.green;
    final plateDarkColor = const Color(0xFF388E3C);
    final endColor = const Color(0xFF1A1D24);
    final shadowColor = Colors.black.withOpacity(0.3);
    
    // Тень грифа
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    // Гриф штанги
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    
    final barRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width * 0.85,
      height: size.height * 0.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(10)),
      barPaint,
    );
    
    // Блик на грифе
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY - 3),
          width: size.width * 0.85,
          height: size.height * 0.08,
        ),
        const Radius.circular(8),
      ),
      highlightPaint,
    );
    
    // Параметры дисков (от большего к меньшему)
    final plateSizes = [0.28, 0.24, 0.20]; // Относительные размеры
    final plateOffsets = [0.32, 0.38, 0.44]; // Отступы от центра
    
    // Рисуем диски (от большего к меньшему)
    for (int i = 0; i < plateCount && i < plateSizes.length; i++) {
      final plateWidth = size.width * plateSizes[i];
      final plateHeight = size.height * 0.45;
      final offset = size.width * plateOffsets[i];
      final opacity = (i + 1) / plateCount * (0.7 + animationValue * 0.3);
      
      // Основной цвет диска
      final platePaint = Paint()
        ..color = plateColor.withOpacity(opacity.clamp(0.3, 1.0))
        ..style = PaintingStyle.fill;
      
      // Тень диска
      final plateShadowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      // Левая сторона
      final leftRect = Rect.fromCenter(
        center: Offset(centerX - offset, centerY),
        width: plateWidth,
        height: plateHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(leftRect, const Radius.circular(8)),
        platePaint,
      );
      
      // Правая сторона
      final rightRect = Rect.fromCenter(
        center: Offset(centerX + offset, centerY),
        width: plateWidth,
        height: plateHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rightRect, const Radius.circular(8)),
        platePaint,
      );
      
      // Ободок диска (темнее)
      final rimPaint = Paint()
        ..color = plateDarkColor.withOpacity(opacity.clamp(0.5, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(leftRect, const Radius.circular(8)),
        rimPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rightRect, const Radius.circular(8)),
        rimPaint,
      );
      
      // Блик на диске
      final diskHighlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.2 * opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX - offset, centerY - 3),
            width: plateWidth * 0.6,
            height: plateHeight * 0.2,
          ),
          const Radius.circular(4),
        ),
        diskHighlightPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX + offset, centerY - 3),
            width: plateWidth * 0.6,
            height: plateHeight * 0.2,
          ),
          const Radius.circular(4),
        ),
        diskHighlightPaint,
      );
    }
    
    // Замки на концах грифа
    final lockPaint = Paint()
      ..color = endColor
      ..style = PaintingStyle.fill;
    
    // Левый замок
    canvas.drawCircle(
      Offset(centerX - size.width * 0.48, centerY),
      size.width * 0.045,
      lockPaint,
    );
    
    // Правый замок
    canvas.drawCircle(
      Offset(centerX + size.width * 0.48, centerY),
      size.width * 0.045,
      lockPaint,
    );
    
    // Металлический блеск на замках
    final metalPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(centerX - size.width * 0.485, centerY - 2),
      size.width * 0.015,
      metalPaint,
    );
    canvas.drawCircle(
      Offset(centerX + size.width * 0.485, centerY - 2),
      size.width * 0.015,
      metalPaint,
    );
    
    // Анимация "свечения" при добавлении диска
    if (animationValue > 0.5) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.2 * (animationValue - 0.5) * 2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(Offset(centerX, centerY), size.width * 0.3, glowPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant BarbellPainter oldDelegate) {
    return oldDelegate.plateCount != plateCount || 
           oldDelegate.animationValue != animationValue;
  }
}
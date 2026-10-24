import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

enum KumiMood { idle, happy, sleepy }

/// Vector fox mascot. Stand-in for final illustrated assets.
class KumiMascot extends StatefulWidget {
  const KumiMascot({
    super.key,
    this.size = 140,
    this.mood = KumiMood.idle,
    this.onTap,
  });

  final double size;
  final KumiMood mood;
  final VoidCallback? onTap;

  @override
  State<KumiMascot> createState() => _KumiMascotState();
}

class _KumiMascotState extends State<KumiMascot> with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _tapController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _idleController.stop();
    } else if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!MediaQuery.disableAnimationsOf(context)) {
      _tapController.forward(from: 0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget mascot = CustomPaint(
      size: Size.square(widget.size),
      painter: _FoxPainter(mood: widget.mood),
    );

    if (!reduceMotion) {
      mascot = AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          final offset = -4 * _idleController.value;
          return Transform.translate(offset: Offset(0, offset), child: child);
        },
        child: mascot,
      );

      mascot = AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          final t = _tapController.value;
          final scale = 1 + 0.06 * math.sin(t * math.pi);
          return Transform.scale(scale: scale, child: child);
        },
        child: mascot,
      );
    }

    return Semantics(
      label: 'Kumi, ketuk untuk bicara',
      button: true,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: mascot,
        ),
      ),
    );
  }
}

class _FoxPainter extends CustomPainter {
  const _FoxPainter({required this.mood});

  final KumiMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = AppColors.fox;
    final dark = Paint()..color = AppColors.foxDark;
    final cream = Paint()..color = AppColors.foxCream;
    final ink = Paint()..color = AppColors.secondary;

    // Ears
    final leftEar = Path()
      ..moveTo(w * 0.16, h * 0.34)
      ..lineTo(w * 0.28, h * 0.10)
      ..lineTo(w * 0.42, h * 0.30)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.84, h * 0.34)
      ..lineTo(w * 0.72, h * 0.10)
      ..lineTo(w * 0.58, h * 0.30)
      ..close();
    canvas.drawPath(leftEar, body);
    canvas.drawPath(rightEar, body);

    // Head
    final head = Path()
      ..moveTo(w * 0.50, h * 0.92)
      ..cubicTo(w * 0.16, h * 0.74, w * 0.12, h * 0.46, w * 0.22, h * 0.30)
      ..cubicTo(w * 0.32, h * 0.18, w * 0.68, h * 0.18, w * 0.78, h * 0.30)
      ..cubicTo(w * 0.88, h * 0.46, w * 0.84, h * 0.74, w * 0.50, h * 0.92)
      ..close();
    canvas.drawPath(head, body);

    // Muzzle
    final muzzle = Path()
      ..moveTo(w * 0.50, h * 0.92)
      ..cubicTo(w * 0.34, h * 0.80, w * 0.30, h * 0.62, w * 0.36, h * 0.56)
      ..cubicTo(w * 0.42, h * 0.50, w * 0.58, h * 0.50, w * 0.64, h * 0.56)
      ..cubicTo(w * 0.70, h * 0.62, w * 0.66, h * 0.80, w * 0.50, h * 0.92)
      ..close();
    canvas.drawPath(muzzle, cream);

    // Eyes
    if (mood == KumiMood.sleepy) {
      final stroke = Paint()
        ..color = AppColors.secondary
        ..strokeWidth = w * 0.014
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.34, h * 0.46), Offset(w * 0.42, h * 0.46), stroke);
      canvas.drawLine(Offset(w * 0.58, h * 0.46), Offset(w * 0.66, h * 0.46), stroke);
    } else if (mood == KumiMood.happy) {
      final stroke = Paint()
        ..color = AppColors.secondary
        ..strokeWidth = w * 0.016
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.38, h * 0.47), width: w * 0.09, height: h * 0.07),
        math.pi,
        math.pi,
        false,
        stroke,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.62, h * 0.47), width: w * 0.09, height: h * 0.07),
        math.pi,
        math.pi,
        false,
        stroke,
      );
    } else {
      canvas.drawCircle(Offset(w * 0.38, h * 0.46), w * 0.035, ink);
      canvas.drawCircle(Offset(w * 0.62, h * 0.46), w * 0.035, ink);
    }

    // Nose
    final nose = Path()
      ..moveTo(w * 0.46, h * 0.68)
      ..lineTo(w * 0.54, h * 0.68)
      ..lineTo(w * 0.50, h * 0.73)
      ..close();
    canvas.drawPath(nose, dark);

    // Cheeks
    final blush = Paint()..color = AppColors.danger.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(w * 0.30, h * 0.58), w * 0.05, blush);
    canvas.drawCircle(Offset(w * 0.70, h * 0.58), w * 0.05, blush);
  }

  @override
  bool shouldRepaint(covariant _FoxPainter oldDelegate) => oldDelegate.mood != mood;
}

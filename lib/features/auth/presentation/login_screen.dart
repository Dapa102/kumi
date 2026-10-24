import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import 'auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final controller = context.read<AuthController>();
    final success = await controller.signInWithGoogle();
    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.error ?? 'Gagal masuk. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _FoxMark(size: 160),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Halo, aku Kumi!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aku bantu kamu mengatur hari\njadi lebih ringan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: controller.busy ? null : () => _signIn(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surfaceAlt,
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary, width: 1),
                ),
                child: controller.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleGlyph(),
                          SizedBox(width: AppSpacing.md),
                          Text('Lanjutkan dengan Google'),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Dengan masuk, kamu setuju pada Ketentuan Layanan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}

/// Simple vector fox used until final mascot art is available.
class _FoxMark extends StatelessWidget {
  const _FoxMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FoxPainter()),
    );
  }
}

class _FoxPainter extends CustomPainter {
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
    canvas.drawCircle(Offset(w * 0.38, h * 0.46), w * 0.035, ink);
    canvas.drawCircle(Offset(w * 0.62, h * 0.46), w * 0.035, ink);

    // Nose
    final nose = Path()
      ..moveTo(w * 0.46, h * 0.68)
      ..lineTo(w * 0.54, h * 0.68)
      ..lineTo(w * 0.50, h * 0.73)
      ..close();
    canvas.drawPath(nose, dark);

    // Cheeks
    final blush = Paint()..color = AppColors.danger.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(w * 0.30, h * 0.58), w * 0.05, blush);
    canvas.drawCircle(Offset(w * 0.70, h * 0.58), w * 0.05, blush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

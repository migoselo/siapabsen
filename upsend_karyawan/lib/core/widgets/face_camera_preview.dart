import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceCameraPreview extends StatelessWidget {
  final CameraController controller;
  final bool showGuide;

  const FaceCameraPreview({
    super.key,
    required this.controller,
    this.showGuide = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                    controller.value.previewSize?.height ??
                    constraints.maxWidth,
                height:
                    controller.value.previewSize?.width ??
                    constraints.maxHeight,
                child: CameraPreview(controller),
              ),
            );
          },
        ),
        if (showGuide)
          Positioned.fill(child: CustomPaint(painter: _FaceGuidePainter())),
        if (showGuide)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Text(
              'Posisikan wajah di dalam bingkai',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
      ],
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final focusRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.45),
        width: size.width * 0.68,
        height: size.height * 0.7,
      ),
      const Radius.circular(28),
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );
    canvas.drawRRect(
      focusRect,
      Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent,
    );
    canvas.restore();

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(focusRect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

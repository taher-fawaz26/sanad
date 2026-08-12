import 'package:flutter/rendering.dart';

/// Paints the small triangle connecting a [PopupMenu] to its anchor widget.
class TrianglePainter extends CustomPainter {
  /// Creates a triangle painter.
  const TrianglePainter({
    this.isDown = true,
    this.color = const Color.fromARGB(0, 0, 0, 0),
  });

  /// Whether the triangle points down (menu shown below the anchor) or up
  /// (menu shown above the anchor).
  final bool isDown;

  /// Fill color, matching [MenuConfig.backgroundColor].
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isDown) {
      path
        ..moveTo(0, -1)
        ..lineTo(size.width, -1)
        ..lineTo(size.width / 2.0, size.height);
    } else {
      path
        ..moveTo(size.width / 2.0, 0)
        ..lineTo(0, size.height + 1)
        ..lineTo(size.width, size.height + 1);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) =>
      isDown != oldDelegate.isDown || color != oldDelegate.color;
}

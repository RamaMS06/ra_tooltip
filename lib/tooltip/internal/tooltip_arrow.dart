
part of '../tooltip_widget.dart';

enum ArrowDirection { up, down, left, right }

class RAArrowPainter extends CustomPainter {
  const RAArrowPainter({
    required this.color,
    required this.isInverted,
    required this.direction,
  });

  final Color color;
  final bool isInverted;
  final ArrowDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    switch (direction) {
      case ArrowDirection.up:
        path.moveTo(0, 0);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(size.width, 0);
        break;
      case ArrowDirection.down:
        // Rotated to top: Arrow pointing upwards
        path.moveTo(0, size.height);
        path.lineTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        break;
      case ArrowDirection.left:
        path.moveTo(0, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(0, size.height);
        break;
      case ArrowDirection.right:
        path.moveTo(0, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(0, size.height);
        break;
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RAArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isInverted != isInverted ||
        oldDelegate.direction != direction;
  }
}

class RATooltipArrow extends StatelessWidget {
  const RATooltipArrow({
    super.key,
    required this.size,
    required this.color,
    this.isInverted = false,
    this.direction = ArrowDirection.down,
  });

  final Size size;
  final Color color;
  final bool isInverted;
  final ArrowDirection direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: RAArrowPainter(
        color: color,
        isInverted: isInverted,
        direction: direction,
      ),
    );
  }
}


class RATooltipArrowPainter extends CustomPainter {
  RATooltipArrowPainter({
    required this.size,
    required this.color,
    required this.isInverted,
  });
  final Size size;
  final Color color;
  final bool isInverted;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isInverted) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }

    path.close();

    canvas
    ..drawShadow(path, Colors.black12, 4, true)
    ..drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


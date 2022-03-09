import 'dart:math';

import 'package:flutter/material.dart';

//-Clase principal del
// class _BubblePainter extends CustomPainter {

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//     ..color = Colors.blue.shade100;

//     final path = Path()
//     ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12.0)));

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(_BubblePainter oldDelegate) => false;
// }

class BubbleTailToPainter extends CustomPainter {
  static const _radius = Radius.circular(12.0);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue.shade100;

    final rect = Offset.zero & size;

    final startTail = Offset(rect.width, rect.height * 0.75);
    final controlTail = Offset(rect.width, rect.height * 0.9);
    final endTail = Offset(rect.width + 5, rect.height * 0.95);

    final tailRadius = (rect.height - endTail.dy) / 2;
    final tailCenter =  Offset(endTail.dx, endTail.dy + tailRadius);
    final tailRect = Rect.fromCircle(center: tailCenter, radius: tailRadius);

    final path = Path()
    ..addRRect(RRect.fromRectAndCorners(rect, topLeft: _radius, bottomLeft: _radius, topRight: _radius))
    ..moveTo(startTail.dx, startTail.dy)
    ..quadraticBezierTo(controlTail.dx, controlTail.dy, endTail.dx, endTail.dy)
    ..arcTo(tailRect, -pi / 2,   pi, false)
    ..lineTo(rect.width, rect.height);

    canvas.drawPath(path, paint);
    // canvas.drawArc(tailRect, pi / 2, -pi, true, Paint()..color = Colors.red);
    // canvas.drawRect(tailRect, Paint()..color = Colors.green.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(BubbleTailToPainter oldDelegate) => false;
}

class BubbleTailFromPainter extends CustomPainter {
  static const _radius = Radius.circular(12.0);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.grey.shade100;

    final rect = Offset.zero & size;

    final startTail = Offset(0, rect.height * 0.75);
    final controlTail = Offset(0, rect.height * 0.9);
    final endTail = Offset(-5, rect.height * 0.95);

    final tailRadius = (rect.height - endTail.dy) / 2;
    final tailCenter =  Offset(endTail.dx, endTail.dy + tailRadius);
    final tailRect = Rect.fromCircle(center: tailCenter, radius: tailRadius);

    final path = Path()
    ..addRRect(RRect.fromRectAndCorners(rect, topLeft: _radius, bottomRight: _radius, topRight: _radius))
    ..moveTo(startTail.dx, startTail.dy)
    ..quadraticBezierTo(controlTail.dx, controlTail.dy, endTail.dx, endTail.dy)
    ..arcTo(tailRect, -pi / 2, -pi, false)
    ..lineTo(0, rect.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BubbleTailFromPainter oldDelegate) => true;
}

//-Para que el slide no tenga tanto padding a los bordes
// class _CustomTrackShape extends RoundedRectSliderTrackShape {
//   Rect getPreferredRect({
//     required RenderBox parentBox,
//     Offset offset = Offset.zero,
//     required SliderThemeData sliderTheme,
//     bool isEnabled = false,
//     bool isDiscrete = false,
//     }) {
//       final double trackHeight = sliderTheme.trackHeight!;
//       final double trackLeft = offset.dx;
//       final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
//       final double trackWidth = parentBox.size.width;
//       return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
//     }
// }
import 'dart:math';

import 'package:chat_app/models/message.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final Message message;

  const ChatMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool myMessage = message.uid == '1';
    
    return Align(
      alignment: myMessage ? Alignment.centerRight : Alignment.centerLeft,

      // child: CustomPaint(
      //   painter: uid == 'uid1' ? _BubbleTailToPainter() : _BubbleTailFromPainter(),
      //   child: Padding(
      //     padding: const EdgeInsets.all(8.0),
      //     child: Text(text),
      //   ),
      // ),

      child: Container(
        margin: myMessage ? const EdgeInsets.only(left: 50.0) : const EdgeInsets.only(right: 50.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: myMessage ? Colors.blue.shade100 : Colors.black12,
          borderRadius: BorderRadius.circular(12.0)
        ),
        child: Text(message.text),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue;

    final path = Path()
    ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12.0)));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_BubblePainter oldDelegate) => false;
}

class _BubbleTailToPainter extends CustomPainter {
  static const _radius = Radius.circular(12.0);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue;

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
  bool shouldRepaint(_BubbleTailToPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_BubbleTailToPainter oldDelegate) => false;
}

class _BubbleTailFromPainter extends CustomPainter {
  static const _radius = Radius.circular(12.0);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue;

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
  bool shouldRepaint(_BubbleTailFromPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(_BubbleTailFromPainter oldDelegate) => true;
}
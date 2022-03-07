import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math';

import 'package:chat_app/global/enviorement.dart';
import 'package:chat_app/providers/audio_provider.dart';
import 'package:chat_app/models/message.dart';

class ChatMessage extends StatelessWidget {
  final Message message;
  final bool sender;

  const ChatMessage({Key? key, required this.message, required this.sender}) : super(key: key);

  static final _appFolder = Environment().appFolder;

  String get _filePath => sender ? _appFolder.sent.path : _appFolder.received.path;
  String get _fileName => message.image ?? message.audio!;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final player = Provider.of<AudioProvider>(context);

    final isPlaying = player.isPlaying;
    final selectedAudio = player.activeAudio == message.id;

    return Align(
      alignment: sender ? Alignment.centerRight : Alignment.centerLeft,
      child: CustomPaint(
        painter: sender ? _BubbleTailToPainter() : _BubbleTailFromPainter(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Builder(
            builder: (context) {
              if(message.audio != null){
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        onPressed: () async {
                          if(player.firstPlay || !selectedAudio){
                            await player.play('$_filePath/$_fileName', message.id!);
                          } else {
                            await player.toggle();
                          }
                        },
                        icon: !selectedAudio 
                          ? const Icon(Icons.play_arrow)
                          : isPlaying ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    SliderTheme(
                      data: const SliderThemeData(
                        // trackShape: _CustomTrackShape()
                      ),
                      child: Slider.adaptive(
                        max: player.maxDuration,
                        value: selectedAudio ? player.playerTime : 0, 
                        onChanged: (value ) {}
                      ),
                    )
                  ],
                );
              }

              if(message.image != null){
                return SizedBox(
                  width: size.width * 0.5,
                  height: size.height * 0.35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File('$_filePath/$_fileName'),
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              }

              if(message.text != null){
                return Text(message.text!);
              }

              return const SizedBox();
            },
          ),
        ),
      ),
      
      // child: Container(
      //   margin: sender ? const EdgeInsets.only(left: 50.0) : const EdgeInsets.only(right: 50.0),
      //   padding: const EdgeInsets.all(8.0),
      //   decoration: BoxDecoration(
      //     color: sender ? Colors.blue.shade100 : Colors.grey.shade100,
      //     borderRadius: BorderRadius.circular(12.0)
      //   ),
      //   child: Text(message.message),
      // ),
    );
  }
}

class _BubblePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue.shade100;

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
  bool shouldRepaint(_BubbleTailToPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(_BubbleTailToPainter oldDelegate) => false;
}

class _BubbleTailFromPainter extends CustomPainter {
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
  bool shouldRepaint(_BubbleTailFromPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(_BubbleTailFromPainter oldDelegate) => true;
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
    }) {
      final double trackHeight = sliderTheme.trackHeight!;
      final double trackLeft = offset.dx;
      final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
      final double trackWidth = parentBox.size.width;
      return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
    }
}
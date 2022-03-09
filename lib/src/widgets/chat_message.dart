import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../global/globals.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../styles/styles.dart';

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
        painter: sender ? BubbleTailToPainter() : BubbleTailFromPainter(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Builder(
            builder: (context) {
              //--------------------------
              // Audio Message
              //--------------------------
              if(message.audio != null){
                final file = File('$_filePath/$_fileName');

                return !file.existsSync() ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.error_outline, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Audio not found')
                  ],
                ) : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        onPressed: () async {
                          if(player.firstPlay || !selectedAudio){
                            await player.play(file.path, message.id!);
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
                    Slider.adaptive(
                      max: player.maxDuration,
                      value: selectedAudio ? player.playerTime : 0, 
                      onChanged: (value ) {}
                    )
                  ],
                );
              }

              //--------------------------
              // Image Message
              //--------------------------
              if(message.image != null){
                final file = File('$_filePath/$_fileName');

                return SizedBox(
                  width: size.width * 0.5,
                  height: size.height * 0.35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: file.existsSync() 
                      ? Image.file(file, fit: BoxFit.fill)
                      : Image.asset("assets/no-image.jpg", fit: BoxFit.fill)
                  ),
                );
              }

              //--------------------------
              // Text Message
              //--------------------------
              return Text(message.text!);
            },
          ),
        ),
      ),
    );
  }
}
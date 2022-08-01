import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'dart:io';

import '../../global/globals.dart';
import '../../providers/message_provider.dart';
import '../../services/messages_service.dart';
import '../../widgets/chat/chat.dart';

class VideoEditionPage extends StatefulWidget {
  final Uint8List? bytes;
  final File? file;
  final Duration? duration;
  final AssetEntity? asset;

  const VideoEditionPage({
    Key? key, 
    this.bytes,
    this.duration,
    this.file,
    this.asset,
  }) : super(key: key);

  @override
  State<VideoEditionPage> createState() => _VideoEditionPageState();
}

class _VideoEditionPageState extends State<VideoEditionPage> {
  late File _file;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    
    if(widget.file != null){
      _file = widget.file!;
      _duration = widget.duration!;
    } else {
      widget.asset!.file.then((file) {
        _file = file!;
        _duration = widget.asset!.videoDuration;
      });
    }
  }

  Future<void> _sendMessage() async {
    // final ext = _file.path.split('/').last.split('.').last;
    final filename = generateFileName('VIDEO', 'mp4');

    final path = '/${AppFolder.sentDirectory}/$filename';

    _file.copySync(path);

    await VideoThumbnail.thumbnailFile(
      video: path,
      thumbnailPath: AppFolder.thumbnailsDirectory,
      imageFormat: ImageFormat.PNG,
      maxWidth: 600,
      quality: 100
    );

    final chat = context.read<MessageProvider>();

    chat.message["video"] = filename;
    chat.message["duration"] = _duration.inMilliseconds;

    context.read<MessagesService>().sendMessage(chat.message);
    chat.clearMessage();

    int count = 0;
    Navigator.of(context).popUntil((_) => count++ == 2);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final chat = context.read<MessageProvider>();

        if(chat.showEmojis) {
          chat.showEmojis = false;
          chat.notify();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          alignment: Alignment.center,
          children: [
            ///---------------------------------------
            /// VIDEO
            ///---------------------------------------
            MediaVideo(
              file: widget.file,
              bytes: widget.bytes,
              asset: widget.asset,
            ),
            
            ///---------------------------------------
            /// HEADER & FOOTER
            ///---------------------------------------
            Column(
              children: [
                const MediaEditionHeader(
                  title: 'Video Edition',
                ),
                
                const Spacer(),
                
                MediaEditionFooter(
                  hintText: 'Video description',
                  onSend: _sendMessage,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
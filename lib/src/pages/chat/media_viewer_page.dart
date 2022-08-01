import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../../styles/styles.dart';
import '../../widgets/chat/chat.dart';

class MediaViewerPage extends StatefulWidget {
  final String id;
  final ImageProvider<Object> image;
  final Size? size;
  final File? video;
  final int? duration;

  const MediaViewerPage({
    Key? key,
    required this.id,
    required this.image,
    this.size,
    this.video,
    this.duration
  }) : super(key: key);

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  final _positionNotifier = ValueNotifier<Duration>(Duration.zero);

  late double _aspectRatio;

  VideoPlayerController? _videoController;
  
  bool _playing = false;
  bool _seeking = false;

  @override
  void initState() {
    super.initState();

    if(widget.video != null){
      _initVideoPlayer();

      _aspectRatio = widget.size!.aspectRatio;

      if(_aspectRatio > 1){
        _aspectRatio = 1 / _aspectRatio;
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer() async {
    _videoController = VideoPlayerController.file(widget.video!);

    _videoController!.initialize().then((_) {
      setState(() => _playing = true);

      _videoController!.play();

      _videoController!.addListener(() {
        if(!_seeking){
          _positionNotifier.value = _videoController!.value.position;
        }

        if(_videoController!.value.position == _videoController!.value.duration){
          _videoController!.seekTo(Duration.zero);
          setState(() => _playing = false);
        }
      });
    });
  }

  void _toggle() {
    if(_playing){
      _videoController!.pause();
    } else {
      _videoController!.play();
    }

    setState(() => _playing = !_playing);
  }

  /// No se mueve el tiempo real el video, a pesar de esperar el seeking
  void _seekToPosition(double value) {
    final time = (value * widget.duration!).toInt();
    final position = Duration(milliseconds: time);

    _positionNotifier.value = position;

    if(_seeking) return;

    _seeking = true;

    _videoController!.seekTo(position).then((_) => _seeking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        // fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ///---------------------------------------
          /// IMAGE O THUMBNAIL
          ///---------------------------------------
          Center(
            child: Hero(
              tag: widget.id,
              createRectTween: (begin, end) => RectTween(begin: begin, end: end),
              child: Image(image: widget.image),
            ),
          ),

          ///---------------------------------------
          /// VIDEO
          ///---------------------------------------
          if(_videoController != null)
            GestureDetector(
              onTap: _toggle,
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: VideoPlayer(_videoController!)
              )
            ),

          ///---------------------------------------
          /// VIDEO PLAY BUTTON
          ///---------------------------------------
          AnimatedOpacity(
            duration: kThemeAnimationDuration,
            opacity: (_playing || widget.video == null) ? 0.0 : 1.0,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 40)
                ),
              ),
            ),
          ),

          ///---------------------------------------
          /// HEADER
          ///---------------------------------------
          const Align(
            alignment: Alignment.topCenter,
            child: MediaEditionHeader(
              title: 'Image view',
            )
          ),

          ///---------------------------------------
          /// VIDEO SLIDER
          ///---------------------------------------
          if(widget.video != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ValueListenableBuilder<Duration>(
                valueListenable: _positionNotifier,
                builder: (_, position, __) {
                  final value = (position.inMilliseconds / widget.duration!).clamp(0.0, 1.0);

                  return Slider(
                    activeColor: ChatTheme.player,
                    inactiveColor: ChatTheme.player.withOpacity(0.5),
                    value: value,
                    onChangeStart: (_) {
                      _videoController!.pause();
                      setState(() => _playing = false);
                    },
                    onChanged: _seekToPosition,
                    onChangeEnd: (_) {
                      _videoController!.play();
                      setState(() => _playing = true);
                    },
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
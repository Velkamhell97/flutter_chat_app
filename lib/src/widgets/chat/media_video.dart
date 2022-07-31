import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

// import 'package:video_trimmer/video_trimmer.dart';

class MediaVideo extends StatefulWidget {
  final File? file;
  final Uint8List? bytes;
  final AssetEntity? asset;

  const MediaVideo({
    Key? key, 
    this.file,
    this.bytes,
    this.asset,
  }) : super(key: key);

  @override
  State<MediaVideo> createState() => _MediaVideoState();
}

/// Para no perder estados con el pageview (multiple selected)
class _MediaVideoState extends State<MediaVideo> with AutomaticKeepAliveClientMixin {
  late ImageProvider _thumbnail;
  late double _aspectRatio;

  // final Trimmer _trimmer = Trimmer();
  VideoPlayerController? _videoController;

  bool _playing = false;
  // bool _canTrim = false;

  // static const _trimHeight = 50.0;

  @override
  void initState() {
    super.initState();

    if(widget.bytes != null){
      _thumbnail = Image.memory(widget.bytes!).image;

      _aspectRatio = widget.asset!.width / widget.asset!.height;

      if(_aspectRatio > 1){
        _aspectRatio = 1 / _aspectRatio;
      }
    } 

    _initVideoPlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer() async {
    final file = widget.file ?? await widget.asset!.file;

    if(file == null) return;

    _videoController = VideoPlayerController.file(file);

    // _trimmer.loadVideo(videoFile: File(widget.file.path)).then((_) {
    //   setState(() => _canTrim = true);
    // });

    _videoController!.initialize().then((_) {
      setState(() {});

      _videoController!.addListener(() {
        if(_videoController!.value.position == _videoController!.value.duration){
          _videoController!.seekTo(Duration.zero);
          setState(() => _playing = false);
        }
      });
    });
  }

  void _toggle() {
    if(_playing) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }

    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Size size = MediaQuery.of(context).size;

    if(widget.file != null){
      /// Si viene de la camara el aspect ratio es toda la pantalla
      _aspectRatio = size.width / size.height;
    }

    final videoReady = _videoController != null;

    return Stack(
      alignment: Alignment.center,
      children: [
        if(widget.asset != null)
          Center(
            child: Hero(
              tag: widget.asset!.id,
              createRectTween: (begin, end) => RectTween(begin: begin, end: end),
              child: Image(image: _thumbnail),
            ),
          ),

        if(videoReady)
          GestureDetector(
            onTap: _toggle,
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: VideoPlayer(_videoController!)
            )
          ),

        AnimatedOpacity(
          duration: kThemeAnimationDuration,
          opacity: _playing ? 0.0 : 1.0,
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
      ]
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';
// import 'package:objectid/objectid.dart';

import '../../styles/styles.dart';
import '../../global/globals.dart';
import '../../providers/message_provider.dart';
import '../../services/messages_service.dart';
import '../../extensions/duration_apis.dart';
import '../../pages/chat/chat.dart';
import '../transitions/transitions.dart';
import '../widgets.dart';
import 'emoji_keyboard.dart';

class ChatTextField extends StatefulWidget {
  const ChatTextField({Key? key}) : super(key: key);

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  late final MessageProvider _chat;

  @override
  void initState() {
    super.initState();

    _chat = Provider.of<MessageProvider>(context, listen: false);

    _chat.controller = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MessageProvider, bool>(
      selector: (_, model) => model.showEmojis,
      /// Como no seteamos un setter con notifyListener al showEmojis, por alguna razon no redibuja 
      /// al cambiar manualemnte el valor y luego notificar, por eso con esto le decimos que siempre
      /// que sea falso redibuje
      shouldRebuild: (prev, next) => !prev && !next,
      builder: (context, showEmojis, _) {
        return EmojiKeyboard(
          textController: _chat.controller,
          inputDecoration: InputStyles.chatInput,
          iconColor: Colors.grey,
          onChanged: (value) => _chat.message['text'] = value,
          hideKeyboard: !showEmojis,
          onVisibilityChanged: (isVisible) => _chat.showEmojis = isVisible,
          child: const _MediaActions(),
        );
      }
    );
  }
}

class _MediaActions extends StatefulWidget {
  const _MediaActions({Key? key}) : super(key: key);

  @override
  State<_MediaActions> createState() => __MediaActionsState();
}

class __MediaActionsState extends State<_MediaActions> with SingleTickerProviderStateMixin {
  /// Procurar no utilizar procesos en el build si se tiene un ticker
  late final AnimationController _cancelController;
  late Size _size;

  final _durationNotifier = ValueNotifier(Duration.zero);
  final _recorder = Record();

  Timer? _timer;
  bool _recording = false;

  static const _codec = AudioEncoder.wav;
  static const _cancelDuration = Duration(milliseconds: 200);
  static const _stepDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _cancelController = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    _size = MediaQuery.of(context).size;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _cancelController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _setTimer() {
    _durationNotifier.value = Duration.zero;

    setState(() => _recording = true);

    _timer?.cancel();

    _timer = Timer.periodic(_stepDuration, (timer) {
      _durationNotifier.value += _stepDuration;
    });
  }

  Future<void> _record() async {
    bool canRecord = await Permission.microphone.isGranted;

    if(canRecord) {
      final filename = generateFileName('AUDIO', 'wav');
      _recorder.start(path: '${AppFolder.sentDirectory}/$filename', encoder: _codec);
      
      _setTimer();
    } else {
      Permission.microphone.request();
    }
  }

  void _stop(bool canceled) {
    _cancelController.animateTo(0.0, duration: _cancelDuration);

    setState(() => _recording = false);

    if(canceled) return;

    final milliseconds = _durationNotifier.value.inMilliseconds;

    if(milliseconds > 1000){
      _timer?.cancel();

      _recorder.stop().then((path) {
        final chat = context.read<MessageProvider>();

        chat.message["audio"] = path!.split('/').last;
        chat.message["duration"] = milliseconds;

        context.read<MessagesService>().sendMessage(chat.message);
        chat.clearMessage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ///-----------------------------------
        /// SWIPE AND MEDIA-RECORD BUTTONS
        ///-----------------------------------
        AnimatedBuilder(
          animation: _cancelController,
          builder: (_, child){
            final dx = -_size.width * _cancelController.value;
            return Transform.translate(offset: Offset(dx,0.0), child: child);
          },
          child: Row(
            children: [
              ///-----------------------------------
              /// SWIPE TO CANCEL
              ///-----------------------------------
              Expanded(
                /// Podria utilizar un AnimatedOpacity pero tendria que ir con un IgnorePointer
                child: AnimatedSwitcher(
                  duration: kThemeAnimationDuration,
                  child: !_recording 
                    ? const SizedBox() 
                    : DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(Icons.chevron_left_rounded),
                          Text('Swipe to cancel')
                        ],
                      ),
                    ),
                ),
              ),
          
              ///-----------------------------------
              /// MEDIA AND RECORD BUTTONS
              ///-----------------------------------
              _MediaAndRecordButton(
                recording: _recording,
                onRecordStart: _record,
                onRecordEnd: _stop,
                onRecordDrag: (value) => _cancelController.value = value,
              ),
            ],
          ),
        ),

        ///-----------------------------------
        /// RECORDING TIME
        ///-----------------------------------
        AnimatedSwitcher(
          duration: kThemeAnimationDuration,
          child: !_recording 
            ? const SizedBox() 
            : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8.0),
                  ValueListenableBuilder<Duration>(
                    valueListenable: _durationNotifier, 
                    builder: (_, duration, __) => Text(duration.mmss())
                  )
                ],
              ),
            ),
        )
      ],
    );
  }
}

class _MediaAndRecordButton extends StatefulWidget {
  final bool recording;
  final VoidCallback onRecordStart;
  final void Function(bool canceled) onRecordEnd;
  final ValueChanged<double> onRecordDrag;

  const _MediaAndRecordButton({
    Key? key,
    required this.recording,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onRecordDrag,
  }) : super(key: key);

  @override
  State<_MediaAndRecordButton> createState() => __MediaAndRecordButtonState();
}

class __MediaAndRecordButtonState extends State<_MediaAndRecordButton> with SingleTickerProviderStateMixin {
  late final AnimationController _recordController;
  late MediaQueryData _mq;

  bool _canceled = false;

  static const _duration = Duration(milliseconds: 150);
  static const _textfieldHeight = 56.0;

  @override
  void initState() {
    super.initState();

    _recordController = AnimationController(
      vsync: this,
      duration: _duration
    );
  }

  @override
  void didChangeDependencies() {
    _mq = MediaQuery.of(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant _MediaAndRecordButton oldWidget) {
    if(widget.recording != oldWidget.recording){
      if(widget.recording){
        _recordController.forward();
      } else {
        _recordController.reverse();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _recordController.dispose();
    super.dispose();
  }

  void _onRecordStart(LongPressStartDetails details) {
    widget.onRecordStart();
  }

  void _onRecordEnd(LongPressEndDetails details){
    if(_canceled){
      _canceled = false;
    } else {
      widget.onRecordEnd(false);
    }
  }

  void _onRecordDrag(LongPressMoveUpdateDetails details) {
    if(widget.recording && !_canceled){
      final maxWidth = _mq.size.width - kMinInteractiveDimension;
      final percentage = details.offsetFromOrigin.dx / maxWidth * -1;

      if(percentage > 0.35) {
        _canceled = true;
        widget.onRecordEnd(true);
      } else {
        widget.onRecordDrag(percentage.clamp(0.0, 1.0));
      }
    }
  }

  void _onSend() {
    final chat = context.read<MessageProvider>();
    context.read<MessagesService>().sendMessage(chat.message);
    chat.clearMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageProvider>(
      builder: (context, chat, __) {
        return Row(
          children: [
            ///----------------------------
            /// MEDIA BUTTON (OVERLAY MENU)
            ///----------------------------
            TweenAnimationBuilder<double>( ///Tambien se pudo hacer con el animatedSwitcher
              tween: Tween(begin: 0.0, end: widget.recording || !chat.showSend ? 1.0 : 0.0),
              duration: kThemeAnimationDuration,
              child: OverlayBuilder(
                showOverlay: chat.showOverlay,
                overlayType: chat.overlayType,
                onRemove: () => chat.showOverlay = false,
                builder: (context, animation, _) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 160),
                    left: 10.0,
                    right: 10.0,
                    bottom: _textfieldHeight + _mq.viewInsets.bottom,
                    child: _MediaButtons(
                      animation: animation,
                    ),
                  )                  ;
                },
                child: IconButton(
                  onPressed: () => chat.showOverlay = true,
                  splashRadius: 24.0,
                  icon: const Icon(Icons.attach_file),
                ),
              ),
              builder: (_, value, child) {
                return FractionalTranslation(
                  translation: Offset(value, 0.0),
                  child: Transform.scale(
                    scale: 1.0 - value,
                    child: child,
                  ),
                );
              }
            ),
      
            ///----------------------------
            /// RECORD BUTTON
            ///----------------------------
            AnimatedSwitcher(
              duration: kThemeAnimationDuration,
              transitionBuilder: scaleTransitionBuilder,
              child: !chat.showSend 
                ? IconButton(
                  onPressed: _onSend,
                  icon: const Icon(Icons.send, color: Colors.blue,)
                ) 
                : RawGestureDetector(
                  gestures: <Type, GestureRecognizerFactory>{
                    LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                      () => LongPressGestureRecognizer(),
                      (LongPressGestureRecognizer instance) {
                        instance.onLongPressStart = _onRecordStart;
                        instance.onLongPressEnd = _onRecordEnd;
                        instance.onLongPressMoveUpdate = _onRecordDrag;
                      },
                    ),
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ///-----------------------------------
                      /// BUTTON BACKGROUND
                      ///-----------------------------------
                      CustomPaint(
                        painter: RecordBackgroundPainter(
                          animation: _recordController
                        )
                      ),
        
                      ///-----------------------------------
                      /// RECORD BUTTON
                      ///-----------------------------------
                      AnimatedScale(
                        duration: kThemeAnimationDuration,
                        scale: widget.recording ? 1.5 : 1.0,
                        child: SizedBox.square(
                          dimension: kMinInteractiveDimension,
                          child: Icon(
                            Icons.mic_none,
                            color: widget.recording ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
            )
          ]
        );
      },
    );
  }
}

/// Podria ser un StalessWidget, no se sabe que tanto afecte
class _MediaButtons extends StatefulWidget {
  final Animation<double> animation;

  const _MediaButtons({Key? key, required this.animation}) : super(key: key);

  @override
  State<_MediaButtons> createState() => __MediaButtonsState();
}

class __MediaButtonsState extends State<_MediaButtons> {
  Future<void> _navigate(PageRoute route) async {
    final chat = context.read<MessageProvider>();

    chat.overlayType = OverlayType.normal;
    chat.showOverlay = false;

    Navigator.of(context).push(route).then((value) {
      chat.overlayType = OverlayType.animated;
    });
  }

  Future<void> _onCamera() async {
    final cameras = await availableCameras();

    final route = CupertinoPageRoute(
      builder: (_) => CameraPage(cameras: cameras)
    );

    _navigate(route);
  }

  void _onGallery() {
    final route = SlideBottomRouteBuilder(
      opaque: false,
      barrierColor: Colors.black38,
      child: const MediaPickerPage(),
    );

    _navigate(route);
  }

  Future<void> _onFiles() async {
    final chat = context.read<MessageProvider>();

    final result = await FilePicker.platform.pickFiles();

    chat.overlayType = OverlayType.normal;
    chat.showOverlay = false;

    if(result == null) return;

    final files = result.paths.map((path) => File(path!)).toList();

    final route = FadeInRouteBuilder(
      child: FileEditionPage(files: files)
    );

    FocusScope.of(context).unfocus();

    Navigator.of(context).push(route).then((value) {
      chat.overlayType = OverlayType.animated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: RevealClipper(
        animation: widget.animation
      ),
      child: Material(
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ///-----------------------------------
                /// MEDIA BUTTON
                ///-----------------------------------
                _MediaIcon(
                  color: Colors.indigo,
                  icon: Icons.camera,
                  label: 'Camera',
                  animation: widget.animation,
                  onPress: _onCamera,
                ),
    
                ///-----------------------------------
                /// MEDIA BUTTON
                ///-----------------------------------
                _MediaIcon(
                  color: Colors.lightBlue,
                  icon: Icons.image,
                  label: 'Gallery',
                  animation: widget.animation,
                  onPress: _onGallery,
                ),
    
                ///-----------------------------------
                /// MEDIA BUTTON
                ///-----------------------------------
                _MediaIcon(
                  color: Colors.purple,
                  icon: Icons.file_copy,
                  label: 'File',
                  animation: widget.animation,
                  onPress: _onFiles,
                )
              ],
            ),
          ),
        ),
    );
  }
}

class _MediaIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPress;
  final Animation<double> animation;

  const _MediaIcon({Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPress,
    required this.animation
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// Se podria crear en el contructor, al ser un staless no se se dedibuja muchas veces
    final bounceAnimation = CurvedAnimation(
      parent: animation, 
      curve: const ElasticInOutCurve(0.6)
    );

    return ScaleTransition(
      scale: bounceAnimation,
      child: Column(
        children: [
          Material(
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: IconButton(
                onPressed: onPress,
                icon: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 5.0),
          Text(label, style: const TextStyle())
        ],
      ),
    );
  }
}
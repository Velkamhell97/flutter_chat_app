import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:io';

import '../../models/models.dart';
import '../../widgets/painters.dart';
import '../../extensions/extensions.dart';
import '../../widgets/transitions/transitions.dart';
import 'chat.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;

  Offset? focusPoint;
  double _minExposureOffset = 0.0;
  double _maxExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  double _currentScale = 1.0;
  double _baseScale = 1.0;

  final _exposureNotifier = ValueNotifier<double>(0.0);
  final _zoomNotifier = ValueNotifier<double>(1.0);
  final _recordNotifier = ValueNotifier(Duration.zero);

  FlashMode _currentFlashMode = FlashMode.off;
  Camera _selectedCamera = Camera.rear;

  final _player = AudioPlayer();

  bool _showZoom = false;
  bool _isRecording = false;

  Timer? _timer;
  static const _step = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _player.setSourceAsset('audios/shutter.mp3');

    onCameraSelected(widget.cameras[_selectedCamera.index]);
  }

  @override
  void didChangeDependencies() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

     if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onCameraSelected(cameraController.description);
    }

    // super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _controller?.dispose();

    _zoomNotifier.dispose();
    _exposureNotifier.dispose();

    _player.dispose();
    _timer?.cancel();

    super.dispose();
  }

  ///---------------------------
  /// CHANGE CAMERA
  ///---------------------------
  Future<void> _onSetCamera() async {
    _selectedCamera = Camera.values[(_selectedCamera.index + 1) % 2];
    onCameraSelected(widget.cameras[_selectedCamera.index]);
  }

  Future<void> onCameraSelected(CameraDescription cameraDescription) async {
    final oldController = _controller;

    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }

    final cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    // cameraController.addListener(() {
    //   if (mounted) {
    //     setState(() {});
    //   }
    
    //   if (cameraController.value.hasError) {
    //     print('Camera Error ${cameraController.value.errorDescription}');
    //   }
    // });

    try {
      await cameraController.initialize();
      
      await Future.wait(<Future<Object?>>[
        cameraController.getMinExposureOffset().then((value) => _minExposureOffset = value),
        cameraController.getMaxExposureOffset().then((value) => _maxExposureOffset = value),
        cameraController.getMinZoomLevel().then((value) => _minZoom = value),
        cameraController.getMaxZoomLevel().then((value) => _maxZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          debugPrint('Access Denied');
          break;
        default:
          debugPrint('Camera Error');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  ///---------------------------
  /// SCALE FUNCTIONS
  ///---------------------------
  void _onScaleStart(ScaleStartDetails details) {
    setState(() => _showZoom = true);
    _baseScale = _currentScale;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    ///Se puede validar por fuera de la funcion, pasando un null si el controller es null
    if (_controller == null) {
      return;
    }

    _currentScale = (_baseScale * details.scale).clamp(_minZoom, _maxZoom);
    _zoomNotifier.value = _currentScale;

    /// Se podria dejar la captura de problemas al listener, pero no se sabe si capture todos los errores
    try {
      await _controller!.setZoomLevel(_currentScale);
    } catch (e) {
      debugPrint('Zoom Error: $e');
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    setState(() => _showZoom = false);
  }

  ///---------------------------
  /// FOCUS ON POINT
  ///---------------------------
  void _onTapDown(TapDownDetails details, BoxConstraints constrains) {
    if (_controller == null) {
      return;
    }

    final cameraController = _controller!;

    final offset = Offset(
      details.localPosition.dx / constrains.maxWidth, 
      details.localPosition.dy / constrains.maxHeight
    );

    try {
      /// Aveces es mejor setearla manual
      cameraController.setExposurePoint(offset);
      cameraController.setFocusPoint(offset);
    } catch (e) {
      debugPrint('Focus Point Error: $e');
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => focusPoint = details.globalPosition);
  }

  ///---------------------------
  /// EXPOSURE
  ///---------------------------
  Future<void> _onSetExposureOffset(double offset) async {
    if (_controller == null) {
      return;
    }

    _currentExposureOffset = offset;
    _exposureNotifier.value = _currentExposureOffset;

    try {
      await _controller!.setExposureOffset(offset);
    } catch (e) {
      debugPrint('Exposure Error: $e');
    }
  }

  ///---------------------------
  /// TOGGLE FLASH
  ///---------------------------
  Future<void> _onSetFlashMode() async {
    if (_controller == null) {
      return;
    }

    _currentFlashMode = FlashMode.values[(_currentFlashMode.index + 1) % 3];

    try {
      await _controller!.setFlashMode(_currentFlashMode);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Flash Mode Error: $e');
    }
  }

  ///---------------------------
  /// TAKE PICTURE
  ///---------------------------
  Future<void> _takePicture(double fitScale) async {
    final cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (cameraController.value.isTakingPicture) {
      return;
    }

    try {
      cameraController.takePicture().then((file) async {
        if(mounted) {
          /// No se sabe si es necesario antes de navegar
          setState(() {});

          final bytes = await file.readAsBytes();

          final route = FadeInRouteBuilder(
            child: ImageEditionPage(
              bytes: bytes, 
              xFile: file,
              fitScale: fitScale
            )
          );

          Navigator.of(context).push(route);
        }
      });

      _player.resume();
    } catch (e) {
      debugPrint('Take Picture Error: $e');
    }
  }

  ///---------------------------
  /// RECORD VIDEO
  ///---------------------------
  void _startTimer() {
    _recordNotifier.value = Duration.zero;

    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer.periodic(_step, (_) {
      _recordNotifier.value = _recordNotifier.value + _step;
    });

    setState(() => _isRecording = true);
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRecording = false);
  }

  Future<void> _startVideoRecording() async {
    final cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      cameraController.startVideoRecording().then((_) {
        if(mounted){
          setState(() {});
        }
      });

      _startTimer();
    } catch (e) {
      debugPrint('Video Recording Error: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    final cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    final miliseconds = _recordNotifier.value.inMilliseconds;

    if(miliseconds < 1000) return;

    try {
      cameraController.stopVideoRecording().then((file) {
        if (mounted) {
          setState(() {});

          final route = FadeInRouteBuilder(
            child: VideoEditionPage(
              file: File(file.path),
              duration: _recordNotifier.value,
            )
          );

          Navigator.of(context).push(route);
        }
      });
    } catch (e) {
      debugPrint('Stop Video Recodring Error: $e');
    } finally {
      _stopTimer();
    }
  }

  /// Por si se quiere pausar o continuar el video, aqui se debe manejar otra estrategia para el tiempo
  /// pues no se puede pausar depronto seria necesario un StopWatcher
  // Future<void> _toggleVideoRecording() async {
  //   final cameraController = _controller;
  //
  //   if (cameraController == null || !cameraController.value.isInitialized) {
  //     return;
  //   }
  //
  //   try {
  //     if (cameraController.value.isRecordingVideo) {
  //       await cameraController.pauseVideoRecording();
  //     } else {
  //       await cameraController.resumeVideoRecording();
  //     }
  //
  //     if(mounted) {
  //       setState(() {});
  //     }
  //   } catch (e) {
  //     print('Error $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final cameraController = _controller;

    final Size size = MediaQuery.of(context).size;

    double scale = 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          ///----------------------------------
          /// CAMERA LAYER
          ///----------------------------------
          Builder(
            builder: (_) {
              if(cameraController == null || !cameraController.value.isInitialized){
                return const SizedBox.shrink();
              }
              
              scale = size.aspectRatio * cameraController.value.aspectRatio;
      
              if(scale < 1) {
                scale = 1 / scale;
              }
      
              return Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(
                    _controller!,
                    child: LayoutBuilder(
                      builder: (context, constrains) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onScaleEnd: _onScaleEnd,
                          onTapDown: (details) => _onTapDown(details, constrains),
                          onTapUp: _onTapUp,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          ///----------------------------------
          /// RECORD TIME
          ///----------------------------------
          Positioned(
            top: size.height * 0.1,
            child: _RecordTime(
              show: _isRecording,
              recordNotifier: _recordNotifier,
            ),
          ),
      
          ///----------------------------------
          /// CAMERA BUTTONS LAYER
          ///----------------------------------
          Positioned(
            bottom: size.height * 0.02,
            left: 0.0,
            right: 0.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //----------------------------------
                /// EXPOSURE SLIDER
                ///----------------------------------
                _ExposureSlider(
                  show: !_isRecording,
                  maxExposureOffset: _maxExposureOffset,
                  minExposureOffset: _minExposureOffset,
                  exposureNotifier: _exposureNotifier,
                  onExposureChanged: _onSetExposureOffset,
                ),
      
                const SizedBox(height: 20.0),
      
                ///----------------------------------
                /// ZOOM SLIDER
                ///----------------------------------
                _ZoomSlider(
                  show: _showZoom, 
                  maxZoom: _maxZoom, 
                  minZoom: _minZoom, 
                  zoomNotifier: _zoomNotifier
                ),
      
                const SizedBox(height: 10.0),
      
                ///----------------------------------
                /// ACTIONS BUTTONS
                ///----------------------------------
                _CameraButtons(
                  flashMode: _currentFlashMode,
                  camera: _selectedCamera,
                  onTakePicture: () => _takePicture(scale),
                  onStartRecorder: _startVideoRecording,
                  onEndRecorder: _stopVideoRecording,
                  onSetFlashMode: _onSetFlashMode,
                  onSetCamera: _onSetCamera,
                )
              ],
            ),
          ),

          ///----------------------------------
          /// FOCUS POINT
          ///----------------------------------
          Positioned(
            left: focusPoint != null ? focusPoint!.dx : null,
            top: focusPoint != null ? focusPoint!.dy : null,
            child: _FocusPoint(center: focusPoint),
          )
        ],
      ),
    );
  }
}


class _RecordTime extends StatelessWidget {
  final bool show;
  final ValueNotifier<Duration> recordNotifier;

  const _RecordTime({
    Key? key, 
    required this.show, 
    required this.recordNotifier
  }) : super(key: key);

  static const _duration = Duration(milliseconds: 300);

  static const _style = TextStyle(fontSize: 15, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _duration,
      opacity: show ? 1.0 : 0.0,
      child: ValueListenableBuilder<Duration>(
        valueListenable: recordNotifier,
        builder: (_, duration, __) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black45, 
              borderRadius: BorderRadius.circular(12.0)
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.circle,
                    color: Colors.redAccent,
                    size: 12,
                  ),
                  
                  const SizedBox(width: 5.0),
                  
                  Text(duration.mmss(), style: _style)
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExposureSlider extends StatelessWidget {
  final bool show;
  final double maxExposureOffset;
  final double minExposureOffset;
  final ValueNotifier<double> exposureNotifier;
  final ValueChanged<double>? onExposureChanged;

  const _ExposureSlider({
    Key? key,
    required this.show,
    required this.maxExposureOffset,
    required this.minExposureOffset,
    required this.exposureNotifier,
    this.onExposureChanged,
  }) : super(key: key);

  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(right: size.width * 0.05),
      child: AnimatedOpacity(
        duration: _duration,
        opacity: show ? 1.0 : 0.0,
        child: SizedBox(
          width: 40,
          child: Column(
            children: [
              const Icon(Icons.brightness_high, color: Colors.white),
              
              const SizedBox(height: 10.0),
              
              RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  width: size.height * 0.5,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.0,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white38
                    ),
                    child: ValueListenableBuilder<double>(
                      valueListenable: exposureNotifier,
                      builder: (_, exposure, __) {
                        return Slider(
                          min: minExposureOffset, 
                          max: maxExposureOffset, 
                          value: exposure, 
                          onChanged: onExposureChanged
                        );
                      }
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10.0),

              const Icon(Icons.brightness_low, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  final bool show;
  final double minZoom;
  final double maxZoom;
  final ValueNotifier<double> zoomNotifier;

  const _ZoomSlider({
    Key? key, 
    required this.show, 
    required this.maxZoom, 
    required this.minZoom, 
    required this.zoomNotifier
  }) : super(key: key);

  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
      child: AnimatedOpacity(
        duration: _duration,
        opacity: show ? 1.0 : 0.0,
        child: Row(
          children: [
            const Icon(Icons.remove, color: Colors.white),
            
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3.0,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white38
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: zoomNotifier,
                  builder: (context, zoom, child) {
                    return Slider(
                      min: minZoom,
                      max: maxZoom,
                      value: zoom,
                      onChanged: (_) {},
                    );
                  }
                ),
              ),
            ),
            
            const Icon(Icons.add, color: Colors.white),
          ],
        ),
      ),
    );
  }
}


class _CameraButtons extends StatefulWidget {
  final FlashMode flashMode;
  final Camera camera;
  final VoidCallback onTakePicture;
  final VoidCallback onStartRecorder;
  final VoidCallback onEndRecorder;
  final VoidCallback onSetFlashMode;
  final VoidCallback onSetCamera;

  const _CameraButtons({
    Key? key,
    required this.flashMode,
    required this.camera,
    required this.onTakePicture,
    required this.onStartRecorder,
    required this.onEndRecorder,
    required this.onSetFlashMode,
    required this.onSetCamera
  }) : super(key: key);

  @override
  State<_CameraButtons> createState() => __CameraButtonsState();
}

class __CameraButtonsState extends State<_CameraButtons> with TickerProviderStateMixin {
  late final AnimationController _controller;

  bool _tapped = false;
  bool _holding = false;

  static const _cameraIcons = [
    Icons.camera_front,
    Icons.camera_rear,
  ];

  static const List<IconData> _flashIcons = [
    Icons.flash_off, 
    Icons.flash_auto, 
    Icons.flash_on
  ];

  static const _switcherDuration = Duration(milliseconds: 300);
  static const _longDuration = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Detecta tambien el tap para tomar una imagen
  void _onLongPressDown(LongPressDownDetails details) {
    setState(() => _tapped = true);

    /// Un poco despues de acabada la animacion (120ms) si no esta grabando removemos la animacion
    Future.delayed(const Duration(milliseconds: 150), () {
      if(!_holding) setState(() => _tapped = false);
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _holding = true;
    widget.onStartRecorder();
    _controller.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _tapped = false;
      _holding = false;
    });
    widget.onEndRecorder();
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity = 1 - _controller.value;
          final scale = 0.4 * _controller.value;
          final dx = 1.2 * _controller.value;
          final color = Color.lerp(Colors.white, Colors.red, _controller.value);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ///-----------------------------------------
              /// FLASH BUTTON
              ///-----------------------------------------
              FractionalTranslation(
                translation: Offset(dx, 0.0),
                child: Transform.scale(
                  scale: 1 - scale,
                  child: InkWell(
                    onTap: widget.onSetFlashMode,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: AnimatedSwitcher(
                        duration: _switcherDuration,
                        child: Icon(
                          _flashIcons[widget.flashMode.index],
                          key: ValueKey(widget.flashMode.name), 
                          color: Colors.white.withOpacity(opacity), 
                          size: 40.0
                        ),
                        transitionBuilder: verticalFadeSlideTransitionBuilder,
                      ),
                    ),
                  ),
                ),
              ),

              ///-----------------------------------------
              /// MAIN BUTTON
              ///-----------------------------------------
              RawGestureDetector(
                gestures: <Type, GestureRecognizerFactory> {
                  TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                    (instance){
                      instance.onTap = widget.onTakePicture;
                    }
                  ),
                  LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                    () => LongPressGestureRecognizer(duration: _longDuration),
                    (instance) {
                      instance.onLongPressDown = _onLongPressDown;
                      instance.onLongPressStart = _onLongPressStart;
                      instance.onLongPressEnd = _onLongPressEnd;
                    }
                  )
                },
                child: Transform.scale(
                  scale: 1 + (0.1 * _controller.value),
                  child: Container(
                    width: 70.0,
                    height: 70.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      border: Border.all(width: 4.0, 
                      color: Colors.white)
                    ),
                    padding: const EdgeInsets.all(3.0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: _tapped ? 1.0 : 0.0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color, 
                          shape: BoxShape.circle
                        ),
                        child: const SizedBox.expand()
                      ),
                    ),
                  ),
                ),
              ),

              ///-----------------------------------------
              /// CAMERA BUTTON
              ///-----------------------------------------
              FractionalTranslation(
                translation: Offset(-dx, 0.0),
                child: Transform.scale(
                  scale: 1 - scale,
                  child: InkWell(
                    onTap: widget.onSetCamera,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: AnimatedSwitcher(
                        duration: _switcherDuration,
                        child: Icon(
                          _cameraIcons[widget.camera.index],
                          key: ValueKey(widget.camera.name), 
                          color: Colors.white.withOpacity(opacity), 
                          size: 40.0
                        ),
                        transitionBuilder: fadeFlipTransitionBuilder,
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _FocusPoint extends StatefulWidget {
  final Offset? center;

  const _FocusPoint({
    Key? key, 
    this.center,
  }) : super(key: key);

  @override
  State<_FocusPoint> createState() => __FocusPointState();
}

class __FocusPointState extends State<_FocusPoint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _show = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300)
    );

    _controller.addStatusListener((status) {
      if(status == AnimationStatus.completed){
        ///Una vez se complete la animacion, esperamos un poco y la desaparecemos
        Future.delayed(const Duration(milliseconds: 100), () {
          if(!_controller.isAnimating){
            setState(() => _show = false);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FocusPoint oldWidget) {
    if(oldWidget.center != widget.center){
      if(_show) {
        _controller.forward(from: 0.0);
        return;
      }

      setState(() => _show = true);

      _controller.forward(from: 0.0);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _show ? CustomPaint(
        painter: FocusPainter(
          animation: _controller
        ),
      ) : const SizedBox(),
    );
  }
}
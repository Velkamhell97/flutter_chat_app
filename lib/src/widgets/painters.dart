import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

///-------------------------------------------------------------------
///-------------------------PAINTERS----------------------------------
///-------------------------------------------------------------------
class OutcomingMessagePainter extends CustomPainter {
  final bool showTail;

  const OutcomingMessagePainter({this.showTail = false});

  static const _kRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = const Color(0xffEFFFDE);

    final rect = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_kRadius));

    canvas.drawRRect(rrect, paint);

    if(showTail){
      final startTail = Offset(rect.width, rect.height - _kRadius);
      final controlTail = Offset(rect.width, rect.height - _kRadius / 2);
      final endTail = Offset(rect.width + _kRadius / 3, rect.height - _kRadius / 4);

      final tailRadius = (rect.height - endTail.dy) / 2;
      final tailCenter =  Offset(endTail.dx, endTail.dy + tailRadius);
      final tailRect = Rect.fromCircle(center: tailCenter, radius: tailRadius);
    
      final path = Path()
        ..addRect(Rect.fromLTWH(startTail.dx - _kRadius, startTail.dy, _kRadius, _kRadius))
        ..moveTo(startTail.dx, startTail.dy)
        ..quadraticBezierTo(controlTail.dx, controlTail.dy, endTail.dx, endTail.dy)
        ..arcTo(tailRect, -pi / 2,   pi, false)
        ..lineTo(rect.width, rect.height);

      canvas.drawPath(path, paint);
    }

    // canvas.drawArc(tailRect, pi / 2, -pi, true, Paint()..color = Colors.red);
    // canvas.drawRect(tailRect, Paint()..color = Colors.green.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(OutcomingMessagePainter oldDelegate) {
    return oldDelegate.showTail != showTail;
  }
}

class IncomingMessagePainter extends CustomPainter {
  final bool showTail;

  const IncomingMessagePainter({this.showTail = false});

  static const _kRadius = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = const Color(0xffEFFFDE);

    final rect = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_kRadius));

    canvas.drawRRect(rrect, paint);

    if(showTail){
      final startTail = Offset(0, rect.height - _kRadius);
      final controlTail = Offset(0, rect.height - _kRadius / 2);
      final endTail = Offset(-_kRadius / 3, rect.height - _kRadius / 4);

      final tailRadius = (rect.height - endTail.dy) / 2;
      final tailCenter =  Offset(endTail.dx, endTail.dy + tailRadius);
      final tailRect = Rect.fromCircle(center: tailCenter, radius: tailRadius);
    
      final path = Path()
        ..addRect(Rect.fromLTWH(startTail.dx, startTail.dy, _kRadius, _kRadius))
        ..moveTo(startTail.dx, startTail.dy)
        ..quadraticBezierTo(controlTail.dx, controlTail.dy, endTail.dx, endTail.dy)
        ..arcTo(tailRect, -pi / 2,   -pi, false)
        ..lineTo(0.0, rect.height);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(IncomingMessagePainter oldDelegate) {
    return oldDelegate.showTail != showTail;
  }
}

class RecordBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  RecordBackgroundPainter({required this.animation}) : super(repaint: animation);

  static const _maxRadius = 50;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.blue.shade200;

    final radius = lerpDouble(0.0, _maxRadius, animation.value)!;

    canvas.drawCircle(const Offset(0.0, 0.0), radius, paint);
  }

  @override
  bool shouldRepaint(RecordBackgroundPainter oldDelegate) => false;
}

class CanvasPainter extends CustomPainter {
  final ValueNotifier<List<Offset>> points;
  final Color color;
  final double strokeWidth;

  const CanvasPainter({
    required this.points,
    required this.color,
    this.strokeWidth = 5.0
  }) : super(repaint: points);

  @override
  void paint(Canvas canvas, Size size) {
    // print('painter $color');

    final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;

    canvas.drawPoints(PointMode.polygon, points.value, paint);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) => points.value.isEmpty;

  @override
  bool shouldRebuildSemantics(CanvasPainter oldDelegate) => false;
}

class FocusPainter extends CustomPainter {
  final Animation<double> animation;

  const FocusPainter({
    required this.animation
  }) : super(repaint: animation);

  static const _radius = 25.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outerPainter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerPainter = Paint()
      ..color = Colors.white38;

    final outerRadius = lerpDouble(_radius * 1.5, _radius, animation.value)!;
    final innerRadius = lerpDouble(0, _radius, animation.value)!;

    canvas.drawCircle(Offset.zero, outerRadius, outerPainter);
    canvas.drawCircle(Offset.zero, innerRadius, innerPainter);
  }

  @override
  bool shouldRepaint(FocusPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(FocusPainter oldDelegate) => false;
}


///-------------------------------------------------------------------
///-------------------------CLIPPERS----------------------------------
///-------------------------------------------------------------------
class RevealClipper extends CustomClipper<Path> {
  final Animation<double> animation;

  const RevealClipper({
    required this.animation,
  }) : super(reclip: animation);

  /// 
  static const _kOfsset = kMinInteractiveDimension * 1.4;

  @override
  Path getClip(Size size) {
    final path = Path();

    final center = Offset(size.width - _kOfsset, size.height);

    final radius = lerpDouble(0.0, size.width, animation.value)!;

    path.addOval(Rect.fromCircle(center: center, radius: radius));

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CropClipper extends CustomClipper<Rect> {
  final Rect rect;

  const CropClipper(this.rect);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      size.width  * rect.left,
      size.height * rect.top,
      size.width  * rect.width,
      size.height * rect.height
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}


///-------------------------------------------------------------------
///-------------------------SLIDER SHAPES-----------------------------
///-------------------------------------------------------------------
class WaveTrackShape extends SliderTrackShape {
  final List<double> samples;
  final Color activeColor;
  final Color inactiveColor;
  final double strokeWidth;
  final bool rounded;

  WaveTrackShape({
    required this.samples,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.blueGrey,
    this.strokeWidth = 5.0,
    this.rounded = true
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy;
    final double trackWidth = parentBox.size.width;
    final double trackHeight = parentBox.size.height;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final size = parentBox.size;

    final percentage = thumbCenter.dx / size.width;

    final activeIndex = (percentage * (samples.length - 1)).round();

    final increment = rounded ? 2 : 1;

    final startIndex = activeIndex.isEven ? activeIndex : activeIndex + (increment - 1);

    final barWidth = size.width / samples.length;

    final radius = rounded ? barWidth : 0.0;

    // print('start: $startIndex - active: $activeIndex');

    for (int i = startIndex; i < samples.length; i += increment) {
      /// Punto de inicio de cada barra
      final left = barWidth * i; 
      /// Las muestras estan normalizadas, la maxima amplitud ocupara todo el height
      final barHeight = samples[i] * size.height;
      /// Cada barra se centra desplazandola su height / 2
      final top = thumbCenter.dy - barHeight / 2;
      //Aqui dibujamos los rectangulos llenos (filled)
      context.canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barWidth, barHeight),
            Radius.circular(radius),
          ),
          paint..color = inactiveColor,
        )
        /// Si no dibujamos el borde las samples con heihg 0 no se veran
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barWidth, barHeight),
            Radius.circular(radius),
          ),
          borderPaint..color = inactiveColor,
        );
    }

    for (int i = 0; i <= activeIndex; i += increment) {
      final left = barWidth * i; 
      final barHeight = samples[i] * size.height;
      final top = thumbCenter.dy - barHeight / 2;
      context.canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barWidth, barHeight),
            Radius.circular(radius),
          ),
          paint..color = activeColor,
        )
        //Draws the border for the rectangles of the waveform.
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barWidth, barHeight),
            Radius.circular(radius),
          ),
          borderPaint..color = activeColor,
        );
    }
  }
}

class ColorPickerTrackShape extends SliderTrackShape {
  final List<Color> colors;

  const ColorPickerTrackShape({required this.colors});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double thumbWidth = sliderTheme.thumbShape!.getPreferredSize(isEnabled, isDiscrete).width;
    final double overlayWidth = sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight!;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);

    final double trackLeft = offset.dx + max(overlayWidth / 2, thumbWidth / 2);
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackRight = trackLeft + parentBox.size.width - max(thumbWidth, overlayWidth);
    final double trackBottom = trackTop + trackHeight;
    // If the parentBox'size less than slider's size the trackRight will be less than trackLeft, so switch them.
    return Rect.fromLTRB(min(trackLeft, trackRight), trackTop, max(trackLeft, trackRight), trackBottom);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final paint = Paint()
    ..shader = LinearGradient(colors: colors).createShader(trackRect);

    final Radius trackRadius = Radius.circular((trackRect.height + additionalActiveTrackHeight) / 2);
    
    context.canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        trackRect.left,
        trackRect.top - (additionalActiveTrackHeight / 2),
        trackRect.right,
        trackRect.bottom + (additionalActiveTrackHeight / 2),
        topLeft: trackRadius,
        bottomLeft: trackRadius,
        bottomRight: trackRadius,
        topRight: trackRadius
      ),
      paint,
    );
  }
}

class ColorPickerThumbShape extends SliderComponentShape {
  final Color color;

  final double enabledThumbRadius;
  final double? disabledThumbRadius;
  final double elevation;
  final double pressedElevation;

  const ColorPickerThumbShape({
    required this.color,
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
    this.elevation = 1.0,
    this.pressedElevation = 6.0,
  });
 
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(isEnabled == true ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final radius = enabledThumbRadius;

    final Tween<double> elevationTween = Tween<double>(
      begin: elevation,
      end: pressedElevation,
    );

    final double evaluatedElevation = elevationTween.evaluate(activationAnimation);
    
    final Path path = Path()
      ..addArc(Rect.fromCenter(center: center, width: 2 * radius, height: 2 * radius), 0, pi * 2);
    
    canvas.drawShadow(path, Colors.black, evaluatedElevation, true);

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      radius - (radius * 0.5),
      Paint()..color = color,
    );
  }
}

class _RectangularSliderValueIndicatorPathPainter {
  const _RectangularSliderValueIndicatorPathPainter();

  static const double _triangleHeight = 8.0;
  static const double _labelPadding = 16.0;
  static const double _minLabelWidth = 16.0;
  static const double _bottomTipYOffset = 14.0;
  static const double _dyOffset = 30.0;
  static const double _deflateFactor = 10.0;

  Size getPreferredSize(
    TextPainter labelPainter,
    double textScaleFactor,
  ) {
    return Size(
      _upperRectangleWidth(labelPainter, 1, textScaleFactor),
      labelPainter.height + _labelPadding,
    );
  }

  double getHorizontalShift({
    required RenderBox parentBox,
    required Offset center,
    required TextPainter labelPainter,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required double scale,
  }) {
    const double edgePadding = 8.0;

    final double rectangleWidth = _upperRectangleWidth(labelPainter, scale, textScaleFactor);

    final Offset globalCenter = parentBox.localToGlobal(center);

    final double overflowLeft = max(0, rectangleWidth / 2 - globalCenter.dx + edgePadding);
    final double overflowRight = max(0, rectangleWidth / 2 - (sizeWithOverflow.width - globalCenter.dx - edgePadding));

    if (rectangleWidth < sizeWithOverflow.width) {
      return overflowLeft - overflowRight;
    } else if (overflowLeft - overflowRight > 0) {
      return overflowLeft - (edgePadding * textScaleFactor);
    } else {
      return -overflowRight + (edgePadding * textScaleFactor);
    }
  }

  double _upperRectangleWidth(TextPainter labelPainter, double scale, double textScaleFactor) {
    final double unscaledWidth = max(_minLabelWidth * textScaleFactor, labelPainter.width) + _labelPadding * 2;
    return unscaledWidth * scale;
  }

  void paint({
    required RenderBox parentBox,
    required Canvas canvas,
    required Offset center,
    required double scale,
    required TextPainter labelPainter,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required Color backgroundPaintColor,
    Color? strokePaintColor,
    required Color currentColor
  }) {
    if (scale == 0.0) {
      // Zero scale essentially means "do not draw anything", so it's safe to just return.
      return;
    }

    final double rectangleWidth = _upperRectangleWidth(labelPainter, scale, textScaleFactor);
    
    final double horizontalShift = getHorizontalShift(
      parentBox: parentBox,
      center: center,
      labelPainter: labelPainter,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: sizeWithOverflow,
      scale: scale,
    );

    final double rectHeight = labelPainter.height + _labelPadding;
    
    final Rect upperRect = Rect.fromLTWH(
      -rectangleWidth / 2 + horizontalShift,
      -_triangleHeight - rectHeight,
      rectHeight,
      rectHeight,
    );

    final Path outerPath = Path();
    final Paint outerPaint = Paint()..color = Colors.white;
    
    final Path innerPath = Path();
    final Paint innerPaint = Paint()..color = currentColor;
    
    outerPath.addOval(upperRect);
    innerPath.addOval(upperRect.deflate(_deflateFactor));

    canvas.save();

    canvas.translate(center.dx, center.dy - _bottomTipYOffset - (_dyOffset * scale));
    
    canvas.scale(scale, scale);
    
    canvas.drawPath(outerPath, outerPaint);
    canvas.drawPath(innerPath, innerPaint);

    canvas.restore();
  }
}

class ColorPickerValueIndicatorShape extends SliderComponentShape {
  final Color color;

  const ColorPickerValueIndicatorShape({required this.color});

  static const _RectangularSliderValueIndicatorPathPainter _pathPainter = _RectangularSliderValueIndicatorPathPainter();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) {
    assert(labelPainter != null);
    assert(textScaleFactor != null && textScaleFactor >= 0);
    return _pathPainter.getPreferredSize(labelPainter!, textScaleFactor!);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final double scale = activationAnimation.value;

    _pathPainter.paint(
      parentBox: parentBox,
      canvas: canvas,
      center: center,
      scale: scale,
      labelPainter: labelPainter,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: sizeWithOverflow,
      backgroundPaintColor: sliderTheme.valueIndicatorColor!,
      currentColor: color
    );
  }
}
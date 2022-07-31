import 'package:flutter/material.dart';
import 'dart:math';

///-------------------------------------------------
/// TRANSITION BUILDERS
///-------------------------------------------------
Widget horizontalSlideTransitionBuilder(Widget child, Animation<double> animation, [double direction = 1.0]) {
  return DualTransitionBuilder(
    animation: animation,
    child: child, 
    reverseBuilder: (_, outAnimation, outChild) {
      final progress = CurvedAnimation(parent: outAnimation, curve: const Interval(0.0, 0.5));
      
      return SlideTransition(
        position: Tween(begin: Offset.zero, end: Offset(1.1 * direction, 0.0)).animate(progress),
        child: outChild,
      );
    }, 
    forwardBuilder: (_, inAnimation, inChild) {
      final progress = CurvedAnimation(parent: inAnimation, curve: const Interval(0.5, 1.0));
      return SlideTransition(
        position: Tween(begin: Offset(-1.1 * direction, 0.0), end: Offset.zero).animate(progress),
        child: inChild,
      );
    }
  );
}


Widget verticalFadeSlideTransitionBuilder(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: DualTransitionBuilder(
      animation: animation,
      child: child, 
      reverseBuilder: (_, outAnimation, outChild) {
        // final progress = CurvedAnimation(parent: outAnimation, curve: const Interval(0.0, 0.5));
        
        return SlideTransition(
          position: Tween(begin: Offset.zero, end: const Offset(0.0, 0.85)).animate(outAnimation),
          child: outChild,
        );
      }, 
      forwardBuilder: (_, inAnimation, inChild) {
        // final progress = CurvedAnimation(parent: inAnimation, curve: const Interval(0.5, 1.0));
        
        return SlideTransition(
          position: Tween(begin: const Offset(0.0, -0.85), end: Offset.zero).animate(inAnimation),
          child: inChild,
        );
      }
    ),
  );
}


Widget fadeFlipTransitionBuilder(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: AnimatedBuilder(
      animation: animation, 
      child: child,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(pi * animation.value),
          alignment: Alignment.center,
          child: child,
        );
      },
    ),
  );
}


Widget scaleTransitionBuilder(Widget child, Animation<double> animation) {
  return ScaleTransition(
    scale: animation, 
    child: child,
    // alignment: Alignment.centerRight,
  );
}

///-------------------------------------------------
/// LAYOUT BUILDERS
///-------------------------------------------------
Widget centerRightLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
  return Stack(
    alignment: Alignment.centerRight,
    children: <Widget>[
      ...previousChildren,
      if (currentChild != null) currentChild,
    ],
  );
}
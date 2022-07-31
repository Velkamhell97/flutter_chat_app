import 'package:flutter/material.dart';

class FadePageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return _FadePageTransitionBuilder(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
  }
}

/// Forma 1 en la que se declaran TransitionBuilder, tienen estaticas o por fuera los tween, inicializan las
/// animaciones en el constructor, pero esto impide que se pueda declarar constante la clase, las animaciones
/// suelen crearse con el .drive
class _FadePageTransitionBuilder extends StatelessWidget {
  final Widget child;

  static final _opacityTween = Tween<double>(begin: 0.0, end: 1.0);
  // static final _easeInTween = CurveTween(curve: Curves.easeIn);

  final Animation<double> _opacityAnimation1;
  // final Animation<double> _opacityAnimation2;

  _FadePageTransitionBuilder({
    Key? key,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required this.child
  }) :  
        _opacityAnimation1 = animation.drive(_opacityTween),
        // _opacityAnimation2 = secondaryAnimation.drive(_easeInTween),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation1,
      child: child,
    );
  }
}


class SlideLeftPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return _SlideLeftPageTransitionBuilder(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
  }
}

/// Forma 2 en la que se declaran TransitionBuilder, igualmente tienen los tween estaticos, pero esta vez
/// no se inicializan las animaciones en el constructor sino en el build, esto permite que se pueda definir
/// como constante la clase, aqui se utiliza en .animate para crear la animacion, segun la documentacion
/// al parecer el drive es un poco mejor que el animation
class _SlideLeftPageTransitionBuilder extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  static final _kFromLeftTween = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero);

  const _SlideLeftPageTransitionBuilder({
    Key? key,
    required this.child,
    required this.animation,
    required this.secondaryAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final position = _kFromLeftTween.animate(animation);

    return SlideTransition(
      position: position,
      child: child,
    );
  }
}

/// Este tipo de secuencia, lo que hace es que en el primer intervalo de 0 al 40% crea una interpolacion
/// entre 5 a 10, luego se mantiene en 10 por el siguiente 20% y finalmente pasa de 10 a 5 con un curve
/// el ultimo 40%
final animation = TweenSequence<double>([
  TweenSequenceItem<double>(
    tween: Tween<double>(begin: 5.0, end: 10.0).chain(CurveTween(curve: Curves.ease)),
    weight: 40.0,
  ),
  TweenSequenceItem<double>(
    tween: ConstantTween<double>(10.0),
    weight: 20.0,
  ),
  TweenSequenceItem<double>(
    tween: Tween<double>(begin: 10.0, end: 5.0).chain(CurveTween(curve: Curves.ease)),
    weight: 40.0,
  ),
]);

/// El widget ColoredBox permite agregar unicamente un color de fondo a un widget 
// ColoredBox(
//   color: Colors.black,
//   child: SizedBox()
// )
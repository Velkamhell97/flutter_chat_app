import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

final _kFromRightTween = Tween<Offset>(begin: const Offset(1.0, 0.0),  end: Offset.zero);
final _kToLeftTween = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0));

const Color _kCupertinoPageTransitionBarrierColor = Color(0x18000000);

///------------------------------------------------
///---------------- CUSTOM CUPERTINO --------------
///------------------------------------------------
class CustomCupertinoPageTransition extends StatelessWidget {
  CustomCupertinoPageTransition({Key? key, required Animation<double> primaryRouteAnimation, required Animation<double> secondaryRouteAnimation, required this.child, required bool linearTransition}) 
  : _primaryPositionAnimation = (linearTransition
      ? primaryRouteAnimation
      : CurvedAnimation(
          parent: primaryRouteAnimation,
          curve: Curves.linearToEaseOut,
          reverseCurve: Curves.easeInToLinear,
        )
      ).drive(_kFromRightTween),
    _secondaryPositionAnimation = (linearTransition
      ? secondaryRouteAnimation
      : CurvedAnimation(
          parent: secondaryRouteAnimation,
          curve: Curves.linearToEaseOut,
          reverseCurve: Curves.easeInToLinear,
        )
      ).drive(_kToLeftTween),
    super(key: key);

  final Animation<Offset> _primaryPositionAnimation;
  final Animation<Offset> _secondaryPositionAnimation;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // print('Widget Builder');

    return SlideTransition(
      position: _secondaryPositionAnimation,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        child: child,
      ),
    );
  }
}

mixin CustomCupertinoRouteTransitionMixin<T> on PageRoute<T> {
  @protected
  Widget buildContent(BuildContext context);

  String? get title;

  ValueNotifier<String?>? _previousTitle;

  ValueListenable<String?> get previousTitle {
    assert(
      _previousTitle != null,
      'Cannot read the previousTitle for a route that has not yet been installed',
    );
    return _previousTitle!;
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    final String? previousTitleString = previousRoute is CustomCupertinoRouteTransitionMixin
      ? previousRoute.title
      : null;
    if (_previousTitle == null) {
      _previousTitle = ValueNotifier<String?>(previousTitleString);
    } else {
      _previousTitle!.value = previousTitleString;
    }
    super.didChangePrevious(previousRoute);
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Color? get barrierColor => fullscreenDialog ? null : _kCupertinoPageTransitionBarrierColor;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is CustomCupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget child = buildContent(context);
    return child;
  }

  static Widget buildPageTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    const bool linearTransition = true;

    // print('Transition Builder');
    
    return CustomCupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      child: child,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}

class CustomCupertinoPageRoute<T> extends PageRoute<T> with CustomCupertinoRouteTransitionMixin<T> {
  CustomCupertinoPageRoute({
    required this.builder,
    /// Propio de ios
    this.title,
    RouteSettings? settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog) {
    assert(opaque);
  }

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final String? title;

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}


///------------------------------------------------
///---------------- CUSTOM MATERIAL ---------------
///------------------------------------------------
mixin CustomMaterialRouteTransitionMixin<T> on PageRoute<T> {
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // Don't perform outgoing animation if the next route is a fullscreen dialog.
    return (nextRoute is CustomMaterialRouteTransitionMixin && !nextRoute.fullscreenDialog)
      || (nextRoute is CustomCupertinoRouteTransitionMixin && !nextRoute.fullscreenDialog);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget result = buildContent(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: result,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;

    // print('transition builder');

    // const open = OpenUpwardsPageTransitionsBuilder();
    // const zoom = ZoomPageTransitionsBuilder();
    // const slide = CupertinoPageTransitionsBuilder();
    // const fade = FadeUpwardsPageTransitionsBuilder();

    return theme.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
    // return open.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
    // return zoom.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
    // return fade.buildTransitions<T>(this, context, animation, secondaryAnimation, child);
    // return slide.buildTransitions<T>(this, context, animation, secondaryAnimation, child);

  }
}

class CustomMaterialPageRoute<T> extends PageRoute<T> with CustomMaterialRouteTransitionMixin<T> {
  CustomMaterialPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog) {
    assert(opaque);
  }

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}


///------------------------------------------------
///--------------- CUSTOM PAGERROUTE --------------
///------------------------------------------------
class SlidePageTransition extends StatelessWidget {
  final Widget child;

  final Animation<Offset> _primaryPositionAnimation;
  final Animation<Offset> _secondaryPositionAnimation;

  // CurvedAnimation(
  //   parent: primaryRouteAnimation,
  //   curve: Curves.linearToEaseOut,
  //   reverseCurve: Curves.easeInToLinear,
  // )

  // CurvedAnimation(
  //   parent: secondaryRouteAnimation,
  //   curve: Curves.linearToEaseOut,
  //   reverseCurve: Curves.easeInToLinear,
  // )

  SlidePageTransition({Key? key, required Animation<double> primaryRouteAnimation, required Animation<double> secondaryRouteAnimation, required this.child}) 
  : _primaryPositionAnimation = primaryRouteAnimation.drive(_kFromRightTween),
    _secondaryPositionAnimation = secondaryRouteAnimation.drive(_kToLeftTween),
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _secondaryPositionAnimation,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        child: child,
      ),
    );
  }
}

mixin SlideRouteTransitionMixin<T> on PageRoute<T> {
  /// Propiedad propia
  @protected
  Widget buildContent(BuildContext context);

  /// Propiedades del pageroute definidas en el mixin
  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Color? get barrierColor => fullscreenDialog ? null : _kCupertinoPageTransitionBarrierColor;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is SlideRouteTransitionMixin && !nextRoute.fullscreenDialog;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final Widget child = buildContent(context);
    return child;
  }

  static Widget buildPageTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlidePageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      child: child,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return buildPageTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}

class SlidePageRoute<T> extends PageRoute<T> with SlideRouteTransitionMixin<T> {
  SlidePageRoute({
    required this.builder,
    RouteSettings? settings,
    this.maintainState = true,
    bool fullscreenDialog = false,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog) {
    assert(opaque);
  }

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  final bool maintainState;

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}


///------------------------------------------------
///-------------- PAGE ROUTE EXAMPLE --------------
///------------------------------------------------
class SlideParallaxRouteBuilder extends PageRouteBuilder {
  final Widget child;

  SlideParallaxRouteBuilder({
    required this.child,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Duration reverseTransitionDuration = const Duration(milliseconds: 300)
  }) : super(
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => child
  );

  /// Returns true if [previousRoute] should animate when this route is pushed on top of it or when then this 
  /// route is popped off of it.
  /// 
  /// Si es true, la previousRoute debera animarse cuando esta ruta se coloce sobre ella (push) o cuando esta
  /// ruta se extraiga de ella (pop)
  /// 
  /// Subclasses can override this method to restrict the set of routes they need to coordinate transitions 
  /// with.
  /// 
  /// If true, and previousRoute.canTransitionTo() is true, then the previous route's 
  /// [ModalRoute.buildTransitions] secondaryAnimation will run from 0.0 - 1.0 when this route is pushed 
  /// on top of it. Similarly, if this route is popped off of [previousRoute] the previous route's 
  /// secondaryAnimation will run from 1.0 - 0.0.
  /// 
  /// Si es true y canTransitionTo es true, la animacion secundaria de la previousRoute pasara de 0 a 1 cuando
  /// esta ruta es colocada sobre ella (push) y pasara de 1 a 0 cuando esta ruta se extraida
  /// de la misma (pop)
  /// 
  /// If false, then the previous route's [ModalRoute.buildTransitions] secondaryAnimation value will be 
  /// kAlwaysDismissedAnimation. In other words [previousRoute] will not animate when this route is pushed
  /// on top of it or when then this route is popped off of it.
  /// 
  /// Si es falso la animacion secundaria de la previousRoute sera siempre kAlwaysDismissedAnimation, es decir
  /// la previousRoute no se animara cuando esta ruta se coloque sobre ella (push) o cuando esta ruta se extraiga
  /// de la misma (pop), la animacion de entrada primary animation siempre se ejecutara asi sea falso
  /// 
  /// Returns true by default.
  @override
  bool canTransitionFrom(TransitionRoute previousRoute) {
    return true;
    // return super.canTransitionFrom(previousRoute);
  }

  /// Returns true if this route supports a transition animation that runs when [nextRoute] is pushed on top of
  /// it or when [nextRoute] is popped off of it.
  /// 
  /// Si es true, esta ruta se animara cuando la nextRoute se coloca sobre esta (push), o cuando la nextRoute 
  /// se extraiga de esta (pop)
  /// 
  /// Subclasses can override this method to restrict the set of routes they need to coordinate transitions with.
  ///
  /// If true, and nextRoute.canTransitionFrom() is true, then the [ModalRoute.buildTransitions] 
  /// secondaryAnimation will run from 0.0 - 1.0 when [nextRoute] is pushed on top of this one. Similarly, 
  /// if the [nextRoute] is popped off of this route, the secondaryAnimation will run from 1.0 - 0.0.
  /// 
  /// Si es true y canTransitionFrom es true, la animacion secundaria de esta ruta pasa de 0 a 1 cuando nextRoute 
  /// es colocada sobre esta (push) y pasara de 1 a 0 cuando la nextRoute sea extraida de esta (pop)
  /// 
  /// If false, this route's [ModalRoute.buildTransitions] secondaryAnimation parameter value will be 
  /// [kAlwaysDismissedAnimation]. In other words, this route will not animate when [nextRoute] is pushed 
  /// on top of it or when [nextRoute] is popped off of it.
  /// 
  /// Si es false, la animacion secundaria siempre sera falsa, esta ruta no se animara cuando nextRoute
  /// es colocada sobre esta (push) o extaida de esta (pop), la animacion de entrada primary animation
  /// siempre se ejecutara asi sea falso
  ///
  /// Returns true by default.
  @override
  bool canTransitionTo(TransitionRoute nextRoute) {
    return true;
    // return nextRoute is SlideParallaxRouteBuilder && !nextRoute.fullscreenDialog;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final _primaryPositionAnimation = animation.drive(_kFromRightTween);
    final _secondaryPositionAnimation = secondaryAnimation.drive(_kToLeftTween);
 
    return SlideTransition(
      position: _secondaryPositionAnimation,
      child: SlideTransition(
        position: _primaryPositionAnimation,
        child: child,
      ),
    );
  }
}


/// No hay mucha diferencia entre el PageRoute y PageRouteBuilder, ya que ambos reciben los mismos argumentos
/// la unica diferencia esque el PageRoute al parecer se usa para animaciones mas personalizadas, si se va
/// a extender el PageRouteBuilder, no tendra diferencia con el PageRoute, mas que el primero asigna unas
/// variables por defecto, pero ambos tienen las mismas propiedades y se pueden sobreescribir los mismos, 
/// si se va a extender de un PageRouteBuilder, mejor extender del PageRoute ya que es lo mismo, el PageRouteBuilder
/// sirve pero cuando no se extiende sino que se utiliza la clase como tal, ademas segun los ejemplos, cuando 
/// se crea un custom route se utiliza un mixin para definir algunas propiedades por defecto y logica adicional
/// ademas se utiliza un stalesWidget que se le pasa al buildTransition, que contiene las animaciones de la 
/// transicion, sin embargo no se sabe si definir esto en forma de widget o directamente en el metodo tenga 
/// alguna ventaja uno sobre otro, siempre que se vaya a utilizar un nextRoute o previousRoute si se neceista
/// crear una clase propia
class FadeInSlideLeftOutPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  
  FadeInSlideLeftOutPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.maintainState = true,
    bool fullscreenDialog = false,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final position = secondaryAnimation.drive(_kToLeftTween);
    
    return SlideTransition(
      position: position,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;
}


///------------------------------------------------
///---------- CUSTOM PAGE ROUTE EXAMPLE -----------
///------------------------------------------------
class CustomPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  /// Para pasar solo clases de las transiciones, pero tambien se podrian devolver funciones que devuelvan
  /// widgets con los argumentos que recibe el transitionBuilder, los PageTransition basicamente son
  /// clases con un solo metodo que devuelve el StalessWidget con las animaciones de la transicion, aqui
  /// se inicializan las animaciones en el constructor, no se sabe si esto represente un beneficio que
  /// definir las animaciones (curves y demas) dentro del metodo
  final PageTransitionsBuilder transitionBuilder;

  CustomPageRoute({
    RouteSettings? settings,
    required this.builder,
    required this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.barrierDismissible = false,
    this.maintainState = true,
    this.barrierColor,
    this.barrierLabel,
    bool fullscreenDialog = false,
  }): super(settings:  settings, fullscreenDialog: fullscreenDialog);

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  final bool opaque;

  @override
  final bool barrierDismissible;

  @override
  final bool maintainState;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return transitionBuilder.buildTransitions(this, context, animation, secondaryAnimation, child);
  }
}
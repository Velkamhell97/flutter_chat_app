import 'package:flutter/material.dart';

/// No se sabe si declararlas por fuera tenga el mismo efecto de declararlas static dentro
final _kFromRightTween = Tween<Offset>(begin: const Offset(1.0, 0.0),  end: Offset.zero);
final _kToLeftTween = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0));
final _kFromBottomTween = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero);

/// En total se concluyen 3 formas de realizar custom routes:
/// 1. Creando un PageRoute y extenderle un mixin, este contiene algunas propiedades predefinas como el
/// transition duration y aqui tambien se modifica el metodoBuildPage para agregar algun Wrapper como 
/// semantics al pageBuilder, y tambien se modifica el buildTransitions en donde generalmente devuelven
/// un StalessWidget que recibe las animaciones y aqui aplican toda la logica, este widget se devuelve de
/// dos formas, la primera es creando un metodo estatico dentro del mixin que devuelva el StalessWidget
/// y pasando este metodo al buildTransitions o creando un TransitionBuilder que basicamente es una clase
/// que recibe las props del TransitionBuilder y las pasa al unico metodo que tiene que devuelve
/// el widget con esas props, al momento de crear las animaciones tambien se presentan dos casos
/// el primero es cuando se inicializan las animaciones en el constructor pero impide que el widget
/// sea constante y la segunda en donde dejan el widget constante e inicializan las animaciones en el metodo
/// build, para ambos casos los tween o curves se declaran de dos maneras, la primera dentro del widget
/// como static final y la segunda por fuera del staless como una top-level-variable.
/// Lo de escoger el metodo estatico para devolver el widget o el transitionBuilder no creo que afecte
/// mucho porque ambos devuelven el StalessWidget, ambos widget se redibujan varias veces durante el
/// build transitions, lo unico que podria llegar a considerarse esque el StalessWidget tenga un mejor
/// comportamiento o que cree algo de cache en las animaciones, pero este siempre se redibujara cuando
/// a medida que aumenta la animacion del TransitionBuilder, aun asi no se esta seguro que tanto puede 
/// afectar pasar un StalessWidget o pasar el widget de la transicion como tal (FooTransition), no se sabe 
/// si afecte mucho el lugar donde se inicializan las animaciones si en el contrustor (no const) o dentro 
/// del build (const) causa duda, tambien si se declaran los tween como top-leve-variables o como static final
/// dentro de la clase (creo que no afectaria).
/// 
/// 2. Se penso en construir un CustomPageRoute, que basicamente heredara todas las props del PageRouteBuilder
/// pero que recibiera un TransitionBuilder como parametro asi estos se crearian aparte, y se podria
/// pasar unicamente la el TransitionBuilder sin crear clases que exitiendan del PageRouteBuilder para cada
/// transicion diferente, el problema de esto esque de esta manera no se podrian compara las rutas en el
/// canTransitionTo y canTransitionFrom, en vez de clases TransitionBuilder, tambien se hubieran podido
/// declarar funciones que recibieran los argumentos del buildTransitions y devolviera el widget.
/// 
/// 3. La tercera forma y la que ofrece quizas mas control para las animaciones en ambos sentidos, es 
/// crear Clases que extiendan del PageRouteBuilder, a pesar de que se crea mucha redundancia pues solo
/// cambia el transitionBuilder, de esta manera podemos usar el canTransitionTo para sincronizar las
/// Animaciones de entrada y salida, aunque tampoco se sabe si sea la mejor solucion, tambien se podrian
/// crear que extiendan solo del PageRoute, no tienen mucha diferencia (al parecer)

///------------------------------------------------
///--------------- AUTH PAGE ROUTES ---------------
///------------------------------------------------
class FadeInRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadeInRouteBuilder({
    required this.child,
  }) : super(pageBuilder: (context, animation, secondaryAnimation) => child);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class SlideLeftInRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget child;

  SlideLeftInRouteBuilder({
    required this.child,
  }) : super(pageBuilder: (context, animation, secondaryAnimation) => child);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final popsition = animation.drive(_kFromRightTween);
    // print('Transition Builder');
    
    return SlideTransition(position: popsition, child: child);
    // return SlideWidget(animation: animation, child: child);
  }
}

class FadeInSlideLeftOutRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadeInSlideLeftOutRouteBuilder({
    required this.child
  }) : super(pageBuilder: (context, animation, secondaryAnimation) => child);

  /// Solo se aplica la secondaryAnimation si la siguiente ruta es un SlideLeftIn 
  @override
  bool canTransitionTo(TransitionRoute nextRoute) {
    return nextRoute is SlideLeftInRouteBuilder;
  }

  /// 1. No se sabe si es mejor los tween estaticos dentro de la clase o finales fuera 
  /// 2. Al parecer el .drive es mejor que el .animate 
  /// 3. No se sabe si sea mejor crear un metodo estatico que devuelva el StalessWidget como el cupertino,
  ///    o un TransitionBuilder como el material.
  /// 4. No se sabe si es mejor inicializar las animaciones en el constructor del StalessWidget en el punto 3
  ///    o en el build del mismo
  /// 5. No se sabe si es mejor utilizar uno de los metodos del punto 3, o pasar directamente el widget e
  ///    instanciar las animaciones dentro del buildTransitions.

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
}

class MaterialZoomPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  MaterialZoomPageRoute({
    required this.builder,
    RouteSettings? settings,
    this.maintainState = true,
    bool fullscreenDialog = false
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => Colors.white;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    /// Se modifico el codigo fuente, recordar que esto es temporal, si se actualiza la version de flutter o
    /// se borra el src de flutter estos cambios desapareceran, se deberia implementar la propia (copiar)
    const route = ZoomPageTransitionsBuilder(); 
    return route.buildTransitions(this, context, animation, secondaryAnimation, child);
  }

  @override
  final bool maintainState;
}


///------------------------------------------------
///--------------- CHAT PAGE ROUTES ---------------
///------------------------------------------------
class SlideBottomRouteBuilder extends PageRouteBuilder {
  final Widget child;
  final Tween<Offset>? position;

  SlideBottomRouteBuilder({
    required this.child,
    this.position,
    bool opaque = true,
    Color? barrierColor,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Duration reverseTransitionDuration = const Duration(milliseconds: 300)
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    opaque: opaque,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration
  );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final tween = position ?? Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero);
    
    return SlideTransition(
      position: tween.animate(animation),
      child: child,
    );
  }
}

/// Para el caso de los dialogs, como no hay una clase que extienda directamente del dialog, sino que esta
/// utiliza otra clase (RawDialogRoute), el mas tedioso intentar crear dialogs con transiciones personalizadas
/// por esta razon tenemos dos opciones utilizar un TransitionBuilder y el metodo buildTransition en el showDialog
/// o utilizar una funcion que devuelva el widget, no se sabe cual de las dos sera mejor, pero se cree que 
/// para animaciones sencillas es mas leible y corto utilizar la funcion, mientras que para transiciones 
/// mas complejas se podria utilizar el PageTransitionBuilder con su StalessWidget

///------------------------------------------------
///-------------- DIALOG PAGE ROUTES --------------
///------------------------------------------------
class FadeTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return _FadeTransition(animation: animation, child: child);
  }
}

class _FadeTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _FadeTransition({Key? key, required this.animation, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: animation, child: child);
  }
}


Widget dialogSlideTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  final position = animation.drive(_kFromBottomTween);

  return SlideTransition(
    position: position,
    child: child,
  );
}


/// Staless de prueba
// class SlideWidget extends StatelessWidget {
//   final Widget child;
//   final Animation<double> animation;
//
//   const SlideWidget({Key? key, required this.animation, required this.child}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // print('Widget Builder');
//     final popsition = animation.drive(_kFromRightTween);
//     return SlideTransition(position: popsition, child: child);
//   }
// }
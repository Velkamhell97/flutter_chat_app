import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const Duration _kMenuDuration = Duration(milliseconds: 300);
const double _kMenuCloseIntervalEnd = 2.0 / 3.0;
const double _kMenuHorizontalPadding = 16.0;
const double _kMenuMaxWidth = 5.0 * _kMenuWidthStep;
const double _kMenuMinWidth = 2.0 * _kMenuWidthStep;
const double _kMenuVerticalPadding = 8.0;
const double _kMenuWidthStep = 56.0;
const double _kMenuScreenPadding = 8.0;

const double kMinInteractiveDimension = 48.0;
const Duration kThemeChangeDuration = Duration(milliseconds: 200);

/// Clase utilizada para que otras clases implementen estos metodos
abstract class PopupMenuEntry<T> extends StatefulWidget {
  const PopupMenuEntry({ Key? key }) : super(key: key);

  double get height;

  bool represents(T? value);
}

/// Un Custom SingleRenderObject (solo 1 widget)
class _MenuItem extends SingleChildRenderObjectWidget {
  const _MenuItem({
    Key? key,
    required this.onLayout,
    required Widget? child,
  }) : super(key: key, child: child);

  /// Variable que se recibe en el widget
  final ValueChanged<Size> onLayout;

  /// El RenderObject es el que dibuja y posiciona el elemento
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuItem(onLayout);
  }

  /// Cuando debe redibujarse el RenderObject
  @override
  void updateRenderObject(BuildContext context, covariant _RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

/// Extiende de un tipo de RenderBox, el RenderProxyBox al parecer tiene un child y simplemente imita casi
/// todas las propiedades de ese child, es util para esos casos que el RenderObject imita propiedades del child
/// 
/// El RenderShiftBox a diferencia del anterior, tiene un tamaño propio asi como padding y permite controlar
/// la posicion del child
/// 
/// Finalmente el RenderObjectWithChildMixin, es un tipo de mixin que proveee metodos al RenderBox para
/// facilitar la construccion de RenderBox
class _RenderMenuItem extends RenderShiftedBox {
  _RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child == null) {
      return Size.zero;
    }
    return child!.getDryLayout(constraints);
  }

  @override
  void performLayout() {
    if (child == null) {
      size = Size.zero;
    } else {
      child!.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child!.size);
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Offset.zero;
    }
    onLayout(size);
  }
}

/// Clase principal del MenuItem que implementa los metodos del MenuEntry
class PopupMenuItem<T> extends PopupMenuEntry<T> {
  const PopupMenuItem({
    Key? key,
    this.value,
    this.onTap,
    this.enabled = true,
    this.height = kMinInteractiveDimension,
    this.padding,
    this.textStyle,
    this.mouseCursor,
    required this.child,
  }) : super(key: key);

  final T? value;

  final VoidCallback? onTap;

  final bool enabled;

  @override
  final double height;

  final EdgeInsets? padding;

  final TextStyle? textStyle;

  final MouseCursor? mouseCursor;

  final Widget? child;

  @override
  bool represents(T? value) => value == this.value;

  /// Metodo del StafullWidget pero en un estado mas puro
  @override
  PopupMenuItemState<T, PopupMenuItem<T>> createState() => PopupMenuItemState<T, PopupMenuItem<T>>();
}

class PopupMenuItemState<T, W extends PopupMenuItem<T>> extends State<W> {
  @protected
  Widget? buildChild() => widget.child;

  @protected
  void handleTap() {
    widget.onTap?.call();

    Navigator.pop<T>(context, widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    TextStyle style = widget.textStyle ?? popupMenuTheme.textStyle ?? theme.textTheme.subtitle1!;

    if (!widget.enabled) {
      style = style.copyWith(color: theme.disabledColor);
    }

    Widget item = AnimatedDefaultTextStyle(
      style: style,
      duration: kThemeChangeDuration,
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        constraints: BoxConstraints(minHeight: widget.height),
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: _kMenuHorizontalPadding),
        child: buildChild(),
      ),
    );

    if (!widget.enabled) {
      final bool isDark = theme.brightness == Brightness.dark;
      item = IconTheme.merge(
        data: IconThemeData(opacity: isDark ? 0.5 : 0.38),
        child: item,
      );
    }
    final MouseCursor effectiveMouseCursor = MaterialStateProperty.resolveAs<MouseCursor>(
      widget.mouseCursor ?? MaterialStateMouseCursor.clickable,
      <MaterialState>{
        if (!widget.enabled) MaterialState.disabled,
      },
    );

    return MergeSemantics(
      child: Semantics(
        enabled: widget.enabled,
        button: true,
        child: InkWell(
          onTap: widget.enabled ? handleTap : null,
          canRequestFocus: widget.enabled,
          mouseCursor: effectiveMouseCursor,
          child: item,
        ),
      ),
    );
  }
}

/// Child que se le pasa el SingleRenderObject que hace como widget principal de la navegacion
/// como no utilizamos el transicionBuilder en el PopupRoute, quizas para no modificar el SingleRenderObject
/// aplicamos las animaciones de transicion dentro del mismo widget, recordar que el SingleRederObject solo
/// es como un tipo de contenedor para el child, que puede modificar su posicion y tamaño.
/// 
/// Al momento del build lo que hace es calcular como un clamp (unit) que tomara para hacer los calculos
/// de los intervalos de opacidad que tendra cada item del menu como un tipo de amimacion stragger, luego
/// de tener los elementos del menu, procede a configurar la animacion y constrains del contenedor de ese
/// menu y de los elementos.
/// 
/// Aqui en el menu primero setea los tweens con los intervals en los que desea que se aplique cada cambio
/// de propiedad en especifico, estas animaciones seran utilizadas unicamente para la transicion ya que el
/// child no cambia y es el que esta definido despues que utiliza unos constrains (este child es el que) 
/// contendra el SingleRenderObject, luego un IntrisicWidt para limitar el widt a un valor en especifico 
/// o multiplo de este (stepWidt) unos semantics y finalmente un widget Scroll (no se sabe porque en vez)
/// de un ListView, finalmente viene el AnimatedBuilder que recibe la animacion del routeTransicion y en base
/// a ello porgrama un builder que seria como el TransitionBuilder del PageRoute
/// 
/// Este comienza con un FadeTransition cuyo intervalo es un 33% de la animacion, es decir, es rapida, luego
/// viene un material que le da el efecto de menu flotante con las propiedades correspondientes y finalmente
/// viene una animacion un tanto curiosa, y es el Align, si se utiliza el AlignDirectional junto con el 
/// widthFactor y Height factor se consigue un efecto peculiar.
/// 
/// En primer lugar lo que estos factores hacen, es hacer basicamente que el width del RenderObject del Align
/// que inicialmente es el valor original de su child se reduzca en un muliplo menor a 1, lo que causara un enco
/// gimiento del RenderObject del Align como tal, pero esto no provocara lo mismo en el child de este Align, ya 
/// que lo que hara con su child, es desplazarlo ya que el limite del contenedor se redujo, asi el child se
/// salga del RenderObject del Align no habra problema de Overflow, entonces causa un efecto de encogimiento en
/// el RenderObject del Align y de desplazamiento del child, este desplazamiento solo se puede hacer en un sentido
/// Vertical u horizontal y dependera de la propiedad alingnment 
/// 
/// Ahora bien para que el efecto del popup no es el de un desplazamiento sino como un resize diagonal y aqui
/// es doden entra en juego el padre del Align, ya que este si se ve afectado por los valores del widthFactor
/// y heightFactor pues este escucha los cambios del RenderObject del Align y no de su child, por lo que el Widget
/// padre del Align si sufrira ese resize diagonal que se busca, el material al ser un fondo blanco y con elevacion
/// da un efecto de crecimiento diagonal tal como un popup pero tambien puede ir cualquier otro widget que se
/// adapte al contenido de su child como un container con fondo, como se ve en los Curves se puede definir 
/// cual dimension crece mas rapido que otra para que sea un efecto mas personalizado.
/// 
/// Sin embargo existe un ultimo problema y es que si no utilizamos ningun tipo de animacion en el child, este
/// se vera como se dezplasa mientraas aparece su contendor en form de popup, lo cual no es el comportamiento deseado
/// pues se quiere que el child haga como si apareciera directamente dentro del RenderBox del align, ya estirado
/// Para ello lo que se hace es precisamente envolver a el child en un widget de opacity (FadeTransition) de manera
/// que primero se complete la animacion del widthFactor o heighFactor dependiendo el alignment para que cuando
/// empieze el FadeIn ya el desplazamiento se haya realizado y el child o lista de childs aparezcan ya dentro del
/// menu, que es lo que se hace en este ejemplo, como se puede ver el intervalo mas pequeño o unit es lo que
/// tarda en completarse al animacion del WidgFactor (que es el axis de desplazamiento con ese alignment),
/// el height factor puede tardar un poco mas porque no habra desplazamiento y los items aparecen secuencialmente
/// una vez termina la transicion del widhtFactor, empieza el de la opacidad de los elemntos, para que parezca
/// que ya estan ubicados
class _PopupMenu<T> extends StatelessWidget {
  const _PopupMenu({
    Key? key,
    required this.route,
    required this.semanticLabel,
  }) : super(key: key);

  final _PopupMenuRoute<T> route;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    /// Forma de crear una staggered animation cuando no se puede controlar el duration (ejemplo con lengh:5): 
    /// Lo primero que hay que hacer es obtener el factor de aumento de cada item, si se toma 1 / 5
    /// se obtendra una animacion secuencial pues cada salto sera de igual amplitud (0.2), si en vez de 
    /// 1/5 tomaramos 1/6 (amplitud 0.167), sobraria un ultimo salto pues los items son 5 (0.83), y es este espacio
    /// que se aprovecha para crear la animacion stragger, lo que se hace es alargar el final de cada animacion
    /// en una constante igual a el tiempo de sobra final entre el numero de elementos, asi se tomaria el (0.167)
    /// sobrante al final y se reparte entre los finales de cada item, de esta manera la animacion no seria secuencial
    /// pues al alargarse el final el inicio de las animaciones que si aumentan en saltos proporcionales comenzarian
    /// antes de que termine la animacion anterior con el final alargado, los intervalos en el ejemplo anterior serian
    /// 1: (0.0, 0.2004), 2: (0.167, 0.3674), 3: (0.334, 0.5344), 4: (0.501, 0.7014), 5: (0.668, 0.8684)
    /// Como se puede observar al final sigue sobrando el espacio inicial,  pues los puntos de inicio
    /// siguen siendo secuenciales, pero con el cambio de los puntos finales se crea un efecto stragger,
    /// con sumarle 1 al legth el numero de slots libres es de 1 (queda el ultimo intervalo) si se suma
    /// mas de 1, por ejemplo 1.5 quedara al final 1.5 intervalos sin completar, asi mismo se puede dividir
    /// este 1/6.5 (0.153) entre el numero de elementos (5) y encontrar el factor de alargamiento (0.03), y el ultimo
    /// intervalo pasaria de ((0.153 * 4 ) = 0.615), (0.615 + 0.153 + 0.03) = 0.798), como se observa entre
    /// mas aumentemos el denominador, las animaciones se hacen mas rapidas y el tiempo stragger entre elemntos
    /// se reduce, cuando decidimos la constante de alargamiento lo que hacemos es multiplicar el intervalo 
    /// (1/6.5) por al valor de (1/lengh) pero esto no siempre tiene que ser asi, por ejemplo si se multiplica
    /// por un valor de 1.0, el final siempre se alargara un intervalo, si se multiplica por 0.5, medio intervalo
    /// y asi, entonces podemos modificar dos cosas, el factor que se le suma a el denominador que deberia ser
    /// mayor que uno y el factor de multiplicacion del factor de alargamiento, de cualquier modo si se quiere
    /// que el ultimo intervalo cubra los intervalos sobrantes por el factor del denominador, la constante de
    /// alrgamiento debera ser de (1/(lenght + factor)) * (factor), de esta manera si el factor es 1, para lengt
    /// de 5, seria (1/6) * (1), como se dijo anteriormente y para un factor de 1.5, (1/6.5) * (1.5), 
    /// lo cual puede no crear animaciones stagger muy deseables.
    /// 
    /// Ahora bien para este ejemplo utilizan una de las animaciones mencionadas anteriormente, con la diferencia
    /// de que el primer intervalo se lo saltan para que lo utilice otra animacion (width), por lo que de por si
    /// ya se tiene un factor minimo de 1, para que cree un espacio adicional, con esto el primer intervalo es
    /// para el width animation y la animacion stagger empieza desde el intervalo 1 (sumandole 1 al i), con 
    /// este desfase, sin un factor stagger, la animacion se vuelve secuencial, ya que el intervalo que
    /// sobraba si estuvieran solo las animaciones stagger, se cubre con la animacion del width, ahora bien
    /// como se quiere hacer un stagger, se utiliza la tecnica de arriba, para los intervalos siguientes al primero
    /// entonces primero se define el factor stagger que se le sumara al 1 para crear un espacio adicional
    /// al creado con el +1 de la animacion del width, en este caso 0.5, con esto se crea medio intervalo adicional
    /// sobrante, con esto ya se puede repartir una constante entre los (end) de los intervalos para que se cree
    /// la animacion stagger, con esto unicamente falta definir el la constante de multiplicacion que multiplica
    /// el unit (o la division de 1 / length + 1 + factor), puede ser como se hizo anteriormente 
    /// (1 / legnt+1+factor) / length, o (unit * 0.2), pero en este caso en especifico en la que ya un intervalo
    /// sobrante lo ocupa el width animation, podemos asignar un factor de multiplicacion igual al factor stagger
    /// que acompaña al +1 del width, con esto lo que se logra es que en la ultima transicion se llegue al 1.0
    /// y no sobre mas tiempo, como se dijo arriba (1/(lenght + factor)) * (factor) hace que la anmacion termine 
    /// en 1.0, en este caso, como ya el +1 nos ocupa un intervalo solo necesitamos que la animacion final cubra
    /// el factor adicional al +1, pues es lo unico que va a sobrar (por el primero estar ocupado), entonces
    /// si lo multiplicamos por el factor (el unit o denominador), la animacion terminara en 1.0, esto unicamente
    /// afecta el alargamiento del (end) del intervalo, que puede modificarse segun gusto, mientras que el factor
    /// como tal, acorta los intervalos y hace mas rapida la animacion
    const double factor = 0.5; /// Staggered Factor
    final double unit = 1.0 / (route.items.length + 1 + factor); // 1.0 for the width and 0.5 for the last item's fade.
    final List<Widget> children = <Widget>[];
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    for (int i = 0; i < route.items.length; i += 1) {
      final double start = (i + 1) * unit;
      final double end = (start +  unit + (factor * unit)).clamp(0.0, 1.0);
      final CurvedAnimation opacity = CurvedAnimation(
        parent: route.animation!,
        curve: Interval(start, end),
      );
      Widget item = route.items[i];
      if (route.initialValue != null && route.items[i].represents(route.initialValue)) {
        item = Container(
          color: Theme.of(context).highlightColor,
          child: item,
        );
      }
      children.add(
        _MenuItem(
          onLayout: (Size size) {
            route.itemSizes[i] = size;
          },
          child: FadeTransition(
            opacity: opacity,
            child: item,
          ),
        ),
      );
    }

    final CurveTween opacity = CurveTween(curve: const Interval(0.0, 1.0 / 3.0)); /// 33%
    final CurveTween width = CurveTween(curve: Interval(0.0, unit)); /// primer intervalo
    final CurveTween height = CurveTween(curve: Interval(0.0, unit * route.items.length)); /// penultimo intervalo

    final Widget child = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _kMenuMinWidth,
        maxWidth: _kMenuMaxWidth,
      ),
      child: IntrinsicWidth(
        stepWidth: _kMenuWidthStep,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: semanticLabel,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: _kMenuVerticalPadding,
            ),
            child: ListBody(children: children),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: route.animation!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: opacity.animate(route.animation!),
          child: Material(
            shape: route.shape ?? popupMenuTheme.shape,
            color: route.color ?? popupMenuTheme.color,
            type: MaterialType.card,
            elevation: route.elevation ?? popupMenuTheme.elevation ?? 8.0,
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              widthFactor: width.evaluate(route.animation!),
              heightFactor: height.evaluate(route.animation!),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Delegate que hace las funciones del SingleChildRenderObject, es decir, calcular la posicion y el tamaño
/// que tendra su widget child esto es un poco mas complejo ya que interviene varios calculos para encontrar
/// una posicion que no vaya a exceder el espacio disponible en la pantalla y tambien otras cosas como si 
/// hay elementos seleccionados, o la posicion que pasamos al inicio. por ultimo tambien dedice cuando
/// se debe redibujar
class _PopupMenuRouteLayout extends SingleChildLayoutDelegate {
  _PopupMenuRouteLayout(
    this.position,
    this.itemSizes,
    this.selectedItemIndex,
    this.textDirection,
    this.padding,
  );

  final RelativeRect position;

  List<Size?> itemSizes;

  final int? selectedItemIndex;

  final TextDirection textDirection;

  EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest).deflate(
      const EdgeInsets.all(_kMenuScreenPadding) + padding,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double buttonHeight = size.height - position.top - position.bottom;
    // Find the ideal vertical position.
    double y = position.top;
    if (selectedItemIndex != null) {
      double selectedItemOffset = _kMenuVerticalPadding;
      for (int index = 0; index < selectedItemIndex!; index += 1) {
        selectedItemOffset += itemSizes[index]!.height;
      }
      selectedItemOffset += itemSizes[selectedItemIndex!]!.height / 2;
      y = y + buttonHeight / 2.0 - selectedItemOffset;
    }

    double x;
    if (position.left > position.right) {
      x = size.width - position.right - childSize.width;
    } else if (position.left < position.right) {
      x = position.left;
    } else {
      switch (textDirection) {
        case TextDirection.rtl:
          x = size.width - position.right - childSize.width;
          break;
        case TextDirection.ltr:
          x = position.left;
          break;
      }
    }

    if (x < _kMenuScreenPadding + padding.left) {
      x = _kMenuScreenPadding + padding.left;
    } else if (x + childSize.width > size.width - _kMenuScreenPadding - padding.right) {
      x = size.width - childSize.width - _kMenuScreenPadding - padding.right  ;
    }
    if (y < _kMenuScreenPadding + padding.top) {
      y = _kMenuScreenPadding + padding.top;
    } else if (y + childSize.height > size.height - _kMenuScreenPadding - padding.bottom) {
      y = size.height - padding.bottom - _kMenuScreenPadding - childSize.height ;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_PopupMenuRouteLayout oldDelegate) {
    assert(itemSizes.length == oldDelegate.itemSizes.length);

    return position != oldDelegate.position
      || selectedItemIndex != oldDelegate.selectedItemIndex
      || textDirection != oldDelegate.textDirection
      || !listEquals(itemSizes, oldDelegate.itemSizes)
      || padding != oldDelegate.padding;
  }
}


/// Esta clase personalizada que extiende del PopupRoute, lo unico que hace es implementar el PopupRoute
/// e implementando los metodos y variables que se necesitan para mostrar el menu, como el buildPage
/// que no retorna un widget comun y corriente sino un SingleRenderObject personalizado, y por esa misma
/// razon no utiliza el transitionBuilder sino que implementa la transicion dentro del child, ademas
/// de que recibe parametros propios que no reciben los PageRoute normalmente es un uso mas avanzado 
/// tambien podemos hasta cambiar la animacion o controlador de la route transicion con el createAnimation
/// recodar que lo que regresa el buildPage es el widget al que se navegara en forma de overlay que es la 
/// caracteristica del poproute, generalmente cuando se utiliza este los widgets son mas pequeños, y tienen
/// animaciones mas personalizadas por eso se crea un PageRoute propio un SingleRenderObject propio
class _PopupMenuRoute<T> extends PopupRoute<T> {
  _PopupMenuRoute({
    required this.position,
    required this.items,
    this.initialValue,
    this.elevation,
    required this.barrierLabel,
    this.semanticLabel,
    this.shape,
    this.color,
    required this.capturedThemes,
  }) : itemSizes = List<Size?>.filled(items.length, null);

  final RelativeRect position;
  final List<PopupMenuEntry<T>> items;
  final List<Size?> itemSizes;
  final T? initialValue;
  final double? elevation;
  final String? semanticLabel;
  final ShapeBorder? shape;
  final Color? color;
  final CapturedThemes capturedThemes;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: super.createAnimation(),
      curve: Curves.linear,
      reverseCurve: const Interval(0.0, _kMenuCloseIntervalEnd),
    );
  }

  @override
  Duration get transitionDuration => _kMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {

    int? selectedItemIndex;
    if (initialValue != null) {
      for (int index = 0; selectedItemIndex == null && index < items.length; index += 1) {
        if (items[index].represents(initialValue)) {
          selectedItemIndex = index;
        }
      }
    }

    final Widget menu = _PopupMenu<T>(route: this, semanticLabel: semanticLabel);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _PopupMenuRouteLayout(
              position,
              itemSizes,
              selectedItemIndex,
              Directionality.of(context),
              mediaQuery.padding,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}


/// Finalmente esta funcion lo unico que hace es capturar algunas variables necesarias del popmenu y solo
/// hace la navegacion con el PopRoute personalizado para este tipo de menus, desde aqui ya comienza todo el 
/// proceso explicado en las secciones de arriba, en el paquete animations, hay un metodo de showModal que
/// permite hacer cosas similares pero con widgets mas generales dando un efecto de transicion modal, util por
/// ejemplo para utilizarlo junto con hero animation, pero no se podria establecer una posicion de donde aparece
/// el widget asi como en este caso
Future<T?> showMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
  T? initialValue,
  double? elevation,
  String? semanticLabel,
  ShapeBorder? shape,
  Color? color,
  bool useRootNavigator = false,
}) {
  assert(debugCheckHasMaterialLocalizations(context));

  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      break;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      semanticLabel ??= MaterialLocalizations.of(context).popupMenuLabel;
  }

  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(_PopupMenuRoute<T>(
    position: position,
    items: items,
    initialValue: initialValue,
    elevation: elevation,
    semanticLabel: semanticLabel,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    shape: shape,
    color: color,
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
  ));
}
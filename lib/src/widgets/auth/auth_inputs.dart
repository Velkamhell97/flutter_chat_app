import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../../styles/styles.dart';
import '../../models/country.dart';
import '../../singlentons/locales_service.dart';
import 'countries_list.dart';

///---------------------------------
/// PASSWORD INPUT
///---------------------------------
class PasswordInput extends StatefulWidget {
  final Function(String)? onPasswordChanged;
  final String? Function(String?)? validator;
  final String? hint;

  const PasswordInput({Key? key, this.onPasswordChanged, this.validator, this.hint}) : super(key: key);

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool show = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: show,
      decoration: InputStyles.authInput.copyWith(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => show = !show),
          child: show ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
        )
      ),
      onChanged: widget.onPasswordChanged,
      validator: widget.validator
    );
  }
}

///---------------------------------
/// PHONE INPUT
///---------------------------------
class PhoneInput extends StatefulWidget {
  final String? initialValue;
  final Function(String)? onPhoneChanged;
  final Function(Country)? onCountryChanged;

  const PhoneInput({Key? key, this.initialValue, this.onPhoneChanged, this.onCountryChanged}) : super(key: key);

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  final _locale = LocalesService();
  late final ValueNotifier<Country?> _countryNotifier;
  
  // final _inputKey = GlobalKey();
  /// Height por defecto de un input, se podria dejar este o cambiar con el globalKey
  final double _maxHeight = 59.0;

  @override
  void initState() {
    super.initState();

    _countryNotifier = ValueNotifier<Country?>(_locale.country);

    /// Para que no cambie el height del country si aparece un error en el input se utiliza un globalKey
    /// que no son optimos y un setState que redibuja todo, pero este widget no es tan pesado
    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    //   final size = _inputKey.currentContext!.size!;
    //   setState(() => _maxHeight = size.height);
    // });
  }

  Future<void> _onTap() async {
    final country = await showModalBottomSheet<Country>(
      context: context, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: CountriesList(
            countries: _locale.countries,
            grouped: _locale.grouped,
            onCountryChanged: (country) => Navigator.of(context).pop(country),
          )
        );
      }
    );

    if(country != null){
      _countryNotifier.value = country;

      if(widget.onCountryChanged != null){
        widget.onCountryChanged!(country);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Se utilizaba un intrisicHeight pero si habia un error en el input este crecia, con un constrainedbox
    /// no funciono, no respetaba los limites, por lo que se utilizo el heihgt por defecto del input
    /// puede que con dispositivos mas grandes o pequeños se vea diferente, y utiliza el globalKey para actualizar
    /// el size,
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ///-------------------------------
        /// Country Flag
        ///-------------------------------
        ValueListenableBuilder<Country?>(
          valueListenable: _countryNotifier, 
          builder: (_, country, __) {
            /// Cuando se utilice siempre tendra valor
            final flag = 'assets/flags/${country?.iso2.toLowerCase()}.png';

            return SizedBox(
              height: _maxHeight,
              child: ElevatedButton.icon(
                style: ButtonStyles.countryButton,
                onPressed: _onTap, 
                icon: SizedBox(
                  width: 28, 
                  child: country == null ? const Icon(Icons.flag) : Image.asset(flag)
                ), 
                label: Text(
                  country == null ? '+XX' : country.code, 
                  style: TextStyles.countryCode
                )
              ),
            );
          }
        ),

        ///-------------------------------------
        /// Spacing
        ///-------------------------------------
        const SizedBox(width: 10.0),

        ///-------------------------------
        /// Number Input
        ///-------------------------------
        Flexible(
          child: TextFormField(
            // key: _inputKey,
            initialValue: widget.initialValue,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.phone,
            decoration: InputStyles.authInput.copyWith(
              hintText: 'Phone',
              prefixIcon: const Icon(Icons.phone),
            ),
            onChanged: widget.onPhoneChanged,
            validator: (value) => (value ?? '').length > 5 ? null : 'The phone is required',
          ),
        )
      ],
    );
  }
}

///---------------------------------
/// CODE INPUT
///---------------------------------
class CodeInput extends StatefulWidget {
  final int codeLength;
  final void Function(String code)? onCodeChanged;
  final String? autoCode;

  const CodeInput({Key? key, this.onCodeChanged, this.codeLength = 5, this.autoCode}) : super(key: key);

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  late final List<FocusNode> _focuses;
  late final List<TextEditingController> _controllers;
  
  List<String> _code = [];

  @override
  void initState() {
    super.initState();

    _code = List.filled(widget.codeLength, '');

    /// Tener cuidado con el list.filled pues pasa la misma referencia para todos los elementos
    _controllers = List.generate(widget.codeLength, (_) => TextEditingController());

    _focuses = List.generate(widget.codeLength, (index) => FocusNode(
      onKey: (node, event) {
        if(event.logicalKey == LogicalKeyboardKey.backspace && index != 0){
          node.previousFocus();
        }
        return KeyEventResult.handled;
      }
    ));
  }

  @override
  void didUpdateWidget(covariant CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Es necesario el microTask porque el cambiar el texto provoca que se redibuje el textfield y 
    /// choque con el rebuild del provocado por este metodo, entonces es necesario esperar a que este pase
    /// tambien se podria utilizar en el build, pero creo que tiene mejor sintaxis aqui 
    if(widget.autoCode != null){
      Future.microtask(() {
        final max = min(widget.autoCode!.length, widget.codeLength);

        for (int i = 0; i < max; i++) {
          _controllers[i].text = widget.autoCode![i];
        }
      });
    }
  }

  @override
  void dispose() {
    for(final node in _focuses){
      node.dispose();
    }

    for(final controller in _controllers){
      controller.dispose();
    }

    super.dispose();
  }

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        final width = constrains.maxWidth / widget.codeLength;

        return  Wrap(
          spacing: _gap,
          children: List.generate(widget.codeLength, (index) {
            return SizedBox(
              width: width - _gap,
              child: TextFormField(
                /// Tambien se pudo crear textController directamente en los elementos y pasarles el 
                /// widget.autoFill[index] como valor inicial, pero no se sabe si esto crearia muchas
                /// referencias del textController, o al menos si se dispongan estas
                controller: _controllers[index],
                focusNode: _focuses[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                buildCounter: (_, {int? currentLength, bool? isFocused, int? maxLength}) => null,
                onChanged: (value) {
                  _code[index] = value;
                  
                  if(value.isNotEmpty){
                    /// Si llega al final hara focus en otro elemento puede ser in input o boton
                    _focuses[index].nextFocus();
                  }
                  
                  if(widget.onCodeChanged != null){
                    widget.onCodeChanged!(_code.join(''));
                  }
                },
                decoration: InputStyles.codeInput,
                showCursor: false,
                validator: (value) => (value ?? '').isNotEmpty ? null : '',
              ),
            );
          }),
        );
      }
    );
  }
}
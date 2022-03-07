import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/providers.dart';

class CodeInput extends StatefulWidget {
  final ResetFormProvider form;

  const CodeInput({Key? key, required this.form}) : super(key: key);

  @override
  State<CodeInput> createState() => _CodeInputState();
}

//-Se puede dejar como un staless si no se necesita el refresh para los focus
class _CodeInputState extends State<CodeInput> {
  late final List<FocusNode> _focuses;

  @override
  void initState() {
    super.initState();

    _focuses = List.generate(5, (index) => FocusNode(
      onKey: (node, event) {
        if(event.isKeyPressed(LogicalKeyboardKey.backspace) && index != 0){
          node.previousFocus();
          // widget.form.refresh();
        }
        return KeyEventResult.ignored;
      }
    ));
  }

  @override
  void dispose() {
    for(final node in _focuses){
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        // final border = widget.form.code[index].isEmpty; //-Para eliminar borde

        return Flexible(
          child: Row(
            children: [
              Flexible(
                child: TextFormField(
                  focusNode: _focuses[index],
                  // textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  buildCounter: (context, {int? currentLength, bool? isFocused, int? maxLength}) => null,
                  onChanged: (value) {
                    widget.form.uploadToken(index, value);
                    
                    if(value.isNotEmpty && index != 4){
                      _focuses[index].nextFocus();
                    }
                  },
                  decoration: const InputDecoration(
                    //-Se pierde un poco el usuario
                    // enabledBorder: border ? null : InputBorder.none,
                    // focusedBorder: border ? null : InputBorder.none, 
                    errorStyle: TextStyle(fontSize: 0)
                  ),
                  // showCursor: false,
                  validator: (value) => (value ?? '').isNotEmpty ? null : '',
                ),
              ),
              if(index != 4)
                const SizedBox(width: 10.0)
            ],
          ),
        );
      }),
    );
  }
}
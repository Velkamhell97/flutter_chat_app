import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../styles/styles.dart';
import '../../extensions/string_apis.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../forms/code_confirm_form.dart';
import '../../widgets/auth/auth.dart';

class CodeConfirmPage extends StatelessWidget {
  final AuthProvider form;

  const CodeConfirmPage({Key? key, required this.form}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _message = 'Enviamos un codigo al numero  ${form.phone["number"]!.hidde(3, -2)} por favor ingresalo para continuar';

    return WillPopScope(
      onWillPop: () async {
        context.read<AuthService>().cancelRequest();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            /// Con esto evitamos la necesidad de crear un nuevo provider ya que variables se comparten entre
            /// estos dos form, el unico inconveniente esque se tiene que tener en cuenta que lo que pasa en
            /// una pantalla puede cambiar en la otra, por ejemplo el loading es necesario cancelarlo antes
            /// de llegar a esta pantalla, pero al mismo tiempo es muy util porque para el caso del autocompletado
            /// del codigo SMS, podemos manejar los valores del formlario de esta pagina, desde la anterior
            /// donde se escucha este evento, el unico inconveniente esque como El authForm original y el value
            /// se encuentran en el mismo nivel del tree (se pasa como argumento el value), se debe tener cuidado
            /// al momento de eliminar las rutas anteriores, porque primero se debe eliminar la ruta que maneja
            /// el value, antes que la que maneja el original, entonces si hacemos un popUntil o intetamos remover
            /// las rutas anteriores como el caso en el que se pasa del new-user al login, habra un error, pues
            /// estos metodos eliminan las rutas de atras para adelante, eliminando primero el authForm original
            /// para solucionar esto, nos encargamos de eliminar primero la ruta del value (esta) con el pushReplacement
            /// y en la siguiente ruta manejamos el PushAndRemoveUntil para borrar todo el historial, no es una
            /// completamente convincente pero funciona bien
            /// 
            /// Otras alternativas seria utilizar un PageView o AnimatedSwitcher para manejar un solo AuthProvider
            /// o utilizar un nuevo AuthProvider solo para este formulario del codigo y pasarle los datos del phone
            /// por los arguments, el problema de esto es que no se podria manejar un formulario desde otro
            /// finalmente podriamos usar un Navigator, para crear una subnavegacion de estas dos pantallas 
            /// y poder colocar un solo AuthProvider en un nivel mas alto, hacer un nestedNavigation para esto
            /// quiazas sea mas de lo necesario
            child: ChangeNotifierProvider<AuthProvider>.value(
              // create: (_) => AuthFormProvider(phone: form.phone),
              value: form,
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      ///-------------------------------------
                      /// SPACING
                      ///-------------------------------------
                      const SizedBox(height: 10.0),
    
                      ///-------------------------------------
                      /// HEADER
                      ///-------------------------------------
                      const LogoHeader(text: 'Code Confirmation'),
    
                      ///-------------------------------------
                      /// TEXT
                      ///-------------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(_message, style: TextStyles.body2),
                      ),
    
                      ///-------------------------------------
                      /// FORM
                      ///-------------------------------------
                      const CodeConfirmForm(),
                      
                      const Spacer(),
                      
                      ///-------------------------------------
                      /// FOOTER
                      ///-------------------------------------
                      const CodeConfirmationFooter(),
    
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


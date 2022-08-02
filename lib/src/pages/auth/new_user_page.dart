import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../forms/new_user_form.dart';
import '../../widgets/auth/auth.dart';
import '../../singlentons/singlentons.dart';

class NewUserPage extends StatefulWidget {
  const NewUserPage({Key? key}) : super(key: key);

  @override
  State<NewUserPage> createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  final _sp = SP();

  @override
  void didChangeDependencies() {
    /// Esta pantalla es el unico input obligatorio por el que tiene que pasar con cualquier tipo de registro
    /// aqui guardamos el height del keyboard inicial, porque hay veces la libreria no detecta los primeros cambios
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if(bottomInset != 0.0){
      _sp.keyboardHeight = bottomInset;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        /// Como es la unica pantlla en el stack del navigator si salimos vamos al background y al volver
        /// se ejecutara la validacion del token llevandonos al home del chat, para evitar eso si salimos
        /// cerramos session
        context.read<AuthService>().cancelRequest();
        context.read<AuthService>().signout();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          // resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(),
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      ///---------------------------
                      /// SPACING
                      ///---------------------------
                      const SizedBox(height: 15.0),
      
                      ///---------------------------
                      /// FORM
                      ///---------------------------
                      const NewUserForm(),
      
                      ///---------------------------
                      /// SPACING
                      ///---------------------------
                      const Spacer(),
      
                      ///---------------------------
                      /// FOOTER
                      ///---------------------------
                      FooterBackButton(
                        onPressed: () {
                          context.read<AuthService>().signout();
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                        },
                      ),
      
                      //---------------------------
                      /// SPACING
                      ///---------------------------
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


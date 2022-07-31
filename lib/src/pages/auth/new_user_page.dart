import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../forms/forms.dart';
import '../../services/services.dart';
import '../../widgets/auth/auth.dart';

class NewUserPage extends StatelessWidget {
  const NewUserPage({Key? key}) : super(key: key);

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
            child: ChangeNotifierProvider<AuthFormProvider>(
              create: (_) => AuthFormProvider(),
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


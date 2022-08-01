import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../styles/styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../forms/reset_password_form.dart';
import '../../widgets/auth/auth.dart';

class ResetPasswordPage extends StatelessWidget {
  final String? email;

  const ResetPasswordPage({Key? key, this.email}) : super(key: key);
  
  static const _message = 'Ingresa tu correo para continuar con el proceso de restauracion de la contraseña';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        /// Si no se esta haciendo una peticion, no hace nada, recordar que los pop deben ser maybePop
        context.read<AuthService>().cancelRequest();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: ChangeNotifierProvider(
            create: (_) => AuthProvider(email: email),
            child: SafeArea(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      ///-------------------------------------
                      /// SPACING
                      ///-------------------------------------
                      const SizedBox(height: 10.0),
    
                      ///-------------------------------------
                      /// HEADER
                      ///-------------------------------------
                      const LogoHeader(text: 'Reset Password'),
    
                      ///-------------------------------------
                      /// TEXT
                      ///-------------------------------------
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(_message, style: TextStyles.body2),
                      ),
    
                      ///-------------------------------------
                      /// FORM
                      ///-------------------------------------
                      const ResetPasswordForm(),
                      
                      ///-------------------------------------
                      /// SPACING
                      ///-------------------------------------
                      const Spacer(),
                      
                      ///-------------------------------------
                      /// FOOTER
                      ///-------------------------------------
                      FooterBackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),

                      ///-------------------------------------
                      /// SPACING
                      ///-------------------------------------
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          )
        ),
      ),
    );
  }
}
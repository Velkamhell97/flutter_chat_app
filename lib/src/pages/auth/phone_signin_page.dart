import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../forms/forms.dart';
import '../../styles/styles.dart';
import '../../widgets/auth/auth.dart';

class PhoneSigninPage extends StatelessWidget {
  const PhoneSigninPage({Key? key}) : super(key: key);

  static const _message = 'Ingresa tu numero de telefono y para enviar un sms y autenticar tu inicio de session';

  @override
  Widget build(BuildContext context) {
    /// Aqui no hacemos ninguna peticion al backend, por lo que no es necesario las validacioens del willPopScope
    /// ni del error que se podria validar es el mounted, para que no vayan a haber problemas si se envia el
    /// mensaje y sale de la pantalla
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: ChangeNotifierProvider(
            create: (context) => AuthFormProvider(),
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
                    const LogoHeader(text: 'Phone Signin'),

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
                    const PhoneSigninForm(),

                    const Spacer(),
                    
                    ///-------------------------------------
                    /// FOOTER
                    ///-------------------------------------
                    FooterBackButton(
                      onPressed: () => Navigator.of(context).pop(),
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
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../styles/styles.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../models/error_response.dart';
import '../pages/auth/code_confirm_page.dart';
import '../widgets/auth/auth_inputs.dart';
import '../widgets/transitions/page_routes.dart';

class PhoneSigninForm extends StatefulWidget {
  const PhoneSigninForm({Key? key}) : super(key: key);

  @override
  State<PhoneSigninForm> createState() => _PhoneSigninFormState();
}

/// Se utiliza un stafull para el metodo mounted
class _PhoneSigninFormState extends State<PhoneSigninForm> {
  Future<void> _onCodeAutoFill(PhoneAuthCredential credentials, AuthProvider form) async {
    form.smsCode = credentials.smsCode;
    
    final auth = context.read<AuthService>();

    final error = await auth.signinWithPhone(credentials);

    if(error == null){
      if(auth.user?.name == null){
        /// A pesar que estoy en una vista anterior se puede navegar desde esta pantalla, lo normal
        /// seria que se necesitara el navigatorKey
        Navigator.of(context).pushReplacementNamed('/new-user');
      } else {
        Navigator.of(context).pushReplacementNamed('/users');
      }
    } else if(error.code != 'cancel') {
      /// Aqui se decide no parar el loading, solo no mostrar el error
      form.error = error;
    }
  }

  void _onCodeSent(String verificationId, int? resendingToken, AuthProvider form) {
    form.loading = false;

    form.phone["verificationId"] = verificationId;
    form.phone["resendToken"] = resendingToken.toString();

    /// Probablemente no sea necesario pues, el mensaje le llegara de todos modos sin necesidad de decirle
    /// tambien se podria mostrar un snackbar al enviar el codigo junto con la navegacion para que
    /// se muestre apenas entre a la otra pantalla, o en la otra pantalla apenas se entre mostrar
    /// ese dialog personalizado
    if(mounted){
      // Navigator.of(context).pushNamed('/code-confirmation', arguments: form);
      final route = SlideLeftInRouteBuilder(child: CodeConfirmPage(form: form));
      Navigator.of(context).push(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification code was sent to ${form.phone["number"]}'))
      );
    }
  }

  void _sendSMS(AuthProvider form) {
    if(form.loading) return;
                  
    form.error = null;
    
    FocusScope.of(context).unfocus();

    if(!form.validate()) return;

    form.loading = true;

    /// El problema de crear una funcion para aislar este metodo esque este metodo es asincrono
    /// y tiene unos callbacks tambien asincronos que al resolverse en diferente orden, no sirve
    /// hacer un await por lo que debemos manejar manualmente que pasa en cada proceso
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: form.fullPhone, 
      verificationCompleted: (credentials) => _onCodeAutoFill(credentials, form), 
      verificationFailed: (error) => form.error = ErrorResponse.fromObject(error), 
      codeSent: (vId, rT) => _onCodeSent(vId, rT, form), 
      codeAutoRetrievalTimeout: (verificationId) {}, ///No necesario en esta pantalla
      timeout: Duration(seconds: form.otpTimeout)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, form, __) {
        return Form(
          key: form.key,
          child: Column(
            children: [
              ///------------------------------------
              /// Phone Input
              ///------------------------------------
              PhoneInput(
                onCountryChanged: (value) => form.country = value,
                onPhoneChanged: (value) => form.phone["number"] = value,
              ),

              ///------------------------------------
              /// Error Text
              ///------------------------------------
              if(form.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(form.error!.message, style: TextStyles.formError, textAlign: TextAlign.center),
                ),
              
              ///------------------------------------
              /// Spacing
              ///------------------------------------
              const SizedBox(height: 20.0),
              
              ///------------------------------------
              /// Submit Button
              ///------------------------------------
              ElevatedButton(
                style: ButtonStyles.authButton,
                onPressed: () => _sendSMS(form), 
                child: SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    child: form.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send SMS', style: TextStyles.button)
                  ),
                )
              )
            ],
          ),
        );
      },
    );
  }
}
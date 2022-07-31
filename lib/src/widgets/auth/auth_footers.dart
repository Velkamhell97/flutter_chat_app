// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../styles/styles.dart';
import '../../services/services.dart';
import '../../pages/auth/auth.dart';
import '../transitions/transitions.dart';
import 'auth.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({Key? key}) : super(key: key);

  Future<void> _googleSingin(BuildContext context, AuthFormProvider form) async {
    form.error = null;

    final dialogs = context.read<DialogsService>();

    /// En vez de utilizar un stack mostramos un overlay, falta manejar el willpop
    final entry = OverlayEntry(
      builder: (context) {
        return const Positioned.fill(
          child: ColoredBox(
            color: Colors.black38,
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          )
        );
      }
    );

    dialogs.showOverlay(entry);

    final auth = context.read<AuthService>();

    final error = await auth.signinWithGoogle();

    if(error == null){
      if(auth.user?.name == null){
        Navigator.of(context).pushReplacementNamed('/new-user');
      } else {
        Navigator.of(context).pushReplacementNamed('/users');
      }
    } else if(error.code != 'cancel') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign in canceled'))
      );

      form.error = error;
    }

    dialogs.removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFormProvider>(
      builder: (context, form, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ///----------------------------------
            /// Text Divider
            ///----------------------------------
            const TextDivider(text: 'Or'),
            
            ///----------------------------------
            /// Spacing
            ///----------------------------------
            const SizedBox(height: 15.0),
            
            ///----------------------------------
            /// Phone Or Google Sinin
            ///----------------------------------
            Row(
              children: [
                Expanded(
                  child: PhoneButton(
                    onPress: form.loading ? null : () {
                      form.error = null;
                      const child = PhoneSigninPage();
                      Navigator.of(context).push(MaterialZoomPageRoute(builder: (_) => child));
                    }
                  )
                ),

                const SizedBox(width: 10.0),
                
                Expanded(
                  child: GoogleButton(
                    onPress: form.loading ? null : () => _googleSingin(context, form)
                  ),
                )
              ],
            ),
            
            const Spacer(),

            ///----------------------------------
            /// Register Link
            ///----------------------------------
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                onPressed: form.loading ? null : () {
                  form.error = null;
                  final child = RegisterPage(email: form.body["email"]);
                  Navigator.of(context).push(SlideLeftInRouteBuilder(child: child));
                } , 
                icon: const Text('Register'),
                label: FaIcon(FontAwesomeIcons.arrowRight, size: 20, color: Colors.blue.shade300),
              ),
            ),
          ],
        );
      },
    );
  }
}


class RegisterFooter extends StatelessWidget {
  const RegisterFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<AuthFormProvider, bool>(
      selector: (_, model) => model.loading,
      builder: (_, loading, __) {
        return Align(
          alignment: Alignment.bottomLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
            onPressed: loading ? null : () => Navigator.of(context).maybePop(), 
            label: const Text('Login'),
            icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 20, color: Colors.blue.shade300,),
          ),
        );
      },
    );
  }
}


class FooterBackButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const FooterBackButton({Key? key, this.title = 'Back to login', this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<AuthFormProvider, bool>(
      selector: (_, model) => model.loading,
      builder: (_, loading, __) => TextButton(
        onPressed: loading ? null : onPressed,
        child: const Text('Back to login', style: TextStyles.button)
      )
    );
  }
}


class CodeConfirmationFooter extends StatelessWidget {
  const CodeConfirmationFooter({Key? key}) : super(key: key);

  Future<void> _onCodeAutoFill(BuildContext context, PhoneAuthCredential credentials, AuthFormProvider form) async {
    form.smsCode = credentials.smsCode;
    
    final auth = context.read<AuthService>();

    final error = await auth.signinWithPhone(credentials);

    if(error == null){
      if(auth.user?.name == null){
        Navigator.of(context).pushReplacementNamed('/new-user');
      } else {
        Navigator.of(context).pushReplacementNamed('/users');
      }
    } else if(error.code != 'cancel') {
      form.error = error;
    }
  }

  void _onCodeSent(BuildContext context, String verificationId, int? resendingToken, AuthFormProvider form){
    form.phone["verificationId"] = verificationId;
    form.phone["resendToken"] = resendingToken.toString();
    
    /// Al volver a redibujar se mantiene en true
    form.tokenSent = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mensaje enviado al ${form.phone["number"]}'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFormProvider>(
      builder: (context, form, __) {
        return Column(
          children: [
            ///----------------------------------
            /// Timer Resend Button
            ///----------------------------------
            TimerButton(
              duration: form.otpTimeout,
              /// Si esta en loading no resetea, y si esta en falso depende si se envio el token o no
              restart: form.loading ? false : form.tokenSent,
              onPressed: form.loading ? null : () {
                /// Se debe repetir la funcion porque daria lo mismo aislarla, y aunque se repitan las funciones
                /// es mejor repetir pero mantener un orden que una funcion que reciba muchos parametros y sobre
                /// toda algo como el context
                FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: form.fullPhone, 
                  verificationCompleted: (credentials) => _onCodeAutoFill(context, credentials, form), 
                  verificationFailed: (error) => form.error = ErrorResponse.fromObject(error), 
                  codeSent: (vId, rT) => _onCodeSent(context, vId, rT, form), 
                  /// Necesario para no hacer el proceso completo sino solo reenviar el codigo
                  forceResendingToken: int.tryParse(form.phone["resendToken"]!),
                  codeAutoRetrievalTimeout: (verificationId) {},
                  timeout: Duration(seconds: form.otpTimeout)
                );
              }, 
            ),

            ///----------------------------------
            /// Back Button
            ///----------------------------------
            TextButton(
              onPressed: form.loading ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Back to phone', style: TextStyles.button)
            )
          ],
        );
      }
    );
  }
}
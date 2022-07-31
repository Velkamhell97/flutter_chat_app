import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/extensions.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../styles/styles.dart';
import '../models/models.dart';
import '../pages/auth/auth.dart';
import '../widgets/transitions/transitions.dart';
import '../widgets/auth/auth.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({Key? key}) : super(key: key);

  Future<void> _login(BuildContext context, AuthFormProvider form) async {
    if(form.loading) return;

    FocusScope.of(context).unfocus();

    if(!form.validate()) return;

    form.loading = true;

    final auth = context.read<AuthService>();

    final error = await auth.signinWithCredentials(AuthType.login, form.body);

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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFormProvider>(
      builder: (context, form, __) {
        return Form(
          key: form.key,
          child: Column(
            children: [
              ///------------------------------------
              /// Email Field
              ///------------------------------------
              TextFormField(
                initialValue: form.body['email'],
                keyboardType: TextInputType.emailAddress,
                decoration: InputStyles.authInput.copyWith(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined)
                ),
                onChanged: (value) => form.body['email'] = value,
                validator: (value) => (value ?? '').isValidEmail ? null : 'Enter a valid email'
              ),
      
              const SizedBox(height: 20.0),
              
              ///------------------------------------
              /// Password Field
              ///------------------------------------
              PasswordInput(
                onPasswordChanged: (value) => form.body["password"] = value,
                validator: (value) => (value ?? '').isValidPassword ? null : 'Password must contain at least 6 characters',
                hint: 'Password',
              ),
              
              const SizedBox(height: 20.0),
              
              ///------------------------------------
              /// Error Text
              ///------------------------------------
              if(form.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(form.error!.message, style: TextStyles.formError, textAlign: TextAlign.center,),
                ),
      
              ///------------------------------------
              /// Submit Button
              ///------------------------------------
              ElevatedButton(
                style: ButtonStyles.authButton,
                onPressed: () => _login(context, form), 
                child: SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    child: form.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyles.button)
                  ),
                )
              ),

              TextButton(
                style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                onPressed: form.loading ? null : ()  {
                  form.error = null; /// Como es un pop si volvemos el error aun aparecera
                  final child = ResetPasswordPage(email: form.body["email"]);
                  Navigator.of(context).push(SlideLeftInRouteBuilder(child: child));
                },
                child: const Text('Forgot Password ?')
              )

              ///------------------------------------
              /// Forgot Password
              ///------------------------------------
              // OverlayBuilder(
              //   child: TextButton(
              //     style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
              //     onPressed: form.loading ? null : ()  {
              //       form.error = null; /// Como es un pop si volvemos el error aun aparecera
              //       final child = ResetPasswordPage(email: form.body["email"]);
              //       Navigator.of(context).push(SlideLeftInRouteBuilder(child: child));
              //     }, 
              //     child: const Text('Forgot Password ?')
              //   ), 
              //   overlayBuilder: (context) {
              //     return SizedBox();
              //   },
              //   overlayTransitionBuilder: (context, animation, child) {
              //     return SlideTransition(
              //       position: Tween(begin: Offset(0.0, 1.0), end: Offset.zero).animate(animation),
              //       child: child,
              //     );
              //   },
              // )
            ],
          ),
        );
      },
    );
  }
}
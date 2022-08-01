import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../styles/styles.dart';
import '../extensions/string_apis.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../models/app_enums.dart';
import '../pages/auth/reset_password_page.dart';
import '../widgets/transitions/page_routes.dart';
import '../widgets/auth/auth_inputs.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({Key? key}) : super(key: key);

  Future<void> _login(BuildContext context, AuthProvider form) async {
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
    return Consumer<AuthProvider>(
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
      
              ///------------------------------------
              /// Spacing
              ///------------------------------------
              const SizedBox(height: 20.0),
              
              ///------------------------------------
              /// Password Field
              ///------------------------------------
              PasswordInput(
                onPasswordChanged: (value) => form.body["password"] = value,
                validator: (value) => (value ?? '').isValidPassword ? null : 'Password must contain at least 6 characters',
                hint: 'Password',
              ),
              
              ///------------------------------------
              /// Spacing
              ///------------------------------------
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

              ///------------------------------------
              /// Forgot Password Button
              ///------------------------------------
              TextButton(
                style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                onPressed: form.loading ? null : ()  {
                  form.error = null; /// Como es un pop si volvemos el error aun aparecera
                  final child = ResetPasswordPage(email: form.body["email"]);
                  Navigator.of(context).push(SlideLeftInRouteBuilder(child: child));
                },
                child: const Text('Forgot Password ?')
              )
            ],
          ),
        );
      },
    );
  }
}
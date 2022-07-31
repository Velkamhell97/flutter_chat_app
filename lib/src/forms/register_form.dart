import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/extensions.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../styles/styles.dart';
import '../widgets/auth/auth.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({Key? key}) : super(key: key);

  Future<void> _register(BuildContext context, AuthFormProvider form) async {
    if(form.loading) return;
                  
    FocusScope.of(context).unfocus();

    if(!form.validate()) return;

    form.loading = true;

    final auth = context.read<AuthService>();

    final error = await auth.signinWithCredentials(AuthType.register, form.body);

    if(error == null){
      if(auth.user?.name == null){
        Navigator.of(context).pushReplacementNamed('/new-user');
      } else {
        Navigator.of(context).pushReplacementNamed('/users');
      }
    } else if(error.code != 'cancel') {
      /// Aqui se decide no parar el loading, solo no mostrar el error
      form.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFormProvider>(
      builder: (context, form, _) {
        return Form(
          key: form.key,
          child: Column(
            children: [
              ///-------------------------------
              /// Email Field
              ///-------------------------------
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
              /// Password
              ///------------------------------------
              PasswordInput(
                onPasswordChanged: (value) => form.body["password"] = value,
                validator: (value) => (value ?? '').isValidPassword? null : 'Password must contain at least 6 characters',
                hint: 'Password',
              ),

              const SizedBox(height: 20.0),

              ///------------------------------------
              /// Confirm Password
              ///------------------------------------
              PasswordInput(
                /// Al parecer no es necesario cambiar un valor para aplicar la validacion
                validator: (value) => (value ?? '') == form.body["password"] ? null : 'Passwords must match',
                hint: 'Repeat Password',
              ),
              
              const SizedBox(height: 20.0),
              
              ///------------------------------------
              /// Error Text
              ///------------------------------------
              if(form.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(form.error!.message, style: TextStyles.formError, textAlign: TextAlign.center),
                ),
      
              ///-------------------------------
              /// Submit Button
              ///-------------------------------
              ElevatedButton(
                style: ButtonStyles.authButton,
                onPressed: () => _register(context, form), 
                child: SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    child: form.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register', style: TextStyles.button)
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';

import '../providers/providers.dart';
import '../services/services.dart';
import '../styles/styles.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthServices>(context, listen: false);
    final form = Provider.of<LoginFormProvider>(context);

    final loading = form.loading;
    final show    = form.show;
    final body    = form.body;
    final error   = form.error;
    
    return Form(
      key: form.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //------------------------------------
          // Email Field
          //------------------------------------
          TextFormField(
            initialValue: body['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: InputStyles.authInputStyle.copyWith(
              hintText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined)
            ),
            onChanged: (value) => body['email'] = value,
            validator: (value) => EmailValidator.validate(value ?? '') ? null : 'Enter a valid email'
          ),

          const SizedBox(height: 20.0),
          
          //------------------------------------
          // Password Field
          //------------------------------------
          TextFormField(
            obscureText: !show,
            decoration: InputStyles.authInputStyle.copyWith(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: GestureDetector(
                onTap: () => form.show = !show,
                child: show ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
              )
            ),
            onChanged: (value) => body['password'] = value,
            validator: (value) => (value ?? '').length > 5 ? null : 'Password must contain at least 6 characters',
          ),

          const SizedBox(height: 20.0),
          
          //------------------------------------
          // Error Text
          //------------------------------------
          if(error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(error.details.msg, style: TextStyles.formError, textAlign: TextAlign.center,),
            ),

          //------------------------------------
          // Submit Button
          //------------------------------------
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 15.0)
            ),
            onPressed: ()  async { //Se podria crear una funcion pero se repetiria codigo
              if(loading) return;
              form.error = null;
              FocusScope.of(context).unfocus();

              if(form.validate()){
                form.loading = true;

                final error = await auth.signin(data: body); //Si hay un error tambien termina el loading

                if(error == null){
                  // Navigator.of(context).restorablePushReplacementNamed('/users');
                  Navigator.of(context).pushReplacementNamed('/users');
                } else {
                  form.error = error;
                  form.loading = false;
                }
              }
            }, 
            child: loading 
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Login', style: TextStyles.button)
          )
        ],
      ),
    );
  }
}
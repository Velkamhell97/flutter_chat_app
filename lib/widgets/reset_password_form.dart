import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';

import 'package:chat_app/providers/reset_form_provider.dart';
import 'package:chat_app/services/auth_services.dart';
import 'package:chat_app/styles/styles.dart';
import 'package:chat_app/widgets/widgets.dart';

class ResetPasswordForm extends StatelessWidget {
  const ResetPasswordForm({Key? key}) : super(key: key);

  void _showDialog(BuildContext context)  async {
    await showGeneralDialog(
      context: context, 
      pageBuilder: (_, __, ___) {
        return const ResetPasswordModal();
      },
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final form = Provider.of<ResetFormProvider>(context);

    final loading   = form.loading;
    final show      = form.show;
    final reshow    = form.reshow;
    final tokenSent = form.tokenSent;
    final body = form.body;
    final error = form.error;

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
              prefixIcon: const Icon(Icons.email)
            ),
            onChanged: (value) => form.body['email'] = value,
            validator: (value) => EmailValidator.validate(value ?? '') ? null : 'Enter a valid email'
          ),

          const SizedBox(height: 20.0),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: tokenSent ? Column(
              children: [
                //------------------------------------
                // Text
                //------------------------------------
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text('Ingresa el codigo que te enviamos al correo y tu nueva contraseña'),
                ),

                //------------------------------------
                // Code Field
                //------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  height: 40,
                  child: CodeInput(form: form),
                ),

                const SizedBox(height: 30.0),

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
                // Confirm Password Field
                //------------------------------------
                TextFormField(
                  obscureText: !reshow,
                  decoration: InputStyles.authInputStyle.copyWith(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: GestureDetector(
                      onTap: () => form.reshow = !reshow,
                      child: reshow ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                    )
                  ),
                  validator: (value) => body['password'] == (value ?? '') ? null : 'The password must match'
                ),

                const SizedBox(height: 20.0),
              ],
            ) : const SizedBox.shrink(),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              );
            },
          ),

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

                if(tokenSent){
                  final error = await auth.resetPassword(data: body);

                  if(error == null){
                    _showDialog(context);
                  } else {
                    form.error = error;
                  }
                } else {
                  final error = await auth.sendResetCode(email: body['email']);

                  if(error == null){
                    form.tokenSent = true;
                  } else {
                    form.error = error;
                  }
                }
                
                form.loading = false;
              }
            }, 
            child: loading 
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(color: Colors.white)) 
              : Text(tokenSent ? 'Reset password' : 'Send token', style: TextStyles.button)
          ),
        ],
      ),
    );
  }
}
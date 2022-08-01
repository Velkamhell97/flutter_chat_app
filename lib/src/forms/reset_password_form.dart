import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/extensions.dart';
import '../providers/providers.dart';
import '../styles/styles.dart';
import '../services/services.dart';

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({Key? key}) : super(key: key);

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

/// Se utiliza un StateFull para utilizar el mounted y explicar un caso
class _ResetPasswordFormState extends State<ResetPasswordForm> {

  Future<void> _reset(AuthFormProvider form) async {
    if(form.loading) return;

    form.tokenSent = false;
    
    FocusScope.of(context).unfocus();

    if(!form.validate()) return;

    form.loading = true;

    final error = await context.read<AuthService>().sendResetEmail(form.body["email"]!);

    if(error == null){
      /// Si se setea el cancelToken no se llegara hasta aqui, pues siempre al salir
      /// habra un error
      if(mounted){
        form.tokenSent = true;
      } else {
        /// Show SnackBar para indicar que se completo la peticion lo cual no es muy normal
        /// para el caso de la autenticacion, o se hace la peticion o no pero no se queda
        /// escuchando a la respuesta
      }
    } else if(error.code == 'cancel') {
      /// opcional cancelar el loading, solo cancela la peticion y sale de la pantalla
      form.loading = false; 
    } else {
      /// Tambien se podria mostrar el error o un snack de que la peticion fue cancelada
      /// pero no es muy comun
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
                initialValue: form.body["email"],
                keyboardType: TextInputType.emailAddress,
                decoration: InputStyles.authInput.copyWith(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email)
                ),
                onChanged: (value) => form.body["email"] = value,
                validator: (value) => (value ?? '').isValidEmail ? null : 'Enter a valid email'
              ),
      
              const SizedBox(height: 20.0),
      
              ///------------------------------------
              /// Message Sent Box
              ///------------------------------------
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: form.tokenSent ? _SuccessMessage(form.body["email"]!) : const SizedBox.shrink(),
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
                onPressed: () => _reset(form), 
                child: SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    child: form.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Email', style: TextStyles.button)
                  ),
                )
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  final String email;

  const _SuccessMessage(this.email, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = 'A email with instructions to reset your password was send to $email';

    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(6.0)
      ),
      padding: const EdgeInsets.all(8.0),
      child: Text(text),
    );
  }
}
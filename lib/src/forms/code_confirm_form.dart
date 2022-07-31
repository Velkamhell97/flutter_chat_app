import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../styles/styles.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/auth/auth.dart';

class CodeConfirmForm extends StatelessWidget {
  const CodeConfirmForm({Key? key}) : super(key: key);

  Future<void> _confirmSMS(BuildContext context, AuthFormProvider form) async {
    if(form.loading) return;
    
    form.error = null;
    
    FocusScope.of(context).unfocus();

    if(!form.validateCode()) return;

    form.loading = true;

    final credentials = PhoneAuthProvider.credential(
      verificationId: form.phone["verificationId"]!, 
      smsCode: form.phone["code"]!
    );

    final auth = context.read<AuthService>();

    final error = await auth.signinWithPhone(credentials);

    if(error == null){
      if(auth.user?.name == null){
        Navigator.of(context).pushNamedAndRemoveUntil('/new-user', (route) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/users', (route) => false);
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
          /// Necesario usar otra key porque se comparte el mismo authFormProvider
          key: form.codeKey,
          child: Column(
            children: [
              ///------------------------------------
              /// Code Input
              ///------------------------------------
              CodeInput(
                /// Autocompleta el codigo, cuando este argumento es diferente de null
                autoCode: form.smsCode,
                codeLength: 6,
                onCodeChanged: (value) => form.phone["code"] = value,
              ),

              ///------------------------------------
              /// Error Text
              ///------------------------------------
              if(form.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(form.error!.message, style: TextStyles.formError, textAlign: TextAlign.center),
                ),
              
              ///-------------------------------------
              /// Spacing
              ///-------------------------------------
              const SizedBox(height: 20.0),
              
              ///------------------------------------
              /// Submit Button
              ///------------------------------------
              ElevatedButton(
                style: ButtonStyles.authButton,
                onPressed: () => _confirmSMS(context, form), 
                child: SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    child: form.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify Code', style: TextStyles.button)
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
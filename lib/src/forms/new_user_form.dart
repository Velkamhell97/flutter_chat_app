import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../styles/styles.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth/user_avatar.dart';

class NewUserForm extends StatelessWidget {
  const NewUserForm({Key? key}) : super(key: key);

  static const _message = 'Ingresa tu nombre y la foto que desees que aparezca en tu perfil';

  Future<void> _save(BuildContext context, AuthProvider form) async {
    if(form.loading) return;

    FocusScope.of(context).unfocus();

    if(!form.validate()) return;

    form.loading = true;

    final error = await context.read<AuthService>().updateUser(form.body);

    if(error == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/users', (_) => false);
    } else if(error.code != 'cancel') {
      form.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Consumer<AuthProvider>(
      builder: (_, form, __){
        return Form(
          key: form.key,
          child: Column(
            children: [ 
              ///------------------------------
              /// Avatar
              ///------------------------------
              UserAvatar(
                radius: size.height * 0.1,
                onAvatarChanged: (avatar) => form.body["avatar"] = avatar,
              ),

              ///---------------------------
              /// Message
              ///---------------------------
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(_message, style: TextStyles.body2),
              ),

              ///-------------------------------
              /// Name Field
              ///-------------------------------
              TextFormField(
                initialValue: form.body['name'],
                keyboardType: TextInputType.name,
                decoration: InputStyles.authInput.copyWith(
                  hintText: 'Name',
                  prefixIcon: const Icon(Icons.person)
                ),
                onChanged: (value) => form.body['name'] = value,
                validator: (value) => (value ?? '').length > 3 ? null : 'The name is required'
              ),

              ///---------------------------
              /// Spacing
              ///---------------------------
              const SizedBox(height: 20.0),

              ///------------------------------------
              /// Error Text
              ///------------------------------------
              if(form.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(form.error!.message, style: TextStyles.formError, textAlign: TextAlign.center),
                ),

              ///-------------------------------
              /// Submit Button
              ///-------------------------------
              ElevatedButton(
                style: ButtonStyles.authButton,
                onPressed: () => _save(context, form), 
                child: SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    child: form.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Start Chat', style: TextStyles.button)
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
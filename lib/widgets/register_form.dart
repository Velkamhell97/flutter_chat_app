import 'package:chat_app/styles/input_styles.dart';
import 'package:chat_app/styles/text_styles.dart';
import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(50),
            child: TextFormField(
              decoration: InputStyles.authInputStyle.copyWith(
                hintText: 'Name',
                prefixIcon: const Icon(Icons.person_outline)
              ),
            ),
          ),
          const SizedBox(height: 20.0),
           Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(50),
            child: TextFormField(
              decoration: InputStyles.authInputStyle.copyWith(
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined)
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(50),
            child: TextFormField(
              obscureText: true,
              decoration: InputStyles.authInputStyle.copyWith(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline)
              )
            ),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 15.0)
            ),
            onPressed: () {}, 
            child: const Text('Register', style: TextStyles.button,)
          )
        ],
      ),
    );
  }
}
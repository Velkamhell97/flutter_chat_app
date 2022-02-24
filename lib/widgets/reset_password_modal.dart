import 'package:flutter/material.dart';

class ResetPasswordModal extends StatelessWidget {
  const ResetPasswordModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          width: size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Password Update Successfully'),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () => Navigator.of(context).pop(), 
                child: const Text('OK')
              )
            ],
          ),
        ),
      ),
    );
  }
}
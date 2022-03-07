import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../styles/styles.dart';
import '../widgets/widgets.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final loginEmail = ModalRoute.of(context)!.settings.arguments as String;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            height: size.height,
            child: ChangeNotifierProvider(
              create: (_) => ResetFormProvider(loginEmail),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Header(),
                  // Text('Post Header'),
                  Center(
                    child: SizedBox(
                      width: size.width * 0.9,
                      child: const ResetPasswordForm()
                    ),
                  ),
                  const Spacer(),
                  const _PreFooter(),
                ],
              ),
            ),
          ),
        )
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        'Ingresa tu correo para continuar con el proceso de restauracion de la contraseña', 
        style: TextStyles.body2
      ),
    );
  }
}

class _PreFooter extends StatelessWidget {
  const _PreFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final form = Provider.of<ResetFormProvider>(context);

    return Column(
      children: [
        TextButton(
          //-Debe ser el maybePop para que detecte el willscope
          // onPressed: () => Navigator.of(context).maybePop(),
          onPressed: form.loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Volver al inicio', style: TextStyles.button)
        )
      ],
    );
  }
}
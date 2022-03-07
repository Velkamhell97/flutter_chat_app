import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../styles/styles.dart';
import '../widgets/widgets.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final loginEmail = ModalRoute.of(context)!.settings.arguments as String;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // backgroundColor: const Color(0xffF2F2F2),
        //-Solucion 1 Video
        body: SingleChildScrollView(
          // reverse: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            height: size.height,
            child: ChangeNotifierProvider(
              create: (_) => RegisterFormProvider(loginEmail),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Header(),
                  // Text('Post Header'),
                  Center(
                    child: SizedBox(
                      width: size.width * 0.9,
                      child: const RegisterForm()
                    ),
                  ),
                  const _PreFooter(),
                  const Text('Terminos y condiciones de uso', textAlign: TextAlign.center, style: TextStyles.body3Grey,)
                ],
              ),
            ),
          ),
        )

        //-Solucion 2: Post Facebook
        // body: CustomScrollView(
        //   physics: const BouncingScrollPhysics(
        //     parent: AlwaysScrollableScrollPhysics()
        //   ),
        //   slivers: [
        //     //-------------------------------------
        //     // HEADER & POST-HEADER
        //     //-------------------------------------
        //     SliverToBoxAdapter(
        //       child: SizedBox(
        //         height: size.height * 0.4,
        //         child: Column(
        //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //           children: const [
        //             _Header(),
        //             // Text('Post Header')
        //           ],
        //         ),
        //       ),
        //     ),
        //
        //     //-------------------------------------
        //     // FORM & PRE-FOOTER & FOOTER
        //     //-------------------------------------
        //     SliverFillRemaining(
        //       hasScrollBody: false,
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           SizedBox(
        //             width: size.width * 0.9,
        //             child: const RegisterForm()
        //           ),
        //           const _PreFooter(),
        //           const Padding(
        //             padding: EdgeInsets.only(bottom: 20.0),
        //             child: Text('Terminos y condiciones de uso', style: TextStyles.body3Grey,),
        //           )
        //         ],
        //       ),
        //     )
        //   ],
        // ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/tag-logo.png', width: 150),
        const SizedBox(height: 10.0),
        const Text('Register', style: TextStyles.title2)
      ],
    );
  }
}

class _PreFooter extends StatelessWidget {
  const _PreFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final form = Provider.of<RegisterFormProvider>(context);

    return Column(
      children: [
        const Text('¿Ya tienes una cuenta?', style: TextStyles.body2grey),
        TextButton(
          onPressed: form.loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Ingresa ahora', style: TextStyles.button)
        )
      ],
    );
  }
}
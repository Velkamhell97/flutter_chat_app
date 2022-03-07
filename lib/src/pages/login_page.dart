import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../styles/styles.dart';
import '../widgets/widgets.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // backgroundColor: const Color(0xffF2F2F2),
        //-Solucion 1 Video: No funciona si se coloca en landscape (se tendria que pensar en un diseño de dos columnas)
        body: SingleChildScrollView(
          // reverse: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            height: size.height,
            child: ChangeNotifierProvider(
              create: (_) => LoginFormProvider(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Header(),
                  // Text('Post Header'),
                  Center(
                    child: SizedBox(
                      width: size.width * 0.9,
                      child: const LoginForm()
                    ),
                  ),
                  const _PreFooter(),
                  const Text('Terminos y condiciones de uso', textAlign: TextAlign.center, style: TextStyles.body3Grey,)
                ],
              ),
            ),
          ),
        )
    
        // -Solucion 2: Post Facebook: si funciona con landscape
        // body: CustomScrollView(
        //   physics: const BouncingScrollPhysics(
        //     //-Cuando se usa el parent se combinan los efectos, el del alwaysScroll es que pueda hacer scroll asi no haya contenido
        //     parent: AlwaysScrollableScrollPhysics()
        //   ),
        //   slivers: [
        //     //-------------------------------------
        //     // HEADER & POST-HEADER
        //     //-------------------------------------
        //     //-El header y post Header por lo general ocupan un espacio fijo en el formulario, no se coloca todo dentro
        //     //-del fill remain porque no se puede alinear todo como se desea en una columna 
        //     SliverToBoxAdapter(
        //       child: SizedBox(
        //         height: size.height * 0.4,
        //         child: Column(
        //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //           children: const [
        //             _Header(),
        //             //-Opcional gracias a la columna tiene un espaciado correcto con el Header
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
        //       hasScrollBody: false, //Si el child tiene un body scrollable, por defecto en true
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           SizedBox(
        //             width: size.width * 0.9,
        //             child: const LoginForm()
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
        const Text('Messenger', style: TextStyles.title2)
      ],
    );
  }
}

class _PreFooter extends StatelessWidget {
  const _PreFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final form = Provider.of<LoginFormProvider>(context);

    return Column(
      children: [
        const Text('¿No tienes cuenta?', style: TextStyles.body2grey),
        TextButton(
          onPressed: form.loading ? null : () {
            form.error = null;
            Navigator.of(context).pushNamed('/register', arguments: form.body['email']);
          }, 
          child: const Text('Crea una ahora', style: TextStyles.button)
        ),
        TextButton(
          onPressed: form.loading ? null : () {
            form.error = null;
            Navigator.of(context).pushNamed('/reset-password', arguments: form.body['email']);
          } , 
          child: const Text('Olvide mi contraseña', style: TextStyles.button)
        )
      ],
    );
  }
}
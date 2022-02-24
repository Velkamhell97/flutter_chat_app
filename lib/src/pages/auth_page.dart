import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chat_app/services/auth_services.dart';
import 'package:chat_app/src/pages/pages.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authServices = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: FutureBuilder(
        //-El entrar a la app checka si esta logeado y actualiza en usuario en caso que sea asi (el usuario no es persistente)
        future: authServices.isLogged(),
        builder: (_, AsyncSnapshot<bool> snapshot) {
          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          if(snapshot.data == false){
            print('user invalid');

            Future.microtask((){
              Navigator.pushReplacement(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => const LoginPage(),
                transitionDuration: const Duration(milliseconds: 0)
              ));
            });
          } else {
            print('user valid');

            Future.microtask((){
              Navigator.pushReplacement(context, PageRouteBuilder(
                // pageBuilder: (_, __, ___) => HomeScreenFinal(),
                //-Se puede agregar animaciones de entrada tipo fooTransition, tambien se deberia modificar el duration
                pageBuilder: (_, __, ___) => const UsersPage(),
                transitionDuration: const Duration(milliseconds: 0)
              ));
            });
          }

          return Container();
        },
      ),
    );
  }
}
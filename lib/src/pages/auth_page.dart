import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/pages.dart';
import '../services/services.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthServices>(context, listen: false);
    final socket = Provider.of<SocketServices>(context, listen: false);

    return Scaffold(
      body: FutureBuilder(
        //-El entrar a la app checka si esta logeado y actualiza en usuario en caso que sea asi (el usuario no es persistente)
        future: user.isLogged(),
        builder: (_, AsyncSnapshot<bool> snapshot) {
          if(!snapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          if(snapshot.data == false){
            // print('user invalid');
            socket.disconnect();

            Future.microtask((){
              Navigator.pushReplacement(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => const LoginPage(),
                transitionDuration: const Duration(milliseconds: 0)
              ));
            });
          } else {
            // print('user valid');
            // socket.connect(user.token!);

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
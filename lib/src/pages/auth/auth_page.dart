import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/services.dart';
import '../../widgets/transitions/page_routes.dart';
import '../../pages/chat/users_page.dart';
import '../../pages/auth/login_page.dart';

class AuthPage extends StatefulWidget {
  final String? payload;

  const AuthPage({Key? key, this.payload}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      final sockets = context.read<SocketsService>();

      final isLogged = await auth.isLogged();

      if(isLogged){
        final route = SlideLeftInRouteBuilder(child: UsersPage(appLaunchPayload: widget.payload));
        Navigator.of(context).pushReplacement(route);
      } else {
        sockets.disconnect();
        final route = FadeInSlideLeftOutRouteBuilder(child: const LoginPage());
        Navigator.of(context).pushReplacement(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator())
    );
  }
}
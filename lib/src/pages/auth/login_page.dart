import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../forms/forms.dart';
import '../../services/services.dart';
import '../../widgets/auth/auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);

    return WillPopScope(
      onWillPop: () async {
        /// Para cancelar peticiones http
        context.read<AuthService>().cancelRequest();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              ///-------------------------------------
              /// HEADER & POST-HEADER
              ///-------------------------------------
              SliverToBoxAdapter(
                child: SizedBox(
                  height: mq.size.height * 0.38,
                  child: Padding(
                    padding: EdgeInsets.only(top: mq.padding.top),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        LogoHeader(text: 'Login'),
                        // Text('Post Header')
                      ],
                    ),
                  ),
                ),
              ),
          
              ///-------------------------------------
              /// FORM & PRE-FOOTER & FOOTER
              ///-------------------------------------
              SliverFillRemaining(
                /// Si el child tiene un body scrollable, por defecto en true
                hasScrollBody: false, 
                child: ChangeNotifierProvider(
                  create: (_) => AuthFormProvider(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ///-------------------------------------
                        /// FORM
                        ///-------------------------------------
                        LoginForm(),
                  
                        ///-------------------------------------
                        /// PRE-FOOTER - FOOTER
                        ///-------------------------------------
                        Expanded(child: LoginFooter()),

                        //-------------------------------------
                        /// SPACING
                        ///-------------------------------------
                        SizedBox(height: 20.0),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

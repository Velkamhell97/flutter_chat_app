import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../forms/register_form.dart';
import '../../widgets/auth/auth.dart';

class RegisterPage extends StatelessWidget {
  final String? email;

  const RegisterPage({Key? key, this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    
    return WillPopScope(
      onWillPop: () async {
        context.read<AuthService>().cancelRequest();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              //-------------------------------------
              // HEADER & POST-HEADER
              //-------------------------------------
              SliverToBoxAdapter(
                child: SizedBox(
                  height: mq.size.height * 0.38,
                  child: Padding(
                    padding: EdgeInsets.only(top: mq.padding.top),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        LogoHeader(text: 'Register'),
                        // Text('Post Header')
                      ],
                    ),
                  ),
                ),
              ),
          
              //-------------------------------------
              // FORM & PRE-FOOTER & FOOTER
              //-------------------------------------
              SliverFillRemaining(
                hasScrollBody: false,
                child: ChangeNotifierProvider(
                  create: (_) => AuthProvider(email: email),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ///-------------------------------------
                        /// FORM
                        ///-------------------------------------
                        RegisterForm(),
                  
                        ///-------------------------------------
                        /// PRE-FOOTER - FOOTER
                        ///-------------------------------------
                        Expanded(child: RegisterFooter()),
                        
                        ///-------------------------------------
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
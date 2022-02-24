import 'package:chat_app/models/user.dart';
import 'package:chat_app/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide RefreshIndicator;

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  static const _users = User.test;

  final _refreshController = RefreshController(initialRefresh: false);

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        title: const Text('My Name'),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const Icon(Icons.check_circle, color: Colors.blue),
        actions: [
          IconButton(
            onPressed: () async {
              Navigator.of(context).pushReplacementNamed('/login');
              auth.signout();
            } ,
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),

      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: WaterDropHeader(
          idleIcon: const Icon(Icons.check, color: Colors.white, size: 15,),
          waterDropColor: Colors.blue,
          complete: Icon(Icons.check_circle, color: Colors.blue.shade300),
        ),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (context, index) => const Divider(thickness: 1), 
          itemCount: 10,
          itemBuilder: (context, index) {
            return Text('Hola');
            // return _UserTile(user: _users[index]);
          }, 
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;

  const _UserTile({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = user.online ? Colors.green.shade300 : Colors.red.shade300;
      
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.name.substring(0,2)),
        backgroundColor: Colors.blue[100],
      ),
      trailing: Icon(Icons.circle, color: color, size: 16),
      title: Text(user.name),
      subtitle: Text(user.email),
    );
  }
}
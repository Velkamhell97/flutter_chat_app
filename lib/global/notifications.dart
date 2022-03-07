import 'package:flutter/material.dart';

import 'package:chat_app/widgets/custom_dialog.dart';

class DialogModel {
  final IconData icon;
  final String title;
  final String body;
  final String mainButton;
  final String? secondaryButton;

  const DialogModel({required this.icon, required this.title, required this.body, required this.mainButton, this.secondaryButton});
}

class Notifications {
  static Future<bool> _dialogBuilder(BuildContext context, DialogModel dialog) async {
    return await showGeneralDialog<bool>(
      context: context, 
      pageBuilder: (context, animation, _) => SlideTransition(
        position: Tween(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0)).animate(animation),
        child: CustomDialog(dialog: dialog),
      ),
    ) ?? false;
  }

  static Future<bool> showStoragePermissionDialog(BuildContext context) async {
    const dialog = DialogModel(
      icon: Icons.folder, 
      title: "Storage Permissions", 
      body: "If you do not allow storage permissions, you won't be able to receive images, cause they are saved on the device", 
      mainButton: 'Accept',
      // secondaryButton: 'Decline'
    );

    return await _dialogBuilder(context, dialog);
  }
}
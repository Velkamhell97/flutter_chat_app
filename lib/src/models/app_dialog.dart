import 'package:flutter/material.dart' show IconData, Icons;

class AppDialog {
  final IconData icon;
  final String title;
  final String body;
  final String mainButton;
  final String? secondaryButton;

  const AppDialog({required this.icon, required this.title, required this.body, required this.mainButton, this.secondaryButton});

  static const storagePermissionDialog = AppDialog(
    icon: Icons.folder, 
    title: "Storage Permissions", 
    body: "If you do not allow storage permissions, you won't be able to receive images, cause they are saved on the device", 
    mainButton: 'Accept',
    // secondaryButton: 'Decline'
  );

  static const resetPasswordDialog = AppDialog(
    icon: Icons.lock, 
    title: "Password Reset Successfully", 
    body: "The password was reseted sucesfully, now you can try login again", 
    mainButton: 'Accept',
    // secondaryButton: 'Decline'
  );
}
import 'package:flutter/material.dart';

import '../global/globals.dart';
import '../styles/styles.dart';

class CustomDialog extends StatelessWidget {
  final DialogModel dialog;

  const CustomDialog({Key? key, required this.dialog}) : super(key: key);

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -_radius,
              left: 0,
              right: 0,
              child: CircleAvatar(
                radius: _radius,
                child: Icon(dialog.icon),
              )
            ),
            Container(
              width: size.width * 0.8,
              padding: const EdgeInsets.fromLTRB(20.0, _radius, 20.0, 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10.0),
                  Text(dialog.title, style: TextStyles.title2),
                  const SizedBox(height: 15.0),
                  Text(dialog.body, textAlign: TextAlign.justify),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      if(dialog.secondaryButton != null)
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop<bool>(false), 
                            child: Text(dialog.secondaryButton!)
                          ),
                        ),
                      
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop<bool>(true), 
                          child: Text(dialog.mainButton)
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
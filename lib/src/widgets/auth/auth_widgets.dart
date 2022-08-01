import 'package:flutter/material.dart';

import '../../styles/styles.dart';

class LogoHeader extends StatelessWidget {
  final String text;
  final double width;

  const LogoHeader({
    Key? key, 
    required this.text,
    this.width = 150
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/tag-logo.png', width: width),
        
        const SizedBox(height: 10.0),
        
        Text(text, style: TextStyles.title2)
      ],
    );
  }
}

class TextDivider extends StatelessWidget {
  final String text;
  final double height;
  final double margin;
  final Color color;

  const TextDivider({
    Key? key, 
    required this.text, 
    this.height = 1.0,
    this.margin = 0.0,
    this.color = Colors.grey
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, color],
                  stops: const [0.0, 0.75]
                )
              ),
              child: SizedBox(height: height),
            ),
            // child: Divider(color: Colors.grey, thickness: 0.8)
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(text)
          ),
          
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Colors.white], 
                  stops: const [0.25, 1.0]
                )
              ),
              child: SizedBox(height: height),
            ),
            // child: Divider(color: Colors.grey, thickness: 0.8)
          ),
        ],
      ),
    );
  }
}



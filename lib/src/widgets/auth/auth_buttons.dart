import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';

import '../../styles/styles.dart';

///---------------------------------
/// PHONE BUTTON
///---------------------------------
class PhoneButton extends StatelessWidget {
  final VoidCallback? onPress;

  const PhoneButton({Key? key, required this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyles.phoneButton,
      onPressed: onPress, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Signin with'),
          SizedBox(width: 10.0),
          FaIcon(FontAwesomeIcons.phone),
        ],
      ) 
    );
  }
}

///---------------------------------
/// GOOGLE BUTTON
///---------------------------------
class GoogleButton extends StatelessWidget {
  final VoidCallback? onPress;

  const GoogleButton({Key? key, required this.onPress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyles.googleButton,
      onPressed: onPress, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('Signin with'),
          SizedBox(width: 10.0),
          FaIcon(FontAwesomeIcons.google)
        ],
      ) 
    );
  }
}

///---------------------------------
/// TIMER BUTTON
///---------------------------------
class TimerButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final int duration;
  final bool restart;
  final bool startOnPressed;
  final bool startOnInit;

  const TimerButton({
    Key? key, 
    this.onPressed, 
    required this.duration, 
    this.restart = false, 
    this.startOnPressed = false, 
    this.startOnInit = true
    }) : super(key: key);

  @override
  State<TimerButton> createState() => _TimerButtonState();
}

class _TimerButtonState extends State<TimerButton> {
  final _counterNotifier = ValueNotifier<int>(0);

  late Timer _timer;

  @override
  void initState() {
    super.initState();

    /// Puede usarse el PostCallback
    if(widget.startOnInit){
      _setTimer();
    }
  }

  void _setTimer(){
    _counterNotifier.value = widget.duration;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) { 
      _counterNotifier.value = _counterNotifier.value - 1;

      if(_counterNotifier.value == 0){
        _timer.cancel();
      }
    });
  }

  /// Alternativa al Future.microtask
  @override
  void didUpdateWidget(covariant TimerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if(widget.restart){
      _setTimer();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if(widget.restart){
    //   Future.microtask(_setTimer);
    // }

    return ValueListenableBuilder<int>(
      valueListenable: _counterNotifier,
      builder: (_, seconds, __) {
        final countdown = seconds == 0 ? 'now' : 'in $seconds';

        return TextButton(
          onPressed: seconds != 0 ? null : () {
            if(widget.onPressed != null) {
              widget.onPressed!();
            }
    
            if(widget.startOnPressed) {
              _setTimer();
            }
          }, 
          child: Text('Resend code $countdown', style: TextStyles.button)
        );
      }
    );
  }
}
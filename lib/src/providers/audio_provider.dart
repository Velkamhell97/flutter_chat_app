import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AudioProvider extends ChangeNotifier {
  final _player = AudioPlayer();

  AudioProvider() {
    init();
  }

  Future<void> init() async{
    _player.onPositionChanged.listen((event) {
      progress = event;
    });

    _player.onPlayerComplete.listen((event) {
      _reset();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  //------------STATES-----------------//
  String selected = '';
  AnimationController? selectedController;

  bool _playing = false;
  bool get playing => _playing;
  set playing(bool playing) {
    if(playing){
      selectedController?.forward();
    } else {
      selectedController?.reverse();
    }

    _playing = playing;
    notifyListeners();
  }

  Duration _progress = Duration.zero;
  Duration get progress => _progress;
  set progress(Duration progress) {
    _progress = progress;
    notifyListeners();
  }

  void _reset([bool resetId = true]) {
    if(resetId) selected = '';
    _progress = Duration.zero;
    playing = false;
    selectedController?.reverse();
  }

  Future<void> toggle(String path, String id, AnimationController controller) async {
    if(selected == id){
      if(_playing) {
        _player.pause();
      } else {
        _player.resume();
      }
      
      playing = !playing;
      return;
    }

    selected = id;

    if(_playing){
      await _player.release();
      _reset(false);
    }

    selectedController = controller;

    _player.play(DeviceFileSource(path));

    playing = true;
  }
}

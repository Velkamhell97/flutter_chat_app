import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

class AudioProvider extends ChangeNotifier {
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;

  bool _canRecord = false;

  //------------STATES-----------------//
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  set isRecording(bool isRecording) {
    _isRecording = isRecording;
    notifyListeners();
  }

  bool firstPlay = true;

  String _activeAudio = '';
  String get activeAudio => _activeAudio;
  set activeAudio(String activeAudio) {
    _activeAudio = activeAudio;
    notifyListeners();
  }

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  set isPlaying(bool isPlaying) {
    _isPlaying = isPlaying;
    notifyListeners();
  }

  //-----------STREAMS-----------------//
  StreamSubscription? _recordStream;
  void _disposeRecordStream() {
    if(_recordStream != null){
      _recordStream!.cancel();
      _recordStream = null;
    }
  }

  StreamSubscription? _playerStream;
  void _disposePlayerStream() {
    if(_playerStream != null){
      _playerStream!.cancel();
      _playerStream = null;
    }
  }

  //---------------TIMES---------------//
  String _recordTime = '';
  String get recordTime => _recordTime;
  set recordTime(String recordTime) {
    _recordTime = recordTime;
    notifyListeners();
  }

  int get recordTimeUnits => int.parse(_recordTime.characters.last);

  double _maxDuration = 1.0;
  double get maxDuration => _maxDuration;
  set maxDuration(double maxDuration) {
    _maxDuration = maxDuration;
    notifyListeners();
  }

  double _playerTime = 0.0;
  double get playerTime => _playerTime;
  set playerTime(double playerTime) {
    _playerTime = playerTime;
    notifyListeners();
  }

  //---------------CONSTRUCTOR---------------//
  AudioProvider() {
    _audioRecorder = FlutterSoundRecorder(logLevel: Level.nothing);
    _audioPlayer = FlutterSoundPlayer(logLevel: Level.nothing);
    _openSession();
  }

  Future<void> _openSession() async {
    await _audioRecorder!.openRecorder();
    await _audioPlayer!.openPlayer();

    await _audioRecorder!.setSubscriptionDuration(const Duration(seconds: 1));
    await _audioPlayer!.setSubscriptionDuration(const Duration(milliseconds: 500));

    _canRecord = true;
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder(); //-El dispose reinicia los valores
    _audioPlayer!.closePlayer();
    super.dispose();
  }

  Future<void> record(String path) async {
    if (_canRecord && !_isRecording) {
      await _audioRecorder!.startRecorder(toFile: path, codec: Codec.pcm16WAV, audioSource: AudioSource.microphone);
      isRecording = true;

      _recordStream = _audioRecorder!.onProgress!.listen((event) {
        final date = DateTime.fromMillisecondsSinceEpoch(event.duration.inMilliseconds, isUtc: true);
        recordTime = DateFormat("mm:ss").format(date);
      });
    }
  }

  Future<void> stop() async {
    if (_canRecord && _isRecording) {
      await _audioRecorder!.stopRecorder();
      isRecording = false;
      // recordTime = '';
      _disposeRecordStream();
    }
  }

  Future<void> play(String path, String id) async {
    if(_audioPlayer!.isPlaying){
      await _audioPlayer!.stopPlayer();
      _disposePlayerStream();
      isPlaying = false;
      playerTime = 0;
    }

    activeAudio = id;

    await _audioPlayer!.startPlayer(
      fromURI: path, 
      codec: Codec.pcm16, 
      whenFinished: () {
        _disposePlayerStream();
        isPlaying = false;
        firstPlay = true;
        playerTime = 0;
      }
    );

    firstPlay = false;
    isPlaying = true;

    _playerStream = _audioPlayer!.onProgress!.listen((event) {
      maxDuration = event.duration.inMilliseconds.toDouble();
      if (maxDuration <= 0) maxDuration = 0.0;

      playerTime = min(event.position.inMilliseconds.toDouble(), maxDuration);
      // print('duration: $maxDuration - time: $playerTime');
      
      if (playerTime < 0.0) {
        playerTime = 0.0;
      }
    });
  }

  Future<void> toggle() async {
    isPlaying ? await _audioPlayer!.pausePlayer() : await _audioPlayer!.resumePlayer();
    isPlaying = !isPlaying;
  }
}

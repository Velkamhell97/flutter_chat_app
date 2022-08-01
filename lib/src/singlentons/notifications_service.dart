import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import '../models/notification_tile.dart';

/// Debe ser una clase singlenton para poder inicializarla en el main de la app, sin embargo
/// no tiene la arquitectura de una clase singlenton pues intervien mas logica y otras 
/// dependencias como dio o los stream, que no se puede cerrar con nigun dispose por no ser un provider,
/// sin embargo si se crea afuera en el main, se tendrian que crear tambien los stream en el main
/// y utlizarlos en el MateApp, entonces esta clase unicamente expondria los metodos como showNotification
/// y donwloadAndSaveFile, por ahora se deja asi por orden, pero no se sabe si sea mejor de la otra
class NotificationsService {
  NotificationsService._internal();

  static final _instance = NotificationsService._internal();

  factory NotificationsService() => _instance;

  final _notifications = FlutterLocalNotificationsPlugin();
  final _dio = Dio();

  static const _channelId = 'chat_channel';
  static const _groupId = 'chat_group_channel';

  final _notificationsStream = BehaviorSubject<Map<String, dynamic>>();
  ValueStream<Map<String, dynamic>> get stream => _notificationsStream.stream;

  static const _channel = AndroidNotificationChannel(
    _channelId, 
    'Flutter Chat Notifications',
    description: 'This channel is used to show incomming messages notifications', 
    importance: Importance.high, 
    groupId: _groupId
  );

  static const _groupChannel = AndroidNotificationChannelGroup(
    _groupId,
    'Flutter Chat Group Notifications',
    description: 'This channel is used to show incomming messages notifications',
  );

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('triforce');
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannelGroup(_groupChannel);
    await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(_channel);

    await _notifications.initialize(
      settings,
      // onSelectNotification: (json) {
      //   final payload = jsonDecode(json ?? '{}');
      //   _notificationsStream.add(payload);
      // },
      // onDidReceiveBackgroundNotificationResponse: onBackground,
      onDidReceiveNotificationResponse: (notification) {
        final payload = jsonDecode(notification.payload ?? '{}');
        _notificationsStream.add(payload);
      }
    );
  }

  /// Convierte una lista de bits en una imagen
  Future<ui.Image> _loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = Completer();

    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  /// Descargamos una imagen de una url y la redondeamos
  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';

    final response = await _dio.get(url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        receiveTimeout: 0,
      )
    );

    /// Para convertir la imagen a una circular
    final image = await _loadImage(response.data);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(image.width.toDouble() / 2, image.height.toDouble() / 2);
    /// Si el radio lo toma la dimension de mayor valor casi siempre el width, por ahora se deja solo para un caso
    final radius = image.height.toDouble() / 2;

    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.clipPath(path);
    canvas.drawImage(image, const Offset(0.0, 0.0), Paint());

    final result = recorder.endRecording();
    final roundedImage = await result.toImage(image.width, image.height);
    final byteData = await roundedImage.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final File file = File(filePath);
    await file.writeAsBytes(buffer);
    return filePath;
  }  

  Future<void> showChatNotification(List<NotificationTile> tiles) async {
    tiles.sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final styleInformation = InboxStyleInformation(tile.last4.reversed.toList());

      AndroidBitmap<Object> largeIcon;

      if(tile.avatar != null){
        final largeIconPath = await _downloadAndSaveFile(tile.avatar!, 'largeIcon');
        largeIcon = FilePathAndroidBitmap(largeIconPath);
      } else {
        largeIcon = const DrawableResourceAndroidBitmap('default_avatar');
      }

      final notificationDetails1 = NotificationDetails(
          android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        groupKey: _groupChannel.id,
        largeIcon: largeIcon,
        styleInformation: styleInformation,
      ));

      final payload = jsonEncode(tile.toJson());

      await _notifications.show(i, tile.name, tile.last4.last, notificationDetails1, payload: payload);
    }

    /// Se necesita para mostrar las notificaciones en grupo
    final notificationsDetails3 = NotificationDetails(
        android: AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      styleInformation: const InboxStyleInformation([]),
      groupKey: _groupChannel.id,
      setAsGroupSummary: true,
    ));

    await _notifications.show(3, 'Attention', 'Two messages', notificationsDetails3);
  }  
}

/// Test Notification
// Future<void> showChatNotificationTest() async {
//   final notificationsDetails3 = NotificationDetails(
//     android: AndroidNotificationDetails(
//     _channel.id,
//     _channel.name,
//   ));
//
//   await _notifications.show(3, 'Attention', 'Two messages', notificationsDetails3);
// }

/// Messagins Notification
// Future<void> showMessagingNotification() async {
//   const me = Person(name: 'Me', key: '1', uri: 'tel:1234567890');
//   const coworker = Person(name: 'Karol Triana', key: '2', uri: 'tel:9876543210');
//   const chef = Person(name: 'Tio Felipe', key: '3', uri: 'tel:111222333444');
//
//   final List<Message> messages = <Message>[
//     Message("Muchas gracias, este mensaje es largo para comprobar el expanded", DateTime.now().add(const Duration(minutes: 5)), coworker),
//     Message("Que haces", DateTime.now().add(const Duration(minutes: 5)), coworker),
//     Message('Hola lechu', DateTime.now().add(const Duration(minutes: 11)), chef),
//   ];
//
//   final MessagingStyleInformation messagingStyle = MessagingStyleInformation(me,
//       groupConversation: true, conversationTitle: 'Team lunch', htmlFormatContent: true, htmlFormatTitle: true, messages: messages);
//
//   final notificationDetails = NotificationDetails(
//       android: AndroidNotificationDetails(_channel.id, _channel.name,
//           channelDescription: _channel.description, category: AndroidNotificationCategory.message, styleInformation: messagingStyle));
//
//   await _notifications.show(0, 'message title', 'message body', notificationDetails);
//
//   // wait 10 seconds and add another message to simulate another response
//   // await Future<void>.delayed(const Duration(seconds: 10), () async {
//   //   messages.add(Message("Message 3", DateTime.now().add(const Duration(minutes: 11)), chef));
//   //   await _notifications.show(0, 'message title', 'message body', platformChannelSpecifics);
//   // });
// }

/// Inbox Notifications
// Future<void> showInboxNotification() async {
//   final String largeIconPath = await _downloadAndSaveFile('https://electronicssoftware.net/wp-content/uploads/user.png', 'largeIcon');
//
//   const styleInformation = InboxStyleInformation(
//     ['Muchas gracias Este es un mensaje largo', 'con la idea que cause un salto de linea', '<br>tercer mensaje'],
//     htmlFormatLines: true,
//     htmlFormatContent: true,
//   );
//
//   final notificationDetails1 = NotificationDetails(
//       android: AndroidNotificationDetails(
//     _channel.id,
//     _channel.name,
//     groupKey: _groupChannel.id,
//     largeIcon: FilePathAndroidBitmap(largeIconPath),
//     styleInformation: styleInformation,
//   ));
//
//   await _notifications.show(1, 'Karol Triana', 'Muchas gracias', notificationDetails1);
//
//   final notificationsDetails2 = NotificationDetails(
//       android: AndroidNotificationDetails(
//     _channel.id,
//     _channel.name,
//     groupKey: _groupChannel.id,
//     largeIcon: FilePathAndroidBitmap(largeIconPath),
//   ));
//
//   await _notifications.show(2, 'Tio Felipe', 'Hola lechu', notificationsDetails2);
//
//   final notificationsDetails3 = NotificationDetails(
//       android: AndroidNotificationDetails(
//     _channel.id,
//     _channel.name,
//     styleInformation: const InboxStyleInformation([]),
//     groupKey: _groupChannel.id,
//     setAsGroupSummary: true,
//   ));
//
//   await _notifications.show(3, 'Attention', 'Two messages', notificationsDetails3);
// }
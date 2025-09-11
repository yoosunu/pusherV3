// ignore_for_file: non_constant_identifier_names, avoid_print, no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pusher_v3/pages/login.dart';
import 'pages/home.dart';
import 'package:pusher_v3/fetch.dart';
import 'package:pusher_v3/notification.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@pragma('vm:entry-point')
void startCallback() async {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  bool isRunning = false;
  bool isLoading = true;
  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
    isRunning = true;
    isLoading = false;
  }

  // Called based on the eventAction set in ForegroundTaskOptions.
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Send data to main isolate.
    Map<String, dynamic> data = {
      "timestampMillis": timestamp.millisecondsSinceEpoch,
      "IsRunning": isRunning,
      "IsLoading": isLoading,
    };
    FlutterForegroundTask.sendDataToMain(data);

    // background posting logic
    getUserBG();
  }

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('onDestroy');
    isRunning = false;
    isLoading = true;
  }

  // Called when data is sent using `FlutterForegroundTask.sendDataToTask`.
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  // Called when the notification itself is pressed.
  @override
  void onNotificationPressed() {
    print('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}

Future<ServiceRequestResult> _startService() async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    return FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Pusher_V3',
      notificationText: 'PusherV3 is running',
      notificationIcon: NotificationIcon(
        metaDataName: 'com.example.pusher_v3.service.PEAR_ICON',
        backgroundColor: Colors.deepPurple[300],
      ),
      notificationButtons: [
        const NotificationButton(id: 'btn_stop', text: 'STOP'),
      ],
      notificationInitialRoute: '/',
      callback: startCallback,
    );
  }
}

Future<void> refreshATBG() async {
  const String url = "https://backend.apot.pro/api/v1/users/refresh-at";

  var _storage = const FlutterSecureStorage();
  String? refreshToken = await _storage.read(key: "refresh_token");

  var response = await http.post(Uri.parse(url),
      body: json.encode({"refresh_token": refreshToken}),
      headers: {'Content-Type': 'application/json'});

  if (response.statusCode == 200) {
    var atData = json.decode(response.body);
    String at = atData["access_token"];
    await _storage.write(key: "access_token", value: at);
  } else {
    await FlutterLocalNotification.showNotification(403, 'AT Error',
        'Failed to refresh AT with ${response.statusCode} | ${response.body}');
  }
}

Future<void> getUserBG() async {
  var _storage = const FlutterSecureStorage();

  const String url = "https://backend.apot.pro/api/v1/users/me";

  String? access_token = await _storage.read(key: "access_token");

  final responseGetUser = await http.get(Uri.parse(url), headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $access_token',
  });

  if (responseGetUser.statusCode == 200) {
    await postDataBG(access_token!);
  } else if (responseGetUser.statusCode == 403) {
    await refreshATBG();
    await getUserBG();
  } else {
    await refreshATBG();
    await getUserBG();
    await FlutterLocalNotification.showNotification(500, 'Get User Error',
        'Failed to get User with ${responseGetUser.statusCode} | ${responseGetUser.body}');
  }
}

Future<void> postDataBG(String accessToken) async {
  final List<String> urls = [
    'http://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=1&menu=2377/',
    'http://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=2&menu=2377',
    'http://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=3&menu=2377',
  ];

  final Uri url = Uri.parse('https://backend.apot.pro/api/v1/notifications/');

  List<INotificationBG> scrappedDataBG = [];
  var results = await Future.wait(urls.map(fetchInfosBG));

  for (var result in results) {
    scrappedDataBG.addAll(result);
  }

  for (INotificationBG data in scrappedDataBG) {
    try {
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(data.toJson()),
      );

      if (response.statusCode == 201) {
        await FlutterLocalNotification.showNotification(data.code, data.title,
            '${data.code} ${data.tag} ${data.writer} ${data.etc}');
        // print('succeed posting ${data.code}');
      }

      if (response.statusCode == 500) {
        await FlutterLocalNotification.showNotification(
            data.code, data.title, 'status 500 | ${data.code}');
        // print('500 error ${data.code} ${response.body}');
      } else {
        // await FlutterLocalNotification.showNotification(
        //     data.code, data.title, 'post Error with ${data.code}');
        // print(
        //     'Request failed with status: ${response.statusCode} | ${data.code} | ${response.body}');
      }
    } catch (e) {
      // print('Post error: $e');
      await FlutterLocalNotification.showNotification(2, 'Post error', '$e');
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterLocalNotification.init();
  FlutterLocalNotification.requestNotificationPermissionAndroid();
  FlutterForegroundTask.initCommunicationPort();

  _startService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PushserV3',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(
        title: 'Pusher',
      ),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => const HomePage(title: 'Home'),
        '/login': (BuildContext context) => const LoginPage(title: 'Login'),
      },
    );
  }
}

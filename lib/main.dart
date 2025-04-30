// ignore_for_file: non_constant_identifier_names, avoid_print

import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'pages/home.dart';
// import 'package:pusher_v3/fetch.dart';
import 'package:pusher_v3/notification.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// @pragma('vm:entry-point')
// void startCallback() async {
//   FlutterForegroundTask.setTaskHandler(MyTaskHandler());
// }

// class MyTaskHandler extends TaskHandler {
//   bool isRunning = false;
//   bool isLoading = true;
//   // Called when the task is started.
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     print('onStart(starter: ${starter.name})');
//     isRunning = true;
//     isLoading = false;
//   }

//   // Called based on the eventAction set in ForegroundTaskOptions.
//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // Send data to main isolate.
//     Map<String, dynamic> data = {
//       "timestampMillis": timestamp.millisecondsSinceEpoch,
//       "IsRunning": isRunning,
//       "IsLoading": isLoading,
//     };
//     FlutterForegroundTask.sendDataToMain(data);

//     // background posting logic
//     postDataBG();
//   }

//   // Called when the task is destroyed.
//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     print('onDestroy');
//     isRunning = false;
//     isLoading = true;
//   }

//   // Called when data is sent using `FlutterForegroundTask.sendDataToTask`.
//   @override
//   void onReceiveData(Object data) {
//     print('onReceiveData: $data');
//   }

//   // Called when the notification button is pressed.
//   @override
//   void onNotificationButtonPressed(String id) async {
//     if (await FlutterForegroundTask.isRunningService) {
//       await FlutterForegroundTask.stopService();
//     }
//   }

//   // Called when the notification itself is pressed.
//   @override
//   void onNotificationPressed() {
//     print('onNotificationPressed');
//   }

//   // Called when the notification itself is dismissed.
//   @override
//   void onNotificationDismissed() {
//     print('onNotificationDismissed');
//   }
// }

// Future<ServiceRequestResult> _startService() async {
//   if (await FlutterForegroundTask.isRunningService) {
//     return FlutterForegroundTask.restartService();
//   } else {
//     return FlutterForegroundTask.startService(
//       serviceId: 256,
//       notificationTitle: 'Pusher_V3',
//       notificationText: 'PusherV3 is running',
//       notificationIcon: NotificationIcon(
//         metaDataName: 'com.example.pusher_v3.service.PEAR_ICON',
//         backgroundColor: Colors.deepPurple[300],
//       ),
//       notificationButtons: [
//         const NotificationButton(id: 'btn_stop', text: 'STOP'),
//       ],
//       notificationInitialRoute: '/',
//       callback: startCallback,
//     );
//   }
// }

// Future<void> postDataBG() async {
//   final List<String> urls = [
//     'http://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=1&menu=2377/',
//     'http://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=2&menu=2377',
//     'http://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=3&menu=2377',
//   ];

//   final Uri url = Uri.parse('https://backend.apot.pro/api/v1/notifications/');

//   List<INotificationBG> scrappedDataBG = [];
//   var results = await Future.wait(urls.map(fetchInfosBG));

//   for (var result in results) {
//     scrappedDataBG.addAll(result);
//   }

//   for (INotificationBG data in scrappedDataBG) {
//     try {
//       var response = await http.post(
//         url,
//         headers: {
//           // 'Jwt': '$access_token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(data.toJson()), // 데이터를 JSON으로 인코딩
//       );

//       // 응답 상태 코드 확인
//       if (response.statusCode == 201) {
//         await FlutterLocalNotification.showNotification(data.code, data.title,
//             '${data.code} ${data.tag} ${data.writer} ${data.etc}');
//         // print('succeed posting ${data.code}');
//       }

//       if (response.statusCode == 500) {
//         await FlutterLocalNotification.showNotification(
//             data.code, data.title, 'status 500 | ${data.code}');
//         print('500 error ${data.code} ${response.body}');
//       } else {
//         // await FlutterLocalNotification.showNotification(
//         //     data.code, data.title, 'post Error with ${data.code}');
//         print(
//             'Request failed with status: ${response.statusCode} | ${data.code} | ${response.body}');
//       }
//       print('wow');
//     } catch (e) {
//       print('Post error: $e');
//       await FlutterLocalNotification.showNotification(2, 'Post error', '$e');
//     }
//   }
// }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterLocalNotification.init();
  FlutterLocalNotification.requestNotificationPermissionAndroid();
  FlutterForegroundTask.initCommunicationPort();

  // _startService();

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
      },
    );
  }
}

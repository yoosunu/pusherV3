// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pusher_v3/fetch.dart';
import 'package:intl/intl.dart';
import 'package:pusher_v3/notification.dart';
import 'package:pusher_v3/pages/save.dart';
import 'package:pusher_v3/sqldbinit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DatabaseHelper dbHelper = DatabaseHelper();
  late List<INotification> fetchedData = [];
  bool isLoading = true;

  bool isLoadingGet = true; // forBG
  bool isRunningGet = false; // forBG
  late DateTime timeStampGet; // forBG

  Future<void> _onReceiveTaskData(Object data) async {
    if (data is Map<String, dynamic>) {
      final dynamic timestampMillis = data["timestampMillis"];
      final bool isRunning = data["IsRunning"];
      final bool isLoading = data["IsLoading"];
      DateTime timestamp =
          DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true);
      setState(() {
        isRunningGet = isRunning;
        timeStampGet = timestamp;
        isLoadingGet = isLoading;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        // When you call this function, will be gone to the settings page.
        // So you need to explain to the user why set it.
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  void _initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
            1200000), // 10분: 600000, 20분: 1200000, 30분: 1800000,
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<List<INotification>> loadData() async {
    const String apiUrl = "https://backend.apot.pro/api/v1/notifications/";

    try {
      var response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Uint8List bodyBytes = response.bodyBytes;
        String decodedBody = utf8.decode(bodyBytes);
        List<dynamic> jsonData = json.decode(decodedBody);

        List<INotification> notifications =
            jsonData.map((item) => INotification.fromJson(item)).toList();

        notifications.sort((a, b) => b.code.compareTo(a.code));
        return notifications;
      } else {
        throw Exception(
            "Failed to load data: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      print("Error fetching data loadData: $e");
      return [];
    }
  }

  Future<List<INotification>> loadAndSetData() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<INotification>? data = await loadData();
      setState(() {
        fetchedData = data;
      });
    } catch (e) {
      print('Error loading data loadAndSetData: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    return fetchedData;
  }

  @override
  void initState() {
    loadAndSetData();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request permissions and initialize the service.
      _requestPermissions();
      _initService();
    });
    super.initState();
  }

  @override
  void dispose() {
    // Remove a callback to receive data sent from the TaskHandler.
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  void showPopup(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final notification = fetchedData[index].created_at;
        final formattedDate = DateFormat('yyyy-MM-dd').format(notification);
        return AlertDialog(
          key: UniqueKey(),
          title: Text(
            fetchedData[index].title,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: SizedBox(
              width: 300,
              height: 220,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark,
                          color: Colors.deepPurple[300],
                          size: 26,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          fetchedData[index].tag,
                          style: const TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Row(children: [
                      Icon(
                        Icons.apartment_rounded,
                        color: Colors.deepPurple[300],
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        fetchedData[index].writer,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Row(children: [
                      Icon(
                        Icons.calendar_month,
                        color: Colors.deepPurple[300],
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        fetchedData[index].etc,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                    child: Row(children: [
                      Icon(
                        Icons.more_time,
                        color: Colors.deepPurple[300],
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ]),
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(horizontal: 30.0),
                      ),
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse(fetchedData[index].link);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        throw fetchedData[index].link;
                      }
                    },
                    child: const Text(
                      'Go to site to check!',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              )),
          actions: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () async {
                await dbHelper.saveNotification({
                  DatabaseHelper.secondColumnCode: fetchedData[index].code,
                  DatabaseHelper.secondColumnTag: fetchedData[index].tag,
                  DatabaseHelper.secondColumnTitle: fetchedData[index].title,
                  DatabaseHelper.secondColumnLink: fetchedData[index].link,
                  DatabaseHelper.secondColumnWriter: fetchedData[index].writer,
                  DatabaseHelper.secondColumnEtc: fetchedData[index].etc,
                  DatabaseHelper.secondColumnCreatedAt:
                      (fetchedData[index].created_at).toIso8601String(),
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notice has been saved'),
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = fetchedData.isNotEmpty
        ? DateFormat(' MM-dd / HH:mm a')
            .format(fetchedData.first.created_at.toLocal())
        : 'No data available';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: isRunningGet
                  ? IconButton(
                      iconSize: 34,
                      onPressed: () {
                        FlutterLocalNotification.showNotification(
                            1, "test", "test message for debugging");
                      },
                      icon: const Icon(Icons.toggle_on_rounded),
                    )
                  : IconButton(
                      iconSize: 34,
                      onPressed: () {
                        FlutterLocalNotification.showNotification(
                            1, "test", "test message for debugging");
                      },
                      icon: const Icon(Icons.toggle_off_outlined),
                    ))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadAndSetData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : fetchedData.isEmpty
                ? const Center(child: Text('No data available'))
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: SizedBox(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(250, 50),
                                  backgroundColor: Colors.purple[50],
                                ),
                                onPressed: () {},
                                child: SizedBox(
                                  width: 240,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Updated: ',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white10,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                            alignment: Alignment.center,
                            child: ListView.builder(
                              itemCount: isLoading ? 1 : fetchedData.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(100, 55),
                                      alignment: Alignment.center,
                                    ),
                                    onPressed: () {
                                      showPopup(context, index);
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${fetchedData[index].code}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Padding(
                                            padding: EdgeInsets.all(10)),
                                        Expanded(
                                          child: Text(
                                            fetchedData[index].title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SavePage(title: "Saved")),
          );
        },
        tooltip: 'Fetch',
        child: const Icon(Icons.save_alt),
      ),
    );
  }
}

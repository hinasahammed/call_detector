import 'dart:developer';
import 'dart:ui';

import 'package:call_detector/call_data.dart';
import 'package:call_detector/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'call_detector_channel',
    'Call Detector Service',
    description: 'This channel is used for call detection service',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Changed to false to avoid auto-start issues
      isForegroundMode: true,
      notificationChannelId: 'call_detector_channel',
      initialNotificationTitle: 'Call Detector',
      initialNotificationContent: 'Monitoring calls in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false, // Changed to false
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification plugin for background service
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize database helper in background isolate
  final dbHelper = DatabaseHelper();

  // Listen to phone state changes in background isolate
  PhoneState.stream.listen((PhoneState state) async {
    try {
      log('Background isolate - Phone state changed: ${state.status}');
      await handlePhoneStateChange(
        state,
        dbHelper,
        flutterLocalNotificationsPlugin,
      );
    } catch (e) {
      log('Error handling phone state change: $e');
    }
  });

  service.on('stopService').listen((event) {
    log('Stopping background service');
    service.stopSelf();
  });

  // Send initial status
  service.invoke('serviceStarted', {'status': 'running'});
}

Future<void> handlePhoneStateChange(
  PhoneState state,
  DatabaseHelper dbHelper,
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    switch (state.status) {
      case PhoneStateStatus.CALL_INCOMING:
        // Store the number if available, or mark that we're expecting it
        final incomingNumber = state.number;
        log('Call incoming: $incomingNumber');

        await prefs.setString(
          'callStartTime',
          DateTime.now().toIso8601String(),
        );
        await prefs.setBool('callAnswered', false);
        await prefs.setBool('callSaved', false);

        // Only store number if it's actually available
        if (incomingNumber != null && incomingNumber.isNotEmpty) {
          await prefs.setString('currentCallNumber', incomingNumber);
          log('Stored incoming number: $incomingNumber');
        } else {
          await prefs.setString('currentCallNumber', 'Unknown');
          log('Number not available, marked as Unknown');
        }
        break;

      case PhoneStateStatus.CALL_STARTED:
        await prefs.setBool('callAnswered', true);

        // Try to get number again in case it wasn't available during CALL_INCOMING
        if (state.number != null && state.number!.isNotEmpty) {
          final currentStored = prefs.getString('currentCallNumber') ?? '';
          if (currentStored == 'Unknown') {
            await prefs.setString('currentCallNumber', state.number!);
            log('Updated number during call start: ${state.number}');
          }
        }
        log('Call answered');
        break;

      case PhoneStateStatus.CALL_ENDED:
        // Add delay to ensure we get the most recent number
        await Future.delayed(Duration(milliseconds: 500));

        // Try to get number one more time from current state
        if (state.number != null && state.number!.isNotEmpty) {
          final currentStored = prefs.getString('currentCallNumber') ?? '';
          if (currentStored == 'Unknown') {
            await prefs.setString('currentCallNumber', state.number!);
            log('Updated number during call end: ${state.number}');
          }
        }

        final currentNumber = prefs.getString('currentCallNumber');
        final alreadySaved = prefs.getBool('callSaved') ?? false;

        if (!alreadySaved &&
            currentNumber != null &&
            currentNumber.isNotEmpty) {
          await handleFinalCallStatus(prefs, dbHelper, notificationsPlugin);
        } else {
          log(
            'CALL_ENDED: alreadySaved=$alreadySaved, currentNumber=$currentNumber',
          );
        }
        break;

      default:
        break;
    }
  } catch (e) {
    log('Error in handlePhoneStateChange: $e');
  }
}

Future<void> handleFinalCallStatus(
  SharedPreferences prefs,
  DatabaseHelper dbHelper,
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
  // Double-check if already saved
  final alreadySaved = prefs.getBool('callSaved') ?? false;
  if (alreadySaved) {
    log('Call already saved. Skipping duplicate insert.');
    return;
  }

  final number = prefs.getString('currentCallNumber') ?? '';
  final startStr = prefs.getString('callStartTime') ?? '';
  final answered = prefs.getBool('callAnswered') ?? false;

  if (startStr.isEmpty) {
    log('Missing call start time, cannot save call');
    await _clearCallData(prefs);
    return;
  }

  // IMMEDIATELY mark as saved to prevent race conditions
  await prefs.setBool('callSaved', true);

  final startTime = DateTime.parse(startStr);
  final endTime = DateTime.now();
  final duration = endTime.difference(startTime);

  // Only save calls that last more than 1 second to avoid phantom calls
  if (duration.inSeconds < 1) {
    log('Call too short (${duration.inSeconds}s), not saving');
    await _clearCallData(prefs);
    return;
  }

  final callType = answered ? 'Answered' : 'Not Answered';
  final displayNumber = (number.isEmpty || number == 'Unknown')
      ? 'Private Number'
      : number;

  try {
    await dbHelper.insertCall(
      CallData(
        number: displayNumber,
        timestamp: startTime,
        duration: duration,
        type: callType,
      ),
    );

    log('Call saved: $displayNumber, $callType, ${duration.inSeconds}s');

    // Use timestamp-based notification ID to avoid conflicts
    final notificationId = startTime.millisecondsSinceEpoch % 2147483647;

    await notificationsPlugin.show(
      notificationId,
      'Call Ended - $callType',
      'Number: $displayNumber, Duration: ${duration.inSeconds}s',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'call_detector_channel',
          'Call Detector Service',
          channelDescription: 'Call detection notifications',
          importance: Importance.high,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    // Clear stored data after successful save
    await _clearCallData(prefs);
  } catch (e) {
    log('Error saving call: $e');
    // Reset saved flag if save failed
    await prefs.setBool('callSaved', false);
  }
}

// Helper function to clear call data
Future<void> _clearCallData(SharedPreferences prefs) async {
  await prefs.remove('currentCallNumber');
  await prefs.remove('callStartTime');
  await prefs.remove('callAnswered');
  await prefs.remove('callSaved');
  log('Call data cleared');
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Call Detector App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CallDetectorScreen(),
    );
  }
}

class CallDetectorScreen extends StatefulWidget {
  const CallDetectorScreen({super.key});

  @override
  State createState() => _CallDetectorScreenState();
}

class _CallDetectorScreenState extends State<CallDetectorScreen> {
  PhoneState status = PhoneState.nothing();
  bool granted = false;
  bool serviceRunning = false;
  List<CallData> callHistory = [];
  String currentCallNumber = '';
  DateTime? callStartTime;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    requestPermissions();
    checkServiceStatus();
    loadLocalCallHistory();

    // Listen to service messages
    FlutterBackgroundService().on('serviceStarted').listen((event) {
      setState(() {
        serviceRunning = true;
      });
    });
  }

  Future<void> checkServiceStatus() async {
    final service = FlutterBackgroundService();
    serviceRunning = await service.isRunning();
    setState(() {});
  }

  Future<void> requestPermissions() async {
    // Request multiple permissions including READ_PHONE_NUMBERS and CALL_LOG
    Map<Permission, PermissionStatus> permissions = await [
      Permission.phone,
      Permission.notification,
      Permission.systemAlertWindow,
    ].request();

    // Also request call log permission specifically (may help with number detection)
    try {
      await Permission.phone.request();
    } catch (e) {
      log('Error requesting call log permission: $e');
    }

    bool hasAllPermissions = permissions.values.every(
      (status) => status.isGranted,
    );

    if (hasAllPermissions) {
      setState(() {
        granted = true;
      });
      startPhoneStateListener();
      await loadLocalCallHistory();

      // Request to ignore battery optimization
      await requestBatteryOptimization();
    } else {
      showPermissionDialog();
    }
  }

  Future<void> requestBatteryOptimization() async {
    try {
      final permission = await Permission.ignoreBatteryOptimizations.request();
      if (permission.isGranted) {
        log('Battery optimization ignored');
      } else {
        log('Battery optimization not granted');
      }
    } catch (e) {
      log('Error requesting battery optimization: $e');
    }
  }

  void showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Required'),
        content: Text(
          'This app needs phone and notification permissions to detect calls in background.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  void startPhoneStateListener() {
    // Only listen in main isolate for UI updates
    PhoneState.stream.listen((PhoneState state) {
      log(
        'Main isolate - Phone state: ${state.status}, Number: ${state.number}',
      );
      setState(() {
        status = state;
      });
    });
  }

  Future<void> loadLocalCallHistory() async {
    try {
      List<CallData> calls = await _dbHelper.getAllCalls();
      setState(() {
        callHistory = calls;
      });
      log('Loaded ${calls.length} calls from database');
    } catch (e) {
      log('Error loading local call history: $e');
    }
  }

  Future<void> startBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        log('Background service started');
      } else {
        log('Background service already running');
      }

      await Future.delayed(Duration(seconds: 1));
      await checkServiceStatus();
    } catch (e) {
      log('Error starting background service: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting service: $e')));
    }
  }

  Future<void> stopBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke("stopService");

      await Future.delayed(Duration(seconds: 1));
      await checkServiceStatus();
      log('Background service stopped');
    } catch (e) {
      log('Error stopping background service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Detector'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadLocalCallHistory,
          ),
        ],
      ),
      body: granted
          ? Column(
              children: [
                _buildStatusCard(),
                _buildServiceControlCard(),
                _buildCallHistorySection(),
              ],
            )
          : _buildPermissionRequiredView(),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Phone State',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 16,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceControlCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Background Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  serviceRunning ? Icons.check_circle : Icons.cancel,
                  color: serviceRunning ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  serviceRunning ? 'Running' : 'Stopped',
                  style: TextStyle(
                    fontSize: 16,
                    color: serviceRunning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: serviceRunning ? null : startBackgroundService,
                  child: Text('Start Service'),
                ),
                ElevatedButton(
                  onPressed: serviceRunning ? stopBackgroundService : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Stop Service'),
                ),
              ],
            ),
            if (!serviceRunning) ...[
              SizedBox(height: 12),
              Text(
                'Start the service to detect calls in background',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCallHistorySection() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Call History (${callHistory.length})',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: loadLocalCallHistory,
                      child: Text('Refresh'),
                    ),
                    if (callHistory.isNotEmpty)
                      IconButton(
                        onPressed: () => _showClearHistoryDialog(),
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: callHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_disabled,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No calls detected yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          serviceRunning
                              ? 'Background service is running. Make a call to test.'
                              : 'Start background service to detect calls',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: callHistory.length,
                    itemBuilder: (context, index) {
                      CallData call = callHistory[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _getCallTypeIcon(call.type),
                            color: _getCallTypeColor(call.type),
                          ),
                          title: Text(
                            call.number,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                call.timestamp.toString().substring(0, 19),
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Duration: ${call.duration.inMinutes}m ${call.duration.inSeconds % 60}s',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              call.type,
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getCallTypeColor(
                              call.type,
                            ).withValues(alpha: .2),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Call History'),
        content: Text('Are you sure you want to delete all call history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dbHelper.deleteAllCalls();
              await loadLocalCallHistory();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Call history cleared')));
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequiredView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Permissions Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please grant phone and notification permissions to detect calls in background',
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: requestPermissions,
            child: Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  // Helper methods remain the same...
  IconData _getStatusIcon() {
    switch (status.status) {
      case PhoneStateStatus.CALL_INCOMING:
        return Icons.call_received;
      case PhoneStateStatus.CALL_STARTED:
        return Icons.call;
      case PhoneStateStatus.CALL_ENDED:
        return Icons.call_end;
      default:
        return Icons.phone_disabled;
    }
  }

  Color _getStatusColor() {
    switch (status.status) {
      case PhoneStateStatus.CALL_INCOMING:
        return Colors.blue;
      case PhoneStateStatus.CALL_STARTED:
        return Colors.green;
      case PhoneStateStatus.CALL_ENDED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status.status) {
      case PhoneStateStatus.CALL_INCOMING:
        return 'Incoming Call';
      case PhoneStateStatus.CALL_STARTED:
        return 'Call In Progress';
      case PhoneStateStatus.CALL_ENDED:
        return 'Call Ended';
      default:
        return 'Idle';
    }
  }

  IconData _getCallTypeIcon(String type) {
    switch (type) {
      case 'Incoming':
      case 'Answered':
        return Icons.call_received;
      case 'Outgoing':
        return Icons.call_made;
      case 'Missed':
        return Icons.call_received;
      case 'Rejected':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  Color _getCallTypeColor(String type) {
    switch (type) {
      case 'Incoming':
      case 'Answered':
        return Colors.green;
      case 'Outgoing':
        return Colors.blue;
      case 'Missed':
        return Colors.red;
      case 'Rejected':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:call_detector/data/local/database_helper.dart';
import 'package:call_detector/view/splash/splash_view.dart';
import 'package:call_detector/viewmodel/background_service.dart';
import 'package:call_detector/viewmodel/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pref = await SharedPreferences.getInstance();
  await BackgroundService.initializeService();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(pref)],
      child: const MyApp(),
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

  // Initialize customer service for background checks
  final customerService = BackgroundService();

  // Set service running status
  BackgroundService.setServiceRunning(true);

  // Start periodic call log fetching
  customerService.syncLocalCallLogs();

  // Listen to phone state changes in background isolate
  PhoneState.stream.listen((PhoneState state) async {
    try {
      log('Background isolate - Phone state changed: ${state.status}');

      await BackgroundService.handlePhoneStateChange(
        state,
        dbHelper,
        customerService,
      );
    } catch (e) {
      log('Error handling phone state change: $e');
    }
  });

  // Handle stop service command
  service.on('stopService').listen((event) {
    log('Stopping background service - received stopService command');
    BackgroundService.setServiceRunning(false);
    customerService.stopPeriodicCallLogFetching();

    // Notify main app that service is stopping
    try {
      service.invoke('serviceStopped', {'status': 'stopped'});
    } catch (e) {
      log('Error invoking serviceStopped: $e');
    }

    service.stopSelf();
  });

  // Handle system stopping the service
  service.on('stop').listen((event) {
    log('Background service stopped by system');
    BackgroundService.setServiceRunning(false);
    customerService.stopPeriodicCallLogFetching();

    // Notify main app that service stopped
    try {
      service.invoke('serviceStopped', {'status': 'stopped'});
    } catch (e) {
      log('Error invoking serviceStopped on system stop: $e');
    }
  });

  // Send periodic heartbeat to main app (optional - helps with status tracking)
  Timer.periodic(const Duration(seconds: 10), (timer) {
    try {
      if (BackgroundService.serviceRunning) {
        service.invoke('serviceHeartbeat', {
          'status': 'running',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        timer.cancel();
      }
    } catch (e) {
      log('Error sending heartbeat: $e');
      timer.cancel();
    }
  });

  // Send initial status
  try {
    service.invoke('serviceStarted', {'status': 'running'});
    log('Background service started successfully');
  } catch (e) {
    log('Error invoking serviceStarted: $e');
  }
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
      home: const SplashView(),
    );
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:call_detector/data/local/database_helper.dart';
import 'package:call_detector/data/network/network_api_service.dart';
import 'package:call_detector/main.dart';
import 'package:call_detector/model/call_data_model.dart';
import 'package:call_detector/model/customerStatus/customer_status_model.dart';
import 'package:call_detector/repository/homeRepository/home_repository.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:phone_state/phone_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  final NetworkApiService networkApiService;
  late final HomeRepository repo;

  BackgroundService() : networkApiService = NetworkApiService() {
    repo = HomeRepository(networkApiService: networkApiService);
  }

  Timer? _callLogTimer;
  static const Duration _callLogInterval = Duration(minutes: 5);
  static bool serviceRunning = false;

  static Future<void> initializeService() async {
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
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'call_detector_channel',
        initialNotificationTitle: 'Call Detector',
        initialNotificationContent: 'Monitoring calls in background',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<CustomerStatusModel> isCustomer(String number) async {
    try {
      // Clean the number for comparison (remove spaces, dashes, etc.)
      String cleanNumber = number.replaceAll(
        RegExp(r'[^\d]'),
        '',
      ); // keep only digits
      if (cleanNumber.startsWith("91") && cleanNumber.length > 10) {
        cleanNumber = cleanNumber.substring(
          cleanNumber.length - 10,
        ); // keep last 10 digits
      }

      final isClient = await repo.isCustomerCall(number: cleanNumber);
      return isClient;
    } catch (e) {
      log('Error checking customer status: $e');
      return CustomerStatusModel(
        isCustomer: false,
      ); // Fail safe - don't store if unsure
    }
  }

  static Future<void> handlePhoneStateChange(
    PhoneState state,
    DatabaseHelper dbHelper,
    BackgroundService customerService,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      switch (state.status) {
        case PhoneStateStatus.CALL_INCOMING:
          final incomingNumber = state.number;
          log('Call incoming: $incomingNumber');

          // Only proceed if we have a valid number
          if (incomingNumber != null && incomingNumber.isNotEmpty) {
            log('Checking if $incomingNumber is a customer...');

            // Check if the incoming number is from a customer
            final status = await customerService.isCustomer(incomingNumber);

            log(
              'Customer check result for $incomingNumber: ${status.isCustomer}',
            );

            if (status.isCustomer) {
              await prefs.setString(
                'callStartTime',
                DateTime.now().toIso8601String(),
              );
              await prefs.setBool('callSaved', false);
              await prefs.setString('currentCallNumber', incomingNumber);
              await prefs.setString('customerName', status.billingName);
              await prefs.setString('customerCode', status.customerCode);
              await prefs.setBool('isCustomerCall', true);

              log(
                'Customer incoming call detected and stored: $incomingNumber (Code: ${status.customerCode})',
              );
            } else {
              await prefs.setBool('isCustomerCall', false);
              log(
                'Non-customer incoming call detected, will be ignored: $incomingNumber',
              );
            }
          } else {
            // No number available, mark to ignore
            await prefs.setBool('isCustomerCall', false);
            log('No number available for incoming call, will be ignored');
          }
          break;

        case PhoneStateStatus.CALL_STARTED:
          log('Call answered/started');
          break;

        case PhoneStateStatus.CALL_ENDED:
          await Future.delayed(const Duration(milliseconds: 500));

          // Check if this was a customer call before processing
          final isCustomerCall = prefs.getBool('isCustomerCall') ?? false;

          if (!isCustomerCall) {
            log(
              'Call ended but was not a trackable customer call, ignoring...',
            );
            await clearCallData(prefs);
            return;
          }

          // Update number if available during call end (for customer calls only)
          if (state.number != null && state.number!.isNotEmpty) {
            final currentStored = prefs.getString('currentCallNumber') ?? '';
            if (currentStored.isEmpty || currentStored == 'Unknown') {
              await prefs.setString('currentCallNumber', state.number!);
              log('Updated customer number during call end: ${state.number}');
            }
          }

          final currentNumber = prefs.getString('currentCallNumber');
          final alreadySaved = prefs.getBool('callSaved') ?? false;

          if (!alreadySaved &&
              currentNumber != null &&
              currentNumber.isNotEmpty) {
            await handleFinalCallStatus(prefs, dbHelper);
          } else {
            log(
              'CALL_ENDED: alreadySaved=$alreadySaved, currentNumber=$currentNumber',
            );
            await clearCallData(prefs);
          }
          break;

        default:
          break;
      }
    } catch (e) {
      log('Error in handlePhoneStateChange: $e');
    }
  }

  static Future<void> handleFinalCallStatus(
    SharedPreferences prefs,
    DatabaseHelper dbHelper,
  ) async {
    // Double-check if already saved
    final alreadySaved = prefs.getBool('callSaved') ?? false;
    if (alreadySaved) {
      log('Call already saved. Skipping duplicate insert.');
      return;
    }

    // Double-check if this was a customer call
    final isCustomerCall = prefs.getBool('isCustomerCall') ?? false;
    if (!isCustomerCall) {
      log('Not a trackable customer call, skipping save.');
      await clearCallData(prefs);
      return;
    }

    final number = prefs.getString('currentCallNumber') ?? '';
    final customerName = prefs.getString('customerName') ?? "Unknown";
    final customerCode = prefs.getString('customerCode') ?? '';
    final startStr = prefs.getString('callStartTime') ?? '';
    final callSource = prefs.getString('callSource') ?? 'unknown';

    if (startStr.isEmpty) {
      log('Missing call start time, cannot save call');
      await clearCallData(prefs);
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
      await clearCallData(prefs);
      return;
    }

    final displayNumber = (number.isEmpty || number == 'Unknown')
        ? 'Private Number'
        : number;

    // Format date and time separately
    final String callDate =
        '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
    final String callTime =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:${startTime.second.toString().padLeft(2, '0')}';

    try {
      await dbHelper.insertCall(
        CallData(
          number: displayNumber,
          date: callDate,
          time: callTime,
          duration: duration.inSeconds.toString(),
          username: customerName,
          customerCode: customerCode.isNotEmpty ? customerCode : null,
        ),
      );

      // Create notification message based on call source
      String notificationTitle = 'Customer Call Ended';
      switch (callSource) {
        case 'customer_incoming':
          notificationTitle = 'Incoming Customer Call Ended';
          break;
        case 'app_outgoing':
          notificationTitle = 'App Call Ended';
          break;
        default:
          notificationTitle = 'Customer Call Ended';
      }

      log(
        '$notificationTitle: $displayNumber ($customerName), Duration: ${duration.inSeconds}s, Customer Code: $customerCode',
      );

      // Clear stored data after successful save
      await clearCallData(prefs);
    } catch (e) {
      log('Error saving customer call: $e');
      // Reset saved flag if save failed
      await prefs.setBool('callSaved', false);
    }
  }

  // Helper function to clear call data
  static Future<void> clearCallData(SharedPreferences prefs) async {
    await prefs.remove('clearCallData');
    await prefs.remove('callSaved');
    await prefs.remove('currentCallNumber');
    await prefs.remove('customerName');
    await prefs.remove('customerCode');
    await prefs.remove('callStartTime');
    await prefs.remove('callSource');
    await prefs.remove('callSource');
  }

  void syncLocalCallLogs({bool isperiodic = true}) {
    if (!serviceRunning) {
      log(
        'Background service not running, cannot start periodic call log fetching',
      );
      return;
    }

    stopPeriodicCallLogFetching(); // Stop existing timer if any

    log(
      'Starting periodic call log syncing every ${_callLogInterval.inMinutes} minutes',
    );

    // Fetch immediately when starting
    syncCallLogs();

    // Then fetch periodically
    if (isperiodic) {
      _callLogTimer = Timer.periodic(_callLogInterval, (timer) {
        syncCallLogs();
      });
    }
  }

  void stopPeriodicCallLogFetching() {
    _callLogTimer?.cancel();
    _callLogTimer = null;
    log('Stopped periodic call log fetching');
  }

  Future<void> syncCallLogs({bool checkServiceRunning = true}) async {
    if (checkServiceRunning) {
      if (!serviceRunning) {
        log('Background service not running, skipping call log syncing');
        return;
      }
    }

    try {
      log('syncing call logs periodically...');
      final dbHelper = DatabaseHelper();
      final unsyncedCalls = await dbHelper.getUnsyncedCalls();

      for (var call in unsyncedCalls) {
        try {
          await repo.syncCallLog(
            customerCode: call.customerCode ?? "0",
            date: call.date,
            time: call.time,
          );

          // Mark this specific call as synced after successful sync
          await dbHelper.updateSyncStatus(
            call.number,
            call.date,
            call.time,
            true,
          );
        } catch (e) {
          log('Error syncing individual call ${call.number}: $e');
          // Continue with next call instead of breaking the loop
        }
      }

      _cleanupSyncedCalls();

      log('Call logs sync process completed');
    } catch (e) {
      log('Error in sync process: $e');
    }
  }

  // Optional: Method to clean up old synced calls periodically
  void _cleanupSyncedCalls() async {
    try {
      final dbHelper = DatabaseHelper();

      final syncedCount = await dbHelper.getCallCount(synced: true);

      if (syncedCount > 0) {
        final deletedCount = await dbHelper.deleteAllSyncedCalls();
        log('Cleaned up $deletedCount synced call logs');
      }
    } catch (e) {
      log('Error cleaning up synced calls: $e');
    }
  }

  static Future<void> fetchCallLogsIfServiceRunning() async {
    if (!serviceRunning) {
      log('Background service not running, skipping call log fetch');
      return;
    }

    final networkApiService = NetworkApiService();
    final repo = HomeRepository(networkApiService: networkApiService);
    try {
      log('Fetching call logs periodically...');
      await repo.fetchCallLogs();
      log('Call logs fetched successfully');
    } catch (e) {
      log('Error fetching call logs: $e');
    }
  }

  // Method to set service running status
  static void setServiceRunning(bool running) {
    serviceRunning = running;
    log('Service running status set to: $running');
  }
}

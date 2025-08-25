import 'dart:async';
import 'dart:developer';

import 'package:call_detector/data/response/status.dart';
import 'package:call_detector/res/components/text/label_large_text.dart';
import 'package:call_detector/res/components/text/label_medium_text.dart';
import 'package:call_detector/res/components/text/label_small_text.dart';
import 'package:call_detector/res/utils/toast_service.dart';
import 'package:call_detector/view/home/widget/action_needed.dart';
import 'package:call_detector/view/home/widget/action_needed_status.dart';
import 'package:call_detector/view/home/widget/call_attented.dart';
import 'package:call_detector/view/home/widget/call_attented_status.dart';
import 'package:call_detector/view/home/widget/call_log_empty_widget.dart';
import 'package:call_detector/view/home/widget/call_log_sync_card.dart';
import 'package:call_detector/view/home/widget/service_control_card.dart';
import 'package:call_detector/view/home/widget/solved.dart';
import 'package:call_detector/view/home/widget/solved_status.dart';
import 'package:call_detector/viewmodel/background_service.dart';
import 'package:call_detector/viewmodel/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _CallDetectorScreenState();
}

class _CallDetectorScreenState extends ConsumerState<HomeView>
    with WidgetsBindingObserver {
  PhoneState status = PhoneState.nothing();
  bool granted = false;
  bool serviceRunning = false;
  Timer? _serviceCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestPermissions();

    // Check service status immediately and then periodically
    _checkServiceStatus();
    _startServiceStatusCheck();

    // Listen to service events
    FlutterBackgroundService().on('serviceStarted').listen((event) {
      log('Service started event received: $event');
      if (mounted) {
        setState(() {
          serviceRunning = true;
        });
      }
    });

    FlutterBackgroundService().on('serviceStopped').listen((event) {
      log('Service stopped event received: $event');
      if (mounted) {
        setState(() {
          serviceRunning = false;
        });
      }
    });

    // Listen to service heartbeat (optional - for better status tracking)
    FlutterBackgroundService().on('serviceHeartbeat').listen((event) {
      // This helps ensure we know the service is actually running
      if (mounted && !serviceRunning) {
        log('Service heartbeat received, updating status to running');
        setState(() {
          serviceRunning = true;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      fetch();
    });
  }

  @override
  void dispose() {
    _serviceCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check service status when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
    }
  }

  // Start periodic service status checking
  void _startServiceStatusCheck() {
    _serviceCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkServiceStatus();
    });
  }

  // Check current service status
  Future<void> _checkServiceStatus() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (mounted && serviceRunning != isRunning) {
        log('Service status changed: $serviceRunning -> $isRunning');
        setState(() {
          serviceRunning = isRunning;
        });
      }
    } catch (e) {
      log('Error checking service status: $e');
    }
  }

  Future<void> requestPermissions() async {
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
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs phone and notification permissions to detect calls in background.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
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
      if (mounted) {
        setState(() {
          status = state;
        });
      }
    });
  }

  Future<void> startBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();

      if (!isRunning) {
        await service.startService();
        log('Background service started');
        // Force check status after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        _checkServiceStatus();
      } else {
        log('Background service already running');
        setState(() {
          serviceRunning = true;
        });
      }
    } catch (e) {
      log('Error starting background service: $e');
      ToastService.showToast(message: "Error starting service: $e");
    }
  }

  Future<void> stopBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke("stopService");

      // Update UI immediately and then verify after a delay
      setState(() {
        serviceRunning = false;
      });

      // Double-check status after a delay
      await Future.delayed(const Duration(milliseconds: 500));
      _checkServiceStatus();

      log('Background service stopped');
    } catch (e) {
      log('Error stopping background service: $e');
    }
  }

  Future fetch() async {
    final service = BackgroundService();
    await service.syncCallLogs(checkServiceRunning: false);
    final viewmodel = ref.read(homeViewmodelProvider.notifier);
    await viewmodel.fetchCalllogs();
  }

  @override
  Widget build(BuildContext context) {
    final viewmodel = ref.read(homeViewmodelProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Detector'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetch();
          _checkServiceStatus(); // Also refresh service status
        },
        child: ListView(
          children: [
            granted
                ? ServiceControlCard(
                    serviceRunning: serviceRunning,
                    startBackgroundService: startBackgroundService,
                    stopBackgroundService: stopBackgroundService,
                  )
                : _buildPermissionRequiredView(),

            if (serviceRunning) const CallLogSyncCard(),
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(homeViewmodelProvider);
                final status = state.callLogStatus;
                final callLogs = state.callLogs;
                return switch (status) {
                  Status.initial => Container(),
                  Status.error => const Center(
                    child: LabelLargeText(text: "Something went wrong"),
                  ),
                  Status.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  Status.completed => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Call History (${callLogs.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      callLogs.isEmpty
                          ? CallLogEmptyWidget(isServiceRunning: serviceRunning)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: callLogs
                                  .map(
                                    (call) => Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    LabelLargeText(
                                                      text:
                                                          call.billingName ??
                                                          "",
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    LabelMediumText(
                                                      text:
                                                          call.registredMobileNumber ??
                                                          "",
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    LabelSmallText(
                                                      text: call.tot ?? "",
                                                    ),
                                                    const Gap(8),
                                                    if ((call.actionNeeded ??
                                                            "0") ==
                                                        "0")
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: ActionNeeded(
                                                              onTap: () async {
                                                                await viewmodel
                                                                    .updateAction(
                                                                      id:
                                                                          call.callLogId ??
                                                                          "0",
                                                                      action:
                                                                          "1",
                                                                    );
                                                              },
                                                            ),
                                                          ),
                                                          // Solved Button
                                                          Expanded(
                                                            child: Solved(
                                                              onTap: () async {
                                                                await viewmodel
                                                                    .updateAction(
                                                                      id:
                                                                          call.callLogId ??
                                                                          "0",
                                                                      action:
                                                                          "2",
                                                                    );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    else if ((call
                                                                .actionNeeded ??
                                                            "") ==
                                                        "1")
                                                      const ActionNeededStatus()
                                                    else
                                                      const SolvedStatus(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if ((call.attended ?? "") == "0")
                                              CallAttented(
                                                onPressed: () async {
                                                  await viewmodel
                                                      .updateAttented(
                                                        id:
                                                            call.callLogId ??
                                                            "0",
                                                        attented: "1",
                                                      );
                                                },
                                              )
                                            else
                                              const CallAttentedStatus(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ],
                  ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequiredView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Permissions Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Please grant phone and notification permissions to detect calls in background',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: requestPermissions,
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }
}

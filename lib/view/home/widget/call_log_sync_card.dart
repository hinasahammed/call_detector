import 'package:call_detector/viewmodel/background_service.dart';
import 'package:flutter/material.dart';

class CallLogSyncCard extends StatelessWidget {
  const CallLogSyncCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cloud_sync, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Call Log Sync',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Auto-sync every ${5} minutes',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                final service = BackgroundService();
                service.syncCallLogs();
              },
              icon: const Icon(Icons.cloud_upload),
            ),
          ],
        ),
      ),
    );
  }
}

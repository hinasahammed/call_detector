import 'package:flutter/material.dart';

class CallLogEmptyWidget extends StatelessWidget {
  const CallLogEmptyWidget({super.key, required this.isServiceRunning});
  final bool isServiceRunning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No calls detected yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            isServiceRunning
                ? 'Background service is running. Make a call to test.'
                : 'Start background service to detect calls',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

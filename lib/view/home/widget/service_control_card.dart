import 'package:call_detector/res/components/buttons/custom_button.dart';
import 'package:call_detector/res/components/text/body_large_text.dart';
import 'package:call_detector/res/components/text/label_large_text.dart';
import 'package:call_detector/res/components/text/label_medium_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ServiceControlCard extends StatelessWidget {
  const ServiceControlCard({
    super.key,
    required this.serviceRunning,
    this.startBackgroundService,
    this.stopBackgroundService,
  });
  final bool serviceRunning;
  final void Function()? startBackgroundService;
  final void Function()? stopBackgroundService;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 8,
          children: [
            const BodyLargeText(
              text: "Background Service",
              fontWeight: FontWeight.w600,
            ),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  serviceRunning ? Icons.check_circle : Icons.cancel,
                  color: serviceRunning ? Colors.green : Colors.red,
                  size: 24,
                ),
                LabelLargeText(
                  text: serviceRunning ? 'Running' : 'Stopped',
                  textColor: serviceRunning ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
            const Gap(8),
            Row(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomButton(
                  borderRadius: BorderRadius.circular(30),
                  onPressed: serviceRunning ? null : startBackgroundService,
                  btnText: "Start Service",
                ),
                CustomButton(
                  borderRadius: BorderRadius.circular(30),
                  bgColor: Colors.red,
                  foregroundColor: Colors.white,
                  onPressed: serviceRunning ? stopBackgroundService : null,
                  btnText: "Stop Service", // Fixed: was "Start Service"
                ),
              ],
            ),
            if (!serviceRunning) ...[
              const Gap(2),
              const LabelMediumText(
                text: "Start the service to detect calls in background",
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
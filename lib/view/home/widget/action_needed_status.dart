import 'package:call_detector/res/components/text/label_medium_text.dart';
import 'package:flutter/material.dart';

class ActionNeededStatus extends StatelessWidget {
  const ActionNeededStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const LabelMediumText(
        text: "Action needed",
        textColor: Colors.amber,
      ),
    );
  }
}

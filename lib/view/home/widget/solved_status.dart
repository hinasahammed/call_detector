import 'package:call_detector/res/components/text/label_medium_text.dart';
import 'package:flutter/material.dart';

class SolvedStatus extends StatelessWidget {
  const SolvedStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const LabelMediumText(text: "Solved", textColor: Colors.blue),
    );
  }
}

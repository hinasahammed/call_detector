import 'package:call_detector/res/components/text/label_medium_text.dart';
import 'package:flutter/material.dart';

class CallAttentedStatus extends StatelessWidget {
  const CallAttentedStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: .15),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: 
      const LabelMediumText(text: "Attented",textColor: Colors.green,)
    );
  }
}

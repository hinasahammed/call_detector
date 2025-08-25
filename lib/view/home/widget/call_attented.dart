import 'package:flutter/material.dart';

class CallAttented extends StatelessWidget {
  const CallAttented({super.key, this.onPressed});
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.call, color: Colors.white),
      ),
    );
  }
}

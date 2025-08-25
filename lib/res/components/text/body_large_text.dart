import 'package:flutter/material.dart';

class BodyLargeText extends StatelessWidget {
  const BodyLargeText({
    super.key,
    required this.text,
    this.textColor,
    this.fontWeight,
  });
  final String text;
  final Color? textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyLarge!.copyWith(
        color: textColor ?? theme.colorScheme.onSurface,
        fontWeight: fontWeight,
      ),
    );
  }
}

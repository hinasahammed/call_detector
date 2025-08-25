import 'package:flutter/material.dart';

class HeadlineLargeText extends StatelessWidget {
  const HeadlineLargeText({
    super.key,
    required this.text,
    this.textColor,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });
  final String text;
  final Color? textColor;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.headlineLarge!.copyWith(
        color: textColor ?? theme.colorScheme.onSurface,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

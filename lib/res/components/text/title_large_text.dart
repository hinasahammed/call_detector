import 'package:flutter/material.dart';

class TitleLargeText extends StatelessWidget {
  const TitleLargeText({
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
      style: theme.textTheme.titleLarge!.copyWith(
        color: textColor ?? theme.colorScheme.onSurface,
        fontWeight: fontWeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

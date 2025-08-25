import 'package:flutter/material.dart';

class LabelSmallText extends StatelessWidget {
  const LabelSmallText({
    super.key,
    required this.text,
    this.textColor,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.lineHeight,
  });
  final String text;
  final Color? textColor;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall!.copyWith(
        color: textColor ?? theme.colorScheme.onSurface,
        fontWeight: fontWeight ?? FontWeight.w400,
        decoration: decoration,
        height: lineHeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

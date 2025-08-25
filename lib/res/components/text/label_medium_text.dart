import 'package:flutter/material.dart';

class LabelMediumText extends StatelessWidget {
  const LabelMediumText({
    super.key,
    required this.text,
    this.textColor,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.linHeight,
  });
  final String text;
  final Color? textColor;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final double? linHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium!.copyWith(
        color: textColor ?? theme.colorScheme.onSurface,
        fontWeight: fontWeight ?? FontWeight.w400,
        decoration: decoration,
        height: linHeight,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

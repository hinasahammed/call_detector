import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.onPressed,
    required this.btnText,
    this.width,
    this.height,
    this.btnIcon,
    this.bgColor,
    this.foregroundColor,
    this.textAlign,
    this.borderColor,
    this.padding,
    this.isLoading = false,
    this.loadingText,
    this.borderRadius,
  });
  final void Function()? onPressed;
  final String btnText;
  final double? width;
  final double? height;
  final IconData? btnIcon;
  final Color? bgColor;
  final Color? foregroundColor;
  final TextAlign? textAlign;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final String? loadingText;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height ?? 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor ?? colorScheme.primary,
          foregroundColor: foregroundColor ?? colorScheme.onPrimary,
          padding: padding,
          iconColor: colorScheme.onPrimary,
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: .8),
          shape: RoundedRectangleBorder(
            side: borderColor == null
                ? BorderSide.none
                : BorderSide(color: colorScheme.primary),
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 3,
                ),
              )
            : btnIcon != null
            ? Icon(btnIcon)
            : null,
        label: Text(
          isLoading ? loadingText ?? "" : btnText,
          textAlign: textAlign,
        ),
      ),
    );
  }
}

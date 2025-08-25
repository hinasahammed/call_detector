import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextformField extends StatelessWidget {
  const CustomTextformField({
    super.key,
    this.controller,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
    required this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.fillColor,
    this.focusNode,
    this.onTapOutside,
    this.isObsecure = false,
    this.isEnabled = true,
    this.maxLine,
    this.readOnly = false,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
  });
  final TextEditingController? controller;
  final bool autofocus;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final String labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final Color? fillColor;
  final FocusNode? focusNode;
  final void Function(PointerDownEvent)? onTapOutside;
  final bool isObsecure;
  final bool isEnabled;
  final int? maxLine;
  final bool readOnly;
  final void Function()? onTap;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      onTap: onTap,
      enabled: isEnabled,
      readOnly: readOnly,
      controller: controller,
      obscureText: isObsecure,
      onTapOutside: onTapOutside,
      textAlign: textAlign,
      autofocus: autofocus,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      focusNode: focusNode,
      maxLines: isObsecure ? 1 : maxLine,
      inputFormatters: inputFormatters,
      decoration:
          decoration ??
          InputDecoration(
            alignLabelWithHint: true,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: .2),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: .2),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: .2),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: .8),
                width: 2,
              ),
            ),
            // labelText: labelText,
            hintText: labelText,
            filled: true,
            fillColor: fillColor ?? theme.colorScheme.surface,
          ),
    );
  }
}

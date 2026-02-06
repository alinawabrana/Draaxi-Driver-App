import 'package:flutter/material.dart';
import 'package:draaxi_driver/src/common/widgets/primary_text_form_field.dart';

class PasswordFormField extends StatefulWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.onChanged,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryTextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      hintText: widget.hintText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        onPressed: _toggleVisibility,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../utils/helpers/helper_function.dart';

class DropdownFormField extends StatelessWidget {
  const DropdownFormField({
    super.key,
    required this.hintText,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
  });

  final String hintText;
  final List<DropdownMenuItem<String>> items;
  final String? value;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = AHelperFunction.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items,
            style: textTheme.bodyMedium,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: textTheme.bodyMedium,
              errorStyle: textTheme.bodySmall?.copyWith(
                height: 1,
                color: colorScheme.error,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              suffixIcon: SizedBox(
                width: 14,
                height: 7,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 24,
                  color: isDark
                      ? const Color(0xFFF7F7F7)
                      : const Color(0xFF414141),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

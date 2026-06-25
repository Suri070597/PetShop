import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class PetTextField extends StatelessWidget {
  const PetTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.38)),
      ),
    );

    if (labelText == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 8),
          child: Text(
            labelText!,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        field,
      ],
    );
  }
}

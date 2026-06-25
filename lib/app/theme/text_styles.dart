import 'package:flutter/material.dart';

import 'colors.dart';

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontSize: 36,
    height: 1.12,
    fontWeight: FontWeight.w800,
    color: AppColors.forest,
  );

  static const title = TextStyle(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  static const section = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );
}

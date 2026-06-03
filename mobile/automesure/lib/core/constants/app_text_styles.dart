import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static final heading1 = GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static final heading2 = GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static final heading3 = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static final body = GoogleFonts.inter(
    fontSize: 14, color: AppColors.textPrimary,
  );
  static final bodySecondary = GoogleFonts.inter(
    fontSize: 14, color: AppColors.textSecondary,
  );
  static final caption = GoogleFonts.inter(
    fontSize: 12, color: AppColors.textSecondary,
  );
  static final bpValue = GoogleFonts.inter(
    fontSize: 52, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
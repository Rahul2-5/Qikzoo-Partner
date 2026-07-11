import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: TextTheme(
          headlineLarge: AppTypography.h1,
          headlineMedium: AppTypography.h2,
          titleMedium: AppTypography.bodyMedium,
          bodyMedium: AppTypography.body,
          bodySmall: AppTypography.caption,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          foregroundColor: AppColors.textPrimary,
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.border.withValues(alpha: 0.75),
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 16,
          ),
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.62),
          ),
          labelStyle:
              AppTypography.caption.copyWith(color: AppColors.textSecondary),
          errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide:
                const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: AppColors.secondary,
          selectionColor: AppColors.secondary.withValues(alpha: 0.2),
          selectionHandleColor: AppColors.secondary,
        ),
      );
}

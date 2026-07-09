import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Temporary stand-in for a route whose real screen hasn't been built yet
/// (screens are added one at a time in later sessions per the UI roadmap).
/// Delete each usage in app_pages.dart as its real screen replaces it.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('$title — coming soon', style: AppTypography.body),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';

class CachedAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const CachedAvatar({super.key, this.url, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.secondaryBg,
        child: Icon(LucideIcons.user, color: AppColors.secondary, size: radius),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => CircleAvatar(radius: radius, backgroundColor: AppColors.secondaryBg),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.secondaryBg,
          child: Icon(LucideIcons.user, color: AppColors.secondary, size: radius),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final bool isOnline;
  final bool isGroup;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.isOnline = false,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.surfaceLight,
          child: imageUrl.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  ),
                )
              : _placeholder(),
        ),
        if (isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: AppTheme.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.background, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    if (isGroup) {
      return Icon(Icons.group_rounded, size: radius * 0.9, color: AppTheme.textMuted);
    }
    return Icon(Icons.person_rounded, size: radius * 0.9, color: AppTheme.textMuted);
  }
}

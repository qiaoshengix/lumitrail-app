import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: kGoldGradient,
        borderRadius: BorderRadius.circular(size * 0.25), // 动态圆角
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.3),
            blurRadius: size * 0.3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.camera,
        color: Colors.white,
        size: size * 0.5, // 图标大小为容器的一半
      ),
    );
  }
}

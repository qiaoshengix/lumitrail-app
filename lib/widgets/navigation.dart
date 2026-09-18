import 'package:flutter/material.dart';

/// 底部 Tab 项数据
class AppTabItem {
  const AppTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// 底部 Tab 导航 - MD3 NavigationBar
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<AppTabItem> items = [
    AppTabItem(
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
      label: '拍照',
    ),
    AppTabItem(
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom,
      label: '穿搭',
    ),
    AppTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '我的',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

/// 通用标题导航栏 - MD3 AppBar（居中标题，无返回按钮）
class TitleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TitleAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
      centerTitle: true,
    );
  }
}

/// 通用返回导航栏 - MD3 AppBar（左返回 + 标题 + 右操作）
class BackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackAppBar({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      ),
      title: Text(title),
      actions: [
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!))
        else if (actionIcon != null)
          IconButton(onPressed: onAction, icon: Icon(actionIcon)),
        const SizedBox(width: 8),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final currentNavIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'الرئيسية', route: '/home'),
    _NavItem(icon: Icons.play_circle_outline, activeIcon: Icons.play_circle, label: 'ريلز', route: '/reels'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'البحث', route: '/search'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'إشعارات', route: '/notifications'),
    _NavItem(icon: Icons.mail_outlined, activeIcon: Icons.mail, label: 'رسائل', route: '/messages'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 768)
            _DesktopNav(
              items: _navItems,
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(currentNavIndexProvider.notifier).state = index;
                context.go(_navItems[index].route);
              },
              isDark: isDark,
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 768
          ? Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2F3336) : Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  ref.read(currentNavIndexProvider.notifier).state = index;
                  context.go(_navItems[index].route);
                },
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: _navItems.map((item) {
                  return BottomNavigationBarItem(
                    icon: Icon(
                      currentIndex == _navItems.indexOf(item)
                          ? item.activeIcon
                          : item.icon,
                      color: currentIndex == _navItems.indexOf(item)
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                    label: item.label,
                  );
                }).toList(),
              ),
            )
          : null,
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/compose'),
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.edit, size: 28),
            )
          : null,
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class _DesktopNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _DesktopNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: isDark ? const Color(0xFF000000) : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _NavItemButton(
            icon: currentIndex == -1 ? Icons.home : Icons.home_outlined,
            activeIcon: Icons.home,
            isActive: false,
            label: '',
            onTap: () => context.go('/home'),
            isDark: isDark,
          ),
          const Spacer(),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _NavItemButton(
              icon: item.icon,
              activeIcon: item.activeIcon,
              isActive: index == currentIndex,
              label: '',
              onTap: () => onTap(index),
              isDark: isDark,
            );
          }),
          const Spacer(),
          _NavItemButton(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            isActive: false,
            label: '',
            onTap: () => context.push('/profile/me'),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItemButton({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(
          isActive ? activeIcon : icon,
          size: 28,
        ),
        color: isActive
            ? (isDark ? Colors.white : Colors.black)
            : Colors.grey,
        tooltip: label.isNotEmpty ? label : null,
        onPressed: onTap,
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_tokens.dart';
import 'project_list_page.dart';
import 'settings_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _index = 0;

  void _onTabSelected(int value) {
    if (_index == value) return;
    setState(() {
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [ProjectListPage(), SettingsPage()],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 20),
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              border: Border.all(color: tokens.border.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _BottomNavItem(
                  label: l10n.mainTabProjects,
                  selected: _index == 0,
                  selectedIcon: Icons.folder,
                  icon: Icons.folder,
                  activeColor: colorScheme.primary,
                  inactiveColor: tokens.mutedForeground.withValues(alpha: 0.82),
                  selectedBackgroundColor: colorScheme.surface,
                  onTap: () => _onTabSelected(0),
                ),
                const SizedBox(width: 6),
                _BottomNavItem(
                  label: l10n.mainTabSettings,
                  selected: _index == 1,
                  selectedIcon: Icons.settings,
                  icon: Icons.settings,
                  activeColor: colorScheme.primary,
                  inactiveColor: tokens.mutedForeground.withValues(alpha: 0.82),
                  selectedBackgroundColor: colorScheme.surface,
                  onTap: () => _onTabSelected(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final Color activeColor;
  final Color inactiveColor;
  final Color selectedBackgroundColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.activeColor,
    required this.inactiveColor,
    required this.selectedBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: selected ? selectedBackgroundColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 14,
                  color: selected ? activeColor : inactiveColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

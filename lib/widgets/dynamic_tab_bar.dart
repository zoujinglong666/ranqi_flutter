import 'package:flutter/material.dart';
import '../models/tab_item.dart';
import '../services/tab_manager.dart';
import '../theme/app_theme.dart';

/// 动态TabBar组件
class DynamicTabBar extends StatelessWidget {
  final TabManager tabManager;
  final Function(int)? onTap;

  const DynamicTabBar({
    super.key,
    required this.tabManager,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabManager,
      builder: (context, child) {
        final visibleTabs = tabManager.visibleTabs;
        
        if (visibleTabs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: tabManager.currentIndex,
            onTap: (index) {
              tabManager.switchToTab(index);
              onTap?.call(index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.textHint,
            selectedLabelStyle: const TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              fontWeight: FontWeight.normal,
            ),
            items: visibleTabs.map((tab) => _buildTabItem(tab, visibleTabs.indexOf(tab))).toList(),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildTabItem(TabItem tab, int index) {
    return BottomNavigationBarItem(
      icon: _buildIconWithBadge(tab.icon, tab, false),
      activeIcon: _buildIconWithBadge(tab.activeIcon, tab, true),
      label: tab.label,
    );
  }

  Widget _buildIconWithBadge(IconData iconData, TabItem tab, bool isActive) {
    Widget icon = Icon(iconData);

    if (tab.showBadge) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6,
            top: -6,
            child: _buildBadge(tab),
          ),
        ],
      );
    }

    return icon;
  }

  Widget _buildBadge(TabItem tab) {
    final badgeColor = tab.badgeColor ?? Colors.red;
    
    if (tab.badgeText != null && tab.badgeText!.isNotEmpty) {
      // 带文字的徽章
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1),
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          tab.badgeText!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      // 红点徽章
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      );
    }
  }
}
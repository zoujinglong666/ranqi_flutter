import 'package:flutter/material.dart';

/// TabBar项目模型
class TabItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  final bool isVisible;
  final bool showBadge;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const TabItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
    this.isVisible = true,
    this.showBadge = false,
    this.badgeText,
    this.badgeColor,
    this.onTap,
  });

  TabItem copyWith({
    String? id,
    String? label,
    IconData? icon,
    IconData? activeIcon,
    Widget? screen,
    bool? isVisible,
    bool? showBadge,
    String? badgeText,
    Color? badgeColor,
    VoidCallback? onTap,
  }) {
    return TabItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      activeIcon: activeIcon ?? this.activeIcon,
      screen: screen ?? this.screen,
      isVisible: isVisible ?? this.isVisible,
      showBadge: showBadge ?? this.showBadge,
      badgeText: badgeText ?? this.badgeText,
      badgeColor: badgeColor ?? this.badgeColor,
      onTap: onTap ?? this.onTap,
    );
  }
}
import 'package:flutter/material.dart';
import '../models/tab_item.dart';
import '../screens/home_screen.dart';
import '../screens/floor_management_screen.dart';
import '../screens/my_screen.dart';

/// Tab配置类
class TabConfig {
  /// 获取默认的Tab配置
  static List<TabItem> getDefaultTabs() {
    return [
      TabItem(
        id: 'home',
        label: '识别',
        icon: Icons.camera_alt_outlined,
        activeIcon: Icons.camera_alt,
        screen: HomeScreen(),
        isVisible: true,
      ),
      TabItem(
        id: 'floor',
        label: '楼层',
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment,
        screen: FloorManagementScreen(),
        isVisible: true,
      ),
      TabItem(
        id: 'profile',
        label: '我的',
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        screen: MyScreen(),
        isVisible: true,
      ),
    ];
  }

  /// 根据用户权限获取Tab配置
  static List<TabItem> getTabsByPermission({
    bool canAccessHome = true,
    bool canAccessFloor = true,
    bool canAccessProfile = true,
  }) {
    return [
      if (canAccessHome)
        TabItem(
          id: 'home',
          label: '识别',
          icon: Icons.camera_alt_outlined,
          activeIcon: Icons.camera_alt,
          screen: HomeScreen(),
          isVisible: true,
        ),
      if (canAccessFloor)
        TabItem(
          id: 'floor',
          label: '楼层',
          icon: Icons.apartment_outlined,
          activeIcon: Icons.apartment,
          screen: FloorManagementScreen(),
          isVisible: true,
        ),
      if (canAccessProfile)
        TabItem(
          id: 'profile',
          label: '我的',
          icon: Icons.person_outlined,
          activeIcon: Icons.person,
          screen: MyScreen(),
          isVisible: true,
        ),
    ];
  }

  /// 获取管理员Tab配置（示例）
  static List<TabItem> getAdminTabs() {
    return [
      TabItem(
        id: 'home',
        label: '识别',
        icon: Icons.camera_alt_outlined,
        activeIcon: Icons.camera_alt,
        screen: HomeScreen(),
        isVisible: true,
      ),
      TabItem(
        id: 'floor',
        label: '楼层管理',
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment,
        screen: FloorManagementScreen(),
        isVisible: true,
        showBadge: true, // 管理员可能有待处理的事项
      ),
      const TabItem(
        id: 'admin',
        label: '管理',
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings,
        screen: Center(child: Text('管理页面')), // 占位符
        isVisible: true,
      ),
      TabItem(
        id: 'profile',
        label: '我的',
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        screen: MyScreen(),
        isVisible: true,
      ),
    ];
  }
}
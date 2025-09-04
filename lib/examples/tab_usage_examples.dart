import 'package:flutter/material.dart';
import '../services/tab_manager.dart';
import '../models/tab_item.dart';

/// TabManager使用示例
class TabUsageExamples {
  static final TabManager _tabManager = TabManager();

  /// 示例1: 动态显示/隐藏Tab
  static void toggleTabVisibility() {
    // 隐藏楼层Tab
    _tabManager.setTabVisibility('floor', false);
    
    // 3秒后重新显示
    Future.delayed(Duration(seconds: 3), () {
      _tabManager.setTabVisibility('floor', true);
    });
  }

  /// 示例2: 设置红点徽章
  static void setTabBadges() {
    // 在楼层Tab上显示红点
    _tabManager.setTabBadge('floor', showBadge: true);
    
    // 在我的Tab上显示数字徽章
    _tabManager.setTabBadge('profile', 
      showBadge: true, 
      badgeText: '5',
      badgeColor: Colors.orange,
    );
  }

  /// 示例3: 动态更新Tab标签和图标
  static void updateTabAppearance() {
    // 更新楼层Tab的标签
    _tabManager.updateTabLabel('floor', '房间管理');
    
    // 更新图标
    _tabManager.updateTabIcon('floor', 
      Icons.home_outlined, 
      Icons.home,
    );
  }

  /// 示例4: 根据用户角色动态配置Tab
  static void configureTabsByUserRole(String userRole) {
    List<TabItem> tabs = [];
    
    switch (userRole) {
      case 'admin':
        tabs = [
          TabItem(
            id: 'dashboard',
            label: '仪表盘',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            screen: Container(child: Center(child: Text('管理员仪表盘'))),
          ),
          TabItem(
            id: 'users',
            label: '用户管理',
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            screen: Container(child: Center(child: Text('用户管理'))),
          ),
          TabItem(
            id: 'settings',
            label: '系统设置',
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            screen: Container(child: Center(child: Text('系统设置'))),
          ),
        ];
        break;
      case 'manager':
        tabs = [
          TabItem(
            id: 'home',
            label: '识别',
            icon: Icons.camera_alt_outlined,
            activeIcon: Icons.camera_alt,
            screen: Container(child: Center(child: Text('识别页面'))),
          ),
          TabItem(
            id: 'floor',
            label: '楼层管理',
            icon: Icons.apartment_outlined,
            activeIcon: Icons.apartment,
            screen: Container(child: Center(child: Text('楼层管理'))),
            showBadge: true, // 管理员可能有待处理事项
          ),
          TabItem(
            id: 'reports',
            label: '报表',
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            screen: Container(child: Center(child: Text('报表页面'))),
          ),
        ];
        break;
      default: // 普通用户
        tabs = [
          TabItem(
            id: 'home',
            label: '识别',
            icon: Icons.camera_alt_outlined,
            activeIcon: Icons.camera_alt,
            screen: Container(child: Center(child: Text('识别页面'))),
          ),
          TabItem(
            id: 'profile',
            label: '我的',
            icon: Icons.person_outlined,
            activeIcon: Icons.person,
            screen: Container(child: Center(child: Text('个人中心'))),
          ),
        ];
    }
    
    _tabManager.initializeTabs(tabs);
  }

  /// 示例5: 处理Tab点击事件
  static void handleTabInteractions() {
    // 添加带有自定义点击事件的Tab
    final customTab = TabItem(
      id: 'custom',
      label: '自定义',
      icon: Icons.star_outlined,
      activeIcon: Icons.star,
      screen: Container(child: Center(child: Text('自定义页面'))),
      onTap: () {
        print('自定义Tab被点击了！');
        // 可以在这里执行自定义逻辑
      },
    );
    
    _tabManager.addTab(customTab);
  }

  /// 示例6: 批量操作
  static void batchOperations() {
    // 清除所有徽章
    _tabManager.clearAllBadges();
    
    // 获取徽章数量
    final badgeCount = _tabManager.getBadgeCount();
    print('当前徽章数量: $badgeCount');
    
    // 切换到指定Tab
    _tabManager.switchToTabById('profile');
  }

  /// 示例7: 动态添加临时Tab
  static void addTemporaryTab() {
    final tempTab = TabItem(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      label: '临时',
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time,
      screen: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('这是一个临时Tab'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 5秒后自动移除
                  Future.delayed(Duration(seconds: 5), () {
                    _tabManager.removeTab('temp_${DateTime.now().millisecondsSinceEpoch}');
                  });
                },
                child: Text('5秒后自动移除'),
              ),
            ],
          ),
        ),
      ),
    );
    
    _tabManager.addTab(tempTab);
  }
}
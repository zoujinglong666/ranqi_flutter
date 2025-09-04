import 'package:flutter/material.dart';
import '../models/tab_item.dart';

/// TabBar管理器
class TabManager extends ChangeNotifier {
  static final TabManager _instance = TabManager._internal();
  factory TabManager() => _instance;
  TabManager._internal();

  List<TabItem> _tabs = [];
  int _currentIndex = 0;

  /// 获取所有Tab项
  List<TabItem> get tabs => _tabs;

  /// 获取可见的Tab项
  List<TabItem> get visibleTabs => _tabs.where((tab) => tab.isVisible).toList();

  /// 获取当前选中的索引
  int get currentIndex => _currentIndex;

  /// 获取当前选中的Tab
  TabItem? get currentTab {
    final visible = visibleTabs;
    if (_currentIndex >= 0 && _currentIndex < visible.length) {
      return visible[_currentIndex];
    }
    return null;
  }

  /// 初始化Tab项
  void initializeTabs(List<TabItem> tabs) {
    _tabs = tabs;
    _currentIndex = 0;
    notifyListeners();
  }

  /// 添加Tab项
  void addTab(TabItem tab) {
    _tabs.add(tab);
    notifyListeners();
  }

  /// 移除Tab项
  void removeTab(String id) {
    _tabs.removeWhere((tab) => tab.id == id);
    // 调整当前索引
    if (_currentIndex >= visibleTabs.length) {
      _currentIndex = visibleTabs.length - 1;
      if (_currentIndex < 0) _currentIndex = 0;
    }
    notifyListeners();
  }

  /// 更新Tab项
  void updateTab(String id, TabItem updatedTab) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      _tabs[index] = updatedTab;
      notifyListeners();
    }
  }

  /// 设置Tab可见性
  void setTabVisibility(String id, bool isVisible) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(isVisible: isVisible);
      // 如果隐藏的是当前选中的Tab，切换到第一个可见的Tab
      if (!isVisible && _tabs[index].id == currentTab?.id) {
        _currentIndex = 0;
      }
      notifyListeners();
    }
  }

  /// 设置Tab红点
  void setTabBadge(String id, {bool showBadge = false, String? badgeText, Color? badgeColor}) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(
        showBadge: showBadge,
        badgeText: badgeText,
        badgeColor: badgeColor,
      );
      notifyListeners();
    }
  }

  /// 更新Tab标签
  void updateTabLabel(String id, String newLabel) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(label: newLabel);
      notifyListeners();
    }
  }

  /// 更新Tab图标
  void updateTabIcon(String id, IconData newIcon, IconData newActiveIcon) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(
        icon: newIcon,
        activeIcon: newActiveIcon,
      );
      notifyListeners();
    }
  }

  /// 切换到指定Tab
  void switchToTab(int index) {
    final visible = visibleTabs;
    if (index >= 0 && index < visible.length) {
      _currentIndex = index;
      // 执行自定义点击回调
      visible[index].onTap?.call();
      notifyListeners();
    }
  }

  /// 根据ID切换到指定Tab
  void switchToTabById(String id) {
    final visible = visibleTabs;
    final index = visible.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      switchToTab(index);
    }
  }

  /// 清除所有Tab的红点
  void clearAllBadges() {
    for (int i = 0; i < _tabs.length; i++) {
      _tabs[i] = _tabs[i].copyWith(showBadge: false, badgeText: null);
    }
    notifyListeners();
  }

  /// 获取Tab的红点数量
  int getBadgeCount() {
    return _tabs.where((tab) => tab.showBadge && tab.isVisible).length;
  }
}
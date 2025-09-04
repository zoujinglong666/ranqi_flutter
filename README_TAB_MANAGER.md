# 动态TabBar路由管理器使用说明

## 概述

这是一个功能强大的动态TabBar管理系统，支持：
- 动态显示/隐藏Tab
- 动态切换Tab名称和图标
- 红点徽章功能
- 自定义点击事件
- 权限控制

## 核心组件

### 1. TabItem (模型)
```dart
TabItem(
  id: 'unique_id',           // 唯一标识
  label: '标签名',            // 显示文字
  icon: Icons.icon_name,     // 未选中图标
  activeIcon: Icons.icon,    // 选中图标
  screen: YourScreen(),      // 对应页面
  isVisible: true,           // 是否可见
  showBadge: false,          // 是否显示徽章
  badgeText: '5',            // 徽章文字
  badgeColor: Colors.red,    // 徽章颜色
  onTap: () => {},           // 点击回调
)
```

### 2. TabManager (管理器)
```dart
final tabManager = TabManager();

// 初始化Tab
tabManager.initializeTabs(tabs);

// 动态操作
tabManager.setTabVisibility('id', false);  // 隐藏Tab
tabManager.setTabBadge('id', showBadge: true);  // 显示红点
tabManager.updateTabLabel('id', '新标签');  // 更新标签
tabManager.switchToTabById('id');  // 切换Tab
```

### 3. DynamicMainScreen (主屏幕)
```dart
DynamicMainScreen(
  initialTabs: TabConfig.getDefaultTabs(),
)
```

## 使用示例

### 基础使用
```dart
// 在main.dart中
MaterialApp(
  routes: {
    '/main': (context) => DynamicMainScreen(
      initialTabs: TabConfig.getDefaultTabs(),
    ),
  },
)
```

### 动态控制
```dart
// 获取TabManager实例
final tabManager = TabManager();

// 显示红点
tabManager.setTabBadge('floor', showBadge: true);

// 隐藏Tab
tabManager.setTabVisibility('profile', false);

// 更新标签
tabManager.updateTabLabel('home', '扫描');

// 切换Tab
tabManager.switchToTabById('floor');
```

### 权限控制
```dart
// 根据用户权限配置Tab
List<TabItem> tabs = TabConfig.getTabsByPermission(
  canAccessHome: true,
  canAccessFloor: userRole == 'admin',
  canAccessProfile: true,
);

DynamicMainScreen(initialTabs: tabs)
```

### 自定义Tab配置
```dart
final customTabs = [
  TabItem(
    id: 'scan',
    label: '扫描',
    icon: Icons.qr_code_scanner,
    activeIcon: Icons.qr_code_scanner,
    screen: ScanScreen(),
    onTap: () {
      print('扫描Tab被点击');
      // 自定义逻辑
    },
  ),
  // 更多Tab...
];
```

## 高级功能

### 1. 徽章系统
```dart
// 红点徽章
tabManager.setTabBadge('id', showBadge: true);

// 数字徽章
tabManager.setTabBadge('id', 
  showBadge: true, 
  badgeText: '99+',
  badgeColor: Colors.orange,
);

// 清除所有徽章
tabManager.clearAllBadges();
```

### 2. 动态Tab管理
```dart
// 添加新Tab
tabManager.addTab(newTabItem);

// 移除Tab
tabManager.removeTab('id');

// 更新Tab
tabManager.updateTab('id', updatedTabItem);
```

### 3. 事件监听
```dart
// 监听Tab变化
tabManager.addListener(() {
  print('Tab状态发生变化');
  print('当前Tab: ${tabManager.currentTab?.label}');
});
```

## 配置文件

### TabConfig
预定义的Tab配置，支持：
- 默认配置
- 权限配置
- 角色配置

```dart
// 默认配置
TabConfig.getDefaultTabs()

// 权限配置
TabConfig.getTabsByPermission(
  canAccessHome: true,
  canAccessFloor: false,
)

// 管理员配置
TabConfig.getAdminTabs()
```

## 注意事项

1. **唯一ID**: 每个Tab必须有唯一的ID
2. **状态保持**: 使用IndexedStack保持页面状态
3. **内存管理**: TabManager是单例，注意内存泄漏
4. **权限检查**: 在显示Tab前检查用户权限
5. **异常处理**: 处理Tab不存在的情况

## 扩展建议

1. **持久化**: 将Tab配置保存到本地存储
2. **网络配置**: 从服务器获取Tab配置
3. **动画效果**: 添加Tab切换动画
4. **手势支持**: 支持滑动切换Tab
5. **主题适配**: 支持深色模式

## 示例代码

详细示例请参考 `lib/examples/tab_usage_examples.dart` 文件。
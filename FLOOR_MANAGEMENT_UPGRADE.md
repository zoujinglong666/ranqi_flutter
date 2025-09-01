# 楼层管理系统升级方案

## 问题背景

原系统使用占位符房间（`_PLACEHOLDER_`）来表示楼层，这种设计存在以下问题：

1. **数据结构不清晰**：楼层概念通过特殊房间来表示，违反了数据模型的语义
2. **代码复杂性**：需要在多处过滤占位符房间，增加了代码复杂度
3. **维护困难**：占位符房间容易在UI中意外显示，需要额外的过滤逻辑
4. **扩展性差**：无法为楼层添加独立的属性（如描述、创建时间等）

## 新的解决方案

### 1. 独立的楼层数据模型

创建了新的 `Floor` 模型：

```dart
class Floor {
  final int floorNumber;        // 楼层号
  final DateTime createdAt;     // 创建时间
  final String? description;    // 楼层描述（可选）
}
```

### 2. 扩展的存储服务

在 `StorageService` 中添加了楼层管理方法：

- `saveFloor(Floor floor)` - 保存单个楼层
- `getFloors()` - 获取所有楼层
- `deleteFloor(int floorNumber)` - 删除楼层
- `getAvailableFloors()` - 获取可用楼层（包含推断的楼层）

### 3. 数据迁移服务

创建了 `MigrationService` 来处理数据迁移：

- 自动检测占位符房间
- 将占位符房间转换为楼层记录
- 清理无用的占位符数据
- 提供迁移统计信息

## 升级优势

### 1. 数据结构清晰
- 楼层和房间概念分离
- 每个实体都有明确的职责
- 支持楼层级别的元数据

### 2. 代码简化
- 移除了所有 `_PLACEHOLDER_` 过滤逻辑
- 楼层管理逻辑更加直观
- 减少了代码重复

### 3. 功能增强
- 支持楼层描述和创建时间
- 更好的楼层删除体验
- 智能的楼层推断（从房间和记录中）

### 4. 向后兼容
- 自动迁移现有数据
- 不影响现有功能
- 平滑升级过程

## 迁移过程

### 自动迁移

应用启动时会自动执行以下步骤：

1. **检测占位符房间**：扫描所有房间，查找 `roomNumber == '_PLACEHOLDER_'` 的记录
2. **创建楼层记录**：为每个占位符房间创建对应的 `Floor` 记录
3. **清理占位符**：删除所有占位符房间
4. **验证迁移**：确保数据完整性

### 手动迁移（可选）

如果需要手动控制迁移过程，可以使用：

```dart
// 检查是否需要迁移
final needsMigration = await MigrationService.needsMigration();

// 执行迁移
if (needsMigration) {
  await MigrationService.migratePlaceholderRoomsToFloors();
}

// 获取迁移统计
final stats = await MigrationService.getMigrationStats();
print('占位符房间: ${stats['placeholderRooms']}');
print('正常房间: ${stats['normalRooms']}');
print('现有楼层: ${stats['existingFloors']}');
```

## 文件变更清单

### 新增文件
- `lib/models/floor.dart` - 楼层数据模型
- `lib/services/migration_service.dart` - 数据迁移服务

### 修改文件
- `lib/services/storage_service.dart` - 添加楼层管理方法
- `lib/screens/floor_management_screen.dart` - 使用新的楼层管理系统
- `lib/screens/home_screen.dart` - 移除占位符过滤逻辑
- `lib/screens/my_records_screen.dart` - 移除占位符过滤逻辑
- `lib/main.dart` - 添加自动迁移逻辑

## 测试建议

1. **迁移测试**：
   - 创建包含占位符房间的测试数据
   - 验证迁移后数据的完整性
   - 确认占位符房间被正确清理

2. **功能测试**：
   - 测试楼层添加功能
   - 测试楼层删除功能
   - 验证房间管理不受影响

3. **UI测试**：
   - 确认不再显示占位符房间
   - 验证楼层选择功能正常
   - 测试记录编辑中的楼层房间联动

## 回滚方案

如果升级后出现问题，可以通过以下步骤回滚：

1. 恢复原始代码文件
2. 手动清理楼层数据：`SharedPreferences.remove('floors')`
3. 重新创建必要的占位符房间

但建议在生产环境部署前充分测试，避免需要回滚的情况。

## 总结

这次升级彻底解决了占位符房间的设计问题，提供了更清晰、更可维护的数据结构。通过自动迁移机制，确保了升级过程的平滑性，不会影响用户的现有数据和使用体验。
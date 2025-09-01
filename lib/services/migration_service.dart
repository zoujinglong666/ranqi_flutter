import '../models/floor.dart';
import '../models/room.dart';
import 'storage_service.dart';

/// 数据迁移服务
/// 用于将旧的占位符房间系统迁移到新的独立楼层系统
class MigrationService {
  /// 执行数据迁移
  /// 将所有占位符房间转换为独立的楼层记录，并清理占位符房间
  static Future<void> migratePlaceholderRoomsToFloors() async {
    try {
      // 获取所有房间
      final rooms = await StorageService.getRooms();
      
      // 找到所有占位符房间
      final placeholderRooms = rooms.where((room) => room.roomNumber == '_PLACEHOLDER_').toList();
      
      if (placeholderRooms.isEmpty) {
        print('迁移完成：没有发现占位符房间');
        return;
      }
      
      // 获取现有楼层
      final existingFloors = await StorageService.getFloors();
      final existingFloorNumbers = existingFloors.map((f) => f.floorNumber).toSet();
      
      // 为每个占位符房间创建对应的楼层记录
      final newFloors = <Floor>[];
      for (final placeholderRoom in placeholderRooms) {
        if (!existingFloorNumbers.contains(placeholderRoom.floor)) {
          final floor = Floor(
            floorNumber: placeholderRoom.floor,
            createdAt: DateTime.now(),
            description: '从占位符房间迁移而来',
          );
          newFloors.add(floor);
          existingFloorNumbers.add(placeholderRoom.floor);
        }
      }
      
      // 保存新楼层
      if (newFloors.isNotEmpty) {
        final allFloors = [...existingFloors, ...newFloors];
        await StorageService.saveFloors(allFloors);
        print('迁移成功：创建了 ${newFloors.length} 个楼层记录');
      }
      
      // 移除所有占位符房间
      final cleanedRooms = rooms.where((room) => room.roomNumber != '_PLACEHOLDER_').toList();
      await StorageService.saveRooms(cleanedRooms);
      
      print('迁移完成：移除了 ${placeholderRooms.length} 个占位符房间');
      
    } catch (e) {
      print('迁移失败: $e');
      rethrow;
    }
  }
  
  /// 检查是否需要迁移
  /// 返回true表示存在占位符房间，需要执行迁移
  static Future<bool> needsMigration() async {
    final rooms = await StorageService.getRooms();
    return rooms.any((room) => room.roomNumber == '_PLACEHOLDER_');
  }
  
  /// 清理所有占位符房间（不创建楼层记录）
  /// 谨慎使用：这会直接删除所有占位符房间
  static Future<void> cleanupPlaceholderRooms() async {
    final rooms = await StorageService.getRooms();
    final placeholderCount = rooms.where((room) => room.roomNumber == '_PLACEHOLDER_').length;
    
    if (placeholderCount == 0) {
      print('清理完成：没有发现占位符房间');
      return;
    }
    
    final cleanedRooms = rooms.where((room) => room.roomNumber != '_PLACEHOLDER_').toList();
    await StorageService.saveRooms(cleanedRooms);
    
    print('清理完成：移除了 $placeholderCount 个占位符房间');
  }
  
  /// 获取迁移统计信息
  static Future<Map<String, int>> getMigrationStats() async {
    final rooms = await StorageService.getRooms();
    final floors = await StorageService.getFloors();
    
    final placeholderRooms = rooms.where((room) => room.roomNumber == '_PLACEHOLDER_').length;
    final normalRooms = rooms.where((room) => room.roomNumber != '_PLACEHOLDER_').length;
    final existingFloors = floors.length;
    
    return {
      'placeholderRooms': placeholderRooms,
      'normalRooms': normalRooms,
      'existingFloors': existingFloors,
    };
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meter_record.dart';
import '../models/room.dart';
import '../models/floor.dart';

class StorageService {
  static const String _recordsKey = 'meter_records';
  static const String _roomsKey = 'rooms';
  static const String _floorsKey = 'floors';

  // 保存表记录
  static Future<void> saveMeterRecord(MeterRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_recordsKey) ?? [];
    records.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_recordsKey, records);
  }

  // 获取所有表记录
  static Future<List<MeterRecord>> getMeterRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_recordsKey) ?? [];
    return records.map((record) => MeterRecord.fromJson(jsonDecode(record))).toList();
  }

  // 删除表记录
  static Future<void> deleteMeterRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_recordsKey) ?? [];
    records.removeWhere((record) {
      final decoded = jsonDecode(record);
      return decoded['id'] == id;
    });
    await prefs.setStringList(_recordsKey, records);
  }

  // 更新表记录
  static Future<void> updateMeterRecord(MeterRecord updatedRecord) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_recordsKey) ?? [];
    
    // 找到并替换对应的记录
    for (int i = 0; i < records.length; i++) {
      final decoded = jsonDecode(records[i]);
      if (decoded['id'] == updatedRecord.id) {
        records[i] = jsonEncode(updatedRecord.toJson());
        break;
      }
    }
    
    await prefs.setStringList(_recordsKey, records);
  }

  // 保存房间信息
  static Future<void> saveRooms(List<Room> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> roomStrings = rooms.map((room) => jsonEncode(room.toJson())).toList();
    await prefs.setStringList(_roomsKey, roomStrings);
  }

  // 保存单个房间
  static Future<void> saveRoom(Room room) async {
    final rooms = await getRooms();
    rooms.add(room);
    await saveRooms(rooms);
  }

  // 获取所有房间
  static Future<List<Room>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> roomStrings = prefs.getStringList(_roomsKey) ?? [];
    return roomStrings.map((room) => Room.fromJson(jsonDecode(room))).toList();
  }

  // 根据楼层获取房间
  static Future<List<Room>> getRoomsByFloor(int floor) async {
    final rooms = await getRooms();
    return rooms.where((room) => room.floor == floor).toList();
  }

  // ========== 楼层管理方法 ==========
  
  // 保存所有楼层
  static Future<void> saveFloors(List<Floor> floors) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> floorStrings = floors.map((floor) => jsonEncode(floor.toJson())).toList();
    await prefs.setStringList(_floorsKey, floorStrings);
  }

  // 保存单个楼层
  static Future<void> saveFloor(Floor floor) async {
    final floors = await getFloors();
    // 检查楼层是否已存在
    if (!floors.any((f) => f.floorNumber == floor.floorNumber)) {
      floors.add(floor);
      await saveFloors(floors);
    }
  }

  // 获取所有楼层
  static Future<List<Floor>> getFloors() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> floorStrings = prefs.getStringList(_floorsKey) ?? [];
    final floors = floorStrings.map((floor) => Floor.fromJson(jsonDecode(floor))).toList();
    floors.sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
    return floors;
  }

  // 删除楼层
  static Future<void> deleteFloor(int floorNumber) async {
    final floors = await getFloors();
    floors.removeWhere((floor) => floor.floorNumber == floorNumber);
    await saveFloors(floors);
  }

  // 获取可用楼层号列表（包含从房间和记录中推断的楼层）
  static Future<List<int>> getAvailableFloors() async {
    final floors = await getFloors();
    final rooms = await getRooms();
    final records = await getMeterRecords();
    
    final Set<int> allFloors = {};
    
    // 添加显式定义的楼层
    allFloors.addAll(floors.map((f) => f.floorNumber));
    
    // 添加从房间推断的楼层
    allFloors.addAll(rooms.map((r) => r.floor));
    
    // 添加从记录推断的楼层
    allFloors.addAll(records.map((r) => r.floor));
    
    final result = allFloors.toList();
    result.sort();
    return result;
  }
}
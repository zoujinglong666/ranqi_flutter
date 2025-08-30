import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meter_record.dart';
import '../models/room.dart';

class StorageService {
  static const String _recordsKey = 'meter_records';
  static const String _roomsKey = 'rooms';

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
}
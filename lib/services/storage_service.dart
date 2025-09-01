import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meter_record.dart';
import '../models/room.dart';
import '../models/floor.dart';
import '../models/rent_record.dart';
import '../models/unit_price.dart';
import '../models/service_fee.dart';

class StorageService {
  static const String _recordsKey = 'meter_records';
  static const String _roomsKey = 'rooms';
  static const String _floorsKey = 'floors';
  static const String _rentRecordsKey = 'rent_records';
  static const String _unitPricesKey = 'unit_prices';
  static const String _serviceFeesKey = 'service_fees';

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

  // ========== 租金记录管理方法 ==========
  
  // 保存租金记录
  static Future<void> saveRentRecord(RentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_rentRecordsKey) ?? [];
    records.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_rentRecordsKey, records);
  }

  // 获取所有租金记录
  static Future<List<RentRecord>> getRentRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_rentRecordsKey) ?? [];
    return records.map((record) => RentRecord.fromJson(jsonDecode(record))).toList();
  }

  // 根据房间和月份获取租金记录
  static Future<RentRecord?> getRentRecord(int floor, String roomNumber, DateTime month) async {
    final records = await getRentRecords();
    try {
      return records.firstWhere((record) => 
        record.floor == floor && 
        record.roomNumber == roomNumber && 
        record.month.year == month.year && 
        record.month.month == month.month
      );
    } catch (e) {
      return null;
    }
  }

  // 更新租金记录
  static Future<void> updateRentRecord(RentRecord updatedRecord) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_rentRecordsKey) ?? [];
    
    for (int i = 0; i < records.length; i++) {
      final decoded = jsonDecode(records[i]);
      if (decoded['id'] == updatedRecord.id) {
        records[i] = jsonEncode(updatedRecord.toJson());
        break;
      }
    }
    
    await prefs.setStringList(_rentRecordsKey, records);
  }

  // 删除租金记录
  static Future<void> deleteRentRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_rentRecordsKey) ?? [];
    records.removeWhere((record) {
      final decoded = jsonDecode(record);
      return decoded['id'] == id;
    });
    await prefs.setStringList(_rentRecordsKey, records);
  }

  // ========== 单价配置管理方法 ==========
  
  // 保存单价配置
  static Future<void> saveUnitPrice(UnitPrice unitPrice) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> prices = prefs.getStringList(_unitPricesKey) ?? [];
    prices.add(jsonEncode(unitPrice.toJson()));
    await prefs.setStringList(_unitPricesKey, prices);
  }

  // 获取所有单价配置
  static Future<List<UnitPrice>> getUnitPrices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> prices = prefs.getStringList(_unitPricesKey) ?? [];
    return prices.map((price) => UnitPrice.fromJson(jsonDecode(price))).toList();
  }

  // 根据表计类型获取当前有效单价
  static Future<UnitPrice?> getCurrentUnitPrice(String meterType) async {
    final prices = await getUnitPrices();
    final activePrices = prices.where((price) => 
      price.meterType == meterType && 
      price.isActive &&
      price.effectiveDate.isBefore(DateTime.now().add(Duration(days: 1)))
    ).toList();
    
    if (activePrices.isEmpty) return null;
    
    // 返回最新的有效单价
    activePrices.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return activePrices.first;
  }

  // 更新单价配置
  static Future<void> updateUnitPrice(UnitPrice updatedPrice) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> prices = prefs.getStringList(_unitPricesKey) ?? [];
    
    for (int i = 0; i < prices.length; i++) {
      final decoded = jsonDecode(prices[i]);
      if (decoded['id'] == updatedPrice.id) {
        prices[i] = jsonEncode(updatedPrice.toJson());
        break;
      }
    }
    
    await prefs.setStringList(_unitPricesKey, prices);
  }

  // 删除单价配置
  static Future<void> deleteUnitPrice(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> prices = prefs.getStringList(_unitPricesKey) ?? [];
    prices.removeWhere((price) {
      final decoded = jsonDecode(price);
      return decoded['id'] == id;
    });
    await prefs.setStringList(_unitPricesKey, prices);
  }

  // ==================== 服务费管理 ====================
  
  // 保存服务费记录
  static Future<void> saveServiceFee(ServiceFee serviceFee) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> fees = prefs.getStringList(_serviceFeesKey) ?? [];
    fees.add(jsonEncode(serviceFee.toJson()));
    await prefs.setStringList(_serviceFeesKey, fees);
  }

  // 获取所有服务费记录
  static Future<List<ServiceFee>> getServiceFees() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> fees = prefs.getStringList(_serviceFeesKey) ?? [];
    return fees.map((fee) => ServiceFee.fromJson(jsonDecode(fee))).toList();
  }

  // 更新服务费记录
  static Future<void> updateServiceFee(ServiceFee updatedServiceFee) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> fees = prefs.getStringList(_serviceFeesKey) ?? [];
    
    for (int i = 0; i < fees.length; i++) {
      final decoded = jsonDecode(fees[i]);
      if (decoded['id'] == updatedServiceFee.id) {
        fees[i] = jsonEncode(updatedServiceFee.toJson());
        break;
      }
    }
    await prefs.setStringList(_serviceFeesKey, fees);
  }

  // 删除服务费记录
  static Future<void> deleteServiceFee(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> fees = prefs.getStringList(_serviceFeesKey) ?? [];
    fees.removeWhere((fee) {
      final decoded = jsonDecode(fee);
      return decoded['id'] == id;
    });
    await prefs.setStringList(_serviceFeesKey, fees);
  }

  // 获取指定房间和月份的服务费
  static Future<List<ServiceFee>> getServiceFeesByRoomAndMonth({
    required String floor,
    required String roomNumber,
    required int year,
    required int month,
  }) async {
    final allFees = await getServiceFees();
    return allFees.where((fee) => 
      fee.floor == floor && 
      fee.roomNumber == roomNumber &&
      fee.month.year == year &&
      fee.month.month == month
    ).toList();
  }

  // 获取指定类型的服务费
  static Future<List<ServiceFee>> getServiceFeesByType(String feeType) async {
    final allFees = await getServiceFees();
    return allFees.where((fee) => fee.feeType == feeType).toList();
  }
}
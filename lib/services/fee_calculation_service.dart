import '../models/meter_record.dart';
import '../models/unit_price.dart';
import '../models/rent_record.dart';
import '../models/service_fee.dart';
import 'storage_service.dart';

class FeeCalculationService {

  /// 计算指定房间和月份的费用详情
  Future<FeeCalculationResult> calculateFees({
    required String floor,
    required String roomNumber,
    required int year,
    required int month,
  }) async {
    try {
      // 获取该房间该月的所有记录
      final allRecords = await StorageService.getMeterRecords();
      final roomRecords = allRecords.where((record) =>
        record.floor == floor &&
        record.roomNumber == roomNumber &&
        record.timestamp.year == year &&
        record.timestamp.month == month
    ).toList();

      // 按表计类型分组
      final waterRecords = roomRecords.where((r) => r.meterType == '水表').toList();
      final electricRecords = roomRecords.where((r) => r.meterType == '电').toList();
      final gasRecords = roomRecords.where((r) => r.meterType == '燃气表').toList();

      // 计算各类费用
      final waterFee = await _calculateMeterFee(waterRecords, '水表', year, month);
      final electricFee = await _calculateMeterFee(electricRecords, '电表', year, month);
      final gasFee = await _calculateMeterFee(gasRecords, '燃气表', year, month);

      // 获取租金
      final rentRecords = await StorageService.getRentRecords();
      final rentRecord = rentRecords.where((r) => 
        r.floor == floor && 
        r.roomNumber == roomNumber &&
        r.month.year == year &&
        r.month.month == month
      ).firstOrNull;

      final rent = rentRecord?.rentAmount ?? 0.0;

      // 获取服务费
      final serviceFees = await StorageService.getServiceFeesByRoomAndMonth(
        floor: floor,
        roomNumber: roomNumber,
        year: year,
        month: month,
      );
      
      final publicServiceFee = serviceFees
          .where((fee) => fee.feeType == '公共服务费')
          .fold<double>(0.0, (sum, fee) => sum + (fee.amount?.toDouble() ?? 0.0));
      
      final sanitationFee = serviceFees
          .where((fee) => fee.feeType == '卫生费')
          .fold<double>(0.0, (sum, fee) => sum + (fee.amount?.toDouble() ?? 0.0));

      // 计算总费用
      final totalFee = waterFee.totalAmount + electricFee.totalAmount + gasFee.totalAmount + rent + publicServiceFee + sanitationFee;

      return FeeCalculationResult(
        floor: floor,
        roomNumber: roomNumber,
        year: year,
        month: month,
        waterFee: waterFee,
        electricFee: electricFee,
        gasFee: gasFee,
        rent: rent,
        publicServiceFee: publicServiceFee,
        sanitationFee: sanitationFee,
        totalAmount: totalFee,
      );
    } catch (e) {
      throw Exception('费用计算失败: $e');
    }
  }

  /// 计算指定表计类型的费用
  Future<MeterFeeDetail> _calculateMeterFee(
    List<MeterRecord> records,
    String meterType,
    int year,
    int month,
  ) async {
    if (records.isEmpty) {
      return MeterFeeDetail(
        meterType: meterType,
        previousReading: 0,
        currentReading: 0,
        usage: 0,
        unitPrice: 0,
        totalAmount: 0,
      );
    }

    // 获取当前月的单价
    final unitPrice = await StorageService.getCurrentUnitPrice(meterType);
    final price = unitPrice?.unitPrice ?? 0.0;

    // 按日期排序，获取最新和最旧的读数
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final oldestRecord = records.first;
    final newestRecord = records.last;

    double previousReading = 0;
    double currentReading = 0;

    if (meterType == '水表') {
      previousReading = double.tryParse(oldestRecord.recognitionResult) ?? 0.0;
      currentReading = double.tryParse(newestRecord.recognitionResult) ?? 0.0;
    } else if (meterType == '电表') {
      previousReading = double.tryParse(oldestRecord.recognitionResult) ?? 0.0;
      currentReading = double.tryParse(newestRecord.recognitionResult) ?? 0.0;
    } else if (meterType == '燃气表') {
      previousReading = double.tryParse(oldestRecord.recognitionResult) ?? 0.0;
      currentReading = double.tryParse(newestRecord.recognitionResult) ?? 0.0;
    }

    final usage = currentReading - previousReading;
    final totalAmount = usage * price;

    return MeterFeeDetail(
      meterType: meterType,
      previousReading: previousReading,
      currentReading: currentReading,
      usage: usage,
      unitPrice: price,
      totalAmount: totalAmount,
    );
  }

  /// 批量计算多个房间的费用
  Future<List<FeeCalculationResult>> calculateBatchFees({
    required int year,
    required int month,
    List<String>? floors,
    List<String>? roomNumbers,
  }) async {
    try {
      // 获取所有房间
      final rooms = await StorageService.getRooms();
      List<FeeCalculationResult> results = [];

      for (final room in rooms) {
        // 如果指定了楼层或房间号，进行过滤
        if (floors != null && !floors.contains(room.floor)) continue;
        if (roomNumbers != null && !roomNumbers.contains(room.roomNumber)) continue;

        final result = await calculateFees(
          floor: room.floor.toString(),
          roomNumber: room.roomNumber,
          year: year,
          month: month,
        );
        results.add(result);
      }

      return results;
    } catch (e) {
      throw Exception('批量费用计算失败: $e');
    }
  }

  /// 获取指定房间的历史费用记录
  Future<List<FeeCalculationResult>> getRoomFeeHistory({
    required String floor,
    required String roomNumber,
    int? startYear,
    int? startMonth,
    int? endYear,
    int? endMonth,
  }) async {
    try {
      final allRecords = await StorageService.getMeterRecords();
      final roomRecords = allRecords.where((record) => 
        record.floor == floor && record.roomNumber == roomNumber
      ).toList();

      if (roomRecords.isEmpty) return [];

      // 获取所有有记录的月份
      final monthsSet = <String>{};
      for (final record in roomRecords) {
        final monthKey = '${record.timestamp.year}-${record.timestamp.month}';
        monthsSet.add(monthKey);
      }

      List<FeeCalculationResult> results = [];
      for (final monthKey in monthsSet) {
        final parts = monthKey.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        // 如果指定了时间范围，进行过滤
        if (startYear != null && startMonth != null) {
          if (year < startYear || (year == startYear && month < startMonth)) {
            continue;
          }
        }
        if (endYear != null && endMonth != null) {
          if (year > endYear || (year == endYear && month > endMonth)) {
            continue;
          }
        }

        final result = await calculateFees(
          floor: floor,
          roomNumber: roomNumber,
          year: year,
          month: month,
        );
        results.add(result);
      }

      // 按时间排序
      results.sort((a, b) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        return a.month.compareTo(b.month);
      });

      return results;
    } catch (e) {
      throw Exception('获取历史费用记录失败: $e');
    }
  }
}

/// 费用计算结果
class FeeCalculationResult {
  final String floor;
  final String roomNumber;
  final int year;
  final int month;
  final MeterFeeDetail waterFee;
  final MeterFeeDetail electricFee;
  final MeterFeeDetail gasFee;
  final double rent;
  final double publicServiceFee;
  final double sanitationFee;
  final double totalAmount;

  FeeCalculationResult({
    required this.floor,
    required this.roomNumber,
    required this.year,
    required this.month,
    required this.waterFee,
    required this.electricFee,
    required this.gasFee,
    required this.rent,
    required this.publicServiceFee,
    required this.sanitationFee,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'floor': floor,
      'roomNumber': roomNumber,
      'year': year,
      'month': month,
      'waterFee': waterFee.toJson(),
      'electricFee': electricFee.toJson(),
      'gasFee': gasFee.toJson(),
      'rent': rent,
      'publicServiceFee': publicServiceFee,
      'sanitationFee': sanitationFee,
      'totalAmount': totalAmount,
    };
  }

  factory FeeCalculationResult.fromJson(Map<String, dynamic> json) {
    return FeeCalculationResult(
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      year: json['year'],
      month: json['month'],
      waterFee: MeterFeeDetail.fromJson(json['waterFee']),
      electricFee: MeterFeeDetail.fromJson(json['electricFee']),
      gasFee: MeterFeeDetail.fromJson(json['gasFee']),
      rent: json['rent'].toDouble(),
      publicServiceFee: json['publicServiceFee'].toDouble(),
      sanitationFee: json['sanitationFee'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
    );
  }
}

/// 表计费用详情
class MeterFeeDetail {
  final String meterType;
  final double previousReading;
  final double currentReading;
  final double usage;
  final double unitPrice;
  final double totalAmount;

  MeterFeeDetail({
    required this.meterType,
    required this.previousReading,
    required this.currentReading,
    required this.usage,
    required this.unitPrice,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'meterType': meterType,
      'previousReading': previousReading,
      'currentReading': currentReading,
      'usage': usage,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }

  factory MeterFeeDetail.fromJson(Map<String, dynamic> json) {
    return MeterFeeDetail(
      meterType: json['meterType'],
      previousReading: json['previousReading'].toDouble(),
      currentReading: json['currentReading'].toDouble(),
      usage: json['usage'].toDouble(),
      unitPrice: json['unitPrice'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
    );
  }
}
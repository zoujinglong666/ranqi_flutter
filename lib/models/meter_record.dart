class MeterRecord {
  final String id;
  final String imagePath;
  final String base64Image;
  final String recognitionResult;
  final int floor;
  final String roomNumber;
  final DateTime timestamp;
  final String meterType; // 表计类型（燃气/水/电）
  
  // 新增：详细API响应信息
  final String? requestId; // API请求ID
  final String? integerPart; // 整数部分
  final String? decimalPart; // 小数部分
  final List<RecognitionDetail>? recognitionDetails; // 识别详情列表
  final bool isManuallyEdited; // 是否手动修正

  // Getter方法，用于兼容现有代码
  String get roomName => '$floor-$roomNumber';
  String get meterReading => recognitionResult;

  MeterRecord({
    required this.id,
    required this.imagePath,
    required this.base64Image,
    required this.recognitionResult,
    required this.floor,
    required this.roomNumber,
    required this.timestamp,
    required this.meterType,
    this.requestId,
    this.integerPart,
    this.decimalPart,
    this.recognitionDetails,
    this.isManuallyEdited = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'base64Image': base64Image,
      'recognitionResult': recognitionResult,
      'floor': floor,
      'roomNumber': roomNumber,
      'timestamp': timestamp.toIso8601String(),
      'meterType': meterType,
      'requestId': requestId,
      'integerPart': integerPart,
      'decimalPart': decimalPart,
      'recognitionDetails': recognitionDetails?.map((e) => e.toJson()).toList(),
      'isManuallyEdited': isManuallyEdited,
    };
  }

  factory MeterRecord.fromJson(Map<String, dynamic> json) {
    return MeterRecord(
      id: json['id'],
      imagePath: json['imagePath'],
      base64Image: json['base64Image'],
      recognitionResult: json['recognitionResult'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      timestamp: DateTime.parse(json['timestamp']),
      meterType: json['meterType'] ?? '燃气', // 兼容旧数据，默认为燃气
      requestId: json['requestId'],
      integerPart: json['integerPart'],
      decimalPart: json['decimalPart'],
      recognitionDetails: json['recognitionDetails'] != null
          ? (json['recognitionDetails'] as List)
              .map((e) => RecognitionDetail.fromJson(e))
              .toList()
          : null,
      isManuallyEdited: json['isManuallyEdited'] ?? false,
    );
  }
}

// 识别详情类
class RecognitionDetail {
  final String word; // 识别的文字
  final double probability; // 置信度
  final String className; // 分类名称

  RecognitionDetail({
    required this.word,
    required this.probability,
    required this.className,
  });

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'probability': probability,
      'className': className,
    };
  }

  factory RecognitionDetail.fromJson(Map<String, dynamic> json) {
    return RecognitionDetail(
      word: json['word'] ?? '',
      probability: (json['probability'] ?? 0.0).toDouble(),
      className: json['className'] ?? '',
    );
  }
}
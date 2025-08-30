class Room {
  final String id;
  final int floor;
  final String roomNumber;
  final double waterPricePerTon; // 水费单价（元/吨）
  final double electricityPricePerKwh; // 电费单价（元/度）
  final double initialWaterAmount; // 初始水量（吨）
  final double initialElectricityAmount; // 初始电量（度）
  final String? occupantName; // 入住人姓名（可为空）
  final String? contactPhone; // 联系电话（可为空）
  final String? checkInInfo; // 入住信息（可为空）

  Room({
    required this.id,
    required this.floor,
    required this.roomNumber,
    this.waterPricePerTon = 3.0, // 默认水费3元/吨
    this.electricityPricePerKwh = 0.6, // 默认电费0.6元/度
    this.initialWaterAmount = 0.0, // 默认初始水量0吨
    this.initialElectricityAmount = 0.0, // 默认初始电量0度
    this.occupantName, // 入住人姓名
    this.contactPhone, // 联系电话
    this.checkInInfo, // 入住信息
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'roomNumber': roomNumber,
      'waterPricePerTon': waterPricePerTon,
      'electricityPricePerKwh': electricityPricePerKwh,
      'initialWaterAmount': initialWaterAmount,
      'initialElectricityAmount': initialElectricityAmount,
      'occupantName': occupantName,
      'contactPhone': contactPhone,
      'checkInInfo': checkInInfo,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      waterPricePerTon: (json['waterPricePerTon'] ?? 3.0).toDouble(),
      electricityPricePerKwh: (json['electricityPricePerKwh'] ?? 0.6).toDouble(),
      initialWaterAmount: (json['initialWaterAmount'] ?? 0.0).toDouble(),
      initialElectricityAmount: (json['initialElectricityAmount'] ?? 0.0).toDouble(),
      occupantName: json['occupantName'],
      contactPhone: json['contactPhone'],
      checkInInfo: json['checkInInfo'],
    );
  }
}
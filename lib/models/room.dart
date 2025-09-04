class Room {
  final String id;
  final int floor;
  final String roomNumber;
  final double waterPricePerTon; // 水费单价（元/吨）
  final double electricityPricePerKwh; // 电费单价（元/度）
  final double gasPricePerCubicMeter; // 燃气费单价（元/立方米）
  final double initialWaterAmount; // 初始水量（吨）
  final double initialElectricityAmount; // 初始电量（度）
  final double initialGasAmount; // 初始燃气量（立方米）
  final String? occupantName; // 入住人姓名（可为空）
  final String? contactPhone; // 联系电话（可为空）
  final String? wechatId; // 微信号（可为空）
  final DateTime? checkInDate; // 入住日期（可为空）
  final String? checkInInfo; // 入住信息（可为空）
  final double? monthlyRent; // 月租金（可为空）
  final double? serviceFee; // 服务费（可为空）
  final double? cleaningFee; // 卫生费（可为空）

  // Getter方法，用于兼容现有代码
  String get name => '$floor-$roomNumber';
  String get floorName => '$floor楼';

  Room({
    required this.id,
    required this.floor,
    required this.roomNumber,
    this.waterPricePerTon = 3.0, // 默认水费3元/吨
    this.electricityPricePerKwh = 0.6, // 默认电费0.6元/度
    this.gasPricePerCubicMeter = 2.5, // 默认燃气费2.5元/立方米
    this.initialWaterAmount = 0.0, // 默认初始水量0吨
    this.initialElectricityAmount = 0.0, // 默认初始电量0度
    this.initialGasAmount = 0.0, // 默认初始燃气量0立方米
    this.occupantName, // 入住人姓名
    this.contactPhone, // 联系电话
    this.wechatId, // 微信号
    this.checkInDate, // 入住日期
    this.checkInInfo, // 入住信息
    this.monthlyRent, // 月租金
    this.serviceFee, // 服务费
    this.cleaningFee, // 卫生费
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'roomNumber': roomNumber,
      'waterPricePerTon': waterPricePerTon,
      'electricityPricePerKwh': electricityPricePerKwh,
      'gasPricePerCubicMeter': gasPricePerCubicMeter,
      'initialWaterAmount': initialWaterAmount,
      'initialElectricityAmount': initialElectricityAmount,
      'initialGasAmount': initialGasAmount,
      'occupantName': occupantName,
      'contactPhone': contactPhone,
      'wechatId': wechatId,
      'checkInDate': checkInDate?.toIso8601String(),
      'checkInInfo': checkInInfo,
      'monthlyRent': monthlyRent,
      'serviceFee': serviceFee,
      'cleaningFee': cleaningFee,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      waterPricePerTon: (json['waterPricePerTon'] ?? 3.0).toDouble(),
      electricityPricePerKwh: (json['electricityPricePerKwh'] ?? 0.6).toDouble(),
      gasPricePerCubicMeter: (json['gasPricePerCubicMeter'] ?? 2.5).toDouble(),
      initialWaterAmount: (json['initialWaterAmount'] ?? 0.0).toDouble(),
      initialElectricityAmount: (json['initialElectricityAmount'] ?? 0.0).toDouble(),
      initialGasAmount: (json['initialGasAmount'] ?? 0.0).toDouble(),
      occupantName: json['occupantName'],
      contactPhone: json['contactPhone'],
      wechatId: json['wechatId'],
      checkInDate: json['checkInDate'] != null ? DateTime.parse(json['checkInDate']) : null,
      checkInInfo: json['checkInInfo'],
      monthlyRent: json['monthlyRent']?.toDouble(),
      serviceFee: json['serviceFee']?.toDouble(),
      cleaningFee: json['cleaningFee']?.toDouble(),
    );
  }
}
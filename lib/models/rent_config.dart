class RentConfig {
  final String id;
  final int floor;
  final String roomNumber;
  final double rentAmount; // 租金金额
  final DateTime startDate; // 生效开始日期
  final DateTime? endDate; // 生效结束日期（null表示长期有效）
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes; // 备注
  final bool isActive; // 是否激活

  RentConfig({
    required this.id,
    required this.floor,
    required this.roomNumber,
    required this.rentAmount,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isActive = true,
  });

  // 检查指定日期是否在有效期内
  bool isValidForDate(DateTime date) {
    if (!isActive) return false;
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    
    if (dateOnly.isBefore(startOnly)) return false;
    
    if (endDate != null) {
      final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (dateOnly.isAfter(endOnly)) return false;
    }
    
    return true;
  }

  // 检查指定月份是否在有效期内
  bool isValidForMonth(DateTime month) {
    if (!isActive) return false;
    
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    
    // 检查月份是否与有效期有重叠
    final configStart = DateTime(startDate.year, startDate.month, startDate.day);
    final configEnd = endDate != null 
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : DateTime(2099, 12, 31); // 如果没有结束日期，设为很远的未来
    
    return !(monthEnd.isBefore(configStart) || monthStart.isAfter(configEnd));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'roomNumber': roomNumber,
      'rentAmount': rentAmount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory RentConfig.fromJson(Map<String, dynamic> json) {
    return RentConfig(
      id: json['id'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      rentAmount: json['rentAmount'].toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(json['startDate']),
      endDate: json['endDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['endDate'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      notes: json['notes'],
      isActive: json['isActive'] ?? true,
    );
  }

  RentConfig copyWith({
    String? id,
    int? floor,
    String? roomNumber,
    double? rentAmount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
  }) {
    return RentConfig(
      id: id ?? this.id,
      floor: floor ?? this.floor,
      roomNumber: roomNumber ?? this.roomNumber,
      rentAmount: rentAmount ?? this.rentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'RentConfig{id: $id, floor: $floor, roomNumber: $roomNumber, rentAmount: $rentAmount, startDate: $startDate, endDate: $endDate, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RentConfig &&
        other.id == id &&
        other.floor == floor &&
        other.roomNumber == roomNumber &&
        other.rentAmount == rentAmount &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        floor.hashCode ^
        roomNumber.hashCode ^
        rentAmount.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        isActive.hashCode;
  }
}
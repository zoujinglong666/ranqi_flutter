class ServiceFee {
  final String id;
  final String floor;
  final String roomNumber;
  final String feeType; // '公共服务费' 或 '卫生费'
  final double amount;
  final DateTime month; // 所属月份
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceFee({
    required this.id,
    required this.floor,
    required this.roomNumber,
    required this.feeType,
    required this.amount,
    required this.month,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'roomNumber': roomNumber,
      'feeType': feeType,
      'amount': amount,
      'month': month.millisecondsSinceEpoch,
      'remarks': remarks,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ServiceFee.fromJson(Map<String, dynamic> json) {
    return ServiceFee(
      id: json['id'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      feeType: json['feeType'],
      amount: json['amount'].toDouble(),
      month: DateTime.fromMillisecondsSinceEpoch(json['month']),
      remarks: json['remarks'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
    );
  }

  ServiceFee copyWith({
    String? id,
    String? floor,
    String? roomNumber,
    String? feeType,
    double? amount,
    DateTime? month,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceFee(
      id: id ?? this.id,
      floor: floor ?? this.floor,
      roomNumber: roomNumber ?? this.roomNumber,
      feeType: feeType ?? this.feeType,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ServiceFee{id: $id, floor: $floor, roomNumber: $roomNumber, feeType: $feeType, amount: $amount, month: $month}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceFee &&
        other.id == id &&
        other.floor == floor &&
        other.roomNumber == roomNumber &&
        other.feeType == feeType &&
        other.amount == amount &&
        other.month == month &&
        other.remarks == remarks;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      floor,
      roomNumber,
      feeType,
      amount,
      month,
      remarks,
    );
  }
}
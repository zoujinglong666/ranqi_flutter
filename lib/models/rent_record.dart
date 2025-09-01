class RentRecord {
  final String id;
  final int floor;
  final String roomNumber;
  final double rentAmount; // 租金金额
  final DateTime month; // 租金所属月份
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes; // 备注

  RentRecord({
    required this.id,
    required this.floor,
    required this.roomNumber,
    required this.rentAmount,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'roomNumber': roomNumber,
      'rentAmount': rentAmount,
      'month': month.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  factory RentRecord.fromJson(Map<String, dynamic> json) {
    return RentRecord(
      id: json['id'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
      rentAmount: json['rentAmount'].toDouble(),
      month: DateTime.fromMillisecondsSinceEpoch(json['month']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      notes: json['notes'],
    );
  }

  RentRecord copyWith({
    String? id,
    int? floor,
    String? roomNumber,
    double? rentAmount,
    DateTime? month,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return RentRecord(
      id: id ?? this.id,
      floor: floor ?? this.floor,
      roomNumber: roomNumber ?? this.roomNumber,
      rentAmount: rentAmount ?? this.rentAmount,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'RentRecord{id: $id, floor: $floor, roomNumber: $roomNumber, rentAmount: $rentAmount, month: $month}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RentRecord &&
        other.id == id &&
        other.floor == floor &&
        other.roomNumber == roomNumber &&
        other.rentAmount == rentAmount &&
        other.month == month;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        floor.hashCode ^
        roomNumber.hashCode ^
        rentAmount.hashCode ^
        month.hashCode;
  }
}
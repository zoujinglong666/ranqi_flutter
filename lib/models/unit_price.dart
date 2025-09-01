class UnitPrice {
  final String id;
  final String meterType; // 表计类型：燃气、水表、电表
  final double price; // 单价
  final DateTime effectiveDate; // 生效日期
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive; // 是否启用
  final String? notes; // 备注

  // 为了兼容性添加的getter
  double get unitPrice => price;
  String get remarks => notes ?? '';
  bool get isEnabled => isActive;

  UnitPrice({
    required this.id,
    required this.meterType,
    required this.price,
    required this.effectiveDate,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meterType': meterType,
      'price': price,
      'effectiveDate': effectiveDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'notes': notes,
    };
  }

  factory UnitPrice.fromJson(Map<String, dynamic> json) {
    return UnitPrice(
      id: json['id'],
      meterType: json['meterType'],
      price: json['price'].toDouble(),
      effectiveDate: DateTime.fromMillisecondsSinceEpoch(json['effectiveDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
    );
  }

  UnitPrice copyWith({
    String? id,
    String? meterType,
    double? price,
    DateTime? effectiveDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? notes,
  }) {
    return UnitPrice(
      id: id ?? this.id,
      meterType: meterType ?? this.meterType,
      price: price ?? this.price,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'UnitPrice{id: $id, meterType: $meterType, price: $price, effectiveDate: $effectiveDate, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnitPrice &&
        other.id == id &&
        other.meterType == meterType &&
        other.price == price &&
        other.effectiveDate == effectiveDate &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        meterType.hashCode ^
        price.hashCode ^
        effectiveDate.hashCode ^
        isActive.hashCode;
  }
}
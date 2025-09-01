class Floor {
  final int floorNumber;
  final DateTime createdAt;
  final String? description;

  Floor({
    required this.floorNumber,
    required this.createdAt,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'floorNumber': floorNumber,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      floorNumber: json['floorNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Floor && other.floorNumber == floorNumber;
  }

  @override
  int get hashCode => floorNumber.hashCode;
}
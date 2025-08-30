class Room {
  final String id;
  final int floor;
  final String roomNumber;

  Room({
    required this.id,
    required this.floor,
    required this.roomNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'roomNumber': roomNumber,
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      floor: json['floor'],
      roomNumber: json['roomNumber'],
    );
  }
}
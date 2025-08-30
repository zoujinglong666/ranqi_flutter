class MeterRecord {
  final String id;
  final String imagePath;
  final String base64Image;
  final String recognitionResult;
  final int floor;
  final String roomNumber;
  final DateTime timestamp;

  MeterRecord({
    required this.id,
    required this.imagePath,
    required this.base64Image,
    required this.recognitionResult,
    required this.floor,
    required this.roomNumber,
    required this.timestamp,
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
    );
  }
}
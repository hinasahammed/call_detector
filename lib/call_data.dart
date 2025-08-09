// call_data.dart
class CallData {
  final String number;
  final DateTime timestamp;
  final Duration duration;
  final String type;

  CallData({
    required this.number,
    required this.timestamp,
    required this.duration,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration.inSeconds,
      'type': type,
    };
  }

  factory CallData.fromMap(Map<String, dynamic> map) {
    return CallData(
      number: map['number'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      duration: Duration(seconds: map['duration'] ?? 0),
      type: map['type'] ?? 'Unknown',
    );
  }

  @override
  String toString() {
    return 'CallData{number: $number, timestamp: $timestamp, duration: $duration, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CallData &&
      other.number == number &&
      other.timestamp == timestamp &&
      other.duration == duration &&
      other.type == type;
  }

  @override
  int get hashCode {
    return number.hashCode ^
      timestamp.hashCode ^
      duration.hashCode ^
      type.hashCode;
  }
}
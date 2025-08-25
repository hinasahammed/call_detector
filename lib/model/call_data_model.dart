class CallData {
  CallData({
    required this.number,
    required this.date,
    required this.time,
    required this.duration,
    this.username,
    this.customerCode,
    this.status = -1, // Default value
    this.serviceStatus = -1, // Default value
    this.synced = false,
  });
  
  final String number;
  final String date; // Format: YYYY-MM-DD
  final String time; // Format: HH:MM:SS
  final String duration;
  final String? username;
  final String? customerCode;
  final int status; // -1, 0, or 1
  final int serviceStatus; // -1, 0, or 1
  final bool synced;

  // Helper method to get combined DateTime
  DateTime get dateTime {
    return DateTime.parse('$date $time');
  }

  // Helper method to get timestamp string (for backward compatibility)
  String get timestamp {
    return dateTime.toIso8601String();
  }
}
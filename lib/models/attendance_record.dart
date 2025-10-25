class AttendanceRecord {
  final int? id;
  final String name;
  final String date;
  final String time;
  final String status;

  AttendanceRecord({
    this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'time': time,
      'status': status,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      time: map['time'],
      status: map['status'],
    );
  }
}


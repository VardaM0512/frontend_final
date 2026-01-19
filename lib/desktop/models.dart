class Slot {
  final String id;
  final String time; // e.g. "09:00 AM"
  final String date; // "yyyy-MM-dd"
  final String room;
  final String? assignedToId; // faculty id who booked
  final String? assignedToName; // convenience for UI
  final String status; // 'OPEN'|'FILLED'
  final String complex;
  final String examName;

  Slot({
    required this.id,
    required this.time,
    required this.date,
    required this.room,
    this.assignedToId,
    this.assignedToName,
    this.status = 'OPEN',
    this.complex = 'Main',
    this.examName = 'Exam',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'date': date,
        'room': room,
        'assignedToId': assignedToId,
        'assignedToName': assignedToName,
        'status': status,
        'complex': complex,
        'examName': examName,
      };

  static Slot fromJson(Map<String, dynamic> j) => Slot(
        id: j['id'] as String,
        time: j['time'] as String,
        date: j['date'] as String,
        room: j['room'] as String,
        assignedToId: j['assignedToId'] as String?,
        assignedToName: j['assignedToName'] as String?,
        status: j['status'] as String? ?? 'OPEN',
        complex: j['complex'] as String? ?? 'Main',
        examName: j['examName'] as String? ?? 'Exam',
      );
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String position;
  final int quota;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    required this.quota,
  });
}

class AppAuthResponse {
  final String token;
  final String userId;
  final String role;

  AppAuthResponse({
    required this.token,
    required this.userId,
    required this.role,
  });
}

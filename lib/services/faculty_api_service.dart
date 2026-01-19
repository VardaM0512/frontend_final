import 'dart:convert';
import 'package:http/http.dart' as http;
import '../desktop/models.dart';

class FacultyApiService {
  static const String baseUrl =
      'https://iecseinvigilationbackend.onrender.com'; // CHANGE if needed

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // 1️⃣ Get faculty profile + assigned slots
  static Future<Map<String, dynamic>> getFacultyMe(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/faculty/me'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to fetch faculty info | ${res.statusCode} | ${res.body}',
      );
    }

    final json = jsonDecode(res.body);

    final profileJson = json['profile'];
    final profile = UserProfile(
      id: profileJson['id'],
      name: profileJson['email'], // backend does not return name
      email: profileJson['email'],
      position: profileJson['role'],
      quota: 0,
    );

    final slots = (json['assignedSlots'] as List)
        .map((s) => Slot(
              id: s['id'],
              date: s['exam_dates']['date'],
              time: '${s['start_time']} - ${s['end_time']}',
              room: s['classrooms']['room_number'],
              status: 'FILLED',
            ))
        .toList();

    return {
      'profile': profile,
      'assignedSlots': slots,
    };
  }

  // 2️⃣ List all slots (open + assigned)
  static Future<List<Slot>> listSlots(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/faculty/slots'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch slots');
    }

    final list = jsonDecode(res.body) as List;

    return list.map((s) {
      return Slot(
        id: s['id'],
        date: s['exam_dates']['date'],
        time: '${s['start_time']} - ${s['end_time']}',
        room: s['classrooms']['room_number'],
        assignedToId: s['assigned_faculty'],
        status: s['assigned_faculty'] == null ? 'OPEN' : 'FILLED',
      );
    }).toList();
  }

  // 3️⃣ Assign slot
  static Future<void> assignSlot(String token, String slotId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/faculty/assign/$slotId'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to assign slot');
    }
  }

  // 4️⃣ Unassign slot
  static Future<void> unassignSlot(String token, String slotId) async {
    final res = await http.put(
      Uri.parse('$baseUrl/faculty/unassign/$slotId'),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to unassign slot');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/faculty_api_service.dart';
import 'package:iesce_invigilation/desktop/models.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class DataManager {
  static const String _baseUrl =
      'https://iecseinvigilationbackend.onrender.com/faculty';
  static String? _authToken;
  static File? _file;
  static Map<String, dynamic> _db = {};
  static bool _isInitialized = false;

  // --- CONFIGURATION ---
  static final List<String> _staticRooms = [
    "NLH-201",
    "NLH-202",
    "NLH-203",
    "NLH-204",
    "AB5-301",
    "AB5-302",
    "AB5-303",
    "AB5-304"
  ];
  static final List<String> _staticTimes = ["09:00 AM", "02:00 PM"];

  static Future<void> authLogout() async {
    _ensureInitialized();
    _db['current_user_id'] = null;
    await _save();
  }

  // --------------------------------------------------------------------------
  // INIT / PERSISTENCE
  // --------------------------------------------------------------------------
  static Future<void> init({bool isMemoryOnly = false}) async {
    if (_isInitialized && !isMemoryOnly) return;
    _db = {};

    try {
      if (!isMemoryOnly) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/desktop_db.json');
        _file = file;

        if (await file.exists()) {
          final contents = await file.readAsString();
          _db = jsonDecode(contents) as Map<String, dynamic>;
        } else {
          _createInitialDb();
          await _save();
        }
      } else {
        _file = null;
        _createInitialDb();
      }

      _db['users'] ??= {};
      _db['exam_dates'] ??= {};
      _db['slots'] ??= {};

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  static void _createInitialDb() {
    final users = <String, dynamic>{};

    final dean = {
      'id': 'dean-1',
      'name': 'Dean Demo',
      'email': 'dean@local',
      'position': 'Dean / Admin',
      'quota': 10,
    };
    final alice = {
      'id': 'fac-1',
      'name': 'Alice Faculty',
      'email': 'alice@uni',
      'position': 'Assistant Professor',
      'quota': 2,
    };
    final bob = {
      'id': 'fac-2',
      'name': 'Bob Faculty',
      'email': 'bob@uni',
      'position': 'Associate Professor',
      'quota': 3,
    };

    users[dean['id'] as String] = dean;
    users[alice['id'] as String] = alice;
    users[bob['id'] as String] = bob;

    final slots = <String, dynamic>{};
    final examDates = <String, dynamic>{};

    // Create tomorrow's date
    final now = DateTime.now().toUtc();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final dateStr =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final dateId = 'date-$dateStr';

    final slotIds = <String>[];
    for (final t in _staticTimes) {
      for (final rawRoom in _staticRooms) {
        // --- FIX: DERIVE COMPLEX DYNAMICALLY ---
        // "AB5-302" -> complex: "AB5", room: "302"
        final parts = rawRoom.split('-');
        final complex = parts.length > 1 ? parts[0] : 'Main';
        final roomNum = parts.length > 1 ? parts[1] : rawRoom;

        final sid =
            'slot-${dateStr}-${t.replaceAll(':', '').replaceAll(' ', '')}-$rawRoom';

        final s = Slot(
                id: sid,
                time: t,
                date: dateStr,
                room: roomNum, // Just "302"
                status: 'OPEN',
                complex: complex, // "AB5"
                examName: 'Demo Exam')
            .toJson();

        slots[sid] = s;
        slotIds.add(sid);
      }
    }

    examDates[dateId] = {
      'id': dateId,
      'date': dateStr,
      'slotIds': slotIds,
    };

    _db = {
      'users': users,
      'exam_dates': examDates,
      'slots': slots,
      'current_user_id': null,
    };
  }

  static Future<void> _save() async {
    if (_file == null) return;
    final encoded = const JsonEncoder.withIndent('  ').convert(_db);
    await _file!.writeAsString(encoded);
  }

  static Future<void> debugReset() async {
    _createInitialDb();
    await _save();
  }

  // --------------------------------------------------------------------------
  // AUTH
  // --------------------------------------------------------------------------
  static Future<AppAuthResponse> postAuthLogin(
    String email,
    String password,
  ) async {
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.session == null || res.user == null) {
      throw Exception("Invalid credentials");
    }

    _authToken = res.session!.accessToken;

    return AppAuthResponse(
      token: _authToken!,
      userId: res.user!.id,
      role: res.user!.userMetadata?['role'] ?? 'FACULTY',
    );
  }

  static int _deriveQuota(String designation) {
    final pos = designation.toLowerCase();
    if (pos.contains('associate')) return 3;
    if (pos.contains('assistant')) return 4;
    if (pos.contains('dean')) return 10;
    return 2;
  }

  // --------------------------------------------------------------------------
  // DEAN APIs
  // --------------------------------------------------------------------------
  static Future<Map<String, dynamic>> postDeanExamDates(String dateStr) async {
    _ensureInitialized();
    try {
      final examDates = Map<String, dynamic>.from(_db['exam_dates'] as Map);
      for (final e in examDates.values) {
        if ((e as Map)['date'] == dateStr)
          return {'error': 'Date already exists'};
      }

      final dateId = 'date-$dateStr';
      examDates[dateId] = {
        'id': dateId,
        'date': dateStr,
        'slotIds': <String>[],
      };
      _db['exam_dates'] = examDates;

      await postDeanGenerateSlots(dateId);
      return {'ok': true, 'id': dateId};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<String> postDeanGenerateSlots(String dateId) async {
    _ensureInitialized();
    final examDates = Map<String, dynamic>.from(_db['exam_dates'] as Map);
    final slots = Map<String, dynamic>.from(_db['slots'] as Map);

    final dateEntry = examDates[dateId] as Map<String, dynamic>?;
    if (dateEntry == null) return 'date_not_found';
    final dateStr = dateEntry['date'] as String;

    final slotIds = <String>[];
    for (final t in _staticTimes) {
      for (final rawRoom in _staticRooms) {
        // --- FIX: DERIVE COMPLEX HERE TOO ---
        final parts = rawRoom.split('-');
        final complex = parts.length > 1 ? parts[0] : 'Main';
        final roomNum = parts.length > 1 ? parts[1] : rawRoom;

        final sid =
            'slot-${dateStr}-${t.replaceAll(':', '').replaceAll(' ', '')}-$rawRoom';
        if (!slots.containsKey(sid)) {
          final s = Slot(
                  id: sid,
                  time: t,
                  date: dateStr,
                  room: roomNum,
                  status: 'OPEN',
                  complex: complex,
                  examName: 'Demo Exam')
              .toJson();
          slots[sid] = s;
        }
        slotIds.add(sid);
      }
    }

    dateEntry['slotIds'] = slotIds;
    examDates[dateId] = dateEntry;
    _db['exam_dates'] = examDates;
    _db['slots'] = slots;
    await _save();

    return 'ok';
  }

  static Future<String> deleteDeanExamDate(String dateId) async {
    _ensureInitialized();
    final examDates = Map<String, dynamic>.from(_db['exam_dates'] as Map);
    final slots = Map<String, dynamic>.from(_db['slots'] as Map);

    if (!examDates.containsKey(dateId)) return 'not_found';

    final dateEntry = examDates[dateId];
    final dateSlotIds = (dateEntry['slotIds'] as List).cast<String>();

    for (final sid in dateSlotIds) {
      slots.remove(sid);
    }

    examDates.remove(dateId);
    _db['exam_dates'] = examDates;
    _db['slots'] = slots;
    await _save();
    return 'ok';
  }

  static Future<String> getDeanSchedulePdf() async {
    return 'mock://dean_schedule.pdf';
  }

  static Future<Map<String, Map<String, Map<String, List<Slot>>>>>
      getDeanScheduleMockData() async {
    _ensureInitialized();
    final Map<String, Map<String, Map<String, List<Slot>>>> out = {};
    final examDates = Map<String, dynamic>.from(_db['exam_dates'] as Map);
    final slots = Map<String, dynamic>.from(_db['slots'] as Map);

    for (final ed in examDates.values) {
      final dateEntry = Map<String, dynamic>.from(ed as Map);
      final dateStr = dateEntry['date'] as String;
      final slotIds = (dateEntry['slotIds'] as List).cast<String>();
      final timesMap = <String, Map<String, List<Slot>>>{};

      for (final sid in slotIds) {
        final sJson = Map<String, dynamic>.from(slots[sid] as Map);
        final slot = Slot.fromJson(sJson);
        timesMap.putIfAbsent(slot.time, () => <String, List<Slot>>{});
        timesMap[slot.time]!.putIfAbsent(slot.complex, () => <Slot>[]);
        timesMap[slot.time]![slot.complex]!.add(slot);
      }
      out[dateStr] = timesMap;
    }
    return out;
  }

  static Future<List<String>> getDeanDateList() async {
    _ensureInitialized();
    final examDates = Map<String, dynamic>.from(_db['exam_dates'] as Map);
    final dates = <String>[];
    for (final e in examDates.values) {
      final dateEntry = Map<String, dynamic>.from(e as Map);
      dates.add(dateEntry['date'] as String);
    }
    dates.sort();
    return dates;
  }

  static Future<Map<String, dynamic>> getFacultyMe() async {
    if (_authToken == null) {
      throw Exception("Not logged in");
    }

    final data = await FacultyApiService.getFacultyMe(_authToken!);

    final UserProfile rawProfile = data['profile'] as UserProfile;

    final profile = UserProfile(
      id: rawProfile.id,
      name: rawProfile.name,
      email: rawProfile.email,
      position: rawProfile.position,
      quota: _deriveQuota(rawProfile.position),
    );

    return {
      'profile': profile,
      'assignedSlots': data['assignedSlots'],
    };
  }

  static Future<List<Slot>> getSlotsForDateInternal(String dateStr) async {
    if (_authToken == null) {
      throw Exception("Not logged in");
    }

    final slots = await FacultyApiService.listSlots(_authToken!);

    return slots.where((slot) => slot.date == dateStr).toList();
  }

  static Future<String> postFacultyAssign(String slotId) async {
    if (_authToken == null) return 'not_logged_in';

    try {
      await FacultyApiService.assignSlot(_authToken!, slotId);
      return 'success';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('quota')) return 'quota_exceeded';
      if (msg.contains('not found')) return 'not_found';
      return 'error';
    }
  }

  static Future<String> putFacultyUnassign(String slotId) async {
    if (_authToken == null) return 'not_logged_in';

    try {
      await FacultyApiService.unassignSlot(_authToken!, slotId);
      return 'cancelled';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not found')) return 'not_found';
      return 'error';
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      print(
          "Warning: DataManager was not initialized. Auto-initializing in memory.");
      init(isMemoryOnly: true);
    }
  }
}

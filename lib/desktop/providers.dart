import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'data_manager.dart';

// --- AUTO DISPOSE PROVIDERS ---
// Using .autoDispose ensures that when you leave a screen (or log out),
// the cache is cleared. When you return, it fetches fresh data automatically.

// 1. User Profile
final currentUserProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final data = await DataManager.getFacultyMe();
  return data['profile'] as UserProfile;
});

// 2. Faculty Bookings (Calendar)
final facultyBookingsProvider = FutureProvider.autoDispose<List<Slot>>((ref) async {
  final data = await DataManager.getFacultyMe();
  return (data['assignedSlots'] as List).cast<Slot>();
});

// 3. Dean Date List (Dropdowns/Chips)
final examDatesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return await DataManager.getDeanDateList();
});

// 4. Slots for Date (Matrix Grid)
final slotsForDateProvider = FutureProvider.autoDispose.family<List<Slot>, String>((ref, dateStr) async {
  return await DataManager.getSlotsForDateInternal(dateStr);
});

// 5. Dean Schedule (Admin View)
final deanScheduleProvider = FutureProvider.autoDispose<Map<String, Map<String, Map<String, List<Slot>>>>>((ref) async {
  return await DataManager.getDeanScheduleMockData();
});
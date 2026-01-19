class ClassroomService {
  static final ClassroomService _instance =
  ClassroomService._internal();

  factory ClassroomService() => _instance;

  ClassroomService._internal();


  final Map<String, List<Map<String, String>>>
  _classroomsPerDate = {};

  List<Map<String, String>> getClassrooms(String dateKey) {
    return _classroomsPerDate[dateKey] ?? [];
  }

  void addClassroom(
      String dateKey,
      String classroom,
      String time,
      ) {
    _classroomsPerDate.putIfAbsent(dateKey, () => []);
    _classroomsPerDate[dateKey]!.add({
      'classroom': classroom,
      'time': time,
    });
  }

  void updateClassroom(
      String dateKey,
      int index,
      String newClassroom,
      String newTime,
      ) {
    if (_classroomsPerDate.containsKey(dateKey) &&
        index >= 0 &&
        index < _classroomsPerDate[dateKey]!.length) {
      _classroomsPerDate[dateKey]![index] = {
        'classroom': newClassroom,
        'time': newTime,
      };
    }
  }

  void deleteClassroom(String dateKey, int index) {
    if (_classroomsPerDate.containsKey(dateKey) &&
        index >= 0 &&
        index < _classroomsPerDate[dateKey]!.length) {
      _classroomsPerDate[dateKey]!.removeAt(index);
    }
  }

  void clearClassrooms(String dateKey) {
    _classroomsPerDate[dateKey]?.clear();
  }


  final Map<String, Map<String, Map<String, String>>>
  _allocations = {};

  String _getDateKey(DateTime date) =>
      "${date.year}-${date.month}-${date.day}";

  void allocateProfessor({
    required DateTime date,
    required String classroom,
    required String time,
    required String professorName,
  }) {
    final key = _getDateKey(date);

    _allocations.putIfAbsent(key, () => {});
    _allocations[key]!.putIfAbsent(classroom, () => {});

    _allocations[key]![classroom]![time] = professorName;
  }

  Map<String, Map<String, String>> getAllocations(DateTime date) {
    final key = _getDateKey(date);
    return _allocations[key] ?? {};
  }

  void clearAllocations(DateTime date) {
    final key = _getDateKey(date);
    _allocations[key]?.clear();
  }


  List<Map<String, String>> getAllocationsForDate(String dateKey) {
    final result = <Map<String, String>>[];

    final dayAllocations = _allocations[dateKey];
    if (dayAllocations == null) return result;

    dayAllocations.forEach((classroom, times) {
      times.forEach((time, professor) {
        result.add({
          'classroom': classroom,
          'time': time,
          'professor': professor,
        });
      });
    });

    return result;
  }
}

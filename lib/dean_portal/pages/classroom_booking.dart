import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';

class ClassroomBookingsPage extends StatefulWidget {
  const ClassroomBookingsPage({super.key});

  @override
  State<ClassroomBookingsPage> createState() =>
      _ClassroomBookingsPageState();
}

class _ClassroomBookingsPageState extends State<ClassroomBookingsPage> {
  DateTime selectedDate = DateTime.now();

  final TextEditingController classroomController =
  TextEditingController();
  final TextEditingController timeController =
  TextEditingController();

  String get dateKey =>
      "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

  // ---------------- EDIT SLOT DIALOG ----------------
  void _editSlot(int index, Map<String, String> room) {
    final editClassroomController =
    TextEditingController(text: room['classroom']);
    final editTimeController =
    TextEditingController(text: room['time']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Time Slot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editClassroomController,
              decoration: const InputDecoration(
                labelText: "Classroom",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editTimeController,
              decoration: const InputDecoration(
                labelText: "Time Slot",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ClassroomService().updateClassroom(
                dateKey,
                index,
                editClassroomController.text.trim(),
                editTimeController.text.trim(),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final classrooms = ClassroomService().getClassrooms(dateKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Classroom Bookings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- DATE PICKER ----------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Selected Date: "
                        "${selectedDate.day}-"
                        "${selectedDate.month}-"
                        "${selectedDate.year}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: const Text("Pick Date"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------- ADD SLOT ----------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: classroomController,
                    decoration: const InputDecoration(
                      labelText: "Classroom",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: "Time Slot (e.g., 9-10)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (classroomController.text.isEmpty ||
                        timeController.text.isEmpty) return;

                    ClassroomService().addClassroom(
                      dateKey,
                      classroomController.text.trim(),
                      timeController.text.trim(),
                    );

                    classroomController.clear();
                    timeController.clear();
                    setState(() {});
                  },
                  child: const Text("Save"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------- SLOT LIST ----------------
            Expanded(
              child: classrooms.isEmpty
                  ? const Center(
                child: Text("No classrooms added yet"),
              )
                  : ListView.separated(
                itemCount: classrooms.length,
                separatorBuilder: (_, __) =>
                const Divider(),
                itemBuilder: (_, index) {
                  final room = classrooms[index];

                  return ListTile(
                    title: Text(
                      "${room['classroom']} • ${room['time']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _editSlot(index, room),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            ClassroomService()
                                .deleteClassroom(
                                dateKey, index);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';

class FacultyInformationPage extends StatefulWidget {
  final String facultyName;
  final String department;
  final int allowedSlots;

  const FacultyInformationPage({
    super.key,
    required this.facultyName,
    required this.department,
    required this.allowedSlots,
  });

  @override
  State<FacultyInformationPage> createState() =>
      _FacultyInformationPageState();
}

class _FacultyInformationPageState extends State<FacultyInformationPage> {
  DateTime selectedDate = DateTime.now();
  final Set<String> selectedSlots = {};

  @override
  Widget build(BuildContext context) {
    final service = ClassroomService();
    final dateKey =
        "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    final allSlots = service.getClassrooms(dateKey);
    final allocations = service.getAllocations(selectedDate);

    selectedSlots.clear();
    allocations.forEach((classroom, times) {
      times.forEach((time, professor) {
        if (professor == widget.facultyName) {
          selectedSlots.add("$classroom|$time");
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Faculty Information")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.facultyName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Department: ${widget.department}",
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Text("Date: "),
                TextButton(
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
                  child: Text(
                    "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Selected Slots: ${selectedSlots.length} / ${widget.allowedSlots}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: allSlots.length,
                itemBuilder: (_, index) {
                  final slot = allSlots[index];
                  final key = "${slot['classroom']}|${slot['time']}";
                  final isSelected = selectedSlots.contains(key);

                  return ListTile(
                    title:
                    Text("${slot['classroom']} • ${slot['time']}"),
                    trailing: isSelected
                        ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    )
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedSlots.remove(key);
                        } else if (selectedSlots.length <
                            widget.allowedSlots) {
                          selectedSlots.add(key);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                allocations.forEach((classroom, times) {
                  times.removeWhere(
                        (_, professor) =>
                    professor == widget.facultyName,
                  );
                });

                for (var slot in selectedSlots) {
                  final parts = slot.split('|');
                  service.allocateProfessor(
                    date: selectedDate,
                    classroom: parts[0],
                    time: parts[1],
                    professorName: widget.facultyName,
                  );
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Allocation updated successfully"),
                  ),
                );
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}

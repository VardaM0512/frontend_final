import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';

class ProfessorAllocationPage extends StatefulWidget {
  final String professorName;
  final int allowedSlots;

  const ProfessorAllocationPage({
    super.key,
    required this.professorName,
    required this.allowedSlots,
  });

  @override
  State<ProfessorAllocationPage> createState() =>
      _ProfessorAllocationPageState();
}

class _ProfessorAllocationPageState extends State<ProfessorAllocationPage> {
  DateTime selectedDate = DateTime.now();
  final Set<int> selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    final dateKey = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    // Fetch classrooms saved for this date
    final availableSlots = ClassroomService().getClassrooms(dateKey);

    return Scaffold(
      appBar: AppBar(title: Text('Allocate ${widget.professorName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date picker
            Row(
              children: [
                const Text("Select Date: "),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        selectedIndices.clear(); // reset selections for new date
                      });
                    }
                  },
                  child: Text("${selectedDate.day}-${selectedDate.month}-${selectedDate.year}"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Slot list
            Expanded(
              child: ListView.builder(
                itemCount: availableSlots.length,
                itemBuilder: (_, index) {
                  final slot = availableSlots[index];
                  final isSelected = selectedIndices.contains(index);
                  return ListTile(
                    title: Text("${slot['classroom']} • ${slot['time']}"),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIndices.remove(index);
                        } else if (selectedIndices.length < widget.allowedSlots) {
                          selectedIndices.add(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: selectedIndices.length == widget.allowedSlots
                  ? () {
                final service = ClassroomService();
                for (var index in selectedIndices) {
                  final slot = availableSlots[index];
                  service.allocateProfessor(
                    date: selectedDate,
                    classroom: slot['classroom']!,
                    time: slot['time']!,
                    professorName: widget.professorName,
                  );
                }
                Navigator.pop(context);
              }
                  : null,
              child: Text("Save Allocation (${selectedIndices.length}/${widget.allowedSlots})"),
            ),
          ],
        ),
      ),
    );
  }
}

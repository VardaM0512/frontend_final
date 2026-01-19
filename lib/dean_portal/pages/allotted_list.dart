import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';

class AllottedListPage extends StatefulWidget {
  const AllottedListPage({super.key});

  @override
  State<AllottedListPage> createState() => _AllottedListPageState();
}

class _AllottedListPageState extends State<AllottedListPage> {
  DateTime selectedDate = DateTime.now();

  void _printPDF() {
    // TODO: Implement PDF export logic here
    print("Printing/Exporting PDF for $selectedDate");
  }

  @override
  Widget build(BuildContext context) {
    final allocations = ClassroomService().getAllocations(selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text("Allotted List")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                      });
                    }
                  },
                  child: Text("${selectedDate.day}-${selectedDate.month}-${selectedDate.year}"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Add the Print/Export button if allocations exist
            if (allocations.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _printPDF,
                icon: const Icon(Icons.print),
                label: const Text("Print/Export PDF"),
              ),

            const SizedBox(height: 16),
            Expanded(
              child: allocations.isEmpty
                  ? const Center(child: Text("No allocations for this date"))
                  : ListView(
                children: allocations.entries.expand((roomEntry) {
                  String classroom = roomEntry.key;
                  return roomEntry.value.entries.map((timeEntry) {
                    return ListTile(
                      title: Text("$classroom • ${timeEntry.key}"),
                      trailing: Text(timeEntry.value),
                    );
                  });
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- Riverpod
import 'package:intl/intl.dart';
import '../theme.dart';
import '../data_manager.dart'; 
import '../models.dart'; 
import '../providers.dart'; // <--- The Brain

class BookingScreen extends ConsumerWidget {
  final DateTime selectedDate;
  final String currentUserId;

  const BookingScreen({
    super.key, 
    required this.selectedDate,
    required this.currentUserId,
  });

  // Helper to handle Booking/Canceling actions
  Future<void> _handleAction(BuildContext context, WidgetRef ref, Future<String> Function() action) async {
    // 1. Execute the API call
    final msg = await action();
    
    // 2. Show Feedback
    if (context.mounted) {
       Color color = AppColors.primary;
       if (msg.contains('success') || msg == 'ok' || msg == 'cancelled') color = AppColors.success;
       if (msg.contains('error') || msg.contains('fail') || msg.contains('not')) color = AppColors.error;

       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg.toUpperCase()), 
        backgroundColor: color, 
        duration: const Duration(seconds: 1),
      ));
    }

    // 3. REFRESH DATA
    // We invalidate the providers to force a re-fetch.
    // This updates the Matrix (this screen) AND the Calendar (parent screen) simultaneously.
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    ref.invalidate(slotsForDateProvider(dateStr)); 
    ref.invalidate(facultyBookingsProvider); 
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    // 1. WATCH THE DATA
    // This automates loading/error states
    final slotsAsync = ref.watch(slotsForDateProvider(dateStr));

    return slotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error loading slots: $err")),
      data: (slots) {
        if (slots.isEmpty) return const Center(child: Text("No slots generated for this date."));

        // Dynamic Column/Row Logic
        final availableRooms = slots.map((s) => s.room).toSet().toList()..sort();
        final availableTimes = slots.map((s) => s.time).toSet().toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.all(color: Colors.grey.shade200),
                children: [
                  // --- HEADER ROW ---
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[50]),
                    children: [
                      const Padding(padding: EdgeInsets.all(16), child: Text("Time \\ Room", style: TextStyle(fontWeight: FontWeight.bold))),
                      ...availableRooms.map((r) => Padding(padding: const EdgeInsets.all(16), child: Text(r, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                  ),

                  // --- DATA ROWS ---
                  ...availableTimes.map((time) {
                    return TableRow(children: [
                      Padding(padding: const EdgeInsets.all(16), child: Text(time, style: const TextStyle(fontWeight: FontWeight.w600))),
                      
                      ...availableRooms.map((room) {
                         final slot = slots.firstWhere(
                            (s) => s.room == room && s.time == time,
                            orElse: () => Slot(id: "null", time: "", date: "", room: "", status: "NULL"), 
                         );

                         if (slot.status == "NULL") return Container(color: Colors.grey[50], height: 60);
                         
                         return _buildSlotCell(context, ref, slot);
                      })
                    ]);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotCell(BuildContext context, WidgetRef ref, Slot slot) {
    bool isFilled = slot.status == 'FILLED';
    bool isMine = slot.assignedToId == currentUserId; 

    if (isFilled) {
      if (isMine) {
        // CASE 1: My Booking (Green + Cancel)
        return Container(
          height: 60,
          color: AppColors.success.withOpacity(0.1), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
              const Text("YOURS", style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => _handleAction(context, ref, () => DataManager.putFacultyUnassign(slot.id)),
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 10, decoration: TextDecoration.underline)),
                ),
              )
            ],
          ),
        );
      } else {
        // CASE 2: Others' Booking (Grey + Locked)
        return Container(
          height: 60,
          color: Colors.grey[100], 
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.lock, color: Colors.grey[400], size: 18),
               Text(
                 slot.assignedToName ?? "Taken", 
                 overflow: TextOverflow.ellipsis, 
                 style: TextStyle(color: Colors.grey[500], fontSize: 10)
               ),
             ],
          ),
        );
      }
    }

    // CASE 3: Open Slot (Select Button)
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () => _handleAction(context, ref, () => DataManager.postFacultyAssign(slot.id)),
        child: const Text("Select"),
      ),
    );
  }
}
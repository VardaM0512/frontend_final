import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../data_manager.dart';
import '../providers.dart';
import 'faculty_dashboard.dart';

class DeanDashboard extends ConsumerStatefulWidget {
  const DeanDashboard({super.key});

  @override
  ConsumerState<DeanDashboard> createState() => _DeanDashboardState();
}

class _DeanDashboardState extends ConsumerState<DeanDashboard> {
  bool _isBookingMode = false;

  Future<void> _addDate(BuildContext context, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final result = await DataManager.postDeanExamDates(dateStr);

    if (context.mounted) {
      if (result.containsKey("error")) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['error']), backgroundColor: AppColors.error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Date Added: $dateStr"),
            backgroundColor: AppColors.success));
        ref.invalidate(examDatesProvider);
        ref.invalidate(deanScheduleProvider);
      }
    }
  }

  Future<void> _handleDeleteDate(BuildContext context, String dateStr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Exam Day?"),
        content: Text(
            "This will remove $dateStr and cancel ALL bookings for that day.\nThis cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await DataManager.deleteDeanExamDate('date-$dateStr');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Date Removed")));
        ref.invalidate(examDatesProvider);
        ref.invalidate(deanScheduleProvider);
        ref.invalidate(facultyBookingsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dean's Console"),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              children: [
                _buildModeButton(
                    "Admin View",
                    Icons.table_chart,
                    !_isBookingMode,
                    () => setState(() => _isBookingMode = false)),
                _buildModeButton("My Bookings", Icons.person, _isBookingMode,
                    () => setState(() => _isBookingMode = true)),
              ],
            ),
          ),
          if (!_isBookingMode)
            IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  final path = await DataManager.getDeanSchedulePdf();
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("PDF Downloaded to: $path")));
                }),
          if (!_isBookingMode)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(deanScheduleProvider);
                }),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Logout",
              onPressed: () async {
                await DataManager.authLogout();

                // Invalidate everything to be safe
                ref.invalidate(currentUserProvider);
                ref.invalidate(deanScheduleProvider);
                ref.invalidate(examDatesProvider);

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/desktop/login', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_isBookingMode
          ? FloatingActionButton.extended(
              label: const Text("Add Exam Day"),
              icon: const Icon(Icons.add),
              onPressed: () async {
                final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) _addDate(context, date);
              })
          : null,
      body: _isBookingMode
          ? const FacultyDashboardContent()
          : _buildAdminView(context, ref),
    );
  }

  Widget _buildModeButton(
      String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isActive ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminView(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(deanScheduleProvider);

    return scheduleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (groupedData) {
        final dates = groupedData.keys.toList()..sort();

        if (dates.isEmpty)
          return const Center(child: Text("No data. Add an exam day."));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final dateStr = dates[index];
            final timeMap = groupedData[dateStr]!;
            final displayDate =
                DateFormat('EEEE, MMM d, y').format(DateTime.parse(dateStr));
            final sortedTimes = timeMap.keys.toList()..sort();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(displayDate,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800])),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: "Remove this Exam Day",
                        onPressed: () => _handleDeleteDate(context, dateStr),
                      ),
                    ],
                  ),
                ),

                // The Main Content Block for this Date
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: sortedTimes.map<Widget>((time) {
                      final complexMap = timeMap[time]!;
                      final sortedComplexes = complexMap.keys.toList()..sort();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Header (e.g. 09:00 AM)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: Colors.grey[100],
                            child: Text(time,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),

                          // Group by Complex (e.g. NLH, AB5)
                          ...sortedComplexes.map((complex) {
                            final rooms = complexMap[complex]!;
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text("$complex Block",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                            fontSize: 13)),
                                  ),

                                  // --- THE DYNAMIC TABLE GRID ---
                                  GridView.extent(
                                    maxCrossAxisExtent:
                                        220, // Increased to fit Full Name
                                    childAspectRatio: 3.5, // Wider to fit text
                                    mainAxisSpacing: 0,
                                    crossAxisSpacing: 0,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: rooms.map((slot) {
                                      final isFilled =
                                          slot.assignedToId != null;

                                      // Logic: Show Full Name if filled, otherwise "OPEN"
                                      final displayText = isFilled
                                          ? (slot.assignedToName ?? "Faculty")
                                          : "OPEN";

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          color: isFilled
                                              ? const Color(0xFFF1F8E9)
                                              : Colors
                                                  .white, // Green tint if booked
                                        ),
                                        child: Row(
                                          children: [
                                            // Room Number
                                            Text(slot.room,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            const SizedBox(width: 8),

                                            // Divider
                                            Container(
                                                width: 1,
                                                height: 16,
                                                color: Colors.grey.shade300),
                                            const SizedBox(width: 8),

                                            // Status / Name
                                            Expanded(
                                              child: Text(
                                                displayText,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  // Green for Name, Red for OPEN
                                                  color: isFilled
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  // -----------------------------
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- Riverpod
import 'package:iesce_invigilation/desktop/data_manager.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../theme.dart';
import '../models.dart'; 
import '../providers.dart'; // <--- The Brain
import 'booking_screen.dart'; 

class FacultyDashboard extends ConsumerWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Portal"), 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () {
              // Manual Refresh: Invalidate all relevant providers
              ref.invalidate(currentUserProvider);
              ref.invalidate(facultyBookingsProvider);
              ref.invalidate(examDatesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: () async {
               // 1. Clear DB Session
               await DataManager.authLogout();
               
               // 2. Wipe Riverpod State (Security)
               ref.invalidate(currentUserProvider);
               ref.invalidate(facultyBookingsProvider);
               
               // 3. Navigate to Login
               if (context.mounted) {
                 // Using raw string or Routes.desktopLogin if you imported main.dart
                 Navigator.pushNamedAndRemoveUntil(context, '/desktop/login', (route) => false);
               }
            },
          )
        ]
      ),
      // We don't need GlobalKeys anymore because state is external
      body: const FacultyDashboardContent(),
    );
  }
}

class FacultyDashboardContent extends ConsumerStatefulWidget {
  const FacultyDashboardContent({super.key});

  @override
  ConsumerState<FacultyDashboardContent> createState() => _FacultyDashboardContentState();
}

class _FacultyDashboardContentState extends ConsumerState<FacultyDashboardContent> {
  // Only UI state remains local
  DateTime? _selectedDate;
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    // 1. WATCH THE DATA
    // The widget will rebuild automatically when these values change
    final userAsync = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(facultyBookingsProvider);
    final datesAsync = ref.watch(examDatesProvider);

    // 2. Handle Loading States (Chained for simplicity)
    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
      data: (user) {
        return bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
          data: (myBookings) {
            return datesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
              data: (dateStrings) {
                 return _buildContent(context, user, myBookings, dateStrings);
              }
            );
          }
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UserProfile user, List<Slot> myBookings, List<String> dateStrings) {
    // Logic: Auto-select first date if none selected
    // We use postFrameCallback to avoid "setState during build" errors
    if (_selectedDate == null && dateStrings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (mounted) {
           setState(() {
             _selectedDate = DateTime.parse(dateStrings.first);
             _calendarController.displayDate = _selectedDate;
           });
         }
      });
    }

    final progress = user.quota > 0 
        ? (myBookings.length / user.quota).clamp(0.0, 1.0) 
        : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- LEFT PANEL ---
        Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1), 
                  child: const Icon(Icons.person, color: AppColors.primary)
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.position),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Quota Usage", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text("${myBookings.length} / ${user.quota}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress, 
                minHeight: 8, 
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey[100],
                color: progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
              const Divider(height: 40),

              const Align(alignment: Alignment.centerLeft, child: Text("My Schedule", style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SfCalendar(
                      view: CalendarView.month,
                      controller: _calendarController,
                      // The Calendar DataSource now comes directly from Riverpod
                      dataSource: SlotDataSource(myBookings),
                      onSelectionChanged: (details) {
                        if (details.date != null) {
                          final dStr = DateFormat('yyyy-MM-dd').format(details.date!);
                          if (dateStrings.contains(dStr)) {
                            setState(() => _selectedDate = details.date);
                          }
                        }
                      },
                      monthViewSettings: const MonthViewSettings(
                        appointmentDisplayMode: MonthAppointmentDisplayMode.indicator, 
                        showAgenda: true,
                        agendaStyle: AgendaStyle(backgroundColor: Colors.transparent),
                      ),
                      todayHighlightColor: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- RIGHT PANEL ---
        Expanded(
          child: Column(
            children: [
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: dateStrings.isEmpty 
                  ? const Center(child: Text("No Active Exam Cycles", style: TextStyle(color: Colors.grey)))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: dateStrings.map((dateStr) {
                         final isSelected = _selectedDate != null && 
                                            DateFormat('yyyy-MM-dd').format(_selectedDate!) == dateStr;

                         return Padding(
                           padding: const EdgeInsets.only(right: 12.0),
                           child: FilterChip(
                             label: Text(dateStr),
                             selected: isSelected,
                             onSelected: (_) {
                               setState(() {
                                 _selectedDate = DateTime.parse(dateStr);
                                 _calendarController.displayDate = _selectedDate;
                               });
                             },
                             checkmarkColor: Colors.white,
                             selectedColor: AppColors.primary.withOpacity(0.2),
                             labelStyle: TextStyle(
                               color: isSelected ? AppColors.primary : Colors.black87, 
                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                             ),
                           ),
                         );
                      }).toList(),
                    ),
              ),
              Expanded(
                child: _selectedDate == null 
                  ? const Center(child: Text("Please select a date to view slots.")) 
                  : BookingScreen(
                      key: ValueKey(_selectedDate!.toIso8601String()), 
                      selectedDate: _selectedDate!, 
                      currentUserId: user.id, 
                      // No callback needed! BookingScreen invalidates provider, this widget auto-updates.
                    )
              )
            ],
          ),
        )
      ],
    );
  }
}

class SlotDataSource extends CalendarDataSource {
  SlotDataSource(List<Slot> source) {
    appointments = source.map((slot) {
      DateTime startTime;
      try {
        startTime = DateFormat("yyyy-MM-dd hh:mm a").parse("${slot.date} ${slot.time}");
      } catch (e) {
        startTime = DateTime.now();
      }
      return Appointment(
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        subject: "Invigilation @ ${slot.room}",
        color: AppColors.primary,
        notes: slot.id,
        isAllDay: false,
      );
    }).toList();
  }
}
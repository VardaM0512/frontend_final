import 'package:flutter/material.dart';
import 'package:iesce_invigilation/faculty_portal/pages/professor_allocation.dart';
import 'faculty_information.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dean Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          children: [
            _buildDashboardCard(
              context,
              title: 'Professor Allocation',
              icon: Icons.person_search,
              onTap: () {
                // Directly open allocation page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorAllocationPage(
                      // TEMPORARY — later this comes from login
                      professorName: 'Logged In Professor',
                      allowedSlots: 2,
                    ),
                  ),
                );
              },
            ),
            _buildDashboardCard(
              context,
              title: 'Faculty information',
              icon: Icons.list_alt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FacultyInformationPage(
                        facultyName: "Srikanth Prabhu",
                        department: "CSE",
                        allowedSlots: 3),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue.shade700),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

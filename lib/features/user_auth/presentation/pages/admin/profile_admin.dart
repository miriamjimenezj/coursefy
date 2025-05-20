import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<List<Map<String, dynamic>>> _fetchAllProgress() async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) return [];

    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('createdBy', isEqualTo: adminId)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (var courseDoc in coursesSnapshot.docs) {
      final courseId = courseDoc.id;
      final courseData = courseDoc.data();
      final courseTitle = courseData['title'] ?? 'Untitled Course';
      final levelsCount = (courseData['levels'] as Map).length;

      final progressSnapshot = await FirebaseFirestore.instance
          .collection('course_progress')
          .where('courseId', isEqualTo: courseId)
          .get();

      for (var progressDoc in progressSnapshot.docs) {
        final progressData = progressDoc.data();
        final userId = progressData['userId'];
        final completedLevels = (progressData['completedLevels'] as List).length;
        final finalTestPassed = progressData['finalTestPassed'] ?? false;

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final email = userDoc.data()?['email'] ?? userId;

        result.add({
          'email': email,
          'course': courseTitle,
          'completed': completedLevels,
          'total': levelsCount,
          'finalTestPassed': finalTestPassed,
        });
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100),
              const SizedBox(height: 12),
              Text(
                user.email ?? "admin",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(local.welcome, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Text(
                local.usersRegisteredToYourCourses,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                Expanded(child: Center(child: Text(local.noCoursesFound)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(item['email'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${local.course}: ${item['course']}"),
                              Text("${item['completed']} / ${item['total']} ${local.levelsCompleted}"),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: (item['completed'] / item['total']).clamp(0.0, 1.0)),
                              const SizedBox(height: 6),
                              Text(
                                item['finalTestPassed']
                                    ? "✅ ${local.finalTestCompleted}"
                                    : "❌ ${local.finalTestPending}",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
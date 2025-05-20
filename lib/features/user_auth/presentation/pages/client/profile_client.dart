import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<List<Map<String, dynamic>>> _fetchCourseProgress(String userId) async {
    final progressSnapshot = await FirebaseFirestore.instance
        .collection('course_progress')
        .where('userId', isEqualTo: userId)
        .get();

    final List<Map<String, dynamic>> result = [];

    for (var doc in progressSnapshot.docs) {
      final progressData = doc.data();
      final courseId = progressData['courseId'];
      final completedFinalTest = progressData['finalTestPassed'] ?? false;

      final courseDoc = await FirebaseFirestore.instance.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) continue;

      final courseData = courseDoc.data();
      final totalLevels = (courseData?['levels'] as Map).length;
      final completedLevels = (progressData['completedLevels'] as List).length;

      final progress = (completedLevels / totalLevels).clamp(0.0, 1.0);

      result.add({
        'title': courseData?['title'] ?? 'Unknown Course',
        'progress': progress,
        'completed': completedLevels,
        'total': totalLevels,
        'finalTestPassed': completedFinalTest,
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final local = AppLocalizations.of(context)!;

    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchCourseProgress(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(local.noCoursesFound));
        }

        final courses = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 35),
              const Icon(Icons.account_circle, size: 100),
              const SizedBox(height: 12),
              Text('${user.email ?? "username"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(local.welcome, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Text(local.coursesCompleted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final bool finalTestPassed = course['finalTestPassed'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(course['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${course['completed']} / ${course['total']} ${local.levelsCompleted}"),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: course['progress']),
                            const SizedBox(height: 10),
                            Text(
                              finalTestPassed
                                  ? "✅ ${local.finalTestCompleted}"
                                  : "❌ ${local.finalTestPending}",
                              style: const TextStyle(fontSize: 14),
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
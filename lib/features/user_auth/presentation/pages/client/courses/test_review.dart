import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TestReviewPage extends StatelessWidget {
  final String courseId;

  const TestReviewPage({super.key, required this.courseId});

  Future<List<Map<String, dynamic>>> _fetchUserAnswers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final doc = await FirebaseFirestore.instance
        .collection('course_progress')
        .doc('$userId$courseId')
        .get();

    if (!doc.exists || doc.data()?['userAnswers'] == null) return [];

    return List<Map<String, dynamic>>.from(doc.data()!['userAnswers']);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.seeResults)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserAnswers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(local.noAnswersFound));
          }

          final answersData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: answersData.length,
            itemBuilder: (context, index) {
              final item = answersData[index];
              final questionText = item['question'];
              final answers = List<Map<String, dynamic>>.from(item['answers']);
              final selectedIndex = answers.indexWhere((a) => a['selected'] == true);
              final correctIndex = answers.indexWhere((a) => a['correct'] == true);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Q${index + 1}: $questionText", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...List.generate(answers.length, (i) {
                        final isCorrect = i == correctIndex;
                        final isUser = i == selectedIndex;

                        return Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle
                                  : isUser
                                  ? Icons.radio_button_checked
                                  : Icons.circle_outlined,
                              color: isCorrect
                                  ? Colors.green
                                  : isUser
                                  ? Colors.blueGrey
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(child: Text(answers[i]['text'] ?? '')),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
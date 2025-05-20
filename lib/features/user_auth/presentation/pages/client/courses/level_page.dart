import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'level_test.dart';

class LevelPage extends StatelessWidget {
  final String levelName;
  final String content;
  final List<dynamic> tests;
  final String courseId;
  final String levelKey;
  final List<int?> userAnswers;

  const LevelPage({
    Key? key,
    required this.levelName,
    required this.content,
    required this.tests,
    required this.courseId,
    required this.levelKey,
    required this.userAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(levelName),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.book, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LevelTestPage(
                      levelName: levelName,
                      questions: List<Map<String, dynamic>>.from(tests),
                      courseId: courseId,
                      levelKey: levelKey,
                      userAnswers: [],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(AppLocalizations.of(context)!.takeTest),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
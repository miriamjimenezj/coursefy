import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'level_result.dart';

class LevelTestPage extends StatefulWidget {
  final String levelName;
  final List<Map<String, dynamic>> questions;
  final String courseId;
  final String levelKey;
  final List<int?> userAnswers;

  const LevelTestPage({
    Key? key,
    required this.levelName,
    required this.questions,
    required this.courseId,
    required this.levelKey,
    required this.userAnswers,
  }) : super(key: key);

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<int?>.filled(widget.questions.length, null);
  }

  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      int correctAnswers = 0;
      for (int i = 0; i < widget.questions.length; i++) {
        final selected = _selectedAnswers[i];
        final answers = List<Map<String, dynamic>>.from(widget.questions[i]['answers']);
        if (selected != null && answers[selected]['correct'] == true) {
          correctAnswers++;
        }
      }

      final percentage = correctAnswers / widget.questions.length;
      final passed = percentage >= 0.5;

      final userId = _auth.currentUser?.uid;
      List<String> newBadges = [];
      if (userId != null) {
        final docRef = _firestore.collection('course_progress').doc('$userId${widget.courseId}');

        final dataToUpdate = {
          'userId': userId,
          'courseId': widget.courseId,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (widget.levelKey == 'finalTest') {
          dataToUpdate['finalTestPassed'] = passed;
        } else if (passed) {
          dataToUpdate['completedLevels'] = FieldValue.arrayUnion([widget.levelKey]);
        }

        await docRef.set(dataToUpdate, SetOptions(merge: true));

        if (passed && widget.levelKey == 'finalTest') {
          final userDocRef = _firestore.collection('users').doc(userId);

          final userSnap = await userDocRef.get();
          final List<dynamic> userCompletedCourses = userSnap.data()?['completedCourses'] ?? [];
          final List<dynamic> userBadges = userSnap.data()?['badges'] ?? [];

          List<String> completedCourses = List<String>.from(userCompletedCourses);
          if (!completedCourses.contains(widget.courseId)) {
            completedCourses.add(widget.courseId);
            await userDocRef.update({'completedCourses': completedCourses});
          }

          final int totalCompleted = completedCourses.length;

          // Badge: Primer curso completado
          if (!userBadges.contains('badge_first_course') && totalCompleted >= 1) {
            newBadges.add('badge_first_course');
          }
          // Badge: 5 cursos completados
          if (!userBadges.contains('badge_5_courses') && totalCompleted >= 5) {
            newBadges.add('badge_5_courses');
          }
          // Badge: 10 cursos completados
          if (!userBadges.contains('badge_10_courses') && totalCompleted >= 10) {
            newBadges.add('badge_10_courses');
          }
          // Badge: Test final con 100%
          if (!userBadges.contains('badge_100_score') && percentage == 1.0) {
            newBadges.add('badge_100_score');
          }

          // Guardar badges si hay nuevas
          if (newBadges.isNotEmpty) {
            await userDocRef.update({
              'badges': FieldValue.arrayUnion(newBadges),
            });

            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.congrats),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.badgeUnlocked),
                    for (final badge in newBadges)
                      Text('• $badge', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      }

      final List<Map<String, dynamic>> userAnswers = [];

      for (int i = 0; i < widget.questions.length; i++) {
        final question = widget.questions[i];
        final selected = _selectedAnswers[i];
        final answers = List<Map<String, dynamic>>.from(question['answers']);

        userAnswers.add({
          'question': question['question'],
          'answers': List.generate(4, (j) => {
            'text': answers[j]['text'],
            'selected': selected == j,
          }),
        });
      }

      await FirebaseFirestore.instance
          .collection('course_progress')
          .doc('$userId${widget.courseId}')
          .set({
        'userAnswers': userAnswers,
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LevelResultPage(
            levelTitle: widget.levelName,
            percentage: percentage,
            passed: passed,
            onReturnHome: () => Navigator.popUntil(context, (route) => route.isFirst),
            onNextLevel: passed ? () => Navigator.pop(context) : null,
            courseId: widget.courseId,
            courseTitle: "Course",
            levels: {},
            userAnswers: _selectedAnswers,
            newBadges: newBadges,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final answers = List<Map<String, dynamic>>.from(question['answers']);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.levelKey == 'finalTest'
            ? AppLocalizations.of(context)!.finalTestOnly
            : '${AppLocalizations.of(context)!.test} ${widget.levelName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.question} ${_currentQuestionIndex + 1}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question['question'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CheckboxListTile(
                  title: Text(
                    answers[index]['text'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: _selectedAnswers[_currentQuestionIndex] == index,
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = index;
                    });
                  },
                  activeColor: Colors.greenAccent,
                  checkColor: Colors.black,
                ),
              );
            }),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _selectedAnswers[_currentQuestionIndex] != null ? _goToNextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[200],
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
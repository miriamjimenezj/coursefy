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

  const LevelTestPage({
    Key? key,
    required this.levelName,
    required this.questions,
    required this.courseId,
    required this.levelKey,
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
      if (userId != null && passed) {
        final docRef = _firestore.collection('course_progress').doc('$userId${widget.courseId}');
        await docRef.set({
          'userId': userId,
          'courseId': widget.courseId,
          'lastUpdated': FieldValue.serverTimestamp(),
          'completedLevels': FieldValue.arrayUnion([widget.levelKey]),
        }, SetOptions(merge: true));
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LevelResultPage(
            levelTitle: widget.levelName,
            percentage: percentage,
            passed: passed,
            onReturnHome: () => Navigator.popUntil(context, (route) => route.isFirst),
            onNextLevel: passed ? () => Navigator.pop(context) : null,
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
        title: Text('${AppLocalizations.of(context)!.test} ${widget.levelName}'),
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
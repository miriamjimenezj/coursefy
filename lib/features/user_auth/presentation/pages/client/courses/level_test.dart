import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LevelTestPage extends StatefulWidget {
  final String levelName;
  final List<Map<String, dynamic>> questions;

  const LevelTestPage({
    Key? key,
    required this.levelName,
    required this.questions,
  }) : super(key: key);

  @override
  State<LevelTestPage> createState() => _LevelTestPageState();
}

class _LevelTestPageState extends State<LevelTestPage> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List<int?>.filled(widget.questions.length, null);
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Test completed logic here
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.testCompleted),
          content: Text(AppLocalizations.of(context)!.thankYouForCompleting),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('OK'),
            ),
          ],
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

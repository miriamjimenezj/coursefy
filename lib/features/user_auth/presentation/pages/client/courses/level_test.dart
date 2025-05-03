import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'level_result.dart';

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
  bool _testCompleted = false;
  int _score = 0;

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
      // Calcular el porcentaje de aciertos
      int correctAnswers = 0;

      for (int i = 0; i < widget.questions.length; i++) {
        final question = widget.questions[i];
        final selected = _selectedAnswers[i];
        if (selected != null && question['answers'][selected]['correct'] == true) {
          correctAnswers++;
        }
      }

      final percentage = correctAnswers / widget.questions.length;
      final passed = percentage >= 0.5;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LevelResultPage(
            levelTitle: widget.levelName,
            percentage: percentage,
            passed: passed,
           ),
        ),
      );
    }
  }

  /* void _calculateScore() {
    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final selected = _selectedAnswers[i];
      final answers = List<Map<String, dynamic>>.from(widget.questions[i]['answers']);
      if (selected != null && answers[selected]['correct'] == true) {
        score++;
      }
    }

    setState(() {
      _score = score;
      _testCompleted = true;
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${AppLocalizations.of(context)!.test} ${widget.levelName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _testCompleted
            ? _buildResultScreen(context)
            : _buildQuestionContent(context),
      ),
    );
  }

  Widget _buildQuestionContent(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final answers = List<Map<String, dynamic>>.from(question['answers']);

    return Column(
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
    );
  }

  Widget _buildResultScreen(BuildContext context) {
    final percentage = (_score / widget.questions.length * 100).round();
    final passed = percentage >= 50;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${AppLocalizations.of(context)!.levelGrades} ${widget.levelName}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Icon(Icons.check_circle, size: 40, color: Colors.black),
        const SizedBox(height: 16),
        Text(
          passed
              ? AppLocalizations.of(context)!.passedMessage
              : AppLocalizations.of(context)!.failedMessage,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 100,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 12,
                backgroundColor: Colors.red[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            Text('$percentage %', style: const TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 32),
        Image.asset(
          passed ? 'assets/good_job.png' : 'assets/try_again.png',
          height: 120,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home),
              label: const Text("Home"),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(passed ? Icons.arrow_forward : Icons.refresh),
              label: Text(passed
                  ? AppLocalizations.of(context)!.nextLevel
                  : AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ],
    );
  }
}
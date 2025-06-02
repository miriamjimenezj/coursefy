import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'level_page.dart';
import 'level_test.dart';

class CoursesPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CoursesPage({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<String> completedLevels = [];
  bool isLoading = true;
  bool finalTestPassed = false;
  Map<String, dynamic> levels = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final progressSnapshot = await FirebaseFirestore.instance
        .collection('course_progress')
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: widget.courseId)
        .limit(1)
        .get();

    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();
    final courseData = courseDoc.data();

    final Map<String, dynamic> loadedLevels = courseData?['levels'] ?? {};

    if (progressSnapshot.docs.isNotEmpty) {
      final doc = progressSnapshot.docs.first;
      final data = doc.data();
      final List<dynamic> levelsCompleted = data['completedLevels'] ?? [];
      finalTestPassed = data['finalTestPassed'] ?? false;

      setState(() {
        completedLevels = List<String>.from(levelsCompleted);
        levels = loadedLevels;
        isLoading = false;
      });
    } else {
      setState(() {
        completedLevels = [];
        levels = loadedLevels;
        isLoading = false;
      });
    }
  }

  Future<void> _openFinalTest() async {
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();

    final courseData = courseDoc.data();
    final List<dynamic> finalTestRaw = courseData!['finalTest'];

    final List<Map<String, dynamic>> finalTest = finalTestRaw.map<Map<String, dynamic>>((q) => {
      'question': q['question'],
      'answers': List<Map<String, dynamic>>.from(q['answers']),
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelTestPage(
          levelName: AppLocalizations.of(context)!.finalTest,
          questions: finalTest,
          courseId: widget.courseId,
          levelKey: 'finalTest',
          userAnswers: [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelKeys = levels.keys.toList()..sort();
    final allLevelsCompleted = levelKeys.isEmpty
        ? false
        : completedLevels.toSet().containsAll(levelKeys.toSet());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle),
        leading: const BackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.selectLevelToStart,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: List.generate(levelKeys.length, (index) {
                  final levelKey = levelKeys[index];
                  final isUnlocked = index == 0 ||
                      completedLevels.contains('level$index') ||
                      completedLevels.contains(levelKey);

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () {
                      final levelData = levels[levelKey];
                      final content = levelData['content'] ?? '';
                      final tests = levelData['tests'] ?? [];
                      final fileUrl = levelData['fileUrl'] ?? '';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelPage(
                            levelName: 'Level ${levelKey.replaceAll('level', '')}',
                            content: content,
                            tests: tests,
                            courseId: widget.courseId,
                            levelKey: levelKey,
                            userAnswers: [],
                            fileUrl: fileUrl,
                          ),
                        ),
                      );
                    }
                        : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUnlocked ? Colors.lightBlueAccent : Colors.grey[400],
                      ),
                      alignment: Alignment.center,
                      child: isUnlocked
                          ? Text(
                        'L${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                          : const Icon(Icons.lock, color: Colors.white),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: allLevelsCompleted ? _openFinalTest : null,
                icon: const Icon(Icons.check_circle),
                label: Text(AppLocalizations.of(context)!.finalTest),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.home, size: 40, color: Colors.blueAccent),
                tooltip: AppLocalizations.of(context)!.home,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
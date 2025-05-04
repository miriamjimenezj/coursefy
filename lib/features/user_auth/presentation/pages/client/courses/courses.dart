import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'level_page.dart';

class CoursesPage extends StatelessWidget {
  final String courseId;
  final String courseTitle;
  final Map<String, dynamic> levels;
  //final String levelKey;

  const CoursesPage({
    Key? key,
    required this.courseId,
    required this.courseTitle,
    required this.levels,
    //required this.levelKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final levelKeys = levels.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.selectLevelToStart,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(levelKeys.length, (index) {
                final levelKey = levelKeys[index];
                final isUnlocked = index == 0; // Solo el primero desbloqueado por ahora

                return GestureDetector(
                  onTap: isUnlocked
                      ? () {
                    final levelData = levels[levelKey];
                    final content = levelData['content'] ?? '';
                    final tests = levelData['tests'] ?? [];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelPage(
                          levelName: 'Level ${levelKey.replaceAll('level', '')}',
                          content: content,
                          tests: tests,
                          courseId: courseId,
                          levelKey: levelKey,
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
              onPressed: () {
                // Acción del test final
              },
              icon: const Icon(Icons.check_circle),
              label: Text(AppLocalizations.of(context)!.finalTest),
            ),
          ],
        ),
      ),
    );
  }
}
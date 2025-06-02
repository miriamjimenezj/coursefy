import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'level_test.dart';
import 'package:url_launcher/url_launcher.dart';

class LevelPage extends StatelessWidget {
  final String levelName;
  final String content;
  final String? fileUrl;
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
    this.fileUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasFile = fileUrl != null && fileUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(levelName),
        leading: const BackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.book, size: 40),
                    const SizedBox(height: 10),
                    if (content.trim().isNotEmpty)
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                    if (hasFile) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () async {
                          final url = Uri.parse(fileUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        label: Text(AppLocalizations.of(context)!.openAttachedFile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
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
      ),
    );
  }
}
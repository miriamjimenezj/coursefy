import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../home_client.dart';
import 'test_review.dart';
import 'courses.dart';

class LevelResultPage extends StatelessWidget {
  final String levelTitle;
  final double percentage;
  final bool passed;
  final String courseId;
  final String courseTitle;
  final Map<String, dynamic> levels;
  final List<int?> userAnswers;
  final List<String> newBadges;

  final VoidCallback onReturnHome;
  final VoidCallback? onNextLevel;

  const LevelResultPage({
    super.key,
    required this.levelTitle,
    required this.percentage,
    required this.passed,
    required this.onReturnHome,
    this.onNextLevel,
    required this.courseId,
    required this.courseTitle,
    required this.levels,
    required this.userAnswers,
    this.newBadges = const [],
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final percentText = '${(percentage * 100).toInt()} %';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          levelTitle.toLowerCase() == AppLocalizations.of(context)!.finalTest.toLowerCase()
              ? AppLocalizations.of(context)!.finalTestOnly
              : 'Results $levelTitle',
        ),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 40, color: Colors.black),
                    const SizedBox(height: 16),
                    Text(
                      passed ? localization.congrats : localization.tryAgain,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    CustomPaint(
                      size: const Size(200, 100),
                      painter: _ArcPainter(percentage: percentage),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Text(percentText, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, size: 32),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeClient(onLocaleChange: _dummyLocaleChange),
                      ),
                          (route) => false,
                    );
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestReviewPage(courseId: courseId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text(localization.seeResults),
                ),
                if (passed)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 32),
                    tooltip: localization.nextLevel,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoursesPage(
                            courseId: courseId,
                            courseTitle: courseTitle,
                          ),
                        ),
                      );
                    },
                  ),
                if (!passed)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 32),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _dummyLocaleChange(Locale _) {}
}

class _ArcPainter extends CustomPainter {
  final double percentage;

  _ArcPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final paint = Paint()
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..color = Colors.red[300]!;

    canvas.drawArc(rect, 3.14, 3.14, false, paint);

    final paintGreen = Paint()
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..color = Colors.green[300]!;

    canvas.drawArc(rect, 3.14, 3.14 * percentage, false, paintGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
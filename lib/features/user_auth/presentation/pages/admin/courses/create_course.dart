import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _levels = List.generate(
    5,
        (index) => {
      'content': TextEditingController(),
      'file': null,
      'tests': [],
    },
  );

  /// **Función para agregar una nueva pregunta a un nivel**
  void _addQuestion(int levelIndex) {
    setState(() {
      _levels[levelIndex]['tests'].add({
        'question': TextEditingController(),
        'answers': List.generate(4, (index) => TextEditingController()),
        'correctAnswers': List.generate(4, (index) => false),
      });
    });
  }

  /// **Función para guardar el curso en Firebase**
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    String userId = _auth.currentUser?.uid ?? '';

    Map<String, dynamic> courseData = {
      'title': _courseNameController.text.trim(),
      'createdBy': userId,
      'createdAt': Timestamp.now(),
      'levels': _levels.asMap().map((index, level) {
        return MapEntry(
          'level${index + 1}',
          {
            'content': level['content'].text.trim(),
            'tests': level['tests'].map((test) {
              return {
                'question': test['question'].text.trim(),
                'answers': List.generate(
                  4,
                      (i) => {
                    'text': test['answers'][i].text.trim(),
                    'correct': test['correctAnswers'][i],
                  },
                ),
              };
            }).toList(),
          },
        );
      }),
    };

    await _firestore.collection('courses').add(courseData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.courseCreated)),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.createCourse)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _courseNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.courseName,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.courseNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              for (int i = 0; i < _levels.length; i++) _buildLevelSection(i),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCourse,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text(AppLocalizations.of(context)!.submitCourse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSection(int levelIndex) {
    return ExpansionTile(
      title: Text("${AppLocalizations.of(context)!.content} L${levelIndex + 1}"),
      children: [
        TextFormField(
          controller: _levels[levelIndex]['content'],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.writeContent,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _addQuestion(levelIndex),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addQuestion),
        ),
        ..._levels[levelIndex]['tests'].map<Widget>((test) {
          return _buildTestQuestion(test);
        }).toList(),
      ],
    );
  }

  Widget _buildTestQuestion(Map<String, dynamic> test) {
    return Column(
      children: [
        TextFormField(
          controller: test['question'],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.question,
            border: OutlineInputBorder(),
          ),
        ),
        ...List.generate(4, (i) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: test['answers'][i],
                  decoration: InputDecoration(
                    labelText: "${AppLocalizations.of(context)!.answer} ${i + 1}",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Checkbox(
                value: test['correctAnswers'][i],
                onChanged: (val) {
                  setState(() {
                    test['correctAnswers'][i] = val!;
                  });
                },
              ),
            ],
          );
        }),
      ],
    );
  }
}
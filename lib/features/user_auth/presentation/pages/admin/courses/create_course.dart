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
  final TextEditingController _titleController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> _levels = List.generate(5, (_) => {
    'content': TextEditingController(),
    'tests': <Map<String, dynamic>>[],
  });

  void _addQuestion(int levelIndex) {
    setState(() {
      _levels[levelIndex]['tests'].add({
        'question': TextEditingController(),
        'answers': List.generate(4, (_) => {
          'text': TextEditingController(),
          'correct': false,
        }),
      });
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    Map<String, dynamic> levelsData = {};
    for (int i = 0; i < _levels.length; i++) {
      levelsData['level${i + 1}'] = {
        'content': _levels[i]['content'].text.trim(),
        'tests': _levels[i]['tests'].map((test) => {
          'question': test['question'].text.trim(),
          'answers': List.generate(4, (j) => {
            'text': test['answers'][j]['text'].text.trim(),
            'correct': test['answers'][j]['correct'],
          })
        }).toList(),
      };
    }

    await FirebaseFirestore.instance.collection('courses').add({
      'title': _titleController.text.trim(),
      'createdBy': userId,
      'createdAt': Timestamp.now(),
      'levels': levelsData,
    });

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
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.courseName,
                  border: const OutlineInputBorder(),
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

  Widget _buildLevelSection(int index) {
    return ExpansionTile(
      title: Text("${AppLocalizations.of(context)!.content} L${index + 1}"),
      children: [
        TextFormField(
          controller: _levels[index]['content'],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.writeContent,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _addQuestion(index),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addQuestion),
        ),
        ..._levels[index]['tests'].map<Widget>((test) => _buildTestQuestion(test)).toList(),
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
            border: const OutlineInputBorder(),
          ),
        ),
        ...List.generate(4, (i) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: test['answers'][i]['text'],
                  decoration: InputDecoration(
                    labelText: "${AppLocalizations.of(context)!.answer} ${i + 1}",
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Checkbox(
                value: test['answers'][i]['correct'],
                onChanged: (val) {
                  setState(() {
                    test['answers'][i]['correct'] = val!;
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

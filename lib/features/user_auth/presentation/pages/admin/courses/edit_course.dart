import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditCoursePage extends StatefulWidget {
  final String courseId;
  final String currentTitle;
  final Map<String, dynamic> levels;

  const EditCoursePage({
    super.key,
    required this.courseId,
    required this.currentTitle,
    required this.levels,
  });

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late Map<String, dynamic> _levels;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);

    _levels = widget.levels.map((key, level) {
      final content = TextEditingController(text: level['content']);
      final tests = (level['tests'] as List).map((test) {
        return {
          'question': TextEditingController(text: test['question']),
          'answers': (test['answers'] as List).map((answer) {
            return {
              'text': TextEditingController(text: answer['text']),
              'correct': answer['correct'],
            };
          }).toList(),
        };
      }).toList();

      return MapEntry(key, {
        'content': content,
        'tests': tests,
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var level in _levels.values) {
      level['content'].dispose();
      for (var test in level['tests']) {
        test['question'].dispose();
        for (var answer in test['answers']) {
          answer['text'].dispose();
        }
      }
    }
    super.dispose();
  }

  Future<void> _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, dynamic> levelsData = {};
        _levels.forEach((key, level) {
          levelsData[key] = {
            'content': level['content'].text.trim(),
            'tests': level['tests'].map((test) {
              return {
                'question': test['question'].text.trim(),
                'answers': List.generate(4, (i) => {
                  'text': test['answers'][i]['text'].text.trim(),
                  'correct': test['answers'][i]['correct'],
                }),
              };
            }).toList(),
          };
        });

        await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update({
          'title': _titleController.text.trim(),
          'levels': levelsData,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.courseUpdated)),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingCourse)),
        );
      }
    }
  }

  void _addQuestion(String levelKey) {
    setState(() {
      _levels[levelKey]['tests'].add({
        'question': TextEditingController(),
        'answers': List.generate(4, (index) => {
          'text': TextEditingController(),
          'correct': false,
        }),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editCourse)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
              ..._levels.entries.map((entry) => _buildLevelSection(entry.key, entry.value)).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateCourse,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSection(String levelKey, Map<String, dynamic> level) {
    return ExpansionTile(
      title: Text("${AppLocalizations.of(context)!.content} ${levelKey}"),
      children: [
        TextFormField(
          controller: level['content'],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.writeContent,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _addQuestion(levelKey),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addQuestion),
        ),
        ...level['tests'].map<Widget>((test) => _buildTestQuestion(test)).toList(),
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

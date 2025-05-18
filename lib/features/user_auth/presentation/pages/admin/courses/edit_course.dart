import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditCoursePage extends StatefulWidget {
  final String courseId;
  final String currentTitle;
  final Map<String, dynamic> levels;
  final List<dynamic> finalTest;
  final List<dynamic> tags;

  const EditCoursePage({
    super.key,
    required this.courseId,
    required this.currentTitle,
    required this.levels,
    required this.finalTest,
    required this.tags,
  });

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  late List<String> _tags;

  late Map<String, dynamic> _levels;
  late List<Map<String, dynamic>> _finalTest;
  int _nextLevelNumber = 0;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.currentTitle;
    _tags = widget.tags.map((tag) => tag.toString()).toList();

    final sortedKeys = widget.levels.keys.toList()..sort();
    _nextLevelNumber = sortedKeys.length + 1;

    _levels = {
      for (var key in sortedKeys)
        key: {
          'content': TextEditingController(text: widget.levels[key]['content']),
          'tests': (widget.levels[key]['tests'] as List).map((test) {
            return {
              'question': TextEditingController(text: test['question']),
              'answers': (test['answers'] as List).map((a) => {
                'text': TextEditingController(text: a['text']),
                'correct': a['correct'],
              }).toList(),
            };
          }).toList(),
        }
    };

    _finalTest = widget.finalTest.map<Map<String, dynamic>>((test) {
      return {
        'question': TextEditingController(text: test['question']),
        'answers': (test['answers'] as List).map((a) => {
          'text': TextEditingController(text: a['text']),
          'correct': a['correct'],
        }).toList(),
      };
    }).toList();
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final levelsData = {
      for (var key in _levels.keys)
        key: {
          'content': _levels[key]['content'].text,
          'tests': _levels[key]['tests'].map((test) => {
            'question': test['question'].text,
            'answers': test['answers'].map((a) => {
              'text': a['text'].text,
              'correct': a['correct'],
            }).toList(),
          }).toList(),
        }
    };

    final finalTestData = _finalTest.map((test) => {
      'question': test['question'].text,
      'answers': test['answers'].map((a) => {
        'text': a['text'].text,
        'correct': a['correct'],
      }).toList(),
    }).toList();

    await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update({
      'title': _titleController.text.trim(),
      'tags': _tags,
      'levels': levelsData,
      'finalTest': finalTestData,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.courseUpdated)),
      );
      Navigator.pop(context);
    }
  }

  void _addQuestionToFinalTest() {
    setState(() {
      _finalTest.add({
        'question': TextEditingController(),
        'answers': List.generate(4, (_) => {
          'text': TextEditingController(),
          'correct': false,
        }),
      });
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _addLevel() {
    setState(() {
      final levelKey = 'level$_nextLevelNumber';
      _levels[levelKey] = {
        'content': TextEditingController(),
        'tests': [],
      };
      _nextLevelNumber++;
    });
  }

  void _addQuestionToLevel(String levelKey) {
    setState(() {
      _levels[levelKey]['tests'].add({
        'question': TextEditingController(),
        'answers': List.generate(4, (_) => {
          'text': TextEditingController(),
          'correct': false,
        }),
      });
    });
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
                    labelText: '${AppLocalizations.of(context)!.answer} ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Checkbox(
                value: test['answers'][i]['correct'],
                onChanged: (value) {
                  setState(() {
                    test['answers'][i]['correct'] = value!;
                  });
                },
              ),
            ],
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editCourse)),
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
                validator: (value) =>
                value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.courseNameRequired : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.tagsLabel,
                  hintText: AppLocalizations.of(context)!.tagsHint,
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addTag),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                )).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addLevel,
                icon: const Icon(Icons.add),
                label: const Text("Añadir nivel"),
              ),
              ..._levels.entries.map((entry) {
                return ExpansionTile(
                  title: Text('${AppLocalizations.of(context)!.content} ${entry.key}'),
                  children: [
                    TextFormField(
                      controller: entry.value['content'],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.writeContent,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    //..._finalTest.map<Widget>((test) => _buildTestQuestion(test as Map<String, dynamic>)).toList(),
                    ...entry.value['tests'].map<Widget>((test) => _buildTestQuestion(test as Map<String, dynamic>)).toList(),
                    ElevatedButton.icon(
                      onPressed: () => _addQuestionToLevel(entry.key),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addQuestion),
                    ),
                  ],
                );
              }),
              //const Divider(height: 40),
              ExpansionTile(
                initiallyExpanded: true,
                title: Text(AppLocalizations.of(context)!.finalTestAdmin, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  ..._finalTest.map(_buildTestQuestion).toList(),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _addQuestionToFinalTest,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.addQuestion),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updateCourse,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
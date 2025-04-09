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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  late Map<String, dynamic> _levels;
  late Map<String, dynamic> _initialLevels;
  int _nextLevelNumber = 0;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.currentTitle;

    final sortedKeys = widget.levels.keys.toList()..sort((a, b) => a.compareTo(b));
    _nextLevelNumber = sortedKeys.length + 1;

    _levels = {
      for (var key in sortedKeys)
        key: {
          'content': TextEditingController(text: widget.levels[key]['content']),
          'tests': (widget.levels[key]['tests'] as List).map((test) {
            return {
              'question': TextEditingController(text: test['question']),
              'answers': (test['answers'] as List).map((answer) {
                return {
                  'text': TextEditingController(text: answer['text']),
                  'correct': answer['correct'],
                };
              }).toList(),
            };
          }).toList(),
        }
    };

    _initialLevels = {
      for (var key in sortedKeys)
        key: {
          'content': TextEditingController(text: widget.levels[key]['content']),
          'tests': (widget.levels[key]['tests'] as List).map((test) {
            return {
              'question': TextEditingController(text: test['question']),
              'answers': (test['answers'] as List).map((answer) {
                return {
                  'text': TextEditingController(text: answer['text']),
                  'correct': answer['correct'],
                };
              }).toList(),
            };
          }).toList(),
        }
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
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
          'tags': _tags,
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

  void _resetForm() {
    setState(() {
      _titleController.text = widget.currentTitle;
      _levels.forEach((key, level) {
        level['content'].text = _initialLevels[key]['content'].text;
        final initialTests = _initialLevels[key]['tests'];
        level['tests'] = initialTests.map((test) {
          return {
            'question': TextEditingController(text: test['question'].text),
            'answers': test['answers'].map((a) => {
              'text': TextEditingController(text: a['text'].text),
              'correct': a['correct'],
            }).toList(),
          };
        }).toList();
      });
    });
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

  void _addLevel() {
    setState(() {
      final levelKey = 'level$_nextLevelNumber';
      _levels[levelKey] = {
        'content': TextEditingController(),
        'tests': <Map<String, dynamic>>[],
      };
      _nextLevelNumber++;
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

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
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
                children: _tags
                    .map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeTag(tag),
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addLevel,
                icon: const Icon(Icons.add),
                label: const Text("Añadir nivel"),
              ),
              const SizedBox(height: 10),
              ..._levels.entries.map((entry) => _buildLevelSection(entry.key, entry.value)).toList(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updateCourse,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[100]),
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                  ElevatedButton(
                    onPressed: _resetForm,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                    child: Text(AppLocalizations.of(context)!.reset),
                  ),
                ],
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
        ...level['tests']
            .map<Widget>((test) => Column(
          children: [
            _buildTestQuestion(test),
            const SizedBox(height: 32),
          ],
        ))
            .toList(),
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

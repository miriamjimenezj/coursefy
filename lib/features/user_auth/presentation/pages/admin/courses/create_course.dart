
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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
  final TextEditingController _tagController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _tags = [];
  final List<Map<String, dynamic>> _levels = [];
  final List<Map<String, dynamic>> _finalTest = [];

  void _addLevel() {
    setState(() {
      _levels.add({
        'content': TextEditingController(),
        'file': null,
        'fileUrl': '',
        'tests': <Map<String, dynamic>>[],
      });
    });
  }

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

  void _addFinalTestQuestion() {
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

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'html'],
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final fileName =
          'level_${index + 1}_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';

      final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
      await ref.putData(file.bytes!);
      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        _levels[index]['file'] = file;
        _levels[index]['fileUrl'] = downloadUrl;
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_finalTest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Debes añadir al menos una pregunta al test final")),
      );
      return;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    Map<String, dynamic> levelsData = {};
    for (int i = 0; i < _levels.length; i++) {
      levelsData['level${i + 1}'] = {
        'content': _levels[i]['content'].text.trim(),
        'fileUrl': _levels[i]['fileUrl'],
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
      'tags': _tags,
      'levels': levelsData,
      'finalTest': _finalTest.map((test) => {
        'question': test['question'].text.trim(),
        'answers': List.generate(4, (j) => {
          'text': test['answers'][j]['text'].text.trim(),
          'correct': test['answers'][j]['correct'],
        })
      }).toList(),
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
                  onDeleted: () => _removeTag(tag),
                )).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addLevel,
                icon: const Icon(Icons.add),
                label: const Text("Añadir nivel"),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < _levels.length; i++) _buildLevelSection(i),
              const SizedBox(height: 30),
              //Text("Test Final", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addFinalTestQuestion,
                icon: const Icon(Icons.add),
                label: const Text("Añadir pregunta al test final"),
              ),
              const SizedBox(height: 10),
              ..._finalTest.map((test) => Column(
                children: [
                  _buildTestQuestion(test),
                  const SizedBox(height: 32),
                ],
              )),
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
          onPressed: () async {
            try {
              await _pickFile(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.fileAttached)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.fileAttachError)),
              );
            }
          },
          icon: const Icon(Icons.attach_file),
          label: Text(AppLocalizations.of(context)!.addFile),
        ),
        if (_levels[index]['fileUrl'] != '')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Archivo adjuntado correctamente", style: const TextStyle(color: Colors.green)),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _addQuestion(index),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addQuestion),
        ),
        ..._levels[index]['tests'].map<Widget>((test) => Column(
          children: [
            _buildTestQuestion(test),
            const SizedBox(height: 32),
          ],
        )).toList(),
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:typed_data';

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
        'fileName': '',
        'tests': <Map<String, dynamic>>[],
      });
    });
  }

  void _removeLevel(int index) async {
    final fileUrl = _levels[index]['fileUrl'] ?? '';
    final fileName = _levels[index]['fileName'] ?? '';
    if (fileUrl.isNotEmpty && fileName.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
        await ref.delete();
      } catch (_) {}
    }
    setState(() {
      _levels.removeAt(index);
    });
  }

  bool _eachLevelHasAtLeastOneQuestion() {
    for (int i = 0; i < _levels.length; i++) {
      if (_levels[i]['tests'].isEmpty) {
        return false;
      }
    }
    return true;
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

  void _removeQuestion(int levelIndex, int questionIndex) {
    setState(() {
      _levels[levelIndex]['tests'].removeAt(questionIndex);
    });
  }

  void _removeFinalTestQuestion(int index) {
    setState(() {
      _finalTest.removeAt(index);
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

  bool _allQuestionsHaveCorrectAnswer() {
    for (var level in _levels) {
      for (var test in level['tests']) {
        final answers = test['answers'];
        if (!answers.any((a) => a['correct'] == true)) {
          return false;
        }
      }
    }
    for (var test in _finalTest) {
      final answers = test['answers'];
      if (!answers.any((a) => a['correct'] == true)) {
        return false;
      }
    }
    return true;
  }

  bool _allQuestionsAndAnswersFilled() {
    for (var level in _levels) {
      for (var test in level['tests']) {
        final questionText = test['question'].text.trim();
        if (questionText.isEmpty) return false;
        for (var answer in test['answers']) {
          if (answer['text'].text.trim().isEmpty) return false;
        }
      }
    }
    for (var test in _finalTest) {
      final questionText = test['question'].text.trim();
      if (questionText.isEmpty) return false;
      for (var answer in test['answers']) {
        if (answer['text'].text.trim().isEmpty) return false;
      }
    }
    return true;
  }

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'html'],
      withData: true,
    );

    if (result != null && result.files.single != null) {
      final file = result.files.single;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null && file.path != null) {
        final fileOnDisk = File(file.path!);
        fileBytes = await fileOnDisk.readAsBytes();
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileEmptyOrUnreadable)),
        );
        return;
      }

      String cleanTitle = _titleController.text.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = '${cleanTitle}_nivel_${index + 1}.${file.extension}';
      final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');

      final metadata = SettableMetadata(
        contentType: file.extension == 'pdf'
            ? 'application/pdf'
            : (file.extension == 'txt'
            ? 'text/plain'
            : 'text/html'),
        customMetadata: {
          'Content-Disposition': 'inline; filename="$fileName"',
        },
      );
      try {
        await ref.putData(fileBytes, metadata);
        final downloadUrl = await ref.getDownloadURL();

        setState(() {
          _levels[index]['file'] = file;
          _levels[index]['fileUrl'] = downloadUrl;
          _levels[index]['fileName'] = fileName;
        });

        print('Archivo subido. URL: $downloadUrl');
      } catch (e) {
        print('Error al subir a Firebase Storage: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppLocalizations.of(context)!.fileUploadError}: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileNotSelectedOrEmpty)),
      );
    }
  }

  Future<void> _removeFile(int index) async {
    final fileUrl = _levels[index]['fileUrl'] ?? '';
    final fileName = _levels[index]['fileName'] ?? '';
    if (fileUrl.isNotEmpty && fileName.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
        await ref.delete();
      } catch (_) {}
    }
    setState(() {
      _levels[index]['file'] = null;
      _levels[index]['fileUrl'] = '';
      _levels[index]['fileName'] = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.fileDeletedSuccessfully)),
    );
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.levelRequired)),
      );
      return;
    }

    for (int i = 0; i < _levels.length; i++) {
      final contentText = _levels[i]['content'].text.trim();
      final fileUrl = _levels[i]['fileUrl'];
      if ((contentText.isEmpty) && (fileUrl == null || fileUrl.toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.levelContentOrFile)),
        );
        return;
      }
    }

    if (!_eachLevelHasAtLeastOneQuestion()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.eachLevelAtLeastOneQuestion)),
      );
      return;
    }

    if (!_allQuestionsAndAnswersFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noEmptyQuestionsOrAnswers)),
      );
      return;
    }

    if (_finalTest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.finalTestRequired)),
      );
      return;
    }

    if (!_allQuestionsHaveCorrectAnswer()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.correctAnswerRequired)),
      );
      return;
    }
    for (int i = 0; i < _levels.length; i++) {
      if (_levels[i]['file'] != null && (_levels[i]['fileUrl'] == null || _levels[i]['fileUrl'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.missingLevelAttachment(i + 1))),
        );
        return;
      }
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
                label: Text(AppLocalizations.of(context)!.addLevel),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < _levels.length; i++) _buildLevelSection(i),
              const SizedBox(height: 30),
              ..._finalTest.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> test = entry.value;
                return Column(
                  children: [
                    _buildTestQuestion(
                      test,
                      onDelete: () => _removeFinalTestQuestion(index),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }).toList(),
              ElevatedButton.icon(
                onPressed: _addFinalTestQuestion,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addFinalTestQuestion),
              ),
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${AppLocalizations.of(context)!.content} L${index + 1}"),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: AppLocalizations.of(context)!.deleteLevel,
            onPressed: () => _removeLevel(index),
          ),
        ],
      ),
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
        Row(
          children: [
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
            const SizedBox(width: 12),
            if (_levels[index]['fileUrl'] != '')
              ElevatedButton.icon(
                onPressed: () => _removeFile(index),
                icon: const Icon(Icons.delete, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                label: Text(AppLocalizations.of(context)!.deleteFile),
              ),
          ],
        ),
        if (_levels[index]['fileUrl'] != '')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(AppLocalizations.of(context)!.fileAttachedSuccessfully, style: const TextStyle(color: Colors.green)),
          ),
        const SizedBox(height: 10),
        ...List.generate(
          _levels[index]['tests'].length,
              (qIdx) => Column(
            children: [
              _buildTestQuestion(_levels[index]['tests'][qIdx], onDelete: () => _removeQuestion(index, qIdx)),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _addQuestion(index),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addQuestion),
        ),
      ],
    );
  }

  Widget _buildTestQuestion(Map<String, dynamic> test, {VoidCallback? onDelete}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: test['question'],
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.question,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: AppLocalizations.of(context)!.deleteQuestion,
                onPressed: onDelete,
              ),
          ],
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
                    if (val == true) {
                      for (var j = 0; j < test['answers'].length; j++) {
                        test['answers'][j]['correct'] = false;
                      }
                      test['answers'][i]['correct'] = true;
                    } else {
                      test['answers'][i]['correct'] = false;
                    }
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'dart:typed_data';

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
          'fileUrl': widget.levels[key]['fileUrl'] ?? '',
          'fileName': widget.levels[key]['fileName'] ?? '',
          'file': null,
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

  Future<void> _pickFile(String levelKey) async {
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
      final fileName = '${cleanTitle}_$levelKey.${file.extension}';
      final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
      final metadata = SettableMetadata(
        contentType: file.extension == 'pdf'
            ? 'application/pdf'
            : (file.extension == 'txt'
            ? 'text/plain'
            : 'text/html'),
        customMetadata: {'Content-Disposition': 'inline; filename="$fileName"'},
      );
      try {
        await ref.putData(fileBytes, metadata);
        final downloadUrl = await ref.getDownloadURL();
        setState(() {
          _levels[levelKey]['file'] = file;
          _levels[levelKey]['fileUrl'] = downloadUrl;
          _levels[levelKey]['fileName'] = fileName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileAttached)),
        );
      } catch (e) {
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

  Future<void> _removeFile(String levelKey) async {
    final fileUrl = _levels[levelKey]['fileUrl'] ?? '';
    final fileName = _levels[levelKey]['fileName'] ?? '';
    if (fileUrl.isNotEmpty && fileName.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
        await ref.delete();
      } catch (_) {}
    }
    setState(() {
      _levels[levelKey]['file'] = null;
      _levels[levelKey]['fileUrl'] = '';
      _levels[levelKey]['fileName'] = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.fileDeletedSuccessfully)),
    );
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
        'fileUrl': '',
        'fileName': '',
        'file': null,
        'tests': [],
      };
      _nextLevelNumber++;
    });
  }

  void _removeLevel(String levelKey) async {
    final fileUrl = _levels[levelKey]['fileUrl'] ?? '';
    final fileName = _levels[levelKey]['fileName'] ?? '';
    if (fileUrl.isNotEmpty && fileName.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
        await ref.delete();
      } catch (_) {}
    }
    setState(() {
      _levels.remove(levelKey);
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

  void _removeQuestionFromLevel(String levelKey, int questionIndex) {
    setState(() {
      _levels[levelKey]['tests'].removeAt(questionIndex);
    });
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

  void _removeQuestionFromFinalTest(int questionIndex) {
    setState(() {
      _finalTest.removeAt(questionIndex);
    });
  }

  bool _eachLevelHasAtLeastOneQuestion() {
    for (var level in _levels.values) {
      if ((level['tests'] as List).isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _allQuestionsHaveCorrectAnswer() {
    for (var level in _levels.values) {
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
    for (var level in _levels.values) {
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

  Future<void> _deleteCourse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCourseTitle),
        content: Text(AppLocalizations.of(context)!.deleteCourseConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)))
        ],
      ),
    );
    if (confirmed == true) {
      for (var level in _levels.values) {
        final fileUrl = level['fileUrl'] ?? '';
        final fileName = level['fileName'] ?? '';
        if (fileUrl.isNotEmpty && fileName.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.ref().child('course_files/$fileName');
            await ref.delete();
          } catch (_) {}
        }
      }
      await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.courseDeleted)),
        );
      }
    }
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_levels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.levelRequired)),
      );
      return;
    }
    for (var entry in _levels.entries) {
      final contentText = entry.value['content'].text.trim();
      final fileUrl = entry.value['fileUrl'];
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
    // Archivos subidos
    for (var entry in _levels.entries) {
      if (entry.value['file'] != null && (entry.value['fileUrl'] == null || entry.value['fileUrl'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.missingLevelAttachment(int.parse(entry.key.replaceAll('level', ''))))),
        );
        return;
      }
    }

    final levelsData = {
      for (var key in _levels.keys)
        key: {
          'content': _levels[key]['content'].text.trim(),
          'fileUrl': _levels[key]['fileUrl'],
          'fileName': _levels[key]['fileName'],
          'tests': _levels[key]['tests'].map((test) => {
            'question': test['question'].text.trim(),
            'answers': List.generate(4, (j) => {
              'text': test['answers'][j]['text'].text.trim(),
              'correct': test['answers'][j]['correct'],
            })
          }).toList(),
        }
    };

    final finalTestData = _finalTest.map((test) => {
      'question': test['question'].text.trim(),
      'answers': List.generate(4, (j) => {
        'text': test['answers'][j]['text'].text.trim(),
        'correct': test['answers'][j]['correct'],
      })
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

  Widget _buildLevelSection(String levelKey) {
    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${AppLocalizations.of(context)!.content} $levelKey"),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: AppLocalizations.of(context)!.deleteLevel,
            onPressed: () => _removeLevel(levelKey),
          ),
        ],
      ),
      children: [
        TextFormField(
          controller: _levels[levelKey]['content'],
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
                  await _pickFile(levelKey);
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
            if (_levels[levelKey]['fileUrl'] != '')
              ElevatedButton.icon(
                onPressed: () => _removeFile(levelKey),
                icon: const Icon(Icons.delete, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                label: Text(AppLocalizations.of(context)!.deleteFile),
              ),
          ],
        ),
        if (_levels[levelKey]['fileUrl'] != '')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(AppLocalizations.of(context)!.fileAttachedSuccessfully, style: const TextStyle(color: Colors.green)),
          ),
        const SizedBox(height: 10),
        ...List.generate(
          _levels[levelKey]['tests'].length,
              (qIdx) => Column(
            children: [
              _buildTestQuestion(
                _levels[levelKey]['tests'][qIdx],
                onDelete: () => _removeQuestionFromLevel(levelKey, qIdx),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _addQuestionToLevel(levelKey),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.addQuestion),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editCourse),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: AppLocalizations.of(context)!.deleteCourse,
            onPressed: _deleteCourse,
          ),
        ],
      ),
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
                validator: (value) => value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.courseNameRequired : null,
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
                  onDeleted: () => setState(() => _tags.remove(tag)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addLevel,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addLevel),
              ),
              ..._levels.entries.map((entry) => _buildLevelSection(entry.key)),
              ExpansionTile(
                initiallyExpanded: true,
                title: Text(AppLocalizations.of(context)!.finalTestOnly, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  ...List.generate(_finalTest.length, (qIdx) => Column(
                    children: [
                      _buildTestQuestion(_finalTest[qIdx], onDelete: () => _removeQuestionFromFinalTest(qIdx)),
                      const SizedBox(height: 32),
                    ],
                  )),
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditCoursePage extends StatefulWidget {
  final String courseId;
  final String currentTitle;
  final List<Map<String, dynamic>> levels;

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
  late List<Map<String, dynamic>> _levels;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _levels = List.from(widget.levels);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// **Actualizar curso en Firestore**
  Future<void> _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update({
          'title': _titleController.text.trim(),
          'levels': _levels,
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

  /// **Agregar una nueva pregunta a un nivel**
  void _addQuestion(int levelIndex) {
    setState(() {
      _levels[levelIndex]['tests'].add({
        'question': TextEditingController(),
        'answers': List.generate(4, (index) => TextEditingController()),
        'correctAnswers': List.generate(4, (index) => false),
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

  /// **Construir la interfaz de edición de niveles**
  Widget _buildLevelSection(int levelIndex) {
    return ExpansionTile(
      title: Text("${AppLocalizations.of(context)!.content} L${levelIndex + 1}"),
      children: [
        TextFormField(
          controller: TextEditingController(text: _levels[levelIndex]['content']),
          onChanged: (value) => _levels[levelIndex]['content'] = value,
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
          return _buildTestQuestion(levelIndex, test);
        }).toList(),
      ],
    );
  }

  /// **Construir preguntas con respuestas editables**
  Widget _buildTestQuestion(int levelIndex, Map<String, dynamic> test) {
    return Column(
      children: [
        TextFormField(
          controller: TextEditingController(text: test['question']),
          onChanged: (value) => test['question'] = value,
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
                  controller: TextEditingController(text: test['answers'][i]['text']),
                  onChanged: (value) => test['answers'][i]['text'] = value,
                  decoration: InputDecoration(
                    labelText: "${AppLocalizations.of(context)!.answer} ${i + 1}",
                    border: OutlineInputBorder(),
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
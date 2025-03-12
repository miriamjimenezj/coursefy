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
  final TextEditingController _courseNameController = TextEditingController();
  bool _isLoading = false;

  /// Crear curso en Firebase
  Future<void> _createCourse() async {
    final String courseName = _courseNameController.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;

    if (courseName.isEmpty) {
      _showErrorDialog(AppLocalizations.of(context)!.errorTitle, AppLocalizations.of(context)!.courseNameRequired);
      return;
    }

    if (user == null) {
      _showErrorDialog(AppLocalizations.of(context)!.errorTitle, AppLocalizations.of(context)!.userNotLoggedIn);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('courses').add({
        'title': courseName,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Volver atrás tras crear
    } catch (e) {
      _showErrorDialog(AppLocalizations.of(context)!.errorTitle, AppLocalizations.of(context)!.createCourseError);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mostrar errores
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.createCourse)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _courseNameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.courseName,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createCourse,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(AppLocalizations.of(context)!.createCourse),
            ),
          ],
        ),
      ),
    );
  }
}
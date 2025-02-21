import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coursefy/features/user_auth/presentation/pages/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// **Función para eliminar la cuenta y salir**
  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    if (user != null) {
      try {
        // Eliminar usuario de Firestore
        await firestore.collection('users').doc(user.uid).delete();

        // Eliminar usuario de Firebase Authentication
        await user.delete();

        // Cerrar sesión antes de redirigir
        await FirebaseAuth.instance.signOut();

      } catch (e) {
        _showErrorDialog(context, "Error", "Could not delete the account. Try again.");
      }
    }
  }

  /// **Mostrar un diálogo de confirmación antes de borrar la cuenta**
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cerrar el diálogo sin hacer nada
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo antes de proceder
              _deleteAccount(context); // Intentar eliminar la cuenta

              // 🔥 **Redirigir inmediatamente al LoginPage**
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// **Mostrar un cuadro de diálogo de error**
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () => _showDeleteConfirmationDialog(context),
          child: const Text(
            "Delete Account",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
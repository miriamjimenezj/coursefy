import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:coursefy/features/presentation/pages/login_page.dart';

class SettingsClientPage extends StatelessWidget {
  final Function(Locale) onLocaleChange;

  const SettingsClientPage({super.key, required this.onLocaleChange});

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
        _showErrorDialog(context, AppLocalizations.of(context)!.errorTitle, AppLocalizations.of(context)!.deleteAccountError);
      }
    }
  }

  /// **Mostrar un diálogo de confirmación antes de borrar la cuenta**
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccountTitle),
        content: Text(AppLocalizations.of(context)!.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cerrar el diálogo sin hacer nada
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo antes de proceder
              _deleteAccount(context); // Intentar eliminar la cuenta
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage(onLocaleChange: onLocaleChange)),
                    (route) => false,
              );
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
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
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Locale _selectedLocale = Localizations.localeOf(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinea elementos a la izquierda
          children: [
            const SizedBox(height: 20),

            // Opción para cambiar idioma
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<Locale>(
              value: _selectedLocale.languageCode == 'es' ? const Locale('es') : const Locale('en'),
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text("English")),
                DropdownMenuItem(value: Locale('es'), child: Text("Español")),
              ],
              onChanged: (Locale? locale) {
                if (locale != null) {
                  onLocaleChange(locale); // Aplica el cambio de idioma en toda la app
                }
              },
            ),

            const SizedBox(height: 20),

            // Opción para eliminar cuenta
            GestureDetector(
              onTap: () => _showDeleteConfirmationDialog(context),
              child: Text(
                AppLocalizations.of(context)!.deleteAccount,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
